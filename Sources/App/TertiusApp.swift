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
            // A monochrome mouse glyph echoing the app icon, drawn as a template
            // image so it adapts to light/dark menu bars (and inverts when open).
            // The middle button is solid when enabled, hollow when disabled.
            Image(nsImage: MenuBarIcon.image(enabled: appDelegate.model.settings.enabled))
                .renderingMode(.template)
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
            Button("Grant Accessibility…") { model.requestAccess() }
            Divider()
        }

        Button("Settings…") {
            // An accessory (LSUIElement) app can't foreground itself, so the
            // Settings window opens hidden behind everything. Activate first,
            // then open, so it actually appears and takes focus.
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        if let updateMessage = model.updateMessage {
            Text(updateMessage)
        }
        Button("Check for Updates…") { model.checkForUpdates() }
        Text("Tertius \(model.version)")

        Divider()

        Button("Quit Tertius") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
