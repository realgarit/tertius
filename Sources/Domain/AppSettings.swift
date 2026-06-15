import Foundation

/// User-configurable settings. A pure value type; the Domain and use cases
/// never see `UserDefaults` — a `ConfigStore` adapter persists this.
public struct AppSettings: Sendable, Equatable, Codable {
    public var enabled: Bool
    public var modifier: Modifier
    public var inputMode: InputMode
    /// Multiplier applied to scroll deltas to produce middle-drag motion.
    /// Scroll deltas are not 1:1 with cursor pixels, so this is calibrated.
    public var sensitivity: Double
    public var invertX: Bool
    public var invertY: Bool
    public var launchAtLogin: Bool

    public init(
        enabled: Bool,
        modifier: Modifier,
        inputMode: InputMode,
        sensitivity: Double,
        invertX: Bool,
        invertY: Bool,
        launchAtLogin: Bool
    ) {
        self.enabled = enabled
        self.modifier = modifier
        self.inputMode = inputMode
        self.sensitivity = sensitivity
        self.invertX = invertX
        self.invertY = invertY
        self.launchAtLogin = launchAtLogin
    }

    /// Sensible defaults: enabled, ⌥ modifier, two-finger drag, neutral sensitivity.
    public static let `default` = AppSettings(
        enabled: true,
        modifier: .option,
        inputMode: .twoFingerDrag,
        sensitivity: 1.0,
        invertX: false,
        invertY: false,
        launchAtLogin: false
    )
}
