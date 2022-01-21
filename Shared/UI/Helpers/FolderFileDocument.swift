import SwiftUI
import UniformTypeIdentifiers

struct Folder: FileDocument {
    static var readableContentTypes = [UTType.folder]
    let wrapper: FileWrapper
    var name: String

    init(url: URL, name: String) throws {
        self.name = name
        self.wrapper = try FileWrapper(url: url, options: [])
        guard wrapper.isDirectory else { throw CocoaError(.featureUnsupported) }
    }

    init(configuration: ReadConfiguration) throws {
        self.wrapper = configuration.file
        self.name = configuration.file.preferredFilename ?? "Untitled"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        wrapper
    }
}
