import '../../../data/islem/islem_kaydi.dart';

/// Cari detayındaki işlem listesinin durumu.
///
/// Yürüyen bakiye burada tutulmaz: o, listeye carinin önbelleklenmiş
/// bakiyesiyle birlikte bakılarak üretilir — bkz. `islem_dokumu_saglayici.dart`.
class IslemListesiDurumu {
  const IslemListesiDurumu({
    required this.kayitlar,
    this.dahaVar = false,
    this.dahaYukleniyor = false,
    this.sayfaHatasi,
  });

  static const IslemListesiDurumu bos = IslemListesiDurumu(
    kayitlar: <IslemKaydi>[],
  );

  /// En yeniden en eskiye sıralı kayıtlar.
  final List<IslemKaydi> kayitlar;

  final bool dahaVar;
  final bool dahaYukleniyor;

  /// Sonraki sayfa yüklenirken oluşan hata. Listedeki kayıtlar ekranda kalır.
  final String? sayfaHatasi;

  bool get bosMu => kayitlar.isEmpty;

  IslemListesiDurumu kopyala({
    List<IslemKaydi>? kayitlar,
    bool? dahaVar,
    bool? dahaYukleniyor,
    String? sayfaHatasi,
    bool hatayiTemizle = false,
  }) => IslemListesiDurumu(
    kayitlar: kayitlar ?? this.kayitlar,
    dahaVar: dahaVar ?? this.dahaVar,
    dahaYukleniyor: dahaYukleniyor ?? this.dahaYukleniyor,
    sayfaHatasi: hatayiTemizle ? null : (sayfaHatasi ?? this.sayfaHatasi),
  );
}
