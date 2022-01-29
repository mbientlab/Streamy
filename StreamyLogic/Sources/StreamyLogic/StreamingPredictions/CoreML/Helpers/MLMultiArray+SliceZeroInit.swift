import Foundation
import CoreML

extension MLMultiArray {

    /// Create 2D array
    convenience init(features: Int, windowWidth: Int, dataType: MLMultiArrayDataType) throws {
        try self.init(shape: [windowWidth, features] as [NSNumber], dataType: dataType)
        self.zeroOut()
    }

    /// Create 1D array
    convenience init(singleRowSize: Int, dataType: MLMultiArrayDataType) throws {
        try self.init(shape: [singleRowSize as NSNumber], dataType: dataType)
        self.zeroOut()
    }
}

extension MLMultiArray {

    /// Overwrite any data in an array with a zero
    func zeroOut() {
        for i in 0..<count {
            self[i] = 0 as NSNumber
        }
    }

    /// Slices a 1D array buffer into a one-dimensional MLFeatureProvider array
    func sliceValues(fromIndex: Int, width: Int) throws -> MLMultiArray {
        let offset = fromIndex * strides[0].intValue * MemoryLayout<Double>.stride
        return try MLMultiArray(
            dataPointer: dataPointer.advanced(by: offset),
            shape: [width] as [NSNumber],
            dataType: dataType,
            strides: strides
        )
    }

    /// Slices a 2D array buffer into a one-dimensional MLFeatureProvider array
    func sliceValues(inFeatureRow: Int, fromIndex: Int, width: Int) throws -> MLMultiArray {
        let strideIndex = 1
        let offset = fromIndex * strides[strideIndex].intValue * MemoryLayout<Double>.stride
        return try MLMultiArray(
            dataPointer: dataPointer.advanced(by: offset),
            shape: [width] as [NSNumber],
            dataType: dataType,
            strides: [strides[strideIndex]])
    }
}
