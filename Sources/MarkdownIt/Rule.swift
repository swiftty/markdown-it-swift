import Foundation

// MARK: -
/// namespace
public enum Rules {}

// MARK: -
public protocol Rule<Input>: ContextKey, CustomDebugStringConvertible {
    associatedtype Context = Never
    associatedtype Input

    typealias Terminator<I> = (State<I>) -> Bool

    var name: String { get }
    var isEnabled: Bool { get set }

    @discardableResult
    func apply(state: inout State<Input>, terminates: Terminator<Input>?) -> Bool
}

extension Rule {
    public var debugDescription: String {
        #"Rule { name: "\#(name)", enable: \#(isEnabled) }"#
    }
}

extension Rule where Context == Never {
    public static var defaultContext: Context { fatalError() }
}

extension Rule {
    @discardableResult
    public func callAsFunction<I>(state: inout State<I>, terminates: Terminator<I>? = nil) -> Bool {
        guard var _state = state as? State<Input> else { return false }
        let ret = apply(state: &_state, terminates: terminates == nil ? nil : { state in
            guard let s = state as? State<I> else { return false }
            return terminates?(s) ?? false
        })
        state = _state as! State<I>
        return ret
    }
}

// MARK: -
public struct RuleGraph {
    private var _rules: [(rule: any Rule, terminates: [any Rule.Type])] = []

    private var cache: [ObjectIdentifier?: [any Rule]]?

    public init(rules: [(rule: any Rule, terminates: [any Rule.Type])]) {
        _rules = rules
    }

    public mutating func rules() -> [any Rule] {
        if cache == nil {
            compile()
        }
        return cache?[nil] ?? []
    }

    public mutating func rules<R>(for rule: R.Type) -> [any Rule] {
        if cache == nil {
            compile()
        }
        return cache?[ObjectIdentifier(rule)] ?? []
    }

    private mutating func compile() {
        cache = [:]
        var chains: Set<ObjectIdentifier?> = [nil]
        for (_, terminates) in _rules {
            chains.formUnion(terminates.lazy.map(ObjectIdentifier.init))
        }
        for chain in chains {
            for (rule, terminates) in _rules {
                guard rule.isEnabled else { continue }
                guard chain == nil || terminates.lazy.map(ObjectIdentifier.init).contains(chain) else { continue }
                cache?[chain, default: []].append(rule)
            }
        }
    }
}

public struct RuleSet {
    private var _rules: [any Rule]

    init(rules: [any Rule]) {
        _rules = rules
    }

    public func rules() -> [any Rule] {
        _rules
    }
}
