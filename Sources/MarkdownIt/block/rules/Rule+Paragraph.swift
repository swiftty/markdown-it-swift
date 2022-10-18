import Foundation

extension Rules {
    public struct Paragraph: NewRule {
        public typealias Cursor = Source<Cursors.Line>

        public var name: String { "paragraph" }
        public var isEnabled: Bool = true

        public func apply(state: inout NewState<Cursor>, terminates: Terminator<Cursor>?) -> Bool {
            let startIndex = state.input.consume().cursor.index
            var endIndex = state.input.cursor.endIndex

            while !state.input.isEmpty {
                endIndex = state.input.cursor.endIndex

                var line = state.input.consume()
                guard !line.isEmpty else { break }

                if line.shouldBeCodeBlock(on: state.block.indent) {
                    continue
                }

                if state.terminate(for: Paragraph.self, terminates) {
                    break
                }
            }

            let content = state.input.content(in: startIndex..<endIndex).trimmed()

            state.push("paragraph_open", nesting: .opening)
            state.push("inline", nesting: .closing(self: true)) { token in
                token.content = content
            }
            state.push("paragraph_close", nesting: .closing())

            return true
        }
    }
}
