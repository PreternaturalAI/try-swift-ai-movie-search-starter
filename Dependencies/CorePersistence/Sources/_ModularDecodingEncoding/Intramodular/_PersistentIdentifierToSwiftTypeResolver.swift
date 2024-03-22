//
// Copyright (c) Vatsal Manot
//

import _CoreIdentity
import Foundation
import Runtime
import Swallow

/// A type that converts a persistent identifier into a Swift type.
///
/// This type is a work-in-progress. Do not use this type directly in your code.
public protocol _PersistentIdentifierToSwiftTypeResolver<Input, Output> {
    associatedtype Input: PersistentIdentifier
    associatedtype Output: _StaticSwiftType
    
    func resolve(from _: Input) throws -> Output?
}

public protocol _StaticSwiftTypeToPersistentIdentifierResolver<Input, Output> {
    associatedtype Input: _StaticSwiftType
    associatedtype Output: PersistentIdentifier
    
    func resolve(from input: Input) throws -> Output?
}
