import SwiftUI
import Translation

struct SettingsView: View {

    @ObservedObject private var settings = Settings.shared
    @StateObject private var packs = LanguagePacks()

    var body: some View {
        Form {
            Section {
                Picker("Первый язык", selection: $settings.pair.first) {
                    ForEach(LanguageCode.allCases, id: \.self) { code in
                        Text(code.localizedName).tag(code)
                    }
                }
                Picker("Второй язык", selection: $settings.pair.second) {
                    ForEach(LanguageCode.allCases, id: \.self) { code in
                        Text(code.localizedName).tag(code)
                    }
                }
            } header: {
                Text("Пара языков")
            } footer: {
                Text(pairHint)
                    .font(.callout)
                    .foregroundStyle(settings.pair.isValid ? Color.secondary : Color.orange)
            }

            Section {
                packRow
            } header: {
                Text("Языковые пакеты")
            } footer: {
                Text("Пакеты хранятся на компьютере — после загрузки перевод работает без интернета. Скачиваются один раз для каждой пары.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Вызов попапа") {
                    Text("⌥⌘T").monospaced()
                }
                Toggle("Запускать при входе в систему", isOn: $settings.launchAtLogin)
                if let error = settings.lastError {
                    Text(error).font(.callout).foregroundStyle(.orange)
                }
            } header: {
                Text("Поведение")
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
                    Text("Проверка…").foregroundStyle(.secondary)
                }
            }

        case .installed:
            LabeledContent(pairTitle) {
                Label("Установлены", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .labelStyle(.titleAndIcon)
            }

        case .available:
            LabeledContent(pairTitle) {
                HStack(spacing: 10) {
                    Text("Не загружены").foregroundStyle(.secondary)
                    Button("Скачать") { packs.download() }
                }
            }

        case .downloading:
            LabeledContent(pairTitle) {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text("Загрузка…").foregroundStyle(.secondary)
                }
            }

        case .unsupported(let code):
            LabeledContent(pairTitle) {
                Text("Apple не переводит: \(code.localizedName)")
                    .foregroundStyle(.orange)
            }

        case .failed(let reason):
            LabeledContent(pairTitle) {
                HStack(spacing: 10) {
                    Text(reason).foregroundStyle(.orange).lineLimit(2)
                    Button("Ещё раз") { packs.download() }
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
            return "Языки в паре должны быть разными."
        }
        if settings.pair.scriptsDiffer {
            return "Разные алфавиты — направление определяется по написанию, точно даже на коротких фразах. Переключать ничего не нужно."
        }
        return "Общий алфавит — направление определяет языковая модель, и на коротких фразах она может ошибаться. Verto предупредит, когда не уверен; ⌘S развернёт вручную."
    }
}
