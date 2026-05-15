import SwiftUI

@main
struct SoundBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // A real window so SwiftUI doesn't terminate when "no windows" exist
        // Hidden immediately on appear, dock icon kept by .regular policy
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .onAppear {
                    NSApp.windows
                        .filter { $0.contentView is NSHostingView<EmptyView> }
                        .forEach { $0.orderOut(nil) }
                }
        }
        .defaultSize(width: 0, height: 0)
        .windowResizability(.contentSize)
        .commandsRemoved()
    }
}
