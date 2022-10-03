import Foundation

public struct Rule<State> {
    public var name: String
    public var alias: Set<String> = []
    public var isEnabled: Bool = true
    public var body: (_ state: inout State, _ cursor: Int) -> Bool
}

public struct Ruler<State> {
    private class Cache {
        var rules: [String: [Rule<State>]] = [:]
        var dirty = true

        subscript (name: String) -> [Rule<State>] {
            rules[name] ?? []
        }

        func compile(rules ruleList: [Rule<State>]) {
            dirty = false
            rules = [:]

            var chains: Set<String> = [""]
            ruleList.forEach {
                chains.formUnion($0.alias)
            }

            for chain in chains {
                for rule in ruleList {
                    guard rule.isEnabled else { continue }
                    guard chain.isEmpty || rule.alias.contains(chain) else { continue }
                    rules[chain, default: []].append(rule)
                }
            }
        }
    }

    var rules: [Rule<State>] = []
    private let cache = Cache()

    public mutating func append(_ rule: Rule<State>) {
        rules.append(rule)
        cache.dirty = true
    }

    public func rules(for name: String) -> [Rule<State>] {
        if cache.dirty {
            cache.compile(rules: rules)
        }
        return cache[name]
    }
}
