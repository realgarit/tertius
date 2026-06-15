import SwiftUI
import AppKit
import Domain

@main
struct TertiusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: appDelegate.model)
        } label: {
            // Template SF Symbol for M3; replaced by a custom template asset in M4.
            Image(systemName: "cursorarrow.click.2")
        }

        Settings {
            SettingsView(model: appDelegate.model)
        }
    }
}

/// Owns the single ``AppModel`` and sets the accessory activation policy so the
/// running app shows no Dock icon (belt-and-braces with `LSUIElement`).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model.start()
    }
}

/// The menu-bar pull-down.
struct MenuContent: View {
    @Bindable var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Toggle("Enabled", isOn: model.binding(\.enabled))

        Divider()

        if !model.isTrusted {
            Text("Accessibility permission required")
            Button("Open Accessibility Settings…") { model.openAccessibilitySettings() }
            Divider()
        }

        Button("Settings…") { openSettings() }
            .keyboardShortcut(",")

        Text("Tertius \(model.version)")

        Divider()

        Button("Quit Tertius") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
