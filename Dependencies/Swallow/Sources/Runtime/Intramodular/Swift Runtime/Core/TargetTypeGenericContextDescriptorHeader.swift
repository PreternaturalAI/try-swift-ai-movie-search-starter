//
// Copyright (c) Vatsal Manot
//

import Swift

@frozen
@usableFromInline
struct TargetTypeGenericContextDescriptorHeader {
    var instantiationCache: Int32
    var defaultInstantiationPattern: Int32
    var base: TargetGenericContextDescriptorHeader
}

@frozen
@usableFromInline
struct TargetGenericContextDescriptorHeader {
    var numberOfParams: UInt16
    var numberOfRequirements: UInt16
    var numberOfKeyArguments: UInt16
    var numberOfExtraArguments: UInt16
}
