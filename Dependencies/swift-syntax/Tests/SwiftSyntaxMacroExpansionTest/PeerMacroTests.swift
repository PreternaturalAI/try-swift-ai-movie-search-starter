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

//==========================================================================//
// IMPORTANT: The macros defined in this file are intended to test the      //
// behavior of MacroSystem. Many of them do not serve as good examples of   //
// how macros should be written. In particular, they often lack error       //
// handling because it is not needed in the few test cases in which these   //
// macros are invoked.                                                      //
//==========================================================================//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class PeerMacroTests: XCTestCase {
  private let indentationWidth: Trivia = .spaces(2)

  func testAddCompletionHandler() {
    struct AddCompletionHandler: PeerMacro {
      static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
      ) throws -> [DeclSyntax] {
        // Only on functions at the moment. We could handle initializers as well
        // with a bit of work.
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
          throw MacroExpansionErrorMessage("@addCompletionHandler only works on functions")
        }

        // This only makes sense for async functions.
        if funcDecl.signature.effectSpecifiers?.asyncSpecifier == nil {
          throw MacroExpansionErrorMessage(
            "@addCompletionHandler requires an async function"
          )
        }

        // Form the completion handler parameter.
        let resultType: TypeSyntax? = funcDecl.signature.returnClause?.type.trimmed

        let completionHandlerParam =
          FunctionParameterSyntax(
            firstName: .identifier("completionHandler"),
            colon: .colonToken(trailingTrivia: .space),
            type: TypeSyntax("(\(resultType ?? "")) -> Void")
          )

        // Add the completion handler parameter to the parameter list.
        let parameterList = funcDecl.signature.parameterClause.parameters
        var newParameterList = parameterList
        if !parameterList.isEmpty {
          // We need to add a trailing comma to the preceding list.
          newParameterList[newParameterList.index(before: newParameterList.endIndex)].trailingComma = .commaToken(trailingTrivia: .space)
        }
        newParameterList.append(completionHandlerParam)

        let callArguments: [String] = parameterList.map { param in
          let argName = param.secondName ?? param.firstName

          if param.firstName.text != "_" {
            return "\(param.firstName.text): \(argName.text)"
          }

          return "\(argName.text)"
        }

        let call: ExprSyntax =
          "\(funcDecl.name)(\(raw: callArguments.joined(separator: ", ")))"

        // FIXME: We should make CodeBlockSyntax ExpressibleByStringInterpolation,
        // so that the full body could go here.
        let newBody: ExprSyntax =
          """

            Task {
              completionHandler(await \(call))
            }

          """

        // Drop the @addCompletionHandler attribute from the new declaration.
        let newAttributeList = funcDecl.attributes.filter {
          guard case let .attribute(attribute) = $0 else {
            return true
          }
          return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name == "addCompletionHandler"
        }

        var newFunc = funcDecl
        newFunc.signature.effectSpecifiers?.asyncSpecifier = nil  // drop async
        newFunc.signature.returnClause = nil  // drop result type
        newFunc.signature.parameterClause.parameters = newParameterList
        newFunc.signature.parameterClause.trailingTrivia = []
        newFunc.body = CodeBlockSyntax { newBody }
        newFunc.attributes = newAttributeList

        return [DeclSyntax(newFunc)]
      }
    }

    assertMacroExpansion(
      """
      @addCompletionHandler
      func f(a: Int, for b: String, _ value: Double) async -> String { }
      """,
      expandedSource: """
        func f(a: Int, for b: String, _ value: Double) async -> String { }

        func f(a: Int, for b: String, _ value: Double, completionHandler: (String) -> Void) {
          Task {
            completionHandler(await f(a: a, for: b, value))
          }
        }
        """,
      macros: ["addCompletionHandler": AddCompletionHandler.self],
      indentationWidth: indentationWidth
    )
  }

  func testPeerMacroOnVariableWithMultipleBindings() {
    struct TestMacro: PeerMacro {
      static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
      ) throws -> [DeclSyntax] {
        return ["var baz: Int = 0"]
      }
    }

    assertMacroExpansion(
      """
      @Test
      let a = 17, b = 12
      """,
      expandedSource: """
        let a = 17, b = 12
        """,
      diagnostics: [
        DiagnosticSpec(message: "peer macro can only be applied to a single variable", line: 1, column: 1)
      ],
      macros: ["Test": TestMacro.self]
    )

    assertMacroExpansion(
      """
      struct Foo {
        @Test
        let a = 17, b = 12
      }
      """,
      expandedSource: """
        struct Foo {
          let a = 17, b = 12
        }
        """,
      diagnostics: [
        DiagnosticSpec(message: "peer macro can only be applied to a single variable", line: 2, column: 3)
      ],
      macros: ["Test": TestMacro.self]
    )
  }

  func testEmpty() {
    struct TestMacro: PeerMacro {
      static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
      ) throws -> [DeclSyntax] {
        return []
      }
    }

    assertMacroExpansion(
      "@Test var x: Int",
      expandedSource: "var x: Int",
      macros: [
        "Test": TestMacro.self
      ]
    )
  }
}
