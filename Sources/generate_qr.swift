import Cocoa
import CoreImage

let urlString = "https://buymeacoffee.com/bli1103"
let outputPath = "/Users/labor01/.gemini/antigravity/scratch/KSwitch/Resources/donation_qr.png"

guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
    fputs("CIQRCodeGenerator unavailable\n", stderr)
    exit(1)
}
filter.setValue(urlString.data(using: .utf8), forKey: "inputMessage")
filter.setValue("M", forKey: "inputCorrectionLevel")

guard let qrCI = filter.outputImage else {
    fputs("Failed to generate QR CIImage\n", stderr)
    exit(1)
}

let context = CIContext()
let rawExtent = qrCI.extent
let targetSide: CGFloat = 512.0
let padding: CGFloat = 24.0
let innerSide = targetSide - padding * 2
let scale = floor(innerSide / rawExtent.width)
let scaledQR = qrCI.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

guard let cgQR = context.createCGImage(scaledQR, from: scaledQR.extent) else {
    fputs("Failed to render QR CGImage\n", stderr)
    exit(1)
}

guard let outRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(targetSide),
    pixelsHigh: Int(targetSide),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap rep\n", stderr)
    exit(1)
}

outRep.size = NSSize(width: targetSide, height: targetSide)
NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: outRep)
NSGraphicsContext.current = gctx
gctx?.imageInterpolation = .none
NSColor(deviceRed: 1, green: 1, blue: 1, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: targetSide, height: targetSide).fill()

let drawW = CGFloat(cgQR.width)
let drawH = CGFloat(cgQR.height)
let drawRect = NSRect(
    x: (targetSide - drawW) / 2,
    y: (targetSide - drawH) / 2,
    width: drawW,
    height: drawH
)
NSImage(cgImage: cgQR, size: NSSize(width: drawW, height: drawH)).draw(in: drawRect)
NSGraphicsContext.restoreGraphicsState()

guard let pngData = outRep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Saved Buy Me a Coffee QR (\(Int(targetSide))x\(Int(targetSide))) to \(outputPath)")

guard let verifyCI = CIImage(contentsOf: URL(fileURLWithPath: outputPath)),
      let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
      let feature = detector.features(in: verifyCI).first as? CIQRCodeFeature else {
    fputs("QR verification failed\n", stderr)
    exit(1)
}
let decoded = feature.messageString ?? ""
print("CIDetector verified payload:", decoded)
if decoded != urlString {
    fputs("Decoded payload mismatch: \(decoded)\n", stderr)
    exit(1)
}
