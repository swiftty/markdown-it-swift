import Foundation

extension Rules {
    public struct Newline: Rule {
        public typealias Input = Source<Cursors.Character>

        public var name: String { "newline" }
        public var isEnabled: Bool = true

        public func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool {
            guard state.input.consume() == "\n" else { return false }

            // '  \n' -> hardbreak
            if state.inline.pending.hasSuffix(" ") {
                let isHard = state.inline.pending.hasSuffix("  ")
                state.inline.pending.removeLast(isHard ? 2 : 1)
                state.push(.inline(isHard ? "hardbreak" : "softbreak"))
            } else {
                state.push(.inline("softbreak"))
            }

            // skip heading spaces for next line
            state.input.consume(while: \.isSpace)

            return true
        }
    }
}
