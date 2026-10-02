import ServiceManagement

final class LoginItemController {
    var menuTitle: String { SMAppService.mainApp.status == .enabled ? "Stop Starting at Login" : "Start at Login" }

    func toggle() throws {
        if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        } else {
            try SMAppService.mainApp.register()
        }
    }
}
