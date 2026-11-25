// Runs the cases in Tests/cases.txt against the cleaner: rules-test <cases file>

import Foundation

@main
enum RuleTests {
    static var failures = 0
    static var count = 0

    static func check(_ input: String, _ want: String) {
        count += 1
        let got = cleanURL(input) ?? input
        guard got != want else { return }
        failures += 1
        print("FAIL  \(input)\n  want  \(want)\n  got   \(got)")
    }

    static func main() throws {
        let cases = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
        for line in cases.split(separator: "\n") where !line.hasPrefix("#") {
            let parts = line.split(separator: " ").map(String.init)
            switch (parts.first, parts.count) {
            case ("strip", 3): check(parts[1], parts[2])
            case ("keep", 2): check(parts[1], parts[1])
            default:
                failures += 1
                print("bad line: \(line)")
            }
        }
        // Inputs with spaces, which the cases file cannot hold.
        for text in ["https://example.com/?utm_source=a b", "not a url", "",
                     "see https://example.com/?utm_source=x for details"] {
            check(text, text)
        }
        print(failures == 0 ? "rule tests passed (\(count) cases)" : "\(failures) of \(count) rule tests FAILED")
        exit(failures == 0 ? 0 : 1)
    }
}
