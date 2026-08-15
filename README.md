# Ölçerim

**Ölçerim**, öğretmenlerin öğrencilerin performanslarını rubrikler ve kriter bazlı değerlendirmelerle takip etmesi için tasarlanmış, **local-first** bir Flutter uygulamasıdır. Hedef platformlar **Android, iOS ve macOS**'tur. Sunucu zorunluluğu yoktur; öğrenci ve değerlendirme verileri cihazdaki SQLite veritabanında tutulur.

## Temel hedef

- Öğrenci/sınıf listelerini Excel veya CSV'den içe aktarmak.
- Öğretmenin rubrik ve kriterlerini tanımlamasını sağlamak.
- Öğrenciyi kriter bazında hızlı biçimde puanlamak ve not almak.
- Değerlendirme çizelgelerini PDF/Excel olarak üretmek, yazdırmak veya sistem paylaşım menüsüyle dışa aktarmak.
- Sunucusuz kullanımda veri kaybına karşı sürümlü ve **şifreli tam yedekleme/geri yükleme** akışı sağlamak.
- Yeni sürümlerde mevcut öğretmen verisini koruyan test edilebilir Drift migration'ları kullanmak.

## Mimari

**Feature-First Local-First Layered Architecture** uygulanır.

```text
UI / Presentation
        ↓
Riverpod controller/provider
        ↓
Feature repository
        ↓
DAO / local service
        ↓
Drift + SQLite / Files / PDF / Excel
```

Ağ katmanı varsayılan mimarinin parçası değildir. Özellikler (`students`, `rubrics`, `evaluations`, `reports`, `backup`) kendi veri ve sunum sorumluluklarını izole eder.

## Teknoloji yığını

- Flutter + Material 3
- Riverpod
- Drift + SQLite
- file_picker + share_plus + path_provider
- excel + csv
- pdf + printing
- Freezed + json_serializable

> Not: Eski mimari notlarında geçen `sqlite3_flutter_libs` artık kullanılmamalıdır. Güncel Drift native kurulumu `sqlite3` 3.x ile Android/iOS/macOS'ta ek native SQLite paketi olmadan çalışır.

## Veri modeli — ilk şema

```text
Students
  └── id, schoolNumber, fullName, className, archived

Rubrics
  └── id, title, description
       └── RubricCriteria
             └── id, rubricId, title, description, maxScore, sortOrder

EvaluationEntries
  └── id, studentId, criterionId, score, note, evaluatedAt
```

`EvaluationEntries(studentId, criterionId)` benzersizdir. Foreign key'ler etkinleştirilir ve veritabanı WAL modunda açılır.

## Kritik veri güvenliği kuralları

1. Kullanıcı verisi `SharedPreferences` veya tek parça JSON içinde tutulmaz.
2. Her şema değişikliğinde `schemaVersion` artırılır ve ileri yönlü açık migration yazılır.
3. Production upgrade sırasında veritabanı silinip yeniden oluşturulmaz.
4. Yedek dosyası uygulama dışına çıkmadan önce şifrelenir; format ve şema sürümü taşır.
5. Restore işlemi doğrulama sonrası transaction içinde yapılır; yarım restore kabul edilmez.
6. PDF/Excel/yedek dosyaları uygulama sandbox'ında kilitli bırakılmaz; Share Sheet / Android Sharesheet üzerinden kullanıcıya teslim edilir.
7. Excel parse ve ağır dosya işlemleri UI isolate üzerinde yapılmaz.

## Klasör yapısı

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/app_router.dart
│   └── theme/app_theme.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── database_provider.dart
│   │   ├── daos/
│   │   │   ├── evaluation_dao.dart
│   │   │   ├── rubric_dao.dart
│   │   │   └── student_dao.dart
│   │   └── tables/
│   │       ├── evaluation_entries.dart
│   │       ├── rubric_criteria.dart
│   │       ├── rubrics.dart
│   │       └── students.dart
│   ├── errors/failures.dart
│   └── services/
│       ├── backup_restore_service.dart
│       ├── excel_service.dart
│       └── pdf_export_service.dart
├── features/
│   ├── backup/
│   ├── evaluations/
│   ├── reports/
│   ├── rubrics/
│   └── students/
└── main.dart
```

## Excel → SQLite veri akışı

1. `StudentImportView` sistem dosya seçicisini açar.
2. Dosya byte'ları `ExcelService`'e aktarılır.
3. Parse/doğrulama işi UI isolate dışına taşınır.
4. Sonuç `StudentRepository` üzerinden `StudentDao.insertMultipleStudents` metoduna gider.
5. DAO tüm öğrencileri tek transaction/batch içinde yazar.
6. Drift stream'i değişikliği yayınlar; Riverpod üzerinden öğrenci listesi reaktif yenilenir.

## Platform runnerlarını oluşturma

Bu repo iskeletinin üretildiği ortamda Flutter CLI bulunmadığı için Android/iOS/macOS runner dosyaları elle kopyalanmamıştır. Flutter'ın kendi güncel şablonundan üretmek için proje kökünde:

```bash
./tool/bootstrap_platforms.sh
```

Bu script geçici bir Flutter projesi oluşturur ve yalnız `android/`, `ios/`, `macos/` ile `.metadata` dosyasını mevcut projeye taşır.

Ardından:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
```

Android veya iOS cihaz/simülatörü için `flutter devices` ile hedefi görüp `flutter run -d <device-id>` kullanın.

## Migration politikası

İlk şema sürümü `1`'dir. Her veri modeli değişikliğinde:

- `schemaVersion` artırılır.
- `onUpgrade` içinde yalnız gereken migration adımları yazılır.
- Eski şemadan yeni şemaya gerçek veriyle migration testi eklenir.
- Yedek format sürümü ile DB şema sürümü birbirinden bağımsız tutulur.

## Yedek formatı

Yedek servisinin dış sözleşmesi hazırdır; gerçek kriptografik implementasyon sonraki geliştirme adımıdır. Nihai format en az şunları taşımalıdır:

```json
{
  "format": "olcerim-backup",
  "formatVersion": 1,
  "createdAt": "ISO-8601",
  "databaseSchemaVersion": 1,
  "cipher": "...",
  "kdf": "...",
  "payload": "encrypted-bytes"
}
```

Şifreleme algoritması uygulama içinde özel tasarlanmamalı; bakımlı bir kriptografi kütüphanesinin AEAD primitive'i ve parola tabanlı güvenli KDF kullanılmalıdır.

## İlk geliştirme sırası

1. Platform runnerlarını üret.
2. Drift code generation'ı çalıştır.
3. Öğrenci import pipeline'ını tamamla.
4. Rubrik CRUD + kriter CRUD'ı tamamla.
5. Değerlendirme tablosunu Drift stream + Riverpod ile bağla.
6. PDF/Excel export ve Share Sheet akışını tamamla.
7. Şifreli backup/restore formatını ve atomik restore'u uygula.
8. Migration test kapısını zorunlu hale getir.

## Gizlilik

Repo private tutulmalıdır. Gerçek öğrenci adı, okul numarası, değerlendirme notu, SQLite dosyası, yedek ve export dosyaları repoya commit edilmemelidir; `.gitignore` bu veri türlerini dışlar.
