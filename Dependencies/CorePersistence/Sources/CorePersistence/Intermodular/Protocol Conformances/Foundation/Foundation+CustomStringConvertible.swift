//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension FileManager.SearchPathDirectory: CustomStringConvertible {
    public var description: String {
        switch self {
            case .applicationDirectory:
                return "Applications"
            case .demoApplicationDirectory:
                return "Demo Applications"
            case .developerApplicationDirectory:
                return "Developer Applications"
            case .adminApplicationDirectory:
                return "Admin Applications"
            case .libraryDirectory:
                return "Library"
            case .developerDirectory:
                return "Developer"
            case .userDirectory:
                return "User"
            case .documentationDirectory:
                return "Documentation"
            case .documentDirectory:
                return "Documents"
            case .coreServiceDirectory:
                return "Core Services"
            case .desktopDirectory:
                return "Desktop"
            case .cachesDirectory:
                return "Caches"
            case .applicationSupportDirectory:
                return "Application Support"
            case .allLibrariesDirectory:
                return "All Libraries"
            case .trashDirectory:
                return "Trash"
                
            default: do {
                if #available(iOS 4.0, macCatalyst 13.0, *) {
                    switch self {
                        case .autosavedInformationDirectory:
                            return "Autosave Information"
                        case .downloadsDirectory:
                            return "Downloads Directory"
                        case .inputMethodsDirectory:
                            return "Input Methods Directory"
                        case .moviesDirectory:
                            return "Movies"
                        case .musicDirectory:
                            return "Music"
                        case .picturesDirectory:
                            return "Pictures"
                        case .printerDescriptionDirectory:
                            return "Printer"
                        case .sharedPublicDirectory:
                            return "Public (Shared)"
                        case .preferencePanesDirectory:
                            return "Preference Panes"
                        case .itemReplacementDirectory:
                            return "Temporary"
                        default:
                            break
                    }
                }
            }
            
            return "(Search Path Directory)"
        }
    }
}

extension FileManager.SearchPathDomainMask: CustomStringConvertible {
    public var description: String {
        switch self {
            case .userDomainMask:
                return "User"
            case .localDomainMask:
                return "Local"
            case .networkDomainMask:
                return "Network"
            case .systemDomainMask:
                return "System"
            case .allDomainsMask:
                return "All"
            default:
                return "(Search Path Domain Mask)"
        }
    }
}
