import '../ortak/harita.dart';

/// Eski `Fidan` şemasıyla yazılmış bir belgeden görünen adı üretir.
///
/// Katalog önceden beş alan tutuyordu — tür, çeşit, anaç, yaş, kök tipi — ve
/// görünen adı `Elma / Scarlet / M9 · 2 Yaş · Tüplü` biçiminde birleştiriyordu.
/// Yeni şemada tek bir serbest [Urun.ad] var. Bu fonksiyon eski belgeleri
/// okunur tutar: göç scripti çalıştırmadan katalog kaybolmaz, kullanıcı kaydı
/// ilk düzenlediğinde ad yeni alana yazılır.
///
/// Ayraçlar sadeleşti: eski ad `/` ve `·` ile bölünüyordu, üretilen ad boşlukla
/// birleşir — artık tek bir metin alanına düşecek ve kullanıcı orada düzeltecek.
String eskiFidanAdi(Map<String, Object?> veri) {
  final yas = haritaTamSayiOpsiyonel(veri, _alanYas);

  final bolumler = <String>[
    haritaMetin(veri, _alanTur),
    haritaMetin(veri, _alanCesit),
    haritaMetinOpsiyonel(veri, _alanAnac) ?? '',
    if (yas != null) '$yas yaş',
    _kokTipiAdi(haritaMetinOpsiyonel(veri, _alanKokTipi)) ?? '',
  ].map((bolum) => bolum.trim()).where((bolum) => bolum.isNotEmpty);

  return bolumler.join(' ');
}

const String _alanTur = 'tur';
const String _alanCesit = 'cesit';
const String _alanAnac = 'anac';
const String _alanYas = 'yas';
const String _alanKokTipi = 'kokTipi';

/// Eski `KokTipi` enum'ının Firestore anahtarları ve görünen karşılıkları.
/// Enum kaldırıldı; okuma için bu iki değer yetiyor.
String? _kokTipiAdi(String? anahtar) => switch (anahtar) {
  'tuplu' => 'tüplü',
  'ciplakKok' => 'çıplak kök',
  _ => null,
};
