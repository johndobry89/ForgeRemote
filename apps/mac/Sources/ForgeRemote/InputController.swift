import AppKit
import ApplicationServices

@MainActor final class InputController {
    private var keys: Set<Int> = []
    private var buttons: Set<Int> = []
    private var location = CGPoint.zero
    private static let modifiers: [(Int, CGEventFlags)] = [
        (55, .maskCommand), (56, .maskShift), (58, .maskAlternate), (59, .maskControl)
    ]
    var bounds = CGRect.zero
    private let permission: () -> Bool
    private let post: (CGEvent) -> Void
    init(permission: @escaping () -> Bool = { AXIsProcessTrusted() }, post: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) }) {
        self.permission = permission; self.post = post
    }
    var allowed: Bool { permission() }
    private func emit(_ event: CGEvent?) {
        guard let event else { return }
        // A nil CGEventSource can inherit local keyboard flags. Every event must
        // describe our tracked remote state, including synthetic release events.
        event.flags = flags
        post(event)
    }
    func apply(_ c: Command) {
        guard allowed else { releaseAll(); return }
        switch c.type {
        case "pointer":
            guard let x = c.x, let y = c.y, let button = c.button, let action = c.action else { return }
            location = CGPoint(x: bounds.minX + x * max(0,bounds.width-1), y: bounds.minY + y * max(0,bounds.height-1))
            let mouse: CGMouseButton = button == 0 ? .left : .right
            let kind: CGEventType
            if action == "down" { buttons.insert(button); kind = button == 0 ? .leftMouseDown : .rightMouseDown }
            else if action == "up" { buttons.remove(button); kind = button == 0 ? .leftMouseUp : .rightMouseUp }
            else if buttons.contains(0) { kind = .leftMouseDragged }
            else if buttons.contains(1) { kind = .rightMouseDragged }
            else { kind = .mouseMoved }
            let event = CGEvent(mouseEventSource: nil, mouseType: kind, mouseCursorPosition: location, mouseButton: mouse)
            emit(event)
        case "scroll":
            let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(-(c.dy ?? 0)), wheel2: Int32(-(c.dx ?? 0)), wheel3: 0)
            emit(event)
        case "text":
            guard let text = c.text else { return }
            let units = Array(text.utf16)
            for down in [true,false] {
                let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: down)
                units.withUnsafeBufferPointer { buffer in if let base = buffer.baseAddress { event?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: base) } }
                emit(event)
            }
        case "key":
            guard let code = c.code, let down = c.down else { return }
            if down { keys.insert(code) } else { keys.remove(code) }
            let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: down)
            emit(event)
        default: break
        }
    }
    private var flags: CGEventFlags {
        var result: CGEventFlags = []
        for (code,flag) in Self.modifiers where keys.contains(code) { result.insert(flag) }
        return result
    }
    func releaseAll() {
        // Release buttons and ordinary keys while their modifiers are still held,
        // then release modifiers individually. Set iteration order is undefined.
        for button in buttons.sorted() {
            buttons.remove(button)
            emit(CGEvent(mouseEventSource: nil, mouseType: button == 0 ? .leftMouseUp : .rightMouseUp, mouseCursorPosition: location, mouseButton: button == 0 ? .left : .right))
        }
        let modifierCodes = Set(Self.modifiers.map { $0.0 })
        for code in keys.subtracting(modifierCodes).sorted() {
            keys.remove(code)
            emit(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: false))
        }
        for (code, _) in Self.modifiers where keys.contains(code) {
            keys.remove(code)
            // CoreGraphics represents modifier transitions as flagsChanged, not
            // keyUp. Removing the key first gives this event the remaining flags.
            emit(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: false))
        }
    }
}
