import '../../core/para/kurus.dart';
import 'bakiye_satiri.dart';

/// Bir işlem kümesinin bakiye dökümü: satırlar ve toplamlar.
///
/// Referans ekstrenin son sayfasındaki üç rakam buradan gelir:
/// `TOPLAM ALACAK`, `TOPLAM BORÇ`, `BAKİYE`.
class BakiyeDokumu {
  const BakiyeDokumu({
    required this.satirlar,
    required this.devir,
    required this.toplamBorc,
    required this.toplamAlacak,
    required this.bakiye,
  });

  static const BakiyeDokumu bos = BakiyeDokumu(
    satirlar: <BakiyeSatiri>[],
    devir: Kurus.sifir,
    toplamBorc: Kurus.sifir,
    toplamAlacak: Kurus.sifir,
    bakiye: Kurus.sifir,
  );

  /// Satırlar, kendilerine verilen sırayı korur.
  final List<BakiyeSatiri> satirlar;

  /// Bu kümeden önceki bakiye. Tarih aralığı seçilmiş ekstrede "devreden"
  /// tutardır; tüm geçmiş dökülüyorsa sıfırdır.
  final Kurus devir;

  /// Yalnızca bu kümedeki işlemlerin toplamı — iptal edilmiş kayıtlar hariç.
  final Kurus toplamBorc;
  final Kurus toplamAlacak;

  /// `devir + toplamBorc − toplamAlacak`. Pozitifse cari işletmeye borçlu.
  final Kurus bakiye;

  bool get bosMu => satirlar.isEmpty;

  /// Toplamlar bakiyeyle tutuyor mu: `devir + borç − alacak == bakiye`.
  ///
  /// Referans ekstredeki yazılım bunu tutturamamış — tabloda borç kolonuna
  /// yazdığı işlemi toplamda alacak saymış. Ekstre bu kontrolü geçmeden
  /// PDF'e basılmaz (bkz. `domain/ekstre/ekstre.dart`).
  bool get tutarliMi => devir + toplamBorc - toplamAlacak == bakiye;

  @override
  String toString() =>
      'BakiyeDokumu(${satirlar.length} satır, bakiye: ${bakiye.deger})';
}
