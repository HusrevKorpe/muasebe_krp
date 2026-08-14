import '../../../data/cari/cari_kaydi.dart';
import '../../../domain/cari/acik_hesap_ozeti.dart';

/// Cari listesi ekranının durumu.
class CariListesiDurumu {
  const CariListesiDurumu({
    this.kayitlar = const <CariKaydi>[],
    this.arama = '',
    this.dahaVar = false,
    this.dahaYukleniyor = false,
    this.sayfaHatasi,
  });

  final List<CariKaydi> kayitlar;
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

  /// Elde tutulan kayıtların alacak/borç toplamı. Açık hesap sekmesinin
  /// başlığında gösteriliyor.
  ///
  /// Toplam **yüklenmiş** kayıtları kapsar: [dahaVar] doğruysa listenin devamı
  /// geldikçe büyür, o yüzden başlık bunu kullanıcıya söyler. Sunucuda toplama
  /// yaptırmak (`aggregate`) çevrimdışı çalışmaz; uygulamanın tamamı önbellek
  /// üzerinden yürüdüğü için toplam da elden hesaplanıyor.
  AcikHesapOzeti get ozet =>
      AcikHesapOzeti.hesapla(kayitlar.map((kayit) => kayit.cari.bakiye));

  CariListesiDurumu kopyala({
    List<CariKaydi>? kayitlar,
    String? arama,
    bool? dahaVar,
    bool? dahaYukleniyor,
    String? sayfaHatasi,
    bool hatayiTemizle = false,
  }) => CariListesiDurumu(
    kayitlar: kayitlar ?? this.kayitlar,
    arama: arama ?? this.arama,
    dahaVar: dahaVar ?? this.dahaVar,
    dahaYukleniyor: dahaYukleniyor ?? this.dahaYukleniyor,
    sayfaHatasi: hatayiTemizle ? null : (sayfaHatasi ?? this.sayfaHatasi),
  );
}
