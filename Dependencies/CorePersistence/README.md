# CorePersistence

A protocol-oriented, batteries-included foundation for persistence in Swift. 

# Goals
This library has ambitious goals:
- Provide a protocol-oriented foundation for all the critical aspects of a typical, modern Swift application's persistence layer.
- Provide standard, high performance primitives for the most common data formats (`JSON`, `CSV`, `XML` etc.).
- Unf*** `Codable`.

# Features
- An opinionated, protocol-oriented encapsulated of persistent identifiers (both type identifiers and instance identifiers).
- A modular plugin system for `Codable` (achieved by custom encoders & decoders that can wrap existing ones, macros, and a suite of protocols).
- Better diagnostics for `Codable` errors (`EncodingError` and `DecodingError` are subpar).
- Essential data storage primitives (see `@FileStorage` and `@FolderStorage` – similar to SwiftUI's `@AppStorage` but for the application's persistence layer.)
- A high performance `JSON` primitive.
- A high performance `CSV` primitive.
- A high performance `XML` primitive (backed by the excellent `XMLCoder` library for now).

# License

CorePersistence is licensed under the [MIT License](https://vmanot.mit-license.org).

# Acknowledgments

<details>
<summary>XMLCoder</summary>

- **Link**: https://github.com/CoreOffice/XMLCoder
- **License**: [MIT License](https://github.com/CoreOffice/XMLCoder/blob/main/LICENSE)
- **Authors**: Shawn Moore and XMLCoder contributors

</details>
