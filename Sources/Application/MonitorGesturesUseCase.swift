import Domain

/// The core use case: subscribes to the input source, runs each sample through
/// the ``DragStateMachine`` with the current settings, drives the pointer
/// actuator, and tells the input source whether to swallow the event.
///
/// Reads settings via a provider closure so live changes (enable/disable,
/// sensitivity, modifier) take effect on the very next sample without re-wiring.
public final class MonitorGesturesUseCase {
    private var stateMachine = DragStateMachine()
    private let input: InputSource
    private let actuator: PointerActuator
    private let settings: () -> AppSettings

    public init(input: InputSource, actuator: PointerActuator, settings: @escaping () -> AppSettings) {
        self.input = input
        self.actuator = actuator
        self.settings = settings
    }

    public func start() {
        input.onSample = { [weak self] sample in
            guard let self else { return false }
            let reaction = self.stateMachine.handle(sample, settings: self.settings())
            self.actuate(reaction.command)
            return reaction.swallowEvent
        }
        try? input.start()
    }

    public func stop() {
        // Guarantee no synthetic button is left held down.
        actuate(stateMachine.reset())
        input.stop()
    }

    private func actuate(_ command: PointerCommand) {
        guard command != .none else { return }
        actuator.perform(command)
    }
}
