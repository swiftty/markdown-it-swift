import Foundation

public struct Source: Equatable {
    public struct Location: Equatable {
        public var row, col: Int
    }

    @inlinable
    public subscript (r: some RangeExpression<Substring.Index>) -> Substring {
        _string[r]
    }

    @inlinable
    public var range: Range<Substring.Index> {
        _cursor..<_string.endIndex
    }

    @inlinable
    public var isEmpty: Bool {
        range.isEmpty
    }

    @inlinable
    public var isNewline: Bool {
        peek().isNewline || isEmpty
    }

    @inlinable
    public var cursor: Substring.Index { _cursor }

    @inlinable
    public var location: Location { _location }

    @usableFromInline private(set) var _string: Substring
    @usableFromInline private(set) var _cursor: Substring.Index
    @usableFromInline private(set) var _location: Location

    @usableFromInline private(set) var _current: Character

    public init(_ wholeString: String) {
        _string = wholeString[...]
        _cursor = _string.startIndex
        _location = .init(row: 0, col: 0)
        _current = _string.isEmpty ? "\0" : _string[_cursor]
    }

    @discardableResult
    @inlinable
    public mutating func consume() -> Character {
        defer {
            let end = _string.endIndex
            let next = _string.index(_cursor, offsetBy: 1, limitedBy: end) ?? end
            if next < end {
                _current = _string[next]
                _cursor = next
                _location.increment(with: _current)
            } else {
                _cursor = end
                _current = "\0"
            }
        }
        return _current
    }

    @inlinable
    public func peek() -> Character {
        return _current
    }
}

extension Source {
    @inlinable
    public func distance(from other: Self) -> Int {
        assert(_string == other._string)
        return _string.distance(from: other._cursor, to: _cursor)
    }
}

extension Source {
    @inlinable
    public mutating func consume(while cond: (Character) -> Bool) {
        while !isEmpty, cond(peek()) {
            consume()
        }
    }

    @inlinable
    public mutating func consume(while ch: Character) {
        consume(while: { $0 == ch })
    }

    @inlinable
    public mutating func consume(if cond: (Character) -> Bool) {
        if !isEmpty, cond(peek()) {
            consume()
        }
    }

    @inlinable
    public mutating func consume(if ch: Character) {
        consume(if: { $0 == ch })
    }
}

extension Source {
    @inlinable
    public mutating func seek(to line: Int) {

    }
}

extension Source {
    public mutating func shouldBeCodeBlock(on blockIndent: Int) -> Bool {
        let start = _cursor
        consume(while: \.isWhitespace && !\.isNewline)
        let spaces = _string.distance(from: start, to: _cursor)
        return spaces - blockIndent >= 4
    }
}

extension Source: CustomStringConvertible {
    public var description: String {
        let end = _string.index(_cursor, offsetBy: 3, limitedBy: _string.endIndex) ?? _string.endIndex
        return """
        Source([\
        \(_location.row):\(_location.col)], \
        \(_current.debugDescription), \
        \(_string[_cursor..<end].debugDescription)\
        )
        """
    }
}

extension Source.Location {
    @usableFromInline
    mutating func increment(with ch: Character) {
        if ch.isNewline {
            row += 1
            col = 0
        } else {
            col += 1
        }
    }
}

extension Source {
    public func lines() -> Lines {
        Lines(base: self)
    }

    private init(line source: inout Source) {
        _cursor = source._cursor
        _location = source._location
        _current = source._current
        source.consume(while: !\.isNewline)
        _string = source._string[_cursor..<source._cursor]
        source.consume(if: \.isNewline)
    }

    public struct Lines {
        public var isEmpty: Bool {
            current.isEmpty && base.isEmpty
        }

        public private(set) var cursor = 0

        private var base: Source
        private var current: Source

        init(base: Source) {
            self.base = base
            current = Source(line: &self.base)
        }

        @discardableResult
        public mutating func consume() -> Source {
            defer {
                if !current.isEmpty {
                    cursor += 1
                }
                current = Source(line: &base)
            }
            return current
        }

        public func peek() -> Source {
            return current
        }

        public func currentState() -> Source {
            base
        }

        public func string(from ranges: [Range<Substring.Index>]) -> Substring {
            var minIndex, maxIndex: Substring.Index!
            for range in ranges {
                minIndex = (minIndex == nil
                            ? range.lowerBound
                            : min(range.lowerBound, minIndex))

                maxIndex = (maxIndex == nil
                            ? range.upperBound
                            : max(range.upperBound, maxIndex))
            }
            return base[minIndex..<maxIndex]
        }
    }
}

public enum Cursors {
    public struct Character: Hashable, Comparable {
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.index < rhs.index
        }

        fileprivate var index: Substring.Index
    }

    public struct Line: Hashable, Comparable {
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.startIndex < rhs.startIndex
        }

        public var isEmpty: Bool {
            (startIndex..<endIndex).isEmpty
        }

        fileprivate var startIndex: Substring.Index
        fileprivate var endIndex: Substring.Index
    }
}

public struct NewSource<Cursor> {
    public private(set) var cursor: Cursor
    private let string: Substring
}

extension NewSource<Cursors.Character> {
    public var isEmpty: Bool {
        (cursor.index..<string.endIndex).isEmpty
    }

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

    public mutating func consume() {
        cursor.index = string.index(cursor.index, offsetBy: 1, limitedBy: string.endIndex) ?? string.endIndex
    }

    public mutating func consume(while cond: (Character) -> Bool) {
        while !isEmpty, cond(peek()) {
            consume()
        }
    }

    public mutating func consume(while ch: Character) {
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

extension NewSource<Cursors.Line> {
    public var isEmpty: Bool {
        (cursor.endIndex..<string.endIndex).isEmpty
    }

    public init(_ wholeString: String) {
        string = wholeString[...]

        var ch = NewSource<Cursors.Character>(string)
        ch.consume(while: !\.isNewline)
        ch.consume(if: \.isNewline)
        cursor = .init(startIndex: string.startIndex, endIndex: ch.cursor.index)
    }

    public func peek() -> NewSource<Cursors.Character> {
        .init(string[cursor.startIndex..<cursor.endIndex])
    }

    public mutating func consume() {
        var ch = NewSource<Cursors.Character>(cursor: .init(index: cursor.endIndex), string: string)
        cursor.startIndex = ch.cursor.index
        ch.consume(while: !\.isNewline)
        ch.consume(if: \.isNewline)
        cursor.endIndex = ch.cursor.index
    }
}
