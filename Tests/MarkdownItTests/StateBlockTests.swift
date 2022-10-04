import XCTest
@testable import MarkdownIt

private func flattenTypes(_ tokens: [Token], level: Int = 0) -> [String] {
    tokens.flatMap {
        [String(repeating: "  ", count: level) + (level > 0 ? "└ " : "") + $0.type]
        + flattenTypes($0.children, level: level + 1)
    }
}

private func parse(_ source: String) -> [Token] {
    let md = MarkdownIt()
    return md.parse(source)
}

class StateBlockTests: XCTestCase {
    func test_state() {
        func state(_ source: String) -> StateBlock {
            StateBlock(source: source[...], md: MarkdownIt())
        }

        let state1 = state("""
        abcdef
        ghijkl

        end
        """)
        XCTAssertEqual(state1.lines.map(\.string), [
            "abcdef",
            "ghijkl",
            "",
            "end"
        ])

        let state2 = state("""
        \tabc
          def
          \

        """)
        XCTAssertEqual(state2.lines[0].indent, 1)
        XCTAssertEqual(state2.lines[0].spaces, 4)
        XCTAssertEqual(state2.lines[1].indent, 2)
        XCTAssertEqual(state2.lines[1].spaces, 2)
        XCTAssertEqual(state2.lines[1].isEmpty, false)
        XCTAssertEqual(state2.lines[2].indent, 2)
        XCTAssertEqual(state2.lines[2].isEmpty, true)
    }

    func test_paragraph() {
        let tokens = parse("""
        abcdef
        ghijkl

        end
        """)

        XCTAssertEqual(flattenTypes(tokens), [
            "paragraph_open",
            "inline",
            "  └ text",
            "paragraph_close",
            "paragraph_open",
            "inline",
            "  └ text",
            "paragraph_close"
        ])
    }

    func test_heading() {
        let tokens = parse("""
        # title
          ## subtitle
        """)

        XCTAssertEqual(flattenTypes(tokens), [
            "heading_open",
            "inline",
            "  └ text",
            "heading_close",
            "heading_open",
            "inline",
            "  └ text",
            "heading_close"
        ])
    }

    func test_hr() {
        let tokens = parse("""
        - -  -
        """)

        XCTAssertEqual(flattenTypes(tokens), [
            "hr"
        ])
        XCTAssertEqual(tokens.first?.markup, "---")
    }
}
