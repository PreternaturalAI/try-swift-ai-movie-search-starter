//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import UniformTypeIdentifiers

public struct _FileOrFolderSerializationConfiguration<Value> {
    let contentType: UTType?
    let coder: _AnyConfiguredFileCoder
    @ReferenceBox
    var initialValue: _ThrowingMaybeLazy<Value?>
    
    init(
        contentType: UTType?,
        coder: _AnyConfiguredFileCoder,
        initialValue: @escaping () throws -> Value
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    init(
        contentType: UTType?,
        coder: _AnyConfiguredFileCoder,
        initialValue: @escaping () throws -> Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
    
    init(
        contentType: UTType?,
        coder: _AnyConfiguredFileCoder,
        initialValue: Value?
    ) {
        self.contentType = contentType
        self.coder = coder
        self._initialValue = .init(.init(initialValue))
    }
}
