import SwiftUI
import Domain

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section {
                Toggle("Enable middle-drag", isOn: model.binding(\.enabled))
            }

            Section("Trigger") {
                Picker("Modifier", selection: model.binding(\.modifier)) {
                    ForEach(Modifier.allCases, id: \.self) { modifier in
                        Text(label(for: modifier)).tag(modifier)
                    }
                }
                if model.settings.modifier == .fn {
                    Label("The Fn / globe key is grabbed by the system (emoji, dictation) and is unreliable as a held modifier.",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Mode", selection: model.binding(\.inputMode)) {
                    Text("Two-finger drag").tag(InputMode.twoFingerDrag)
                    Text("Click-drag").tag(InputMode.clickDrag)
                }
            }

            Section("Motion") {
                HStack {
                    Text("Sensitivity")
                    Slider(value: model.binding(\.sensitivity),
                           in: AppSettings.sensitivityRange)
                    Text(String(format: "%.1f×", model.settings.sensitivity))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }
                Toggle("Invert X", isOn: model.binding(\.invertX))
                Toggle("Invert Y", isOn: model.binding(\.invertY))
            }

            Section("General") {
                Toggle("Launch at login", isOn: model.launchAtLoginBinding())

                HStack {
                    Label(model.isTrusted ? "Accessibility granted" : "Accessibility required",
                          systemImage: model.isTrusted ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(model.isTrusted ? .green : .orange)
                    Spacer()
                    if !model.isTrusted {
                        Button("Grant…") { model.requestAccess() }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .onAppear { model.refreshTrust() }
    }

    private func label(for modifier: Modifier) -> String {
        switch modifier {
        case .option: return "Option (⌥)"
        case .control: return "Control (⌃)"
        case .command: return "Command (⌘)"
        case .fn: return "Fn (globe)"
        }
    }
}
