import Testing
@testable import Application
import Domain

@Suite("MonitorGesturesUseCase")
struct MonitorGesturesUseCaseTests {

    // MARK: Test doubles at the Port boundary

    final class FakeInputSource: InputSource {
        var onSample: ((GestureSample) -> Bool)?
        private(set) var started = false
        func start() throws { started = true }
        func stop() { started = false }
        /// Test helper: push a sample as the tap would, returning the swallow decision.
        func emit(_ sample: GestureSample) -> Bool { onSample?(sample) ?? false }
    }

    final class FakePointerActuator: PointerActuator {
        private(set) var commands: [PointerCommand] = []
        func perform(_ command: PointerCommand) { commands.append(command) }
    }

    private func scroll(_ phase: ScrollPhase, dx: Double = 0, dy: Double = 0,
                        modifiers: Set<Modifier> = [.option]) -> GestureSample {
        GestureSample(kind: .scroll, phase: phase, isMomentum: false, isContinuous: true,
                      deltaX: dx, deltaY: dy, activeModifiers: modifiers, timestamp: 0)
    }

    @Test("start() begins the input source")
    func startBeginsInput() {
        let input = FakeInputSource()
        let uc = MonitorGesturesUseCase(input: input, actuator: FakePointerActuator(), settings: { .default })
        uc.start()
        #expect(input.started == true)
    }

    @Test("a began→changed→ended sequence drives middle down/drag/up on the actuator")
    func drivesActuator() {
        let input = FakeInputSource()
        let actuator = FakePointerActuator()
        let uc = MonitorGesturesUseCase(input: input, actuator: actuator, settings: { .default })
        uc.start()

        _ = input.emit(scroll(.began))
        _ = input.emit(scroll(.changed, dx: 2, dy: 3))
        _ = input.emit(scroll(.ended))

        #expect(actuator.commands == [.middleDown, .middleDrag(dx: 2, dy: 3), .middleUp])
    }

    @Test("no-op (.none) reactions are not forwarded to the actuator")
    func noneNotForwarded() {
        let input = FakeInputSource()
        let actuator = FakePointerActuator()
        let uc = MonitorGesturesUseCase(input: input, actuator: actuator, settings: { .default })
        uc.start()

        _ = input.emit(scroll(.began, modifiers: [])) // not engaged → .none, passes through

        #expect(actuator.commands.isEmpty)
    }

    @Test("the swallow decision is returned to the input source")
    func returnsSwallowDecision() {
        let input = FakeInputSource()
        let uc = MonitorGesturesUseCase(input: input, actuator: FakePointerActuator(), settings: { .default })
        uc.start()

        #expect(input.emit(scroll(.began)) == true)               // engaged drag start → swallow
        #expect(input.emit(scroll(.began, modifiers: [])) == false) // not engaged → pass through
    }

    @Test("live settings are read per sample")
    func readsLiveSettings() {
        let input = FakeInputSource()
        let actuator = FakePointerActuator()
        var current = AppSettings.default
        current.enabled = false
        let uc = MonitorGesturesUseCase(input: input, actuator: actuator, settings: { current })
        uc.start()

        _ = input.emit(scroll(.began)) // disabled → nothing
        #expect(actuator.commands.isEmpty)

        current.enabled = true
        _ = input.emit(scroll(.began)) // now engaged
        #expect(actuator.commands == [.middleDown])
    }

    @Test("stop() releases a held button and stops the input source")
    func stopReleasesAndStops() {
        let input = FakeInputSource()
        let actuator = FakePointerActuator()
        let uc = MonitorGesturesUseCase(input: input, actuator: actuator, settings: { .default })
        uc.start()
        _ = input.emit(scroll(.began)) // now dragging

        uc.stop()

        #expect(actuator.commands == [.middleDown, .middleUp])
        #expect(input.started == false)
    }
}
