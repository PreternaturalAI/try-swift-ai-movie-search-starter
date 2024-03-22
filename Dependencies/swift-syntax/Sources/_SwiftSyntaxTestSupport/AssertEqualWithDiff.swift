//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest

/// Asserts that the two strings are equal, providing Unix `diff`-style output if they are not.
///
/// - Parameters:
///   - actual: The actual string.
///   - expected: The expected string.
///   - message: An optional description of the failure.
///   - additionalInfo: Additional information about the failed test case that will be printed after the diff
///   - file: The file in which failure occurred. Defaults to the file name of the test case in
///     which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
public func assertStringsEqualWithDiff(
  _ actual: String,
  _ expected: String,
  _ message: String = "",
  additionalInfo: @autoclosure () -> String? = nil,
  file: StaticString = #file,
  line: UInt = #line
) {
  if actual == expected {
    return
  }
  failStringsEqualWithDiff(
    actual,
    expected,
    message,
    additionalInfo: additionalInfo(),
    file: file,
    line: line
  )
}

/// Asserts that the two data are equal, providing Unix `diff`-style output if they are not.
///
/// - Parameters:
///   - actual: The actual string.
///   - expected: The expected string.
///   - message: An optional description of the failure.
///   - additionalInfo: Additional information about the failed test case that will be printed after the diff
///   - file: The file in which failure occurred. Defaults to the file name of the test case in
///     which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
public func assertDataEqualWithDiff(
  _ actual: Data,
  _ expected: Data,
  _ message: String = "",
  additionalInfo: @autoclosure () -> String? = nil,
  file: StaticString = #file,
  line: UInt = #line
) {
  if actual == expected {
    return
  }

  // NOTE: Converting to `Stirng` here looses invalid UTF8 sequence difference,
  // but at least we can see something is different.
  failStringsEqualWithDiff(
    String(decoding: actual, as: UTF8.self),
    String(decoding: expected, as: UTF8.self),
    message,
    additionalInfo: additionalInfo(),
    file: file,
    line: line
  )
}

/// `XCTFail` with `diff`-style output.
public func failStringsEqualWithDiff(
  _ actual: String,
  _ expected: String,
  _ message: String = "",
  additionalInfo: @autoclosure () -> String? = nil,
  file: StaticString = #file,
  line: UInt = #line
) {
  // Use `CollectionDifference` on supported platforms to get `diff`-like line-based output. On
  // older platforms, fall back to simple string comparison.
  if #available(macOS 10.15, *) {
    let actualLines = actual.components(separatedBy: .newlines)
    let expectedLines = expected.components(separatedBy: .newlines)

    let difference = actualLines.difference(from: expectedLines)

    var result = ""

    var insertions = [Int: String]()
    var removals = [Int: String]()

    for change in difference {
      switch change {
      case .insert(let offset, let element, _):
        insertions[offset] = element
      case .remove(let offset, let element, _):
        removals[offset] = element
      }
    }

    var expectedLine = 0
    var actualLine = 0

    while expectedLine < expectedLines.count || actualLine < actualLines.count {
      if let removal = removals[expectedLine] {
        result += "–\(removal)\n"
        expectedLine += 1
      } else if let insertion = insertions[actualLine] {
        result += "+\(insertion)\n"
        actualLine += 1
      } else {
        result += " \(expectedLines[expectedLine])\n"
        expectedLine += 1
        actualLine += 1
      }
    }

    let failureMessage = "Actual output (+) differed from expected output (-):\n\(result)"
    var fullMessage = message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
    if let additionalInfo = additionalInfo() {
      fullMessage = """
        \(fullMessage)
        \(additionalInfo)
        """
    }
    XCTFail(fullMessage, file: file, line: line)
  } else {
    // Fall back to simple message on platforms that don't support CollectionDifference.
    let failureMessage = "Actual output differed from expected output:"
    let fullMessage = message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
    XCTFail(fullMessage, file: file, line: line)
  }
}
