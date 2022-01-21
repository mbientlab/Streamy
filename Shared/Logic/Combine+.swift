import Foundation
import Combine

extension Publisher {

    /// Publish on DispatchQueue.main.
    ///
    func onMain() -> AnyPublisher<Output,Failure> {
        receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Erase output to void, publishing on DispatchQueue.main.
    ///
    func voidOnMain() -> AnyPublisher<(),Failure> {
        map { _ in () }.onMain()
    }
}

extension Publisher {

    /// Observe a published property's changes with a one-liner.
    ///
    /// ```
    /// @Published var whenDoesThisChange = false
    /// $whenDoesThisChange.debugPrint()
    /// ```
    ///
    func debugPrint(prefix: String = "-> ") {
        self
            .print(prefix, to: nil)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &debugs)
    }
}

fileprivate var debugs = Set<AnyCancellable>()

/// Stop-gap utility designed to be used by one parent object for its children to schedule tasks that might complete after they disappear.
///
class UnownedCancellableStore {

    private let queue: DispatchQueue
    private var storage: Set<AnyCancellable> = []

    var subs: Set<AnyCancellable> {
        get { queue.sync { storage } }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.storage = newValue
            }
        }
    }

    func releaseAll() {
        queue.sync(flags: .barrier) { storage = [] }
    }

    init(concurrentQueue: DispatchQueue = .init(label: "UnownedCancellableStore", qos: .background, attributes: .concurrent)) {
        self.queue = concurrentQueue
    }
}
