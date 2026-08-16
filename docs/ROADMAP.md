# Ölçerim — Ürün Yol Haritası

Bu belge, **Ölçerim 1.0** için güncel ürün durumunu, kalan işleri ve faz çıkış kriterlerini tanımlar.

> Ürün vaadi: **Sınıfını aktar, değerlendirme aracını oluştur, öğrencilerini hızlıca değerlendir ve sonucu hemen raporla. Verilerin cihazından çıkmasın.**

## Durum özeti

Güncel `main`, artık mimari iskelet değil çalışan bir local-first üründür. Uygulama Android, iOS/iPadOS ve macOS hedeflerini; ilişkisel Drift/SQLite veri modelini; Excel/CSV importunu; rubrik ve hızlı ölçek değerlendirmelerini; telefon ve geniş ekran puanlama akışlarını; sonuç ekranlarını; PDF/XLSX/CSV exportunu; yazdırma/paylaşmayı; şifreli backup/restore'u; onboarding'i; tema ayarlarını; demo verisini ve hazır rubrik şablonlarını içerir.

Veritabanı şeması **v6**'dır. Release kalite kapısı GitHub Actions üzerinde `build_runner`, `flutter analyze`, `flutter test`, Android APK/AAB, unsigned iOS release ve macOS release buildlerini çalıştırır. Aynı kapı artık `main` pushlarının yanında `main` hedefli pull requestlerde de çalışır.

### Faz durumları

| Faz | Durum | Kalan ana iş |
|---|---|---|
| 0 — Teknik temel | **DONE** | — |
| 1 — Sınıf/öğrenci | **PARTIAL** | eğitim yılı edit/archive polish |
| 2 — Assessment domain | **DONE** | — |
| 3 — Hızlı değerlendirme | **PARTIAL** | klavye navigasyonu/shortcut; isteğe bağlı toplu puanlama |
| 4 — Rubrik oluşturucu | **DONE** | — |
| 5 — Sonuç/analiz | **DONE** | — |
| 6 — PDF/Excel/Print | **DONE** | export regression coverage sürekli korunmalı |
| 7 — Backup/Restore | **DONE** | — |
| 8 — Ürün UX | **PARTIAL** | erişilebilirlik/font-scaling cihaz doğrulaması |
| 9 — Güvenilirlik | **PARTIAL** | platform UI/widget coverage genişletilmeli |
| 10 — Gerçek öğretmen beta | **BLOCKED/EXTERNAL** | gerçek beta oturumları ve PASS kanıtı |
| 11 — Store/dağıtım | **BLOCKED/EXTERNAL** | signing, TestFlight, Play internal/closed testing, notarization |
| 12 — Ticari katman | **NOT STARTED BY DESIGN** | Faz 10 doğrulanmadan başlanmaz |
| 13 — Lansman paketi | **PARTIAL** | gerçek store screenshotları ve final platform app icon assetleri |

---

## Faz 0 — Çalışan teknik temel

**Durum: DONE**

- Android, iOS ve macOS runner üretimi
- Drift code generation ve database lifecycle
- Riverpod provider ağı
- Global error handling ve logging
- Migration altyapısı
- CI analyze/test/build kapısı

### Çıkış kriteri
Üç hedef için release build üretilebiliyor; SQLite yaşam döngüsü ve migration zinciri testlerle korunuyor.

---

## Faz 1 — Sınıf ve öğrenci yönetimi

**Durum: PARTIAL**

### Tamamlanan
- `SchoolYear → Course → Classroom → Student` ilişkisel modeli
- Sınıf oluşturma/düzenleme/arşivleme
- Manuel öğrenci CRUD ve arşivleme
- Excel/CSV import
- Kolon algılama, önizleme ve satır doğrulama
- Dosya içi duplicate tespiti
- Mevcut sınıftaki okul numarası conflict'lerini import öncesinde satır bazında gösterme
- Aktif ve arşivlenmiş öğrencileri aynı uniqueness invariantı içinde kontrol etme
- Önizleme sonrası yarış durumuna karşı write transaction içinde conflict'i yeniden doğrulama
- Conflict olduğunda sessiz overwrite yerine güvenli bloklama
- Transaction/batch ile toplu yazma ve conflict halinde sıfır partial insert

### Kalan
- Eğitim yılı düzenleme/arşivleme UX'ini tamamlamak

### Çıkış kriteri
30–40 öğrencilik gerçek sınıf birkaç dakika içinde güvenli biçimde oluşturulabilmeli; conflict sonucu kullanıcıya import başlamadan önce açıkça gösterilmeli ve stale preview durumunda write path aynı invariantı yeniden doğrulamalıdır.

