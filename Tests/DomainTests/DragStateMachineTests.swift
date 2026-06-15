import Testing
@testable import Domain

@Suite("DragStateMachine — two-finger drag")
struct DragStateMachineTests {

    // Convenience builders keep the intent of each test legible.
    private func scroll(
        _ phase: ScrollPhase,
        dx: Double = 0,
        dy: Double = 0,
        modifiers: Set<Modifier> = [.option],
        momentum: Bool = false,
        continuous: Bool = true
    ) -> GestureSample {
        GestureSample(
            kind: .scroll,
            phase: phase,
            isMomentum: momentum,
            isContinuous: continuous,
            deltaX: dx,
            deltaY: dy,
            activeModifiers: modifiers,
            timestamp: 0
        )
    }

    private func modifierChange(_ modifiers: Set<Modifier>) -> GestureSample {
        GestureSample(
            kind: .modifierChange,
            phase: .none,
            isMomentum: false,
            isContinuous: false,
            deltaX: 0,
            deltaY: 0,
            activeModifiers: modifiers,
            timestamp: 0
        )
    }

    @Test("modifier held + scroll began → middle-button down, event swallowed, now dragging")
    func beganWithModifierStartsDrag() {
        var sm = DragStateMachine()
        let r = sm.handle(scroll(.began), settings: .default)

        #expect(r.command == .middleDown)
        #expect(r.swallowEvent == true)
        #expect(sm.isDragging == true)
    }

    @Test("while dragging, scroll changed → middle-drag with the deltas, swallowed")
    func changedWhileDraggingDrags() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        let r = sm.handle(scroll(.changed, dx: 4, dy: -3), settings: .default)

