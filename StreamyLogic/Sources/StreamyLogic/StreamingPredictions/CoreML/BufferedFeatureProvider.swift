import Foundation
import CoreML

// MARK: - Providing CoreML Data from the Input Buffer

/// CoreML prediction windows may span a second or two, but the user expects the app to:
/// (1) react faster than once per second
/// (2) not miss activity signatures that occur between two windows or with conflicting signatures within one window
///
/// To do so, we need to hold a buffer and kickoff predictions at shorter intervals, such that predictions correspond to overlapping time intervals. The CoreML interface for obtaining data for a prediction, however, isn't built for buffered input. (It just directly asks for data for a feature, without any sort of buffer index flag.)
///
/// This class interfaces with CoreML while referencing a parent object that sorts out slicing the buffer data into the right window size for CoreML.
///
class BufferedFeatureProvider: MLFeatureProvider {

    /// Tells the parent which slice of the buffer is relevant
    let slidingWindowIndex: Int

    /// Data buffer holder
    weak var parent: ParentMLFeatureProvider?

    /// Feature names CoreML can ask for
    let featureNames: Set<String>

    init(slidingWindowIndex: Int, parent: ParentMLFeatureProvider) {
        self.slidingWindowIndex = slidingWindowIndex
        self.parent = parent
        self.featureNames = parent.inputFeatureNames
    }

    /// CoreML MLFeatureProvider requirement
    func featureValue(for featureName: String) -> MLFeatureValue? {
        parent?.getFeature(named: featureName, forSlidingWindow: slidingWindowIndex)
    }
}

/// Parent buffer holder that can slice data for presentation to CoreML at higher frequency than the model window would ordinarily fill
///
protocol ParentMLFeatureProvider: AnyObject {
    var inputFeatureNames: Set<String> { get }
    func getFeature(named: String, forSlidingWindow: Int) -> MLFeatureValue?
}
