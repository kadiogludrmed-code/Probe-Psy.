import SwiftUI

@main
struct ProbePsyApp: App {
    @State private var store = LocalStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .environment(\.locale, Locale(identifier: store.state.language ?? "de"))
                .overlay {
                    if phase != .active {
                        Rectangle().fill(.background).ignoresSafeArea()
                            .overlay(Image(systemName: "lock.shield").font(.largeTitle))
                            .accessibilityHidden(true)
                    }
                }
        }
    }
}
