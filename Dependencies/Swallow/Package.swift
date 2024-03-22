// swift-tools-version:5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Swallow",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Swallow",
            targets: [
                "SE0270_RangeSet",
                "Swallow",
                "SwallowMacrosClient",
                "Compute",
                "CoreModel",
                "Diagnostics",
                "FoundationX",
                "LoremIpsum",
                "POSIX",
                "PythonString",
                "Runtime",
            ]
        ),
        .library(
            name: "MacroBuilder",
            targets: ["MacroBuilder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
    ],
    targets: [
        .target(
            name: "_SwallowMacrosRuntime",
            dependencies: [
                "Diagnostics",
                "Swallow",
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .macro(
            name: "SwallowMacros",
            dependencies: [
                "Swallow",
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "SwiftSyntaxUtilities",
            ],
            path: "Sources/SwallowMacros"
        ),
        .target(
            name: "LoremIpsum",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "SE0270_RangeSet",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "Swallow",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "SwallowMacrosClient",
            dependencies: [
                "_SwallowMacrosRuntime",
                "SwallowMacros",
                "Runtime",
                "Swallow"
            ],
            path: "Sources/SwallowMacrosClient",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "MacroBuilder",
            dependencies: [
                "MacroBuilderCore",
                "Swallow",
                "SwiftSyntaxUtilities",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/MacroBuilder"
        ),
        .target(
            name: "MacroBuilderCore",
            dependencies: [
                "SwallowMacros",
                "Swallow",
            ],
            path: "Sources/MacroBuilderCore"
        ),
        .target(
            name: "SwiftSyntaxUtilities",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "Swallow",
            ],
            path: "Sources/SwiftSyntaxUtilities"
        ),
        .target(
            name: "Compute",
            dependencies: [
                "Diagnostics",
                .product(name: "Collections", package: "swift-collections"),
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "CoreModel",
            dependencies: [
                "Diagnostics",
                .product(name: "Collections", package: "swift-collections"),
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "Diagnostics",
            dependencies: [
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "FoundationX",
            dependencies: [
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "POSIX",
            dependencies: [
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "PythonString",
            dependencies: [
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "Runtime",
            dependencies: [
                "_SwallowMacrosRuntime",
                "Compute",
                "FoundationX",
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .testTarget(
            name: "SwallowTests",
            dependencies: [
                "Runtime",
                "Swallow"
            ],
            path: "Tests/Swallow"
        ),
    ]
)
