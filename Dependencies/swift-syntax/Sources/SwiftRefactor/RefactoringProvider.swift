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

/// A refactoring expressed as textual edits on the original syntax tree. In
/// general clients should prefer `SyntaxRefactoringProvider` where possible.
public protocol EditRefactoringProvider {
  /// The type of syntax this refactoring action accepts.
  associatedtype Input: SyntaxProtocol
  /// Contextual information used by the refactoring action.
  associatedtype Context = Void

  /// Perform the refactoring action on the provided syntax node.
  ///
  /// - Parameters:
  ///   - syntax: The syntax to transform.
  ///   - context: Contextual information used by the refactoring action.
  /// - Returns: Textual edits that describe how to apply the result of the
  ///            refactoring action on locations within the original tree. An
  ///            empty array if the refactoring could not be performed.
  static func textRefactor(syntax: Input, in context: Context) -> [SourceEdit]
}

extension EditRefactoringProvider where Context == Void {
  /// See `textRefactor(syntax:in:)`. This method provides a convenient way to
  /// invoke a refactoring action that requires no context.
  ///
  /// - Parameters:
  ///   - syntax: The syntax to transform.
  /// - Returns: Textual edits describing the refactoring to perform.
  public static func textRefactor(syntax: Input) -> [SourceEdit] {
    return self.textRefactor(syntax: syntax, in: ())
  }
}

/// A refactoring expressed as a structural transformation of the original
/// syntax node. For example, a refactoring action that wishes to exchange the
/// leading trivia of a node could call call `with(\.leadingTrivia, _:)`
/// against its input syntax and return the resulting syntax node. Or, for
/// compound syntax nodes, entire sub-trees can be added, exchanged, or removed
/// by calling the corresponding `with` API.
///
/// - Note: The syntax trees returned by SwiftSyntax are immutable: any
///         transformation made against the tree results in a distinct tree.
///
/// Handling Malformed Syntax
/// =========================
///
/// A refactoring provider cannot assume that the syntax it is given is
/// necessarily well-formed. As the SwiftSyntax library is capable of recovering
/// from a variety of erroneous inputs, a refactoring provider has to be
/// prepared to fail gracefully as well. Many refactoring providers follow a
/// common validation pattern that "preflights" the refactoring by testing the
/// structure of the provided syntax nodes. If the tests fail, the refactoring
/// provider exits early by returning an empty array. It is recommended that
/// refactoring actions fail as quickly as possible to give any associated
/// tooling space to recover as well.
public protocol SyntaxRefactoringProvider: EditRefactoringProvider {
  // Should not be required, see https://github.com/apple/swift/issues/66004.
  // The default is a hack to workaround the warning that we'd hit otherwise.
  associatedtype Input: SyntaxProtocol = MissingSyntax
  /// The type of syntax this refactoring action returns.
  associatedtype Output: SyntaxProtocol
  /// Contextual information used by the refactoring action.
  associatedtype Context = Void

  /// Perform the refactoring action on the provided syntax node. It is assumed
  /// that the returned output completely replaces the input node.
  ///
  /// - Parameters:
  ///   - syntax: The syntax to transform.
  ///   - context: Contextual information used by the refactoring action.
  /// - Returns: The result of applying the refactoring action, or `nil` if the
  ///            action could not be performed.
  static func refactor(syntax: Input, in context: Context) -> Output?
}

extension SyntaxRefactoringProvider where Context == Void {
  /// See `refactor(syntax:in:)`. This method provides a convenient way to
  /// invoke a refactoring action that requires no context.
  ///
  /// - Parameters:
  ///   - syntax: The syntax to transform.
  /// - Returns: The result of applying the refactoring action, or `nil` if the
  ///            action could not be performed.
  public static func refactor(syntax: Input) -> Output? {
    return self.refactor(syntax: syntax, in: ())
  }
}

extension SyntaxRefactoringProvider {
  /// Provides a default implementation for
  /// `EditRefactoringProvider.textRefactor(syntax:in:)` that produces an edit
  /// to replace the input of `refactor(syntax:in:)` with its returned output.
  public static func textRefactor(syntax: Input, in context: Context) -> [SourceEdit] {
    guard let output = refactor(syntax: syntax, in: context) else {
      return []
    }
    return [SourceEdit.replace(syntax, with: output.description)]
  }
}

/// A textual edit to the original source represented by a range and a
/// replacement.
public struct SourceEdit: Equatable {
  /// The half-open range that this edit applies to.
  public let range: Range<AbsolutePosition>
  /// The text to replace the original range with. Empty for a deletion.
  public let replacement: String

  /// Length of the original source range that this edit applies to. Zero if
  /// this is an addition.
  public var length: SourceLength {
    return SourceLength(utf8Length: range.lowerBound.utf8Offset - range.upperBound.utf8Offset)
  }

  /// Create an edit to replace `range` in the original source with
  /// `replacement`.
  public init(range: Range<AbsolutePosition>, replacement: String) {
    self.range = range
    self.replacement = replacement
  }

  /// Convenience function to create a textual addition after the given node
  /// and its trivia.
  public static func insert(_ newText: String, after node: some SyntaxProtocol) -> SourceEdit {
    return SourceEdit(range: node.endPosition..<node.endPosition, replacement: newText)
  }

  /// Convenience function to create a textual addition before the given node
  /// and its trivia.
  public static func insert(_ newText: String, before node: some SyntaxProtocol) -> SourceEdit {
    return SourceEdit(range: node.position..<node.position, replacement: newText)
  }

  /// Convenience function to create a textual replacement of the given node,
  /// including its trivia.
  public static func replace(_ node: some SyntaxProtocol, with replacement: String) -> SourceEdit {
    return SourceEdit(range: node.position..<node.endPosition, replacement: replacement)
  }

  /// Convenience function to create a textual deletion the given node and its
  /// trivia.
  public static func remove(_ node: some SyntaxProtocol) -> SourceEdit {
    return SourceEdit(range: node.position..<node.endPosition, replacement: "")
  }
}

extension SourceEdit: CustomDebugStringConvertible {
  public var debugDescription: String {
    let hasNewline = replacement.contains { $0.isNewline }
    if hasNewline {
      return #"""
        \#(range.lowerBound.utf8Offset)-\#(range.upperBound.utf8Offset)
        """
        \#(replacement)
        """
        """#
    }
    return "\(range.lowerBound.utf8Offset)-\(range.upperBound.utf8Offset) \"\(replacement)\""
  }
}
