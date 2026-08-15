# Ölçerim — Ürün Yol Haritası

Bu belge, mevcut mimari iskeletten pazarlanabilir **Ölçerim 1.0** sürümüne kadar izlenecek geliştirme sırasını tanımlar.

> Ürün vaadi: **Sınıfını aktar, değerlendirme aracını oluştur, öğrencilerini hızlıca değerlendir ve sonucu hemen raporla. Verilerin cihazından çıkmasın.**

## Mevcut durum

Repo şu anda ürünün mimari başlangıç noktasındadır:

- Flutter + Material 3 iskeleti
- Riverpod altyapısı
- Drift + SQLite veri katmanı
- Students / Rubrics / RubricCriteria / EvaluationEntries ilk şeması
- DAO ve repository başlangıç yapısı
- Excel, PDF ve backup servis sözleşmeleri
- Android / iOS / macOS hedefleri

Bu aşama **çalışan ürün değil, geliştirmeye hazır mimari tabandır**.

---

## Faz 0 — Çalışan teknik temel

### Amaç
İskeleti üç platformda açılan, veri yazıp okuyabilen gerçek uygulama tabanına dönüştürmek.

### İşler
- Android, iOS ve macOS runnerlarını üret.
- Bağımlılıkları kur ve Drift code generation'ı tamamla.
- Database lifecycle ve provider ağacını tamamla.
- Global error handling ve temel logging ekle.
- Placeholder repository/service kodlarını temizle.
- İlk migration test altyapısını kur.

### Çıkış kriteri
- Android, iOS ve macOS'ta uygulama açılır.
- SQLite oluşturulur.
- Veri yazılır, okunur ve uygulama yeniden açıldığında korunur.
- İlk migration testi çalışır.

---

## Faz 1 — Sınıf ve öğrenci yönetimi

### Amaç
Öğretmenin gerçek bir sınıfı uygulamaya eksiksiz taşıyabilmesi.

### Veri modeli
Mevcut `Student.className` yaklaşımı kaldırılarak ilişkisel model kurulmalıdır:

```text
SchoolYear
Classroom
Course
Student
```

### İşler
- Eğitim yılı yönetimi
- Sınıf oluşturma / düzenleme / arşivleme
- Ders ilişkilendirme
- Manuel öğrenci ekleme / düzenleme / arşivleme
- Excel ve CSV içe aktarma
- Import önizleme ve satır doğrulama
- Duplicate / eksik veri yönetimi

### Import akışı

```text
Dosya seç
→ kolonları algıla
→ önizleme
→ hatalı satırları göster
→ kullanıcı onayı
→ tek transaction ile içe aktar
```

### Çıkış kriteri
Gerçek bir öğretmen 30–40 öğrencilik bir sınıfı birkaç dakika içinde oluşturabilmelidir.

---

## Faz 2 — Değerlendirme domain modeli

### Amaç
Ürünü yalnız “rubrik uygulaması” olmaktan çıkarıp genel performans değerlendirme çekirdeğine oturtmak.

### Hedef model

```text
Assessment
AssessmentType
Rubric
RubricCriterion
Evaluation
EvaluationEntry
ObservationNote
```

### Ölçerim 1.0 değerlendirme tipleri
1. Rubrik
2. Hızlı derecelendirme ölçeği

Kontrol listesi, serbest gözlem ve diğer tipler sonraki sürümlere bırakılabilir.

### Çıkış kriteri
Bir değerlendirme, sınıftan ve rubrik şablonundan bağımsız şekilde oluşturulup bir sınıfa uygulanabilmelidir.

---

## Faz 3 — Hızlı değerlendirme ekranı

### Amaç
Öğretmenin ders sırasında mümkün olan en az etkileşimle öğrencileri puanlayabilmesi.

### Tablet / macOS
Tablo ağırlıklı toplu değerlendirme görünümü.

