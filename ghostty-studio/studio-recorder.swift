// studio-recorder: record ONE window (the STUDIO Ghostty) to a .mov via ScreenCaptureKit.
// The capture follows the window wherever it moves, ignores whatever overlaps it, and
// leaves out the shadow and the mouse pointer. Stops cleanly on SIGINT/SIGTERM or a line on stdin.
//   studio-recorder <pid> <out.mov> [seconds]
//   STUDIO_KEY=1  green-key take: ProRes 4444 (full-res color, so green never bleeds into
//                 letter edges the way H.264's 4:2:0 chroma does) + green behind the corners
// Built on demand by `studio` (macOS 15+).
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

let keyed = ProcessInfo.processInfo.environment["STUDIO_KEY"] != nil
// globals so they outlive the stream: SCStreamConfiguration.backgroundColor doesn't retain
let keyGreen = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
let plainBlack = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

let args = CommandLine.arguments
guard args.count >= 3, let pid = pid_t(args[1]) else { fail("usage: studio-recorder <pid> <out.mov> [seconds]") }
let outURL = URL(fileURLWithPath: args[2])
let limit = args.count > 3 ? Double(args[3]) : nil

final class Recorder: NSObject, SCStreamOutput, SCStreamDelegate {
    let pid: pid_t
    let outURL: URL
    let queue = DispatchQueue(label: "studio.recorder")   // every writer touch happens here
    var stream: SCStream?
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var started = false
    var frames = 0

    init(pid: pid_t, outURL: URL) { self.pid = pid; self.outURL = outURL }

    func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let window = content.windows
            .filter({ [pid] in $0.owningApplication?.processID == pid && $0.windowLayer == 0 })
            .max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
        else { fail("no on-screen window for pid \(pid)") }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        // Retina scale, capped so the long side is <= 2880 px (1.5x a 1080x1920 Reel)
        let scale = min(CGFloat(filter.pointPixelScale), 2880 / max(window.frame.width, window.frame.height))
        config.width = Int(window.frame.width * scale) / 2 * 2      // even dimensions for the encoder
        config.height = Int(window.frame.height * scale) / 2 * 2
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        // if the window changes size mid-take, scale it into the same frame (ratio kept)
        config.scalesToFit = true
        config.preservesAspectRatio = true
        config.colorSpaceName = CGColorSpace.sRGB   // keep the key at true #00ff00, not display-profiled
        config.backgroundColor = keyed ? keyGreen : plainBlack   // what shows behind the rounded corners
        config.showsCursor = false
        config.ignoreShadowsSingleWindow = true
        config.capturesAudio = false
        config.queueDepth = 6

        let w = try AVAssetWriter(outputURL: outURL, fileType: .mov)
        var settings: [String: Any] = [
            AVVideoCodecKey: keyed ? AVVideoCodecType.proRes4444 : AVVideoCodecType.h264,
            AVVideoWidthKey: config.width, AVVideoHeightKey: config.height,
            AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                                        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                                        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2],
        ]
        if !keyed {
            settings[AVVideoCompressionPropertiesKey] = [AVVideoAverageBitRateKey: 24_000_000]
        }
        let i = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        i.expectsMediaDataInRealTime = true
        guard w.canAdd(i) else { fail("writer can't take this video format") }
        w.add(i)
        guard w.startWriting() else { fail("writer: \(w.error?.localizedDescription ?? "?")") }
        writer = w; input = i

        let s = SCStream(filter: filter, configuration: config, delegate: self)
        try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        debug("window \(window.windowID) \(window.frame) scale \(scale) keyed \(keyed)")
        try await s.startCapture()
        stream = s
        print("recording \(config.width)x\(config.height)\(keyed ? " ProRes 4444 (green key)" : "") -> \(outURL.path)")
        fflush(stdout)
    }

    // ScreenCaptureKit only sends a frame when the window changes, so the file is
    // variable-frame-rate: a still terminal costs nothing.
    func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, buffer.isValid, let input, let writer,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: false)
                as? [[SCStreamFrameInfo: Any]],
              let raw = attachments.first?[.status] as? Int, SCFrameStatus(rawValue: raw) == .complete
        else { return }
        // Ghostty repaints every frame while shaders animate even when nothing changed;
        // skip exact repeats so a still terminal costs nothing (the file is VFR anyway)
        let fp = fingerprint(buffer)
        if started, fp == lastPrint { return }
        lastPrint = fp
        if !started {
            writer.startSession(atSourceTime: buffer.presentationTimeStamp)
            started = true
        }
        if input.isReadyForMoreMediaData, input.append(buffer) { frames += 1 }
    }

    var lastPrint: UInt64 = 0
    /// FNV-1a over a sparse grid of pixels (~1 in 60): a cheap "did anything change" check.
    /// The grid offset walks a little each row so thin text strokes can't hide between samples.
    func fingerprint(_ buffer: CMSampleBuffer) -> UInt64 {
        guard let px = CMSampleBufferGetImageBuffer(buffer) else { return 0 }
        CVPixelBufferLockBaseAddress(px, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(px, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(px) else { return 0 }
        let w = CVPixelBufferGetWidth(px), h = CVPixelBufferGetHeight(px)
        let stride = CVPixelBufferGetBytesPerRow(px)
        let p = base.assumingMemoryBound(to: UInt32.self)
        var hash: UInt64 = 0xcbf29ce484222325
        var y = 0
        while y < h {
            let row = p + (y * stride / 4)
            var x = y % 7
            while x < w { hash = (hash ^ UInt64(row[x])) &* 0x100000001b3; x += 7 }
            y += 3
        }
        return hash
    }

    func stop() {
        guard let s = stream else { exit(0) }
        stream = nil
        Task {
            try? await s.stopCapture()
            queue.async { [self] in
                guard let writer, let input, started else { fail("no frames captured") }
                input.markAsFinished()
                // run the file to the moment of stopping, not just the last change on screen
                writer.endSession(atSourceTime: CMClockGetTime(CMClockGetHostTimeClock()))
                writer.finishWriting { [self] in
                    if writer.status != .completed { fail("finish: \(writer.error?.localizedDescription ?? "?")") }
                    debug("wrote \(frames) frames")
                    exit(0)
                }
            }
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        debug("capture stopped: \(error.localizedDescription)")   // e.g. the window closed
        self.stream = stream
        stop()
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
