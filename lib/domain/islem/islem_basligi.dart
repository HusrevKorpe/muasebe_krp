import 'islem_kalemi.dart';

/// Kullanıcı açıklama yazmadıysa başlığı kalem adlarından üretir.
///
/// Açıklama zorunlu bir alan değil: "sattım" deyip iki satır girmek yeten bir
/// akış olmalı. Ama hesap dökümünde her satırın bir açıklaması olmalı, yoksa
/// müşteri neye para verdiğini okuyamaz — bu yüzden boş başlık kalemlerden
/// türetilir: `zeytin, Hurma, nakliye`.
///
/// Uzun listelerde ilk [_enCokKalem] ad yazılır, kalanı sayıyla özetlenir:
/// `elma, armut, kiraz +3`. Tam liste zaten kalem satırlarında görünüyor.
abstract final class IslemBasligi {
  /// Başlıkta adı yazılan en fazla kalem sayısı.
  static const int _enCokKalem = 3;

  static const String _ayrac = ', ';

  /// [yazilan] doluysa olduğu gibi döner; boşsa [kalemler]'den üretir.
  static String uret({
    required String yazilan,
    required List<IslemKalemi> kalemler,
  }) {
    final temiz = yazilan.trim();
    if (temiz.isNotEmpty) return temiz;

    final adlar = kalemler
        .map((kalem) => kalem.ad.trim())
        .where((ad) => ad.isNotEmpty)
        .toList(growable: false);
    if (adlar.isEmpty) return '';

    if (adlar.length <= _enCokKalem) return adlar.join(_ayrac);

    final gosterilen = adlar.take(_enCokKalem).join(_ayrac);
    return '$gosterilen +${adlar.length - _enCokKalem}';
  }

  /// [baslik], [kalemler]'den türetilmiş olabilir mi?
  ///
  /// Düzenleme formu açıklama kutusunu buna bakarak dolduruyor: kullanıcı
  /// açıklamayı hiç yazmadıysa kutu boş açılmalı ki bir satırı değiştirdiğinde
  /// açıklama da kendiliğinden yenilensin. Kutuya `Elma Scarlet M9` yazılsaydı,
  /// satır armuda çevrildiğinde ekstrede hâlâ elma yazardı.
  ///
  /// Kullanıcının elle yazdığı açıklama kalemlerin türetilmişine birebir eşitse
  /// yazılmamış sayılır. Sonucu aynı olduğu için bu, kaydı bozmaz.
  static bool turetilmisMi({
    required String baslik,
    required List<IslemKalemi> kalemler,
  }) => baslik.trim() == uret(yazilan: '', kalemler: kalemler);
}
