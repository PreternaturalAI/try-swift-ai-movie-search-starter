//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct _KeyedFileBundleChildConfiguration {
    weak var enclosingInstance: (any FileBundle)?
    
    let parent: any _FileBundleContainerElement
    let key: String
    let readOptions: Set<FileDocumentReadOption>
    let existingFileWrapper: _AsyncFileWrapper?
    
    init(
        enclosingInstance: (any FileBundle)?,
        parent: any _FileBundleContainerElement,
        key: String,
        readOptions: Set<FileDocumentReadOption>,
        existingFileWrapper: _AsyncFileWrapper? = nil
    ) {
        self.enclosingInstance = enclosingInstance
        self.parent = parent
        self.key = key
        self.readOptions = readOptions
        self.existingFileWrapper = existingFileWrapper
    }
}

enum _KeyedFileBundleChildStateFlag {
    case deletedByParent
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
protocol _KeyedFileBundleChild<Contents>: _FileBundleChild {
    associatedtype Contents
    
    typealias InitializationParameters = _KeyedFileBundleChildConfiguration
    typealias StateFlags = Set<_KeyedFileBundleChildStateFlag>
    
    var parent: (any _FileBundleContainerElement)? { get }
    
    var key: String { get }
    var stateFlags: StateFlags { get set }
    var preferredFileName: String? { get }
    
    var contents: Contents { get throws }
    
    func setContents(_ contents: Contents) throws
    
    func refresh() throws
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _KeyedFileBundleChild {
    var _fileName: String {
        preferredFileName ?? key
    }
    
    func _assertParentChildFileWrapperConsistency() {
        if let parentFileWrapper = parent?.fileWrapper, let fileWrapper {
            assert(parentFileWrapper.contains(fileWrapper))
        }
    }
    
    func _removeFileWrapperFromParent(
        forReplacementWith replacement: _AsyncFileWrapper?
    ) throws {
        guard let parentFileWrapper = parent?.fileWrapper else {
            return
        }
        
        if let fileWrapper {
            parentFileWrapper.removeFileWrapper(fileWrapper)
        } else {
            if let existingWrapper = parentFileWrapper.fileWrappers?[_fileName] {
                do {
                    try _tryAssert(existingWrapper === replacement)
                } catch {
                    if existingWrapper.isDirectory, replacement == nil {
                        return // forgive and forget
                    }
                }
            }
        }
    }
    
    func _addFileWrapperToParent() throws {
        if let fileWrapper, let parentFileWrapper = parent?.fileWrapper {
            if parentFileWrapper.isDirectory {
                assert(parentFileWrapper.fileWrappers.isNotNil)
            }
            
            let existing = parentFileWrapper.fileWrappers![_fileName]
            
            guard existing == nil else {
                assert(existing!.preferredFileName == fileWrapper.preferredFileName)
                
                parentFileWrapper.removeFileWrapper(existing!)
                parentFileWrapper.addFileWrapper(fileWrapper)
                
                // assert(parentFileWrapper.fileWrappers![_fileName] == fileWrapper)
                
                return
            }
            
            if fileWrapper.preferredFileName == nil {
                fileWrapper.preferredFileName = _fileName
            }
            
            parentFileWrapper.addFileWrapper(fileWrapper)
            
            cleanUpFileWrapper()
        } else {
            assertionFailure()
        }
    }
    
    private func cleanUpFileWrapper() {
        guard let fileWrapper = fileWrapper else {
            return
        }
        
        if fileWrapper.isDirectory {
            if let dsStoreFile = fileWrapper.fileWrappers?[".DS_Store"] {
                fileWrapper.removeFileWrapper(dsStoreFile)
            }
        }
    }
}
