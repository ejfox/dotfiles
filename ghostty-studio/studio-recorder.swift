// studio-recorder: record ONE window (the STUDIO Ghostty) to a .mov via ScreenCaptureKit.
// The capture follows the window wherever it moves, ignores whatever overlaps it, and
// leaves out the shadow and the mouse pointer. Stops cleanly on SIGINT/SIGTERM or a line on stdin.
//   studio-recorder <pid> <out.mov> [seconds]
// Build: swiftc -O -o ~/.dotfiles/bin/studio-recorder studio-recorder.swift  (macOS 15+)
import AppKit
import AVFoundation
import Foundation
import ScreenCaptureKit

// ScreenCaptureKit adds a menu-bar "recording" item, which needs a real (Dock-less) app loop
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

func debug(_ msg: String) {
    if ProcessInfo.processInfo.environment["STUDIO_DEBUG"] != nil {
        FileHandle.standardError.write(("[rec] " + msg + "\n").data(using: .utf8)!)
    }
}

// global so it outlives the stream: SCStreamConfiguration.backgroundColor doesn't retain it
let keyGreen = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)

let args = CommandLine.arguments
guard args.count >= 3, let pid = pid_t(args[1]) else { fail("usage: studio-recorder <pid> <out.mov> [seconds]") }
let outURL = URL(fileURLWithPath: args[2])
let limit = args.count > 3 ? Double(args[3]) : nil

final class Recorder: NSObject, SCRecordingOutputDelegate, SCStreamDelegate {
    let pid: pid_t
    let outURL: URL
    var stream: SCStream?
    var output: SCRecordingOutput?   // must be retained for the whole capture
    var finished = false

    init(pid: pid_t, outURL: URL) { self.pid = pid; self.outURL = outURL }

    func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let window = content.windows
            .filter({ [pid] in $0.owningApplication?.processID == pid && $0.windowLayer == 0 })
            .max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
        else { fail("no on-screen window for pid \(pid)") }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        // Retina scale, capped so the long side is <= 2880 px: the H.264 hardware encoder
        // refuses 2160x3840, and 1620x2880 is already 1.5x a 1080x1920 Reel
        let scale = min(CGFloat(filter.pointPixelScale), 2880 / max(window.frame.width, window.frame.height))
        config.width = Int(window.frame.width * scale) / 2 * 2      // even dimensions for the encoder
        config.height = Int(window.frame.height * scale) / 2 * 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.colorSpaceName = CGColorSpace.sRGB   // keep the key at true #00ff00, not display-profiled
        config.backgroundColor = keyGreen   // rounded corners -> key, not black
        config.showsCursor = false
        config.ignoreShadowsSingleWindow = true
        config.capturesAudio = false
        config.queueDepth = 6

        let recConfig = SCRecordingOutputConfiguration()
        recConfig.outputURL = outURL
        recConfig.outputFileType = .mov
        recConfig.videoCodecType = .h264
        let out = SCRecordingOutput(configuration: recConfig, delegate: self)
        output = out

        let s = SCStream(filter: filter, configuration: config, delegate: self)
        try s.addRecordingOutput(out)
        debug("window \(window.windowID) \(window.frame) scale \(scale); starting capture")
        try await s.startCapture()
        stream = s
        print("recording \(config.width)x\(config.height) -> \(outURL.path)")
        fflush(stdout)
    }

    func stop() {
        guard let s = stream else { exit(0) }
        stream = nil
        Task {
            try? await s.stopCapture()
            // the file is finalized when recordingOutputDidFinishRecording fires; give it a moment
            for _ in 0..<50 where !finished { try? await Task.sleep(nanoseconds: 100_000_000) }
            exit(0)
        }
    }

    func recordingOutputDidStartRecording(_ recordingOutput: SCRecordingOutput) { debug("file recording started") }
    func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) { debug("file finished"); finished = true }
    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) {
        fail("recording failed: \(error.localizedDescription)")
    }
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        fail("capture stopped: \(error.localizedDescription)")   // e.g. the window closed
    }
}

let recorder = Recorder(pid: pid, outURL: outURL)
for sig in [SIGINT, SIGTERM] {
    signal(sig, SIG_IGN)
    let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    src.setEventHandler { recorder.stop() }
    src.resume()
    _ = Unmanaged.passRetained(src)
}
Thread.detachNewThread {
    while readLine() != nil { DispatchQueue.main.async { recorder.stop() }; return }
}
Task {
    do { try await recorder.start() } catch { fail("couldn't start: \(error.localizedDescription)") }
    if let limit { try? await Task.sleep(nanoseconds: UInt64(limit * 1e9)); recorder.stop() }
}
app.run()
