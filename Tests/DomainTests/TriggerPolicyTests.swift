import Testing
@testable import Domain

@Suite("TriggerPolicy")
struct TriggerPolicyTests {
    private func sample(_ modifiers: Set<Modifier>) -> GestureSample {
        GestureSample(
            kind: .scroll, phase: .began, isMomentum: false, isContinuous: true,
            deltaX: 0, deltaY: 0, activeModifiers: modifiers, timestamp: 0
        )
    }

    @Test("engaged when enabled, two-finger mode, and the configured modifier is held")
    func engagedHappyPath() {
        #expect(TriggerPolicy.isEngaged(sample([.option]), settings: .default) == true)
    }

    @Test("not engaged when the configured modifier is absent")
    func notEngagedWithoutModifier() {
        #expect(TriggerPolicy.isEngaged(sample([]), settings: .default) == false)
        #expect(TriggerPolicy.isEngaged(sample([.control]), settings: .default) == false)
    }

    @Test("not engaged when disabled")
    func notEngagedWhenDisabled() {
        var s = AppSettings.default
        s.enabled = false
        #expect(TriggerPolicy.isEngaged(sample([.option]), settings: s) == false)
    }

    @Test("not engaged in click-drag mode (scroll is not its trigger)")
    func notEngagedInClickDragMode() {
        var s = AppSettings.default
        s.inputMode = .clickDrag
        #expect(TriggerPolicy.isEngaged(sample([.option]), settings: s) == false)
    }

    @Test("respects a non-default configured modifier")
    func respectsConfiguredModifier() {
        var s = AppSettings.default
        s.modifier = .command
        #expect(TriggerPolicy.isEngaged(sample([.command]), settings: s) == true)
        #expect(TriggerPolicy.isEngaged(sample([.option]), settings: s) == false)
    }
}
