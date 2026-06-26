import CoreGraphics
import Domain
import Application

/// Builds synthetic middle-button (`otherMouse*`, button 2 = center) events.
/// Factored out so the construction is unit-testable without posting.
public enum MiddleButtonEventFactory {
    public static func make(
        type: CGEventType,
        at point: CGPoint,
        delta: CGVector = .zero,
        source: CGEventSource?
    ) -> CGEvent? {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: .center
        ) else { return nil }
        // Explicit for robustness — the middle button is button number 2.
        event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        // The per-event motion. A real middle-drag carries its movement in these
        // fields (what `[NSEvent deltaX/deltaY]` reads). A two-finger glide is a
        // scroll: the system cursor never travels, so without this the target app
        // reads deltaX/deltaY = 0 and orbits by nothing. Integer-valued fields,
        // matching real hardware (sub-pixel motion is accumulated by the caller).
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(delta.dx.rounded()))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(delta.dy.rounded()))
        return event
    }
}

/// Posts synthetic middle-button events. Anchors at the real cursor on
/// middle-down and advances by the supplied deltas for each drag, so the target
/// app reads a held-middle-button drag. Cursor source and the post function are
/// injectable for testing.
public final class CGEventPointerActuator: PointerActuator {
    private let source: CGEventSource?
    private let cursorLocation: () -> CGPoint
    private let post: (CGEvent) -> Void
    private var position: CGPoint = .zero

    public init(
        cursorLocation: @escaping () -> CGPoint = { CGEvent(source: nil)?.location ?? .zero },
        post: @escaping (CGEvent) -> Void = { $0.post(tap: .cgSessionEventTap) }
    ) {
        self.source = CGEventSource(stateID: .combinedSessionState)
        self.cursorLocation = cursorLocation
        self.post = post
    }

    public func perform(_ command: PointerCommand) {
        switch command {
        case .none:
            return
        case .middleDown:
            position = cursorLocation()
            postEvent(.otherMouseDown)
        case let .middleDrag(dx, dy):
            let previous = position
            position = CGPoint(x: position.x + dx, y: position.y + dy)
            // The motion this event carries. Rounding the running position
            // (rather than each raw delta) preserves sub-pixel glides: several
            // 0.4px steps still add up to whole-pixel motion instead of each
            // rounding to zero and stalling a slow orbit.
            let delta = CGVector(
                dx: position.x.rounded() - previous.x.rounded(),
                dy: position.y.rounded() - previous.y.rounded()
            )
            postEvent(.otherMouseDragged, delta: delta)
        case .middleUp:
            postEvent(.otherMouseUp)
        }
    }

    private func postEvent(_ type: CGEventType, delta: CGVector = .zero) {
        guard let event = MiddleButtonEventFactory.make(type: type, at: position, delta: delta, source: source) else { return }
        post(event)
    }
}
