# Ölçerim — Ürün Kapsamı ve Sınırlar

Bu belge, **Ölçerim 1.0** için ürün kapsamını sabitler. Amaç, geliştirme sırasında ürünün gereksiz yere büyümesini, temel iş akışının ertelenmesini ve teknik borcun “özellik” uğruna kabul edilmesini önlemektir.

## 1. Ürün tanımı

Ölçerim, öğretmenlerin öğrencilerin performanslarını cihaz üzerinde, hızlı ve yapılandırılmış biçimde değerlendirmesi için tasarlanan **local-first** bir uygulamadır.

Hedef platformlar:
- Android
- iOS / iPadOS
- macOS

Temel kullanıcı: **öğretmen**.

Temel ürün vaadi:

> **Sınıfını aktar, değerlendirme aracını oluştur, öğrencilerini hızlıca değerlendir ve sonucu hemen raporla. Verilerin cihazından çıkmasın.**

---

## 2. Ölçerim 1.0 — Kapsam içinde

### Sınıf ve öğrenci yönetimi
- Eğitim yılı
- Sınıf
- Ders
- Öğrenci
- Manuel öğrenci ekleme / düzenleme
- Excel / CSV öğrenci içe aktarma
- Import önizleme ve doğrulama
- Arşivleme

### Değerlendirme
- Değerlendirme oluşturma
- Rubrik tabanlı değerlendirme
- Hızlı derecelendirme ölçeği
- Kriter bazlı puanlama
- Öğrenci bazlı not
- Otomatik kayıt
- Tamamlandı / eksik durumu
- Değerlendirilmeyen öğrenci filtresi

### Rubrik yönetimi
- Rubrik oluşturma
- Kriter oluşturma
- Maksimum puan
- Kriter açıklaması
- Rubrik düzenleme
- Rubrik çoğaltma
- Rubriği şablon olarak yeniden kullanma
- Gelişmiş performans seviyeleri

### Sonuçlar
- Öğrenci toplam puanı
- Sınıf ortalaması
- Kriter ortalamaları
- Eksik / tamamlanan değerlendirmeler
- Öğrenci bazlı sonuç görünümü

### Raporlama ve dışa aktarma
- Öğrenci değerlendirme PDF'i
- Sınıf değerlendirme çizelgesi PDF'i
- Excel / CSV export
- Yazdırma
- Sistem Share Sheet

### Veri güvenliği
- Drift / SQLite
- İlişkisel veri modeli
- Foreign key'ler
- Transaction kullanımı
- Test edilmiş schema migration'ları
- Şifreli manuel tam yedekleme
- Yedek geri yükleme
- Atomik restore

### Kullanılabilirlik
- Telefon arayüzü
- Tablet arayüzü
- macOS arayüzü
- Dark mode
- Font scaling
- Temel VoiceOver / TalkBack uyumu
- Kullanıcı dostu hata mesajları
- Empty state'ler

---

## 3. Ölçerim 1.0 — Kesin olarak kapsam dışında

Aşağıdaki özellikler 1.0'ın parçası değildir ve ana ürün akışı tamamlanmadan geliştirilmemelidir.

### Yapay zekâ
- AI ile otomatik puanlama
- LLM entegrasyonu
- AI rubrik üretimi
- AI öğrenci analizi
- AI geri bildirim üretimi

### OCR ve belge okuma
- Sınav kâğıdı OCR
- El yazısı tanıma
- Fotoğraftan otomatik değerlendirme
- PDF sınav okuma

### Bulut
- Otomatik cloud sync
- Çoklu cihaz gerçek zamanlı senkronizasyon
- Merkezi sunucu
- Kullanıcı hesabı zorunluluğu
- Web backend

### Kurumsal sistemler
- Okul yönetim paneli
- Yönetici hesabı
- Veli hesabı
- Öğrenci hesabı
- LMS entegrasyonu
- e-Okul API entegrasyonu
- Kurumsal SSO

