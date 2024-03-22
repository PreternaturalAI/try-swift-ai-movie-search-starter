//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol HadeanIdentifiable: PersistentlyRepresentableType {
    static var hadeanIdentifier: HadeanIdentifier { get }
}

extension HadeanIdentifiable where PersistentTypeRepresentation == HadeanIdentifier {
    public static var persistentTypeRepresentation: PersistentTypeRepresentation {
        hadeanIdentifier
    }
}
