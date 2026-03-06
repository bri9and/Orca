import SwiftUI
import AppKit

@main
struct JarvisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var serverManager = ServerManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView(serverManager: serverManager)
                .background(WindowAccessor(autosaveName: "JarvisMainWindow"))
        }
        .commands {
            // Remove "New Window" — single window app
            CommandGroup(replacing: .newItem) {}

            // View menu
            CommandGroup(after: .toolbar) {
                Button("Reload Page") {
                    NotificationCenter.default.post(name: .reloadWebView, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // Jarvis menu
            CommandMenu("Jarvis") {
                Button("Open in Browser") {
                    NSWorkspace.shared.open(serverManager.url)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()

                Button("Restart Server") {
                    serverManager.restart()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("View Logs") {
                    serverManager.openLogs()
                }

                Divider()

                Button("Dashboard Folder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: serverManager.dashboardPath)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single instance: if already running, activate and exit
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleID = Bundle.main.bundleIdentifier ?? "com.jarvis.app"
        let instances = runningApps.filter { $0.bundleIdentifier == myBundleID }
        if instances.count > 1 {
            // Activate the other instance
            if let other = instances.first(where: { $0 != NSRunningApplication.current }) {
                other.activate()
            }
            NSApp.terminate(nil)
            return
        }

        // Start the server
        Task { @MainActor in
            ServerManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ServerManager.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
