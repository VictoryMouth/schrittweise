import AppKit
import Foundation

// MARK: - Color Helpers
extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

let primaryGreen = NSColor(hex: 0x30D158)
let mintColor = NSColor(hex: 0x00C7BE)
let cyanColor = NSColor(hex: 0x64D2FF)
let orangeColor = NSColor(hex: 0xFF9F0A)
let yellowColor = NSColor(hex: 0xFFD60A)
let bgDark = NSColor(hex: 0x0B0F0D)
let cardBgDark = NSColor(hex: 0x1C2320)
let cardBorder = NSColor(hex: 0x2A3530)
let secondaryText = NSColor(hex: 0x8E8E93)
let tertiaryText = NSColor(hex: 0x636366)

// MARK: - Drawing Utils
func drawText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) {
    let para = NSMutableParagraphStyle()
    para.alignment = alignment
    para.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: para
    ]
    (text as NSString).draw(in: rect, withAttributes: attrs)
}

func drawLinearGradient(ctx: CGContext, colors: [NSColor], in rect: CGRect, start: CGPoint, end: CGPoint) {
    let cgColors = colors.map { $0.cgColor } as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: cgColors, locations: nil) {
        ctx.saveGState()
        ctx.clip(to: rect)
        ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
        ctx.restoreGState()
    }
}

