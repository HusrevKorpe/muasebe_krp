import '../../core/para/kurus.dart';
import '../../core/tarih/tarih_bicimi.dart';
import '../cari/cari.dart';
import '../islem/bakiye_dokumu.dart';
import '../islem/bakiye_satiri.dart';
import '../isletme/isletme.dart';
import 'ekstre_araligi.dart';

/// PDF'e basılacak ekstrenin tamamı: başlık bilgileri, satırlar ve toplamlar.
///
/// Bu sınıf hesap yapmaz; [dokum] içindeki rakamları taşır ve doğruluğunu
/// [tutarliMi] ile beyan eder. Üretimi `EkstreOlusturucu` yapar.
class Ekstre {
  const Ekstre({
    required this.isletme,
    required this.cari,
    required this.aralik,
    required this.dokum,
    required this.hazirlanmaTarihi,
  });

  /// Ekstreyi gönderen işletme — sayfa başlığı buradan üretilir.
  final Isletme isletme;

  /// "İLGİLİ FİRMA" bloğundaki cari.
  final Cari cari;

  final EkstreAraligi aralik;

  /// Satırlar **eskiden yeniye** sıralıdır: ekstrenin doğal yönü budur ve
  /// [kapanisBakiyesi] son satırın bakiyesine eşittir.
  final BakiyeDokumu dokum;

  /// Alt bilgideki "… tarihinde hazırlanmıştır." tarihi.
  final DateTime hazirlanmaTarihi;

  List<BakiyeSatiri> get satirlar => dokum.satirlar;

  bool get bosMu => dokum.bosMu;

  /// Aralık başlamadan önceki bakiye — tablonun ilk satırı olarak basılır.
  ///
  /// Tarih aralığı seçilmiş bir ekstrede bu satır olmazsa bakiye kolonu
  /// sıfırdan başlar ve müşteriye yanlış borç gösterilir.
  Kurus get acilisBakiyesi => dokum.devir;

  bool get acilisBakiyesiVarMi => !dokum.devir.sifirMi;

  Kurus get toplamBorc => dokum.toplamBorc;
  Kurus get toplamAlacak => dokum.toplamAlacak;

  /// Ekstrenin sonucu: `açılış + toplam borç − toplam alacak`.
  Kurus get kapanisBakiyesi => dokum.bakiye;

  /// Başlıkta gösterilen aralığın ilk günü.
  ///
  /// "Tümü" seçildiğinde sınır yoktur; o zaman ilk işlemin tarihi yazılır —
  /// hiç işlem yoksa hazırlanma tarihi.
  DateTime get gosterilenBaslangic =>
      aralik.baslangic ??
      (bosMu ? hazirlanmaTarihi : satirlar.first.islem.islemTarihi);

  DateTime get gosterilenBitis => aralik.bitis ?? hazirlanmaTarihi;

  /// `17 Eylül 2021 — 24 Mayıs 2025`
  String get aralikMetni => tarihAraligi(gosterilenBaslangic, gosterilenBitis);

  /// Tablo ile toplamlar tutuyor mu?
  ///
  /// Referans yazılım bunu tutturamamış: listelediği faturalar `456.031,25 ₺`
  /// ederken `TOPLAM BORÇ` alanına `314.000,00 ₺` yazmış, son işlemi tabloda
  /// borç, toplamda alacak saymış. Biz o hatayı kopyalamıyoruz; kural iki
  /// parçalı (bkz. `fazlar/faz-4-ekstre.md`):
  ///
  /// 1. `açılış + toplam borç − toplam alacak == kapanış bakiyesi`
  /// 2. kapanış bakiyesi, tablodaki **son satırın** bakiyesine eşit
  ///
  /// İkinci koşul burada kontrol edilir, [BakiyeDokumu.tutarliMi] içinde değil:
  /// satır sırasını yalnızca bu sınıf garanti eder (ekran dökümü tersten
  /// yürür, orada son satır en eski işlemdir).
  bool get tutarliMi =>
      dokum.tutarliMi &&
      (bosMu || satirlar.last.yuruyenBakiye == kapanisBakiyesi);

  @override
  String toString() =>
      'Ekstre(${cari.ad}, ${satirlar.length} satır, '
      '${kapanisBakiyesi.deger})';
}
