import SwiftUI
import AppKit

// MARK: - Color Palette
let appGreen = Color(red: 0x30/255.0, green: 0xD1/255.0, blue: 0x58/255.0)
let appMint = Color(red: 0x00/255.0, green: 0xC7/255.0, blue: 0xBE/255.0)
let appCyan = Color(red: 0x64/255.0, green: 0xD2/255.0, blue: 0xFF/255.0)
let appOrange = Color(red: 0xFF/255.0, green: 0x9F/255.0, blue: 0x0A/255.0)
let appYellow = Color(red: 0xFF/255.0, green: 0xD6/255.0, blue: 0x0A/255.0)

let bgBlack = Color(red: 0x07/255.0, green: 0x0A/255.0, blue: 0x08/255.0)
let cardBg = Color(red: 0x14/255.0, green: 0x1B/255.0, blue: 0x17/255.0)
let cardBorder = Color.white.opacity(0.08)

// MARK: - Status Bar View
struct StatusBarView: View {
    var body: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            // Dynamic Island Placeholder
            Capsule()
                .fill(Color.black)
                .frame(width: 120, height: 32)
                .overlay(
                    HStack(spacing: 8) {
                        Circle().fill(Color.black).frame(width: 11, height: 11)
                        Spacer()
                        Circle().fill(Color.blue.opacity(0.3)).frame(width: 10, height: 10)
                    }
                    .padding(.horizontal, 10)
                )
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

// MARK: - iPhone Screen 1: Tagesfortschritt
struct IPhoneScreen1View: View {
    var width: CGFloat = 393
    var height: CGFloat = 852
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // Nav Bar
            HStack {
                Text("Schrittweise")
                    .font(.system(size: width > 400 ? 34 : 30, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(appGreen)
                    .padding(9)
                    .background(Circle().fill(appGreen.opacity(0.15)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                // Haupt-Fortschritts-Ring Hero Card
                VStack(spacing: 14) {
                    ZStack {
                        // Hintergrund-Ring
                        Circle()
                            .stroke(appGreen.opacity(0.15), lineWidth: 22)
                        
                        // Fortschritts-Ring mit Farbverlauf
                        Circle()
                            .trim(from: 0, to: 0.754)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [appGreen, appMint, appCyan, appGreen]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 22, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        // Innere Daten
                        VStack(spacing: 3) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(appGreen)
                            
                            Text("7.542")
                                .font(.system(size: width > 400 ? 44 : 38, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("von 10.000")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("75%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(appGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(appGreen.opacity(0.2)))
                        }
                    }
                    .frame(width: width > 400 ? 230 : 205, height: width > 400 ? 230 : 205)
                    .padding(.vertical, 8)
                    
                    // Fehlende Schritte Leiste
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(appGreen)
                            .font(.system(size: 12))
                        Text("Noch **2.458 Schritte** bis zum Tagesziel")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 22).stroke(cardBorder, lineWidth: 1)))
                
                // Metriken-Grid (Distanz & Kalorien)
                HStack(spacing: 12) {
                    // Distanz Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "figure.walk.motion")
                                .foregroundColor(appCyan)
                                .font(.system(size: 15))
                            Spacer()
                            Text("Distanz")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        Text("5,8 km")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Heute zurückgelegt")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1)))
                    
                    // Kalorien Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(appOrange)
                                .font(.system(size: 15))
                            Spacer()
                            Text("Kalorien")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        Text("418 kcal")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Aktiv verbrannt")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1)))
                }
                
                // Schnell-Aktionen
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(appGreen)
                        Text("Tagesziel anpassen")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                }
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: height)
        .background(bgBlack)
    }
}

// MARK: - iPhone Screen 2: 7-Tage-Historie
struct IPhoneScreen2View: View {
    var width: CGFloat = 393
    var height: CGFloat = 852
    
    let weekDays: [(day: String, steps: Int, goal: Int, reached: Bool)] = [
        ("Mo", 8420, 10000, false),
        ("Di", 10450, 10000, true),
        ("Mi", 7200, 10000, false),
        ("Do", 11200, 10000, true),
        ("Fr", 9850, 10000, false),
        ("Sa", 12340, 10000, true),
        ("So", 7542, 10000, false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // Nav Bar
            HStack {
                Text("Wochen-Trend")
                    .font(.system(size: width > 400 ? 34 : 30, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Letzte 7 Tage")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appGreen)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(appGreen.opacity(0.18)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                // Haupt-Diagramm Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("DURCHSCHNITT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            Text("9.571")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("Schritte pro Tag")
                                .font(.system(size: 12))
                                .foregroundColor(appGreen)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("ZIELQUOTE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            Text("3 / 7")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(appYellow)
                            Text("Tage erreicht")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Balkendiagramm
                    let barWidth: CGFloat = width > 400 ? 34 : 28
                    let barMaxH: CGFloat = width > 400 ? 150 : 135
                    
                    HStack(alignment: .bottom, spacing: width > 400 ? 12 : 9) {
                        ForEach(weekDays, id: \.day) { item in
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    // Hintergrund-Säule
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: barWidth, height: barMaxH)
                                    
                                    // Aktiver Fortschrittsbalken
                                    let barH = CGFloat(item.steps) / 13000.0 * barMaxH
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(
                                            item.reached
                                            ? LinearGradient(colors: [appGreen, appMint], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [appCyan.opacity(0.8), appCyan.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .frame(width: barWidth, height: min(barMaxH, max(18, barH)))
                                        .overlay(
                                            item.reached
                                            ? Image(systemName: "star.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(.black)
                                                .padding(.top, 5)
                                            : nil,
                                            alignment: .top
                                        )
                                }
                                
                                Text(item.day)
                                    .font(.system(size: 12, weight: item.day == "So" ? .bold : .medium))
                                    .foregroundColor(item.day == "So" ? appGreen : .gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    
                    // Ziellinie Legende
                    HStack(spacing: 8) {
                        Circle().fill(appGreen).frame(width: 7, height: 7)
                        Text("Ziel erreicht (10.000+)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Spacer()
                        Circle().fill(appCyan).frame(width: 7, height: 7)
                        Text("Aktiv")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 22).stroke(cardBorder, lineWidth: 1)))
                
                // Gesamt-Statistiken
                VStack(spacing: 10) {
                    HStack {
                        Text("Wochen-Zusammenfassung")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("GESAMTSCHRITTE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("67.002")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05)))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("GESAMTDISTANZ")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("51,2 km")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(appCyan)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05)))
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 22).stroke(cardBorder, lineWidth: 1)))
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: height)
        .background(bgBlack)
    }
}

// MARK: - iPhone Screen 3: Ziele & Motivation
struct IPhoneScreen3View: View {
    var width: CGFloat = 393
    var height: CGFloat = 852
    
    let presetGoals = [5000, 8000, 10000, 12000, 15000, 20000]
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // Background Header
            HStack {
                Text("Einstellungen")
                    .font(.system(size: width > 400 ? 34 : 30, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                // Sheet-Like Card: Ziel einstellen
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("TÄGLICHES SCHRITTZIEL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Text("10.000")
                            .font(.system(size: width > 400 ? 46 : 40, weight: .heavy, design: .rounded))
                            .foregroundColor(appGreen)
                        
                        Text("Schritte jeden Tag")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 6)
                    
                    // Stepper Buttons
                    HStack(spacing: 20) {
                        HStack {
                            Image(systemName: "minus")
                            Text("500")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.1)))
                        
                        HStack {
                            Image(systemName: "plus")
                            Text("500")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.1)))
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Schnellauswahl Chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schnellauswahl")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(presetGoals, id: \.self) { goal in
                                Text("\(goal.formatted())")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(goal == 10000 ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(goal == 10000 ? appGreen : Color.white.opacity(0.08))
                                    )
                            }
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 22).stroke(cardBorder, lineWidth: 1)))
                
                // Motivations-Mitteilungen Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Smarte Motivation")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Mitteilungen bei Meilensteinen")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // Active Toggle
                        RoundedRectangle(cornerRadius: 15)
                            .fill(appGreen)
                            .frame(width: 46, height: 28)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .padding(2),
                                alignment: .trailing
                            )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Meilensteine Badges
                    HStack(spacing: 7) {
                        ForEach(["25%", "50%", "75%", "90%", "100%"], id: \.self) { milestone in
                            Text(milestone)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(appGreen)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(appGreen.opacity(0.15)))
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(cardBg).overlay(RoundedRectangle(cornerRadius: 22).stroke(cardBorder, lineWidth: 1)))
                
                // Speicher Button
                Text("Ziel speichern")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 15).fill(appGreen))
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: height)
        .background(bgBlack)
    }
}

// MARK: - Apple Watch Screen 1: Watch App
struct WatchScreen1View: View {
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("9:41")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(appGreen)
                Spacer()
                Image(systemName: "figure.walk")
                    .foregroundColor(appGreen)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // Ring
            ZStack {
                Circle()
                    .stroke(appGreen.opacity(0.2), lineWidth: 14)
                
                Circle()
                    .trim(from: 0, to: 0.754)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [appGreen, appMint, appCyan, appGreen]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("7.542")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("75%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(appGreen)
                }
            }
            .frame(width: 140, height: 140)
            .padding(.vertical, 4)
            
