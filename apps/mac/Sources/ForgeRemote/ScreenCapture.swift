import Foundation
import ScreenCaptureKit
import CoreImage
import UniformTypeIdentifiers
import CoreMedia
import CoreVideo
import ImageIO

final class ScreenCapture: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private var stream: SCStream?
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let queue = DispatchQueue(label: "dev.forge.capture")
    // SCStream callback is synchronous. Mailbox allows one encoded frame awaiting main actor.
    private let lock = NSLock()
    private var busy = false
    private var enabled = false
    private var displayID: CGDirectDisplayID = 0
    private var displayBounds = CGRect.zero
    var output: (@Sendable (Data, Int, Int, CGRect) -> Void)?
    var failure: (@Sendable () -> Void)?
    func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) else { throw CaptureError.noDisplay }
        displayID = display.displayID; displayBounds = CGDisplayBounds(display.displayID)
        let config = SCStreamConfiguration()
        let ratio = min(1.0,1280.0 / Double(display.width))
        config.width = Int(Double(display.width)*ratio); config.height = Int(Double(display.height)*ratio)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 8)
        config.queueDepth = 3; config.showsCursor = true; config.pixelFormat = kCVPixelFormatType_32BGRA
        let stream = SCStream(filter: SCContentFilter(display: display, excludingWindows: []), configuration: config, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        self.stream = stream
        lock.withLock { enabled = true }
        do { try await stream.startCapture() } catch { lock.withLock { enabled = false }; self.stream = nil; throw error }
    }
    func stop() async {
        lock.withLock { enabled = false }
        let old = stream; stream = nil
        try? await old?.stopCapture()
    }
    func consumed() { lock.withLock { busy = false } }
    func stream(_ stream: SCStream, didStopWithError error: Error) { lock.withLock { enabled = false }; failure?() }
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let raw = attachments.first?[.status] as? Int, SCFrameStatus(rawValue: raw) == .complete,
              let pixel = sampleBuffer.imageBuffer else { return }
        let acquired = lock.withLock { if !enabled || busy { return false }; busy = true; return true }
        guard acquired else { return }
        guard CGDisplayBounds(displayID) == displayBounds else { consumed(); failure?(); return }
        let image = CIImage(cvPixelBuffer: pixel)
        guard let color = CGColorSpace(name: CGColorSpace.sRGB), let jpeg = context.jpegRepresentation(of: image, colorSpace: color, options: [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.6]), jpeg.count <= 2_000_000 else { consumed(); return }
        output?(jpeg,CVPixelBufferGetWidth(pixel),CVPixelBufferGetHeight(pixel),displayBounds)
    }
    enum CaptureError: Error { case noDisplay }
}