### Telefon
Tek öğrenci odaklı, büyük dokunma hedefleri olan ardışık değerlendirme görünümü.

### İşler
- Otomatik kayıt
- Önceki / sonraki öğrenci
- Tamamlandı / eksik durumu
- Değerlendirilmeyenleri filtreleme
- Not ekleme
- Klavye, dokunmatik ve tablet kullanım optimizasyonu
- Gerekli yerlerde toplu puanlama

### Çıkış kriteri
30 öğrencilik bir sınıf, veri kaybı veya sürekli “Kaydet” gereksinimi olmadan akıcı biçimde değerlendirilebilmelidir.

---

## Faz 4 — Rubrik oluşturucu

### Basit mod
- Kriter adı
- Maksimum puan
- Açıklama
- Sıralama

### Gelişmiş mod
- Performans seviyeleri
- Seviye açıklamaları
- Seviye bazlı puanlar

### İşler
- Rubrik CRUD
- Kriter CRUD
- Rubrik çoğaltma
- Şablon olarak saklama
- Başka sınıf / değerlendirmede yeniden kullanma

### Çıkış kriteri
Öğretmen mevcut bir şablonu kopyalayıp birkaç düzenlemeyle yeni değerlendirme oluşturabilmelidir.

---

## Faz 5 — Sonuç ve temel analiz

### Sınıf görünümü
- Sınıf ortalaması
- Kriter ortalamaları
- Tamamlanan / eksik değerlendirme sayısı
- Öğrenci bazlı toplamlar

### Öğrenci görünümü
- Kriter puanları
- Toplam puan
- Değerlendirme notları

### Sınır
1.0'da ağır istatistik, tahmin veya yapay zekâ analizi yapılmayacaktır.

### Çıkış kriteri
Öğretmen sınıfın ve tek öğrencinin performansını birkaç saniye içinde anlayabilmelidir.

---

## Faz 6 — PDF / Excel / Yazdırma

### Minimum çıktılar
1. Öğrenci değerlendirme formu
2. Sınıf değerlendirme çizelgesi
3. Excel/CSV sonuç tablosu

### İşler
- PDF üretimi
- Excel export
- Print / AirPrint / Android Print
- Sistem Share Sheet
- Dosyalara Kaydet / AirDrop / Drive / Mail gibi hedeflere aktarım

### Çıkış kriteri
Öğretmen değerlendirme sonucunu uygulama dışına standart bir dosya olarak çıkarabilmelidir.

---

## Faz 7 — Şifreli yedekleme ve geri yükleme

### Amaç
Sunucusuz ürünün temel veri kaybı riskini yönetmek.

### Backup kapsamı
- Eğitim yılları
- Sınıflar
- Öğrenciler
- Rubrikler
- Değerlendirmeler
- Uygulama ayarları

### Gereksinimler
- Sürümlü backup formatı
- AEAD tabanlı şifreleme
- Güvenli KDF
- Restore öncesi metadata önizlemesi
- Restore doğrulaması
- Atomik restore

### Kritik invariant
**Restore ya tamamen başarılı olur ya da mevcut veritabanı hiç değişmez.**

### Çıkış kriteri
Backup → temiz veritabanı → restore sonucunda anlamlı kullanıcı verisi birebir geri gelmelidir.

---

## Faz 8 — Ürün UX'i

### İşler
- İlk açılış deneyimi
- Empty state'ler
- Açık eylem butonları
- Kullanıcı dostu hata mesajları
- Undo / arşivleme akışları
- Dark mode
- Font scaling
- Tablet landscape
- VoiceOver / TalkBack temel erişilebilirlik
- Minimum dokunma hedefleri

### Çıkış kriteri
Yeni kullanıcı teknik açıklamaya ihtiyaç duymadan ilk sınıfını oluşturabilmelidir.

---

## Faz 9 — Güvenilirlik ve test kapıları

### Domain testleri
- Puan hesaplama
- Maksimum skor kuralları
- Değerlendirme durumları

