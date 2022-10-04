import Foundation

extension Rule where State == StateCore {
    public static var inline: Body {
        return { state, cursor in
            for (i, var token) in state.tokens.enumerated() where token.type == "inline" {
                state.md.inline(token.content[...], md: state.md, tokens: &token.children)
                state.tokens[i] = token
            }
            return true
        }
    }
}
