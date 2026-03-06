import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let autosaveName: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.setFrameAutosaveName(autosaveName)

                // Set a reasonable default size if no saved frame
                if !window.setFrameUsingName(autosaveName) {
                    window.setContentSize(NSSize(width: 1280, height: 820))
                    window.center()
                }

                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isMovableByWindowBackground = true
                window.minSize = NSSize(width: 800, height: 500)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
