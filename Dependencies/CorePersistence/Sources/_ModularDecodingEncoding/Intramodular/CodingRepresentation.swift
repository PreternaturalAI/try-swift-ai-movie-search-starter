//
// Copyright (c) Vatsal Manot
//

import Swallow

@_spi(Internal)
public protocol CodingRepresentation {
    associatedtype Body: CodingRepresentation
    
    var body: Body { get }
}
