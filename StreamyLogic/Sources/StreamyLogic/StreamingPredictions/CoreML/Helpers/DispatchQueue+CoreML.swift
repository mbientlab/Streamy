import Foundation

extension DispatchQueue {

    fileprivate static let coreMLQueueKey = DispatchSpecificKey<Int>()
    fileprivate static let coreMLQueueValue = 2222

    func markAsCoreMLQueue() {
        setSpecific(key: Self.coreMLQueueKey, value: Self.coreMLQueueValue)
    }

    static func assertOnCoreMLQueue() {
        assert(getSpecific(key: Self.coreMLQueueKey) == Self.coreMLQueueValue)
    }
}
