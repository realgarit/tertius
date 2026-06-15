import SwiftUI
import Observation
import Domain
import Application
import Infrastructure

/// The composition root and observable coordinator. Builds the object graph by
/// hand (no DI framework), owns the settings + gesture monitor, and exposes
/// observable state + bindings to the SwiftUI menu and settings window.
@MainActor
@Observable
final class AppModel {
    /// Live, observable copy of settings for SwiftUI. Mutations go through
    /// ``update(_:)`` so they persist; the monitor reads the same source.
    private(set) var settings: AppSettings
    private(set) var isTrusted: Bool

    private let settingsStore: SettingsStore
    private let monitor: MonitorGesturesUseCase
    private let authorizer: AXAccessibilityAuthorizer
    private let launchAtLogin: ManageLaunchAtLoginUseCase

    let version: String

    init() {
        let config = UserDefaultsConfigStore()
        let store = SettingsStore(config: config)
        let auth = AXAccessibilityAuthorizer()

        self.settingsStore = store
        self.settings = store.settings
        self.authorizer = auth
        self.isTrusted = auth.isTrusted
        self.launchAtLogin = ManageLaunchAtLoginUseCase(manager: SMAppServiceLaunchManager())
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"

        let input = ScrollGestureInputSource()
        let actuator = CGEventPointerActuator()
        // The monitor reads the store directly so live setting changes apply
        // on the next sample without re-wiring.
        self.monitor = MonitorGesturesUseCase(input: input, actuator: actuator, settings: { store.settings })
    }

    /// Start observing input once permission is in place.
    func start() {
        refreshTrust()
        if isTrusted {
            monitor.start()
        }
    }

    func refreshTrust() {
        isTrusted = authorizer.isTrusted
    }

    /// Prompt for Accessibility, then (re)start if it was just granted.
    func requestAccess() {
        authorizer.requestAccess()
        refreshTrust()
        if isTrusted { monitor.start() }
    }

    func openAccessibilitySettings() {
        authorizer.openAccessibilitySettings()
    }

    private func update(_ mutate: (inout AppSettings) -> Void) {
        settingsStore.update(mutate)
        settings = settingsStore.settings
    }

    /// A two-way binding into a settings field that persists on write.
    func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    /// Launch-at-login binding also drives the SMAppService registration.
    func launchAtLoginBinding() -> Binding<Bool> {
        Binding(
            get: { self.settings.launchAtLogin },
            set: { newValue in
                try? self.launchAtLogin.apply(newValue)
                self.update { $0.launchAtLogin = newValue }
            }
        )
    }
}
