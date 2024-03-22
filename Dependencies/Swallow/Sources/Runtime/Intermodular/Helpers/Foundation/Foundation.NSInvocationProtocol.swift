//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@objc public protocol NSInvocationProtocol: ObjCObject {
    var methodSignature: NSMethodSignatureProtocol { get set }
    var argumentsRetained: Bool { get set }
    var target: AnyObject { get set }
    var selector: Selector { get set }

    static func invocationWithMethodSignature(_: AnyObject) -> NSInvocationProtocol

    func retainArguments()

    func getReturnValue(_: UnsafeMutableRawPointer)
    func setReturnValue(_: UnsafeMutableRawPointer)

    func getArgument(_: UnsafeMutableRawPointer, atIndex _: Int)
    func setArgument(_: UnsafeMutableRawPointer, atIndex _: Int)

    func invoke()
    func invokeWithTarget(_: AnyObject)
}

let NSInvocationType = unsafeBitCast(ObjCClass(name: "NSInvocation"), to: NSInvocationProtocol.Type.self)

// MARK: - Auxiliary Extensions

extension NSInvocationProtocol {
    public func invoke(using implementation: ObjCVirtualMethodImplementation) {
        implementation.invoke(for: self)
    }

    public func setReturnValue(_ value: AnyObjCCodable) {
        guard value.type.memoryLayout.size != 0 else {
            return
        }
        
        let buffer = value.encodeObjCValueToRawBuffer()
        setReturnValue(buffer)
        keepAlive(value)
        value.deinitializeRawObjCValueBuffer(buffer)
        buffer.deallocate()
    }
}

// MARK: - Helpers

extension ObjCCodable {
    public init(_returnValueFromInvocation invocation: NSInvocationProtocol) {
        let methodReturnLength = invocation.methodSignature.methodReturnLength
        let buffer = UnsafeMutableRawPointer.allocate(capacity: .init(methodReturnLength))

        if methodReturnLength != 0 {
            invocation.getReturnValue(buffer)
        }

        self.init(decodingObjCValueFromRawBuffer: buffer, encoding: .init(String(utf8String: invocation.methodSignature.methodReturnType)))
        
        buffer.deallocate()
    }
}

extension ObjCMethodInvocation {
    public init(nsInvocation: NSInvocationProtocol) {
        let target = asObjCObject(nsInvocation.target)
        let method = target.objCClass[methodNamed: nsInvocation.selector.value]!
        
        var arguments: [AnyObjCCodable] = []
        
        for (index, type) in method.argumentTypes.enumerated().dropFirst(2) {
            let buffer = UnsafeMutableRawBufferPointer.allocate(for: type.toTypeMetadata())

            nsInvocation.getArgument(buffer.baseAddress!, atIndex: index)

            arguments += AnyObjCCodable(decodingObjCValueFromRawBuffer: buffer.baseAddress, encoding: type)

            buffer.deallocate()
        }

        let payload = Payload(target: target, selector: method.getDescription().selector, arguments: arguments)

        self.init(method: method, payload: payload)
    }
}
