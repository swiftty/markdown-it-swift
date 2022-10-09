import Foundation

struct StateInline {
    public var tokens: [Token]

    var pending = ""
    var pendingLevel = 0
}

extension StateInline {
    mutating func pushPending() {
        var token = Token(type: "text", nesting: .closing(self: true), level: pendingLevel)
        token.content = pending
        tokens.append(token)
        pending = ""
    }
}
