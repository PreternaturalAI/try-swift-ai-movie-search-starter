//
// Copyright (c) Vatsal Manot
//

import Compute
import Merge
import OrderedCollections
import Swallow

// TODO: Rename ResourceCoordinators to ResourcesProducer maybe and introduce _AsyncResourcesProducer to expose rules of engagement (latency etc.)?
public final class _SyncedAsyncResources<ResourceCoordinators: AsyncSequence>: ObservableObject where ResourceCoordinators.Element: _AsyncResourceCoordinator {
    public typealias ResourceCoordinator = ResourceCoordinators.Element
    public typealias ResourceValue = ResourceCoordinator.Value
    public typealias Element = _SyncedAsyncResource<ResourceCoordinator>
    
    public typealias ResolvedResourceCoordinators = OrderedDictionary<ResourceCoordinator.ID, Element>
    public typealias ResolvedResourceValues = OrderedDictionary<ResourceCoordinator.ID, ResourceValue>
    
    public let objectWillChange = ObservableObjectPublisher()
    
    private let stream: AsyncThrowingStream<ResourceCoordinators, Error>
    
    @MutexProtected
    private var resolvedResourceCoordinators: ResolvedResourceCoordinators = [:]
    
    public var _cachedOrSynchronousSnapshot: ResolvedResourceValues {
        resolvedResourceCoordinators.compactMapValues({ try? $0._cachedOrSynchronouslyAccessedValue })
    }
    
    public init(stream: AsyncThrowingStream<ResourceCoordinators, Error>) {        
        self.stream = stream
        
        Task {
            try! await start()
        }
    }
    
    private func start() async throws {
        var iterator = stream.makeAsyncIterator()
        
        var elementFulfillment: (any _SwiftTaskProtocol)?
        
        while let next = try await iterator.next() {
            elementFulfillment?.cancel()
            elementFulfillment = Task {
                try await fulfill(with: next)
            }
        }
    }
    
    private func fulfill(
        with sequence: ResourceCoordinators
    ) async throws {
        var allSeen: Set<ResourceCoordinator.ID> = []
        
        var elements = self.resolvedResourceCoordinators
        
        for try await coordinator in sequence {
            elements[coordinator.id] = .init(parent: self, coordinator: coordinator)
            
            allSeen.insert(coordinator.id)
        }
        
        let toBeRemoved = Set(elements.keys).subtracting(allSeen)
        
        toBeRemoved.forEach {
            elements[$0]?.removeFromParent()
            
            elements.removeValue(forKey: $0)
        }
        
        assert(elements.count == allSeen.count)
        
        self.$resolvedResourceCoordinators.assignedValue = elements
        
        await MainActor.run {
            objectWillChange.send()
        }
    }
}
