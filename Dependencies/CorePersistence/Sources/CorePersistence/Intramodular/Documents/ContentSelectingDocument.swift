//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol ContentSelectingDocument {
    /// Could be a page of a PDF, a markdown section, a portion of a CSV document.
    associatedtype ContentSelection
}

/// A marked up document suitable for embedding/LLM query.
public protocol AugmentedDocumentContent: ContentSelectingDocument {
    associatedtype Source: ContentSelectingDocument
    associatedtype Data
    
    var data: Data { get }
    
    init(source: ContentSelection, data: Data)
    
    /// Get the source's verbatim content selection.
    ///
    /// Does not need to map 1:1, returned content-span can be a larger/more general region.
    subscript(_ selection: ContentSelection) -> Source.ContentSelection { get }
}
