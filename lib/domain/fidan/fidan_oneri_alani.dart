/// Formda geçmiş girişlerin önerildiği alanlar.
///
/// Tür ve anaç serbest metindir — ayrı bir "türler" koleksiyonu açılmaz. Öneri
/// listesi mevcut fidanlardan türetilir; kullanıcı tek kişi olduğu için ikinci
/// bir koleksiyonu güncel tutmanın maliyeti kazancından büyük
/// (bkz. `fazlar/faz-3-katalog.md`).
///
/// Çeşit bilerek dışarıda: aynı çeşit adı farklı türlerde tekrarlanmaz ve
/// kullanıcıya "Elma" içinde geçen bir çeşidi "Zeytin" girerken önermek
/// yanıltıcı olurdu.
enum FidanOneriAlani { tur, anac }
