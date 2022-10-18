import Foundation

public enum BlockContext: ContextKey {
    public struct Context {
        public var level = 0
        public var indent = 0
    }

    public static var defaultContext: Context { .init() }
}

extension State<Source<Cursors.Line>> {
    public var block: BlockContext.Context {
        get { self[BlockContext.self] }
        set { self[BlockContext.self] = newValue }
    }

    public mutating func push(_ depth: Token.Depth, _ modify: (inout Token) -> Void = { _ in }) {
        var token = Token(depth: depth, level: block.level)
        token.block = true

        block.level += depth.level

        modify(&token)
        tokens.append(token)
    }

    public func terminate<R>(for rule: R.Type, _ outer: ((State) -> Bool)?) -> Bool {
        if let outer {
            return outer(self)
        }
        return terminate(with: md.block.ruler.rules(for: rule))
    }

    public func terminate(_ outer: ((State) -> Bool)?) -> Bool {
        if let outer {
            return outer(self)
        }
        return terminate(with: md.block.ruler.rules())
    }

    private func terminate(with rules: [any Rule]) -> Bool {
        var state = self
        for rule in rules {
            if rule(state: &state) {
                return true
            }
        }
        return false
    }
}
