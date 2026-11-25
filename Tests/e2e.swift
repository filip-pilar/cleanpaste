// Drives a running watcher through a private pasteboard: e2e <pasteboard-name>
// The real clipboard is never read or written.

import AppKit

let pb = NSPasteboard(name: NSPasteboard.Name(CommandLine.arguments[1]))
typealias PType = NSPasteboard.PasteboardType
let urlName = PType("public.url-name")
let concealed = PType("org.nspasteboard.ConcealedType")

/// Long enough for the watcher's slowest (idle) poll to have come round.
let settle = 2.5
var failures = 0
var latencies: [Double] = []
var emptyWindows: [Double] = []

func seconds() -> Double { Double(DispatchTime.now().uptimeNanoseconds) / 1e9 }

func put(_ items: [(PType, String)]) -> Int {
    let change = pb.declareTypes(items.map(\.0), owner: nil)
    for (type, value) in items { pb.setString(value, forType: type) }
    return change
}

func waitForRewrite(since change: Int, timeout: Double) -> Double? {
    let start = seconds()
    while seconds() - start < timeout {
        if pb.changeCount != change { return (seconds() - start) * 1000 }
        usleep(2000)
    }
    return nil
}

func report(_ ok: Bool, _ label: String, _ detail: String = "") {
    if !ok { failures += 1 }
    print("\(ok ? "ok  " : "FAIL")  \(label)\(detail.isEmpty ? "" : "  \(detail)")")
}

func expectCleaned(_ label: String, _ items: [(PType, String)], _ expected: [(PType, String)],
                   absent: [PType] = []) {
    let change = put(items)
    guard let ms = waitForRewrite(since: change, timeout: settle) else {
        return report(false, label, "not rewritten within \(settle)s")
    }
    // The watcher empties the clipboard and then writes: time how long it stays empty.
    let emptied = seconds()
    while pb.string(forType: .string) == nil, seconds() - emptied < 1 { usleep(200) }
    let window = (seconds() - emptied) * 1000
    usleep(100_000) // let the remaining types land
    for (type, want) in expected {
        let got = pb.string(forType: type)
        if got != want { return report(false, label, "\(type.rawValue): got \(got ?? "nil"), want \(want)") }
    }
    for type in absent where pb.types?.contains(type) == true {
        return report(false, label, "\(type.rawValue) should be gone")
    }
    if pb.changeCount != change + 1 {
        return report(false, label, "change count moved by \(pb.changeCount - change), want 1")
    }
    latencies.append(ms)
    emptyWindows.append(window)
    report(true, label, String(format: "%.0f ms, empty for %.2f ms", ms, window))
}

func expectUntouched(_ label: String, _ items: [(PType, String)]) {
    let change = put(items)
    if waitForRewrite(since: change, timeout: settle) != nil {
        return report(false, label, "was rewritten to \(pb.string(forType: .string) ?? "nil")")
    }
    report(true, label)
}

usleep(500_000) // let the watcher start and note the starting change count
let inputIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
print(String(format: "keyboard/mouse idle for %.0f s (over 60 s the watcher polls every 1-1.5 s instead of 0.2 s)", inputIdle))

let dirty = "https://example.com/article?utm_source=newsletter&id=42&fbclid=abc123"
let clean = "https://example.com/article?id=42"

for i in 1...8 {
    expectCleaned("plain URL #\(i)", [(.string, dirty)], [(.string, clean)])
    usleep(UInt32.random(in: 20_000...180_000))
}
expectCleaned("URL with surrounding whitespace", [(.string, "  \(dirty)\n")], [(.string, clean)])
expectCleaned("link with URL type and title",
              [(.string, dirty), (.URL, dirty), (urlName, "An Article")],
              [(.string, clean), (.URL, clean), (urlName, "An Article")])
expectCleaned("link with HTML alongside",
              [(.string, dirty), (.html, "<a href=\"\(dirty)\">\(dirty)</a>")],
              [(.string, clean)], absent: [.html])
expectUntouched("URL with nothing to strip", [(.string, clean)])
expectUntouched("text that merely contains a URL", [(.string, "see \(dirty) for details")])
expectUntouched("copy marked concealed (password manager)", [(.string, dirty), (concealed, "")])
expectUntouched("copy with no text", [(.png, "not really a png")])

pb.releaseGlobally()
if !latencies.isEmpty {
    let sorted = latencies.sorted()
    print(String(format: "latency over %d rewrites: median %.0f ms, max %.0f ms",
                 sorted.count, sorted[sorted.count / 2], sorted.last!))
    let windows = emptyWindows.sorted()
    print(String(format: "clipboard empty during a rewrite: median %.2f ms, max %.2f ms",
                 windows[windows.count / 2], windows.last!))
}
print(failures == 0 ? "watcher tests passed" : "\(failures) watcher test(s) FAILED")
exit(failures == 0 ? 0 : 1)
