import Foundation

extension Rule<Cursors.Line, StateBlock> {
    /// fences (``` lang, ~~~ lang)
    public static var fence: Body {
        return { lines, state in
            var line = lines.peek()

            guard !line.shouldBeCodeBlock(on: state.blockIndent) else { return false }

            let marker = line.consume()
            guard ["~", "`"].contains(marker) else { return false }

            let markerLength = line.consume(while: marker) + 1
            if markerLength < 3 { return false }

            lines.consume()

            let start = lines.cursor.startIndex
            var end = start
            while !lines.isEmpty {
                end = lines.cursor.startIndex
                line = lines.consume()
                let leadingSpaceWidth = line.leadingSpaceWidth
                if leadingSpaceWidth < state.blockIndent {
                    // non-empty line with negative indent should stop the list:
                    // - ```
                    //  test
                    break
                }

                line.consume(while: \.isSpace)
                if line.consume() == marker { continue }
                if leadingSpaceWidth - state.blockIndent >= 4 { continue }

                if line.consume(while: marker) + 1 < markerLength { continue }

                var remainings = line.content
                remainings.trim(after: \.isSpace)
                if remainings.isEmpty {
                    break
                }
            }

            state.tokens.push("fence", nesting: .closing(self: true)) {
                $0.content = lines.content(in: start..<end).trimmed()
                $0.markup = String(repeating: String(marker), count: markerLength)
            }
            return true
        }
    }
}

extension Rules {
    public struct Fence: NewRule {
        public typealias Cursor = Source<Cursors.Line>

        public var name: String { "heading" }
        public var isEnabled: Bool = true

        public func apply(state: inout NewState<Cursor>, terminates: Terminator<Cursor>?) -> Bool {
            var line = state.input.peek()

            guard !line.shouldBeCodeBlock(on: state.indent) else { return false }

            let marker = line.consume()
            guard ["~", "`"].contains(marker) else { return false }

            let markerLength = line.consume(while: marker) + 1
            if markerLength < 3 { return false }

            state.input.consume()

            let start = state.input.cursor.startIndex
            var end = start
            while !state.input.isEmpty {
                end = state.input.cursor.startIndex
                line = state.input.consume()
                let leadingSpaceWidth = line.leadingSpaceWidth
                if leadingSpaceWidth < state.indent {
                    // non-empty line with negative indent should stop the list:
                    // - ```
                    //  test
                    break
                }

                line.consume(while: \.isSpace)
                if line.consume() == marker { continue }
                if leadingSpaceWidth - state.indent >= 4 { continue }

                if line.consume(while: marker) + 1 < markerLength { continue }

                var remainings = line.content
                remainings.trim(after: \.isSpace)
                if remainings.isEmpty {
                    break
                }
            }

            let content = state.input.content(in: start..<end).trimmed()
            state.push("fence", nesting: .closing(self: true)) {
                $0.content = content
                $0.markup = String(repeating: String(marker), count: markerLength)
            }
            return true
        }
    }
}
