//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

extension _FileStorageCoordinators {
    public final class Directory<Item, ID: Hashable>: _AnyFileStorageCoordinator<_ObservableIdentifiedFolderContents<Item, ID>, _ObservableIdentifiedFolderContents<Item, ID>.WrappedValue> {
        public typealias Base = _ObservableIdentifiedFolderContents<Item, ID>
        
        @MainActor
        @PublishedObject var base: Base
        
        @MainActor
        public var _hasReadWithLogicalParentAtLeastOnce = false
        
        @MainActor(unsafe)
        public override var wrappedValue: _ObservableIdentifiedFolderContents<Item, ID>.WrappedValue {
            get {
                guard _hasReadWithLogicalParentAtLeastOnce else {
                    guard let _enclosingInstance else {
                        return base.wrappedValue
                    }
                    
                    return try! _withLogicalParent(_enclosingInstance) {
                        base.wrappedValue
                    }
                }
                
                return base.wrappedValue
            } set {
                _expectNoThrow {
                    try _withLogicalParent(_enclosingInstance) {
                        base.wrappedValue = newValue
                    }
                }
            }
        }
        
        @MainActor
        public init(
            base: Base
        ) throws {
            self.base = base
            
            try super.init(
                fileSystemResource: FileURL(try base.folderURL),
                configuration: .init(
                    path: nil,
                    serialization: .init(
                        contentType: nil,
                        coder: _AnyConfiguredFileCoder(rawValue: .topLevelData(.topLevelDataCoder(JSONCoder(), forType: Never.self))),
                        initialValue: nil
                    ),
                    readWriteOptions: .init(
                        readErrorRecoveryStrategy: .discardAndReset
                    )
                )
            )
        }
        
        override public func commit() {
            // do nothing
        }
    }
}
