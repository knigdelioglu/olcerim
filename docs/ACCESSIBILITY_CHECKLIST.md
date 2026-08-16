# Ölçerim — Accessibility Acceptance Checklist

Bu belge, otomatik testlerle doğrulanabilen erişilebilirlik kuralları ile gerçek cihaz/ekran okuyucu doğrulamasını birbirinden ayırır.

> **Kural:** CI yeşil olması VoiceOver veya TalkBack PASS anlamına gelmez. Gerçek cihaz maddeleri gözlem yapılmadan işaretlenmez.

## 1. Otomatik kalite kapıları

Aşağıdaki invariant'lar test veya statik yapı ile korunur:

- Material tap target davranışı `padded` olmalıdır.
- `IconButton` ve `TextButton` minimum hedefi en az **48 × 48 dp** olmalıdır.
- Filled/Outlined ana aksiyonlar en az **48 dp** yüksekliğinde olmalıdır.
- Geniş ekran gradebook header ve öğrenci/puan satırları sistem `TextScaler` değerine göre büyümelidir.
- Frozen öğrenci sütunu ile yatay puan grid'i aynı dinamik satır yüksekliğini kullanmalıdır.
- Score hücresinin tıklanabilir alanı en az **48 dp** yüksekliğinde olmalıdır.
- Kriter notu butonu lokal `VisualDensity.compact` ile küçültülmemelidir.
- Büyük sistem yazısında temel FilledButton regression testi overflow üretmemelidir.

İlgili testler:

- `test/app/accessibility_layout_test.dart`
- `test/app/responsive_layout_test.dart`
- `test/features/evaluations/gradebook_keyboard_navigation_test.dart`

## 2. Büyük yazı / font scaling manuel matrisi

Her hedef platformda en az normal ölçek ve işletim sisteminin büyük erişilebilirlik metin boyutlarından biriyle kontrol et.

### Kritik ekranlar

- [ ] Onboarding
- [ ] Sınıflar
- [ ] Sınıf detayı / öğrenci listesi
- [ ] Öğrenci import önizlemesi
- [ ] Assessment oluşturma
- [ ] Telefon puanlama
- [ ] Tablet/macOS gradebook
- [ ] Rubrik editörü
- [ ] Sonuçlar
- [ ] Raporlar
- [ ] Backup / restore
- [ ] Ayarlar

### PASS kriteri

- Kritik aksiyon metni kesilmez veya erişilemez hale gelmez.
- Render overflow görülmez.
- İçerik gerekirse scroll edilebilir.
- Form alanı etiketi ile kullanıcı girdisi birbirini kapatmaz.
- Dialog/bottom sheet aksiyonları ekranda erişilebilir kalır.
- Gradebook'ta öğrenci sütunu ile score satırları dikey hizasını kaybetmez.

## 3. Touch target manuel matrisi

- [ ] Android telefon
- [ ] iPhone
- [ ] iPad/tablet
- [ ] macOS pointer kullanımı

### PASS kriteri

- Icon-only aksiyonlarda yanlış komşu aksiyona basma riski yaratacak sıkışıklık yoktur.
- Kritik icon-only aksiyonlarda tooltip/semantic anlam bulunur.
- Puan hücreleri mouse/touch ve klavye ile aynı canonical aksiyonu açar.
- Disabled kontrolün durumu yalnız renk farkıyla anlatılmaz.

## 4. VoiceOver — Apple

Aşağıdaki doğrulama gerçek iPhone/iPad veya macOS erişilebilirlik oturumunda yapılmalıdır.

- [ ] Ana navigation sırası mantıklı.
- [ ] Icon-only butonların adı okunuyor.
- [ ] Form alanlarının label'ları okunuyor.
- [ ] Evaluation status (`Tamamlandı`, `Eksik`, `Değerlendirilmedi`) okunuyor.
- [ ] Gradebook score hücresinde öğrenci + kriter + mevcut puan okunuyor.
- [ ] Dialog açıldığında focus dialog içine geçiyor.
- [ ] Dialog kapanınca focus anlamlı noktaya dönüyor.
- [ ] Snackbar/başarı-hata geri bildirimi anlaşılabilir.

**Durum:** `NOT VALIDATED` — gerçek cihaz kanıtı bekleniyor.

## 5. TalkBack — Android

- [ ] Ana navigation sırası mantıklı.
- [ ] Icon-only butonların adı okunuyor.
- [ ] Form alanlarının label'ları okunuyor.
- [ ] Evaluation status okunuyor.
- [ ] Score hücreleri anlamlı tek hedef olarak dolaşılabiliyor.
- [ ] Dialog ve sheet focus geçişleri doğru.
- [ ] Import conflict mesajı satır ve okul numarasıyla anlaşılır okunuyor.
- [ ] Backup/restore risk uyarısı atlanmıyor.

**Durum:** `NOT VALIDATED` — gerçek cihaz kanıtı bekleniyor.

## 6. Pencere / orientation matrisi

- [ ] 375 px sınıfı kompakt telefon genişliği
- [ ] 600 px breakpoint çevresi
- [ ] 800 px tablet portrait/medium
- [ ] 1024 px tablet landscape / expanded sınırı
- [ ] 1280–1440 px macOS tipik pencere
- [ ] Daraltılmış macOS pencere

### PASS kriteri

- `<600`: compact akış
- `600..<1024`: medium yerleşim
- `>=1024`: expanded yerleşim
- Navigation bar/rail geçişi içerik kaybı üretmez.
- Yatay gradebook gerektiğinde yatay scroll kullanır; sayfanın geri kalanı erişilebilir kalır.

## 7. Beta öncesi çıkış kuralı

Faz 8'in otomatik kısmı ancak ilgili CI testleri yeşil olduğunda tamamlanmış sayılır. VoiceOver/TalkBack ve gerçek cihaz font-scaling matrisi gözlem formuyla doğrulanmadan **Faz 8 tamamen DONE** veya **accessibility PASS** olarak raporlanmaz.
