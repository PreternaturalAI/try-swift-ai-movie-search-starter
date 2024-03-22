//
// Copyright (c) Vatsal Manot
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    public static let webInternetLocation = UTType("com.apple.web-internet-location")!
}

extension UTType {
    public init?(from url: URL) {
        if FileManager.default.fileExists(at: url), let type = try? url.resourceValues(forKeys: [.typeIdentifierKey]).contentType {
            self = type
        } else if let type = UTType(filenameExtension: url.pathExtension) {
            self = type
        } else {
            return nil
        }
    }
}
