# Ölçerim 1.0 — Store Privacy / Data Safety Kaydı

Bu belge Apple App Privacy ve Google Play Data Safety formları doldurulurken kaynak olarak kullanılır. Store formlarındaki terimler ve politika sürümleri yayın tarihinde tekrar doğrulanmalıdır.

## Mimari gerçekler

- Öğrenci ve değerlendirme verisi cihazdaki SQLite'ta tutulur.
- Ölçerim backend'i yoktur.
- Kullanıcı hesabı yoktur.
- Otomatik cloud sync yoktur.
- Reklam SDK'sı yoktur.
- Tracking SDK'sı yoktur.
- Uzaktan analytics/crash telemetry entegrasyonu yoktur.
- Dosya import/export kullanıcı tarafından başlatılan sistem picker/share işlemleridir.
- Manuel backup şifrelenir; hedefi kullanıcı seçer.

## Uygulamanın yerelde işlediği hassas sayılabilecek veri

- öğrenci adı
- okul numarası
- sınıf/ders bilgisi
- performans puanı
- öğretmen değerlendirme notu

Bu verilerin yerelde işlenmesi, store'un 'collected' tanımına her zaman eşit değildir. Apple ve Google'ın yayın tarihindeki güncel tanımları esas alınmalıdır; bu belge hukuki/store yorumu yerine teknik kaynak kaydıdır.

## İzin yaklaşımı

- Geniş depolama erişimi istenmez.
- Dosyaya kullanıcı sistem picker ile erişir.
- Paylaşım sistem share sheet üzerinden yapılır.
- Kamera/mikrofon/konum/rehber izni 1.0 kapsamında yoktur.
- Ağ erişimi ürünün ana akışı için gerekli değildir.

## Değişiklik tetikleyicileri

Aşağıdakilerden biri eklenirse privacy/data safety tekrar değerlendirilir:
- in-app purchase SDK'sının store iletişimi dışında telemetry davranışı
- analytics/crash SDK
- hesap/backend
- cloud sync
- AI/OCR servisi
- reklam
- push notification
