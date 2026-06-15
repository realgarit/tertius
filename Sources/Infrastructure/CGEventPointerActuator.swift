import CoreGraphics
import Domain
import Application

/// Builds synthetic middle-button (`otherMouse*`, button 2 = center) events.
/// Factored out so the construction is unit-testable without posting.
public enum MiddleButtonEventFactory {
    public static func make(type: CGEventType, at point: CGPoint, source: CGEventSource?) -> CGEvent? {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: .center
        ) else { return nil }
        // Explicit for robustness — the middle button is button number 2.
        event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
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
            position = CGPoint(x: position.x + dx, y: position.y + dy)
            postEvent(.otherMouseDragged)
        case .middleUp:
            postEvent(.otherMouseUp)
        }
    }

    private func postEvent(_ type: CGEventType) {
        guard let event = MiddleButtonEventFactory.make(type: type, at: position, source: source) else { return }
        post(event)
    }
}
