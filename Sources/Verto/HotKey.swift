import VertoCore
import AppKit
import Carbon.HIToolbox

/// A system-wide hotkey that can be changed while the app runs.
///
/// Carbon's `RegisterEventHotKey` is used rather than an `NSEvent` global monitor
/// because it needs no Accessibility permission — one less prompt before the app does
/// anything useful (Р-7).
@MainActor
final class HotKey {

    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context else { return noErr }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &eventType, context, &handler)
    }

    /// Returns false when the system refuses the combination — almost always because
    /// something else already owns it. The caller has to say so; failing silently
    /// looks exactly like a broken app.
    @discardableResult
    func register(_ combo: HotKeyCombo) -> Bool {
        unregister()

        let id = EventHotKeyID(signature: OSType(0x5654_524F), id: 1) // 'VTRO'
        let status = RegisterEventHotKey(combo.keyCode, combo.carbonModifiers, id,
                                         GetApplicationEventTarget(), 0, &ref)
        if status != noErr { ref = nil }
        return status == noErr
    }

    func unregister() {
        if let ref {
            UnregisterEventHotKey(ref)
            self.ref = nil
        }
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
