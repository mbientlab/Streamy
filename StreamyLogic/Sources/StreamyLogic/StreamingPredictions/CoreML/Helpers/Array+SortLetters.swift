import Foundation
import CoreML

public  extension Array where Element == String {
    var sortedByLetter: Self {
        sorted(by: { lhs, rhs in
            guard lhs.endIndex == rhs.endIndex else  {
                return lhs.endIndex < rhs.endIndex
            }
            return lhs < rhs
        })
    }
}

public extension Array where Element == (String, Double) {
    var sortedByLetter: Self {
        sorted(by: { lhs, rhs in
            guard lhs.0.endIndex == rhs.0.endIndex else  {
                return lhs.0.endIndex < rhs.0.endIndex
            }
            return lhs.0 < rhs.0
        })
    }
}

