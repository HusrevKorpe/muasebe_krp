import 'islem.dart';

/// İşlem sıralamasının tek tanımı: **işlem tarihi, sonra belge kimliği.**
///
/// Yürüyen bakiye sıraya bağlıdır; sorgu ile ekranın sırası birbirinden ayrılırsa
/// bakiye kolonu kayar. Bu yüzden Firestore sorgusu da (`islemTarihi`, `__name__`)
/// ile sıralar ve bu karşılaştırıcı onunla birebir aynı sonucu verir.
///
/// **`olusturmaTarihi` neden ölçüt değil:** o alan `serverTimestamp()` ile
/// yazılır ve sunucu onaylayana kadar `null` okunur. Çevrimdışı girilen bir
/// işlem, sıralama ona bakarsa listede yanlış yere düşerdi (bkz. KURALLAR.md
/// §4.4). Aynı güne düşen işlemlerin kendi arasındaki sırası belge kimliğinden
/// gelir; kimlikler `data/islem/islem_kimligi.dart` içinde zaman sıralı üretilir,
/// böylece aynı günün işlemleri giriş sırasında kalır.
int islemKarsilastir(Islem a, Islem b) {
  final tarih = a.islemTarihi.compareTo(b.islemTarihi);
  return tarih != 0 ? tarih : a.id.compareTo(b.id);
}

/// Listeyi eskiden yeniye sıralanmış bir kopya olarak döner.
List<Islem> eskidenYeniye(Iterable<Islem> islemler) =>
    islemler.toList()..sort(islemKarsilastir);

/// Listeyi yeniden eskiye sıralanmış bir kopya olarak döner.
List<Islem> yenidenEskiye(Iterable<Islem> islemler) =>
    islemler.toList()..sort((a, b) => islemKarsilastir(b, a));
