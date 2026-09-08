import AppKit
import Testing
@testable import VertoCore

// A global shortcut is registered system-wide, so a bad one does damage far outside
// this app: it fires while the user types in something else entirely.

private func combo(_ key: String, _ modifiers: NSEvent.ModifierFlags,
                   keyCode: UInt32 = 17) -> HotKeyCombo? {
    HotKeyCombo(keyCode: keyCode, modifiers: modifiers, characters: key)
}

@Suite("Что считается допустимым сочетанием")
struct HotKeyValidationTests {

    @Test("Нужен хотя бы один из ⌘ ⌥ ⌃",
          arguments: [NSEvent.ModifierFlags.command,
                      .option,
                      .control,
                      [.command, .shift],
                      [.control, .option]])
    func acceptsRealModifiers(_ modifiers: NSEvent.ModifierFlags) {
        #expect(combo("t", modifiers) != nil)
    }

    @Test("Без модификаторов — отказ")
    func rejectsBareKey() {
        // Otherwise the shortcut fires every time the user types the letter anywhere.
        #expect(combo("t", []) == nil)
    }

    @Test("Один Shift не считается модификатором")
    func rejectsShiftAlone() {
        // ⇧T is just a capital T.
        #expect(combo("T", .shift) == nil)
    }

    @Test("Клавиша без имени — отказ")
    func rejectsUnnamedKey() {
        #expect(HotKeyCombo(keyCode: 9999, modifiers: .command, characters: nil) == nil)
        #expect(HotKeyCombo(keyCode: 9999, modifiers: .command, characters: "") == nil)
    }
}

@Suite("Как сочетание записывается")
struct HotKeyLabelTests {

    @Test("Модификаторы идут в порядке Apple")
    func modifiersInAppleOrder() {
        // ⌃⌥⇧⌘ — the order every macOS menu uses.
        #expect(combo("t", [.command, .control, .option, .shift])?.label == "⌃⌥⇧⌘T")
        #expect(combo("t", [.command, .option])?.label == "⌥⌘T")
        #expect(combo("t", [.shift, .command])?.label == "⇧⌘T")
    }

    @Test("Буква пишется заглавной")
    func letterIsUppercased() {
        #expect(combo("t", .command)?.label == "⌘T")
    }

    @Test("У клавиш без символа есть свои знаки",
          arguments: [(49, "␣"), (36, "↩"), (48, "⇥"), (53, "⎋"), (123, "←"), (122, "F1")])
    func namedKeysHaveSymbols(_ keyCode: Int, _ symbol: String) {
        let result = HotKeyCombo(keyCode: UInt32(keyCode), modifiers: .command, characters: nil)
        #expect(result?.label == "⌘" + symbol)
    }

    @Test("Значение по умолчанию — ⌥⌘T")
    func defaultIsOptionCommandT() {
        // Not ⌥Space: Raycast and Alfred already own that one.
        #expect(HotKeyCombo.default.label == "⌥⌘T")
    }
}

@Suite("Сочетание переживает перезапуск")
struct HotKeyPersistenceTests {

    @Test("Кодируется и читается обратно без потерь")
    func roundTrips() throws {
        let original = try #require(combo("k", [.control, .command]))
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(HotKeyCombo.self, from: data)
        #expect(restored == original)
        #expect(restored.label == "⌃⌘K")
    }
}
