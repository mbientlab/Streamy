import XCTest
@testable import StreamyLogic
import MetaWear
import SwiftUI

final class ButtonPressCSVTests: XCTestCase {

    // MARK: - End to End

    func test_Splits_NoButton_FallsbackToNoSplitCSV() {
        let testCase = [
            makeFakeDataTablePressure(timeRanges: (0...5)),
            makeFakeDataTableAmbientLight(timeRanges: (1...6)),
        ]
        let sut = ButtonPressSplitConverter(requireButtonPresses: false).convertToCSVs
        let result = sut(testCase, "DATE")
        let filenamePrefixes = result.map(\.filename).compactMap { Int($0.prefix(1)) }
        let filenameSuffixes = result.map(\.filename).compactMap { $0.suffix(4) }
        XCTAssertEqual(result.endIndex, 2)
        XCTAssertEqual(filenamePrefixes, [])
        XCTAssertTrue(filenameSuffixes.allSatisfy({ $0 == "DATE" }))
    }

    func test_Splits_ThreeSensors_TwoRanges_IntoSixFiles() {
        let testCase = [
            makeFakeDataTablePressure(timeRanges: (0...5)),
            makeFakeDataTableAmbientLight(timeRanges: (1...6)),
            makeFakeDataTableMechanicalButton([
                (0 , .down),
                (1 , .up),
                (2 , .down),
                (5 , .up),
                (6 , .down),
            ])
        ]
        let sut = ButtonPressSplitConverter(requireButtonPresses: true).convertToCSVs
        let result = sut(testCase, "DATE")
        let filenamePrefixes = result.map(\.filename).compactMap { Int($0.prefix(1)) }
        let filenameSuffixes = result.map(\.filename).compactMap { $0.suffix(4) }
        XCTAssertEqual(result.endIndex, 4)
        XCTAssertEqual(filenamePrefixes, [0, 1, 0, 1])
        XCTAssertTrue(filenameSuffixes.allSatisfy({ $0 == "DATE" }))
    }

    func test_Splits_ThreeSensors_RequireButtonPresses_NoValidRanges_IntoZeroFiles() {
        let testCase = [
            makeFakeDataTablePressure(timeRanges: (0...5)),
            makeFakeDataTableAmbientLight(timeRanges: (1...6)),
            makeFakeDataTableMechanicalButton([
                (10 , .down),
                (11 , .up),
                (12 , .down),
                (15 , .up),
                (16 , .down),
            ])
        ]
        let sut = ButtonPressSplitConverter(requireButtonPresses: true).convertToCSVs
        let result = sut(testCase, "DATE")
        XCTAssertEqual(result.endIndex, 0)
    }

    func test_Splits_ThreeSensors_DoNotRequireButtonPresses_NoValidRanges_IntoTwoFiles() {
        let testCase = [
            makeFakeDataTablePressure(timeRanges: (0...5)),
            makeFakeDataTableAmbientLight(timeRanges: (1...6)),
            makeFakeDataTableMechanicalButton([
                (10 , .down),
                (11 , .up),
                (12 , .down),
                (15 , .up),
                (16 , .down),
            ])
        ]
        let sut = ButtonPressSplitConverter(requireButtonPresses: false).convertToCSVs
        let result = sut(testCase, "DATE")
        XCTAssertEqual(result.endIndex, 2)
    }

    // MARK: - CSVs Only

    func test_Splits_EmptyRange_IntoZeroFiles() {
        let testCase = makeFakeDataTablePressure(timeRanges: 0...5)
        let testRanges = [ClosedRange<Double>]()
        let expFiles = 0
        let sut = ButtonPressSplitConverter(requireButtonPresses: false).splitIntoMultipleCSVs
        let result = sut(testCase, testRanges)
        XCTAssertEqual(result.endIndex, expFiles)
    }

    func test_Splits_InfiniteRange_IntoOneFile() {
        let testCase = makeFakeDataTablePressure(timeRanges: 0...5)
        let testRanges = [0...(.greatestFiniteMagnitude)]
        let exp: [[Double]] = makeEpochExp((0...5))
        let sut = ButtonPressSplitConverter(requireButtonPresses: false).splitIntoMultipleCSVs
        let result = sut(testCase, testRanges)
        XCTAssertEqual(result.endIndex, exp.endIndex)
        XCTAssertEqual(getEpochs(of: result), exp)
    }

    func test_Splits_ThreeValidRanges_IntoThreeFiles() {
        let testCase = makeFakeDataTablePressure(timeRanges: 0...10)
        let testRanges = [2...3, 4...5, 10...(.greatestFiniteMagnitude)]
        let exp: [[Double]] = makeEpochExp(2...3, 4...5, 10...10)
        let sut = ButtonPressSplitConverter(requireButtonPresses: false).splitIntoMultipleCSVs
        let result = sut(testCase, testRanges)
        XCTAssertEqual(result.endIndex, exp.endIndex)
        XCTAssertEqual(getEpochs(of: result), exp)
    }

