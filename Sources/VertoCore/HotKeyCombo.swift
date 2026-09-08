import AppKit
import Carbon.HIToolbox

/// A key combination, stored so it survives a restart and displayed the way macOS
/// writes shortcuts.
public struct HotKeyCombo: Codable, Equatable, Sendable {

    public var keyCode: UInt32
    public var carbonModifiers: UInt32
    /// Rendered once, when the combination is recorded, so the label does not depend
    /// on the keyboard layout in use later.
    public var label: String

    /// ⌥⌘T. Deliberately not ⌥Space, which Raycast and Alfred already own.
    public static let `default` = HotKeyCombo(
        keyCode: UInt32(kVK_ANSI_T),
        carbonModifiers: UInt32(optionKey | cmdKey),
        label: "⌥⌘T"
    )

    public init?(event: NSEvent) {
        self.init(keyCode: UInt32(event.keyCode),
                  modifiers: event.modifierFlags,
                  characters: event.charactersIgnoringModifiers)
    }

    /// Fails when the combination would be a bad global shortcut rather than when the
    /// key is unknown. Takes the parts rather than an event, so the rules can be
    /// exercised without synthesising one.
    public init?(keyCode: UInt32, modifiers: NSEvent.ModifierFlags, characters: String?) {
        let flags = modifiers.intersection(.deviceIndependentFlagsMask)

        // A global shortcut without ⌘, ⌥ or ⌃ would fire while typing anywhere on the
        // system. Shift alone does not count — ⇧A is just a capital A.
        guard flags.contains(.command) || flags.contains(.option) || flags.contains(.control) else {
            return nil
        }

        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }

        guard let name = Self.name(keyCode: keyCode, characters: characters) else { return nil }

        self.keyCode = keyCode
        carbonModifiers = carbon
        // Apple's order, the one shown in every menu.
        label = (flags.contains(.control) ? "⌃" : "")
              + (flags.contains(.option)  ? "⌥" : "")
              + (flags.contains(.shift)   ? "⇧" : "")
              + (flags.contains(.command) ? "⌘" : "")
              + name
    }

    private init(keyCode: UInt32, carbonModifiers: UInt32, label: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.label = label
    }

    /// Keys that have a symbol rather than a character.
    private static let named: [Int: String] = [
        kVK_Space: "␣", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦", kVK_Escape: "⎋", kVK_Home: "↖", kVK_End: "↘",
        kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
        kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12"
    ]

    private static func name(keyCode: UInt32, characters: String?) -> String? {
        if let named = named[Int(keyCode)] { return named }
        guard let characters, !characters.isEmpty else { return nil }
        return characters.uppercased()
    }
}
