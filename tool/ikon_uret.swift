// FidanCari uygulama ikonunu ve açılış görselini üretir.
//
// İkon ikili dosya olarak repoda duruyor ama kaynağı bu betik: renk ya da biçim
// değişince PNG'ler elle düzenlenmez, betik yeniden koşturulur.
//
//   swift tool/ikon_uret.swift
//
// Çizim CoreGraphics ile yapılıyor; makinede ImageMagick/PIL gerekmiyor.
//
// Marka: fidan yeşili zemin üzerinde beyaz fidan ve altında iki defter satırı —
// "fidan" ile "cari hesap" bir arada. 40 piksele indiğinde de okunsun diye
// ayrıntı yok, gövde ve yapraklar kalın.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Ayarlar

/// Tüm çizim 1024 birimlik tasarım uzayında yapılır, çıktı boyutuna ölçeklenir.
let tasarimBoyu: CGFloat = 1024

/// Tema ile aynı fidan yeşili (bkz. lib/app/tema.dart).
let ustRenk = (r: 0.239, g: 0.573, b: 0.259) // #3D9242
let altRenk = (r: 0.106, g: 0.369, b: 0.125) // #1B5E20

let renkUzayi = CGColorSpaceCreateDeviceRGB()

func renk(_ bilesen: (r: Double, g: Double, b: Double)) -> CGColor {
  CGColor(
    colorSpace: renkUzayi,
    components: [bilesen.r, bilesen.g, bilesen.b, 1]
  )!
}

let beyaz = CGColor(colorSpace: renkUzayi, components: [1, 1, 1, 1])!

// MARK: - Çizim

/// Zemin: dikey gradyan. [koseYaricapi] sıfırsa tam kare basar.
///
/// Uygulama ikonunda köşe yuvarlatma **yapılmaz** — iOS maskeyi kendisi
/// uygular, yuvarlatılmış ikon köşelerinde beyaz kırpıntı bırakır.
func zeminiCiz(_ baglam: CGContext, koseYaricapi: CGFloat) {
  let cerceve = CGRect(x: 0, y: 0, width: tasarimBoyu, height: tasarimBoyu)

  baglam.saveGState()
  if koseYaricapi > 0 {
    let yol = CGPath(
      roundedRect: cerceve,
      cornerWidth: koseYaricapi,
      cornerHeight: koseYaricapi,
      transform: nil
    )
    baglam.addPath(yol)
    baglam.clip()
  }

  let gradyan = CGGradient(
    colorsSpace: renkUzayi,
    colors: [renk(ustRenk), renk(altRenk)] as CFArray,
    locations: [0, 1]
  )!
  baglam.drawLinearGradient(
    gradyan,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: 0, y: tasarimBoyu),
    options: []
  )
  baglam.restoreGState()
}

/// Fidan: eğri gövde, iki yaprak ve altında iki defter satırı.
func fidaniCiz(_ baglam: CGContext) {
  baglam.setFillColor(beyaz)
  baglam.setStrokeColor(beyaz)
  baglam.setLineCap(.round)

  // Gövde — hafif S kıvrımı, düz çizgiden daha canlı duruyor.
  baglam.setLineWidth(46)
  baglam.move(to: CGPoint(x: 512, y: 700))
  baglam.addCurve(
    to: CGPoint(x: 512, y: 300),
    control1: CGPoint(x: 468, y: 590),
    control2: CGPoint(x: 548, y: 450)
  )
  baglam.strokePath()

  // Sol yaprak.
  baglam.move(to: CGPoint(x: 508, y: 552))
  baglam.addQuadCurve(
    to: CGPoint(x: 236, y: 372),
    control: CGPoint(x: 300, y: 596)
  )
  baglam.addQuadCurve(
    to: CGPoint(x: 508, y: 552),
    control: CGPoint(x: 400, y: 300)
  )
  baglam.fillPath()

  // Sağ yaprak — soldakinden yukarıda, simetri fazla durgun görünüyordu.
  baglam.move(to: CGPoint(x: 516, y: 442))
  baglam.addQuadCurve(
    to: CGPoint(x: 788, y: 262),
    control: CGPoint(x: 724, y: 486)
  )
  baglam.addQuadCurve(
    to: CGPoint(x: 516, y: 442),
    control: CGPoint(x: 624, y: 190)
  )
  baglam.fillPath()

  // Defter satırları: hem toprak hem cari hesap dökümü okunsun diye.
  baglam.setLineWidth(52)
  baglam.move(to: CGPoint(x: 276, y: 790))
  baglam.addLine(to: CGPoint(x: 748, y: 790))
  baglam.strokePath()

  baglam.setLineWidth(52)
  baglam.move(to: CGPoint(x: 366, y: 898))
  baglam.addLine(to: CGPoint(x: 658, y: 898))
  baglam.strokePath()
}

