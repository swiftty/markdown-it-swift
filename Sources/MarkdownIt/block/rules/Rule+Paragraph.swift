import Foundation

extension Rules {
    public struct Paragraph: Rule {
        public typealias Input = Source<Cursors.Line>

        public var name: String { "paragraph" }
        public var isEnabled: Bool = true

        public func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool {
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

            state.push(.opening("paragraph"))
            state.push(.inline("inline")) { token in
                token.content = content
            }
            state.push(.closing("paragraph"))

            return true
        }
    }
}
