import Foundation

extension Rules {
    public struct Fence: Rule {
        public typealias Input = Source<Cursors.Line>

        public var name: String { "fence" }
        public var isEnabled: Bool = true

        public func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool {
            var line = state.input.peek()

            guard !line.shouldBeCodeBlock(on: state.block.indent) else { return false }

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
                if leadingSpaceWidth < state.block.indent {
                    // non-empty line with negative indent should stop the list:
                    // - ```
                    //  test
                    break
                }

                line.consume(while: \.isSpace)
                if line.consume() == marker { continue }
                if leadingSpaceWidth - state.block.indent >= 4 { continue }

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