    func test_Splits_OutOfRangeLow_IntoZeroFiles() {
        let testCase = makeFakeDataTablePressure(timeRanges: 1...10)
        let testRanges = [(-Double.greatestFiniteMagnitude)...0]
        let exp: [[Double]] = [[Double]]()
        let sut = ButtonPressSplitConverter(requireButtonPresses: true).splitIntoMultipleCSVs
        let result = sut(testCase, testRanges)
        XCTAssertEqual(result.endIndex, exp.endIndex)
        XCTAssertEqual(getEpochs(of: result), exp)
    }

    func test_Splits_OutOfRangeHigh_IntoZeroFiles() {
        let testCase = makeFakeDataTablePressure(timeRanges: 0...10)
        let testRanges = [11...(.greatestFiniteMagnitude)]
        let exp: [[Double]] = [[Double]]()
        let sut = ButtonPressSplitConverter(requireButtonPresses: true).splitIntoMultipleCSVs
        let result = sut(testCase, testRanges)
        XCTAssertEqual(result.endIndex, exp.endIndex)
        XCTAssertEqual(getEpochs(of: result), exp)
    }

    func test_Splits_OneValidTwoInvalidRanges_IntoOneFile() {
        let testCase = makeFakeDataTablePressure(timeRanges: 0...10)
        let testRanges = [9...10, 11...12, 15...(.greatestFiniteMagnitude)]
        let exp: [[Double]] = makeEpochExp(9...10)
        let sut = ButtonPressSplitConverter(requireButtonPresses: true).splitIntoMultipleCSVs
        let result = sut(testCase, testRanges)
        XCTAssertEqual(result.endIndex, exp.endIndex)
        XCTAssertEqual(getEpochs(of: result), exp)
    }

    // MARK: - Ranges Only

    func test_Parses_EmptyStream_PressesRequired_AsEmptyRange() throws {
        let testCase: [MWDataTable]    = [ makeFakeDataTableMechanicalButton([]) ]
        let exp: [ClosedRange<Double>] = [ ]
        let sut = ButtonPressSplitConverter().getRecordingRanges
        let result = try XCTUnwrap(sut(testCase[...]))
        XCTAssertEqual(result, exp)
    }

    func test_Parses_EmptyStream_NoPressesRequired_AsNoTimeRestrictionOneCSV() throws {
        let testCase: [MWDataTable]    = [ makeFakeDataTableMechanicalButton([]) ]
        let exp: [ClosedRange<Double>] = [ 0...(.greatestFiniteMagnitude) ]
        let sut = ButtonPressSplitConverter(requireButtonPresses: false).getRecordingRanges
        let result = try XCTUnwrap(sut(testCase[...]))
        XCTAssertEqual(result, exp)
    }

    func test_Parses_OpenEndedStream_AsNoEndTimeRestriction() throws {
        let testCase: [MWDataTable] =    [ makeFakeDataTableMechanicalButton([ (13.55, .up) ]) ]
        let exp: [ClosedRange<Double>] = [ 13.55...(.greatestFiniteMagnitude) ]
        let sut = ButtonPressSplitConverter().getRecordingRanges
        let result = try XCTUnwrap(sut(testCase[...]))
        XCTAssertEqual(result, exp)
    }

    func test_Parses_ComplexButtonStream_SkippingRepeats() throws {
        let testCase: [MWDataTable] = [makeFakeDataTableMechanicalButton([
            (0 , .down),
            (1 , .down),
            (2 , .down),
            (3 , .up),
            (4 , .down),
            (5 , .up),
            (6 , .down),
            (7 , .up),
            (8 , .down),
            (9 , .down),
            (10, .up),
            (11, .up),
            (12, .down),
            (13, .up),
        ])]
        let exp: [ClosedRange<Double>] = [
            3...4, 5...6, 7...8, 10...12, 13...(.greatestFiniteMagnitude)
        ]
        let sut = ButtonPressSplitConverter().getRecordingRanges

        let result = try XCTUnwrap(sut(testCase[...]))
        XCTAssertEqual(result, exp)
    }
}

private func makeEpochExp(_ ranges: ClosedRange<Int>...) -> [[Double]] {
    ranges.map { $0.map { Double($0) } }
}

private func getEpochs(of tables: [MWDataTable]) -> [[Double]] {
    tables.map { $0.rows.compactMap { Double($0[0]) } }
}

private func makeFakeDataTable<S: MWPollable>(timeRanges: ClosedRange<Int>, _ s: S) -> MWDataTable where S.DataType == Float {
    let data = timeRanges.map { time -> (Date, Float) in
        (.init(timeIntervalSince1970: .init(time)), .init(time) )
    }
    return .init(streamed: data, s, startDate: .init(timeIntervalSince1970: 0))
}

private func makeFakeDataTableMechanicalButton(_ events: [(Double, MWMechanicalButton.State)]) -> MWDataTable {
    .init(streamed: events.map { (.init(timeIntervalSince1970: $0), $1) },
          .mechanicalButton, startDate: .init(timeIntervalSince1970: 0))
}

private func makeFakeDataTableAmbientLight(timeRanges: ClosedRange<Int>) -> MWDataTable {
    makeFakeDataTable(timeRanges: timeRanges, .humidity())
}

private func makeFakeDataTablePressure(timeRanges: ClosedRange<Int>) -> MWDataTable {
    makeFakeDataTable(timeRanges: timeRanges, MWThermometer(rate: .every10min, type: .bmp280, channel: 1))
}
