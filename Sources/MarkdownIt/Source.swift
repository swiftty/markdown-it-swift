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
