//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct _FileRepresentingFileWrapper<ID: Hashable>: _FileOrFolderRepresenting {
    public typealias Child = _FileRepresentingFileWrapper
    
    public private(set) var base: _AsyncFileWrapper
    
    public let id: ID
    
    public init(
        _ base: _AsyncFileWrapper,
        id: ID
    ) {
        self.base = base
        self.id = id
    }
    
    public init(_ base: _AsyncFileWrapper) where ID == AnyHashable {
        self.init(base, id: UUID())
    }
    
    public init<T>(
        contents: T,
        coder: _AnyConfiguredFileCoder,
        id: ID,
        preferredFileName: String
    ) throws {
        self.init(
            _AsyncFileWrapper(
                regularFileWithContents: .init(),
                preferredFileName: preferredFileName
            ),
            id: id
        )
        
        try encode(contents, using: coder)
    }
    
    public func _toURL() throws -> URL {
        throw Never.Reason.unimplemented
    }
    
    public func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        if !base.isDirectory, base.regularFileContents?.isEmpty == true {
            return nil
        }
        
        switch coder.rawValue {
            case .document(let documentType):
                return try documentType.init(configuration: .init(file: base, url: nil))
            case .topLevelData(let coder):
                guard let data = base.regularFileContents else {
                    return nil
                }
                
                return try coder.decode(from: data)
        }
    }
    
    public mutating func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        guard let preferredFileName = base.preferredFileName else {
            assertionFailure()
            
            return
        }
        
        guard !_isValueNil(contents) else {
            let newFileWrapper = _AsyncFileWrapper(regularFileWithContents: Data())
            
            newFileWrapper.preferredFileName = preferredFileName
            
            self.base = newFileWrapper
            
            return
        }
        
        switch coder.rawValue {
            case .document(let documentType):
                let newFileWrapper = try _AsyncFileWrapper(
                    documentType._opaque_fileWrapper(
                        for: contents,
                        configuration: .init(existingFile: base, url: nil)
                    )
                )
                
                newFileWrapper.preferredFileName = base.preferredFileName
                
                self.base = newFileWrapper
            case .topLevelData(let coder):
                let data = try coder.encode(contents)
                
                let newFileWrapper = _AsyncFileWrapper(regularFileWithContents: data)
                
                newFileWrapper.preferredFileName = preferredFileName
                
                self.base = newFileWrapper
        }
    }
    
    public func streamChildren() throws -> AsyncThrowingStream<AnyAsyncSequence<Child>, Error> {
        throw Never.Reason.illegal
    }
    
    public func child(
        at path: String
    ) throws -> Child {
        throw Never.Reason.illegal
    }
}
