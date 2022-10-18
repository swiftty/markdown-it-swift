import Foundation

public protocol ContextKey {
    associatedtype Context

    static var defaultContext: Context { get }
}

public struct State<Input> {
    public var input: Input
    public var tokens: [Token]

    public let md: MarkdownIt

    private var contexts: [ObjectIdentifier: Any] = [:]

    init(input: Input, tokens: [Token], md: MarkdownIt) {
        self.input = input
        self.tokens = tokens
        self.md = md
    }
}

extension State {
    public subscript <K>(key: K.Type) -> K.Context where K: ContextKey {
        get {
            if let context = contexts[ObjectIdentifier(key)] as? K.Context {
                return context
            }
            return key.defaultContext
        }
        set {
            contexts[ObjectIdentifier(key)] = newValue
        }
    }
}
