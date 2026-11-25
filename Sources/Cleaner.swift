import Foundation

/// Longest clipboard string worth looking at. Real URLs are far shorter.
let maxURLBytes = 8192

/// Returns `input` with tracking parameters removed, or nil when `input` is not a
/// single http(s) URL or there is nothing to remove.
///
/// It edits the raw string instead of round-tripping through URLComponents, so
/// everything that is kept (encoding, order, fragment) stays byte-for-byte the same.
func cleanURL(_ input: String) -> String? {
    guard input.utf8.count <= maxURLBytes else { return nil }
    let s = Substring(input.trimmingCharacters(in: .whitespacesAndNewlines))

    guard let schemeEnd = s.range(of: "://")?.upperBound else { return nil }
    let scheme = s[..<schemeEnd].lowercased()
    guard scheme == "http://" || scheme == "https://" else { return nil }
    guard !s.contains(where: \.isWhitespace) else { return nil }

    // scheme://authority | path | ?query | #fragment
    let afterScheme = s[schemeEnd...]
    let authorityEnd = afterScheme.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? s.endIndex
    let host = hostName(in: afterScheme[..<authorityEnd])
    guard !host.isEmpty else { return nil }

    let rest = s[authorityEnd...]
    let fragmentStart = rest.firstIndex(of: "#") ?? rest.endIndex
    let fragment = rest[fragmentStart...]
    let beforeFragment = rest[..<fragmentStart]
    let queryStart = beforeFragment.firstIndex(of: "?")
    var path = beforeFragment[..<(queryStart ?? beforeFragment.endIndex)]
    let query = queryStart.map { beforeFragment[beforeFragment.index(after: $0)...] }

    if untouchedHosts.contains(where: { $0.matches(host) }) { return nil }
    let lowered = beforeFragment.lowercased()
    if untouchedURLWords.contains(where: lowered.contains) { return nil }

    let rules = siteRules.filter { $0.matches(host) }
    var changed = false

    // A redirect wrapper: hand back the real destination, itself cleaned.
    if let query, let redirect = rules.compactMap(\.unwrapRedirect).first(where: { $0.path == path || ($0.path == "/" && path.isEmpty) }) {
        for pair in query.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2, redirect.params.contains(parts[0].lowercased()),
                  let target = parts[1].removingPercentEncoding,
                  target.lowercased().hasPrefix("http://") || target.lowercased().hasPrefix("https://"),
                  !target.contains(where: \.isWhitespace)
            else { continue }
            return cleanURL(target) ?? target
        }
    }

    if rules.contains(where: \.stripRefSegments), path.contains("/ref=") {
        let kept = path.split(separator: "/", omittingEmptySubsequences: false)
            .filter { !$0.hasPrefix("ref=") }
        path = Substring(kept.joined(separator: "/"))
        changed = true
    }

    var keptPairs: [Substring] = []
    if let query {
        for pair in query.split(separator: "&", omittingEmptySubsequences: false) {
            let rawName = pair.prefix { $0 != "=" }
            let name = (rawName.removingPercentEncoding ?? String(rawName)).lowercased()
            if isTracking(name, rules: rules) || isReferrer(name, pair: pair) {
                changed = true
            } else {
                keptPairs.append(pair)
            }
        }
    }
    guard changed else { return nil }

    var out = String(s[..<authorityEnd])
    out += path
    if !keptPairs.isEmpty {
        out += "?" + keptPairs.joined(separator: "&")
    }
    out += fragment
    return out
}

private func isTracking(_ name: String, rules: [SiteRule]) -> Bool {
    if name.isEmpty { return false }
    if globalParams.contains(name) || globalPrefixes.contains(where: name.hasPrefix) { return true }
    return rules.contains { $0.params.contains(name) || $0.prefixes.contains(where: name.hasPrefix) }
}

private func isReferrer(_ name: String, pair: Substring) -> Bool {
    guard referrerParams.contains(name), let equals = pair.firstIndex(of: "=") else { return false }
    let raw = pair[pair.index(after: equals)...]
    return referrerValues.contains((raw.removingPercentEncoding ?? String(raw)).lowercased())
}

/// Lowercased host from "user:pass@Host:port". Empty for IPv6 literals, which have no rules.
private func hostName(in authority: Substring) -> String {
    var host = authority
    if let at = host.lastIndex(of: "@") { host = host[host.index(after: at)...] }
    if host.hasPrefix("[") { return "" }
    if let colon = host.firstIndex(of: ":") { host = host[..<colon] }
    return host.lowercased()
}
