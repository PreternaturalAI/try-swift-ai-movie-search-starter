//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import TabularData

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
final class _TabularDataDecoder: Decoder {
    enum Owner: Equatable {
        case topLevel
        case container(_DecodingContainerKind)
    }
    
    private enum DecodingError: Error {
        case cannotDecodeAsTopLevelKeyedContainer
    }
    
    public let codingPath: [CodingKey]
    
    private let owner: Owner
    private let dataFrame: DataFrame
    private let rowSelection: DataFrame.Row?
    
    public var userInfo = [CodingUserInfoKey: Any]()
    
    init(
        owner: Owner,
        dataFrame: DataFrame
    ) {
        self.owner = owner
        self.codingPath = []
        self.dataFrame = dataFrame
        self.rowSelection = nil
    }
    
    init(
        owner: Owner,
        row: DataFrame.Row,
        in dataFrame: DataFrame,
        at key: CodingKey
    ) {
        assert(owner == .container(.unkeyed))
        
        self.owner = owner
        self.codingPath = [key]
        self.dataFrame = dataFrame
        self.rowSelection = row
    }
    
    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key>  {
        guard owner == .container(.unkeyed), let row = rowSelection else {
            assert(owner == .topLevel)
            
            throw DecodingError.cannotDecodeAsTopLevelKeyedContainer
        }
        
        return KeyedDecodingContainer(
            KeyedContainer<Key>(
                codingPath: codingPath,
                dataFrame: dataFrame,
                row: row
            )
        )
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedContainer(
            codingPath: codingPath,
            dataFrame: dataFrame
        )
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        if owner == .container(.singleValue) {
            throw Never.Reason.unsupported
        }
        
        return SingleValueContainer(
            codingPath: codingPath,
            dataFrame: dataFrame
        )
    }
}
