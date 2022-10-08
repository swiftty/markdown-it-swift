import Foundation

struct BlockState {
    var blockIndent = 0
    var level = 0

    var ruler: Ruler<Cursors.Line, BlockState>

    var tokens: [Token] = []
}

extension BlockState {
    func terminate(_ name: String, source: Source<Cursors.Line>) -> Bool {
        var source = source
        var state = self
        for rule in ruler.rules(for: name) {
            if rule.body(&source, &state) {
                return true
            }
        }
        return false
    }
}

extension BlockState {
    mutating func push(_ type: String, nesting: Token.Nesting,
                       _ modify: (inout Token) -> Void = { _ in }) {
        var token = Token(type: type, nesting: nesting, level: level)
        token.block = true

        level += nesting.nextLevel

        modify(&token)
        tokens.append(token)
    }
}

private extension Token.Nesting {
    var nextLevel: Int {
        switch self {
        case .opening: return 1
        case .closing(let flag): return flag ? 0 : -1
        }
    }
}
