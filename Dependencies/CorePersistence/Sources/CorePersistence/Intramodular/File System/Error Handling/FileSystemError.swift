//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

public enum FileSystemError: _ErrorX {
    case couldNotAccessWithSecureScope(URL)
    case fileNotFound(URL)
    case invalidPathAppend(FilePath)
    case isNotFileURL(URL)
    
    case unknown(AnyError)
    
    public init?(_catchAll error: AnyError) throws {
        self = .unknown(error)
    }
}
