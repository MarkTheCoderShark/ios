import Foundation
import Combine

// MARK: - Combine Extensions for Better Usage Patterns

extension Publisher {
    /// Retries with exponential backoff
    func retryWithExponentialBackoff(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0
    ) -> AnyPublisher<Self.Output, Self.Failure> {
        return self.catch { error -> AnyPublisher<Self.Output, Self.Failure> in
            let delay = Swift.min(baseDelay * pow(2.0, Double(maxRetries)), maxDelay)
            return self
                .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Assigns to multiple KeyPaths simultaneously
    func assign<Root: AnyObject>(
        to keyPaths: [ReferenceWritableKeyPath<Root, Self.Output>],
        on object: Root
    ) -> AnyCancellable {
        return sink(
            receiveCompletion: { _ in },
            receiveValue: { value in
                keyPaths.forEach { keyPath in
                    object[keyPath: keyPath] = value
                }
            }
        )
    }
}

extension Publisher where Self.Failure == Never {
    /// Safely assigns to a property with weak capture
    func assignWeak<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
        on object: Root
    ) -> AnyCancellable {
        return sink(receiveValue: { [weak object] value in
            object?[keyPath: keyPath] = value
        })
    }
}

// MARK: - Custom Publishers

struct AsyncPublisher<PublisherOutput>: Publisher {
    typealias Output = PublisherOutput
    typealias Failure = Error

    private let asyncWork: () async throws -> PublisherOutput

    init(_ asyncWork: @escaping () async throws -> PublisherOutput) {
        self.asyncWork = asyncWork
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = AsyncSubscription<PublisherOutput, S>(subscriber: subscriber, asyncWork: asyncWork)
        subscriber.receive(subscription: subscription)
    }
}

private class AsyncSubscription<SubscriptionOutput, S: Subscriber>: Subscription
where S.Input == SubscriptionOutput, S.Failure == Error {

    private var subscriber: S?
    private let asyncWork: () async throws -> SubscriptionOutput
    private var isCancelled = false

    init(subscriber: S, asyncWork: @escaping () async throws -> SubscriptionOutput) {
        self.subscriber = subscriber
        self.asyncWork = asyncWork
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 && !isCancelled else { return }

        DispatchQueue.global().async { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            
            Task {
                do {
                    let result = try await self.asyncWork()
                    guard !self.isCancelled else { return }
                    _ = self.subscriber?.receive(result)
                    self.subscriber?.receive(completion: .finished)
                } catch {
                    guard !self.isCancelled else { return }
                    self.subscriber?.receive(completion: .failure(error))
                }
            }
        }
    }

    func cancel() {
        isCancelled = true
        subscriber = nil
    }
}

// MARK: - Usage Examples for the codebase

extension AnyPublisher {
    static func fromAsync<PublisherOutput>(_ asyncWork: @escaping () async throws -> PublisherOutput) -> AnyPublisher<PublisherOutput, Error> {
        return AsyncPublisher(asyncWork).eraseToAnyPublisher()
    }
}