---

## Faz 2 — Değerlendirme domain modeli

**Durum: DONE**

Çekirdek model:

```text
Assessment
AssessmentType
Rubric
RubricCriterion
RubricLevel
Evaluation
EvaluationEntry
ObservationNote
```

1.0 tipleri:
1. Rubrik
2. Hızlı derecelendirme ölçeği

Assessment oluşturulurken rubrik snapshot'ı alınır; evaluation kayıtları sınıftaki aktif öğrenciler için canonical write path üzerinden üretilir.

---

## Faz 3 — Hızlı değerlendirme ekranı

**Durum: PARTIAL**

### Tamamlanan
- Telefon için tek öğrenci odaklı akış
- Tablet/macOS için gradebook görünümü
- Otomatik kayıt
- Önceki/sonraki öğrenci
- notStarted/incomplete/completed durumları
- Değerlendirilmeyen/eksik filtreleri
- Kriter notu, öğrenci notu ve zaman damgalı gözlem

### Kalan
- macOS/tablet için gerçek klavye focus navigasyonu ve shortcutlar
- Kullanıcı testinde ihtiyaç doğrulanırsa toplu puanlama

### Çıkış kriteri
30 öğrencilik sınıf veri kaybı veya manuel Kaydet ihtiyacı olmadan akıcı değerlendirilmeli; desktop kullanıcısı yalnız fareye bağımlı bırakılmamalıdır.

---

## Faz 4 — Rubrik oluşturucu

**Durum: DONE**

- Basit kriter editörü
- Maksimum puan/açıklama/sıra
- Gelişmiş performans seviyeleri
- Rubrik düzenleme, çoğaltma, arşivleme
- Şablon olarak tekrar kullanım

---

## Faz 5 — Sonuç ve temel analiz

**Durum: DONE**

- Sınıf ortalaması
- Kriter ortalamaları
- Tamamlanan/eksik öğrenci sayısı
- Öğrenci toplamları
- Öğrenci drill-down
- Kriter/öğrenci/gözlem notları
- En güçlü kriter ve gelişim alanı gibi temel özetler

1.0 sınırı gereği ağır BI, tahminleme veya AI analizi yoktur.

---

## Faz 6 — PDF / Excel / Yazdırma

**Durum: DONE**

Çıktılar:
1. Öğrenci değerlendirme PDF'i
2. Sınıf değerlendirme çizelgesi PDF'i
3. XLSX sonuç tablosu
4. CSV sonuç tablosu
5. Sistem yazdırma/paylaşma akışları

### Kalite kapısı
Export regression testleri şu invariants'ı korur:
- öğrenci/kriter eşleşmesi
- toplam ve durum alanları
- kriter/öğretmen/gözlem notları
- Türkçe karakterler
- eksik değerlendirme
- öğrencisiz değerlendirme
- CSV ve XLSX mantıksal içerik eşitliği
- sınıf ve öğrenci PDF'lerinin geçerli PDF üretmesi

---

## Faz 7 — Şifreli yedekleme ve geri yükleme

**Durum: DONE**

- Sürümlü backup envelope
- AES-256-GCM authenticated encryption
- PBKDF2-HMAC-SHA256, 600.000 iterasyon, 256-bit anahtar
- Random salt ve nonce
- Restore öncesi metadata/count preview
- Tüm kullanıcı tablolarını kapsayan backup
- Tek DB transaction içinde atomik restore
- Restore sonrası evaluation-status invariant onarımı

### Zorunlu invariant

```text
DB A
→ encrypted backup
→ clean DB B
→ restore
→ A.data == B.data
```

Ayrıca restore ortasında hata oluşursa önceki DB'nin değişmeden kaldığı test edilir.

---

## Faz 8 — Ürün UX'i

**Durum: PARTIAL**

### Tamamlanan
- Onboarding
- Empty state'ler
- Responsive telefon/tablet/macOS yerleşimleri
- Dark/light/system tema
- Kullanıcı dostu hata yüzeyleri
- Archive/Undo yaklaşımı
- Temel semantic label kullanımı

### Kalan
- VoiceOver/TalkBack gerçek cihaz doğrulaması
- büyük font/font scaling kontrolü
- minimum touch target audit'i
- tablet landscape ve macOS pencere boyutu regresyonları

---

## Faz 9 — Güvenilirlik ve test kapıları

**Durum: PARTIAL — veri güvenliği P0'ları kapalı**

