import Foundation

public class Dispatcher {
    public typealias Callback = Any? -> Void

    private let instanceIdentifier = NSUUID().UUIDString
    public var tokenGenerator: TokenStream.Generator

    private var callbacks: [Token: Callback] = [:]
    private var isPending: [Token: (Bool)] = [:]
    private var isHandled: [Token: (Bool)] = [:]
    private var isDispatching: Bool = false
    private var pendingPayload: Any?
    
    public init() {
        tokenGenerator = TokenStream(prefix: instanceIdentifier).generate()
    }
    
    ///MARK: Public

    public func register(callback: Callback) -> Token {
        if let id = tokenGenerator.next() {
            callbacks[id] = callback
            return id
        }
        
        preconditionFailure("Dispatcher.register(...): Failed to generate token for registration.")
    }
    
    public func unregister(id: Token) {
        assertTokenOwnership(id)
        precondition(contains(callbacks.keys, id), "Dispatcher.unregister(...): `\(id)` does not map to a registered callback.")
        callbacks.removeValueForKey(id)
    }
    
    public func waitFor(ids: [Token]) {
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
    
    public func dispatch(payload: Any?) {
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

    private func assertTokenOwnership(id: Token) {
        assert(id.prefix == instanceIdentifier, "Token is owned by a different dispatcher")
    }
    
    private func invokeCallback(id: Token) {
        isPending[id] = true
        callbacks[id]!(pendingPayload)
        isHandled[id] = true
    }
    
    private func startDispatching(payload: Any?) {
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

extension Dispatcher {
    public struct Token: Equatable, Hashable {
        private init(_ prefix: String, _ index: Int) {
            self.value = "\(prefix)_\(index)"
            self.prefix = prefix
        }
        private let value: String
        private let prefix: String
        public var hashValue: Int { return value.hashValue }
    }

    public struct TokenStream {
        let prefix: String
    }
}

public func ==(lhs: Dispatcher.Token, rhs: Dispatcher.Token) -> Bool {
    return lhs.value == rhs.value
}

extension Dispatcher.TokenStream: CollectionType {
    typealias Index = Int
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return Int.max }
    
    public subscript(index: Int) -> Dispatcher.Token {
        get { return Dispatcher.Token(prefix, index) }
    }
    
    public func generate() -> IndexingGenerator<Dispatcher.TokenStream> {
        return IndexingGenerator(self)
    }
}