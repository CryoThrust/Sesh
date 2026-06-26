import SwiftUI
import Foundation

// MARK: - Data Model

struct ClaudeSession: Identifiable {
    let id: String
    var displayName: String    // custom name, persisted
    let summary: String
    let firstMessage: String
    let projectPath: String
    let lastModified: Date
    let gitBranch: String
    let cwd: String
    let fileSize: Int64
}

// MARK: - Session Names Persistence

class SessionNames {
    static let shared = SessionNames()
    private let defaults = UserDefaults.standard
    private let key = "com.yohanes.sesh.names"

    func load() -> [String: String] {
        defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    func save(_ names: [String: String]) {
        defaults.set(names, forKey: key)
    }

    func name(for id: String) -> String? {
        load()[id]
    }

    func setName(_ name: String?, for id: String) {
        var names = load()
        if let name, !name.isEmpty {
            names[id] = name
        } else {
            names.removeValue(forKey: id)
        }
        save(names)
    }
}

// MARK: - Terminal Preference

enum TerminalApp: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm = "iTerm2"
    case ghostty = "Ghostty"
    case warp = "Warp"
    case alacritty = "Alacritty"
    case kitty = "kitty"

    var id: String { rawValue }

    var bundleID: String {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .iterm: return "com.googlecode.iterm2"
        case .ghostty: return "com.mitchellh.ghostty"
        case .warp: return "dev.warp.Warp-Stable"
        case .alacritty: return "org.alacritty"
        case .kitty: return "net.kovidgoyal.kitty"
        }
    }

    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }
}

// MARK: - Session Parser

class SessionStore: ObservableObject {
    @Published var sessions: [ClaudeSession] = []
    @Published var isLoading = false
    @Published var searchText = ""

    private let projectsDir: URL

    init() {
        self.projectsDir = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".claude/projects")
    }

    var filteredSessions: [ClaudeSession] {
        if searchText.isEmpty { return sessions }
        let q = searchText.lowercased()
        return sessions.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.summary.lowercased().contains(q) ||
            $0.firstMessage.lowercased().contains(q) ||
            $0.projectPath.lowercased().contains(q) ||
            $0.id.lowercased().contains(q) ||
            $0.gitBranch.lowercased().contains(q)
        }
    }

    func rename(sessionId: String, newName: String?) {
        // Write custom-title record to the JSONL so claude -r can find it
        writeCustomTitle(sessionId: sessionId, title: newName)
        if let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[idx].displayName = newName ?? ""
        }
    }

    private func writeCustomTitle(sessionId: String, title: String?) {
        // Find the JSONL file for this session
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return }

        for projectDir in projectDirs {
            let file = projectDir.appendingPathComponent("\(sessionId).jsonl")
            if fm.fileExists(atPath: file.path) {
                if let title, !title.isEmpty {
                    let record = "{\"type\":\"custom-title\",\"customTitle\":\(jsonEscaped(title)),\"sessionId\":\(jsonEscaped(sessionId))}\n"
                    if let data = record.data(using: .utf8) {
                        if let handle = try? FileHandle(forWritingTo: file) {
                            handle.seekToEndOfFile()
                            handle.write(data)
                            try? handle.close()
                        }
                    }
                }
                return
            }
        }
    }

    private func jsonEscaped(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    func loadSessions() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let results = self.parseAllSessions()
            DispatchQueue.main.async {
                self.sessions = results
                self.isLoading = false
            }
        }
    }

    private func parseAllSessions() -> [ClaudeSession] {
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return [] }

        let savedNames = SessionNames.shared.load()
        var results: [ClaudeSession] = []

        for projectDir in projectDirs {
            var isDir: ObjCBool = false
            fm.fileExists(atPath: projectDir.path, isDirectory: &isDir)
            guard isDir.boolValue else { continue }

            guard let files = try? fm.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil) else { continue }

            let projectPath = decodeProjectPath(projectDir.lastPathComponent)

            for file in files {
                let filename = file.lastPathComponent
                guard filename.hasSuffix(".jsonl"), !filename.hasPrefix("agent-") else { continue }

                let sessionId = filename.replacingOccurrences(of: ".jsonl", with: "")

                guard let attrs = try? fm.attributesOfItem(atPath: file.path),
                      let modDate = attrs[.modificationDate] as? Date,
                      let fileSize = attrs[.size] as? Int64 else { continue }

                var summary = ""
                var firstMessage = ""
                var gitBranch = ""
                var cwd = ""

                if let handle = try? FileHandle(forReadingFrom: file) {
                    let chunkSize = min(fileSize, 256 * 1024)
                    let data = handle.readData(ofLength: Int(chunkSize))
                    try? handle.close()

                    if let text = String(data: data, encoding: .utf8) {
                        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
                        for line in lines {
                            guard let lineData = line.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

                            let type = json["type"] as? String ?? ""

                            if type == "summary" {
                                summary = json["summary"] as? String ?? ""
                            }

                            if type == "user", firstMessage.isEmpty {
                                if let message = json["message"] as? [String: Any],
                                   let content = message["content"] {
                                    firstMessage = extractText(from: content)
                                }
                                gitBranch = json["gitBranch"] as? String ?? ""
                                cwd = json["cwd"] as? String ?? ""
                            }

                            if !summary.isEmpty && !firstMessage.isEmpty { break }
                        }
                    }
                }

                let displaySummary = summary.isEmpty ? firstMessage : summary
                let displayMessage = firstMessage.isEmpty ? summary : firstMessage
                let displayName = savedNames[sessionId] ?? ""

                results.append(ClaudeSession(
                    id: sessionId,
                    displayName: displayName,
                    summary: displaySummary,
                    firstMessage: displayMessage,
                    projectPath: projectPath,
                    lastModified: modDate,
                    gitBranch: gitBranch,
                    cwd: cwd,
                    fileSize: fileSize
                ))
            }
        }

        results.sort { $0.lastModified > $1.lastModified }
        return results
    }

    private func decodeProjectPath(_ dirName: String) -> String {
        var path = dirName
        if path.hasPrefix("-") { path = String(path.dropFirst()) }
        return path.replacingOccurrences(of: "-", with: "/")
    }

    private func extractText(from content: Any) -> String {
        if let str = content as? String {
            return String(str.prefix(200))
        }
        if let arr = content as? [[String: Any]] {
            for item in arr {
                if item["type"] as? String == "text",
                   let text = item["text"] as? String {
                    return String(text.prefix(200))
                }
            }
        }
        return ""
    }
}