            // Metrics Pills
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .foregroundColor(appCyan)
                        .font(.system(size: 10))
                    Text("5,8 km")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(appOrange)
                        .font(.system(size: 10))
                    Text("418 kcal")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
            }
            
            Spacer()
        }
        .frame(width: 205, height: 251)
        .background(Color.black)
    }
}

// MARK: - Apple Watch Screen 2: Zifferblatt Komplikationen
struct WatchScreen2View: View {
    var body: some View {
        VStack(spacing: 10) {
            // Header / Watch Face Time
            VStack(spacing: 2) {
                Text("MO. 17. NOV.")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(appGreen)
                Text("10:09")
                    .font(.system(size: 38, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 14)
            
            // Modular Rectangular Complication
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(appGreen)
                        .font(.system(size: 11))
                    Text("SCHRITTE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("75%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(appGreen)
                }
                
                Text("7.542 / 10.000")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(colors: [appGreen, appMint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * 0.754)
                    }
                }
                .frame(height: 6)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
            .padding(.horizontal, 10)
            
            // Circular Complications Row
            HStack(spacing: 14) {
                // Complication: Ring + Count
                ZStack {
                    Circle().stroke(appGreen.opacity(0.2), lineWidth: 4)
                    Circle().trim(from: 0, to: 0.75)
                        .stroke(appGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("7.5k")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 44, height: 44)
                
                // Complication: Kalorien
                ZStack {
                    Circle().fill(Color.white.opacity(0.1))
                    VStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(appOrange)
                        Text("418")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 44, height: 44)
                
                // Complication: Distanz
                ZStack {
                    Circle().fill(Color.white.opacity(0.1))
                    VStack(spacing: 1) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 11))
                            .foregroundColor(appCyan)
                        Text("5.8k")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .padding(.top, 2)
            
            Spacer()
        }
        .frame(width: 205, height: 251)
        .background(Color.black)
    }
}

// Helper to save CGImage to disk
func savePNG(cgImg: CGImage, path: String) {
    let rep = NSBitmapImageRep(cgImage: cgImg)
    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: path))
    }
}

