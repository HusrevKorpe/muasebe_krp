import '../../../data/cari/cari_kaydi.dart';
import '../../../domain/cari/cari_siralamasi.dart';

/// Cari listesi ekranının durumu.
class CariListesiDurumu {
  const CariListesiDurumu({
    this.kayitlar = const <CariKaydi>[],
    this.arama = '',
    this.siralama = CariSiralamasi.ad,
    this.dahaVar = false,
    this.dahaYukleniyor = false,
    this.sayfaHatasi,
  });

  final List<CariKaydi> kayitlar;
  final String arama;
  final CariSiralamasi siralama;

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

  CariListesiDurumu kopyala({
    List<CariKaydi>? kayitlar,
    String? arama,
    CariSiralamasi? siralama,
    bool? dahaVar,
    bool? dahaYukleniyor,
    String? sayfaHatasi,
    bool hatayiTemizle = false,
  }) => CariListesiDurumu(
    kayitlar: kayitlar ?? this.kayitlar,
    arama: arama ?? this.arama,
    siralama: siralama ?? this.siralama,
    dahaVar: dahaVar ?? this.dahaVar,
    dahaYukleniyor: dahaYukleniyor ?? this.dahaYukleniyor,
    sayfaHatasi: hatayiTemizle ? null : (sayfaHatasi ?? this.sayfaHatasi),
  );
}
