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

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxMacros

/// An implementation of the `MacroExpansionContext` protocol that is
/// suitable for testing purposes.
public class BasicMacroExpansionContext {
  /// A single source file that is known to the macro expansion context.
  public struct KnownSourceFile {
    /// The name of the module in which this source file resides.
    let moduleName: String

    /// The full path to the file.
    let fullFilePath: String

    public init(moduleName: String, fullFilePath: String) {
      self.moduleName = moduleName
      self.fullFilePath = fullFilePath
    }
  }

  /// Create a new macro evaluation context.
  public init(
    expansionDiscriminator: String = "__macro_local_",
    sourceFiles: [SourceFileSyntax: KnownSourceFile] = [:]
  ) {
    self.expansionDiscriminator = expansionDiscriminator
    self.sourceFiles = sourceFiles
  }

  /// The set of diagnostics that were emitted as part of expanding the
  /// macro.
  public private(set) var diagnostics: [Diagnostic] = []

  /// Mapping from the root source file syntax nodes to the known source-file
  /// information about that source file.
  private var sourceFiles: [SourceFileSyntax: KnownSourceFile] = [:]

  /// Mapping from intentionally-disconnected syntax nodes to the corresponding
  /// nodes in the original source file.
  ///
  /// This is used to establish the link between a node that been intentionally
  /// disconnected from a source file to hide information from the macro
  /// implementation.
  private var detachedNodes: [Syntax: Syntax] = [:]

  /// The macro expansion discriminator, which is used to form unique names
  /// when requested.
  ///
  /// The expansion discriminator is combined with the `uniqueNames` counters
  /// to produce unique names.
  private var expansionDiscriminator: String = ""

  /// Counter for each of the uniqued names.
  ///
  /// Used in conjunction with `expansionDiscriminator`.
  private var uniqueNames: [String: Int] = [:]

}

extension BasicMacroExpansionContext {
  /// Detach the given node, and record where it came from.
  public func detach<Node: SyntaxProtocol>(_ node: Node) -> Node {
    let detached = node.detached
    detachedNodes[Syntax(detached)] = Syntax(node)
    return detached
  }

  /// Fold all operators in `node` and associated the ``KnownSourceFile``
  /// information of `node` with the original new, folded tree.
  func foldAllOperators(of node: some SyntaxProtocol, with operatorTable: OperatorTable) -> Syntax {
    let folded = operatorTable.foldAll(node, errorHandler: { _ in /*ignore*/ })
    if let originalSourceFile = node.root.as(SourceFileSyntax.self),
      let newSourceFile = folded.root.as(SourceFileSyntax.self)
    {
      // Folding operators doesn't change the source file and its associated locations
      // Record the `KnownSourceFile` information for the folded tree.
      sourceFiles[newSourceFile] = sourceFiles[originalSourceFile]
    }
    return folded
  }
}

extension String {
  /// Retrieve the base name of a string that represents a path, removing the
  /// directory.
  fileprivate var basename: String {
    guard let lastSlash = lastIndex(of: "/") else {
      return self
    }

    return String(self[index(after: lastSlash)...])
  }

}
extension BasicMacroExpansionContext: MacroExpansionContext {
  /// Generate a unique name for use in the macro.
  public func makeUniqueName(_ providedName: String) -> TokenSyntax {
    // If provided with an empty name, substitute in something.
    let name = providedName.isEmpty ? "__local" : providedName

    // Grab a unique index value for this name.
    let uniqueIndex = uniqueNames[name, default: 0]
    uniqueNames[name] = uniqueIndex + 1

    // Start with the expansion discriminator.
    var resultString = expansionDiscriminator

    // Mangle the name
    resultString += "\(name.count)\(name)"

    // Mangle the operator for unique macro names.
    resultString += "fMu"

    // Mangle the index.
    if uniqueIndex > 0 {
      resultString += "\(uniqueIndex - 1)"
    }
    resultString += "_"

    return TokenSyntax(.identifier(resultString), presence: .present)
  }

  /// Produce a diagnostic while expanding the macro.
  public func diagnose(_ diagnostic: Diagnostic) {
    diagnostics.append(diagnostic)
  }

  /// Translates a position from a detached node to the corresponding location
  /// in the original source file.
  ///
  /// - Parameters:
  ///   - position: The position to translate
  ///   - node: The node at which the position is anchored. This node is used to
  ///     find the offset in the original source file
  ///   - fileName: The file name that should be used in the `SourceLocation`
  /// - Returns: The location in the original source file
  public func location(
    for position: AbsolutePosition,
    anchoredAt node: Syntax,
    fileName: String
  ) -> SourceLocation {
    guard let nodeInOriginalTree = detachedNodes[node.root] else {
      return SourceLocationConverter(fileName: fileName, tree: node.root).location(for: position)
    }
    let adjustedPosition = position + SourceLength(utf8Length: nodeInOriginalTree.position.utf8Offset)
    return SourceLocationConverter(fileName: fileName, tree: nodeInOriginalTree.root).location(for: adjustedPosition)
  }

  public func location(
    of node: some SyntaxProtocol,
    at position: PositionInSyntaxNode,
    filePathMode: SourceLocationFilePathMode
  ) -> AbstractSourceLocation? {
    // Dig out the root source file and figure out how we need to adjust the
    // offset of the given syntax node to adjust for it.
    let rootSourceFile: SourceFileSyntax?
    let offsetAdjustment: SourceLength
    if let directRootSourceFile = node.root.as(SourceFileSyntax.self) {
      // The syntax node came from the source file itself.
      rootSourceFile = directRootSourceFile
      offsetAdjustment = .zero
    } else if let nodeInOriginalTree = detachedNodes[Syntax(node)] {
      // The syntax node came from a disconnected root, so adjust for that.
      rootSourceFile = nodeInOriginalTree.root.as(SourceFileSyntax.self)
      offsetAdjustment = SourceLength(utf8Length: nodeInOriginalTree.position.utf8Offset)
    } else {
      return nil
    }

    guard let rootSourceFile, let knownRoot = sourceFiles[rootSourceFile] else {
      return nil
    }

    // Determine the filename to use in the resulting location.
    let fileName: String
    switch filePathMode {
    case .fileID:
      fileName = "\(knownRoot.moduleName)/\(knownRoot.fullFilePath.basename)"

    case .filePath:
      fileName = knownRoot.fullFilePath
    }

    // Find the node's offset relative to its root.
    let rawPosition: AbsolutePosition
    switch position {
    case .beforeLeadingTrivia:
      rawPosition = node.position

    case .afterLeadingTrivia:
      rawPosition = node.positionAfterSkippingLeadingTrivia

    case .beforeTrailingTrivia:
      rawPosition = node.endPositionBeforeTrailingTrivia

    case .afterTrailingTrivia:
      rawPosition = node.endPosition
    }

    // Do the location lookup.
    let converter = SourceLocationConverter(fileName: fileName, tree: rootSourceFile)
    return AbstractSourceLocation(converter.location(for: rawPosition + offsetAdjustment))
  }
}
