import '../ortak/harita.dart';

/// İlk `Fidan` şemasındaki yaş ve kök tipi alanlarını tek metne toplar:
/// `2 yaş tüplü`.
///
/// Katalog iki kez şema değiştirdi ve üçü de göç scripti olmadan okunuyor:
///
/// | Şema | Alanlar | Tanınma işareti |
/// |---|---|---|
/// | İlk | tür, çeşit, anaç, yaş, kök tipi | `tur` var, `ad` yok |
/// | Ara | tek serbest `ad` | `tur` yok |
/// | Bugün | tür, çeşit, anaç (+ türetilmiş `ad`) | ikisi de var |
///
/// Yaş ve kök tipinin bugünkü şemada karşılığı yok. Bilgiyi kaybetmemek için
/// ilk şemadan okunan anacın ardına ekleniyor: `M9 2 yaş tüplü`. Kullanıcı
/// kaydı ilk düzenlediğinde istemediği kısmı siler ve kayıt `ad` alanını
/// kazandığı için ek bir daha uygulanmaz (bkz. `Urun.fromMap`).
String eskiFidanEki(Map<String, Object?> veri) {
  final yas = haritaTamSayiOpsiyonel(veri, _alanYas);

  final bolumler = <String>[
    if (yas != null) '$yas yaş',
    _kokTipiAdi(haritaMetinOpsiyonel(veri, _alanKokTipi)) ?? '',
  ].where((bolum) => bolum.isNotEmpty);

  return bolumler.join(' ');
}

const String _alanYas = 'yas';
const String _alanKokTipi = 'kokTipi';

/// Eski `KokTipi` enum'ının Firestore anahtarları ve görünen karşılıkları.
/// Enum kaldırıldı; okuma için bu iki değer yetiyor.
String? _kokTipiAdi(String? anahtar) => switch (anahtar) {
  'tuplu' => 'tüplü',
  'ciplakKok' => 'çıplak kök',
  _ => null,
};
