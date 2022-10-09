import Foundation

public struct StateInline {
    public var tokens: Tokens

    var pending = ""
    var pendingLevel = 0

    init(tokens: [Token]) {
        self.tokens = Tokens(tokens)
    }
}

extension StateInline {
    mutating func pushPendingIfNeeded() {
        guard !pending.isEmpty else { return }
        pushPending()
    }

    mutating func pushPending() {
        tokens.push("text", nesting: .closing(self: true)) {
            $0.block = false
            $0.level = pendingLevel
            $0.content = pending
        }
        pending = ""
    }
}
