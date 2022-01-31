import Foundation
import simd
#if os(macOS)
import AppKit
#endif

// MARK: - Utilities Menu on macOS

public struct QuaternionDeltaCalculator {

    public static func computeDeltas(folders: [URL]) {
        DispatchQueue.global().async {
            let csvURLs = Finder.getCSVsInFolders(folders)
            let computedCSVs = csvURLs.compactMap(Finder.getCSVColumns).map(modify)
            zip(csvURLs, computedCSVs).forEach(Finder.writeCSV)
            Finder.openAndSelect(folders)
        }
    }

    /// Replace existing quaternion column with the delta between each row.
    /// Outer: Row. Inner: Columns.
    ///
    private static func modify(_ csv: [[String]]) -> [[String]] {
        guard let header = csv.first,
              header.suffix(4) == ["X", "Y", "Z", "W"],
              csv.indices.contains(1),
              var priorQuaternion = getQuaternion(in: csv[1])
        else { return csv }

        return csv
            .suffix(from: 2)
            .reduce(into: [header]) { newCSV, row in
                guard let rowQuaternion = getQuaternion(in: row) else { return }
                let delta = computeDelta(prior: priorQuaternion, current: rowQuaternion)
                let newRow = replaceQuaternion(inRow: row, with: delta)
                priorQuaternion = rowQuaternion
                newCSV.append(newRow)
        }
    }

    private static func computeDelta(prior: simd_quatd, current: simd_quatd) -> simd_quatd {
        current * prior.inverse
    }

    private static func getQuaternion(in row: [String]) -> simd_quatd? {
        let doubles = row.suffix(4).compactMap(Double.init)
        guard doubles.endIndex == 4 else { return nil }
        return simd_quatd(vector: .init(doubles))
    }

    private static func replaceQuaternion(inRow: [String], with quaternion: simd_quatd) -> [String] {
        var mutableRow = inRow
        let vector = quaternion.vector
        let columnQuaternion = [vector.x, vector.y, vector.z, vector.w].map { String(format: "%1.3f", $0) }
        mutableRow.replaceSubrange(mutableRow.indices.suffix(4), with: columnQuaternion)
        return mutableRow
    }
}

public struct Downsampler {

    public static func downsample(folders: [URL], divisibleBy offset: Int = 2) {
        DispatchQueue.global().async {
            let csvs = Finder.getCSVsInFolders(folders)
            csvs.forEach { downsample($0, divisibleBy: offset) }
            Finder.openAndSelect(folders)
        }
    }

    private static func downsample(_ csvURL: URL, divisibleBy offset: Int) {
        guard let csv = Finder.getCSVLines(csvURL) else { return }

        let downsampled = csv
            .enumerated()
            .reduce(into: "") { newCSV, line in
                if line.offset == 0 { newCSV += "\(line.element)\n"; return }
                guard line.offset % 2 == 0 else { return }
                newCSV += "\(line.element)\n"
            }

        Finder.writeCSV(string: downsampled, to: csvURL)
    }
}

// MARK: - Retrieve CSVs

struct Finder {

    static func getCSVsInFolders(_ folders: [URL]) -> [URL] {
        folders.reduce(into: [URL]()) { result, url in
            let csvs = try? FileManager.default
                .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
                .filter { $0.pathExtension == "csv" }
            result.append(contentsOf: csvs ?? [])
        }
    }

    static func getCSVLines(_ csvURL: URL) -> [String]? {
        guard let data = FileManager.default.contents(atPath: csvURL.path),
              let csv = String(data: data, encoding: .utf8)?.components(separatedBy: .newlines)
        else { return nil }
        return csv
    }

    static func getCSVColumns(_ csvURL: URL) -> [[String]]? {
        guard let lines = getCSVLines(csvURL) else { return nil }
        return lines.map { $0.components(separatedBy: ",") }
    }

    static func writeCSV(string: String, to url: URL) {
        try? string.data(using: .utf8)?.write(to: url, options: .atomic)
    }

    static func writeCSV(to url: URL, lines: [[String]]) {
        let csv = lines.map { $0.joined(separator: ",") }.joined(separator: "\n")
        writeCSV(string: csv, to: url)
    }

    static func openAndSelect(_ urls: [URL]) {
        #if os(macOS)
        DispatchQueue.main.async {
            NSWorkspace.shared.activateFileViewerSelecting(urls)
        }
        #endif
    }
}
