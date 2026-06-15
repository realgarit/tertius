import Foundation

/// Compile-time identity constants shared across layers.
/// Kept in Domain because they are pure data with no framework dependency.
public enum TertiusInfo {
    /// Reverse-DNS bundle identifier. This value is part of the codesign
    /// designated requirement, which the Accessibility (TCC) grant is keyed to.
    /// Changing it invalidates the user's permission grant — do not change it.
    public static let bundleIdentifier = "io.github.realgarit.tertius"

    /// Human-facing product name.
    public static let displayName = "Tertius"
}