// MARK: - Main Execution
MainActor.assumeIsolated {
    let fm = FileManager.default
    
    // Create folders
    let iphoneDefaultDir = "AppStore_Screenshots/iPhone"
    let iphoneMediumDir = "AppStore_Screenshots/iPhone_Medium_Display_1179x2556"
    let iphoneLargeDir = "AppStore_Screenshots/iPhone_Large_Display_1290x2796"
    let watchDir = "AppStore_Screenshots/AppleWatch"
    let webDir = "docs/images"
    
    for dir in [iphoneDefaultDir, iphoneMediumDir, iphoneLargeDir, watchDir, webDir] {
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
    }
    
    // 1. Render iPhone Medium Display: 393 x 852 @ 3x scale = EXACT 1179 x 2556 px
    // (Matches "iPhone with Dynamic Island (medium display)" in App Store Connect!)
    let mediumScreens: [(view: AnyView, name: String)] = [
        (AnyView(IPhoneScreen1View(width: 393, height: 852)), "01_iPhone_Tagesfortschritt"),
        (AnyView(IPhoneScreen2View(width: 393, height: 852)), "02_iPhone_Wochenhistorie"),
        (AnyView(IPhoneScreen3View(width: 393, height: 852)), "03_iPhone_Ziele_Motivation")
    ]
    
    for (i, item) in mediumScreens.enumerated() {
        let renderer = ImageRenderer(content: item.view)
        renderer.scale = 3.0 // 393 * 3 = 1179, 852 * 3 = 2556
        if let cgImg = renderer.cgImage {
            // Save into standard iPhone folder (for immediate drag-and-drop into the active tab)
            let path1 = "\(iphoneDefaultDir)/\(item.name).png"
            savePNG(cgImg: cgImg, path: path1)
            
            // Also save into specifically labeled folder
            let path2 = "\(iphoneMediumDir)/\(item.name).png"
            savePNG(cgImg: cgImg, path: path2)
            print("Generated Medium Display (1179x2556): \(path1)")
        }
        
        // Web version
        let webRenderer = ImageRenderer(content: item.view)
        webRenderer.scale = 1.5
        if let cgImg = webRenderer.cgImage {
            let webPath = "\(webDir)/screen_iphone_\(i + 1).png"
            savePNG(cgImg: cgImg, path: webPath)
        }
    }
    
    // 2. Render iPhone Large Display: 430 x 932 @ 3x scale = EXACT 1290 x 2796 px
    // (Matches "iPhone with Dynamic Island (large display)" in App Store Connect!)
    let largeScreens: [(view: AnyView, name: String)] = [
        (AnyView(IPhoneScreen1View(width: 430, height: 932)), "01_iPhone_Tagesfortschritt"),
        (AnyView(IPhoneScreen2View(width: 430, height: 932)), "02_iPhone_Wochenhistorie"),
        (AnyView(IPhoneScreen3View(width: 430, height: 932)), "03_iPhone_Ziele_Motivation")
    ]
    
    for item in largeScreens {
        let renderer = ImageRenderer(content: item.view)
        renderer.scale = 3.0 // 430 * 3 = 1290, 932 * 3 = 2796
        if let cgImg = renderer.cgImage {
            let path = "\(iphoneLargeDir)/\(item.name).png"
            savePNG(cgImg: cgImg, path: path)
            print("Generated Large Display (1290x2796): \(path)")
        }
    }
    
    // 3. Render Apple Watch Screens
    // Standard Ultra: 205x251 @ 2x = 410x502
    let watchScreens: [(view: AnyView, name: String)] = [
        (AnyView(WatchScreen1View()), "01_Watch_App"),
        (AnyView(WatchScreen2View()), "02_Watch_Komplikationen")
    ]
    
    for (i, item) in watchScreens.enumerated() {
        let renderer = ImageRenderer(content: item.view)
        renderer.scale = 2.0 // 410x502
        if let cgImg = renderer.cgImage {
            let path = "\(watchDir)/\(item.name).png"
            savePNG(cgImg: cgImg, path: path)
            print("Generated Watch (410x502): \(path)")
            
            let webPath = "\(webDir)/screen_watch_\(i + 1).png"
            savePNG(cgImg: cgImg, path: webPath)
        }
    }
    
    print("DONE! ALL FORMATS READY FOR APP STORE CONNECT!")
}
