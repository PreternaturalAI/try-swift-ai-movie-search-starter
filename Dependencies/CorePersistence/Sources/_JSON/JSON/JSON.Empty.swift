//
// Copyright (c) Vatsal Manot
//

import Swift

extension JSON {
    public struct Empty: Decodable {
        public init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer() {
                if singleValueContainer.decodeNil() {
                    return
                } else {
                    do {
                        let json = try singleValueContainer.decode(JSON.self)
                        if json.isEmpty {
                            return
                        } else {
                            throw JSON.RuntimeError.isNotEmpty
                        }
                    } catch {
                        throw JSON.RuntimeError.isNotEmpty
                    }
                }
            } else if let unkeyedContainer = try? decoder.unkeyedContainer() {
                if unkeyedContainer.isAtEnd {
                    return
                } else {
                    throw JSON.RuntimeError.isNotEmpty
                }
            } else if let keyedContainer = try? decoder.container(keyedBy: JSONCodingKey.self) {
                if keyedContainer.allKeys.isEmpty {
                    return
                } else {
                    throw JSON.RuntimeError.isNotEmpty
                }
            } else {
                throw JSON.RuntimeError.isNotEmpty
            }
        }
    }
}
