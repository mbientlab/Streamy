import Foundation
import MetaWear

public typealias CSVFile = (filename: String, csv: Data)

protocol CSVConverter {
    func convertToCSVs(_ dataTables: [MWDataTable], _ filenameTag: String) -> [CSVFile]
}

struct NoSplitConverter: CSVConverter {
    func convertToCSVs(_ dataTables: [MWDataTable], _ filenameTag: String) -> [CSVFile] {
        dataTables.map { table -> (String, Data) in
            let filename = [table.source.name, filenameTag].joined(separator: " ")
            let csv = table.makeCSV(delimiter: ",").data(using: .utf8)!
            return (filename, csv)
        }
    }
}

extension MWMechanicalButton.State {
    var opposite: Self { self == .up ? .down : .up }
}

struct ButtonPressSplitConverter: CSVConverter {

    var requireButtonPresses: Bool
    let startSignal: MWMechanicalButton.State
    let endSignal: MWMechanicalButton.State

    init(requireButtonPresses: Bool = true, startOn: MWMechanicalButton.State = .up) {
        self.requireButtonPresses = requireButtonPresses
        self.startSignal = startOn
        self.endSignal = startOn.opposite
    }
}

extension ButtonPressSplitConverter {

    func convertToCSVs(_ dataTables: [MWDataTable], _ filenamePrefix: String) -> [CSVFile] {
        guard let ranges = getRecordingRanges(fromButton: dataTables[...])
        else { return NoSplitConverter().convertToCSVs(dataTables, filenamePrefix) }

        return dataTables
            .flatMap { table -> [(Int, String, Data)] in
                guard table.source != .mechanicalButton else { return [] }
                let filename = [table.source.name, filenamePrefix].joined(separator: " ")
                return splitIntoMultipleCSVs(table, by: ranges)
                    .compactMap { $0.makeCSV(delimiter: ",").data(using: .utf8) }
                    .enumerated()
                    .map { ($0, filename, $1) }
            }
            .map { index, filename, data -> CSVFile in
                ("\(index) - " + filename, data)
            }
    }

    func splitIntoMultipleCSVs(_ dataTable: MWDataTable, by ranges: [ClosedRange<Double>]) -> [MWDataTable] {
        guard ranges.isEmpty == false, dataTable.rows.first?.isEmpty == false else { return [] }
        var index = 0
        var splits = [MWDataTable]()

        for range in ranges {
            var rowsInRange = [[String]]()


        findRows: while index < dataTable.rows.endIndex, let epoch = Double(dataTable.rows[index][0]) {
            if range.lowerBound > epoch {
                index += 1
                continue findRows

            } else if range.contains(epoch) {
                rowsInRange.append(dataTable.rows[index])
                index += 1
                continue findRows

            } else if range.upperBound < epoch {
                break findRows
            }
        }

            guard rowsInRange.isEmpty == false else { continue }
            let newTable = MWDataTable(source: dataTable.source, startDate: Date(), rows: rowsInRange)
            splits.append(newTable)
        }

        return splits.isEmpty ? (requireButtonPresses ? [] : [dataTable]) : splits
    }

    func getRecordingRanges(fromButton dataTables: ArraySlice<MWDataTable>) -> [ClosedRange<Double>]? {
        guard var rows = dataTables.first(where: { $0.source == .mechanicalButton })?.rows[0...]
        else { return nil }

        var ranges = [ClosedRange<Double>]()
        var start: Double? = nil
        var end: Double? = nil

        func epoch(of row: [String]) -> Double? {
            guard let first = row.first else { return nil }
            return Double(first)
        }

        /// Find ranges row by row
        while let row = rows.popFirst() {
            guard let last = row.last,
                  let state = MWMechanicalButton.State(rawValue: last.lowercased())
            else { continue }

            /// If without start date, find next "start" event
            guard let lower = start else {
                if state == startSignal {
                    start = epoch(of: row)
                }
                continue
            }

            /// If without end date, find next "end" event
            guard state == endSignal, end == nil else { continue }
            end = epoch(of: row)

            /// If have start and end date, assign a range and start over
            guard let upper = end else { continue }
            ranges.append((lower...upper))
            (start, end) = (nil, nil)
        }

        /// Assign open ended final range if needed
        if let lower = start, end == nil {
            ranges.append((lower...(.greatestFiniteMagnitude)))
        }

        /// Handle case where no ranges found
        let notFoundOption = self.requireButtonPresses ? [] : [(0...(.greatestFiniteMagnitude))]
        return ranges.isEmpty ? notFoundOption : ranges
    }
}
