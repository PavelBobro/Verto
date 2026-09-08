import VertoCore
import SwiftUI
import Translation

struct SettingsView: View {

    @ObservedObject private var settings = Settings.shared
    @StateObject private var packs = LanguagePacks()

    var body: some View {
        Form {
            Section {
                Picker(L.firstLanguage, selection: $settings.pair.first) {
                    ForEach(LanguageCode.allCases, id: \.self) { code in
                        Text(code.localizedName).tag(code)
                    }
                }
                Picker(L.secondLanguage, selection: $settings.pair.second) {
                    ForEach(LanguageCode.allCases, id: \.self) { code in
                        Text(code.localizedName).tag(code)
                    }
                }
            } header: {
                Text(L.languagePair)
            } footer: {
                Text(pairHint)
                    .font(.callout)
                    .foregroundStyle(settings.pair.isValid ? Color.secondary : Color.orange)
            }

            Section {
                packRow
            } header: {
                Text(L.packs)
            } footer: {
                Text(L.packsFooter)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent(L.hotkeyLabel) {
                    Text("⌥⌘T").monospaced()
                }
                Toggle(L.launchAtLogin, isOn: $settings.launchAtLogin)
                if let error = settings.lastError {
                    Text(error).font(.callout).foregroundStyle(.orange)
                }
            } header: {
                Text(L.behaviour)
            }

            Section {
                Picker(L.interfaceLanguage, selection: $settings.appLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.title).tag(language)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .task(id: settings.pair) { await packs.refresh(for: settings.pair) }
        .translationTask(packs.pending) { session in
            do {
                try await session.prepareTranslation()
                await packs.legFinished()
            } catch {
                packs.legFailed(error)
            }
        }
    }

    // MARK: - Language packs

    @ViewBuilder
    private var packRow: some View {
        switch packs.state {
        case .checking:
            LabeledContent(pairTitle) {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text(L.packChecking).foregroundStyle(.secondary)
                }
            }

        case .installed:
            LabeledContent(pairTitle) {
                Label(L.packInstalled, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .labelStyle(.titleAndIcon)
            }

        case .available:
            LabeledContent(pairTitle) {
                HStack(spacing: 10) {
                    Text(L.packMissing).foregroundStyle(.secondary)
                    Button(L.packDownload) { packs.download() }
                }
            }

        case .downloading:
            LabeledContent(pairTitle) {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text(L.packDownloading).foregroundStyle(.secondary)
                }
            }

        case .unsupported(let code):
            LabeledContent(pairTitle) {
                Text(L.packUnsupported(code.localizedName))
                    .foregroundStyle(.orange)
            }

        case .failed(let reason):
            LabeledContent(pairTitle) {
                HStack(spacing: 10) {
                    Text(reason).foregroundStyle(.orange).lineLimit(2)
                    Button(L.packRetry) { packs.download() }
                }
            }
        }
    }

    private var pairTitle: String {
        "\(settings.pair.first.badge) ⇄ \(settings.pair.second.badge)"
    }

    /// Says out loud how reliable detection will be for the chosen pair — the answer
    /// changes completely depending on whether the two alphabets differ.
    private var pairHint: String {
        guard settings.pair.isValid else {
            return L.hintSameLanguage
        }
        if settings.pair.scriptsDiffer {
            return L.hintScriptsDiffer
        }
        return L.hintSharedScript
    }
}