// MARK: - Date Formatter

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Size Formatter

extension Int64 {
    var fileSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}

// MARK: - Rename Sheet

struct RenameSheet: View {
    let sessionId: String
    let currentName: String
    @State private var newName: String
    @Environment(\.dismiss) private var dismiss
    let onSave: (String?) -> Void

    init(sessionId: String, currentName: String, onSave: @escaping (String?) -> Void) {
        self.sessionId = sessionId
        self.currentName = currentName
        self.onSave = onSave
        self._newName = State(initialValue: currentName)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename Session")
                .font(.headline)

            TextField("Display name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    onSave(newName.isEmpty ? nil : newName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}

// MARK: - Main View

struct SessionListView: View {
    @StateObject private var store = SessionStore()
    @State private var selectedSessionId: ClaudeSession.ID?
    @State private var renamingSession: ClaudeSession?
    @AppStorage("preferredTerminal") private var preferredTerminalRaw: String = "Terminal"

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search sessions...", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Picker("Terminal", selection: $preferredTerminalRaw) {
                    ForEach(TerminalApp.allCases.filter(\.isInstalled)) { term in
                        Text(term.rawValue).tag(term.rawValue)
                    }
                }
                .frame(width: 150)
                .help("Choose which terminal to open sessions in")

                Spacer()

                if store.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button(action: { store.loadSessions() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")

                Button(action: { openInTerminal(sessionId: nil, cwd: nil, skipPermissions: false) }) {
                    Image(systemName: "terminal")
                }
                .help("Open new Claude session")
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Session Table
            Table(store.filteredSessions, selection: $selectedSessionId) {
                TableColumn("Name") { (session: ClaudeSession) in
                    if session.displayName.isEmpty {
                        Text(session.summary)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    } else {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(session.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                            Text(session.summary)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .width(min: 120, ideal: 200)

                TableColumn("Last Modified") { (session: ClaudeSession) in
                    Text(session.lastModified.relativeString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .help(session.lastModified.shortDateString)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Project") { (session: ClaudeSession) in
                    Text(session.projectPath)
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(1)
                        .help(session.projectPath)
                }
                .width(min: 150, ideal: 250)

                TableColumn("Branch") { (session: ClaudeSession) in
                    if !session.gitBranch.isEmpty {
                        Text(session.gitBranch)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
                .width(min: 60, ideal: 80)

                TableColumn("Size") { (session: ClaudeSession) in
                    Text(session.fileSize.fileSizeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .width(min: 50, ideal: 60)

                TableColumn("Session ID") { (session: ClaudeSession) in
                    Text(session.id)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .help(session.id)
                }
                .width(min: 80, ideal: 120)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .onTapGesture(count: 2) {
                if let id = selectedSessionId,
                   let session = store.filteredSessions.first(where: { $0.id == id }) {
                    openInTerminal(sessionId: session.id, cwd: session.cwd, skipPermissions: false)
                }
            }
            .contextMenu(forSelectionType: ClaudeSession.ID.self) { ids in
                if let id = ids.first,
                   let session = store.filteredSessions.first(where: { $0.id == id }) {
                    Button("Open Session") {
                        openInTerminal(sessionId: session.id, cwd: session.cwd, skipPermissions: false)
                    }
                    Button("Open Session (Skip Permissions)") {
                        openInTerminal(sessionId: session.id, cwd: session.cwd, skipPermissions: true)
                    }
                    Divider()
                    Button("Rename...") {
                        renamingSession = session
                    }
                    Divider()
                    Button("Copy Session ID") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.id, forType: .string)
                    }
                    Button("Copy Project Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.projectPath, forType: .string)
                    }
                    Button("Open in Finder") {
                        let path = session.cwd.isEmpty ? NSHomeDirectory() : session.projectPath
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .sheet(item: $renamingSession) { session in
            RenameSheet(
                sessionId: session.id,
                currentName: session.displayName
            ) { newName in
                store.rename(sessionId: session.id, newName: newName)
            }
        }
        .onAppear { store.loadSessions() }
    }

    private func openInTerminal(sessionId: String?, cwd: String?, skipPermissions: Bool) {
        var claudeArgs: [String]
        let claudePath = findClaudePath()

        if let sid = sessionId {
            if skipPermissions {
                claudeArgs = ["-r", sid, "--dangerously-skip-permissions"]
            } else {
                claudeArgs = ["-r", sid]
            }
        } else {
            if skipPermissions {
                claudeArgs = ["--dangerously-skip-permissions"]
            } else {
                claudeArgs = []
            }
        }

        let workDir = (cwd?.isEmpty ?? true) ? NSHomeDirectory() : cwd!
        let terminal = preferredTerminal()

        switch terminal {
        case .terminal:
            let cmd = "claude \(claudeArgs.map { "'\($0)'" }.joined(separator: " "))"
            runAppleScript("""
            tell application "Terminal"
                activate
                do script "\(cmd.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))"
            end tell
            """)

        case .iterm:
            let cmd = "claude \(claudeArgs.map { "'\($0)'" }.joined(separator: " "))"
            runAppleScript("""
            tell application "iTerm2"
                activate
                create window with default profile command "\(cmd.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))"
            end tell
            """)

        case .ghostty:
            if let ghosttyURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleID) {
                let exeURL = ghosttyURL.appendingPathComponent("Contents/MacOS/ghostty")
                let process = Process()
                process.executableURL = exeURL
                var args = ["-e", claudePath]
                args.append(contentsOf: claudeArgs)
                process.arguments = args
                process.currentDirectoryURL = URL(fileURLWithPath: workDir)
                try? process.run()
            }

        case .warp:
            if let warpURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleID) {
                let exeURL = warpURL.appendingPathComponent("Contents/MacOS/Warp")
                let process = Process()
                process.executableURL = exeURL
                let cmd = "claude \(claudeArgs.map { "'\($0)'" }.joined(separator: " "))"
                process.arguments = ["--", "-e", "bash", "-lc", cmd]
                process.currentDirectoryURL = URL(fileURLWithPath: workDir)
                try? process.run()
            }

        case .alacritty, .kitty:
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleID) {
                let exeName = terminal == .alacritty ? "alacritty" : "kitty"
                let exeURL = appURL.appendingPathComponent("Contents/MacOS/\(exeName)")
                let process = Process()
                process.executableURL = exeURL
                let cmd = "claude \(claudeArgs.map { "'\($0)'" }.joined(separator: " "))"
                process.arguments = ["-e", "bash", "-lc", cmd]
                process.currentDirectoryURL = URL(fileURLWithPath: workDir)
                try? process.run()
            }
        }
    }

    private func preferredTerminal() -> TerminalApp {
        TerminalApp(rawValue: preferredTerminalRaw) ?? .terminal
    }

    private func findClaudePath() -> String {
        // Try common locations first
        let candidates = [
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            NSHomeDirectory() + "/.nvm/versions/node/*/bin/claude"
        ]
        let fm = FileManager.default
        for path in candidates {
            if path.contains("*") {
                // Glob pattern — try to expand
                if let urls = try? fm.contentsOfDirectory(atPath: NSString(string: path).deletingLastPathComponent) {
                    for item in urls.sorted().reversed() {
                        let full = NSString(string: path).deletingLastPathComponent + "/" + item + "/bin/claude"
                        if fm.isExecutableFile(atPath: full) { return full }
                    }
                }
            } else if fm.isExecutableFile(atPath: path) {
                return path
            }
        }
        // Fallback: use `which`
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        if let data = try? pipe.fileHandleForReading.readToEnd(),
           let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !result.isEmpty {
            return result
        }
        return "claude"
    }

    private func runAppleScript(_ source: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        do {
            try process.run()
        } catch {
            if let appleScript = NSAppleScript(source: source) {
                var err: NSDictionary?
                appleScript.executeAndReturnError(&err)
            }
        }
    }
}

// MARK: - App

@main
struct SeshApp: App {
    var body: some Scene {
        WindowGroup {
            SessionListView()
        }
        .defaultSize(width: 1000, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshSessions, object: nil)
                }
                .keyboardShortcut("r")
            }
        }
    }
}

extension Notification.Name {
    static let refreshSessions = Notification.Name("refreshSessions")
}

// Make ClaudeSession usable with .sheet(item:)
extension ClaudeSession: Equatable {
    static func == (lhs: ClaudeSession, rhs: ClaudeSession) -> Bool {
        lhs.id == rhs.id
    }
}
