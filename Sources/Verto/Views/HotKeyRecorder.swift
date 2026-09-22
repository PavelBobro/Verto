import VertoCore
import SwiftUI

/// Click, press a combination, done. Escape cancels; ⌫ restores the default.
struct HotKeyRecorder: View {

    @Binding var combo: HotKeyCombo
    // An object rather than @State: on the macOS 27 SDK @State is a macro whose
    // implementation ships only with Xcode, and Verto builds without it.
    @StateObject private var recorder = Recorder()

    private var isRecording: Bool { recorder.isRecording }

    var body: some View {
        Button(action: toggle) {
            Text(isRecording ? L.hotkeyRecording : combo.label)
                .font(isRecording ? .body : .body.monospaced())
                .foregroundStyle(isRecording ? Color.secondary : Color.primary)
                .frame(minWidth: 92)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isRecording ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isRecording ? Color.accentColor : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .help(L.hotkeyHelp)
        .onDisappear(perform: stop)
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        recorder.isRecording = true
        // A local monitor is enough: recording only happens while the settings window
        // has focus, and swallowing the event stops it reaching the button underneath.
        recorder.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch Int(event.keyCode) {
            case 53:                     // esc — leave the shortcut as it was
                stop()
            case 51:                     // ⌫ — back to the default
                combo = .default
                stop()
            default:
                if let recorded = HotKeyCombo(event: event) {
                    combo = recorded
                    stop()
                }
                // Anything without ⌘/⌥/⌃ is ignored rather than rejected: the field
                // simply keeps waiting, which reads as "that one will not do".
            }
            return nil
        }
    }

    private func stop() {
        if let monitor = recorder.monitor { NSEvent.removeMonitor(monitor) }
        recorder.monitor = nil
        recorder.isRecording = false
    }
}

@MainActor
private final class Recorder: ObservableObject {
    @Published var isRecording = false
    var monitor: Any?
}
