// Types used by Rules.swift. Adding a rule never needs a change here.

enum HostPattern {
    /// The domain itself or any subdomain: "x.com" matches x.com and mobile.x.com.
    case domain(String)
    /// The name with any subdomain and any country suffix: "amazon" matches
    /// www.amazon.com and smile.amazon.co.uk.
    case brand(String)
    /// Like `brand`, but only the bare or www host: "google" matches www.google.de
    /// and google.com, not docs.google.com.
    case brandRoot(String)

    func matches(_ host: String) -> Bool {
        switch self {
        case .domain(let d):
            return host == d || host.hasSuffix("." + d)
        case .brand(let b):
            return host.split(separator: ".").dropLast().contains { $0 == b }
        case .brandRoot(let b):
            let labels = host.split(separator: ".")
            guard labels.count >= 2 else { return false }
            return labels[0] == b || (labels[0] == "www" && labels.count >= 3 && labels[1] == b)
        }
    }
}

/// Parameters that are only safe to strip on particular sites.
struct SiteRule {
    let hosts: [HostPattern]
    let params: Set<String>
    var prefixes: [String] = []
    /// Drop "/ref=..." path segments (Amazon, IMDb).
    var stripRefSegments = false
    /// A redirect page whose real destination sits in one of `params`, such as
    /// google.com/url?url=https://example.com. The destination replaces the whole URL.
    var unwrapRedirect: (path: String, params: [String])? = nil

    func matches(_ host: String) -> Bool { hosts.contains { $0.matches(host) } }
}
