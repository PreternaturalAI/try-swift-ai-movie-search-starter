//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import Swallow

protocol _FileBundleElement: AnyObject {
    var fileWrapper: _AsyncFileWrapper? { get }
    var knownFileURL: URL? { get throws }
}

protocol _FileBundleContainerElement: _FileBundleElement, ObservableObject {
    func childDidUpdate(_ node: any _FileBundleChild)
}
