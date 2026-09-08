import VertoCore
import SwiftUI
import Translation

struct PopoverView: View {


    // The popover is built once and lives for the whole session, so it has to watch
    // settings to redraw when the interface language changes.
    @ObservedObject private var settings = Settings.shared
    @ObservedObject var model: PopoverModel

    /// Closing and opening windows is the controller's job, not the view's.
    let onClose: () -> Void
    let onOpenSettings: () -> Void
    let onCaptureScreen: () -> Void

    @State private var showingHistory = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)

            if showingHistory {
                HistoryView { record in
                    model.restore(record)
                    showingHistory = false
                    inputFocused = true
                }
                Divider().opacity(0.5)
                historyFooter
            } else {
                translator
            }
        }
        .frame(width: 360)
        .frame(minHeight: 300, maxHeight: 520, alignment: .top)
        .background(shortcuts)
        .onAppear {
            inputFocused = true
            model.syncPair()
        }
        .translationTask(model.downloadConfiguration) { session in
            try? await session.prepareTranslation()
            model.downloadFinished()
        }
    }

    private var translator: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if model.isRecognizing {
                    HStack(spacing: 9) {
                        ProgressView().controlSize(.small)
                        Text(L.recognizing)
                    }
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 13)
                } else if model.recognizedNothing {
                    Text(L.recognizedNothing)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 13)
                } else {
                TextEditor(text: $model.input)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .frame(minHeight: 76, maxHeight: .infinity)
                .focused($inputFocused)

                // Only while there is something to clear — a permanent × in an empty
                // field is just clutter.
                if !model.input.isEmpty {
                    Button {
                        model.reset()
                        inputFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .pointerStyle(.link)
                    .help(L.clearInput)
                    .padding(.top, 8)
                    .padding(.trailing, 9)
                }
                }
            }

            Divider().opacity(0.5).padding(.horizontal, 14)

            output
                // Equal claim on the spare height, so the translation never ends up
                // squeezed into a strip under a giant input box.
                .frame(minHeight: 76, maxHeight: .infinity, alignment: .topLeading)

            Divider().opacity(0.5)
            footer
        }
    }

    private var historyFooter: some View {
        HStack {
            Button(L.historyBack) { showingHistory = false }
                .buttonStyle(.plain)
                .pointerStyle(.link)
            Spacer()
            if !HistoryStore.shared.history.isEmpty {
                Button(L.historyClear) { HistoryStore.shared.clear() }
                    .buttonStyle(.plain)
                    .pointerStyle(.link)
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Keyboard

    /// Zero-sized buttons are how a popover gets real shortcuts: the footer promises
    /// them, so they have to exist.
    private var shortcuts: some View {
        ZStack {
            Button("", action: copyAndClose)
                .keyboardShortcut(.return, modifiers: .command)
            Button("", action: model.swap)
                .keyboardShortcut("s", modifiers: .command)
            Button("", action: onClose)
                .keyboardShortcut(.cancelAction)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    private func copyAndClose() {
        guard let text = model.translatedText else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        // The transaction is finished; leaving the old text would make the next
        // paste land in a field that already has content.
        model.reset()
        onClose()
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            // Centred independently of the pill, so the name stays optically centred
            // whether the badge reads "RU → EN" or "PT → UK".
            Text("VERTO")
                .font(.system(size: 15, weight: .semibold))
                .tracking(6)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
            Button(action: model.swap) {
                HStack(spacing: 6) {
                    Text(model.source.badge)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .opacity(0.55)
                    Text(model.target.badge)
                    if !model.isConfident {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 11)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .help(L.swapHelp)

            Spacer()

            Button(action: onCaptureScreen) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .help(L.captureHelp)

            Button { showingHistory.toggle() } label: {
                Image(systemName: showingHistory ? "clock.fill" : "clock")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .help(L.historyHelp)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .help(L.settingsHelp)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: - Output

    @ViewBuilder
    private var output: some View {
        switch model.state {
        case .idle:
            placeholder(L.outputPlaceholder)

        case .translating:
            status { ProgressView().controlSize(.small); Text(L.translating) }

        case .translated(let text):
            ScrollView {
                Text(text)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)

        case .needsDownload(let language):
            status {
                ProgressView().controlSize(.small)
                Text(L.downloading(language.localizedName))
            }

        case .unsupported(let language):
            message(L.unsupported(language.localizedName))

        case .failed(let reason):
            message(reason)
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
    }

    private func status<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 9, content: content)
            .font(.system(size: 12.5))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
    }

    private func message(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle").opacity(0.55)
            Text(text)
        }
        .font(.system(size: 12.5))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            if model.isConfident {
                // A real button, not a caption: the shortcut is the fast path, but the
                // hint is the only thing a first-time user sees.
                Button(action: copyAndClose) {
                    Text(L.copyAndClose)
                        .foregroundStyle(model.translatedText == nil ? .tertiary : .secondary)
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .disabled(model.translatedText == nil)
            } else {
                Text(L.lowConfidence)
                    .foregroundStyle(.orange)
            }

            Spacer()
            Text(L.swapHint).foregroundStyle(.tertiary)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
