import SwiftUI

@main
struct VioletNotebookApp: App {
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
