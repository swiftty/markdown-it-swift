import Foundation

struct InlineState {
    var tokens: [Token] = []

    var level = 0

    var pending = ""
    var pendingLevel = 0
}

extension InlineState {
    mutating func pushPending() {
        var token = Token(type: "text", nesting: .closing(self: true), level: pendingLevel)
        token.content = pending
        tokens.append(token)
        pending = ""
    }
}
