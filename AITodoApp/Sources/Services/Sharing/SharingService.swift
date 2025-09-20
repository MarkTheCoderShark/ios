import Foundation
import CoreData
import Combine

class SharingService: ObservableObject {
    @Published var pendingInvites: [Invite] = []
    @Published var teamMembers: [User] = []

    private let persistenceController = PersistenceController.shared
    private let emailService = EmailInviteService()

    init() {
        loadTeamMembers()
        loadPendingInvites()
    }

    func shareTask(_ task: Task, with users: [User], role: TaskRole = .editor) -> Bool {
        guard canUserShare(task: task) else { return false }

        let context = persistenceController.backgroundContext()
        var success = true

        context.performAndWait {
            for user in users {
                if !isUserAlreadyAssigned(task: task, user: user) {
                    switch role {
                    case .assignee:
                        task.addToAssignees(user)
                    case .follower:
                        task.addToFollowers(user)
                    }
                }
            }

            task.isShared = true
            task.updatedAt = Date()

            do {
                try context.save()
                self.sendTaskSharedNotifications(task: task, users: users, role: role)
            } catch {
                print("Failed to share task: \(error)")
                success = false
            }
        }

        return success
    }

    func shareProject(_ project: Project, with users: [User], role: ProjectRole = .editor) -> Bool {
        guard canUserShare(project: project) else { return false }

        let context = persistenceController.backgroundContext()
        var success = true

        context.performAndWait {
            for user in users {
                if !isUserAlreadyInProject(project: project, user: user) {
                    let membership = ProjectMembership(context: context)
                    membership.project = project
                    membership.user = user
                    membership.role = role
                    membership.joinedAt = Date()
                    membership.isActive = true
                }
            }

            project.visibility = .shared
            project.updatedAt = Date()

            do {
                try context.save()
                self.sendProjectSharedNotifications(project: project, users: users, role: role)
            } catch {
                print("Failed to share project: \(error)")
                success = false
            }
        }

        return success
    }

    func inviteUserByEmail(_ email: String, to project: Project? = nil, role: ProjectRole = .commenter) {
        let invite = createInvite(email: email, project: project, role: role)
        emailService.sendInvite(invite) { [weak self] success in
            if success {
                self?.savePendingInvite(invite)
            }
        }
    }

