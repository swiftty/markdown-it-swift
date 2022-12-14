import Foundation

extension Rules {
    public struct Heading: Rule {
        public typealias Input = Source<Cursors.Line>

        public var name: String { "heading" }
        public var isEnabled: Bool = true

        public func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool {
            var line = state.input.consume()

            guard !line.shouldBeCodeBlock(on: state.block.indent) else { return false }
            guard line.consume() == "#" else { return false }

            var level = 1
            while line.peek() == "#" {
                level += 1
                line.consume()
                if level > 6 {
                    return false
                }
            }

            guard line.consume().isSpace else { return false }

            // Let's cut tails like '    ###  ' from the end of string
            var content = line.content
            content.trim(after: \.isWhitespace)
            content.trim(after: { $0 == "#" })

            let markup = String(repeating: "#", count: level)
            state.push(.opening("heading")) { token in
                token.markup = markup
            }
            state.push(.inline("inline")) { token in
                token.content = String(content)
            }
            state.push(.closing("heading")) { token in
                token.markup = markup
            }

            return true
        }
    }
}
