#!/bin/bash
set -e

cd "$(dirname "$0")/Awake"

echo "Building Awake..."
swift build -c release

echo "Packaging .app..."
mkdir -p ../Awake.app/Contents/MacOS
mkdir -p ../Awake.app/Contents/Resources
cp .build/release/Awake ../Awake.app/Contents/MacOS/Awake

echo "Generating app icon..."
cat << 'SWIFT' > /tmp/awake_genicon.swift
import Cocoa

let s = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: s, pixelsHigh: s, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx

NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).setFill()
NSRect(x: 0, y: 0, width: s, height: s).fill()

let cx = CGFloat(s) / 2
let cy = CGFloat(s) / 2
let outerR = CGFloat(s) * 0.42
let innerR = CGFloat(s) * 0.34

let outerPath = NSBezierPath(ovalIn: NSRect(x: cx - outerR, y: cy - outerR, width: outerR * 2, height: outerR * 2))
NSColor(red: 1.0, green: 0.67, blue: 0.0, alpha: 1.0).setFill()
outerPath.fill()

let innerPath = NSBezierPath(ovalIn: NSRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2))
NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0).setFill()
innerPath.fill()

let irisR = innerR * 0.5
let irisPath = NSBezierPath(ovalIn: NSRect(x: cx - irisR, y: cy - irisR, width: irisR * 2, height: irisR * 2))
NSColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0).setFill()
irisPath.fill()

let pupilR = innerR * 0.22
let pupilPath = NSBezierPath(ovalIn: NSRect(x: cx - pupilR, y: cy - pupilR, width: pupilR * 2, height: pupilR * 2))
NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0).setFill()
pupilPath.fill()

let hlR = innerR * 0.08
let hlX = cx + irisR * 0.35
let hlY = cy + irisR * 0.35
let hlPath = NSBezierPath(ovalIn: NSRect(x: hlX - hlR, y: hlY - hlR, width: hlR * 2, height: hlR * 2))
NSColor.white.withAlphaComponent(0.8).setFill()
hlPath.fill()

for offset: CGFloat in [-outerR * 0.15, 0, outerR * 0.15] {
    let sx = cx + offset
    let steamPath = NSBezierPath()
    steamPath.move(to: NSPoint(x: sx, y: cy - innerR - innerR * 0.15))
    steamPath.curve(to: NSPoint(x: sx - innerR * 0.08, y: cy - innerR - innerR * 0.4), controlPoint1: NSPoint(x: sx - innerR * 0.12, y: cy - innerR - innerR * 0.2), controlPoint2: NSPoint(x: sx - innerR * 0.1, y: cy - innerR - innerR * 0.35))
    steamPath.curve(to: NSPoint(x: sx, y: cy - innerR - innerR * 0.6), controlPoint1: NSPoint(x: sx + innerR * 0.05, y: cy - innerR - innerR * 0.45), controlPoint2: NSPoint(x: sx + innerR * 0.06, y: cy - innerR - innerR * 0.55))
    steamPath.lineWidth = CGFloat(s) * 0.025
    steamPath.lineCapStyle = .round
    NSColor(red: 1.0, green: 0.67, blue: 0.0, alpha: 0.7).setStroke()
    steamPath.stroke()
}

ctx.flushGraphics()

let pngData = rep.representation(using: .png, properties: [:])!
try! pngData.write(to: URL(fileURLWithPath: "/tmp/awake_icon_1024.png"))
SWIFT

swift /tmp/awake_genicon.swift 2>/dev/null

if [ -f /tmp/awake_icon_1024.png ]; then
    rm -rf /tmp/awake.iconset
    mkdir -p /tmp/awake.iconset
    sips -z 16 16     /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_16x16.png -s format png >/dev/null 2>&1
    sips -z 32 32     /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_16x16@2x.png -s format png >/dev/null 2>&1
    sips -z 32 32     /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_32x32.png -s format png >/dev/null 2>&1
    sips -z 64 64     /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_32x32@2x.png -s format png >/dev/null 2>&1
    sips -z 128 128   /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_128x128.png -s format png >/dev/null 2>&1
    sips -z 256 256   /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_128x128@2x.png -s format png >/dev/null 2>&1
    sips -z 256 256   /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_256x256.png -s format png >/dev/null 2>&1
    sips -z 512 512   /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_256x256@2x.png -s format png >/dev/null 2>&1
    sips -z 512 512   /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_512x512.png -s format png >/dev/null 2>&1
    sips -z 1024 1024 /tmp/awake_icon_1024.png --out /tmp/awake.iconset/icon_512x512@2x.png -s format png >/dev/null 2>&1
    iconutil -c icns /tmp/awake.iconset -o ../Awake.app/Contents/Resources/AppIcon.icns 2>/dev/null || true
    cp /tmp/awake_icon_1024.png ../Awake.app/Contents/Resources/AppIcon.png 2>/dev/null || true
    rm -rf /tmp/awake.iconset /tmp/awake_genicon.swift /tmp/awake_icon_1024.png
    echo "App icon installed"
fi

echo ""
echo "Done! Run with: open ../Awake.app"
echo "Install: cp -r ../Awake.app /Applications/"