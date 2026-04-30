import SwiftUI
import Combine
import Foundation

@main
struct AwakeApp: App {
    @StateObject private var state = AwakeState()

    init() {
        ensureSingleInstance()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(state)
        } label: {
            Image(systemName: state.isActive ? "eye.fill" : "eye.slash")
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var state: AwakeState
    @State private var customHours = ""
    @State private var customMinutes = ""

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(state.isActive ? Color.amber : Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)

                Circle()
                    .strokeBorder(state.isActive ? Color.amberLight : Color.gray.opacity(0.5), lineWidth: 4)
                    .frame(width: 104, height: 104)

                if state.isActive {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .offset(y: -12)
                }

                Text(state.timerText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .offset(y: state.isActive ? 10 : 0)
            }

            HStack(spacing: 8) {
                DurationButton(label: "30m", duration: 1800)
                DurationButton(label: "1h", duration: 3600)
                DurationButton(label: "2h", duration: 7200)
                DurationButton(label: "\u{221E}", duration: 0)
            }

            HStack(spacing: 6) {
                TextField("h", text: $customHours)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)

                Text("h")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("m", text: $customMinutes)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)

                Text("m")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Button(action: startCustom) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .tint(.amber)
                .disabled(customHours.isEmpty && customMinutes.isEmpty)
            }

            Toggle("Prevent display sleep", isOn: $state.preventDisplay)

            HStack(spacing: 8) {
                Button(action: { state.stop() }) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.8))
                .disabled(!state.isActive)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 240)
    }

    private func startCustom() {
        let h = Int(customHours) ?? 0
        let m = Int(customMinutes) ?? 0
        let total = TimeInterval(h * 3600 + m * 60)
        guard total > 0 else { return }
        state.start(duration: total)
    }
}

struct DurationButton: View {
    let label: String
    let duration: TimeInterval
    @EnvironmentObject var state: AwakeState

    var body: some View {
        Button(action: { state.start(duration: duration) }) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(state.isActive ? Color.amber : .blue)
    }
}

class AwakeState: ObservableObject {
    @Published var isActive = false
    @Published var timerText = "00:00"
    @Published var preventDisplay = false
    @Published var isIndefinite = false

    private var process: Process?
    private var endTime: Date?
    private var timer: Timer?

    func start(duration: TimeInterval) {
        stop()

        let args = buildArgs(duration: duration)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = args

        do {
            try process.run()
            self.process = process
        } catch {
            return
        }

        isActive = true
        isIndefinite = duration == 0

        if duration > 0 {
            endTime = Date().addingTimeInterval(duration)
        } else {
            endTime = nil
            timerText = "\u{221E}"
        }

        startTimer()
    }

    func stop() {
        process?.terminate()
        process = nil
        isActive = false
        isIndefinite = false
        timerText = "00:00"
        endTime = nil
        timer?.invalidate()
        timer = nil
    }

    private func buildArgs(duration: TimeInterval) -> [String] {
        var args = ["-i"]
        if preventDisplay {
            args.append("-d")
        }
        if duration > 0 {
            args.append("-t")
            args.append(String(Int(duration)))
        }
        return args
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func updateTimer() {
        guard isActive else {
            stop()
            return
        }
        guard let endTime = endTime else {
            timerText = "\u{221E}"
            return
        }
        let remaining = endTime.timeIntervalSinceNow
        if remaining <= 0 {
            stop()
            return
        }
        let h = Int(remaining) / 3600
        let m = Int(remaining) % 3600 / 60
        let s = Int(remaining) % 60
        if h > 0 {
            timerText = String(format: "%d:%02d:%02d", h, m, s)
        } else {
            timerText = String(format: "%02d:%02d", m, s)
        }
    }

    deinit {
        stop()
    }
}

extension Color {
    static let amber = Color(red: 1.0, green: 0.67, blue: 0.0)
    static let amberLight = Color(red: 1.0, green: 0.78, blue: 0.2)
}

private func ensureSingleInstance() {
    let lockPath = NSTemporaryDirectory() + "com.awake.app.lock"
    let fd = open(lockPath, O_CREAT | O_RDWR, 0o644)
    if fd == -1 {
        fatalError("Cannot create lock file")
    }
    let result = flock(fd, LOCK_EX | LOCK_NB)
    if result != 0 {
        print("Awake is already running. Exiting.")
        exit(0)
    }
}