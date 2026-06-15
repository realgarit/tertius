import Foundation

/// An abstract pointer action the Domain wants performed. The Infrastructure
/// `PointerActuator` adapter turns these into synthetic `CGEvent`s.
public enum PointerCommand: Sendable, Equatable {
    case none
    case middleDown
    case middleDrag(dx: Double, dy: Double)
    case middleUp
}

/// The Domain's response to a single ``GestureSample``: what pointer action to
/// perform, and whether the underlying OS event should be swallowed (consumed)
/// so it does not also trigger native scrolling/zooming.
public struct Reaction: Sendable, Equatable {
    public var command: PointerCommand
    public var swallowEvent: Bool

    public init(command: PointerCommand, swallowEvent: Bool) {
        self.command = command
        self.swallowEvent = swallowEvent
    }

    /// Pass the event through untouched, doing nothing.
    public static let passThrough = Reaction(command: .none, swallowEvent: false)
}
