import '../cari/cari.dart';
import '../islem/bakiye_hesaplayici.dart';
import '../islem/islem.dart';
import '../islem/islem_siralamasi.dart';
import '../isletme/isletme.dart';
import 'ekstre.dart';
import 'ekstre_araligi.dart';

/// Cari + tarih aralığı + işlemler → [Ekstre].
///
/// İşin püf noktası **açılış bakiyesidir**: aralığın başlangıcından önceki
/// işlemler tabloya girmez ama bakiyeye girer. Atlanırsa ekstre sıfırdan
/// başlar ve müşteriye yanlış borç gösterilir — bu fazın en kolay gözden
/// kaçan hesabı (bkz. `fazlar/faz-4-ekstre.md`).
abstract final class EkstreOlusturucu {
  /// [islemler] sırasız verilebilir; burada aralığa göre ayrılır ve
  /// `islemKarsilastir` ile eskiden yeniye sıralanır.
  ///
  /// Aralığın **sonrasındaki** işlemler tamamen dışarıda kalır: ne tabloya
  /// girer ne de bakiyeye. Kullanıcı geçmiş bir dönemin ekstresini aldığında
  /// o günkü bakiyeyi görmeli, bugünküyü değil.
  static Ekstre olustur({
    required Isletme isletme,
    required Cari cari,
    required EkstreAraligi aralik,
    required Iterable<Islem> islemler,
    required DateTime hazirlanmaTarihi,
  }) {
    final oncekiler = <Islem>[];
    final icindekiler = <Islem>[];

    for (final islem in islemler) {
      if (aralik.oncesindeMi(islem.islemTarihi)) {
        oncekiler.add(islem);
      } else if (aralik.icerirMi(islem.islemTarihi)) {
        icindekiler.add(islem);
      }
    }

    // İptal edilmiş kayıtların etkisi sıfırdır (bkz. `Islem.bakiyeEtkisi`);
    // açılış bakiyesine de katılmazlar.
    final devir = BakiyeHesaplayici.bakiye(oncekiler);

    return Ekstre(
      isletme: isletme,
      cari: cari,
      aralik: aralik,
      dokum: BakiyeHesaplayici.ileri(
        islemler: eskidenYeniye(icindekiler),
        devir: devir,
      ),
      hazirlanmaTarihi: hazirlanmaTarihi,
    );
  }
}
