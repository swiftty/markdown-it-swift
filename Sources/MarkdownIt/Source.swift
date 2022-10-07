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

extension Source {
    public static func fromString(_ string: String) -> (Source, CharacterCursor, LineCursor) {
        let source = Source(string)
        let ch = CharacterCursor(index: source._string.startIndex)
        var ch1 = ch
        source.consume(&ch1, while: !\.isNewline)
        source.consume(&ch1, if: \.isNewline)
        let line = LineCursor(startIndex: ch.index, endIndex: ch1.index)
        return (source, ch, line)
    }
}

extension Source {
    public struct CharacterCursor: Hashable, Comparable {
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.index < rhs.index
        }

        fileprivate var index: Substring.Index
    }

    public subscript (cursor: CharacterCursor) -> Character {
        cursor.index < _string.endIndex ? _string[cursor.index] : "\0"
    }

    public func consume(_ cursor: inout CharacterCursor) {
        cursor.index = _string.index(cursor.index, offsetBy: 1, limitedBy: _string.endIndex) ?? _string.endIndex
    }

    @inlinable
    public func consume(_ cursor: inout CharacterCursor, while cond: (Character) -> Bool) {
        while !isEmpty, cond(self[cursor]) {
            consume(&cursor)
        }
    }

    @inlinable
    public func consume(_ cursor: inout CharacterCursor, while ch: Character) {
        consume(&cursor, while: { $0 == ch })
    }

    @inlinable
    public func consume(_ cursor: inout CharacterCursor, if cond: (Character) -> Bool) {
        if !isEmpty, cond(self[cursor]) {
            consume(&cursor)
        }
    }

    @inlinable
    public func consume(_ cursor: inout CharacterCursor, if ch: Character) {
        consume(&cursor, if: { $0 == ch })
    }
}

extension Source {
    public struct LineCursor: Hashable, Comparable {
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.startIndex < rhs.startIndex
        }

        public var isEmpty: Bool {
            (startIndex..<endIndex).isEmpty
        }

        fileprivate var startIndex: Substring.Index
        fileprivate var endIndex: Substring.Index
    }

    public subscript (cursor: LineCursor) -> Substring {
        _string[cursor.startIndex..<cursor.endIndex]
    }

    public func consume(_ cursor: inout LineCursor) {
        var ch = CharacterCursor(index: cursor.endIndex)
        consume(&ch)
        cursor.startIndex = ch.index
        consume(&ch, while: !\.isNewline)
        consume(&ch, if: \.isNewline)
        cursor.endIndex = ch.index
    }
}