    func acceptInvite(_ invite: Invite) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }

        let context = persistenceController.backgroundContext()
        var success = true

        context.performAndWait {
            if let project = invite.project {
                let membership = ProjectMembership(context: context)
                membership.project = project
                membership.user = currentUser
                membership.role = invite.role
                membership.joinedAt = Date()
                membership.isActive = true

                project.updatedAt = Date()
            }

            invite.isAccepted = true
            invite.acceptedAt = Date()
            invite.acceptedBy = currentUser

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.loadTeamMembers()
                    self.loadPendingInvites()
                }
            } catch {
                print("Failed to accept invite: \(error)")
                success = false
            }
        }

        return success
    }

    func revokeAccess(from user: User, for resource: SharableResource) -> Bool {
        guard canUserManagePermissions(for: resource) else { return false }

        let context = persistenceController.backgroundContext()
        var success = true

        context.performAndWait {
            switch resource {
            case .task(let task):
                task.removeFromAssignees(user)
                task.removeFromFollowers(user)
                task.updatedAt = Date()

            case .project(let project):
                if let memberships = project.memberships?.allObjects as? [ProjectMembership] {
                    for membership in memberships where membership.user.id == user.id {
                        membership.isActive = false
                        membership.user.removeFromProjectMemberships(membership)
                    }
                }
                project.updatedAt = Date()
            }

            do {
                try context.save()
                self.sendAccessRevokedNotification(user: user, resource: resource)
            } catch {
                print("Failed to revoke access: \(error)")
                success = false
            }
        }

        return success
    }

    func updatePermissions(for user: User, in resource: SharableResource, newRole: Any) -> Bool {
        guard canUserManagePermissions(for: resource) else { return false }

        let context = persistenceController.backgroundContext()
        var success = true

        context.performAndWait {
            switch resource {
            case .task(let task):
                if let taskRole = newRole as? TaskRole {
                    task.removeFromAssignees(user)
                    task.removeFromFollowers(user)

                    switch taskRole {
                    case .assignee:
                        task.addToAssignees(user)
                    case .follower:
                        task.addToFollowers(user)
                    }
                }

            case .project(let project):
                if let projectRole = newRole as? ProjectRole,
                   let memberships = project.memberships?.allObjects as? [ProjectMembership],
                   let membership = memberships.first(where: { $0.user.id == user.id }) {
                    membership.role = projectRole
                }
            }

            do {
                try context.save()
                self.sendPermissionsUpdatedNotification(user: user, resource: resource, newRole: newRole)
            } catch {
                print("Failed to update permissions: \(error)")
                success = false
            }
        }

        return success
    }

    func generateShareLink(for resource: SharableResource, permissions: ShareLinkPermissions) -> String? {
        let linkId = UUID().uuidString
        let baseURL = "https://app.aitodo.com/shared"

        switch resource {
        case .task(let task):
            saveShareLink(id: linkId, taskId: task.id, permissions: permissions)
            return "\(baseURL)/task/\(linkId)"

        case .project(let project):
            saveShareLink(id: linkId, projectId: project.id, permissions: permissions)
            return "\(baseURL)/project/\(linkId)"
        }
    }

    private func canUserShare(task: Task) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }
        return task.owner.id == currentUser.id || isUserAssignedToTask(task: task, user: currentUser)
    }

    private func canUserShare(project: Project) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }

        if project.owner.id == currentUser.id {
            return true
        }

        guard let memberships = project.memberships?.allObjects as? [ProjectMembership] else {
            return false
        }

        return memberships.contains { membership in
            membership.user.id == currentUser.id && (membership.role == .owner || membership.role == .editor)
        }
    }

    private func canUserManagePermissions(for resource: SharableResource) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }

        switch resource {
        case .task(let task):
            return task.owner.id == currentUser.id

        case .project(let project):
            if project.owner.id == currentUser.id {
                return true
            }

            guard let memberships = project.memberships?.allObjects as? [ProjectMembership] else {
                return false
            }

            return memberships.contains { membership in
                membership.user.id == currentUser.id && membership.role == .owner
            }
        }
    }

    private func isUserAlreadyAssigned(task: Task, user: User) -> Bool {
        let assignees = task.assignees?.allObjects as? [User] ?? []
        let followers = task.followers?.allObjects as? [User] ?? []

        return assignees.contains { $0.id == user.id } || followers.contains { $0.id == user.id }
    }

    private func isUserAssignedToTask(task: Task, user: User) -> Bool {
        let assignees = task.assignees?.allObjects as? [User] ?? []
        return assignees.contains { $0.id == user.id }
    }

    private func isUserAlreadyInProject(project: Project, user: User) -> Bool {
        guard let memberships = project.memberships?.allObjects as? [ProjectMembership] else {
            return false
        }

        return memberships.contains { membership in
            membership.user.id == user.id && membership.isActive
        }
    }

    private func createInvite(email: String, project: Project?, role: ProjectRole) -> Invite {
        return Invite(
            id: UUID(),
            email: email,
            project: project,
            role: role,
            invitedBy: getCurrentUser(),
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
    }

    private func savePendingInvite(_ invite: Invite) {
        DispatchQueue.main.async {
            self.pendingInvites.append(invite)
        }
    }

    private func loadTeamMembers() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.displayName, ascending: true)]

        do {
            teamMembers = try context.fetch(request)
        } catch {
            print("Failed to load team members: \(error)")
        }
    }

    private func loadPendingInvites() {
    }

    private func sendTaskSharedNotifications(task: Task, users: [User], role: TaskRole) {
    }

    private func sendProjectSharedNotifications(project: Project, users: [User], role: ProjectRole) {
    }

    private func sendAccessRevokedNotification(user: User, resource: SharableResource) {
    }

    private func sendPermissionsUpdatedNotification(user: User, resource: SharableResource, newRole: Any) {
    }

    private func saveShareLink(id: String, taskId: UUID? = nil, projectId: UUID? = nil, permissions: ShareLinkPermissions) {
    }

    private func getCurrentUser() -> User? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
}

enum SharableResource {
    case task(Task)
    case project(Project)
}

enum TaskRole {
    case assignee
    case follower
}

struct ShareLinkPermissions {
    let canView: Bool
    let canComment: Bool
    let canEdit: Bool
    let expiresAt: Date?
}

struct Invite {
    let id: UUID
    let email: String
    let project: Project?
    let role: ProjectRole
    let invitedBy: User?
    let createdAt: Date
    let expiresAt: Date?
    var isAccepted = false
    var acceptedAt: Date?
    var acceptedBy: User?
}

class EmailInviteService {
    func sendInvite(_ invite: Invite, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(true)
        }
    }
}