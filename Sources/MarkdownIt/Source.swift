import Foundation

public enum Cursors {
    public struct Character: Hashable, Comparable {
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.index < rhs.index
        }

        public fileprivate(set) var index: Substring.Index
    }

    public struct Line: Hashable, Comparable {
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.startIndex < rhs.startIndex
        }

        public var isEmpty: Bool {
            (startIndex..<endIndex).isEmpty
        }

        public fileprivate(set) var startIndex: Substring.Index
        public fileprivate(set) var endIndex: Substring.Index
    }
}

public struct Source<Cursor> {
    public private(set) var cursor: Cursor
    private let string: Substring
}

extension Source<Cursors.Character> {
    public init(_ wholeString: String) {
        string = wholeString[...]
        cursor = .init(index: string.startIndex)
    }

    fileprivate init(_ wholeString: Substring) {
        string = wholeString
        cursor = .init(index: string.startIndex)
    }

    public func peek() -> Character {
        cursor.index < string.endIndex ? string[cursor.index] : "\0"
    }

    @discardableResult
    public mutating func consume() -> Character {
        defer {
            cursor.index = string.index(cursor.index, offsetBy: 1, limitedBy: string.endIndex) ?? string.endIndex
        }
        return peek()
    }

    @discardableResult
    public mutating func consume(while cond: (Character) -> Bool) -> Int {
        var count = 0
        while !isEmpty, cond(peek()) {
            consume()
            count += 1
        }
        return count
    }

    @discardableResult
    public mutating func consume(while ch: Character) -> Int {
        consume(while: { $0 == ch })
    }

    public mutating func consume(if cond: (Character) -> Bool) {
        if !isEmpty, cond(peek()) {
            consume()
        }
    }

    public mutating func consume(if ch: Character) {
        consume(if: { $0 == ch })
    }
}

extension Source<Cursors.Character> {
    public var isEmpty: Bool {
        (cursor.index..<string.endIndex).isEmpty
    }

    public var content: Substring {
        string[cursor.index...]
    }

    public var leadingSpaceWidth: Int {
        var spaces = 0
        for ch in string {
            guard ch.isSpace else { return spaces }
            spaces += ch == "\t" ? 4 - spaces % 4 : 1
        }
        return spaces
    }

    public mutating func shouldBeCodeBlock(on blockIndent: Int) -> Bool {
        consume(while: \.isSpace)
        return leadingSpaceWidth - blockIndent >= 4
    }
}

// MARK: - for line
extension Source<Cursors.Line> {
    public init(_ wholeString: String) {
        string = wholeString[...]

        var ch = Source<Cursors.Character>(string)
        ch.consume(while: !\.isNewline)
        cursor = .init(startIndex: string.startIndex, endIndex: ch.cursor.index)
    }

    public func peek() -> Source<Cursors.Character> {
        return .init(string[cursor.startIndex..<cursor.endIndex])
    }

    @discardableResult
    public mutating func consume() -> Source<Cursors.Character> {
        defer {
            var ch = Source<Cursors.Character>(cursor: .init(index: cursor.endIndex), string: string)
            ch.consume(if: \.isNewline)
            cursor.startIndex = ch.cursor.index
            ch.consume(while: !\.isNewline)
            cursor.endIndex = ch.cursor.index
        }
        return peek()
    }
}

extension Source<Cursors.Line> {
    public var isEmpty: Bool {
        (cursor.startIndex..<string.endIndex).isEmpty
    }

    public func content(in range: Range<Substring.Index>) -> Substring {
        string[range]
    }
}

extension Source: CustomStringConvertible {
    public var description: String {
        switch cursor {
        case let cursor as Cursors.Character:
            let ch = cursor.index < string.endIndex ? String(string[cursor.index]) : ""
            let next = string.index(cursor.index, offsetBy: 1, limitedBy: string.endIndex) ?? string.endIndex
            return """
            Source("\(ch)", remaining: \(string[next...].debugDescription))
            """

        case let cursor as Cursors.Line:
            return """
            Source("\(string[cursor.startIndex..<cursor.endIndex])", remaining: \(string[cursor.endIndex...].debugDescription))
            """

        default:
            return "Source(\"\(string)\", cursor: \(cursor))"
        }
    }
}
