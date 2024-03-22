//
// Copyright (c) Vatsal Manot
//

import Dispatch

@_spi(Internal)
extension DispatchQueue {
    @_spi(Internal)
    public final class _DebouncedView {
        private let debounceInterval: DispatchTimeInterval?
        private let queue: DispatchQueue
        
        private var workItem: DispatchWorkItem?
        
        fileprivate init(queue: DispatchQueue, debounceInterval: DispatchTimeInterval?) {
            self.debounceInterval = debounceInterval
            self.queue = queue
        }
        
        public func schedule(_ action: @escaping () -> Void) {
            workItem?.cancel()
            
            let newWorkItem = DispatchWorkItem { [weak self] in
                action()
                
                self?.workItem = nil
            }
            
            workItem = newWorkItem
            
            if let debounceInterval {
                queue.asyncAfter(deadline: .now() + debounceInterval, execute: newWorkItem)
            } else {
                queue.asyncAfter(deadline: .now() + .milliseconds(10), execute: newWorkItem)
            }
        }
    }
    
    @_spi(Internal)
    public func _debounce(
        for debounceInterval: DispatchTimeInterval? = nil
    ) -> _DebouncedView {
        .init(queue: self, debounceInterval: debounceInterval)
    }
}
