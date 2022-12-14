import Foundation

extension Rules {
    public struct HorizontalRule: Rule {
        public typealias Input = Source<Cursors.Line>

        public var name: String { "hr" }
        public var isEnabled: Bool = true

        public func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool {
            var line = state.input.consume()

            guard !line.shouldBeCodeBlock(on: state.block.indent) else { return false }

            let marker = line.consume()
            guard ["*", "-", "_"].contains(marker) else { return false }

            // markers can be mixed with spaces, but there should be at least 3 of them
            var cnt = 1
            while !line.isEmpty {
                let ch = line.consume()
                guard ch.isSpace || ch == marker else { return false }
                cnt += ch == marker ? 1 : 0
            }

            guard cnt >= 3 else { return false }

            state.push(.inline("hr")) { token in
                token.markup = .init(repeating: marker, count: cnt)
            }

            return true
        }
    }
}
