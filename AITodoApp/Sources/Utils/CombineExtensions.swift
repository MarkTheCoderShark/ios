import Foundation
import Combine

// MARK: - Combine Extensions for Better Usage Patterns

extension Publisher {
    /// Retries with exponential backoff
    func retryWithExponentialBackoff(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0
    ) -> Publishers.TryMap<Publishers.Catch<Self, Publishers.Delay<Just<Self.Output>, DispatchQueue>>, Self.Output> {

        return self.catch { error -> Publishers.Delay<Just<Self.Output>, DispatchQueue> in
            let delay = min(baseDelay * pow(2.0, Double(maxRetries)), maxDelay)
            return Just(self.output)
                .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
        }
        .tryMap { $0 }
    }

    /// Assigns to multiple KeyPaths simultaneously
    func assign<Root: AnyObject>(
        to keyPaths: [ReferenceWritableKeyPath<Root, Self.Output>],
        on object: Root
    ) -> AnyCancellable {
        return sink { value in
            keyPaths.forEach { keyPath in
                object[keyPath: keyPath] = value
            }
        }
    }
}

extension Publisher where Self.Failure == Never {
    /// Safely assigns to a property with weak capture
    func assignWeak<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
        on object: Root
    ) -> AnyCancellable {
        return sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

// MARK: - Custom Publishers

struct AsyncPublisher<Output>: Publisher {
    typealias Failure = Error

    private let asyncWork: () async throws -> Output

    init(_ asyncWork: @escaping () async throws -> Output) {
        self.asyncWork = asyncWork
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = AsyncSubscription(subscriber: subscriber, asyncWork: asyncWork)
        subscriber.receive(subscription: subscription)
    }
}

private class AsyncSubscription<Output, S: Subscriber>: Subscription
where S.Input == Output, S.Failure == Error {

    private var subscriber: S?
    private let asyncWork: () async throws -> Output
    private var task: Task<Void, Never>?

    init(subscriber: S, asyncWork: @escaping () async throws -> Output) {
        self.subscriber = subscriber
        self.asyncWork = asyncWork
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else { return }

        task = Task {
            do {
                let result = try await asyncWork()
                _ = subscriber?.receive(result)
                subscriber?.receive(completion: .finished)
            } catch {
                subscriber?.receive(completion: .failure(error))
            }
        }
    }

    func cancel() {
        task?.cancel()
        subscriber = nil
    }
}

// MARK: - Usage Examples for the codebase

extension AnyPublisher {
    static func fromAsync<Output>(_ asyncWork: @escaping () async throws -> Output) -> AnyPublisher<Output, Error> {
        return AsyncPublisher(asyncWork).eraseToAnyPublisher()
    }
}