import Foundation

public enum InlineContext: ContextKey {
    public struct Context {
        public var pending = ""
        public var pendingLevel = 0

        public var level = 0
    }

    public static var defaultContext: Context { .init() }
}

extension State<Source<Cursors.Character>> {
    public var inline: InlineContext.Context {
        get { self[InlineContext.self] }
        set { self[InlineContext.self] = newValue }
    }

    public mutating func pushPendingIfNeeded() {
        guard !inline.pending.isEmpty else { return }
        pushPending()
    }

    public mutating func pushPending() {
        var token = Token(type: "text", nesting: .closing(self: true), level: inline.pendingLevel)
        token.block = false
        token.content = inline.pending
        tokens.append(token)

        inline.pending = ""
    }

    public mutating func push(_ type: String, nesting: Token.Nesting,
                              _ modify: (inout Token) -> Void = { _ in }) {
        pushPendingIfNeeded()

        let level = inline.level + nesting.nextLevel

        var token = Token(type: type, nesting: nesting, level: level)
        token.block = false

        inline.level = level

        modify(&token)
        inline.pendingLevel = inline.level
        tokens.append(token)
    }
}
