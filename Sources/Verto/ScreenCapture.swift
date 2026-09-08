import AppKit

/// Grabs a region of the screen the user draws with the crosshair.
///
/// Shells out to `screencapture` rather than driving ScreenCaptureKit: the system
/// tool already provides the selection people know — crosshair, space to move the
/// selection, esc to cancel — and reimplementing that would be worse in every way.
enum ScreenCapture {

    /// Returns nil when the user cancels, which is a normal outcome and not an error.
    static func selectRegion() async -> NSImage? {
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("verto-\(UUID().uuidString).png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -i interactive, -x silent, -o no window shadow
        process.arguments = ["-i", "-x", "-o", file.path]

        do {
            try process.run()
        } catch {
            NSLog("Verto: screencapture failed to start — \(error)")
            return nil
        }

        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in continuation.resume() }
        }

        defer { try? FileManager.default.removeItem(at: file) }

        // Cancelling writes no file at all.
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return NSImage(contentsOf: file)
    }
}