        #expect(r.command == .middleDrag(dx: 4, dy: -3))
        #expect(r.swallowEvent == true)
        #expect(sm.isDragging == true)
    }

    @Test("while dragging, scroll ended → middle-button up, swallowed, no longer dragging")
    func endedWhileDraggingReleases() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        let r = sm.handle(scroll(.ended), settings: .default)

        #expect(r.command == .middleUp)
        #expect(r.swallowEvent == true)
        #expect(sm.isDragging == false)
    }

    @Test("full sequence began→changed→changed→ended produces down, drags, up")
    func fullSequence() {
        var sm = DragStateMachine()
        let down = sm.handle(scroll(.began), settings: .default)
        let d1 = sm.handle(scroll(.changed, dx: 2, dy: 2), settings: .default)
        let d2 = sm.handle(scroll(.changed, dx: 1, dy: 0), settings: .default)
        let up = sm.handle(scroll(.ended), settings: .default)

        #expect(down.command == .middleDown)
        #expect(d1.command == .middleDrag(dx: 2, dy: 2))
        #expect(d2.command == .middleDrag(dx: 1, dy: 0))
        #expect(up.command == .middleUp)
        #expect(sm.isDragging == false)
    }

    @Test("after drag ends, momentum is swallowed while modifier still held (no zoom blip)")
    func momentumAfterEndSwallowedWhileModifierHeld() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)
        _ = sm.handle(scroll(.ended), settings: .default)

        // Inertial tail arrives with ⌥ still down.
        let r = sm.handle(scroll(.none, dx: 5, dy: 5, momentum: true), settings: .default)

        #expect(r.command == .none)
        #expect(r.swallowEvent == true)
        #expect(sm.isDragging == false)
    }

    @Test("modifier released mid-drag (flagsChanged) → middle-up, flagsChanged not swallowed")
    func modifierReleaseMidDragReleases() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        let r = sm.handle(modifierChange([]), settings: .default)

        #expect(r.command == .middleUp)
        #expect(r.swallowEvent == false) // flagsChanged must reach the system
        #expect(sm.isDragging == false)
    }

    @Test("a different modifier toggled mid-drag keeps the drag alive and is not swallowed")
    func unrelatedModifierChangeKeepsDrag() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        // Control added while ⌥ stays held.
        let r = sm.handle(modifierChange([.option, .control]), settings: .default)

        #expect(sm.isDragging == true)
        #expect(r.swallowEvent == false)
    }

    @Test("no modifier → scroll passes through untouched (native zoom preserved)")
    func noModifierPassesThrough() {
        var sm = DragStateMachine()
        let r = sm.handle(scroll(.began, modifiers: []), settings: .default)

        #expect(r == .passThrough)
        #expect(sm.isDragging == false)
    }

    @Test("disabled → scroll passes through even with the modifier held")
    func disabledPassesThrough() {
        var settings = AppSettings.default
        settings.enabled = false
        var sm = DragStateMachine()

        let r = sm.handle(scroll(.began), settings: settings)

        #expect(r == .passThrough)
        #expect(sm.isDragging == false)
    }

    @Test("disabling mid-drag ends the drag with a middle-up")
    func disablingMidDragReleases() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        var off = AppSettings.default
        off.enabled = false
        let r = sm.handle(scroll(.changed, dx: 1, dy: 1), settings: off)

        #expect(r.command == .middleUp)
        #expect(sm.isDragging == false)
    }

    @Test("sensitivity scales the drag deltas")
    func sensitivityScalesDeltas() {
        var settings = AppSettings.default
        settings.sensitivity = 2.5
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: settings)

        let r = sm.handle(scroll(.changed, dx: 4, dy: -2), settings: settings)

        #expect(r.command == .middleDrag(dx: 10, dy: -5))
    }

    @Test("invertX and invertY flip the respective axes")
    func inversionFlipsAxes() {
        var settings = AppSettings.default
        settings.invertX = true
        settings.invertY = true
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: settings)

        let r = sm.handle(scroll(.changed, dx: 3, dy: 7), settings: settings)

        #expect(r.command == .middleDrag(dx: -3, dy: -7))
    }

    @Test("engaged scroll without a clean began is swallowed but starts no drag")
    func engagedChangedWithoutBeganSwallowsButNoDrag() {
        var sm = DragStateMachine()
        let r = sm.handle(scroll(.changed, dx: 5, dy: 5), settings: .default)

        #expect(r.command == .none)
        #expect(r.swallowEvent == true) // ⌥ held ⇒ claim it so it never zooms
        #expect(sm.isDragging == false)
    }

    @Test("clickDrag mode does not engage on two-finger scroll")
    func clickDragModeIgnoresScroll() {
        var settings = AppSettings.default
        settings.inputMode = .clickDrag
        var sm = DragStateMachine()

        let r = sm.handle(scroll(.began), settings: settings)

        #expect(r == .passThrough)
        #expect(sm.isDragging == false)
    }

    // MARK: - Momentum tail (review finding C1: must never leak to native)

    @Test("modifier released mid-drag, then momentum tail is swallowed (no zoom blip)")
    func momentumTailSwallowedAfterModifierRelease() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)
        _ = sm.handle(scroll(.changed, dx: 5, dy: 5), settings: .default)

        // ⌥ released while inertia is still coming.
        let up = sm.handle(modifierChange([]), settings: .default)
        #expect(up.command == .middleUp)

        // The inertial tail now arrives with NO modifier held. It must be
        // swallowed (ignored entirely), not passed through as native scroll.
        let tail1 = sm.handle(scroll(.none, dx: 8, dy: 8, modifiers: [], momentum: true), settings: .default)
        let tail2 = sm.handle(scroll(.none, dx: 3, dy: 3, modifiers: [], momentum: true), settings: .default)

        #expect(tail1.command == .none)
        #expect(tail1.swallowEvent == true)
        #expect(tail2.swallowEvent == true)
        #expect(sm.isDragging == false)
    }

    @Test("fingers lift with no `ended`, momentum starts while modifier held → drag closes, tail swallowed")
    func momentumWithoutEndedClosesDrag() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)
        _ = sm.handle(scroll(.changed, dx: 4, dy: 4), settings: .default)

        // No `ended`; the first momentum frame arrives (⌥ still held).
        let firstMomentum = sm.handle(scroll(.none, dx: 9, dy: 9, momentum: true), settings: .default)

        #expect(firstMomentum.command == .middleUp) // close the open button
        #expect(firstMomentum.swallowEvent == true)
        #expect(sm.isDragging == false)
    }

    @Test("native scroll inertia (never dragged, no modifier) passes through untouched")
    func nativeMomentumPassesThrough() {
        var sm = DragStateMachine()
        let begin = sm.handle(scroll(.began, dx: 2, dy: 2, modifiers: []), settings: .default)
        let momentum = sm.handle(scroll(.none, dx: 6, dy: 6, modifiers: [], momentum: true), settings: .default)

        #expect(begin == .passThrough)
        #expect(momentum == .passThrough) // never swallow native scroll momentum
    }

    // MARK: - Mouse wheel (non-continuous) must not be claimed

    @Test("⌥ + physical mouse wheel (non-continuous) passes through, never starts a drag")
    func modifierPlusMouseWheelPassesThrough() {
        var sm = DragStateMachine()
        // A notched wheel reports phase .none and isContinuous == false.
        let r = sm.handle(scroll(.none, dx: 0, dy: 1, continuous: false), settings: .default)

        #expect(r == .passThrough)
        #expect(sm.isDragging == false)
    }

    // MARK: - Sensitivity clamping (review finding H3)

    @Test("sensitivity of 0 is clamped to a positive minimum (no dead drag)")
    func zeroSensitivityClamped() {
        var settings = AppSettings.default
        settings.sensitivity = 0
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: settings)

        let r = sm.handle(scroll(.changed, dx: 4, dy: 4), settings: settings)

        // Clamped to AppSettings.sensitivityRange.lowerBound (0.1): 4 * 0.1 = 0.4.
        #expect(r.command == .middleDrag(dx: 0.4, dy: 0.4))
    }

    @Test("negative sensitivity is clamped positive (does not silently invert)")
    func negativeSensitivityClamped() {
        var settings = AppSettings.default
        settings.sensitivity = -2
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: settings)

        let r = sm.handle(scroll(.changed, dx: 4, dy: 0), settings: settings)

        #expect(r.command == .middleDrag(dx: 0.4, dy: 0)) // 4 * 0.1, positive
    }

    // MARK: - Down/up invariant & teardown safety (review finding C2)

    @Test("a fresh began while already dragging keeps the drag (no double-down)")
    func beganWhileDraggingContinues() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        let r = sm.handle(scroll(.began), settings: .default)

        #expect(r.command == .none)   // no second middle-down
        #expect(r.swallowEvent == true)
        #expect(sm.isDragging == true)
    }

    @Test("reset() while dragging emits a middle-up and goes idle (teardown safety)")
    func resetReleasesOpenButton() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        let cmd = sm.reset()

        #expect(cmd == .middleUp)
        #expect(sm.isDragging == false)
    }

    @Test("reset() while idle is a no-op")
    func resetWhenIdleIsNoOp() {
        var sm = DragStateMachine()
        #expect(sm.reset() == .none)
        #expect(sm.isDragging == false)
    }

    // MARK: - Untested edges flagged by review (M4/M5/M6)

    @Test("pressing the modifier while idle passes through and starts no drag")
    func modifierPressWhileIdlePassesThrough() {
        var sm = DragStateMachine()
        let r = sm.handle(modifierChange([.option]), settings: .default)

        #expect(r == .passThrough)
        #expect(sm.isDragging == false)
    }

    @Test("changing the configured modifier mid-drag ends the drag on the next sample")
    func changingConfiguredModifierMidDragReleases() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default) // dragging under ⌥

        // User reconfigures the trigger to ⌘ while still physically holding ⌥.
        var remapped = AppSettings.default
        remapped.modifier = .command
        let r = sm.handle(scroll(.changed, dx: 1, dy: 1, modifiers: [.option]), settings: remapped)

        #expect(r.command == .middleUp)
        #expect(sm.isDragging == false)
    }

    @Test("re-enabling mid-gesture requires a fresh began to resume")
    func reEnableMidGestureRequiresNewBegan() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        var off = AppSettings.default
        off.enabled = false
        _ = sm.handle(scroll(.changed, dx: 1, dy: 1), settings: off) // middle-up, idle

        // Re-enabled, but mid-stream `changed` must not resume the drag.
        let resume = sm.handle(scroll(.changed, dx: 2, dy: 2), settings: .default)
        #expect(resume.command == .none)
        #expect(sm.isDragging == false)

        // A clean began does start a new drag.
        let fresh = sm.handle(scroll(.began), settings: .default)
        #expect(fresh.command == .middleDown)
        #expect(sm.isDragging == true)
    }
}
