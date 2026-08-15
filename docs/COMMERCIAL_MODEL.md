# Ölçerim — Ticari Model ve Faz 12 Kapısı

## Model

Ölçerim için tercih edilen model **local-first premium** uygulamadır. Ücretlendirme ürünü backend, kullanıcı hesabı veya zorunlu cloud katmanına dönüştürmemelidir.

## Planlanan paketler

### Ücretsiz
- 1 aktif sınıf
- en fazla 2 yeniden kullanılabilir rubrik
- temel değerlendirme akışı
- öğrenci/sınıf veri yönetimi
- güvenli restore erişimi

### Pro
- sınırsız aktif sınıf
- sınırsız rubrik
- gelişmiş rubrik performans seviyeleri
- PDF raporları
- Excel/CSV export
- temel gelişmiş sonuç görünümü

## Veri güvenliği istisnası

Restore, ticari entitlement nedeniyle engellenmez. Kullanıcının daha önce oluşturduğu kendi verisine erişebilmesi abonelik/satın alma durumundan bağımsız bir güvenlik gereksinimidir.

Backup'ın fiyatlandırma kapsamı gerçek beta ve store modeli kesinleşirken ayrıca değerlendirilecektir. Veri kaybı riskini artıracak bir karar varsayılan olarak reddedilir.

## Şu an neden paywall yok?

`ROADMAP.md` Faz 12 açıkça fiyatlandırma/satın alma mekanizmasının ana akış gerçek öğretmen beta testinde doğrulandıktan sonra uygulanmasını şart koşuyor. Bu dış doğrulama henüz yapılmadığından:

- `CommercialPolicy.monetizationEnabled = false`
- hiçbir ana özellik fiilen kilitlenmez
- paywall veya “yakında” UI'ı gösterilmez
- App Store / Play ürün kimliği uydurulmaz
- satın alma sonucu simüle edilmez

Bu davranış `UX_DESIGN.md` içindeki gereksiz/disabled “yakında” UI yasağıyla da uyumludur.

## Aktivasyon ön koşulları

Monetizasyon ayrı bir release değişikliği olarak ancak:

1. `docs/BETA_TEST_PLAN.md` kriterleri gerçek kullanıcılarla PASS,
2. Faz 14 tüm test/build kapıları PASS,
3. App Store Connect ve Play Console gerçek ürünleri oluşturulmuş,
4. fiyat ve satın alma türü kararlaştırılmış,
5. satın alma geri yükleme akışı iki store'da test edilmiş,
6. gizlilik ve Data Safety metinleri satın alma SDK davranışı açısından tekrar kontrol edilmiş

olduğunda aktive edilir.

## Store ürün entegrasyonu için hedef kontrat

Daha sonra eklenecek store adapter'ı domain'e yalnız doğrulanmış sonucu verir:

```text
Store SDK
  ↓ verified purchase / restore
EntitlementRepository
  ↓ ProductTier.pro
CommercialPolicy
  ↓ feature gate
UI
```

UI doğrudan store SDK sonucuna göre veri yazmaz. Entitlement cache yalnız yerel kolaylık içindir; gerçek satın alma doğrulaması platformun desteklediği restore/query akışından yeniden yapılabilmelidir.

## Scope koruması

Ticari katman:
- backend zorunluluğu getiremez,
- öğrenci verisini store/ödeme servisine gönderemez,
- değerlendirme domain modelini değiştiremez,
- migration/backup doğruluğunu bypass edemez,
- ücretsiz kullanıcı verisini rehin bırakan bir restore engeli yaratamaz.
