/// Tür, çeşit ve anaçtan faturaya yazılan tek satırlık adı üretir.
///
/// `Elma Scarlet M9`, `Elma Scarlet`, `nakliye` — boş bırakılan parça atlanır.
/// Fidan kimliği üç alandan oluşur ama üçü de zorunlu değildir: "nakliye" gibi
/// kalemlerde yalnızca [tur] doludur (bkz. `fazlar/faz-3-katalog.md`).
///
/// Ayraç boşluktur, `/` değil: bu metin müşteriye giden faturaya ve PDF ekstreye
/// olduğu gibi basılıyor; orada ürün adı gibi okunmalı, form dökümü gibi değil.
///
/// Hem [Urun] hem [IslemKalemi] adını buradan üretir — ikisi de aynı üç parçayı
/// taşıyor ve katalogdan seçilen kalem, seçildiği ürünle **aynı** adı vermeli.
String urunAdi({required String tur, String cesit = '', String anac = ''}) =>
    <String>[
      tur,
      cesit,
      anac,
    ].map((parca) => parca.trim()).where((parca) => parca.isNotEmpty).join(' ');
