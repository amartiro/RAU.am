import SwiftUI

@main
struct RAUMobileApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(model)
        }
    }
}
