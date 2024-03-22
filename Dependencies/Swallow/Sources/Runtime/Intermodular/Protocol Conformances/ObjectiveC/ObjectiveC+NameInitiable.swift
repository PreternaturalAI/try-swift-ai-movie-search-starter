//
// Copyright (c) Vatsal Manot
//

import ObjectiveC
import Swallow

extension Selector: NameInitiable {
	public init(name: String) {
		self = .init(stringLiteral: name)
	}
}
