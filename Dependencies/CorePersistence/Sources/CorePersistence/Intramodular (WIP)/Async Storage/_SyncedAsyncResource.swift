//
// Copyright (c) Vatsal Manot
//

import Compute
import Merge
import Swallow

public final class _SyncedAsyncResource<Coordinator: _AsyncResourceCoordinator> {
    public enum _ExistentialStatus {
        case regular
        case zombie
    }
    
    public let _upstreamValuesPublisher = PassthroughSubject<Coordinator.Value, Never>()
    
    public var upstreamValuesPublisher: AnyPublisher<Coordinator.Value, Never> {
        _upstreamValuesPublisher.eraseToAnyPublisher()
    }
    
    private weak var parent: (any ObservableObject)?
    private var _valueResolutionTask: (any _SwiftTaskProtocol)?
    private let _resolvedValue = _AsyncGenerationBox<Coordinator.Value, Error>()
    
    let coordinator: Coordinator
        
    var _cachedOrSynchronouslyAccessedValue: Coordinator.Value {
        get throws {
            if let value = _resolvedValue.lastValue {
                return try value.get()
            } else {
                _valueResolutionTask?.cancel()
                
                let value = try coordinator._getSynchronously()
                
                _resolvedValue.fulfill(with: value)
                
                return value
            }
        }
    }
    
    init(
        parent: any ObservableObject,
        coordinator: Coordinator
    ) {
        self.parent = parent
        self.coordinator = coordinator
        
        resolveLatest()
    }
    
    public func send(
        _ value: Coordinator.Value
    ) async where Coordinator: _AsyncMutableResourceCoordinator {
        guard parent != nil else {
            assertionFailure()
            
            return
        }
        
        _valueResolutionTask?.cancel()
        _resolvedValue.cancel()
        
        _resolvedValue.fulfill(with: value) // FIXME:?
        
        do {
            try await coordinator.update(value)
        } catch {
            assertionFailure()
        }
    }
    
    private func resolveLatest() {
        _valueResolutionTask = Task { [weak self] in
            let value = await Result {
                try await self.unwrap().coordinator.get()
            }
            
            guard let `self` = self else {
                return
            }
            
            try Task.checkCancellation()
            
            do {
                try _upstreamValuesPublisher.send(value.get())
            } catch {
                assertionFailure(error)
            }
            
            self._resolvedValue.fulfill(with: value)
            
            Task { @MainActor [weak self] in
                try! self?.parent?._opaque_publishToObjectWillChange()
            }
        }
    }
    
    public func removeFromParent() {
        _resolvedValue.cancel()
        
        parent = nil
    }
}