// MARK: - Üretim

/// [boyut] piksellik PNG üretir.
///
/// [saydam] yalnızca açılış görselinde açılır; mağaza ikonunda alfa kanalı
/// bulunması reddedilme sebebidir, bu yüzden ikon `noneSkipLast` ile basılır.
func gorselUret(boyut: Int, koseYaricapi: CGFloat, saydam: Bool) -> CGImage {
  let bilgi = saydam
    ? CGImageAlphaInfo.premultipliedLast.rawValue
    : CGImageAlphaInfo.noneSkipLast.rawValue

  let baglam = CGContext(
    data: nil,
    width: boyut,
    height: boyut,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: renkUzayi,
    bitmapInfo: bilgi
  )!

  // Tasarım uzayı y aşağı doğru artar; CoreGraphics'in tersini çeviriyoruz.
  let olcek = CGFloat(boyut) / tasarimBoyu
  baglam.translateBy(x: 0, y: CGFloat(boyut))
  baglam.scaleBy(x: olcek, y: -olcek)

  zeminiCiz(baglam, koseYaricapi: koseYaricapi)
  fidaniCiz(baglam)

  return baglam.makeImage()!
}

func yaz(_ gorsel: CGImage, _ yol: String) {
  let url = URL(fileURLWithPath: yol)
  let hedef = CGImageDestinationCreateWithURL(
    url as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
  )!
  CGImageDestinationAddImage(hedef, gorsel, nil)
  guard CGImageDestinationFinalize(hedef) else {
    FileHandle.standardError.write("Yazılamadı: \(yol)\n".data(using: .utf8)!)
    exit(1)
  }
  print("  \(yol)")
}

let kok = FileManager.default.currentDirectoryPath
let ikonKlasoru =
  "\(kok)/ios/Runner/Assets.xcassets/AppIcon.appiconset"
let acilisKlasoru =
  "\(kok)/ios/Runner/Assets.xcassets/LaunchImage.imageset"

/// Asset katalogundaki dosya adı → piksel boyu.
let ikonlar: [(ad: String, boyut: Int)] = [
  ("Icon-App-20x20@1x", 20),
  ("Icon-App-20x20@2x", 40),
  ("Icon-App-20x20@3x", 60),
  ("Icon-App-29x29@1x", 29),
  ("Icon-App-29x29@2x", 58),
  ("Icon-App-29x29@3x", 87),
  ("Icon-App-40x40@1x", 40),
  ("Icon-App-40x40@2x", 80),
  ("Icon-App-40x40@3x", 120),
  ("Icon-App-60x60@2x", 120),
  ("Icon-App-60x60@3x", 180),
  ("Icon-App-76x76@1x", 76),
  ("Icon-App-76x76@2x", 152),
  ("Icon-App-83.5x83.5@2x", 167),
  ("Icon-App-1024x1024@1x", 1024),
]

print("Uygulama ikonu:")
for ikon in ikonlar {
  let gorsel = gorselUret(boyut: ikon.boyut, koseYaricapi: 0, saydam: false)
  yaz(gorsel, "\(ikonKlasoru)/\(ikon.ad).png")
}

// Açılış görseli: köşesi yuvarlatılmış rozet. Beyaz zeminde de siyah zeminde de
// okunsun diye kendi zeminini taşıyor (storyboard sistem rengini kullanıyor).
let acilisNoktaBoyu = 200
print("Açılış görseli:")
for olcek in 1...3 {
  let boyut = acilisNoktaBoyu * olcek
  let gorsel = gorselUret(
    boyut: boyut,
    koseYaricapi: tasarimBoyu * 0.2237,
    saydam: true
  )
  let ek = olcek == 1 ? "" : "@\(olcek)x"
  yaz(gorsel, "\(acilisKlasoru)/LaunchImage\(ek).png")
}
