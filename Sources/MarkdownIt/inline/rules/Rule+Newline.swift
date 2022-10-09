import Foundation

extension Rule<Cursors.Character, StateInline> {
    public static var newline: Body {
        return { source, state in
            guard source.peek() == "\n" else { return false }

            // '  \n' -> hardbreak
            if state.pending.hasSuffix(" ") {
                let isHard = state.pending.hasSuffix("  ")
                state.pending.trim(after: { $0 == " " })
                state.pushPendingIfNeeded()
                state.tokens.push(isHard ? "hardbreak" : "softbreak", nesting: .closing(self: true))
            } else {
                state.pushPendingIfNeeded()
                state.tokens.push("softbreak", nesting: .closing(self: true))
            }

            source.consume()  // "\n"
            source.consume(while: \.isSpace)

            return true
        }
    }
}
