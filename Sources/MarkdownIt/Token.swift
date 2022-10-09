import Foundation

// MARK: - token
public struct Token {
    public enum Nesting: Equatable {
        case opening, closing(`self`: Bool = false)
    }
    public var type: String
    public var nesting: Nesting
    public var level: Int

    public var block = false

    public var content = ""
    public var markup = ""

    public var children: [Token] = []
}

// MARK: - tokens
public struct Tokens {
    fileprivate var values: [Token] = []

    var level = 0

    init(_ values: [Token] = []) {
        self.values = values
    }

    public mutating func push(_ type: String, nesting: Token.Nesting,
                              _ modify: (inout Token) -> Void = { _ in }) {
        var token = Token(type: type, nesting: nesting, level: level)
        token.block = true

        level += nesting.nextLevel

        modify(&token)
        values.append(token)
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

// MARK: - helper
extension Array<Token> {
    public init(_ tokens: Tokens) {
        self = tokens.values
    }
}
