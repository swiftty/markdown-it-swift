import Foundation

extension Rule where State == StateCore {
    public static var block: Body {
        return { state, cursor in
            state.md.block(state.source, md: state.md, tokens: &state.tokens)
            return true
        }
    }
}
