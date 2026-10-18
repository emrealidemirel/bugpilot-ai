// Run from the project root: swift tool/generate_icons.swift
// Packages the transparent master into each platform's required icon sizes.
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = NSImage(contentsOf: root.appendingPathComponent("assets/branding/bugpilot_symbol.png"))!
let symbol = source.cgImage(forProposedRect: nil, context: nil, hints: nil)!

func png(_ size: Int, transparent: Bool = false, scale: CGFloat = 0.9) -> Data {
    let context = CGContext(data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: size * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    if !transparent {
        context.setFillColor(CGColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    }
    let extent = CGFloat(size) * scale
    let offset = (CGFloat(size) - extent) / 2
    context.interpolationQuality = .high
    context.draw(symbol, in: CGRect(x: offset, y: offset, width: extent, height: extent))
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    if !transparent {
        // Store opaque launcher assets without an alpha channel for App Store validation.
        let opaque = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
            bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: size * 3, bitsPerPixel: 24)!
        for y in 0..<size { for x in 0..<size {
            opaque.setColor(bitmap.colorAt(x: x, y: y)!, atX: x, y: y)
        }}
        return opaque.representation(using: .png, properties: [:])!
    }
    return bitmap.representation(using: .png, properties: [:])!
}

func write(_ data: Data, _ path: String) throws {
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

for folder in ["ios/Runner/Assets.xcassets/AppIcon.appiconset", "macos/Runner/Assets.xcassets/AppIcon.appiconset"] {
    let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("\(folder)/Contents.json"))) as! [String: Any]
    for item in manifest["images"] as! [[String: String]] {
        guard let filename = item["filename"] else { continue }
        let points = Double(item["size"]!.split(separator: "x")[0])!
        let scale = Double(item["scale"]!.dropLast())!
        try write(png(Int(points * scale)), "\(folder)/\(filename)")
    }
}
for (density, size) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
    try write(png(size), "android/app/src/main/res/mipmap-\(density)/ic_launcher.png")
    try write(png(Int(Double(size) * 2.25), transparent: true, scale: 0.65), "android/app/src/main/res/mipmap-\(density)/ic_launcher_foreground.png")
}
for size in [192, 512] {
    try write(png(size), "web/icons/Icon-\(size).png")
    try write(png(size, scale: 0.75), "web/icons/Icon-maskable-\(size).png")
}
try write(png(32), "web/favicon.png")
try write(png(1024), "assets/branding/bugpilot_app_icon.png")

// ICO directory followed by PNG entries; supported by modern Windows.
func le(_ value: Int, _ bytes: Int) -> Data {
    Data((0..<bytes).map { UInt8((value >> ($0 * 8)) & 255) })
}
let sizes = [16, 24, 32, 48, 64, 128, 256]
let entries = sizes.map { png($0) }
var ico = le(0, 2) + le(1, 2) + le(sizes.count, 2)
var offset = 6 + sizes.count * 16
for (size, data) in zip(sizes, entries) {
    ico += Data([UInt8(size % 256), UInt8(size % 256), 0, 0])
    ico += le(1, 2) + le(32, 2) + le(data.count, 4) + le(offset, 4)
    offset += data.count
}
for data in entries { ico += data }
try write(ico, "windows/runner/resources/app_icon.ico")
print("Generated iOS, Android, macOS, Windows and web icons.")
