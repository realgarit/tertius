import Foundation

/// Pure, stateful decision core. Consumes ``GestureSample``s plus the current
/// ``AppSettings`` and produces a ``Reaction`` (pointer command + swallow flag).
/// Holds only whether a drag is currently active. Fully unit-testable with no
/// trackpad and no framework beyond Foundation.
public struct DragStateMachine: Sendable {
    public private(set) var isDragging: Bool = false

    public init() {}

    public mutating func handle(_ sample: GestureSample, settings: AppSettings) -> Reaction {
        let engaged = TriggerPolicy.isEngaged(sample, settings: settings)

        // Trigger lost while mid-drag (modifier released, disabled, or mode
        // changed). End the drag. Never swallow the event that ended it: a
        // modifier release must reach the system, and a scroll that lost
        // engagement should pass through.
        if isDragging && !engaged {
            isDragging = false
            return Reaction(command: .middleUp, swallowEvent: false)
        }

        if !isDragging {
            // Modifier-change events never start a drag and are never swallowed;
            // a drag only begins on a real scroll `began`.
            guard engaged, sample.kind == .scroll else { return .passThrough }

            if sample.phase == .began, !sample.isMomentum {
                isDragging = true
                return Reaction(command: .middleDown, swallowEvent: true)
            }

            // Engaged (modifier held) but no clean `began`: claim the event so
            // ⌥ + scroll never falls through to native zoom, but start nothing.
            return Reaction(command: .none, swallowEvent: true)
        }

        // Dragging and still engaged.
        guard sample.kind == .scroll else {
            // An unrelated modifier toggled while the trigger modifier stays
            // held. Keep dragging; don't swallow the flagsChanged.
            return Reaction(command: .none, swallowEvent: false)
        }

        if sample.isMomentum {
            // Inertial tail: ignore it, but swallow so it doesn't leak as scroll.
            return Reaction(command: .none, swallowEvent: true)
        }

        switch sample.phase {
        case .changed:
            let dx = sample.deltaX * settings.sensitivity * (settings.invertX ? -1 : 1)
            let dy = sample.deltaY * settings.sensitivity * (settings.invertY ? -1 : 1)
            return Reaction(command: .middleDrag(dx: dx, dy: dy), swallowEvent: true)
        case .ended:
            isDragging = false
            return Reaction(command: .middleUp, swallowEvent: true)
        case .began, .none:
            // A stray began/none mid-drag: keep dragging, swallow, no command.
            return Reaction(command: .none, swallowEvent: true)
        }
    }
}
