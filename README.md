# Ölçerim

**Ölçerim**, öğretmenlerin öğrenci performansını cihaz üzerinde rubrik ve hızlı derecelendirme araçlarıyla takip etmesi için geliştirilmiş **local-first** bir Flutter uygulamasıdır. Hedef platformlar **Android, iOS/iPadOS ve macOS**'tur. Sunucu zorunluluğu yoktur; sınıf, öğrenci, değerlendirme ve ayar verileri Drift/SQLite içinde tutulur.

## Güncel ürün durumu

Repo artık mimari iskelet değil çalışan 1.0 ürün adayıdır. Güncel uygulama şunları içerir:

- Eğitim yılı, ders, sınıf ve öğrenci yönetimi
- Manuel öğrenci CRUD + Excel/CSV import
- Import önizlemesinde dosya içi ve mevcut sınıf okul numarası conflict kontrolü
- Rubrik ve hızlı derecelendirme assessment tipleri
- Rubrik editörü, performans seviyeleri ve şablon tekrar kullanımı
- Telefon için ardışık öğrenci puanlama, tablet/macOS için gradebook
- Otomatik kayıt, kriter notu, öğrenci notu ve zaman damgalı gözlem
- Sınıf/öğrenci sonuç ekranları
- PDF, XLSX ve CSV export; yazdırma ve sistem paylaşımı
- AES-256-GCM ile şifreli tam backup/restore
- Atomik restore ve migration test zinciri
- Onboarding, light/dark/system tema, demo veri ve hazır rubrik şablonları
- GitHub Actions kalite kapısı: analyze + test + Android/iOS/macOS release buildleri

Gerçek öğretmen beta testi, store signing/TestFlight/Play dağıtımı ve final store assetleri henüz dış süreç olarak tamamlanmalıdır. Güncel durum için [`docs/ROADMAP.md`](docs/ROADMAP.md) esas alınır.

## Ürün referans belgeleri

- [`docs/ROADMAP.md`](docs/ROADMAP.md) — fazların güncel durumu, kalan işler ve release sırası
- [`docs/PRODUCT_SCOPE.md`](docs/PRODUCT_SCOPE.md) — 1.0 kapsamı, mimari invariant'lar ve Definition of Done
- [`docs/UX_DESIGN.md`](docs/UX_DESIGN.md) — tasarım sistemi ve responsive UX kuralları
- [`docs/BETA_TEST_PLAN.md`](docs/BETA_TEST_PLAN.md) — gerçek öğretmen beta protokolü
- [`docs/STORE_RELEASE.md`](docs/STORE_RELEASE.md) — signing ve store release kontratı

## Mimari

**Feature-First Local-First Layered Architecture** uygulanır.

```text
Presentation / UI
        ↓
Riverpod controller/provider
        ↓
Feature repository
        ↓
DAO / local service
        ↓
Drift + SQLite / File system / PDF / Excel
```

Ağ katmanı temel ürün için zorunlu değildir. Aynı domain verisi için alternatif write path açılmamalı; veri invariant'ları repository/DAO katmanında korunmalıdır.

## Teknoloji yığını

- Flutter + Material 3
- Riverpod
- Drift + SQLite (`sqlite3` 3.x)
- file_picker + share_plus + path_provider
- excel + csv
- pdf + printing
- cryptography + cryptography_flutter
- Freezed + json_serializable

## Veri modeli — schema v6

```text
SchoolYear
  └── Course
       └── Classroom
            └── Student

Rubric (template veya assessment snapshot)
  └── RubricCriterion
       └── RubricLevel

Assessment
  └── Evaluation (assessment + student)
       ├── EvaluationEntry (criterion score + criterion note)
       └── ObservationNote

AppSetting
```

Güncel fiziksel tablolar:

```text
school_years
courses
classrooms
students
rubrics
rubric_criteria
rubric_levels
assessments
evaluations
evaluation_entries
observation_notes
app_settings
```

Temel bütünlük kuralları:

- `Student` bir `Classroom`a bağlıdır.
- Aynı sınıfta aynı okul numarası duplicate olamaz; archive durumu bu uniqueness invariantını kaldırmaz.
- Assessment oluşturulurken kullanılan rubrik snapshot olarak kopyalanır; sonradan template değişikliği eski değerlendirmeyi bozmaz.
- `Evaluation`, assessment + student çiftini temsil eder.
- `EvaluationEntry`, evaluation + criterion için tek canonical puan kaydıdır.
- Puan kriter maksimumunu aşamaz.
- Evaluation status (`notStarted | incomplete | completed`) gerçek entry sayısından türetilen invariant olarak korunur.
- Foreign key'ler açık, production DB WAL modundadır.

## Excel / CSV → SQLite akışı

```text
Dosya seç
→ byte'ları al
→ UI isolate dışında parse et
→ kolonları algıla
→ dosya içi validation
→ mevcut sınıf conflict preflight
→ önizle
→ write transaction içinde conflict'i yeniden doğrula
→ tek transaction/batch ile yaz
→ Drift stream üzerinden UI'ı yenile
```

Import güvenliği:

