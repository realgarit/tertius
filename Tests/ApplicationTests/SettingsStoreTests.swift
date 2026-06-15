import Testing
@testable import Application
import Domain

@Suite("SettingsStore")
struct SettingsStoreTests {
    final class FakeConfigStore: ConfigStore {
        var stored: AppSettings
        private(set) var saveCount = 0
        init(_ initial: AppSettings) { stored = initial }
        func load() -> AppSettings { stored }
        func save(_ settings: AppSettings) { stored = settings; saveCount += 1 }
    }

    @Test("loads current settings from the config store on init")
    func loadsOnInit() {
        var seed = AppSettings.default
        seed.sensitivity = 7.0
        let store = SettingsStore(config: FakeConfigStore(seed))
        #expect(store.settings.sensitivity == 7.0)
    }

    @Test("update mutates, persists, and notifies")
    func updatePersistsAndNotifies() {
        let config = FakeConfigStore(.default)
        var notified: AppSettings?
        let store = SettingsStore(config: config, onChange: { notified = $0 })

        store.update { $0.enabled = false; $0.modifier = .command }

        #expect(store.settings.enabled == false)
        #expect(store.settings.modifier == .command)
        #expect(config.saveCount == 1)
        #expect(config.stored.modifier == .command) // persisted
        #expect(notified?.modifier == .command)     // observer fired
    }
}

@Suite("ManageLaunchAtLoginUseCase")
struct ManageLaunchAtLoginUseCaseTests {
    final class FakeLaunchManager: LaunchAtLoginManaging {
        var isEnabled = false
        private(set) var lastSet: Bool?
        func setEnabled(_ enabled: Bool) throws { isEnabled = enabled; lastSet = enabled }
    }

    @Test("apply forwards to the manager")
    func applyForwards() throws {
        let manager = FakeLaunchManager()
        let useCase = ManageLaunchAtLoginUseCase(manager: manager)

        try useCase.apply(true)
        #expect(manager.lastSet == true)
        #expect(useCase.isEnabled == true)
    }
}
