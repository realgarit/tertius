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
        momentum: Bool = false
    ) -> GestureSample {
        GestureSample(
            kind: .scroll,
            phase: phase,
            isMomentum: momentum,
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

    @Test("momentum events while dragging are ignored but swallowed")
    func momentumWhileDraggingIgnored() {
        var sm = DragStateMachine()
        _ = sm.handle(scroll(.began), settings: .default)

        let r = sm.handle(scroll(.changed, dx: 9, dy: 9, momentum: true), settings: .default)

        #expect(r.command == .none)
        #expect(r.swallowEvent == true)
        #expect(sm.isDragging == true)
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
}
