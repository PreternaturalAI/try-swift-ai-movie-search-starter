//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    public typealias ChildBundle<Contents: FileBundle> = _FileBundle_BundleProperty<Self, Contents>
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
class _KeyedFileBundleChildBundle<Bundle: FileBundle>: _KeyedFileBundleChildGenericBase<Bundle>, _FileBundleContainerElement, ObservableObject {
    private let configuration: () throws -> _RelativeFolderConfiguration<Contents>
    private var bundle: Bundle?
    private let bundleObjectWillChangeRelay = ObjectWillChangePublisherRelay()
    
    override var contents: Contents {
        get throws {
            try bundle.unwrap()
        }
    }
    
    override func setContents(_ contents: Bundle) throws {
        assertionFailure("You cannot reinitialize a file bundle.")
    }
    
    public override var knownFileURL: URL? {
        get throws {
            try parent?.knownFileURL?.appending(URL.PathComponent(rawValue: _fileName, isDirectory: true))
        }
    }
    
    @MainActor
    init?(
        parameters: InitializationParameters,
        configuration: @escaping () throws -> _RelativeFolderConfiguration<Contents>,
        uninitializedContents: Bundle?
    ) throws {
        self.configuration = configuration
        
        try super.init(parameters: parameters)
        
        let created = try createBundle(
            readOptions: parameters.readOptions,
            proposedBundle: uninitializedContents,
            existingFileWrapper: parameters.existingFileWrapper
        )
        
        guard created else {
            if parameters.readOptions.contains(.createIfNeeded) {
                throw _FileBundleError.keyedBundleCreationFailed
            }
            
            return nil
        }
        
        try refresh()
    }
    
    override func refresh() throws {
        if bundle == nil {
            try createBundle(readOptions: [])
        }
        
        bundleObjectWillChangeRelay.source = self.bundle
        bundleObjectWillChangeRelay.destination = self
    }
    
    @discardableResult
    private func createBundle(
        readOptions: Set<FileDocumentReadOption>,
        proposedBundle: Bundle? = nil,
        existingFileWrapper: _AsyncFileWrapper? = nil
    ) throws -> Bool {
        let configuration = try self.configuration()
        
        preferredFileName = configuration.path
        
        self.fileWrapper = try existingFileWrapper ?? parent.unwrap().fileWrapper?.fileWrappers.unwrap()[_fileName]
        
        if self.fileWrapper == nil {
            guard readOptions.contains(.createIfNeeded) else {
                return false
            }
            
            self.fileWrapper = _AsyncFileWrapper(directoryWithFileWrappers: [:])
            self.fileWrapper!.preferredFileName = self._fileName
        }
        
        bundle = try proposedBundle ?? Bundle(
            parameters: .init(
                parent: enclosingInstance,
                file: _FileRepresentingFileWrapper(fileWrapper.unwrap(), id: self.id),
                readOptions: readOptions,
                owner: self
            )
        )
        
        bundle = try _withLogicalParent(enclosingInstance) {
            bundle
        }
        
        guard bundle != nil else {
            return false
        }
        
        return true
    }
    
    func childDidUpdate(_ node: _FileBundleChild) {
        parent?.childDidUpdate(self)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    @MainActor
    func _createKeyedFileBundleChildWithUnitializedSelf(
        enclosingInstance: (any FileBundle)?,
        parent: any _FileBundleContainerElement,
        key: String,
        existingFileWrapper: _AsyncFileWrapper?
    ) throws -> (any _FileBundleContainerElement)? {
        try _KeyedFileBundleChildBundle(
            parameters: .init(
                enclosingInstance: enclosingInstance,
                parent: parent,
                key: key,
                readOptions: [.createIfNeeded],
                existingFileWrapper: existingFileWrapper
            ),
            configuration: {
                .init(
                    path: nil,
                    initialValue: nil
                )
            },
            uninitializedContents: self
        )
    }
}
