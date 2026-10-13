# Генерує Swift-код векторних контурів (з SVG-шляхів веб-версії) — дуги переводяться в криві Безьє.
import sys
from svgelements import Path, Move, Line, CubicBezier, QuadraticBezier, Arc, Close

SHAPES = {
  # мультяшна рука (viewBox 0 0 64 84), кінчик пальця — (26, 3)
  'handCuff':  "M14 68 h34 a4 4 0 0 1 4 4 v11 h-42 v-11 a4 4 0 0 1 4 -4z",
  'handPalm':  "M19 42 V10 a7 7 0 0 1 14 0 v22 a5.5 5.5 0 0 1 10.5 1.5 a5.5 5.5 0 0 1 10 2.5 v13 q0 19 -19 19 h-6 q-11 0 -15.5 -9 l-6.5 -13 a5.2 5.2 0 0 1 8.5 -5.8 z",
  'handLines': "M33 32 v6 M43.5 33.5 v6",
  'handBlush': "M22.5 8.5 q3.5 -2.5 7 0",
  # циферблат-котик (координати SVG веб-версії, центр 150,150)
  'whiskerL':  "M16 146 L-18 134 M14 162 L-20 164 M18 178 L-14 192",
  'whiskerR':  "M284 146 L318 134 M286 162 L320 164 M282 178 L314 192",
  'earLOuter': "M36 72 L30 20 Q31 9 41 12 L99 23 Z",
  'earLInner': "M48 56 L45 28 L78 33 Z",
  'earROuter': "M264 72 L270 20 Q269 9 259 12 L201 23 Z",
  'earRInner': "M252 56 L255 28 L222 33 Z",
  'eyeClosedL':"M122 114 q6 -7 12 0",
  'eyeClosedR':"M166 114 q6 -7 12 0",
  'nose':      "M146 172 h8 l-4 4 z",
  'mouth':     "M150 176 q-4 6 -9 3 M150 176 q4 6 9 3",
  # хвиля між календарем і карткою (viewBox 0 0 390 26)
  'calWave':   "M0 14 C60 0 120 2 190 12 C260 22 320 24 390 8 V26 H0Z",
  # нота для кнопки музики (viewBox 0 0 24 24)
  'noteStem':  "M9 18V6l10-2v12",
  'noteWave1': "M22 8q1.6 2 0 4",
  'noteWave2': "M23.6 6.5q2.8 3.5 0 7",
  'noteSlash': "M3 3l18 18",
}
def f(v): return f"{v:.3f}".rstrip('0').rstrip('.') if '.' in f"{v:.3f}" else f"{v}"
out = ["// Згенеровано tools/gen_paths.py з SVG-контурів веб-версії. Не редагувати вручну.",
       "import SwiftUI", "", "enum VectorPaths {"]
for name, d in SHAPES.items():
    p = Path(d)
    lines = [f"    static let {name}: Path = {{", "        var p = Path()"]
    for seg in p.segments():
        if isinstance(seg, Move):
            lines.append(f"        p.move(to: CGPoint(x: {f(seg.end.x)}, y: {f(seg.end.y)}))")
        elif isinstance(seg, Close):
            lines.append("        p.closeSubpath()")
        elif isinstance(seg, Line):
            lines.append(f"        p.addLine(to: CGPoint(x: {f(seg.end.x)}, y: {f(seg.end.y)}))")
        elif isinstance(seg, QuadraticBezier):
            lines.append(f"        p.addQuadCurve(to: CGPoint(x: {f(seg.end.x)}, y: {f(seg.end.y)}), control: CGPoint(x: {f(seg.control.x)}, y: {f(seg.control.y)}))")
        elif isinstance(seg, CubicBezier):
            lines.append(f"        p.addCurve(to: CGPoint(x: {f(seg.end.x)}, y: {f(seg.end.y)}), control1: CGPoint(x: {f(seg.control1.x)}, y: {f(seg.control1.y)}), control2: CGPoint(x: {f(seg.control2.x)}, y: {f(seg.control2.y)}))")
        elif isinstance(seg, Arc):
            for c in seg.as_cubic_curves():
                lines.append(f"        p.addCurve(to: CGPoint(x: {f(c.end.x)}, y: {f(c.end.y)}), control1: CGPoint(x: {f(c.control1.x)}, y: {f(c.control1.y)}), control2: CGPoint(x: {f(c.control2.x)}, y: {f(c.control2.y)}))")
        else:
            raise SystemExit(f"невідомий сегмент {seg}")
    lines.append("        return p")
    lines.append("    }()")
    out += lines
out.append("}")
open(sys.argv[1], 'w', encoding='utf8').write("\n".join(out) + "\n")
print("ok", len(SHAPES))
