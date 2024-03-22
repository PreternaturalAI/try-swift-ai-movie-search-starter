//
// Copyright (c) Vatsal Manot
//

import Compute
import FoundationX
import Swallow
import SwiftUI
import UniformTypeIdentifiers
import TabularData

public struct CSV {
    public private(set) var headers: [CSVColumnHeader] = [] {
        didSet {
            for (index, column) in headers.enumerated() {
                headers[index].index = index
                
                if let name = column.name {
                    nameToColumnMap[name] = column
                }
            }
        }
    }
    
    private var nameToColumnMap: [String: CSVColumnHeader] = [:]
    private var data: [CSVColumnHeader: [String]] = [:]
    
    public init() {
        
    }
}

extension CSV {
    public var hasHeaderRow: Bool {
        data.keys.contains(where: { $0.name != nil })
    }
    
    public subscript(_ header: CSVColumnHeader) -> [String] {
        get {
            data[header]!
        } set {
            data[header] = newValue
        }
    }
    
    public subscript(column name: String) -> [String] {
        get {
            self[columnHeader(named: name)]
        } set {
            self[columnHeader(named: name)] = newValue
        }
    }
    
    private func columnHeader(at index: Int) -> CSVColumnHeader {
        headers[try: index] ?? CSVColumnHeader(index: index)
    }
    
    public func columnHeader(named name: String) -> CSVColumnHeader {
        nameToColumnMap[name] ?? headers.first(where: { $0.name == name })!
    }
    
    public mutating func renameColumn(named originalName: String, to newName: String) {
        assert(nameToColumnMap[newName] == nil)
        
        nameToColumnMap[newName] = nameToColumnMap[originalName]
        headers = headers.map({ CSVColumnHeader(index: $0.index, name: $0.name == originalName ? newName : $0.name) })
    }
}

extension CSV {
    public func filter(_ isIncluded: ([CSVColumnHeader: String]) throws -> Bool) rethrows -> Self {
        var rowIndices = Set<Int>()
        
        let allRowIndices = 0..<rowCount
        
        for rowIndex in allRowIndices {
            var row: [CSVColumnHeader: String] = [:]
            
            for columnHeader in headers {
                row[columnHeader] = self[columnHeader][rowIndex]
            }
            
            if try isIncluded(row) {
                rowIndices.insert(rowIndex)
            }
        }
        
        return build(self) {
            for header in data.keys {
                $0.data[header]!.remove(at: Set(allRowIndices).subtracting(rowIndices).sorted(by: { $1 > $0 }))
            }
        }
    }
    
    public func filter(byColumn columnName: String, isIncluded: (String) throws -> Bool) rethrows -> Self {
        try filter({ try isIncluded($0[columnHeader(named: columnName)]!) })
    }
}

extension CSV {
    public mutating func appendRow(_ row: [String]) {
        for (columnIndex, column) in headers.enumerated() {
            data[column]!.append(row[columnIndex])
        }
    }
    
    public mutating func appendRow(_ row: [String: String]) {
        for column in headers {
            data[column]!.append(row[column.name!] ?? "")
        }
    }
    
    @discardableResult
    public mutating func appendColumn(named headerName: String? = nil) -> CSVColumnHeader {
        let columnHeader = CSVColumnHeader(index: headers.indices.last.map({ $0 + 1 }) ?? 0, name: headerName)
        
        self.headers += columnHeader
        
        data[columnHeader] = Array(repeating: String(), count: rowCount)
        
        return columnHeader
    }
    
    public mutating func append(_ other: CSV) {
        data.merge(
            build(other, with: { $0.incrementIndices(by: headers.count) }).data,
            uniquingKeysWith: { _, _ in fatalError() }
        )
    }
    
    private mutating func incrementIndices(by x: Int) {
        data._forEach(mutating: { element in
            element.key.index += x
        })
    }
}

// MARK: - Initializers

extension CSV {
    private enum _EncodingError: Swift.Error {
        case emptyData
    }
    
    public init<Data: Collection>(from data: Data) throws where Data.Element: Encodable {
        guard let first = data.first else {
            throw _EncodingError.emptyData
        }
        
        TODO.here(.optimize)
        
        let jsonData = try JSONEncoder().encode(first)
        let firstValueDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)
        
        for key in firstValueDictionary.keys {
            self.appendColumn(named: key)
        }
        
        let allRemainingValueDictionaries = try data.dropFirst().map({ try JSONDecoder().decode([String: AnyCodable].self, from: JSONEncoder().encode($0)) })
        
        for dictionary in [firstValueDictionary].join(allRemainingValueDictionaries) {
            appendRow(dictionary.mapValues({ $0.description }))
        }
    }
}

// MARK: - Extensions

extension CSV {
    public func decode<T: Decodable>(_ type: T.Type) throws -> [T] {
        try CSVDecoder().decode(Array<T>.self, from: self)
    }
}

// MARK: - Conformances

extension CSV: Collection {
    public var isEmpty: Bool {
        data.isEmpty
    }
    
    public var startIndex: Int {
        headers.startIndex
    }
    
    public var endIndex: Int {
        headers.endIndex
    }
    
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    public subscript(position: Int) -> [String] {
        data[columnHeader(at: position)]!
    }
}

