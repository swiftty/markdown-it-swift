import Foundation

public struct Rule<Cursor, State> {
    public typealias Body = (inout Source<Cursor>, inout State) -> Bool

    public var name: String
    public var terminatedBy: Set<String> = []
    public var isEnabled: Bool = true
    public var body: Body
}

public struct Ruler<Cursor, State> {
    private var rules: [String: [Rule<Cursor, State>]] = [:]

    init(rules ruleList: [Rule<Cursor, State>]) {
        var chains: Set<String> = [""]
        ruleList.forEach {
            chains.formUnion($0.terminatedBy)
        }

        for chain in chains {
            for rule in ruleList {
                guard rule.isEnabled else { continue }
                guard chain.isEmpty || rule.terminatedBy.contains(chain) else { continue }
                rules[chain, default: []].append(rule)
            }
        }
    }

    public func rules(for name: String) -> [Rule<Cursor, State>] {
        return rules[name] ?? []
    }
}

