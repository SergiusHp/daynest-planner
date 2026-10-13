import SwiftUI

// Палітра й типографіка — ті самі значення, що й у веб-версії (теплі кремові/персикові тони, коричневий контур).
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

enum Theme {
    static let day = Color(hex: 0xfef1d9)        // фон сторінки дня
    static let calTop = Color(hex: 0xfdecce)     // фон календаря й фокусу
    static let card = Color(hex: 0xfef2d7)       // картка під календарем
    static let sky = Color(hex: 0xfdd195)        // небо привітального екрана
    static let field = Color(hex: 0xf7af52)      // «поле» під кнопкою «Розпочати»
    static let accent = Color(hex: 0xf67a36)
    static let accentDark = Color(hex: 0xc95a1d)
    static let onAccent = Color(hex: 0xfffaf0)
    static let chip = Color(hex: 0xf8dcb1)
    static let tog = Color(hex: 0xfde5c4)
    static let brown = Color(hex: 0x5f2507)
    static let dotRing = Color(hex: 0x722403)
    static let ink = Color(hex: 0x2b1a0d)
    static let inkSoft = Color(hex: 0x4a3322)
    static let inkMuted = Color(hex: 0x86664a)
    static let inkFaint = Color(hex: 0xb9a07f)
    static let cream = Color(hex: 0xfffaf0)
    static let checkBg = Color(hex: 0xfdf4e3)
    static let scrim = Color(hex: 0x2b1a0d, alpha: 0.38)
    static let divider = Color(hex: 0x86664a, alpha: 0.16)
    static let error = Color(hex: 0xb24a12)
}

/// Накреслення Nunito, вбудованого в застосунок (див. Resources/Fonts, Info.plist → UIAppFonts).
enum NunitoWeight: String {
    case semibold = "Nunito-SemiBold"
    case bold = "Nunito-Bold"
    case extraBold = "Nunito-ExtraBold"
}

extension Font {
    /// Nunito, що масштабується разом із системним розміром тексту (відносно стилю `relativeTo`).
    static func nunito(_ size: CGFloat, _ weight: NunitoWeight = .semibold, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }
    /// Фіксований розмір — для мініатюр і циферблата, які масштабуються разом із малюнком.
    static func nunitoFixed(_ size: CGFloat, _ weight: NunitoWeight = .semibold) -> Font {
        .custom(weight.rawValue, fixedSize: size)
    }
}

/// Контур із фіксованої системи координат (як viewBox у SVG), вписаний у прямокутник.
struct ScaledPath: Shape {
    let path: Path
    let box: CGRect
    var uniform = true

    func path(in rect: CGRect) -> Path {
        var sx = rect.width / box.width, sy = rect.height / box.height
        if uniform { let s = min(sx, sy); sx = s; sy = s }
        let t = CGAffineTransform(translationX: rect.minX - box.minX * sx, y: rect.minY - box.minY * sy)
            .scaledBy(x: sx, y: sy)
        return path.applying(t)
    }
}

/// Тінь-«поличка» під кнопками, як `box-shadow: 0 3px 0` у веб-версії.
struct LedgeButtonStyle: ButtonStyle {
    var fill: Color
    var text: Color
    var ledge: Color
    var border: Color? = nil
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.nunito(17, .extraBold, relativeTo: .headline))
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                Capsule().fill(fill)
                    .overlay { if let border { Capsule().strokeBorder(border, lineWidth: 2.5) } }
                    .background(Capsule().fill(ledge).offset(y: pressed ? 1 : 4))
            )
            .offset(y: pressed ? 2 : 0)
            .animation(.easeOut(duration: 0.12), value: pressed)
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == LedgeButtonStyle {
    static var primaryLedge: LedgeButtonStyle {
        LedgeButtonStyle(fill: Theme.accent, text: Theme.onAccent, ledge: Theme.accentDark)
    }
    static var creamLedge: LedgeButtonStyle {
        LedgeButtonStyle(fill: Color(hex: 0xfef3dd), text: Theme.ink, ledge: Color(hex: 0x783c0a, alpha: 0.18))
    }
}

/// Кнопка без жодного системного оформлення (для котика, сонечка тощо): без фону, рамки й підсвітки.
struct InvisibleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.contentShape(Rectangle())
    }
}
