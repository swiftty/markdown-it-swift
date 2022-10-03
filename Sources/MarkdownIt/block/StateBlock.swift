import Foundation

public struct StateBlock {
    public struct Line {
        public var string: Substring
        public var indent = 0
        public var spaces = 0

        public var isEmpty: Bool {
            string.index(string.startIndex, offsetBy: indent) >= string.endIndex
        }
    }

    public var source: Substring
    public var tokens: [Token] = []
    public var md: MarkdownIt

    public var cursor = 0
    public var parentType: String = "root"

    public var lines: [Line] = []
    public var blockIndent = 0
    public var level = 0

    public init(source: Substring, tokens: [Token] = [], md: MarkdownIt) {
        self.source = source
        self.tokens = tokens
        self.md = md

        var foundIndent = false
        var indent = 0
        var offset = 0
        var start = source.startIndex
        for i in source.indices {
            let ch = source[i]
            if !foundIndent {
                if ch.isWhitespace && !ch.isNewline {
                    indent += 1
                    offset += ch == "\t" ? 4 - offset % 4 : 1
                    continue
                } else {
                    foundIndent = true
                }
            }

            if ch.isNewline {
                lines.append(.init(string: source[start..<i], indent: indent, spaces: offset))

                start = source.index(i, offsetBy: 1)
                foundIndent = false
                indent = 0
                offset = 0
            }
        }
        lines.append(.init(string: source[start..<source.endIndex], indent: indent, spaces: offset))
    }

    public mutating func push(_ type: String, nesting: Token.Nesting, _ mutate: (inout Token) -> Void) {
        var token = Token(type: type, nesting: nesting, level: level)
        token.block = true

        level += nesting.nextLevel

        mutate(&token)
        tokens.append(token)
    }

    public mutating func push(_ type: String, nesting: Token.Nesting) {
        push(type, nesting: nesting, { _ in })
    }

    public func string(in indices: Range<Int>, indent: Int = 0) -> String {
        if indices.isEmpty {
            return ""
        }

        var results: [Substring] = []
        for i in indices {
            let line = lines[i]
            results.append(line.string)
        }
        return results.joined()
    }
}

extension StateBlock.Line {
}

private extension Token.Nesting {
    var nextLevel: Int {
        switch self {
        case .opening: return 1
        case .closing(let flag): return flag ? 0 : -1
        }
    }
}
