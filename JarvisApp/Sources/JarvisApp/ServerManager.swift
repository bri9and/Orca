import Foundation
import AppKit

@MainActor
final class ServerManager: ObservableObject {
    static let shared = ServerManager()

    @Published var isReady = false
    @Published var isStarting = false
    @Published var errorMessage: String?

    private var process: Process?
    private var pollTimer: Timer?

    let port: Int = 3001
    let dashboardPath = "/Users/cbas-mini/projects/orchestrator/dashboard"
    private let pidFile = NSHomeDirectory() + "/.jarvis.pid"
    private let logFile = NSHomeDirectory() + "/.jarvis.log"

    var url: URL { URL(string: "http://localhost:\(port)")! }

    private init() {}

    func start() {
        guard !isReady, !isStarting else { return }
        isStarting = true
        errorMessage = nil

        // Check if port is already in use (e.g. server already running)
        if isPortInUse() {
            log("Port \(port) already in use — attaching to existing server")
            isReady = true
            isStarting = false
            return
        }

        startServerProcess()
        startPolling()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil

        if let process = process, process.isRunning {
            log("Stopping server (pid \(process.processIdentifier))")
            // Kill the entire process group
            kill(-process.processIdentifier, SIGTERM)
            process.waitUntilExit()
        }
        process = nil

        // Clean up PID file
        try? FileManager.default.removeItem(atPath: pidFile)

        isReady = false
        isStarting = false
    }

    func restart() {
        stop()
        // Small delay before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.start()
        }
    }

    func openLogs() {
        NSWorkspace.shared.open(URL(fileURLWithPath: logFile))
    }

    // MARK: - Private

    private func startServerProcess() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "cd \(dashboardPath) && exec npx next dev --port \(port)"]

        // Start a new process group so we can kill the tree
        process.qualityOfService = .userInitiated

        // Redirect output to log file
        let logHandle: FileHandle
        if !FileManager.default.fileExists(atPath: logFile) {
            FileManager.default.createFile(atPath: logFile, contents: nil)
        }
        logHandle = FileHandle(forWritingAtPath: logFile)!
        logHandle.seekToEndOfFile()
        process.standardOutput = logHandle
        process.standardError = logHandle

        do {
            try process.run()
            log("Server started (pid \(process.processIdentifier))")

            // Write PID file
            try String(process.processIdentifier).write(toFile: pidFile, atomically: true, encoding: .utf8)

            self.process = process
        } catch {
            log("Failed to start server: \(error)")
            errorMessage = "Failed to start server: \(error.localizedDescription)"
            isStarting = false
        }
    }

    private func startPolling() {
        var elapsed: TimeInterval = 0
        let interval: TimeInterval = 0.5
        let timeout: TimeInterval = 30

        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            elapsed += interval

            if elapsed >= timeout {
                timer.invalidate()
                Task { @MainActor in
                    self.errorMessage = "Server did not respond within \(Int(timeout))s"
                    self.isStarting = false
                    self.log("Timeout waiting for server")
                }
                return
            }

            // Check if process died
            Task { @MainActor in
                if let proc = self.process, !proc.isRunning {
                    timer.invalidate()
                    self.errorMessage = "Server process exited unexpectedly"
                    self.isStarting = false
                    self.log("Server process exited with code \(proc.terminationStatus)")
                    return
                }
            }

            // Poll the server
            let pollURL = URL(string: "http://localhost:\(self.port)")!
            var request = URLRequest(url: pollURL)
            request.timeoutInterval = 2
            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let http = response as? HTTPURLResponse, http.statusCode < 500 {
                    timer.invalidate()
                    Task { @MainActor in
                        self.isReady = true
                        self.isStarting = false
                        self.log("Server is ready")
                    }
                }
            }.resume()
        }
    }

    private func isPortInUse() -> Bool {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }

    private func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [JarvisApp] \(message)\n"
        if let data = line.data(using: .utf8),
           let handle = FileHandle(forWritingAtPath: logFile) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        }
        print(message)
    }
}
