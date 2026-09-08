#!/usr/bin/env swift
//
// Draws Verto.icns without Xcode or an asset catalogue.
//
//   swift Tools/make-icon.swift Resources
//
// Writes Verto.iconset/ next to the output, then leaves iconutil to the Makefile.

import AppKit

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"
let iconset = URL(fileURLWithPath: output).appendingPathComponent("Verto.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

/// One canvas-sized drawing of the icon: a light glass squircle with a blue V.
func draw(canvas: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: canvas, height: canvas), flipped: true) { _ in
        let u = canvas / 1024                       // artwork authored at 1024
        let inset = 100 * u
        let side = canvas - inset * 2
        let plate = NSRect(x: inset, y: inset, width: side, height: side)
        let radius = 224 * u                        // ≈ the macOS squircle

        let squircle = NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius)

        // Body: cool light glass, lighter at the top where the light falls.
        NSGradient(starting: NSColor(srgbRed: 0.933, green: 0.949, blue: 0.965, alpha: 1),
                   ending:   NSColor(srgbRed: 0.722, green: 0.784, blue: 0.839, alpha: 1))?
            .draw(in: squircle, angle: 90)

        // The V, drawn as a solid letterform rather than a stroke so it stays crisp
        // when the icon is shown at 16 pt in a Finder list.
        let v = NSBezierPath()
        v.move(to: NSPoint(x: 268 * u, y: 300 * u))
        v.line(to: NSPoint(x: 424 * u, y: 300 * u))
        v.line(to: NSPoint(x: 512 * u, y: 606 * u))
        v.line(to: NSPoint(x: 600 * u, y: 300 * u))
        v.line(to: NSPoint(x: 756 * u, y: 300 * u))
        v.line(to: NSPoint(x: 596 * u, y: 762 * u))
        v.line(to: NSPoint(x: 428 * u, y: 762 * u))
        v.close()

        NSGraphicsContext.saveGraphicsState()
        v.addClip()
        NSGradient(starting: NSColor(srgbRed: 0.180, green: 0.525, blue: 1.0, alpha: 1),
                   ending:   NSColor(srgbRed: 0.043, green: 0.310, blue: 0.722, alpha: 1))?
            .draw(in: v.bounds, angle: 90)
        NSGraphicsContext.restoreGraphicsState()

        // Sheen. Drawn across the whole plate with stops rather than over a shorter
        // rectangle: a gradient that ends at the edge of its own rect leaves a hard
        // line straight across the artwork.
        NSGraphicsContext.saveGraphicsState()
        squircle.addClip()
        NSGradient(colors: [NSColor(white: 1, alpha: 0.60),
                            NSColor(white: 1, alpha: 0.16),
                            NSColor(white: 1, alpha: 0.0)],
                   atLocations: [0.0, 0.34, 0.72],
                   colorSpace: .sRGB)?
            .draw(in: plate, angle: 90)
        NSGraphicsContext.restoreGraphicsState()

        NSColor(white: 1, alpha: 0.75).setStroke()
        let edge = NSBezierPath(roundedRect: plate.insetBy(dx: u, dy: u),
                                xRadius: radius, yRadius: radius)
        edge.lineWidth = 2 * u
        edge.stroke()

        return true
    }
}

func write(_ image: NSImage, pixels: Int, name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: iconset.appendingPathComponent(name))
}

for (points, scales) in [(16, [1, 2]), (32, [1, 2]), (128, [1, 2]), (256, [1, 2]), (512, [1, 2])] {
    for scale in scales {
        let pixels = points * scale
        let suffix = scale == 2 ? "@2x" : ""
        write(draw(canvas: CGFloat(pixels)), pixels: pixels,
              name: "icon_\(points)x\(points)\(suffix).png")
    }
}

print("iconset готов: \(iconset.path)")
