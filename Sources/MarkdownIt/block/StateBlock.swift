import Foundation

extension NewState where Input == Source<Cursors.Line> {
    public mutating func push(_ type: String, nesting: Token.Nesting,
                              _ modify: (inout Token) -> Void = { _ in }) {
        var token = Token(type: type, nesting: nesting, level: level)
        token.block = true

        level += nesting.nextLevel

        modify(&token)
        tokens.append(token)
    }

    public func terminate<R>(for rule: R.Type, _ outer: ((NewState) -> Bool)?) -> Bool {
        if let outer {
            return outer(self)
        }
        return terminate(with: md.block.ruler.rules(for: rule))
    }

    public func terminate(_ outer: ((NewState) -> Bool)?) -> Bool {
        if let outer {
            return outer(self)
        }
        return terminate(with: md.block.ruler.rules())
    }

    private func terminate(with rules: [any NewRule]) -> Bool {
        var state = self
        for rule in rules {
            if rule(state: &state) {
                return true
            }
        }
        return false
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
