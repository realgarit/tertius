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

    /// Valid range for ``sensitivity``. The settings UI constrains its slider to
    /// this range; ``clampedSensitivity`` enforces it for any value (e.g. one
    /// loaded from disk) so a 0 or negative value can never produce a dead or
    /// silently inverted drag.
    public static let sensitivityRange: ClosedRange<Double> = 0.1...30.0

    /// ``sensitivity`` clamped into ``sensitivityRange``. Always positive.
    public var clampedSensitivity: Double {
        min(max(sensitivity, Self.sensitivityRange.lowerBound), Self.sensitivityRange.upperBound)
    }

    /// Sensible defaults: enabled, ⌥ modifier, two-finger drag. The sensitivity
    /// default is tuned for orbit feel — trackpad scroll deltas are small, so a
    /// neutral 1× felt sluggish; 5× is a snappier starting point (adjustable up
    /// to 30× in Settings).
    public static let `default` = AppSettings(
        enabled: true,
        modifier: .option,
        inputMode: .twoFingerDrag,
        sensitivity: 5.0,
        invertX: false,
        invertY: false,
        launchAtLogin: false
    )
}
