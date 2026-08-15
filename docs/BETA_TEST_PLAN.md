# Ölçerim 1.0 — Gerçek Öğretmen Beta Testi

Bu belge Faz 10'un dış kullanıcı doğrulama protokolüdür. Bu repodaki demo ve fixture verileri **sentetiktir**. Gerçek beta sonucu ancak gerçek öğretmenlerin uygulamayı bağımsız kullanmasıyla doldurulur; geliştirme sırasında uydurma başarı kaydı yazılmaz.

## Amaç

Öğretmenin ana ürün zincirini teknik yardım almadan tamamlayabildiğini ve değerlendirme sırasında uygulamanın tempo kaybettirmediğini doğrulamak.

## Katılımcı önerisi

- En az 5 öğretmen.
- Mümkünse en az 2 farklı branş.
- En az bir telefon, bir tablet ve bir Mac kullanım oturumu.
- Katılımcıların gerçek öğrenci verisi kullanması zorunlu değildir; `test/fixtures/beta_students.csv` veya uygulamadaki sentetik demo kullanılabilir.

## Zorunlu görevler

1. İlk sınıfı oluştur.
2. 30 öğrencilik CSV'yi içe aktar.
3. 5 kriterli bir rubrik oluştur.
4. Yeni değerlendirme oluştur.
5. En az 10 öğrenciyi puanla.
6. Önceki bir öğrencinin puanını değiştir.
7. Sınıf sonucunu aç ve kriter ortalamalarını bul.
8. Sınıf PDF'ini önizle ve paylaşım ekranını aç.
9. Excel sonucunu dışa aktar.
10. Uygulamayı kapatıp yeniden aç; verinin durduğunu kontrol et.
11. Şifreli yedek oluştur.
12. Yedeği geri yükleme önizlemesine kadar aç; metadata'yı doğrula.
13. Ayrı test cihazında/temiz test kurulumunda restore'u tamamla.

## Her görev için kayıt

| Alan | Kayıt |
|---|---|
| Başladı | saat |
| Bitti | saat |
| Yardım aldı mı? | Evet/Hayır |
| Yanlış ekrana girdi mi? | Evet/Hayır |
| Geri döndü mü? | kaç kez |
| Durup düşündüğü yer | serbest not |
| Beklemediği sonuç | serbest not |
| Gereksiz bulduğu tıklama | serbest not |

## Kritik UX sinyalleri

- `Kaydet` araması veya verinin kaydolduğuna dair güvensizlik.
- Değerlendirilmeyen öğrenciye ulaşmakta zorluk.
- Telefon ekranında kriter/sonraki öğrenci akışının yavaşlaması.
- Tablet/Mac gradebook'ta hangi hücrenin hangi öğrenciye ait olduğunun kaybedilmesi.
- Excel kolon eşleştirmede tereddüt.
- PDF/Excel'in cihazdan nasıl çıkarılacağının anlaşılamaması.
- Backup dosyasının nereye gittiğinin belirsiz kalması.
- Restore'un mevcut veriyi değiştireceğinin fark edilmemesi.

## Faz 10 geçiş kriteri

Faz 10 yalnız şu dış kanıtla gerçek anlamda PASS sayılır:

- Katılımcıların tamamı ana zinciri geliştirici müdahalesi olmadan tamamlar.
- Kritik veri kaybı / yanlış öğrenciye puan / yanlış sınıfa import olayı yoktur.
- Puanlama sırasında kullanıcı manuel kaydetme ihtiyacı hissetmez.
- En az %80 katılımcı ilk denemede PDF/Excel paylaşımına ulaşır.
- Backup ve restore uyarıları bütün katılımcılar tarafından doğru yorumlanır.

Bir kritik veri problemi görülürse yeni özellik geliştirmek yerine sorun çözülür ve beta senaryosu tekrarlanır.
