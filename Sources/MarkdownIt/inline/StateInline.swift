import Foundation

public struct StateInline {
    public struct Line {
        public var string: Substring

        public var isEmpty: Bool {
            string.isEmpty
        }
    }
    public struct Delimiter {

    }
    public var source: Substring { line.string }
    public var md: MarkdownIt
    public var tokens: [Token]

    public var line: Line
    public var delimiters: [Delimiter] = []

    public var level = 0

    public var pending = ""
    public var pendingLevel = 0

    public init(source: Substring, md: MarkdownIt, tokens: [Token]) {
        self.md = md
        self.tokens = tokens
        self.line = .init(string: source)
    }
}

extension StateInline {
    public mutating func pushPending() {
        var token = Token(type: "text", nesting: .closing(self: true), level: pendingLevel)
        token.content = pending
        tokens.append(token)
        pending = ""
    }
}

extension StateInline.Line {
    public mutating func consume(reversed: Bool = false) -> Character {
        let peek = _peek(reversed: reversed)
        defer {
            if peek.hasNext {
                let next = string.index(peek.index, offsetBy: reversed ? -1 : 1)
                string = reversed ? string[..<next] : string[next...]
            }
        }
        return string[peek.index]
    }

    public func peek(reversed: Bool = false) -> Character {
        string[_peek(reversed: reversed).index]
    }

    private func _peek(reversed: Bool) -> (index: Substring.Index, hasNext: Bool) {
        if reversed {
            let end = string.index(before: string.endIndex)
            return (end, end > string.startIndex)
        } else {
            let start = string.startIndex
            return (start, start < string.endIndex)
        }
    }
}
