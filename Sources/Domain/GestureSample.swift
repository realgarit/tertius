import Foundation

/// The scroll-gesture phase carried by a trackpad scroll event.
///
/// `none` is used for non-gesture scrolls (e.g. a mouse wheel) and for
/// modifier-change samples, which carry no scroll phase.
public enum ScrollPhase: Sendable, Equatable {
    case none
    case began
    case changed
    case ended
}

/// What kind of underlying OS event produced this sample.
public enum GestureKind: Sendable, Equatable {
    /// A trackpad/mouse `scrollWheel` event.
    case scroll
    /// A `flagsChanged` event — the set of held modifiers changed.
    case modifierChange
}

/// A normalized input value object. The Domain never sees a raw `CGEvent`;
/// the Infrastructure event-tap adapter translates events into these.
public struct GestureSample: Sendable, Equatable {
    public var kind: GestureKind
    public var phase: ScrollPhase
    /// True if this scroll event is part of the inertial momentum tail that
    /// arrives after the fingers lift. These must be ignored for dragging.
    public var isMomentum: Bool
    /// True for pixel-based (continuous) scrolls — a trackpad or Magic Mouse.
    /// False for a notched/line-based mouse wheel. Only continuous scrolls can
    /// trigger orbit; a physical mouse wheel always passes through so ⌥ + wheel
    /// keeps working in other apps.
    public var isContinuous: Bool
    public var deltaX: Double
    public var deltaY: Double
    public var activeModifiers: Set<Modifier>
    public var timestamp: TimeInterval

    public init(
        kind: GestureKind,
        phase: ScrollPhase,
        isMomentum: Bool,
        isContinuous: Bool,
        deltaX: Double,
        deltaY: Double,
        activeModifiers: Set<Modifier>,
        timestamp: TimeInterval
    ) {
        self.kind = kind
        self.phase = phase
        self.isMomentum = isMomentum
        self.isContinuous = isContinuous
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.activeModifiers = activeModifiers
        self.timestamp = timestamp
    }
}
