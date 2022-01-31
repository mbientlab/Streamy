import SwiftUI
import StreamyLogic

// Utilities for wrangling data you get from the MetaWear for CoreML.

struct DownsampleButton: View {

    @State private var showPicker = false
    var body: some View {
        Button("Downsample CSVs by 50%") { showPicker = true }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder], allowsMultipleSelection: true) { result in
            guard case let .success(urls) = result else { return }
            Downsampler.downsample(folders: urls)
        }
    }
}

struct ComputeDifferenceButton: View {

    @State private var showPicker = false
    var body: some View {
        Button("Compute Quaternion Deltas") { showPicker = true }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder], allowsMultipleSelection: true) { result in
            guard case let .success(urls) = result else { return }
            QuaternionDeltaCalculator.computeDeltas(folders: urls)
        }
    }
}
