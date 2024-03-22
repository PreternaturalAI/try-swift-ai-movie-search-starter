//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
class _KeyedFileBundleChildGenericBase<Contents>: Identifiable, _KeyedFileBundleChild {
    private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
    
    let id: AnyHashable = UUID()
    
    weak private(set) var enclosingInstance: (any FileBundle)?
    weak private(set) var parent: (any _FileBundleContainerElement)?
    
    let key: String
    
    var fileWrapper: _AsyncFileWrapper? {
        willSet {
            guard fileWrapper != newValue else {
                return
            }
            
            _expectNoThrow {
                try _removeFileWrapperFromParent(forReplacementWith: newValue)
            }
        } didSet {
            guard oldValue !== fileWrapper else {
                return
            }
            
            _expectNoThrow {
                try _addFileWrapperToParent()
            }
        }
    }
    
    var knownFileURL: URL? {
        get throws {
            fatalError(.abstract)
        }
    }
    
    var preferredFileName: String?
    var stateFlags: StateFlags
    
    @MainActor
    var contents: Contents {
        get throws {
            fatalError(.abstract)
        }
    }
    
    @MainActor
    func setContents(_ contents: Contents) throws {
        fatalError(.abstract)
    }
    
    init?(parameters: InitializationParameters) throws {
        self.enclosingInstance = parameters.enclosingInstance
        self.parent = parameters.parent
        self.key = parameters.key
        self.stateFlags = []
        
        objectWillChangeRelay.source = self
        objectWillChangeRelay.destination = parent
    }
    
    @MainActor
    func refresh() throws {
        
    }
}
