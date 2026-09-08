import AppKit
import Carbon.HIToolbox

/// A system-wide hotkey.
///
/// Carbon's `RegisterEventHotKey` is used rather than an `NSEvent` global monitor
/// because it needs no Accessibility permission — one less prompt before the app
/// does anything useful (Р-7).
final class HotKey {

    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    /// ⌥⌘T. Deliberately not ⌥Space, which Raycast and Alfred already own (Р-6).
    static let defaultKeyCode = UInt32(kVK_ANSI_T)
    static let defaultModifiers = UInt32(optionKey | cmdKey)

    init?(keyCode: UInt32 = HotKey.defaultKeyCode,
          modifiers: UInt32 = HotKey.defaultModifiers,
          action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()

        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context else { return noErr }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue().action()
            return noErr
        }, 1, &eventType, context, &handler)

        guard installed == noErr else { return nil }

        let id = EventHotKeyID(signature: OSType(0x5654_524F), id: 1) // 'VTRO'
        let registered = RegisterEventHotKey(keyCode, modifiers, id,
                                             GetApplicationEventTarget(), 0, &ref)
        guard registered == noErr else { return nil }
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
