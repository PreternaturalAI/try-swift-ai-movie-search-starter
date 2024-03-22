//
// Copyright (c) Vatsal Manot
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct module: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HadeanIdentifierMacro.self
    ]
}