### Database testleri
- CRUD
- Foreign key
- Transaction
- Migration

### Import testleri
- Boş dosya
- Bozuk dosya
- Duplicate öğrenci
- Türkçe karakterler
- Büyük sınıf / büyük dosya

### Backup testleri

```text
DB A
→ backup
→ temiz DB
→ restore
→ DB B

A == B
```

### UI testleri
- Telefon
- Tablet
- macOS
- Kritik değerlendirme akışları

### Çıkış kriteri
Veri kaybı yaratabilecek hiçbir kritik akış testsiz kalmaz.

---

## Faz 10 — Gerçek öğretmen beta testi

### Zorunlu görev senaryoları
1. Sınıf oluştur.
2. Excel'den öğrenci aktar.
3. Rubrik oluştur.
4. Öğrencileri değerlendir.
5. Bir puanı değiştir.
6. PDF / Excel çıkar.
7. Uygulamayı kapat ve tekrar aç.
8. Yedek al.
9. Yedeği geri yükle.

### İzlenecek UX sinyalleri
- Kullanıcının durup düşündüğü yerler
- Gereksiz tıklamalar
- Yanlış anlaşılabilen kavramlar
- Değerlendirme sırasında tempo kaybı

### Çıkış kriteri
Gerçek öğretmenler ana akışı yardım almadan tamamlayabilmelidir.

---

## Faz 11 — Store ve dağıtım hazırlığı

### Apple
- Bundle ID
- Signing
- App icon
- Launch screen
- Privacy manifest
- TestFlight
- macOS signing / notarization / sandbox izinleri

### Android
- Application ID
- Signing key
- AAB
- Play Console
- Data Safety
- Internal / closed testing

### Çıkış kriteri
Store review'a gönderilebilir release candidate oluşur.

---

## Faz 12 — Ticari ürün katmanı

1.0 için tercih edilen model: **local-first premium uygulama**.

Olası paketleme:

### Ücretsiz
- Sınırlı sınıf / rubrik
- Temel değerlendirme

### Pro
- Sınırsız sınıf ve öğrenci
- Tüm rubrik özellikleri
- PDF / Excel
- Backup / restore
- Gelişmiş temel raporlar

Fiyatlandırma ve satın alma mekanizması, ürünün ana iş akışı beta testinde doğrulandıktan sonra uygulanmalıdır.

---

## Faz 13 — Lansman paketi

- Uygulama ikonu
- Görsel kimlik
- Store ekran görüntüleri
- Store açıklamaları
- Gizlilik politikası
- Destek kanalı
- Kullanım rehberi
- Sürüm notları
- Demo sınıfı
- Hazır rubrik şablonları

Önerilen ilk şablonlar:
- Sözlü Sunum
- Konuşma Becerisi
- Proje Değerlendirme
- Grup Çalışması
- Okuma Becerisi
- Yazma Becerisi

---

# Geliştirme sırası

```text
0. Platform + DB temelini doğrula
↓
1. Classroom + Student
↓
2. Excel / CSV import
↓
3. Assessment domain modeli
↓
4. Rubric editor
↓
5. Hızlı değerlendirme ekranı
↓
6. Sonuç ekranları
↓
7. PDF / Excel / Print
↓
8. Backup / Restore
↓
9. UX polish
↓
10. Migration + regression testleri
↓
11. Gerçek öğretmen beta
↓
12. Store hazırlığı
↓
13. Ölçerim 1.0
```

## Yol haritası kuralı

Bir fazın veri modeli veya temel invariant'ı tamamlanmadan sonraki fazın görsel özelliklerine geçilmemelidir. Özellikle migration, backup ve değerlendirme veri bütünlüğü “sonra bakılacak teknik borç” olarak ertelenemez.

Kapsam sınırları için bkz. [`PRODUCT_SCOPE.md`](PRODUCT_SCOPE.md).
