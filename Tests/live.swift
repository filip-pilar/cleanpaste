// Checks the installed agent against the real clipboard, then puts back what was there.
// The previous contents are held in memory only and never printed.

import AppKit

let pb = NSPasteboard.general
func seconds() -> Double { Double(DispatchTime.now().uptimeNanoseconds) / 1e9 }

let saved: [[(NSPasteboard.PasteboardType, Data)]] = (pb.pasteboardItems ?? []).map { item in
    item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
}

let dirty = "https://example.com/article?utm_source=chatgpt.com&id=42&fbclid=abc123"
let clean = "https://example.com/article?id=42"
var latencies: [Double] = []
var ok = true
var last = 0
for _ in 1...5 {
    let change = pb.clearContents()
    pb.setString(dirty, forType: .string)
    let start = seconds()
    while pb.changeCount == change, seconds() - start < 3 { usleep(2000) }
    let ms = (seconds() - start) * 1000
    usleep(100_000)
    last = pb.changeCount
    if pb.string(forType: .string) == clean { latencies.append(ms) } else { ok = false }
    usleep(UInt32.random(in: 50_000...250_000))
}

// Put the old contents back unless something else was copied meanwhile.
if pb.changeCount == last {
    pb.clearContents()
    let items = saved.map { entries -> NSPasteboardItem in
        let item = NSPasteboardItem()
        for (type, data) in entries { item.setData(data, forType: type) }
        return item
    }
    if !items.isEmpty { pb.writeObjects(items) }
    print("previous clipboard restored (\(saved.count) item(s))")
} else {
    print("clipboard changed during the test, so the previous contents were not restored")
}
let sorted = latencies.sorted()
print(ok ? String(format: "real clipboard: 5 of 5 cleaned, median %.0f ms, max %.0f ms", sorted[2], sorted[4])
         : "real clipboard: \(latencies.count) of 5 cleaned  FAILED")
exit(ok ? 0 : 1)
