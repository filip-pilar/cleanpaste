// Reports what a running process costs over a window: usage <pid> <seconds>

import CoreGraphics
import Darwin

func usage(of pid: pid_t) -> rusage_info_v4 {
    var info = rusage_info_v4()
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
            proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
        }
    }
    guard result == 0 else { fatalError("cannot read usage of pid \(pid)") }
    return info
}

var timebase = mach_timebase_info_data_t()
mach_timebase_info(&timebase)
func milliseconds(_ machTime: UInt64) -> Double {
    Double(machTime) * Double(timebase.numer) / Double(timebase.denom) / 1e6
}
func inputIdle() -> Double {
    CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
}

let pid = pid_t(CommandLine.arguments[1])!
let window = Double(CommandLine.arguments[2])!

usleep(1_500_000) // skip launch costs when the process has only just started
let before = usage(of: pid)
let idleBefore = inputIdle()
usleep(UInt32(window * 1_000_000))
let after = usage(of: pid)
let idleAfter = inputIdle()

let cpu = milliseconds(after.ri_user_time + after.ri_system_time)
    - milliseconds(before.ri_user_time + before.ri_system_time)
let wakeups = Double(after.ri_pkg_idle_wkups + after.ri_interrupt_wkups)
    - Double(before.ri_pkg_idle_wkups + before.ri_interrupt_wkups)

print(String(format: "window:        %.0f s (keyboard/mouse idle %.0f s at start, %.0f s at end)",
             window, idleBefore, idleAfter))
print(String(format: "cpu time:      %.2f ms  (%.4f%% of one core)", cpu, cpu / (window * 1000) * 100))
print(String(format: "wakeups:       %.1f per second", wakeups / window))
print(String(format: "memory:        %.1f MB footprint, %.1f MB resident",
             Double(after.ri_phys_footprint) / 1_048_576, Double(after.ri_resident_size) / 1_048_576))
print(String(format: "disk written:  %llu bytes", after.ri_diskio_byteswritten - before.ri_diskio_byteswritten))