### Mevcut kapsam
- Domain invariant testleri
- FK/transaction/rollback testleri
- Import parse/validation ve existing-conflict preflight testleri
- Import conflict transaction rollback testi
- v1 ve tarihsel v2/v3/v4/v5 → v6 migration testleri
- Full encrypted backup/restore round-trip testi
- Failed restore atomic rollback testi
- PDF/CSV/XLSX regression testleri
- Kritik entegrasyon zinciri:

```text
CSV import
→ rubrik
→ assessment
→ puanlama/not/gözlem
→ sonuç
→ PDF/CSV/XLSX
→ DB restart
→ encrypted backup
→ clean DB restore
```

### Kalan
- Telefon/tablet/macOS widget/UI test kapsamını genişletmek
- Accessibility/font scaling testlerini otomasyona uygun yerlerde eklemek
- Yeni export ve migration değişikliklerinde regression test zorunluluğunu sürdürmek

### Çıkış kriteri
Veri kaybı veya yanlış veri eşlemesi yaratabilecek hiçbir kritik akış testsiz kalmaz.

---

## Faz 10 — Gerçek öğretmen beta testi

**Durum: BLOCKED/EXTERNAL — gerçek kullanıcı kanıtı gerekli**

Repo `BETA_TEST_PLAN.md` ve `BETA_OBSERVATION_FORM.md` sağlar. Bu faz kod veya sentetik fixture ile PASS sayılamaz.

Zorunlu ana görevler:
1. Sınıf oluştur
2. Excel/CSV'den öğrenci aktar
3. Rubrik oluştur
4. Öğrencileri değerlendir
5. Puan değiştir
6. Sonuç/PDF/XLSX çıkar
7. Uygulamayı kapat/aç
8. Yedek al
9. Temiz kurulumda restore et

### Çıkış kriteri
Gerçek öğretmenler ana akışı geliştirici müdahalesi olmadan tamamlar ve kritik veri doğruluğu problemi görülmez.

---

## Faz 11 — Store ve dağıtım hazırlığı

**Durum: BLOCKED/EXTERNAL**

### Repo tarafında hazır
- `com.knigdelioglu.olcerim` kimliği
- Android/iOS/macOS runner üretimi
- Privacy manifest başlangıcı
- macOS sandbox/file/print entitlementları
- Android APK/AAB, unsigned iOS ve macOS release CI buildleri

### Hesap/signing ortamında tamamlanacak
- Apple App ID/certificate/provisioning
- TestFlight archive
- macOS notarization veya Mac App Store signing
- Play Console + Play App Signing + upload key
- Internal/closed testing
- Store privacy/data-safety formları

### Çıkış kriteri
Gerçek imzalı release candidate store review'a gönderilebilir durumda olmalıdır.

---

## Faz 12 — Ticari ürün katmanı

**Durum: NOT STARTED BY DESIGN**

Mevcut kodda local entitlement/cache iskeleti bulunabilir; gerçek satın alma/paywall/receipt doğrulama Faz 10 beta doğrulanmadan tamamlanmaz.

Tercih edilen yön: local-first premium uygulama. Fiyat ve paket sınırları gerçek beta bulgularından sonra sabitlenir.

---

## Faz 13 — Lansman paketi

**Durum: PARTIAL**

### Hazır
- Görsel kimlik başlangıcı
- Store metadata taslakları
- Gizlilik politikası/data-safety belgeleri
- Destek/kullanım rehberi/sürüm notları
- Demo feature
- 6 başlangıç rubrik şablonu:
  - Sözlü Sunum
  - Konuşma Becerisi
  - Proje Değerlendirme
  - Grup Çalışması
  - Okuma Becerisi
  - Yazma Becerisi

### Kalan
- Final platform app icon seti ve runner üretim pipeline'ına uygulanması
- Gerçek cihaz/simulator store screenshotları
- Beta sonrası son store metni/polish

---

# Güncel çalışma sırası

```text
1. Desktop keyboard grading polish
↓
2. Accessibility + font scaling audit/test
↓
3. Gerçek öğretmen beta
↓
4. Beta P0/P1 düzeltmeleri
↓
5. Final icon + screenshot assetleri
↓
6. Signing / TestFlight / Play internal testing
↓
7. Ticari model ve IAP kararı
↓
8. Ölçerim 1.0 RC
```

## Yol haritası kuralı

Migration, backup/restore, değerlendirme veri bütünlüğü ve yanlış öğrenciye/sınıfa veri bağlanması hiçbir zaman “sonra bakılacak” teknik borç kabul edilmez. Dış doğrulama gerektiren beta ve signing maddeleri, sentetik veri veya doküman varlığıyla tamamlanmış işaretlenemez.

Kapsam sınırları için bkz. [`PRODUCT_SCOPE.md`](PRODUCT_SCOPE.md).
