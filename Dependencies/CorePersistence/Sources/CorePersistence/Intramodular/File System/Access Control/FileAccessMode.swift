//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public enum FileAccessMode: Hashable {
    case read
    case write
    case update
}

public protocol FileAccessModeType: _StaticValue {
    static var value: FileAccessMode { get }
}

public protocol FileAccessModeTypeForWriting: FileAccessModeType {
    static var value: FileAccessMode { get }
}

public protocol FileAccessModeTypeForReading: FileAccessModeType {
    static var value: FileAccessMode { get }
}

// MARK: - Conformances

public enum FileAccessModes {
    public struct ReadAccess: FileAccessModeTypeForReading {
        public static let value: FileAccessMode = .read
        
        public init() {
            
        }
    }
    
    public struct WriteAccess: FileAccessModeTypeForWriting {
        public static let value: FileAccessMode = .write
        
        public init() {
            
        }
    }
    
    public struct UpdateAccess: FileAccessModeTypeForUpdating {
        public static let value: FileAccessMode = .update
        
        public init() {
            
        }
    }
}

extension FileAccessModeType where Self == FileAccessModes.ReadAccess {
    public static var read: Self {
        Self()
    }
}

extension FileAccessModeType where Self == FileAccessModes.WriteAccess {
    public static var write: Self {
        Self()
    }
}

extension FileAccessModeType where Self == FileAccessModes.UpdateAccess {
    public static var update: Self {
        Self()
    }
}

// MARK: - Auxiliary

extension FileHandle {
    public convenience init(forURL url: URL, accessMode mode: FileAccessMode) throws {
        switch mode {
            case .read:
                try self.init(forReadingFrom: url)
            case .write:
                try self.init(forWritingTo: url)
            case .update:
                try self.init(forUpdating: url)
        }
    }
}

// MARK: - Auxiliary

public typealias FileAccessModeTypeForUpdating = FileAccessModeTypeForReading & FileAccessModeTypeForWriting
