//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

internal class BinaryReader {
    private let stream: InputStream
    private let byteOrder: ByteOrder
    private let closeOnDeinit: Bool
    
    private let _buffer: UnsafeMutablePointer<UInt8>
    private let _capacity: Int
    private var _count: Int = 0
    private var _position: Int = 0
    
    internal init(
        stream: InputStream,
        endian: ByteOrder,
        closeOnDeinit: Bool,
        bufferSize: Int = Int(UInt16.max)) throws {
        
        var endian = endian
        
        if stream.streamStatus == .notOpen {
            stream.open()
        }
        if stream.streamStatus != .open {
            throw CSV.Error.cannotOpenFile
        }
        
        _buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        _capacity = bufferSize
        _count = stream.read(_buffer, maxLength: _capacity)
        
        if _count < 0 {
            throw CSV.Error.cannotReadFile
        }
        
        var position = 0
        
        if let (e, l) = Unicode.ByteOrderMark.readByteOrderMark(from: _buffer, count: _count) {
            if endian != .unknown && endian != e {
                throw CSV.Error.stringEndianMismatch
            }
            endian = e
            position = l
        }
        
        _position = position
        
        self.stream = stream
        self.byteOrder = endian
        self.closeOnDeinit = closeOnDeinit
    }
    
    deinit {
        if closeOnDeinit && stream.streamStatus != .closed {
            stream.close()
        }
        
        _buffer.deallocate()
    }
    
    internal var hasBytesAvailable: Bool {
        if _count - _position > 0 {
            return true
        }
        
        return stream.hasBytesAvailable
    }
    
    @inline(__always)
    private func readStream(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        var count = 0
        
        for i in 0 ..< maxLength {
            if _position >= _count {
                let result = stream.read(_buffer, maxLength: _capacity)
                
                if result < 0 {
                    if let error = stream.streamError {
                        throw CSV.Error.streamErrorHasOccurred(error: error)
                    } else {
                        throw CSV.Error.cannotReadFile
                    }
                }
                _count = result
                _position = 0
                
                if result == 0 {
                    break
                }
            }
            
            buffer[i] = _buffer[_position]
            _position += 1
            count += 1
        }
        
        return count
    }
    
    internal func readUInt8() throws -> UInt8 {
        let bufferSize = 1
        var buffer: UInt8 = 0
        
        if try readStream(&buffer, maxLength: bufferSize) != bufferSize {
            throw CSV.Error.cannotReadFile
        }
        
        return buffer
    }
    
    internal func readUInt16() throws -> UInt16 {
        let bufferSize = 2
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        defer {
            buffer.deallocate()
        }
        
        if try readStream(buffer, maxLength: bufferSize) != bufferSize {
            throw CSV.Error.stringEncodingMismatch
        }
        
        return try buffer.withMemoryRebound(to: UInt16.self, capacity: 1) {
            switch byteOrder {
                case .significanceDescending:
                    return UInt16(bigEndian: $0.pointee)
                case .significanceAscending:
                    return UInt16(littleEndian: $0.pointee)
                default:
                    throw CSV.Error.stringEndianMismatch
            }
        }
    }
    
    internal func readUInt32() throws -> UInt32 {
        let bufferSize = 4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        defer {
            buffer.deallocate()
        }
        
        if try readStream(buffer, maxLength: bufferSize) != bufferSize {
            throw CSV.Error.stringEncodingMismatch
        }
        
        return try buffer.withMemoryRebound(to: UInt32.self, capacity: 1) {
            switch byteOrder {
                case .significanceDescending:
                    return UInt32(bigEndian: $0.pointee)
                case .significanceAscending:
                    return UInt32(littleEndian: $0.pointee)
                default:
                    throw CSV.Error.stringEndianMismatch
            }
        }
    }
}

extension BinaryReader {
    internal class UInt8Iterator: Sequence, IteratorProtocol {
        private let reader: BinaryReader
        internal var errorHandler: ((Error) -> Void)?
        
        fileprivate init(reader: BinaryReader) {
            self.reader = reader
        }
        
        internal func next() -> UInt8? {
            if !reader.hasBytesAvailable {
                return nil
            }
            
            do {
                return try reader.readUInt8()
            } catch {
                errorHandler?(error)
                return nil
            }
        }
    }
    
    internal func makeUInt8Iterator() -> UInt8Iterator {
        return UInt8Iterator(reader: self)
    }
}

extension BinaryReader {
    internal class UInt16Iterator: Sequence, IteratorProtocol {
        private let reader: BinaryReader
        internal var errorHandler: ((Error) -> Void)?
        
        fileprivate init(reader: BinaryReader) {
            self.reader = reader
        }
        
        internal func next() -> UInt16? {
            if !reader.hasBytesAvailable {
                return nil
            }
            
            do {
                return try reader.readUInt16()
            } catch {
                errorHandler?(error)
                return nil
            }
        }
    }
    
    internal func makeUInt16Iterator() -> UInt16Iterator {
        return UInt16Iterator(reader: self)
    }
    
}

extension BinaryReader {
    internal class UInt32Iterator: Sequence, IteratorProtocol {
        private let reader: BinaryReader
        internal var errorHandler: ((Error) -> Void)?
        
        fileprivate init(reader: BinaryReader) {
            self.reader = reader
        }
        
        internal func next() -> UInt32? {
            if !reader.hasBytesAvailable {
                return nil
            }
            
            do {
                return try reader.readUInt32()
            } catch {
                errorHandler?(error)
                return nil
            }
        }
    }
    
    internal func makeUInt32Iterator() -> UInt32Iterator {
        return UInt32Iterator(reader: self)
    }
}
