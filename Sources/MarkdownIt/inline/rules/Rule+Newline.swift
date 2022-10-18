import Foundation

extension Rules {
    public struct Newline: Rule {
        public typealias Input = Source<Cursors.Character>

        public var name: String { "newline" }
        public var isEnabled: Bool = true

        public func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool {
            guard state.input.peek() == "\n" else { return false }

            // '  \n' -> hardbreak
            if state.inline.pending.hasSuffix(" ") {
                let isHard = state.inline.pending.hasSuffix("  ")
                state.inline.pending.trim(after: { $0 == " " })
                state.push(.inline(isHard ? "hardbreak" : "softbreak"))
            } else {
                state.push(.inline("softbreak"))
            }

            state.input.consume()  // "\n"
            state.input.consume(while: \.isSpace)

            return true
        }
    }
}
