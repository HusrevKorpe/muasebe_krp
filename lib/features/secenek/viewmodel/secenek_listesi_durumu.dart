import '../../../data/secenek/secenek_kaydi.dart';

/// Tür, çeşit ya da anaç listesi ekranının durumu.
class SecenekListesiDurumu {
  const SecenekListesiDurumu({
    this.kayitlar = const <SecenekKaydi>[],
    this.arama = '',
    this.dahaVar = false,
    this.dahaYukleniyor = false,
    this.sayfaHatasi,
  });

  final List<SecenekKaydi> kayitlar;
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

  SecenekListesiDurumu kopyala({
    List<SecenekKaydi>? kayitlar,
    String? arama,
    bool? dahaVar,
    bool? dahaYukleniyor,
    String? sayfaHatasi,
    bool hatayiTemizle = false,
  }) => SecenekListesiDurumu(
    kayitlar: kayitlar ?? this.kayitlar,
    arama: arama ?? this.arama,
    dahaVar: dahaVar ?? this.dahaVar,
    dahaYukleniyor: dahaYukleniyor ?? this.dahaYukleniyor,
    sayfaHatasi: hatayiTemizle ? null : (sayfaHatasi ?? this.sayfaHatasi),
  );
}
