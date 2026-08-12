/// Türkçe tarih biçimleri.
///
/// Ay adları elle tanımlıdır; `intl` paketinin tarih biçimlemesi çalışma anında
/// yerel veri yüklenmesini (`initializeDateFormatting`) gerektirir ve bu adım
/// atlanırsa testlerde ve sürüm derlemesinde sessizce farklı davranır.
library;

const List<String> _aylar = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const List<String> _gunler = <String>[
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Uzun biçim: `17 Eylül 2021`
String uzunTarih(DateTime tarih) =>
    '${tarih.day} ${_aylar[tarih.month - 1]} ${tarih.year}';

/// Ekstre tablosunun tarih biçimi: `05 Aralık 2024`
///
/// [uzunTarih]'ten tek farkı günün iki haneye tamamlanmasıdır. Tabloda tarihler
/// alt alta dizildiği için tek haneli gün kolonu tırtıklı gösteriyor; referans
/// ekstre de bu kolonda günü sıfırla dolduruyor. Cümle içinde ise `5 Aralık`
/// doğru yazımdır — bu yüzden iki ayrı biçim var.
String tabloTarihi(DateTime tarih) =>
    '${_ikiHane(tarih.day)} ${_aylar[tarih.month - 1]} ${tarih.year}';

/// Dar alanlarda kullanılan kısa biçim: `17.09.2021`
String kisaTarih(DateTime tarih) =>
    '${_ikiHane(tarih.day)}.${_ikiHane(tarih.month)}.${tarih.year}';

/// Gün adıyla birlikte: `Cuma, 17 Eylül 2021`
String gunAdiylaTarih(DateTime tarih) =>
    '${_gunler[tarih.weekday - 1]}, ${uzunTarih(tarih)}';

/// Ekstre alt bilgisi: `17.09.2021 tarihinde hazırlanmıştır.`
String hazirlanmaNotu(DateTime tarih) =>
    '${kisaTarih(tarih)} tarihinde hazırlanmıştır.';

/// İki tarihi `17 Eylül 2021 — 24 Mayıs 2025` biçiminde birleştirir.
String tarihAraligi(DateTime baslangic, DateTime bitis) =>
    '${uzunTarih(baslangic)} — ${uzunTarih(bitis)}';

String _ikiHane(int deger) => deger.toString().padLeft(2, '0');
