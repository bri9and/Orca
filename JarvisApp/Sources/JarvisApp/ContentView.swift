import SwiftUI

struct ContentView: View {
    @ObservedObject var serverManager: ServerManager

    var body: some View {
        Group {
            if serverManager.isReady {
                ReloadableWebView(url: serverManager.url)
                    .transition(.opacity)
            } else {
                SplashView(serverManager: serverManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: serverManager.isReady)
        .frame(minWidth: 900, minHeight: 600)
    }
}
