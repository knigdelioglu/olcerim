# Ölçerim 1.0 — Store ve Dağıtım Hazırlığı

Bu belge Faz 11 release kontratıdır. Signing sertifikaları, provisioning profile, Play signing key ve store hesap gizlileri repoya konmaz.

## Sabit uygulama kimliği

- Android application ID: `com.knigdelioglu.olcerim`
- iOS bundle ID: `com.knigdelioglu.olcerim`
- macOS bundle ID: `com.knigdelioglu.olcerim`
- Görünen ad: `Ölçerim`

Runnerlar `./tool/bootstrap_platforms.sh` ile güncel Flutter SDK şablonundan üretilir.

## Apple

### Repo tarafından hazırlanan
- iOS ve macOS targetları.
- `PrivacyInfo.xcprivacy`: tracking yok, uygulama seviyesinde veri toplama yok olarak başlangıç manifesti.
- macOS App Sandbox.
- Kullanıcının seçtiği dosyalar için `user-selected.read-write` entitlement.
- macOS yazdırma entitlement.
- Sistem Files / Share Sheet kullanımı.

### Apple hesabında tamamlanacak
- App ID: `com.knigdelioglu.olcerim`.
- Development/Distribution signing.
- iOS provisioning.
- TestFlight kayıtları.
- macOS distribution + notarization veya Mac App Store profili.
- App Store Connect privacy cevapları, bu repodaki `PRIVACY_POLICY.md` ve `DATA_SAFETY.md` ile karşılaştırılarak doldurulur.
- Yaşa uygunluk ve ülke dağıtımı.

## Android

### Repo tarafından hazırlanan
- Flutter Android targetı.
- application ID `com.knigdelioglu.olcerim`.
- Sistem file picker/share yaklaşımı; geniş depolama izni istenmez.

### Play Console'da tamamlanacak
- Play App Signing.
- Upload key yerel/güvenli secret store'da tutulur; repo dışıdır.
- Internal testing → closed testing → production sırası.
- Data Safety formu `DATA_SAFETY.md` ile uyumlu doldurulur.
- Store listing ve content rating.

## Release build kapıları

Store yüklemesinden önce Faz 14 CI en az:

```text
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
flutter build macos --release
```

kapılarını geçmelidir. iOS/macOS imzalı archive işlemleri yalnız gerçek Apple signing ortamında yapılır.

## Release secret politikası

Aşağıdakiler commit edilmez:
- `.jks`, `.keystore`
- `key.properties`
- `.p12`, `.pem`
- provisioning profile
- App Store Connect API key
- Google Play service account JSON
- herhangi bir store şifresi/tokenı

`.gitignore` bunların temel uzantılarını zaten dışlar; release sırasında ayrıca `git status` kontrol edilir.

## Release candidate tanımı

Bir commit yalnız şu durumda store RC olarak etiketlenebilir:
- Faz 14 test/build kapıları PASS.
- Kritik P0/P1 açık hata yok.
- Gerçek beta PASS kaydı var.
- Store metadata ve gizlilik metinleri güncel.
- Signing dışı release artifactleri üretilebiliyor.
