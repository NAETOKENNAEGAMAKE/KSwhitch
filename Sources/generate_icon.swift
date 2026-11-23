import Cocoa

let args = CommandLine.arguments
let outDir = args.count > 1 ? args[1] : "AppIcon.iconset"

let fm = FileManager.default
try? fm.removeItem(atPath: outDir)
try fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let specs: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func renderIcon(pixelSize: Int) -> Data? {
    let s = CGFloat(pixelSize)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    rep.size = NSSize(width: s, height: s)
    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = ctx

    // macOS icon safe inset (~10% padding)
    let inset = s * 0.095
    let cardRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = cardRect.width * 0.225
    let squircle = NSBezierPath(roundedRect: cardRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Subtle drop shadow
    ctx.cgContext.saveGState()
    ctx.cgContext.setShadow(
        offset: CGSize(width: 0, height: -s * 0.015),
        blur: s * 0.03,
        color: NSColor.black.withAlphaComponent(0.35).cgColor
    )
    NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.18, alpha: 1.0).setFill()
    squircle.fill()
    ctx.cgContext.restoreGState()

    // Background gradient inside squircle
    squircle.addClip()
    let bgGradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.16, green: 0.20, blue: 0.34, alpha: 1.0),
            NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.18, alpha: 1.0)
        ]
    )
    bgGradient?.draw(in: cardRect, angle: -60)

    // Keycap inner glass highlight border
    let innerInset = cardRect.width * 0.018
    let innerRect = cardRect.insetBy(dx: innerInset, dy: innerInset)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: cornerRadius * 0.92, yRadius: cornerRadius * 0.92)
    NSColor.white.withAlphaComponent(0.18).setStroke()
    innerPath.lineWidth = max(1.0, s * 0.012)
    innerPath.stroke()

    // Diagonal divider / subtle badge accent
    let slashPath = NSBezierPath()
    slashPath.move(to: NSPoint(x: cardRect.minX + cardRect.width * 0.62, y: cardRect.minY + cardRect.height * 0.22))
    slashPath.line(to: NSPoint(x: cardRect.minX + cardRect.width * 0.38, y: cardRect.minY + cardRect.height * 0.78))
    NSColor.white.withAlphaComponent(0.14).setStroke()
    slashPath.lineWidth = max(1.0, s * 0.022)
    slashPath.lineCapStyle = .round
    slashPath.stroke()

    // Draw "한" (top-left cyan)
    let hanFontSize = cardRect.width * 0.42
    let hanFont = NSFont.systemFont(ofSize: hanFontSize, weight: .heavy)
    let hanColor = NSColor(calibratedRed: 0.35, green: 0.82, blue: 1.0, alpha: 1.0)
    let hanAttrs: [NSAttributedString.Key: Any] = [
        .font: hanFont,
        .foregroundColor: hanColor
    ]
    let hanStr = NSAttributedString(string: "한", attributes: hanAttrs)
    let hanSize = hanStr.size()
    let hanOrigin = NSPoint(
        x: cardRect.minX + cardRect.width * 0.30 - hanSize.width * 0.5,
        y: cardRect.minY + cardRect.height * 0.63 - hanSize.height * 0.5
    )
    hanStr.draw(at: hanOrigin)

    // Draw "A" (bottom-right crisp white)
    let engFontSize = cardRect.width * 0.38
    let engFont = NSFont.systemFont(ofSize: engFontSize, weight: .bold)
    let engAttrs: [NSAttributedString.Key: Any] = [
        .font: engFont,
        .foregroundColor: NSColor.white.withAlphaComponent(0.95)
    ]
    let engStr = NSAttributedString(string: "A", attributes: engAttrs)
    let engSize = engStr.size()
    let engOrigin = NSPoint(
        x: cardRect.minX + cardRect.width * 0.70 - engSize.width * 0.5,
        y: cardRect.minY + cardRect.height * 0.34 - engSize.height * 0.5
    )
    engStr.draw(at: engOrigin)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

for (filename, size) in specs {
    guard let png = renderIcon(pixelSize: size) else {
        fputs("Failed to render \(filename)\n", stderr)
        exit(1)
    }
    let path = (outDir as NSString).appendingPathComponent(filename)
    try png.write(to: URL(fileURLWithPath: path))
}

print("Generated iconset at \(outDir)")
