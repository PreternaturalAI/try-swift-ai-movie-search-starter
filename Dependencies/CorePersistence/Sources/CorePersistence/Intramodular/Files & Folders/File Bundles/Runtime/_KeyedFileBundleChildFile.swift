//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    public typealias File<Contents> = _FileBundle_KeyedFileProperty<Self, Contents>
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
class _KeyedFileBundleChildFile<Contents>: _KeyedFileBundleChildGenericBase<Contents>, _FileOrFolderRepresenting, ObservableObject {
    private var wantsCreation: Bool = false
    private let configuration: () throws -> _RelativeFileConfiguration<Contents>
    
    private var coordinator: FileStorage<MutableValueBox<Contents>, Contents>.Coordinator?
    private let coordinatorObjectWillChangeRelay = ObjectWillChangePublisherRelay()
    
    @MainActor
    override var contents: Contents {
        get {
            try! getFileCoordinator().wrappedValue
        }
    }
    
    override func setContents(_ contents: Contents) throws {
        try getFileCoordinator().wrappedValue = contents
    }
    
    override var knownFileURL: URL? {
        get throws {
            try parent?.knownFileURL?.appending(URL.PathComponent(rawValue: _fileName, isDirectory: nil))
        }
    }
    
    init?(
        parameters: InitializationParameters,
        configuration: @escaping () throws -> _RelativeFileConfiguration<Contents>
    ) throws {
        self.wantsCreation = parameters.readOptions.contains(.createIfNeeded)
        self.configuration = configuration
        
        try super.init(parameters: parameters)
        
        guard try acquireFileWrapper(readOptions: parameters.readOptions) else {
            return nil
        }
    }
    
    @discardableResult
    private func acquireFileWrapper(
        readOptions: Set<FileDocumentReadOption>
    ) throws -> Bool {
        var configuration = try self.configuration()
        let relativeFilePath = try? configuration.consumePath()
        
        self.fileWrapper = try parent.unwrap().fileWrapper?.fileWrappers.unwrap()[relativeFilePath ?? key]
        
        preferredFileName = relativeFilePath
        
        if self.fileWrapper == nil, wantsCreation {
            let initialValue: Contents
            
            initialValue = try configuration.serialization.initialValue().unwrap()
            
            self.fileWrapper = try _FileRepresentingFileWrapper(
                contents: initialValue,
                coder: configuration.serialization.coder,
                id: self.id,
                preferredFileName: _fileName
            )
            .base
            
            wantsCreation = false
        }
        
        if self.fileWrapper == nil, !readOptions.contains(.createIfNeeded) {
            throw _FileBundleError.keyedFileCreationFailed
        }
        
        _assertParentChildFileWrapperConsistency()
        
        return true
    }
    
    override func refresh() throws {
        if coordinator == nil {
            try _refreshFileCoordinator()
        }
        
        _assertParentChildFileWrapperConsistency()
    }
    
    @MainActor
    func getFileCoordinator() throws -> FileStorage<MutableValueBox<Contents>, Contents>.Coordinator {
        try coordinator ?? _refreshFileCoordinator()
    }
    
    @MainActor
    @discardableResult
    func _refreshFileCoordinator() throws -> FileStorage<MutableValueBox<Contents>, Contents>.Coordinator {
        var latestConfiguration = try configuration()
        
        latestConfiguration.readWriteOptions.readErrorRecoveryStrategy = .fatalError
        
        let relativeFilePath = try? latestConfiguration.consumePath()
        
        preferredFileName = relativeFilePath
        
        if let existingCoordinator = coordinator {
            guard existingCoordinator.configuration.isEqual(to: latestConfiguration) == false else {
                return existingCoordinator
            }
        }
        
        coordinator = try _FileStorageCoordinators.RegularFile(
            fileSystemResource: self,
            configuration: latestConfiguration,
            cache: InMemorySingleValueCache()
        )
        
        coordinatorObjectWillChangeRelay.source = coordinator
        coordinatorObjectWillChangeRelay.destination = self
        
        _assertParentChildFileWrapperConsistency()
        
        return try coordinator.unwrap()
    }
    
    func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        guard let fileWrapper else {
            if wantsCreation {
                return try coordinator?.configuration.serialization.initialValue()
            } else {
                return nil
            }
        }
        
        let id = self.id
        let file = _FileRepresentingFileWrapper(fileWrapper, id: id)
        
        wantsCreation = false
        
        _assertParentChildFileWrapperConsistency()
        
        return try file.decode(using: coder)
    }
    
    func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        guard !stateFlags.contains(.deletedByParent) else {
            return
        }
        
        guard let fileWrapper else {
            throw _FileBundleError.fileWrapperMissing
        }
        
        let id = self.id
        var file = _FileRepresentingFileWrapper(fileWrapper, id: id)
        
        try file.encode(contents, using: coder)
        
        self.fileWrapper = file.base
        
        parent?.childDidUpdate(self)
    }
}
