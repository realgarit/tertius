import SwiftUI
import AppKit
import Domain

@main
struct TertiusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(TertiusInfo.displayName, systemImage: "cursorarrow.click.2") {
            Text("\(TertiusInfo.displayName)")
            Divider()
            Button("Quit \(TertiusInfo.displayName)") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

/// Drives activation policy so the running app shows no Dock icon (menu-bar only).
/// Belt-and-braces alongside `LSUIElement` in the packaged Info.plist.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