func drawRoundedRect(ctx: CGContext, rect: CGRect, cornerRadius: CGFloat, fill: NSColor?, stroke: NSColor? = nil, lineWidth: CGFloat = 1.0) {
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    if let fill = fill {
        ctx.setFillColor(fill.cgColor)
        ctx.addPath(path)
        ctx.fillPath()
    }
    if let stroke = stroke {
        ctx.setStrokeColor(stroke.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(path)
        ctx.strokePath()
    }
}

func drawProgressRing(ctx: CGContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat, progress: CGFloat) {
    // Background Track
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(primaryGreen.withAlphaComponent(0.2).cgColor)
    ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
    
    // Gradient Progress Arc
    let startAngle: CGFloat = -.pi / 2
    let endAngle: CGFloat = startAngle + (.pi * 2 * progress)
    
    ctx.saveGState()
    ctx.setStrokeColor(primaryGreen.cgColor)
    ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    ctx.strokePath()
    ctx.restoreGState()
}

func saveImage(rep: NSBitmapImageRep, to path: String) {
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    let url = URL(fileURLWithPath: path)
    try? data.write(to: url)
    print("Created: \(path)")
}

// =========================================================================
// MARK: - iPhone Screenshot Generator (1290 x 2796)
// =========================================================================

func makeIPhoneContext() -> (NSBitmapImageRep, CGContext) {
    let w = 1290
    let h = 2796
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: w,
        pixelsHigh: h,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    return (rep, ctx)
}

func drawIPhoneBase(ctx: CGContext, title: String, subtitle: String) -> CGRect {
    let w: CGFloat = 1290
    let h: CGFloat = 2796
    
    // Background gradient
    drawLinearGradient(
        ctx: ctx,
        colors: [NSColor(hex: 0x07110C), NSColor(hex: 0x020504)],
        in: CGRect(x: 0, y: 0, width: w, height: h),
        start: CGPoint(x: w/2, y: h),
        end: CGPoint(x: w/2, y: 0)
    )
    
    // Subtle top radial glow
    ctx.saveGState()
    let glowColors = [primaryGreen.withAlphaComponent(0.18).cgColor, NSColor.clear.cgColor] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let radial = CGGradient(colorsSpace: space, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(radial, startCenter: CGPoint(x: w/2, y: h - 150), startRadius: 0, endCenter: CGPoint(x: w/2, y: h - 150), endRadius: 700, options: [])
    }
    ctx.restoreGState()
    
    // Top Headline & Subheadline
    let titleFont = NSFont.systemFont(ofSize: 76, weight: .heavy)
    let subtitleFont = NSFont.systemFont(ofSize: 38, weight: .medium)
    
    drawText(title, in: CGRect(x: 80, y: h - 330, width: w - 160, height: 180), font: titleFont, color: .white, alignment: .center)
    drawText(subtitle, in: CGRect(x: 100, y: h - 450, width: w - 200, height: 110), font: subtitleFont, color: primaryGreen, alignment: .center)
    
    // Phone Device Frame
    let phoneWidth: CGFloat = 1050
    let phoneHeight: CGFloat = 2150
    let phoneX = (w - phoneWidth) / 2
    let phoneY: CGFloat = -100 // clipped slightly at bottom for standard App Store style
    let phoneRect = CGRect(x: phoneX, y: phoneY, width: phoneWidth, height: phoneHeight)
    
    // Device Outer Border & Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 25), blur: 70, color: NSColor.black.withAlphaComponent(0.7).cgColor)
    drawRoundedRect(ctx: ctx, rect: phoneRect, cornerRadius: 110, fill: NSColor(hex: 0x000000), stroke: NSColor(hex: 0x333333), lineWidth: 10)
    ctx.restoreGState()
    
    // Phone Inner Screen
    let screenInset: CGFloat = 20
    let screenRect = phoneRect.insetBy(dx: screenInset, dy: screenInset)
    drawRoundedRect(ctx: ctx, rect: screenRect, cornerRadius: 90, fill: NSColor(hex: 0x000000))
    
    // Dynamic Island Mockup
    let islandW: CGFloat = 260
    let islandH: CGFloat = 65
    let islandX = screenRect.midX - (islandW / 2)
    let islandY = screenRect.maxY - 110
    drawRoundedRect(ctx: ctx, rect: CGRect(x: islandX, y: islandY, width: islandW, height: islandH), cornerRadius: 32, fill: .black)
    
    // Status Bar items (Time, Battery)
    let statusFont = NSFont.systemFont(ofSize: 30, weight: .semibold)
    drawText("9:41", in: CGRect(x: screenRect.minX + 70, y: screenRect.maxY - 95, width: 140, height: 40), font: statusFont, color: .white)
    
    // App Navigation Bar inside Screen
    let navY = screenRect.maxY - 220
    let navTitleFont = NSFont.systemFont(ofSize: 48, weight: .bold)
    drawText("Schrittweise", in: CGRect(x: screenRect.minX + 50, y: navY, width: 400, height: 60), font: navTitleFont, color: .white)
    
    // Date header
    let dateFont = NSFont.systemFont(ofSize: 26, weight: .medium)
    drawText("HEUTE, 17. NOVEMBER", in: CGRect(x: screenRect.minX + 52, y: navY + 58, width: 400, height: 35), font: dateFont, color: secondaryText)
    
    return screenRect
}

// -------------------------------------------------------------
// Screen 1: Dashboard & Progress
// -------------------------------------------------------------
func generateIPhoneScreen1() {
    let (rep, ctx) = makeIPhoneContext()
    let screen = drawIPhoneBase(ctx: ctx, title: "Tagesziel & Aktivität im Blick", subtitle: "Dynamischer Fortschrittsring in Echtzeit")
    
    // Hero Progress Card
    let heroRect = CGRect(x: screen.minX + 40, y: screen.maxY - 880, width: screen.width - 80, height: 620)
    drawRoundedRect(ctx: ctx, rect: heroRect, cornerRadius: 40, fill: cardBgDark, stroke: cardBorder, lineWidth: 2)
    
    // Circular Ring in Hero Card
    let ringCenter = CGPoint(x: heroRect.midX, y: heroRect.minY + 360)
    drawProgressRing(ctx: ctx, center: ringCenter, radius: 170, lineWidth: 28, progress: 0.784)
    
    // Inner Ring Labels
    let stepsNumberFont = NSFont.systemFont(ofSize: 72, weight: .heavy)
    let stepsLabelFont = NSFont.systemFont(ofSize: 28, weight: .semibold)
    let goalLabelFont = NSFont.systemFont(ofSize: 26, weight: .medium)
    
    drawText("7.842", in: CGRect(x: heroRect.minX, y: ringCenter.y - 45, width: heroRect.width, height: 85), font: stepsNumberFont, color: .white, alignment: .center)
    drawText("Schritte heute", in: CGRect(x: heroRect.minX, y: ringCenter.y - 95, width: heroRect.width, height: 40), font: stepsLabelFont, color: primaryGreen, alignment: .center)
    drawText("Tagesziel: 10.000", in: CGRect(x: heroRect.minX, y: ringCenter.y + 70, width: heroRect.width, height: 35), font: goalLabelFont, color: secondaryText, alignment: .center)
    
    // Bottom Hero Bar: 78% • Noch 2.158 Schritte
    let badgeRect = CGRect(x: heroRect.minX + 50, y: heroRect.minY + 45, width: heroRect.width - 100, height: 65)
    drawRoundedRect(ctx: ctx, rect: badgeRect, cornerRadius: 20, fill: NSColor.white.withAlphaComponent(0.06))
    let badgeFont = NSFont.systemFont(ofSize: 30, weight: .bold)
    drawText("78% erreicht  •  Noch 2.158 Schritte", in: CGRect(x: badgeRect.minX, y: badgeRect.minY + 14, width: badgeRect.width, height: 45), font: badgeFont, color: primaryGreen, alignment: .center)
    
    // 3 Metric Cards Grid
    let gridY = heroRect.minY - 240
    let cardW = (heroRect.width - 40) / 3
    let metricHeight: CGFloat = 210
    
    let metrics: [(String, String, String, NSColor)] = [
        ("Distanz", "5.88 km", "location.fill", cyanColor),
        ("Kalorien", "314 kcal", "flame.fill", orangeColor),
        ("Fortschritt", "78%", "target", primaryGreen)
    ]
    
    for (i, m) in metrics.enumerated() {
        let cardRect = CGRect(x: heroRect.minX + CGFloat(i) * (cardW + 20), y: gridY, width: cardW, height: metricHeight)
        drawRoundedRect(ctx: ctx, rect: cardRect, cornerRadius: 30, fill: cardBgDark, stroke: cardBorder, lineWidth: 2)
        
        let mLabelFont = NSFont.systemFont(ofSize: 26, weight: .medium)
        let mValFont = NSFont.systemFont(ofSize: 42, weight: .heavy)
        
        drawText(m.0, in: CGRect(x: cardRect.minX + 24, y: cardRect.maxY - 60, width: cardRect.width - 48, height: 35), font: mLabelFont, color: m.3)
        drawText(m.1, in: CGRect(x: cardRect.minX + 24, y: cardRect.minY + 40, width: cardRect.width - 48, height: 60), font: mValFont, color: .white)
    }
    
    // Action Button Preview
    let btnY = gridY - 150
    let btnRect = CGRect(x: heroRect.minX, y: btnY, width: heroRect.width, height: 110)
    drawRoundedRect(ctx: ctx, rect: btnRect, cornerRadius: 28, fill: primaryGreen)
    let btnFont = NSFont.systemFont(ofSize: 34, weight: .bold)
    drawText("Tagesziel ändern & Einstellungen", in: CGRect(x: btnRect.minX, y: btnRect.minY + 32, width: btnRect.width, height: 50), font: btnFont, color: .black, alignment: .center)
    
    saveImage(rep: rep, to: "AppStore_Screenshots/iPhone/01_iPhone_Tagesfortschritt.png")
}

// -------------------------------------------------------------
// Screen 2: 7-Days History
// -------------------------------------------------------------
func generateIPhoneScreen2() {
    let (rep, ctx) = makeIPhoneContext()
    let screen = drawIPhoneBase(ctx: ctx, title: "7-Tage-Historie & Trends", subtitle: "Deine Aktivität der Woche auf einen Blick")
    
    // Weekly Chart Card
    let chartRect = CGRect(x: screen.minX + 40, y: screen.maxY - 1100, width: screen.width - 80, height: 840)
    drawRoundedRect(ctx: ctx, rect: chartRect, cornerRadius: 40, fill: cardBgDark, stroke: cardBorder, lineWidth: 2)
    
    let titleFont = NSFont.systemFont(ofSize: 42, weight: .bold)
    let avgFont = NSFont.systemFont(ofSize: 28, weight: .medium)
    drawText("Letzte 7 Tage", in: CGRect(x: chartRect.minX + 40, y: chartRect.maxY - 80, width: 400, height: 50), font: titleFont, color: .white)
    drawText("Ø 9.608 Schritte / Tag", in: CGRect(x: chartRect.maxX - 440, y: chartRect.maxY - 72, width: 400, height: 40), font: avgFont, color: primaryGreen, alignment: .right)
    
    // Chart Bars
    let days: [(String, Int, Bool)] = [
        ("Mo", 8400, false),
        ("Di", 10250, true),
        ("Mi", 9120, false),
        ("Do", 11450, true),
        ("Fr", 7900, false),
        ("Sa", 12300, true),
        ("So", 7842, false)
    ]
    
    let maxSteps = 14000
    let chartAreaH: CGFloat = 460
    let chartBottom: CGFloat = chartRect.minY + 150
    let barWidth: CGFloat = (chartRect.width - 160) / 7
    
    // Goal line (10.000)
    let goalY = chartBottom + (chartAreaH * CGFloat(10000) / CGFloat(maxSteps))
    ctx.setStrokeColor(yellowColor.withAlphaComponent(0.5).cgColor)
    ctx.setLineWidth(2)
    ctx.setLineDash(phase: 0, lengths: [8, 6])
    ctx.beginPath()
    ctx.move(to: CGPoint(x: chartRect.minX + 40, y: goalY))
    ctx.addLine(to: CGPoint(x: chartRect.maxX - 40, y: goalY))
    ctx.strokePath()
    ctx.setLineDash(phase: 0, lengths: [])
    
    let goalTextFont = NSFont.systemFont(ofSize: 22, weight: .semibold)
    drawText("ZIEL: 10.000", in: CGRect(x: chartRect.minX + 45, y: goalY + 6, width: 200, height: 30), font: goalTextFont, color: yellowColor)
    
    let dayFont = NSFont.systemFont(ofSize: 26, weight: .bold)
    let stepsFont = NSFont.systemFont(ofSize: 22, weight: .medium)
    
    for (i, day) in days.enumerated() {
        let x = chartRect.minX + 60 + CGFloat(i) * (barWidth + 12)
        let barH = chartAreaH * (CGFloat(day.1) / CGFloat(maxSteps))
        let barRect = CGRect(x: x, y: chartBottom, width: barWidth - 12, height: barH)
        
        let barColor = day.2 ? primaryGreen : cyanColor.withAlphaComponent(0.85)
        drawRoundedRect(ctx: ctx, rect: barRect, cornerRadius: 14, fill: barColor)
        
        // Day label below
        drawText(day.0, in: CGRect(x: x - 6, y: chartBottom - 50, width: barWidth, height: 35), font: dayFont, color: day.2 ? .white : secondaryText, alignment: .center)
        
        // Value label above
        let valStr = String(format: "%.1fk", Double(day.1) / 1000.0)
        drawText(valStr, in: CGRect(x: x - 10, y: chartBottom + barH + 12, width: barWidth + 8, height: 30), font: stepsFont, color: day.2 ? primaryGreen : secondaryText, alignment: .center)
    }
    
    // Bottom Stat Highlight Cards
    let summaryY = chartRect.minY - 260
    let sCardW = (chartRect.width - 24) / 2
    
    // Left Stat Card
    let leftCard = CGRect(x: chartRect.minX, y: summaryY, width: sCardW, height: 220)
    drawRoundedRect(ctx: ctx, rect: leftCard, cornerRadius: 32, fill: cardBgDark, stroke: cardBorder, lineWidth: 2)
    drawText("Ziele erreicht", in: CGRect(x: leftCard.minX + 30, y: leftCard.maxY - 65, width: leftCard.width - 60, height: 35), font: avgFont, color: secondaryText)
    drawText("3 von 7 Tagen 🏆", in: CGRect(x: leftCard.minX + 30, y: leftCard.minY + 45, width: leftCard.width - 60, height: 60), font: NSFont.systemFont(ofSize: 42, weight: .heavy), color: yellowColor)
    
    // Right Stat Card
    let rightCard = CGRect(x: chartRect.minX + sCardW + 24, y: summaryY, width: sCardW, height: 220)
    drawRoundedRect(ctx: ctx, rect: rightCard, cornerRadius: 32, fill: cardBgDark, stroke: cardBorder, lineWidth: 2)
    drawText("Gesamtstrecke", in: CGRect(x: rightCard.minX + 30, y: rightCard.maxY - 65, width: rightCard.width - 60, height: 35), font: avgFont, color: secondaryText)
    drawText("48.5 km", in: CGRect(x: rightCard.minX + 30, y: rightCard.minY + 45, width: rightCard.width - 60, height: 60), font: NSFont.systemFont(ofSize: 42, weight: .heavy), color: cyanColor)
    
    saveImage(rep: rep, to: "AppStore_Screenshots/iPhone/02_iPhone_Wochenhistorie.png")
}

// -------------------------------------------------------------
// Screen 3: Goal Setting & Motivations
// -------------------------------------------------------------
func generateIPhoneScreen3() {
    let (rep, ctx) = makeIPhoneContext()
    let screen = drawIPhoneBase(ctx: ctx, title: "Ziel flexibel & Motivation", subtitle: "Passe dein Ziel jederzeit an & erhalte Motivation")
    
    // Modal Sheet Card
    let sheetRect = CGRect(x: screen.minX + 40, y: screen.maxY - 1320, width: screen.width - 80, height: 1060)
    drawRoundedRect(ctx: ctx, rect: sheetRect, cornerRadius: 44, fill: cardBgDark, stroke: cardBorder, lineWidth: 2)
    
    // Grabber
    let grabberW: CGFloat = 120
    let grabberH: CGFloat = 10
    drawRoundedRect(ctx: ctx, rect: CGRect(x: sheetRect.midX - (grabberW/2), y: sheetRect.maxY - 35, width: grabberW, height: grabberH), cornerRadius: 5, fill: NSColor.white.withAlphaComponent(0.3))
    
    let modalTitleFont = NSFont.systemFont(ofSize: 46, weight: .bold)
    drawText("Tagesziel anpassen", in: CGRect(x: sheetRect.minX + 40, y: sheetRect.maxY - 110, width: sheetRect.width - 80, height: 60), font: modalTitleFont, color: .white, alignment: .center)
    
    // Current Target Display
    let numFont = NSFont.systemFont(ofSize: 84, weight: .heavy)
    let subNumFont = NSFont.systemFont(ofSize: 32, weight: .semibold)
    drawText("10.000", in: CGRect(x: sheetRect.minX, y: sheetRect.maxY - 250, width: sheetRect.width, height: 100), font: numFont, color: primaryGreen, alignment: .center)
    drawText("Schritte pro Tag", in: CGRect(x: sheetRect.minX, y: sheetRect.maxY - 305, width: sheetRect.width, height: 45), font: subNumFont, color: secondaryText, alignment: .center)
    
    // Quick Presets Grid (2x3)
    let presets = [5000, 8000, 10000, 12000, 15000, 20000]
    let pillW = (sheetRect.width - 120) / 3
    let pillH: CGFloat = 75
    let gridStartY = sheetRect.maxY - 520
    
    for (i, p) in presets.enumerated() {
        let col = i % 3
        let row = i / 3
        let px = sheetRect.minX + 40 + CGFloat(col) * (pillW + 20)
        let py = gridStartY - CGFloat(row) * (pillH + 20)
        let pRect = CGRect(x: px, y: py, width: pillW, height: pillH)
        
        let isSelected = (p == 10000)
        drawRoundedRect(
            ctx: ctx,
            rect: pRect,
            cornerRadius: 22,
            fill: isSelected ? primaryGreen : NSColor.white.withAlphaComponent(0.08),
            stroke: isSelected ? nil : cardBorder,
            lineWidth: 1
        )
        
        let pFont = NSFont.systemFont(ofSize: 28, weight: .bold)
        drawText("\(p.formatted())", in: CGRect(x: pRect.minX, y: pRect.minY + 20, width: pRect.width, height: 40), font: pFont, color: isSelected ? .black : .white, alignment: .center)
    }
    
    // Notification Toggle Card
    let notifY = gridStartY - 240
    let notifRect = CGRect(x: sheetRect.minX + 40, y: notifY, width: sheetRect.width - 80, height: 160)
    drawRoundedRect(ctx: ctx, rect: notifRect, cornerRadius: 28, fill: NSColor.white.withAlphaComponent(0.06), stroke: cardBorder, lineWidth: 1)
    
    let nTitleFont = NSFont.systemFont(ofSize: 32, weight: .bold)
    let nDescFont = NSFont.systemFont(ofSize: 24, weight: .medium)
    drawText("Smarte Motivations-Mitteilungen", in: CGRect(x: notifRect.minX + 30, y: notifRect.maxY - 60, width: notifRect.width - 180, height: 40), font: nTitleFont, color: .white)
    drawText("Mitteilungen bei 25%, 50%, 75%, 90% und 100%", in: CGRect(x: notifRect.minX + 30, y: notifRect.minY + 30, width: notifRect.width - 180, height: 40), font: nDescFont, color: secondaryText)
    
    // iOS Toggle Switch Mockup (ON)
    let toggleRect = CGRect(x: notifRect.maxX - 130, y: notifRect.midY - 26, width: 100, height: 55)
    drawRoundedRect(ctx: ctx, rect: toggleRect, cornerRadius: 28, fill: primaryGreen)
    let knobRect = CGRect(x: toggleRect.maxX - 52, y: toggleRect.minY + 3, width: 49, height: 49)
    drawRoundedRect(ctx: ctx, rect: knobRect, cornerRadius: 24.5, fill: .white)
    
    // Save Button
    let saveY = notifY - 140
    let saveBtn = CGRect(x: sheetRect.minX + 40, y: saveY, width: sheetRect.width - 80, height: 105)
    drawRoundedRect(ctx: ctx, rect: saveBtn, cornerRadius: 30, fill: primaryGreen)
    drawText("Ziel speichern", in: CGRect(x: saveBtn.minX, y: saveBtn.minY + 28, width: saveBtn.width, height: 50), font: NSFont.systemFont(ofSize: 36, weight: .bold), color: .black, alignment: .center)
    
    saveImage(rep: rep, to: "AppStore_Screenshots/iPhone/03_iPhone_Ziele_Motivation.png")
}

// =========================================================================
// MARK: - Apple Watch Screenshot Generator (410 x 502)
// =========================================================================

func makeWatchContext() -> (NSBitmapImageRep, CGContext) {
    let w = 410
    let h = 502
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: w,
        pixelsHigh: h,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    return (rep, ctx)
}

// -------------------------------------------------------------
// Watch Screen 1: App Interface
// -------------------------------------------------------------
func generateWatchScreen1() {
    let (rep, ctx) = makeWatchContext()
    let w: CGFloat = 410
    let h: CGFloat = 502
    
    // Full Watch Screen background (Black with rounded corners)
    drawRoundedRect(ctx: ctx, rect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 70, fill: .black)
    
    // Top Bar (Time & Title)
    let timeFont = NSFont.systemFont(ofSize: 18, weight: .semibold)
    let titleFont = NSFont.systemFont(ofSize: 17, weight: .bold)
    drawText("9:41", in: CGRect(x: 24, y: h - 38, width: 80, height: 24), font: timeFont, color: primaryGreen)
    drawText("Schrittweise", in: CGRect(x: 0, y: h - 70, width: w, height: 26), font: titleFont, color: .white, alignment: .center)
    
    // Circular Progress Ring
    let ringCenter = CGPoint(x: w / 2, y: h - 180)
    drawProgressRing(ctx: ctx, center: ringCenter, radius: 68, lineWidth: 13, progress: 0.784)
    
    // Steps in Center of Ring
    let stepsFont = NSFont.systemFont(ofSize: 32, weight: .heavy)
    let goalFont = NSFont.systemFont(ofSize: 13, weight: .medium)
    drawText("7.842", in: CGRect(x: 0, y: ringCenter.y - 18, width: w, height: 38), font: stepsFont, color: .white, alignment: .center)
    drawText("Ziel: 10.000", in: CGRect(x: 0, y: ringCenter.y - 42, width: w, height: 20), font: goalFont, color: secondaryText, alignment: .center)
    
    // Percentage Status
    let pctFont = NSFont.systemFont(ofSize: 14, weight: .bold)
    drawText("78% • Noch 2.158", in: CGRect(x: 0, y: ringCenter.y - 105, width: w, height: 22), font: pctFont, color: primaryGreen, alignment: .center)
    
    // Metric Cards (Distance & Calories)
    let cardW: CGFloat = 175
    let cardH: CGFloat = 64
    let cardY: CGFloat = 90
    
    // Distance Card
    let dRect = CGRect(x: 24, y: cardY, width: cardW, height: cardH)
    drawRoundedRect(ctx: ctx, rect: dRect, cornerRadius: 16, fill: NSColor(hex: 0x1A2220), stroke: cardBorder, lineWidth: 1)
    let mLabelFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    let mValFont = NSFont.systemFont(ofSize: 17, weight: .bold)
    drawText("Distanz", in: CGRect(x: dRect.minX + 12, y: dRect.maxY - 24, width: 100, height: 18), font: mLabelFont, color: cyanColor)
    drawText("5.88 km", in: CGRect(x: dRect.minX + 12, y: dRect.minY + 8, width: 150, height: 26), font: mValFont, color: .white)
    
    // Calories Card
    let cRect = CGRect(x: w - 24 - cardW, y: cardY, width: cardW, height: cardH)
    drawRoundedRect(ctx: ctx, rect: cRect, cornerRadius: 16, fill: NSColor(hex: 0x1A2220), stroke: cardBorder, lineWidth: 1)
    drawText("Kalorien", in: CGRect(x: cRect.minX + 12, y: cRect.maxY - 24, width: 100, height: 18), font: mLabelFont, color: orangeColor)
    drawText("314 kcal", in: CGRect(x: cRect.minX + 12, y: cRect.minY + 8, width: 150, height: 26), font: mValFont, color: .white)
    
    // Goal change button
    let btnRect = CGRect(x: 24, y: 22, width: w - 48, height: 50)
    drawRoundedRect(ctx: ctx, rect: btnRect, cornerRadius: 25, fill: NSColor.white.withAlphaComponent(0.12))
    let btnFont = NSFont.systemFont(ofSize: 15, weight: .semibold)
    drawText("🎯  Ziel ändern", in: CGRect(x: btnRect.minX, y: btnRect.minY + 14, width: btnRect.width, height: 24), font: btnFont, color: .white, alignment: .center)
    
    saveImage(rep: rep, to: "AppStore_Screenshots/AppleWatch/01_Watch_App.png")
}

// -------------------------------------------------------------
// Watch Screen 2: Complications
// -------------------------------------------------------------
func generateWatchScreen2() {
    let (rep, ctx) = makeWatchContext()
    let w: CGFloat = 410
    let h: CGFloat = 502
    
    drawRoundedRect(ctx: ctx, rect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 70, fill: .black)
    
    // Time Header
    let timeFont = NSFont.systemFont(ofSize: 18, weight: .semibold)
    drawText("9:41", in: CGRect(x: 24, y: h - 38, width: 80, height: 24), font: timeFont, color: primaryGreen)
    
    // Header
    let hTitleFont = NSFont.systemFont(ofSize: 16, weight: .bold)
    let hSubFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    drawText("KOMPLIKATIONEN", in: CGRect(x: 0, y: h - 70, width: w, height: 22), font: hTitleFont, color: primaryGreen, alignment: .center)
    drawText("3 Designs für dein Zifferblatt", in: CGRect(x: 0, y: h - 92, width: w, height: 18), font: hSubFont, color: secondaryText, alignment: .center)
    
    // 1. Rectangular Complication Preview
    let comp1Rect = CGRect(x: 24, y: h - 230, width: w - 48, height: 120)
    drawRoundedRect(ctx: ctx, rect: comp1Rect, cornerRadius: 18, fill: NSColor.white.withAlphaComponent(0.1), stroke: primaryGreen.withAlphaComponent(0.4), lineWidth: 1.5)
    
    let cTitleFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    let cPctFont = NSFont.systemFont(ofSize: 13, weight: .bold)
    drawText("🚶  Schritte", in: CGRect(x: comp1Rect.minX + 16, y: comp1Rect.maxY - 28, width: 140, height: 20), font: cTitleFont, color: primaryGreen)
    drawText("78%", in: CGRect(x: comp1Rect.maxX - 80, y: comp1Rect.maxY - 28, width: 64, height: 20), font: cPctFont, color: primaryGreen, alignment: .right)
    
    let cBigFont = NSFont.systemFont(ofSize: 26, weight: .heavy)
    let cSubFont = NSFont.systemFont(ofSize: 13, weight: .medium)
    drawText("7.842", in: CGRect(x: comp1Rect.minX + 16, y: comp1Rect.minY + 36, width: 150, height: 35), font: cBigFont, color: .white)
    drawText("/ 10.000  •  5.9 km", in: CGRect(x: comp1Rect.minX + 105, y: comp1Rect.minY + 41, width: 180, height: 20), font: cSubFont, color: secondaryText)
    
    // Slim progress bar inside complication
    let barRect = CGRect(x: comp1Rect.minX + 16, y: comp1Rect.minY + 16, width: comp1Rect.width - 32, height: 8)
    drawRoundedRect(ctx: ctx, rect: barRect, cornerRadius: 4, fill: NSColor.white.withAlphaComponent(0.2))
    let fillRect = CGRect(x: barRect.minX, y: barRect.minY, width: barRect.width * 0.78, height: 8)
    drawRoundedRect(ctx: ctx, rect: fillRect, cornerRadius: 4, fill: primaryGreen)
    
    // 2. Big Number Complication Preview
    let comp2Rect = CGRect(x: 24, y: 130, width: (w - 60) / 2, height: 110)
    drawRoundedRect(ctx: ctx, rect: comp2Rect, cornerRadius: 18, fill: NSColor.white.withAlphaComponent(0.08))
    drawText("Große Zahl", in: CGRect(x: comp2Rect.minX + 10, y: comp2Rect.maxY - 25, width: comp2Rect.width - 20, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .semibold), color: secondaryText, alignment: .center)
    drawText("7.842", in: CGRect(x: comp2Rect.minX, y: comp2Rect.minY + 24, width: comp2Rect.width, height: 42), font: NSFont.systemFont(ofSize: 32, weight: .heavy), color: .white, alignment: .center)
    
    // 3. Circular Complication Preview
    let comp3Rect = CGRect(x: comp2Rect.maxX + 12, y: 130, width: (w - 60) / 2, height: 110)
    drawRoundedRect(ctx: ctx, rect: comp3Rect, cornerRadius: 18, fill: NSColor.white.withAlphaComponent(0.08))
    drawText("Kreisring", in: CGRect(x: comp3Rect.minX + 10, y: comp3Rect.maxY - 25, width: comp3Rect.width - 20, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .semibold), color: secondaryText, alignment: .center)
    
    let ringC = CGPoint(x: comp3Rect.midX, y: comp3Rect.minY + 45)
    drawProgressRing(ctx: ctx, center: ringC, radius: 24, lineWidth: 6, progress: 0.78)
    drawText("7.8k", in: CGRect(x: comp3Rect.minX, y: ringC.y - 10, width: comp3Rect.width, height: 20), font: NSFont.systemFont(ofSize: 13, weight: .bold), color: .white, alignment: .center)
    
    // Footer description
    let fFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    drawText("Live-Updates im Hintergrund", in: CGRect(x: 0, y: 40, width: w, height: 22), font: fFont, color: primaryGreen, alignment: .center)
    drawText("Direkt aus Apple Health ohne Batterieverlust", in: CGRect(x: 0, y: 20, width: w, height: 18), font: NSFont.systemFont(ofSize: 10, weight: .regular), color: secondaryText, alignment: .center)
    
    saveImage(rep: rep, to: "AppStore_Screenshots/AppleWatch/02_Watch_Komplikationen.png")
}

// Run All
print("Starting screenshot generation...")
generateIPhoneScreen1()
generateIPhoneScreen2()
generateIPhoneScreen3()
generateWatchScreen1()
generateWatchScreen2()
print("All screenshots generated successfully!")
