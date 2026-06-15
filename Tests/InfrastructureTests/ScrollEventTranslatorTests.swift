import Testing
import CoreGraphics
@testable import Infrastructure
import Domain

@Suite("ScrollEventTranslator")
struct ScrollEventTranslatorTests {

    /// Builds a synthetic scrollWheel CGEvent with the given fields set. No
    /// posting — pure in-process object manipulation, safe to run headlessly.
    private func scrollEvent(
        scrollPhaseRaw: Int64,
        momentumRaw: Int64 = 0,
        continuous: Bool = true,
        axis1 vertical: Double = 0,
        axis2 horizontal: Double = 0,
        flags: CGEventFlags = []
    ) -> CGEvent {
        let e = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: 0, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventScrollPhase, value: scrollPhaseRaw)
        e.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentumRaw)
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
        e.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: vertical)
        e.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: horizontal)
        e.flags = flags
        return e
    }

    @Test("scroll phase raw values map to the Domain ScrollPhase")
    func phaseMapping() {
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 1), type: .scrollWheel)?.phase == .began)
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 2), type: .scrollWheel)?.phase == .changed)
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 4), type: .scrollWheel)?.phase == .ended)
        // cancelled (8) is treated like ended so a drag still releases.
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 8), type: .scrollWheel)?.phase == .ended)
        // mayBegin (128) and 0 carry no actionable phase.
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 128), type: .scrollWheel)?.phase == ScrollPhase.none)
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 0), type: .scrollWheel)?.phase == ScrollPhase.none)
    }

    @Test("momentum phase != 0 marks the sample as momentum, phase becomes none")
    func momentumMapping() {
        let s = ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 0, momentumRaw: 2), type: .scrollWheel)
        #expect(s?.isMomentum == true)
        #expect(s?.phase == ScrollPhase.none)

        let active = ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 2), type: .scrollWheel)
        #expect(active?.isMomentum == false)
    }

    @Test("isContinuous reflects the pixel-based flag")
    func continuousMapping() {
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 1, continuous: true), type: .scrollWheel)?.isContinuous == true)
        #expect(ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 0, continuous: false), type: .scrollWheel)?.isContinuous == false)
    }

    @Test("Axis1 maps to deltaY (vertical) and Axis2 to deltaX (horizontal)")
    func deltaAxisMapping() {
        let s = ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 2, axis1: -3.5, axis2: 5.25), type: .scrollWheel)
        #expect(s?.deltaY == -3.5) // Axis1 = vertical
        #expect(s?.deltaX == 5.25) // Axis2 = horizontal
    }

    @Test("event flags become the active modifier set")
    func modifierMapping() {
        let s = ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 1, flags: [.maskAlternate, .maskCommand]), type: .scrollWheel)
        #expect(s?.activeModifiers == [.option, .command])

        let fn = ScrollEventTranslator.sample(from: scrollEvent(scrollPhaseRaw: 1, flags: [.maskSecondaryFn]), type: .scrollWheel)
        #expect(fn?.activeModifiers == [.fn])
    }

    @Test("a flagsChanged event becomes a modifierChange sample carrying the modifiers")
    func flagsChangedMapping() {
        let e = CGEvent(source: nil)!
        e.type = .flagsChanged
        e.flags = [.maskAlternate]
        let s = ScrollEventTranslator.sample(from: e, type: .flagsChanged)
        #expect(s?.kind == .modifierChange)
        #expect(s?.phase == ScrollPhase.none)
        #expect(s?.activeModifiers == [.option])
    }

    @Test("unrelated event types translate to nil")
    func unrelatedTypesIgnored() {
        let e = CGEvent(source: nil)!
        #expect(ScrollEventTranslator.sample(from: e, type: .keyDown) == nil)
    }
}
