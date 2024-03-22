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

import SwiftSyntax

extension Trivia {
  /// Removes all whitespaces that is trailing before a newline trivia,
  /// effectively making sure that lines don't end with a whitespace
  func trimmingTrailingWhitespaceBeforeNewline(isBeforeNewline: Bool) -> Trivia {
    // Iterate through the trivia in reverse. Every time we see a newline drop
    // all whitespaces until we see a non-whitespace trivia piece.
    var isBeforeNewline = isBeforeNewline
    var trimmedReversedPieces: [TriviaPiece] = []
    for piece in pieces.reversed() {
      if piece.isNewline {
        isBeforeNewline = true
        trimmedReversedPieces.append(piece)
        continue
      }
      if isBeforeNewline && piece.isWhitespace {
        continue
      }
      trimmedReversedPieces.append(piece)
      isBeforeNewline = false
    }
    return Trivia(pieces: trimmedReversedPieces.reversed())
  }

  /// Returns `true` if this trivia contains indentation.
  func containsIndentation(isOnNewline: Bool) -> Bool {
    guard let indentation = indentation(isOnNewline: isOnNewline) else {
      return false
    }
    return !indentation.isEmpty
  }

  /// Returns the indentation of the last trivia piece in this trivia that is
  /// not a whitespace.
  /// - Parameter isOnNewline: Specifies if the character before this trivia is a newline character, i.e. if this trivia already starts on a new line.
  /// - Returns: An optional ``Trivia`` with indentation of the last trivia piece.
  public func indentation(isOnNewline: Bool) -> Trivia? {
    let lastNonWhitespaceTriviaPieceIndex = self.pieces.lastIndex(where: { !$0.isWhitespace }) ?? self.pieces.endIndex
    let piecesBeforeLastNonWhitespace = self.pieces[..<lastNonWhitespaceTriviaPieceIndex]
    let indentation: ArraySlice<TriviaPiece>
    if let lastNewlineIndex = piecesBeforeLastNonWhitespace.lastIndex(where: { $0.isNewline }) {
      indentation = piecesBeforeLastNonWhitespace[(lastNewlineIndex + 1)...]
    } else if isOnNewline {
      indentation = piecesBeforeLastNonWhitespace
    } else {
      return nil
    }
    return Trivia(pieces: indentation)
  }

  /// Adds `indentation` after every newline in this trivia.
  func indented(indentation: Trivia, isOnNewline: Bool) -> Trivia {
    guard !isEmpty else {
      if isOnNewline {
        return indentation
      }
      return self
    }

    var indentedPieces: [TriviaPiece] = []
    if isOnNewline {
      indentedPieces.append(contentsOf: indentation)
    }

    for piece in pieces {
      indentedPieces.append(piece)
      if piece.isNewline {
        indentedPieces.append(contentsOf: indentation)
      }
    }

    return Trivia(pieces: indentedPieces)
  }

  var startsWithNewline: Bool {
    guard let first = self.first else {
      return false
    }
    return first.isNewline
  }

  var startsWithWhitespace: Bool {
    guard let first = self.first else {
      return false
    }
    return first.isWhitespace
  }

  var endsWithNewline: Bool {
    guard let last = self.pieces.last else {
      return false
    }
    return last.isNewline
  }

  var endsWithWhitespace: Bool {
    guard let last = self.pieces.last else {
      return false
    }
    return last.isWhitespace
  }
}
