import '../../../data/urun/urun_kaydi.dart';

/// Ürün listesi ekranının durumu.
class UrunListesiDurumu {
  const UrunListesiDurumu({
    this.kayitlar = const <UrunKaydi>[],
    this.arama = '',
    this.dahaVar = false,
    this.dahaYukleniyor = false,
    this.sayfaHatasi,
  });

  final List<UrunKaydi> kayitlar;
  final String arama;

  /// Sunucuda okunacak kayıt kaldı mı.
  final bool dahaVar;

  /// Sonraki sayfa şu anda yükleniyor mu. İlk yüklemeden ayrıdır: liste
  /// yerinde kalır, yalnızca altta bir gösterge döner.
  final bool dahaYukleniyor;

  /// Sonraki sayfa yüklenirken oluşan hata. İlk sayfa hatasından ayrı tutulur;
  /// eldeki kayıtlar ekranda kalmalı, kullanıcı yalnızca devamını kaybetmeli.
  final String? sayfaHatasi;

  bool get bosMu => kayitlar.isEmpty;

  bool get aramaVarMi => arama.trim().isNotEmpty;

  UrunListesiDurumu kopyala({
    List<UrunKaydi>? kayitlar,
    String? arama,
    bool? dahaVar,
    bool? dahaYukleniyor,
    String? sayfaHatasi,
    bool hatayiTemizle = false,
  }) => UrunListesiDurumu(
    kayitlar: kayitlar ?? this.kayitlar,
    arama: arama ?? this.arama,
    dahaVar: dahaVar ?? this.dahaVar,
    dahaYukleniyor: dahaYukleniyor ?? this.dahaYukleniyor,
    sayfaHatasi: hatayiTemizle ? null : (sayfaHatasi ?? this.sayfaHatasi),
  );
}
