import Foundation

/// Pure, stateful decision core. Consumes ``GestureSample``s plus the current
/// ``AppSettings`` and produces a ``Reaction`` (pointer command + swallow flag).
/// Fully unit-testable with no trackpad and no framework beyond Foundation.
///
/// Invariant: every emitted `.middleDown` is eventually matched by a `.middleUp`
/// — via a scroll `ended`, a modifier release, a disable, or ``reset()`` at
/// teardown. Callers MUST call ``reset()`` when stopping so a held button is
/// never left down.
public struct DragStateMachine: Sendable {
    public private(set) var isDragging: Bool = false

    /// True while we are suppressing the inertial momentum tail of a drag we
    /// initiated. Set when a drag ends; cleared by the next non-momentum scroll
    /// (the start of a new, unrelated gesture). Lets us swallow the tail even
    /// after the modifier is released, without ever swallowing native scroll
    /// inertia from a gesture we did not capture.
    private var suppressingMomentumTail: Bool = false

    public init() {}

    public mutating func handle(_ sample: GestureSample, settings: AppSettings) -> Reaction {
        // 1. Momentum/inertia is handled first and uniformly. We only ever
        //    touch momentum that belongs to a drag we initiated; everything
        //    else (native scroll inertia) passes through untouched.
        if sample.isMomentum {
            if isDragging || suppressingMomentumTail {
                var command: PointerCommand = .none
                if isDragging {
                    // Fingers lifted without a clean `ended`; close the button.
                    isDragging = false
                    command = .middleUp
                }
                suppressingMomentumTail = true
                return Reaction(command: command, swallowEvent: true)
            }
            return .passThrough
        }

        // 2. A non-momentum *scroll* marks the start of a new discrete gesture,
        //    so the previous gesture's momentum tail is over. (A flagsChanged
        //    does NOT end the tail — it can fire during the inertia.)
        if sample.kind == .scroll {
            suppressingMomentumTail = false
        }

        let engaged = TriggerPolicy.isEngaged(sample, settings: settings)

        // 3. Trigger lost while mid-drag (modifier released, disabled, or mode
        //    changed): end the drag. Never swallow the event that ended it — a
        //    modifier release must reach the system. Arm tail suppression so any
        //    following inertia is ignored.
        if isDragging && !engaged {
            isDragging = false
            suppressingMomentumTail = true
            return Reaction(command: .middleUp, swallowEvent: false)
        }

        if !isDragging {
            guard engaged, sample.kind == .scroll, sample.isContinuous else {
                // Not engaged, a modifier change, or a non-continuous mouse
                // wheel: pass through so native scroll/zoom and ⌥ + wheel work.
                return .passThrough
            }

            if sample.phase == .began {
                isDragging = true
                return Reaction(command: .middleDown, swallowEvent: true)
            }

            // Engaged continuous scroll with no clean `began`: claim it so
            // ⌥ + trackpad scroll never falls through to native zoom, but start
            // nothing.
            return Reaction(command: .none, swallowEvent: true)
        }

        // 4. Dragging and still engaged.
        guard sample.kind == .scroll else {
            // An unrelated modifier toggled while the trigger modifier stays
            // held. Keep dragging; don't swallow the flagsChanged.
            return Reaction(command: .none, swallowEvent: false)
        }

        switch sample.phase {
        case .changed:
            let s = settings.clampedSensitivity
            let dx = sample.deltaX * s * (settings.invertX ? -1 : 1)
            let dy = sample.deltaY * s * (settings.invertY ? -1 : 1)
            return Reaction(command: .middleDrag(dx: dx, dy: dy), swallowEvent: true)
        case .ended:
            isDragging = false
            suppressingMomentumTail = true
            return Reaction(command: .middleUp, swallowEvent: true)
        case .began, .none:
            // A stray began/none mid-drag: keep dragging, swallow, no command.
            // (A second `began` continues the drag rather than re-anchoring; the
            // eventual `ended`/release closes it — the down/up invariant holds.)
            return Reaction(command: .none, swallowEvent: true)
        }
    }

    /// Force the drag to end. Returns `.middleUp` if a drag was active (so the
    /// caller can release the synthetic button), otherwise `.none`. Call this on
    /// stop/disable/teardown to guarantee no button is left held down.
    public mutating func reset() -> PointerCommand {
        guard isDragging else { return .none }
        isDragging = false
        suppressingMomentumTail = true
        return .middleUp
    }
}
