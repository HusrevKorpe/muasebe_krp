/// Gün sınırı hesapları.
///
/// Tarih aralığı süzgeçlerinin tek doğru yeri burasıdır. İşlem tarihleri
/// kullanıcının seçtiği güne ait olsa da saat bilgisi taşıyabilir (takvimden
/// gelen tarih gece yarısıdır, ama ileride farklı bir yoldan girilen kayıt
/// öğlen olabilir). Sınırı gün başına/sonuna genişletmeden karşılaştırırsak
/// aynı güne düşen işlemler ekstreden sessizce düşer.
library;

/// Günün ilk anı: `17.09.2021 00:00:00.000`
DateTime gunBasi(DateTime tarih) =>
    DateTime(tarih.year, tarih.month, tarih.day);

/// Günün son anı: `17.09.2021 23:59:59.999`
///
/// Bir sonraki günün başını alıp bir milisaniye geri gitmek, ay ve yıl
/// sonlarında da doğru çalışır — `DateTime` taşmayı kendisi çevirir.
DateTime gunSonu(DateTime tarih) => DateTime(
  tarih.year,
  tarih.month,
  tarih.day + 1,
).subtract(const Duration(milliseconds: 1));