extension CSV: DataDecodableWithDefaultStrategy {
    public struct DataDecodingStrategy: Initiable {
        public let encoding: String.Encoding
        public let hasHeaderRow: Bool
        
        public init(
            encoding: String.Encoding,
            hasHeaderRow: Bool = true
        ) {
            self.encoding = encoding
            self.hasHeaderRow = hasHeaderRow
        }
        
        public init() {
            self.init(encoding: .utf8, hasHeaderRow: true)
        }
    }
    
    public static var defaultDataDecodingStrategy: DataDecodingStrategy {
        .init()
    }
    
    public init(data: Data, using strategy: DataDecodingStrategy) throws {
        self.init()
        
        try self.read(
            from: String(data: data, encoding: .utf8).unwrap(),
            hasHeaderRow: strategy.hasHeaderRow
        )
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CSV: FileDocument {
    public static var readableContentTypes: [UTType] {
        [.commaSeparatedText]
    }
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.init()
        
        try read(from: data.toUTF8String().unwrap())
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        do {
            let stream = OutputStream(toMemory: ())
            
            try write(to: .init(stream: stream))
            
            return try FileWrapper(regularFileWithContents: stream.dataWrittenToMemoryStream.unwrap())
        } catch {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
}

extension CSV: RowMajorRectangularCollection {
    public typealias Rows = LazyMapSequence<LazySequence<(Range<Int>)>.Elements, [String]>
    public typealias Columns = LazyMapSequence<LazySequence<Range<Array<CSVColumnHeader>.Index>>.Elements, [String]>
    public typealias RectangularIterator = AnyIterator<String>
    
    public var rows: Rows {
        (0..<rowCount).lazy.map({ self[row: $0] })
    }
    
    public var rowCount: Int {
        data.values.compactMap({ $0.count }).first ?? 0
    }
    
    public var columns: Columns {
        headers.indices.lazy.map({ self[column: $0] })
    }
    
    public var columnNames: [String?] {
        headers.map({ $0.name })
    }
    
    public var columnCount: Int {
        headers.count
    }
    
    public subscript(row rowIndex: Int) -> [String] {
        get {
            headers.map({ data[$0]![rowIndex] })
        } set {
            /// A boolean indicating whether the rows should be appended (if `rowIndex` is out of bounds by `1`).
            let shouldAppend = rowIndex == rowCount
            
            if shouldAppend {
                appendRow(newValue)
            } else {
                for (columnIndex, column) in headers.enumerated() {
                    data[column]![rowIndex] = newValue[columnIndex]
                }
            }
        }
    }
    
    public subscript(column columnIndex: Int) -> [String] {
        get {
            self[columnHeader(at: columnIndex)]
        } set {
            self[columnHeader(at: columnIndex)] = newValue
        }
    }
    
    public func makeRectangularIterator() -> AnyIterator<String> {
        .init(rows.lazy.flatMap({ $0 }).makeIterator())
    }
    
    public subscript(rectangular position: Int) -> String {
        self[row: rowIndex(from: position), column: columnIndex(from: position)]
    }
    
    public func index(forRow rowIndex: Int, column columnIndex: Int) -> Int {
        rowIndex * columnIndex
    }
}

extension CSV: Sequence {
    public func makeIterator() -> AnyIterator<[String]> {
        .init(rows.makeIterator())
    }
}

// MARK: - Reading & Writing -

extension CSV {
    public mutating func read(from reader: CSVReader) {
        guard let first = reader.next() else {
            return
        }
        
        if let headerRow = reader.headerRow {
            for (index, name) in headerRow.enumerated() {
                headers.append(CSVColumnHeader(index: index, name: name))
            }
        } else {
            for index in first.indices {
                headers.append(CSVColumnHeader(index: index))
            }
        }
        
        for row in [first].join(reader.makeSequence()) {
            for (columnIndex, cellValue) in row.enumerated() {
                data[columnHeader(at: columnIndex), default: []].append(cellValue)
            }
        }
    }
    
    public mutating func read(
        from string: String,
        encoding: String.Encoding = .utf8,
        hasHeaderRow: Bool = true
    ) throws {
        let reader = try CSVReader(string: string, hasHeaderRow: hasHeaderRow)
        
        read(from: reader)
    }
    
    /// Writes the contents of the CSV to a CSV writer.
    public mutating func read(
        from location: URLRepresentable,
        encoding: String.Encoding = .utf8,
        hasHeaderRow: Bool = true
    ) throws {
        let reader = try CSVReader(
            string: String(contentsOf: location, encoding: encoding),
            hasHeaderRow: hasHeaderRow
        )
        
        read(from: reader)
    }
    
    /// Writes the contents of the CSV to a CSV writer.
    public func write(
        to writer: CSVWriter
    ) throws {
        if hasHeaderRow {
            writer.beginNewRow()
            try writer.write(row: headers.map({ $0.name ?? "" }))
        }
        
        for rowIndex in 0..<rowCount {
            try writer.write(row: headers.map({ data[$0]?[rowIndex] ?? "" }))
        }
    }
    
    /// Writes the contents of the CSV to a given location.
    public func write(
        to location: URLRepresentable
    ) throws {
        let writer = try CSVWriter(stream: try OutputStream(url: location, append: false).unwrap())
        
        try write(to: writer)
    }
}
