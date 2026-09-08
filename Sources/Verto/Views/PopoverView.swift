import SwiftUI
import Translation

struct PopoverView: View {

    /// Closing and opening windows is the controller's job, not the view's.
    let onClose: () -> Void
    let onOpenSettings: () -> Void

    @StateObject private var model = PopoverModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)

            TextEditor(text: $model.input)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .frame(minHeight: 76, maxHeight: .infinity)
                .focused($inputFocused)
                .onChange(of: model.input) { _, text in model.inputChanged(text) }

            Divider().opacity(0.5).padding(.horizontal, 14)

            output
                // Equal claim on the spare height, so the translation never ends up
                // squeezed into a strip under a giant input box.
                .frame(minHeight: 76, maxHeight: .infinity, alignment: .topLeading)

            Divider().opacity(0.5)
            footer
        }
        .frame(width: 360)
        // Base height holds until the text outgrows it, then the window grows to a
        // ceiling and the fields scroll inside themselves (FR-8).
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
            .help("Развернуть направление (⌘S)")

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .help("Настройки (⌘,)")
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
            placeholder("Перевод появится здесь")

        case .translating:
            status { ProgressView().controlSize(.small); Text("Перевод…") }

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
                Text("Загрузка языка «\(language.localizedName)» — один раз")
            }

        case .unsupported(let language):
            message("Apple не переводит язык «\(language.localizedName)». Выберите другую пару.")

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
                    Text("⌘↩ Скопировать и закрыть")
                        .foregroundStyle(model.translatedText == nil ? .tertiary : .secondary)
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .disabled(model.translatedText == nil)
            } else {
                Text("Направление определено предположительно")
                    .foregroundStyle(.orange)
            }

            Spacer()
            Text("⌘S развернуть").foregroundStyle(.tertiary)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
