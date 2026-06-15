import Testing
import Foundation
@testable import Domain

@Suite("AppSettings")
struct AppSettingsTests {
    @Test("default settings match the documented defaults")
    func defaults() {
        let d = AppSettings.default
        #expect(d.enabled == true)
        #expect(d.modifier == .option)
        #expect(d.inputMode == .twoFingerDrag)
        #expect(d.sensitivity == 1.0)
        #expect(d.invertX == false)
        #expect(d.invertY == false)
        #expect(d.launchAtLogin == false)
    }

    // Guards the persistence contract used by the ConfigStore adapter (M2).
    @Test("survives a JSON Codable round-trip unchanged")
    func codableRoundTrip() throws {
        var original = AppSettings.default
        original.modifier = .fn
        original.inputMode = .clickDrag
        original.sensitivity = 3.25
        original.invertX = true
        original.launchAtLogin = true

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded == original)
    }
}
