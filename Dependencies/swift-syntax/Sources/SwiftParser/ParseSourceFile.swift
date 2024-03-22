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

extension Parser {
  /// Parse the source code in the given string as Swift source file. See
  /// `Parser.init` for more details.
  public static func parse(
    source: String
  ) -> SourceFileSyntax {
    var parser = Parser(source)
    return SourceFileSyntax.parse(from: &parser)
  }

  /// A compiler interface that allows the enabling of experimental features.
  @_spi(ExperimentalLanguageFeatures)
  public static func parse(
    source: UnsafeBufferPointer<UInt8>,
    experimentalFeatures: ExperimentalFeatures
  ) -> SourceFileSyntax {
    var parser = Parser(source, experimentalFeatures: experimentalFeatures)
    return SourceFileSyntax.parse(from: &parser)
  }

  /// Parse the source code in the given buffer as Swift source file. See
  /// `Parser.init` for more details.
  public static func parse(
    source: UnsafeBufferPointer<UInt8>,
    maximumNestingLevel: Int? = nil
  ) -> SourceFileSyntax {
    var parser = Parser(source, maximumNestingLevel: maximumNestingLevel)
    return SourceFileSyntax.parse(from: &parser)
  }

  /// Parse the source code in the given string as Swift source file with support
  /// for incremental parsing.
  ///
  /// When parsing a source file for the first time, invoke `parseIncrementally`
  /// with `parseTransition: nil`. This returns the initial tree as well as
  /// ``LookaheadRanges``. If an edit is made to the source file, an
  /// ``IncrementalParseTransition`` can be constructed from the initial tree
  /// and its ``LookaheadRanges``. When invoking `parseIncrementally` again with
  /// the post-edit source and that parse transition, the parser will re-use
  /// nodes that haven’t changed.
  ///
  /// - Parameters:
  ///   - source: The source code to parse
  ///   - parseTransition: If a similar source file has already been parsed, the
  ///     ``IncrementalParseTransition`` that contains the previous tree as well
  ///     as the edits that were performed to it.
  /// - Returns: The parsed tree as well as the ``LookaheadRanges`` that describe
  ///            how far the parser looked ahead while parsing a node, which is
  ///            necessary to construct an ``IncrementalParseTransition`` for a
  ///            subsequent incremental parse
  public static func parseIncrementally(
    source: String,
    parseTransition: IncrementalParseTransition?
  ) -> (tree: SourceFileSyntax, lookaheadRanges: LookaheadRanges) {
    var parser = Parser(source, parseTransition: parseTransition)
    return (SourceFileSyntax.parse(from: &parser), parser.lookaheadRanges)
  }

  /// Parse the source code in the given buffer as Swift source file with support
  /// for incremental parsing.
  ///
  /// See doc comments in ``Parser/parseIncrementally(source:parseTransition:)``
  public static func parseIncrementally(
    source: UnsafeBufferPointer<UInt8>,
    maximumNestingLevel: Int? = nil,
    parseTransition: IncrementalParseTransition?
  ) -> (tree: SourceFileSyntax, lookaheadRanges: LookaheadRanges) {
    var parser = Parser(source, maximumNestingLevel: maximumNestingLevel, parseTransition: parseTransition)
    return (SourceFileSyntax.parse(from: &parser), parser.lookaheadRanges)
  }
}

extension Parser {
  mutating func parseRemainder<R: RawSyntaxNodeProtocol>(into: R) -> R {
    guard !into.raw.kind.isSyntaxCollection, let layout = into.raw.layoutView else {
      preconditionFailure("Only support parsing of non-collection layout nodes")
    }

    let remainingTokens = self.consumeRemainingTokens()
    if remainingTokens.isEmpty {
      return into
    }

    let existingUnexpected: [RawSyntax]
    if let unexpectedNode = layout.children[layout.children.count - 1] {
      precondition(unexpectedNode.is(RawUnexpectedNodesSyntax.self))
      existingUnexpected = unexpectedNode.as(RawUnexpectedNodesSyntax.self).elements
    } else {
      existingUnexpected = []
    }
    let unexpected = RawUnexpectedNodesSyntax(elements: existingUnexpected + remainingTokens, arena: self.arena)

    let withUnexpected = layout.replacingChild(at: layout.children.count - 1, with: unexpected.raw, arena: self.arena)
    return R.init(withUnexpected)!
  }
}
