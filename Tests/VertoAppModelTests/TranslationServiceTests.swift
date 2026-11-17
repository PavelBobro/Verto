import Testing
import VertoAppModel
import VertoCore

@Suite("Сервис перевода")
@MainActor
struct TranslationServiceTests {

    @Test("Пустой ввод не запускает запрос")
    func emptyInputStaysIdle() {
        let service = TranslationService()
        service.translate(" \n\t ", from: .russian, to: .english)
        #expect(service.state == .idle)
    }

    @Test("Отмена возвращает сервис в idle")
    func cancelReturnsToIdle() {
        let service = TranslationService()
        service.cancel()
        #expect(service.state == .idle)
    }
}
