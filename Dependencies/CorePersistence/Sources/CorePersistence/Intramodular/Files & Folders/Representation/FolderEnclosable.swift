//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import UniformTypeIdentifiers

/// A resource that can be completely enclosed within a folder.
public protocol FolderEnclosable {
    var topLevelFileContents: [URL.PathComponent] { get throws }
}

public struct FilenameProvider: CustomFilenameConvertible {
    public var name: String
    
    public var filenameProvider: FilenameProvider {
        self
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public func filename(
        inDirectory url: URL
    ) -> String {
        name
    }
}

public protocol CustomFilenameConvertible {
    var filenameProvider: FilenameProvider { get }
}

extension UUID: CustomFilenameConvertible {
    public var filenameProvider: FilenameProvider {
        FilenameProvider(name: description)
    }
}

extension _TypeAssociatedID: CustomFilenameConvertible where RawValue: CustomFilenameConvertible {
    public var filenameProvider: FilenameProvider {
        rawValue.filenameProvider
    }
}