### Web ürünü
- Web uygulaması
- Tarayıcı tabanlı admin paneli

### Sosyal / iletişim özellikleri
- Mesajlaşma
- Bildirim ağı
- Veliye otomatik mesaj gönderme
- Öğrenciyle canlı paylaşım

### Gelişmiş analitik
- Tahminleme
- Öğrenci başarı tahmini
- AI destekli öneri sistemi
- Çok dönemli gelişmiş BI dashboard'u

Bu maddeler gelecekte değerlendirilebilir; bu belge onları ürün taahhüdü haline getirmez.

---

## 4. Mimari olarak değiştirilemez ilkeler

### Local-first
Uygulamanın temel işlevleri internet bağlantısı olmadan çalışmalıdır.

### SQLite ana veri kaynağıdır
İlişkisel kullanıcı verisi:
- `SharedPreferences`
- key-value store
- tek parça JSON dosyası

içinde tutulamaz.

### Feature-first yapı korunur
Yeni özellikler mevcut katmanları bypass ederek doğrudan UI → SQLite erişimi kuramaz.

Beklenen akış:

```text
Presentation
→ Controller / Provider
→ Repository
→ DAO / Service
→ SQLite / File system
```

### Tek bir canonical write path
Aynı domain verisinin farklı ekranlarda birbirinden bağımsız yazma yolları bulunmamalıdır. Veri invariant'larını bypass eden alternatif kayıt yolları teknik borç kabul edilir.

### Migration zorunludur
Production verisini korumak için:
- Her şema değişikliğinde `schemaVersion` artırılır.
- İleri yönlü migration yazılır.
- Migration testi eklenir.
- “DB'yi sil ve yeniden oluştur” production çözümü değildir.

---

## 5. Veri güvenliği sınırları

### Gerçek öğrenci verisi repoya giremez
Aşağıdakiler commit edilmez:
- Öğrenci adları
- Okul numaraları
- Değerlendirme notları
- Gerçek sınıf listeleri
- SQLite dosyaları
- Backup dosyaları
- Export dosyaları

Testlerde yalnız sentetik / anonim fixture kullanılmalıdır.

### Yedek düz metin olamaz
Backup formatı:
- sürümlü,
- şifreli,
- bütünlüğü doğrulanabilir

olmalıdır.

### Restore atomik olmak zorundadır
Restore sırasında yarım veri yazımı kabul edilmez.

### Dosyalar kullanıcıya teslim edilebilir olmalıdır
PDF, Excel ve yedekler yalnız uygulama sandbox'ında bırakılmaz; platformun sistem paylaşım / kaydetme mekanizmaları kullanılmalıdır.

---

## 6. UX sınırları

Ürünün başarısı özellik sayısıyla değil, değerlendirme sırasında öğretmenin hız kaybetmemesiyle ölçülür.

Bu nedenle:
- Sık kullanılan puanlama işlemlerinde gereksiz modal kullanılmaz.
- Her öğrenci sonrası manuel “Kaydet” zorunluluğu oluşturulmaz.
- Telefon ve tablet aynı ekranı zorla paylaşmak zorunda değildir.
- Hata mesajlarında teknik exception metni kullanıcıya gösterilmez.
- Destructive işlemlerde mümkün olduğunda arşivleme / undo tercih edilir.
- Öğretmenin değerlendirme sırasında bir öğrenciden diğerine geçişi hızlı olmalıdır.

---

## 7. Performans sınırları

- Excel parse gibi ağır işler UI isolate'ını bloke etmemelidir.
- Toplu SQLite yazımları transaction / batch ile yapılmalıdır.
- Liste ve değerlendirme ekranları gereksiz full rebuild üretmemelidir.
- Normal okul kullanımındaki sınıf büyüklükleri uygulamada hissedilir gecikme yaratmamalıdır.

Performans problemi görülmeden karmaşık premature optimization yapılmamalıdır; ancak bilinen pahalı işlemler ana UI thread'e taşınamaz.

