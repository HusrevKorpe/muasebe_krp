import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Ekstreye gömülen fontlar.
///
/// **Bu fazın en kolay atlanan maddesi.** `pdf` paketinin yerleşik fontları
/// (Helvetica ve akrabaları) PDF standardının Latin-1 kümesiyle sınırlıdır:
/// `ğ ş ı İ` ve `₺` karakterlerini basmaz, yerlerine kutucuk koyar. Ekstre
/// müşteriye gönderilen belge olduğu için bu kabul edilemez — font gömmek
/// zorunludur.
///
/// Roboto, Flutter SDK'sının kendi kopyasından alındı (Apache 2.0); lisans
/// metni `assets/fonts/Roboto-LICENSE.txt` içinde duruyor.
class EkstreFontlari {
  const EkstreFontlari({required this.normal, required this.kalin});

  static const String normalYolu = 'assets/fonts/Roboto-Regular.ttf';
  static const String kalinYolu = 'assets/fonts/Roboto-Bold.ttf';

  /// Fontları varlık paketinden okur ve ayrıştırır.
  ///
  /// Ayrıştırma pahalıdır; her ekstrede tekrarlanmasın diye sonucu
  /// `ekstreFontlariSaglayici` önbelleğe alır (bkz. `viewmodel/`).
  static Future<EkstreFontlari> yukle() async => EkstreFontlari(
    normal: pw.Font.ttf(await rootBundle.load(normalYolu)),
    kalin: pw.Font.ttf(await rootBundle.load(kalinYolu)),
  );

  final pw.Font normal;
  final pw.Font kalin;
}
