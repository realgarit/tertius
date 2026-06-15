#!/usr/bin/env swift
//
// Generates the macOS AppIcon set programmatically (no design tool needed).
// A flat, HIG-style icon: a blue squircle with a white mouse silhouette whose
// middle button is accented — evoking the "third mouse button" the app adds.
//
// Run:  swift scripts/make-icons.swift
//
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.first.map { ($0 as NSString).deletingLastPathComponent } ?? ".")
    .deletingLastPathComponent()
let outDir = root.appendingPathComponent("Sources/App/Resources/Assets.xcassets/AppIcon.appiconset")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawIcon(_ ctx: CGContext, _ n: CGFloat) {
    ctx.clear(CGRect(x: 0, y: 0, width: n, height: n))

    // Background squircle with a small margin.
    let margin = n * 0.085
    let bg = CGRect(x: margin, y: margin, width: n - 2 * margin, height: n - 2 * margin)
    ctx.saveGState()
    ctx.addPath(roundedRectPath(bg, radius: n * 0.225))
    ctx.clip()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: colorSpace, colors: [
        CGColor(red: 0.27, green: 0.55, blue: 0.99, alpha: 1), // top
        CGColor(red: 0.13, green: 0.36, blue: 0.92, alpha: 1), // bottom
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: n), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()

    // Mouse body (white capsule).
    let bodyW = n * 0.34
    let bodyH = n * 0.50
    let bodyX = (n - bodyW) / 2
    let bodyY = (n - bodyH) / 2
    let body = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
    ctx.addPath(roundedRectPath(body, radius: bodyW * 0.48))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillPath()

    // Accent middle button (the point of the app), upper-center of the body.
    let btnW = bodyW * 0.18
    let btnH = bodyH * 0.24
    let btnX = (n - btnW) / 2
    let btnY = bodyY + bodyH * 0.56
    let btn = CGRect(x: btnX, y: btnY, width: btnW, height: btnH)
    ctx.addPath(roundedRectPath(btn, radius: btnW * 0.5))
    ctx.setFillColor(CGColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1)) // accent orange
    ctx.fillPath()
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gctx
    drawIcon(gctx.cgContext, CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let data = png(pixels: s)
    try! data.write(to: outDir.appendingPathComponent("icon_\(s).png"))
}

// macOS AppIcon Contents.json (each idiom/scale references a pixel file).
let contents = """
{
  "images" : [
    { "idiom" : "mac", "size" : "16x16", "scale" : "1x", "filename" : "icon_16.png" },
    { "idiom" : "mac", "size" : "16x16", "scale" : "2x", "filename" : "icon_32.png" },
    { "idiom" : "mac", "size" : "32x32", "scale" : "1x", "filename" : "icon_32.png" },
    { "idiom" : "mac", "size" : "32x32", "scale" : "2x", "filename" : "icon_64.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "1x", "filename" : "icon_128.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "2x", "filename" : "icon_256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "1x", "filename" : "icon_256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "2x", "filename" : "icon_512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "1x", "filename" : "icon_512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "2x", "filename" : "icon_1024.png" }
  ],
  "info" : { "version" : 1, "author" : "tertius" }
}
"""
try! contents.write(to: outDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Wrote AppIcon set (\(sizes.count) PNGs) to \(outDir.path)")
