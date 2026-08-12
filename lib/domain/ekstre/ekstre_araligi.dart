import '../../core/tarih/gun_siniri.dart';

/// Ekstrenin hangi tarih aralığını kapsadığı.
///
/// Sınırlar **gün bazlıdır**: [baslangic] o günün 00:00'ı, [bitis] o günün
/// 23:59:59.999'u olarak saklanır. Kullanıcı takvimden 24 Mayıs'ı seçtiğinde
/// o gün girilen işlem ekstreye girmeli; sınır gün başına yuvarlanırsa aynı
/// güne düşen işlemler sessizce dışarıda kalırdı.
///
/// [baslangic] boşsa "en baştan", [bitis] boşsa "bugüne kadar" demektir;
/// ikisi de boşsa aralık [EkstreAraligi.tumu]'dür.
class EkstreAraligi {
  const EkstreAraligi._({required this.tip, this.baslangic, this.bitis});

  /// Carinin bütün geçmişi. Açılış bakiyesi sıfırdır.
  const EkstreAraligi.tumu() : this._(tip: EkstreAralikTipi.tumu);

  /// İçinde bulunulan ayın ilk gününden [bugun]'e kadar.
  factory EkstreAraligi.buAy(DateTime bugun) => EkstreAraligi._(
    tip: EkstreAralikTipi.buAy,
    baslangic: DateTime(bugun.year, bugun.month),
    bitis: gunSonu(bugun),
  );

  /// İçinde bulunulan yılın ilk gününden [bugun]'e kadar.
  factory EkstreAraligi.buYil(DateTime bugun) => EkstreAraligi._(
    tip: EkstreAralikTipi.buYil,
    baslangic: DateTime(bugun.year),
    bitis: gunSonu(bugun),
  );

  /// Kullanıcının takvimden seçtiği aralık.
  ///
  /// Sınırlar ters verilirse yer değiştirilir: kullanıcı bitiş tarihini
  /// başlangıçtan önce seçtiğinde boş ekstre üretmek yerine aralığı düzeltmek
  /// daha doğru.
  factory EkstreAraligi.ozel({
    required DateTime baslangic,
    required DateTime bitis,
  }) {
    final tersMi = bitis.isBefore(baslangic);
    return EkstreAraligi._(
      tip: EkstreAralikTipi.ozel,
      baslangic: gunBasi(tersMi ? bitis : baslangic),
      bitis: gunSonu(tersMi ? baslangic : bitis),
    );
  }

  final EkstreAralikTipi tip;

  /// Aralığın ilk anı. `null` ise sınır yok.
  final DateTime? baslangic;

  /// Aralığın son anı (günün 23:59:59.999'u). `null` ise sınır yok.
  final DateTime? bitis;

  bool get tumuMu => tip == EkstreAralikTipi.tumu;

  /// İşlem bu aralığın içinde mi?
  bool icerirMi(DateTime tarih) => !oncesindeMi(tarih) && !sonrasindaMi(tarih);

  /// İşlem aralık başlamadan önce mi? Açılış bakiyesi bu işlemlerden toplanır.
  bool oncesindeMi(DateTime tarih) =>
      baslangic != null && tarih.isBefore(baslangic!);

  bool sonrasindaMi(DateTime tarih) => bitis != null && tarih.isAfter(bitis!);

  @override
  bool operator ==(Object other) =>
      other is EkstreAraligi &&
      other.tip == tip &&
      other.baslangic == baslangic &&
      other.bitis == bitis;

  @override
  int get hashCode => Object.hash(tip, baslangic, bitis);

  @override
  String toString() => 'EkstreAraligi(${tip.name}, $baslangic → $bitis)';
}

/// Ekstre ekranındaki hazır aralık seçenekleri.
enum EkstreAralikTipi { buAy, buYil, tumu, ozel }
