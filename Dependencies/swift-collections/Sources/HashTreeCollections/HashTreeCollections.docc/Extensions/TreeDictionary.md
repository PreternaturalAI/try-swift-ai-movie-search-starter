# ``HashTreeCollections/TreeDictionary``

<!-- Summary -->

<!-- ## Overview -->

## Topics

### Collection Views

`TreeDictionary` provides the customary dictionary views, `keys` and
`values`. These are collection types that are projections of the dictionary
itself, with elements that match only the keys or values of the dictionary,
respectively. The `Keys` view is notable in that it provides operations for
subtracting and intersecting the keys of two dictionaries, allowing for easy
detection of inserted and removed items between two snapshots of the same
dictionary. Because `TreeDictionary` needs to invalidate indices on every
mutation, its `Values` view is not a `MutableCollection`.

- ``Keys-swift.struct``
- ``Values-swift.struct``
- ``keys-swift.property``
- ``values-swift.property``

### Creating a Dictionary

- ``init()``
- ``init(_:)-111p1``
- ``init(_:)-9atjh``
- ``init(uniqueKeysWithValues:)-2hosl``
- ``init(uniqueKeysWithValues:)-92276``
- ``init(_:uniquingKeysWith:)-6nofo``
- ``init(_:uniquingKeysWith:)-99403``
- ``init(grouping:by:)-a4ma``
- ``init(grouping:by:)-4he86``
- ``init(keys:valueGenerator:)``


### Inspecting a Dictionary

- ``isEmpty-6icj0``
- ``count-ibl8``

### Accessing Keys and Values

- ``subscript(_:)-8gx3j``
- ``subscript(_:default:)``
- ``index(forKey:)``

### Adding or Updating Keys and Values

Beyond the standard `updateValue(_:forKey:)` method, `TreeDictionary` also
provides additional `updateValue` variants that take closure arguments. These
provide a more straightforward way to perform in-place mutations on dictionary
values (compared to mutating values through the corresponding subscript
operation.) `TreeDictionary` also provides the standard `merge` and
`merging` operations for combining dictionary values.

- ``updateValue(_:forKey:)``
- ``updateValue(forKey:with:)``
- ``updateValue(forKey:default:with:)``
- ``merge(_:uniquingKeysWith:)-59cm5``
- ``merge(_:uniquingKeysWith:)-38axt``
- ``merge(_:uniquingKeysWith:)-3s4cw``
- ``merging(_:uniquingKeysWith:)-3khxe``
- ``merging(_:uniquingKeysWith:)-1k63w``
- ``merging(_:uniquingKeysWith:)-87wp7``

### Removing Keys and Values

- ``removeValue(forKey:)``
- ``remove(at:)``
- ``filter(_:)``

### Comparing Dictionaries

- ``==(_:_:)``

### Transforming a Dictionary

- ``mapValues(_:)``
- ``compactMapValues(_:)``