- Dosya içindeki duplicate okul numaraları ve boş öğrenci adları import başlamadan raporlanır.
- Seçili sınıfta aynı okul numarasına sahip aktif **veya arşivlenmiş** öğrenci varsa ilgili CSV/Excel satırı, okul numarası ve mevcut öğrenci adı önizlemede gösterilir.
- Conflict kayıtları sessizce overwrite edilmez.
- Preview ile kayıt arasındaki sürede sınıf değişmiş olabileceği için DAO aynı kontrolü write transaction içinde tekrarlar.
- Transaction seviyesinde conflict bulunursa hiçbir yeni öğrenci satırı yazılmaz.
- Aynı okul numarası farklı bir sınıfta kullanılabilir; invariant sınıf + okul numarası çiftidir.

## Değerlendirme akışı

```text
Classroom
→ rubric template veya quick-scale preset
→ Assessment
→ rubric snapshot
→ sınıftaki aktif öğrenciler için Evaluation kayıtları
→ criterion score / note / observation autosave
→ AssessmentResults
→ PDF / XLSX / CSV
```

Telefon görünümü öğrenci-odaklı ardışık akış kullanır; geniş ekranda gradebook yerleşimi kullanılır.

## Backup / restore

Backup implementasyonu gerçektir; placeholder değildir.

Şifreleme:

- **AES-256-GCM** authenticated encryption
- **PBKDF2-HMAC-SHA256**
- **600.000 iterasyon**
- 256-bit türetilmiş anahtar
- random salt + nonce
- MAC doğrulaması

Envelope örneği:

```json
{
  "format": "olcerim-backup",
  "formatVersion": 1,
  "cipher": "AES-256-GCM",
  "kdf": "PBKDF2-HMAC-SHA256",
  "iterations": 600000,
  "salt": "base64",
  "nonce": "base64",
  "cipherText": "base64",
  "mac": "base64"
}
```

Şifreli payload içinde metadata (`createdAt`, `databaseSchemaVersion`, tablo sayımları) ve güncel kullanıcı tablolarının tamamı bulunur. Restore tüm tabloları tek Drift transaction içinde değiştirir; hata halinde eski DB korunur.

Test kapısı ayrıca şunu doğrular:

```text
DB A
→ encrypted backup
→ clean DB B
→ restore
→ A.data == B.data
```

## Migration politikası

Güncel şema **v6**'dır.

Kurallar:

1. Her veri modeli değişikliğinde `schemaVersion` artırılır.
2. `onUpgrade` içinde ileri yönlü açık migration yazılır.
3. Production çözümü olarak DB silinmez.
4. Tarihsel kullanıcı DB'leri için migration regression testi eklenir.
5. Güncel test matrisi v1/v2/v3/v4/v5 → v6 upgrade yollarını kapsar.
6. v6 migration'ı eski sürümlerde stale kalabilen evaluation statuslarını gerçek score/criterion sayılarından yeniden hesaplar.

## Kritik test zinciri

CI'da unit/data testlerinin yanında kritik entegrasyon akışı da çalışır:

```text
CSV import
→ rubrik oluştur
→ assessment oluştur
→ puan/not/gözlem kaydet
→ sonuçları doğrula
→ PDF/CSV/XLSX üret
→ DB'yi kapat/aç
→ encrypted backup
→ clean DB restore
→ sonuç ve FK bütünlüğünü tekrar doğrula
```

Ek regression testleri:

- CSV/XLSX mantıksal içerik eşitliği
- Türkçe karakterler
- kriter/öğretmen/gözlem notları
- completed/incomplete sonuçlar
- öğrencisiz assessment exportu
- aktif/arşivlenmiş student import conflict preflight
- stale preview conflictinde transaction rollback

## Platform runnerları ve yerel çalıştırma

Runnerlar güncel Flutter SDK şablonundan üretilebilir:

```bash
./tool/bootstrap_platforms.sh
```

Ardından:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
```

Diğer cihaz/simülatörler için:

```bash
flutter devices
flutter run -d <device-id>
```

## CI kalite kapısı

`.github/workflows/phase14-quality-gate.yml` hem `main` pushlarında hem `main` hedefli pull requestlerde çalışır:

```text
bootstrap platform runners
→ flutter pub get
→ build_runner
→ flutter analyze
→ flutter test
→ Android APK
→ Android AAB
→ unsigned iOS release
→ macOS release
```

Bu kapının yeşil olması gerçek store signing veya gerçek öğretmen beta PASS yerine geçmez.

## Gizlilik ve repo hijyeni

Gerçek öğrenci adı, okul numarası, değerlendirme notu, SQLite dosyası, backup ve export dosyaları repoya commit edilmemelidir. Testlerde yalnız sentetik/anonim fixture kullanılmalıdır.

## Sıradaki işler

Güncel sıra `docs/ROADMAP.md` ile yönetilir. Kısa özet:

1. macOS/tablet keyboard grading polish
2. Accessibility/font scaling audit
3. Gerçek öğretmen beta
4. Beta P0/P1 düzeltmeleri
5. Final app icon + gerçek store screenshotları
6. Apple/Google signing ve internal testing
7. Beta sonrası ticari/IAP kararı
