//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

enum _FileBundleError: Error {
    case fileWrapperMissing
    case annotationInitializationFailed
    case keyedFileCreationFailed
    case keyedBundleCreationFailed
    case failedToInitializeKeyedChild
}

public protocol _FileBundle: _HasPlaceholder {
    
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public protocol FileBundle: _FileBundle, AnyObject, _HasPlaceholder, ObservableObject {
    /// Perform a one-time setup.
    ///
    /// This method will be removed in a future release, it's a temporary workaround until more powerful primitives are introduced.
    func _load() throws
}

// MARK: - Implementation

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    public func _load() throws {
        // do nothing
    }
}
