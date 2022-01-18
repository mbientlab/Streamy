import SwiftUI
import UniformTypeIdentifiers

public struct Folder: FileDocument {
    public static var readableContentTypes = [UTType.folder]
    public let wrapper: FileWrapper
    public var name: String

    public init(url: URL, name: String) throws {
        self.name = name
        self.wrapper = try FileWrapper(url: url, options: [])
        guard wrapper.isDirectory else { throw CocoaError(.featureUnsupported) }
    }

    public init(configuration: ReadConfiguration) throws {
        self.wrapper = configuration.file
        self.name = configuration.file.preferredFilename ?? "Untitled"
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        wrapper
    }
}
