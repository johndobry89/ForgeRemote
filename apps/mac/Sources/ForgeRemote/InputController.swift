import AppKit
import ApplicationServices

@MainActor final class InputController {
    private var keys: Set<Int> = []
    private var buttons: Set<Int> = []
    private var location = CGPoint.zero
    var bounds = CGRect.zero
    private let permission: () -> Bool
    private let post: (CGEvent) -> Void
    init(permission: @escaping () -> Bool = { AXIsProcessTrusted() }, post: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) }) {
        self.permission = permission; self.post = post
    }
    var allowed: Bool { permission() }
    private func emit(_ event: CGEvent?) { if let event { post(event) } }
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
            event?.flags = flags; emit(event)
        case "scroll":
            let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(-(c.dy ?? 0)), wheel2: Int32(-(c.dx ?? 0)), wheel3: 0)
            event?.flags = flags; emit(event)
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
            event?.flags = flags; emit(event)
        default: break
        }
    }
    private var flags: CGEventFlags {
        var result: CGEventFlags = []
        for (code,flag) in [(55,CGEventFlags.maskCommand),(56,.maskShift),(58,.maskAlternate),(59,.maskControl)] where keys.contains(code) { result.insert(flag) }
        return result
    }
    func releaseAll() {
        for code in keys { emit(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(code), keyDown: false)) }
        for button in buttons { emit(CGEvent(mouseEventSource: nil, mouseType: button == 0 ? .leftMouseUp : .rightMouseUp, mouseCursorPosition: location, mouseButton: button == 0 ? .left : .right)) }
        keys.removeAll(); buttons.removeAll()
    }
}