---

## 8. Test ve kalite kapıları

Aşağıdaki alanlarda veri davranışı testsiz production'a alınamaz:

### Zorunlu
- Schema migration
- Backup / restore
- Import doğrulama
- Puan hesaplama
- Foreign key / ilişkisel bütünlük
- Transaction gerektiren çoklu yazma işlemleri

### Release öncesi kritik kullanıcı akışı

```text
Sınıf oluştur
→ öğrenci aktar
→ rubrik oluştur
→ değerlendirme yap
→ sonucu görüntüle
→ PDF/Excel çıkar
→ uygulamayı kapat/aç
→ yedek al
→ restore et
```

Bu zincir başarısızsa sürüm pazarlanabilir kabul edilmez.

---

## 9. Teknik borç politikası

Aşağıdakiler “sonra düzeltiriz” kategorisine bırakılamaz:
- Veri kaybı riski
- Migration eksikliği
- Restore bütünlüğü
- Domain invariant bypass'ı
- Aynı veriyi farklı şekilde yazan birden fazla yol
- Kullanıcı verisinin yanlış sınıf / öğrenci / değerlendirmeye bağlanması
- Secret veya gerçek öğrenci verisinin repoya girmesi

Düşük etkili görsel polish veya kod tekrarları ayrı backlog'a bırakılabilir; veri doğruluğu bırakılamaz.

---

## 10. Kapsam değişikliği kuralı

Yeni bir özellik önerildiğinde önce şu sorular cevaplanmalıdır:

1. Ölçerim'in temel ürün vaadini doğrudan güçlendiriyor mu?
2. Mevcut 1.0 ana akışının tamamlanmasını geciktiriyor mu?
3. Yeni backend, hesap sistemi veya platform bağımlılığı getiriyor mu?
4. Veri modelini veya migration riskini büyütüyor mu?
5. Gerçek öğretmen beta testinde gözlenen bir probleme cevap veriyor mu?

Özellik temel akışı geciktiriyorsa varsayılan karar **1.x / 2.0 backlog'una ertelemek** olmalıdır.

---

## 11. Ölçerim 1.0 Definition of Done

Ölçerim 1.0 ancak aşağıdakilerin tamamı sağlandığında “pazarlanabilir ürün” kabul edilir:

- Android, iOS/iPadOS ve macOS release build'leri çalışır.
- Öğretmen gerçek sınıfını Excel/CSV veya manuel girişle oluşturabilir.
- Rubrik veya hızlı ölçek oluşturabilir.
- Sınıfı hızlı biçimde değerlendirebilir.
- Veri uygulama yeniden açıldığında korunur.
- Sonuçları görüntüleyebilir.
- PDF ve Excel/CSV çıkarabilir.
- Yazdırabilir / paylaşabilir.
- Şifreli yedek alabilir.
- Yedeği güvenli ve atomik biçimde geri yükleyebilir.
- Migration testleri geçer.
- Kritik domain ve backup testleri geçer.
- Gerçek öğretmen beta kullanıcıları ana akışı yardım almadan tamamlayabilir.
- Gizlilik politikası ve store metadata hazırdır.
- Kritik P0/P1 veri kaybı veya doğruluk hatası yoktur.

---

## 12. 1.0 sonrası adaylar — taahhüt değildir

Ana ürün başarıyla doğrulandıktan sonra değerlendirilebilecek başlıklar:
- Daha fazla değerlendirme tipi
- Hazır rubrik kütüphanesi
- Gelişmiş dönem karşılaştırmaları
- Opsiyonel cihazlar arası senkronizasyon
- Opsiyonel Ölçerim Cloud
- AI destekli yardımcı özellikler
- OCR tabanlı iş akışları

Bu başlıklar mevcut 1.0 kapsamını değiştirmez.

Yol haritası için bkz. [`ROADMAP.md`](ROADMAP.md).
