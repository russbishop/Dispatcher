import Foundation

public class Dispatcher<ActionType> {
    public typealias Callback = ActionType -> Void

    private let instanceIdentifier = NSUUID().UUIDString
    public var tokenGenerator: DispatchTokenStream.Generator

    private var callbacks: [DispatchToken: Callback] = [:]
    private var isPending: [DispatchToken: (Bool)] = [:]
    private var isHandled: [DispatchToken: (Bool)] = [:]
    private var isDispatching: Bool = false
    private var pendingPayload: ActionType?
    
    public init() {
        tokenGenerator = DispatchTokenStream(prefix: instanceIdentifier).generate()
    }
    
    ///MARK: Public

    public func register(callback: Callback) -> DispatchToken {
        if let id = tokenGenerator.next() {
            callbacks[id] = callback
            return id
        }
        
        preconditionFailure("Dispatcher.register(...): Failed to generate token for registration.")
    }
    
    public func unregister(id: DispatchToken) {
        assertTokenOwnership(id)
        precondition(contains(callbacks.keys, id), "Dispatcher.unregister(...): `\(id)` does not map to a registered callback.")
        callbacks.removeValueForKey(id)
    }
    
    public func waitFor(ids: [DispatchToken]) {
        precondition(isDispatching, "Dispatcher.waitFor(...): Must be invoked while dispatching.")
        
        for id in ids {
            assertTokenOwnership(id)
            if isPending[id]! {
                precondition(isHandled[id] != nil, "Dispatcher.waitFor(...): Circular dependency detected while waiting for `\(id)`.")
                continue
            }
            invokeCallback(id)
        }
    }
    
    public func dispatch(payload: ActionType) {
        precondition(!isDispatching, "Dispatch.dispatch(...): Cannot dispatch in the middle of a dispatch.")

        startDispatching(payload)

        for id in callbacks.keys {
            if isPending[id]! {
                continue
            }
            invokeCallback(id)
        }

        stopDispatching()
    }
    
    ///MARK: Private

    private func assertTokenOwnership(id: DispatchToken) {
        assert(id.prefix == instanceIdentifier, "Token is owned by a different dispatcher")
    }
    
    private func invokeCallback(id: DispatchToken) {
        isPending[id] = true
        callbacks[id]!(pendingPayload!)
        isHandled[id] = true
    }
    
    private func startDispatching(payload: ActionType) {
        for id in callbacks.keys {
            isPending[id] = false
            isHandled[id] = false
        }
        pendingPayload = payload
        isDispatching = true
    }
    
    private func stopDispatching() {
        pendingPayload = nil
        isDispatching = false
    }
}

///MARK: Tokens

public struct DispatchToken: Equatable, Hashable {
    private init(_ prefix: String, _ index: Int) {
        self.value = "\(prefix)_\(index)"
        self.prefix = prefix
    }
    private let value: String
    private let prefix: String
    public var hashValue: Int { return value.hashValue }
}

public struct DispatchTokenStream: CollectionType {
    let prefix: String
    typealias Index = Int
        public var startIndex: Int { return 0 }
        public var endIndex: Int { return Int.max }

        public subscript(index: Int) -> DispatchToken {
            get { return DispatchToken(prefix, index) }
        }

        public func generate() -> IndexingGenerator<DispatchTokenStream> {
            return IndexingGenerator(self)
        }
    }

public func ==(lhs: DispatchToken, rhs: DispatchToken) -> Bool {
    return lhs.value == rhs.value
}

