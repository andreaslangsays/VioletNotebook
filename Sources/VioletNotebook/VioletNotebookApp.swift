import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct VioletNotebookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var journal = Journal(directory: URL(fileURLWithPath: NSHomeDirectory()))
    
    var body: some Scene {
        WindowGroup {
            MainView(journal: journal)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            SidebarCommands()
        }
    }
}
