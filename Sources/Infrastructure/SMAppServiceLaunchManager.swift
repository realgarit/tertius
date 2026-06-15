import ServiceManagement
import Application

/// Launch-at-login via `SMAppService` (macOS 13+). Registers the main app as a
/// login item. Not unit-tested — `SMAppService` needs a real installed bundle.
public final class SMAppServiceLaunchManager: LaunchAtLoginManaging {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
