import ApplicationServices
import CoreGraphics
import AppKit
import Application

/// Wraps the Accessibility-trust and PostEvent checks. The app needs both an
/// active session tap (Accessibility) and the ability to post synthetic events
/// (PostEvent) — both surface under the Accessibility row in System Settings.
public final class AXAccessibilityAuthorizer: AccessibilityAuthorizing {
    public init() {}

    /// True only when the app may both observe (active tap) and post events.
    public var isTrusted: Bool {
        AXIsProcessTrusted() && CGPreflightPostEventAccess()
    }

    /// Prompt for Accessibility (system dialog) and request PostEvent access.
    public func requestAccess() {
        // Underlying value of `kAXTrustedCheckOptionPrompt`. Using the literal
        // avoids referencing the imported global `var`, which Swift 6 strict
        // concurrency rejects as shared mutable state.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        if !CGPreflightPostEventAccess() {
            _ = CGRequestPostEventAccess()
        }
    }

    /// Deep-link the user straight to the Accessibility list (for a UI button).
    /// Works via NSWorkspace (not the `open` CLI).
    public func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
