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

@_spi(RawSyntax) import SwiftSyntax

extension StringLiteralExprSyntax {

  /// Returns the string value of the literal as the parsed program would see
  /// it: Multiline strings are combined into one string, escape sequences are
  /// resolved.
  ///
  /// Returns nil if the literal contains interpolation segments.
  public var representedLiteralValue: String? {
    // Currently the implementation relies on properly parsed literals.
    guard !hasError else { return nil }
    guard let stringLiteralKind else { return nil }

    // Concatenate unescaped string literal segments. For example multiline
    // strings consist of multiple segments. Abort on finding string
    // interpolation.
    var result = ""
    for segment in segments {
      switch segment {
      case .stringSegment(let stringSegmentSyntax):
        stringSegmentSyntax.appendUnescapedLiteralValue(
          stringLiteralKind: stringLiteralKind,
          delimiterLength: delimiterLength,
          to: &result
        )
      case .expressionSegment:
        // Bail out if there are any interpolation segments.
        return nil
      }
    }

    return result
  }

  fileprivate var stringLiteralKind: StringLiteralKind? {
    switch openingQuote.tokenKind {
    case .stringQuote:
      return .singleLine
    case .multilineStringQuote:
      return .multiLine
    case .singleQuote:
      return .singleQuote
    default:
      return nil
    }
  }

  fileprivate var delimiterLength: Int {
    openingPounds?.text.count ?? 0
  }
}

extension StringSegmentSyntax {
  fileprivate func appendUnescapedLiteralValue(
    stringLiteralKind: StringLiteralKind,
    delimiterLength: Int,
    to output: inout String
  ) {
    precondition(!hasError, "appendUnescapedLiteralValue relies on properly parsed literals")

    var text = content.text
    text.withUTF8 { buffer in
      var cursor = Lexer.Cursor(input: buffer, previous: 0)

      // Put the cursor in the string literal lexing state. This is just
      // defensive as it's currently not used by `lexCharacterInStringLiteral`.
      let state = Lexer.Cursor.State.inStringLiteral(kind: stringLiteralKind, delimiterLength: delimiterLength)
      let transition = Lexer.StateTransition.push(newState: state)
      cursor.perform(stateTransition: transition, stateAllocator: BumpPtrAllocator(slabSize: 256))

      while true {
        let lex = cursor.lexCharacterInStringLiteral(
          stringLiteralKind: stringLiteralKind,
          delimiterLength: delimiterLength
        )

        switch lex {
        case .success(let scalar):
          output.append(Character(scalar))
        case .validatedEscapeSequence(let character):
          output.append(character)
        case .endOfString, .error:
          // We get an error at the end of the string because
          // `lexCharacterInStringLiteral` expects the closing quote.
          // We can assume the error just signals the end of string
          // because we made sure the token lexed fine before.
          return
        }
      }
    }
  }
}
