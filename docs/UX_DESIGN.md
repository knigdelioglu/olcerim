# Ölçerim — UX Tasarımı ve Tasarım Sistemi

Bu belge, **Ölçerim 1.0** için kullanıcı deneyimi, görsel dil, responsive davranış, bileşen kuralları ve ekran spesifikasyonlarının tek referansıdır. Amaç; Android, iOS/iPadOS ve macOS üzerinde aynı ürün mantığını korurken her cihaz sınıfında hızlı, sakin ve öğretmenin ders içindeki temposunu bozmayan bir deneyim oluşturmaktır.

> Ürün vaadi: **Sınıfını aktar, değerlendirme aracını oluştur, öğrencilerini hızlıca değerlendir ve sonucu hemen raporla. Verilerin cihazından çıkmasın.**

Bu belge [`PRODUCT_SCOPE.md`](PRODUCT_SCOPE.md) ile birlikte okunmalıdır. Burada tarif edilen ancak ürün kapsamı belgesinde 1.0 dışında bırakılan hiçbir özellik 1.0'a alınmaz.

---

# 1. UX hedefleri

Ölçerim'in UX'i aşağıdaki öncelik sırasına göre tasarlanır:

1. **Hız:** Öğretmen ders sırasında öğrenciden öğrenciye geçerken uygulama tempo kaybettirmemelidir.
2. **Veri güveni:** Kullanıcı yaptığı işlemin kaydedilip kaydedilmediğini düşünmek zorunda kalmamalıdır.
3. **Düşük bilişsel yük:** Ekranda aynı anda yalnız o iş için gerekli kararlar gösterilmelidir.
4. **Yerel-öncelikli açıklık:** Hesap, bağlantı, senkronizasyon veya sunucu kavramları ana akışta görünmez; çünkü 1.0'da bunlar yoktur.
5. **Platforma uyum:** Telefon, tablet ve masaüstü aynı ekranı ölçeklemek yerine aynı işi cihazın gücüne göre farklı yerleşimle yapar.
6. **Geri alınabilirlik:** Veri kaybı riski taşıyan eylemlerde silme yerine arşivleme, uygun yerlerde Undo ve açık onay kullanılır.
7. **Öğretmen dili:** Teknik terimler, veritabanı kavramları ve geliştirici mesajları UI'a sızmaz.

## 1.1 Başarı ölçütleri

1.0 beta testinde hedeflenen davranışlar:

- Yeni kullanıcı yardım almadan ilk sınıfını oluşturabilmeli.
- 30–40 öğrencilik Excel/CSV listesi birkaç dakika içinde içe aktarılabilmeli.
- Öğretmen bir değerlendirme oturumunda sürekli “Kaydet” butonuna basmamalı.
- Değerlendirilmeyen öğrenciye ulaşmak en fazla iki etkileşim gerektirmeli.
- PDF/Excel çıktısına ana değerlendirme sonucundan en fazla üç ana etkileşimle ulaşılmalı.
- Kullanıcı yedek alırken “verilerim nereye gitti?” sorusunu yaşamamalı; dosya sistem paylaşım ekranıyla teslim edilmelidir.

---

# 2. Ürün bilgi mimarisi

## 2.1 Ana bölümler

Ölçerim 1.0'ın kalıcı ana navigasyonu beş bölümden oluşur:

1. **Sınıflar**
2. **Değerlendirmeler**
3. **Rubrikler**
4. **Raporlar**
5. **Ayarlar**

`Yedekleme` Ayarlar içinde saklanmaz; veri güvenliği kritik olduğu için Ayarlar ana sayfasında belirgin bir kart olarak görünür ve gerektiğinde bağımsız “Yedekleme ve Geri Yükleme” ekranına açılır.

Önceki teknik iskeletteki `Öğrenciler` ana sekmesi ürün düzeyinde `Sınıflar` altında ele alınır. Öğrenci, bağlamdan kopuk global bir liste yerine bir sınıfın üyesi olarak yönetilir.

## 2.2 Navigasyon davranışı

### Compact — telefon, `< 600 dp`

Alt `NavigationBar` kullanılır:

- Sınıflar
- Değerlendirmeler
- Rubrikler
- Raporlar
- Ayarlar

Kurallar:

- Yükseklik: Material 3 varsayılanına yakın, görsel olarak yaklaşık `80 dp`.
- Seçili öğede ikon + label görünür vurgu alır.
- Alt navigasyon değerlendirme oturumu gibi tam odak ekranlarında gizlenebilir.
- Geri davranışı platform kurallarına uyar; Android sistem back, iOS/macOS üst seviye navigation semantiği korunur.

### Medium — tablet portrait / küçük landscape, `600–1023 dp`

Sol `NavigationRail` kullanılır:

- Genişlik yaklaşık `80 dp`.
- İkon + kısa label.
- İçerik alanı kalan genişliği alır.
- Detay ekranlarında mümkünse master-detail düzenine geçilir.

### Expanded — büyük tablet landscape / macOS, `>= 1024 dp`

Sol geniş sidebar kullanılır:

- Genişlik `240–272 dp`.
- Uygulama adı ve küçük marka işareti üstte.
- Ana bölümler ikon + metin olarak görünür.
- En altta `Ayarlar` ve uygulama sürümü.
- İçerik alanı merkezde `maxWidth` sınırıyla veya tablo ekranlarında tam kullanılabilir genişlikle açılır.

## 2.3 Responsive breakpoint standardı

Flutter'da tek kaynak:

```text
compact  : width < 600
medium   : 600 <= width < 1024
expanded : width >= 1024
```

Breakpoint'ler ekran adına göre değiştirilmez. Bir ekran özel ihtiyaca sahipse bu temel sınıfların içinde kendi maksimum içerik genişliğini ayarlar.

---

# 3. Görsel kimlik

## 3.1 Marka karakteri

Ölçerim'in görsel dili:

- sakin,
- güvenilir,
- akademik ama bürokratik olmayan,
- modern,
- yoğun veri ekranlarında yorucu olmayan,
- renk patlamaları yerine kontrollü vurgu kullanan

bir karakter taşımalıdır.

Ana görsel metafor: **ölçme + işaretleme + ilerleme**. Uygulama ikonunda ileride kare/grid yapısı içinde belirgin bir onay işareti veya ölçüm çizgisi kullanılabilir. İkon üretimi ayrı görsel çalışma olarak yapılacaktır; bu belge ikonu raster/vektör olarak tanımlamaz.

## 3.2 Renk sistemi

Tasarım başlangıç rengi mevcut Flutter iskeletiyle uyumlu olarak **indigo** ailesidir.

### Light theme temel tokenları

| Token | Renk | Kullanım |
|---|---|---|
| `primary` | `#4F46E5` | Ana CTA, seçili durum, aktif kontrol |
| `onPrimary` | `#FFFFFF` | Primary üzerindeki metin/ikon |
| `primaryContainer` | `#E0E7FF` | Seçili kart, tonal vurgu |
| `onPrimaryContainer` | `#25205F` | Container üzerindeki metin |
| `secondary` | `#475569` | İkincil kontrol ve bilgi |
| `surface` | `#FFFBFE` veya platform Material 3 yüzeyi | Ana yüzey |
| `surfaceContainerLow` | `#F8F7FB` | Gruplama yüzeyi |
| `surfaceContainer` | `#F1F0F5` | Kart/toolbar alt yüzeyi |
| `surfaceContainerHigh` | `#EAE9EF` | Hover/selected yardımcı yüzey |
| `onSurface` | `#1C1B1F` | Ana metin |
| `onSurfaceVariant` | `#5F5E66` | İkincil metin |
| `outline` | `#797780` | Sınır |
| `outlineVariant` | `#CAC7D0` | İnce divider |
| `success` | `#2E7D32` | Tamamlandı, başarılı import/backup |
| `successContainer` | `#DFF3E1` | Başarı banner/kart |
| `warning` | `#A15C00` | Eksik değerlendirme, dikkat |
| `warningContainer` | `#FFF1D6` | Uyarı yüzeyi |
| `error` | `#B3261E` | Hata/destructive |
| `errorContainer` | `#F9DEDC` | Hata yüzeyi |
| `info` | `#1565C0` | Bilgilendirme |
| `infoContainer` | `#E3F2FD` | Bilgilendirme yüzeyi |

### Dark theme yaklaşımı

Dark theme Material 3 dynamic tonal mantığına göre türetilir; sabit siyah kullanılmaz.

- Ana arka plan: yaklaşık `#121318`.
- Yüzeyler: `#1A1B20`, `#202127`, `#282930` kademeleri.
- Primary: yaklaşık `#B9C3FF`.
- Metin: `#E5E1E6`.
- Divider: düşük kontrastlı `#45464F`.

Kural: dark modda primary rengin doygunluğu azaltılır; büyük yüzeyler indigo ile boyanmaz.

## 3.3 Renk kullanım kuralları

- Primary renk ekranın yaklaşık `%10–15`inden fazlasını kaplamamalıdır.
- Başarı, uyarı ve hata renkleri yalnız semantik amaçla kullanılır.
- Puan skalalarında kırmızı–yeşil tek başına anlam taşımaz; sayı/label da gösterilir.
- Değerlendirme tablosunda her hücreyi renkli yapmak yasaktır. Renk yalnız seçili hücre, tamamlanma durumu veya eşik uyarısı için kullanılır.
- Destructive eylem primary renkle gösterilmez.

---

# 4. Tipografi

Ölçerim özel font paketlemez; platformun yüksek kaliteli sistem fontlarını kullanır. Flutter/Material varsayılanı temel alınır. Böylece iOS/macOS'ta SF ailesi, Android'de Roboto çizgisi korunur.

## 4.1 Tipografi ölçeği

| Rol | Boyut | Ağırlık | Kullanım |
|---|---:|---:|---|
| Display | 32 | 600 | İlk açılış büyük başlığı, seyrek |
| Headline Large | 28 | 600 | Büyük ekran sayfa başlığı |
| Headline Medium | 24 | 600 | Ana ekran başlığı |
| Title Large | 22 | 600 | Kart/section önemli başlık |
| Title Medium | 16 | 600 | Liste kart başlığı |
| Body Large | 16 | 400 | Ana metin/form |
| Body Medium | 14 | 400 | İkincil metin |
| Label Large | 14 | 600 | Buton |
| Label Medium | 12 | 600 | Chip/yardımcı etiket |

Kurallar:

- Tamamı büyük harf CTA kullanılmaz.
- Uzun açıklamalarda satır yüksekliği `1.4–1.5`.
- Öğrenci adları ve sınıf adları ellipsis ile kaybolmadan önce uygun genişlik verilir.
- Kullanıcı sistem font boyutunu büyüttüğünde kritik eylemler taşmamalıdır.

---

# 5. Ölçü, grid ve boşluk sistemi

## 5.1 Spacing tokenları

```text
space-1 = 4 dp
space-2 = 8 dp
space-3 = 12 dp
space-4 = 16 dp
space-5 = 24 dp
space-6 = 32 dp
space-7 = 48 dp
space-8 = 64 dp
```

Standart ekran yatay padding:

- Telefon: `16 dp`
- Tablet: `24 dp`
- Mac/expanded: `32 dp`

Maksimum form genişliği: `640 dp`.
Maksimum okuma/ayar içeriği: `760 dp`.
Tablo/gradebook ekranlarında max width uygulanmaz.

## 5.2 Köşe yarıçapları

```text
radius-small  = 8 dp
radius-medium = 12 dp
radius-large  = 16 dp
radius-xl     = 24 dp
```

- Butonlar: `12 dp`.
- Kartlar: `16 dp`.
- Küçük chip: tam pill veya `8 dp`.
- Modal/bottom sheet: üst köşeler `24 dp`.

## 5.3 Elevation

Ağır gölge kullanılmaz.

- Ana kartlar çoğunlukla `0–1` elevation.
- Floating toolbar/FAB: `2–3`.
- Modal: Material varsayılan tonal/elevation davranışı.
- Gruplama için gölgeden önce yüzey tonu ve spacing tercih edilir.

---

# 6. Bileşen sistemi

## 6.1 Ana buton — FilledButton

Kullanım: ekrandaki tek ana ilerleme eylemi.

Örnekler:

- `İlk sınıfımı oluştur`
- `İçe aktar`
- `Değerlendirmeyi başlat`
- `PDF oluştur`
- `Yedek oluştur`

Kurallar:

- Minimum yükseklik: `48 dp`.
- Telefon formunun sonunda gerektiğinde tam genişlik.
- Tablet/Mac'te içeriğe göre genişlik; minimum yaklaşık `120 dp`.
- Aynı görünür bölgede iki eşdeğer primary CTA kullanılmaz.
- İşlem sürerken buton disabled + küçük progress indicator; label mümkünse korunur.

## 6.2 Tonal buton — FilledButton.tonal

Kullanım: önemli ama ana olmayan eylem.

Örnek:

- `Önizle`
- `Şablondan seç`
- `Dosya seç`
- `Paylaş`

## 6.3 OutlinedButton

Kullanım:

- alternatif yol,
- iptal olmayan ikincil eylem,
- filtre/araç işlemi.

Örnek: `CSV seç`, `Rubriği çoğalt`.

## 6.4 TextButton

Kullanım:

- modal `İptal`,
- düşük öncelikli “Daha sonra”,
- küçük inline action.

## 6.5 Destructive action

- `Sil` yerine ürün genelinde önce `Arşivle` tercih edilir.
- Gerçek silme gerekiyorsa error rengi ve açık fiil kullanılır.
- Destructive buton modalda primary pozisyona konmaz; onay metni nesneyi adıyla belirtir.

Örnek:

> “10/A sınıfını kalıcı olarak silmek istiyor musunuz?”

1.0'da mümkün olan veri türlerinde kalıcı silme kullanıcıya sunulmayabilir; arşivleme yeterlidir.

## 6.6 IconButton

- Minimum hit target `48x48 dp`.
- Tooltip zorunlu (desktop/tablet hover ve accessibility için).
- Yalnız ikon anlamı evrensel değilse label'lı buton tercih edilir.

## 6.7 FloatingActionButton

Telefon sınıf listesi / rubrik listesi gibi “tek ekleme eylemi” olan ekranlarda kullanılabilir.

- `+ Sınıf` veya `+ Rubrik` için extended FAB tercih edilebilir.
- Değerlendirme oturumunda FAB kullanılmaz.
- Tablet/Mac'te üst toolbar `Yeni` butonu tercih edilir.

## 6.8 TextField / form alanları

- Label her zaman görünür; placeholder label'ın yerini almaz.
- Yardım metni gerekiyorsa input altında kısa görünür.
- Hata validasyon sonrası aynı alan altında gösterilir.
- Form submit edilmeden önce her tuşta agresif hata gösterilmez.
- Numeric puan alanında platforma uygun numeric keyboard.
- Maksimum puan alanında negatif/ondalık kuralları domain tarafından doğrulanır.

Standart yükseklik yaklaşık `56 dp`.

## 6.9 Dropdown / seçim

Az seçenek: segmented button veya radio.
Orta seçenek: dropdown.
Uzun sınıf/rubrik listesi: searchable modal/bottom sheet.

## 6.10 Chips

Kullanım:

- `Tamamlandı`
- `Eksik`
- `Değerlendirilmedi`
- `Arşiv`
- aktif filtreler

Status chip renkleri semantik tokenlarla; metin mutlaka görünür.

## 6.11 Cards

Kart bilgi grubunu temsil eder, dekoratif kutu değildir.

Sınıf kartı örneği:

```text
10/A
Türk Dili ve Edebiyatı
31 öğrenci · 4 değerlendirme

Son değerlendirme: 12 Ağu
```

Kartın tamamı açılabilir. Sağ üst `…` menüsü düzenle/arşivle gibi secondary actions taşır.

## 6.12 Dialog / bottom sheet

Telefon:
- hızlı seçim ve kısa formlar için bottom sheet.
- kritik onaylar için alert dialog.

Tablet/Mac:
- dialog veya side panel.

Uzun editörler modal içine sıkıştırılmaz; tam ekran/route açılır.

## 6.13 Snackbar / banner

Snackbar:
- düşük riskli tek seferlik feedback.
- örnek: `Öğrenci arşivlendi` + `Geri al`.

Inline banner:
- kullanıcı karar vermeden kapanmaması gereken uyarı.
- örnek: importta 3 satır hatalı.

## 6.14 Progress

- Belirsiz kısa işlem: circular progress.
- Import/restore gibi aşamalı işlem: linear progress + durum metni.
- Skeleton yalnız gerçekten gecikmeli yüklenen karmaşık listede; yerel DB sorgularında çoğu zaman gerekmez.

---

# 7. Global etkileşim kuralları

## 7.1 Otomatik kayıt

Değerlendirme oturumunda puan ve kısa notlar **otomatik kaydedilir**.

UI davranışı:

- Kullanıcı puan verir.
- Hücre/alan anında optimistic olarak yeni değeri gösterir.
- Sağ üst veya toolbar'da çok kısa `Kaydediliyor…` durumu belirebilir.
- Başarılı olduğunda sessizce `Kaydedildi` durumuna döner.
- DB yazma hatasında alan eski değere körlemesine dönmez; hata açıkça gösterilir ve yeniden deneme sunulur.

Normal başarıda snackbar gösterilmez; 30 öğrenci puanlarken spam yaratır.

## 7.2 Undo

Aşağıdaki işlemlerde Undo hedeflenir:

- öğrenci arşivleme,
- sınıf arşivleme,
- rubrik arşivleme,
- kriter kaldırma (henüz kullanılmamışsa).

Snackbar süresi yaklaşık `5–7 saniye`.

## 7.3 Arama ve filtre

Listeler `> 12` öğede arama sunmalıdır.

Filtreler:

- değerlendirmelerde: `Tümü`, `Devam ediyor`, `Tamamlandı`.
- değerlendirme oturumunda: `Tümü`, `Değerlendirilmedi`, `Eksik`, `Tamamlandı`.
- sınıflarda: aktif eğitim yılı varsayılan; arşiv ayrı görünüm.

## 7.4 Klavye ve masaüstü

Mac için temel kısayollar:

| Kısayol | Eylem |
|---|---|
| `⌘N` | Bağlama göre yeni sınıf/rubrik/değerlendirme |
| `⌘F` | Görünür listedeki arama alanına odaklan |
| `⌘S` | Editör ekranında açık değişikliği kaydet; auto-save ekranında no-op/feedback |
| `Esc` | Modal kapat / aktif hücre editini iptal et |
| `↑ ↓` | Listede/hızlı değerlendirmede öğrenci gez |
| `Tab / Shift+Tab` | Form/hücre odağı |
| `Enter` | Seçili eylemi onayla / hücre editini bitir |

Kısayollar menü/tooltip ile keşfedilebilir olmalıdır.

---

# 8. İlk açılış ve onboarding

## 8.1 Launch / splash

Özel uzun splash yoktur.

- Sistem launch ekranı açık nötr yüzey.
- Ortada sade Ölçerim işareti/kelime markası.
- Ağ isteği beklenmez.
- DB migration gerekiyorsa kullanıcıya boş spinner yerine gerekirse `Verileriniz hazırlanıyor…` gösterilir.

## 8.2 Hoş geldiniz ekranı

### Amaç
Yeni kullanıcıyı ürünün değer önerisiyle karşılamak ve tek net eyleme yönlendirmek.

### Telefon düzeni

Üstten yaklaşık `64–80 dp` boşluk.

```text
[Ölçerim işareti]

Öğrenci değerlendirmeyi
hızlandırın

Sınıfınızı aktarın, rubriğinizi oluşturun,
öğrencilerinizi değerlendirin ve raporlayın.
Veriler cihazınızda kalır.

[ İlk sınıfımı oluştur ]

Daha sonra örnek verileri incele
```

### Tablet/Mac

Merkezde `560–640 dp` genişlikli panel. Sol tarafta aşırı pazarlama illüstrasyonu kullanılmaz; ürünün kendisini hızlı başlatmak önceliklidir.

### Kurallar

- Hesap oluştur / giriş yap yoktur.
- İzin isteme yoktur.
- 3–5 onboarding carousel sayfası yoktur.
- Tek CTA: `İlk sınıfımı oluştur`.
- İkinci yol ancak demo veri gerçekten yapılırsa `Örnek sınıfı incele` olabilir.

---

# 9. Sınıflar ekranı

## 9.1 Amaç
Öğretmenin aktif sınıflarını ve o sınıflardaki güncel çalışma bağlamını tek bakışta görmesi.

## 9.2 Empty state

```text
Henüz sınıfınız yok

Öğrencilerinizi değerlendirmeye başlamak için
ilk sınıfınızı oluşturun.

[ Sınıf oluştur ]
```

Altında ikincil:

`Excel/CSV ile başlamak ister misiniz? Sınıf oluşturduktan sonra öğrenci listenizi içe aktarabilirsiniz.`

## 9.3 Dolu ekran — telefon

AppBar:
- Başlık: `Sınıflar`
- sağ: arama ikonu

İçerik:
- eğitim yılı selector chip: `2026–2027 ▾`
- sınıf kartları dikey liste
- sağ alt extended FAB: `+ Sınıf`

Sınıf kartı:

```text
10/A                              ⋮
Türk Dili ve Edebiyatı
31 öğrenci

4 değerlendirme · Son: 12 Ağu
```

Kart yüksekliği yaklaşık `112–128 dp`.

## 9.4 Tablet/Mac

- Üst toolbar: `Sınıflar` + eğitim yılı + `Yeni sınıf`.
- Kart grid'i: orta genişlikte 2 kolon, büyük ekranda 3 kolon; kart min `280 dp`, max `360 dp`.
- Çok sınıf varsa arama alanı toolbar'da görünür.

## 9.5 Kart menüsü

- `Sınıfı aç`
- `Düzenle`
- `Öğrenci içe aktar`
- `Arşivle`

Arşivlenen sınıf ana listeden kaybolur ve snackbar:

`10/A arşivlendi` — `Geri al`

---

# 10. Sınıf oluştur / düzenle

## Alanlar

1. `Eğitim yılı` — varsayılan aktif yıl
2. `Sınıf adı` — ör. `10/A`
3. `Ders` — ör. `Türk Dili ve Edebiyatı`
4. Opsiyonel `Açıklama`

Telefon:
- tam ekran route.
- alt safe-area içinde sticky primary `Sınıfı oluştur`.

Tablet/Mac:
- `560–640 dp` form column.
- sağ üst/alt primary action.

Validasyon:

- sınıf adı boş olamaz.
- aynı eğitim yılı + aynı sınıf + aynı ders kombinasyonu varsa kullanıcıya açık uyarı.

Hata metni:

`Bu eğitim yılında aynı ad ve dersle bir sınıf zaten var.`

---

# 11. Sınıf detay / öğrenci listesi

## 11.1 Header

```text
10/A
Türk Dili ve Edebiyatı · 2026–2027
31 öğrenci
```

Ana eylemler:

- `Değerlendirme başlat`
- `Öğrenci ekle`
- `İçe aktar`

Telefon: `Değerlendirme başlat` primary; diğerleri overflow veya tonal.
Tablet/Mac: üçü toolbar'da görünür.

## 11.2 Öğrenci listesi

Satır:

```text
1234   Ayşe Demir                    ›
```

- Okul numarası ikincil veya sabit dar kolon.
- Öğrenci adı ana vurgu.
- Satır yüksekliği min `56 dp`.

Telefon swipe-to-delete kullanılmaz; yanlış veri kaybı riski. `…` menüsünden `Düzenle`, `Arşivle`.

Tablet/Mac:
- başlık kolonları `No`, `Öğrenci`, `Son değerlendirme`, durum.
- satır hover.

## 11.3 Arama

Arama öğrenci adı ve okul numarasında çalışır.

---

# 12. Öğrenci ekle / düzenle

Alanlar:

- `Okul numarası`
- `Ad soyad`

Sınıf bağlamı ekranda readonly görünür.

Primary:
- yeni: `Öğrenciyi ekle`
- edit: `Değişiklikleri kaydet`

Duplicate hata:

`Bu okul numarası bu sınıfta zaten kullanılıyor.`

---

# 13. Excel / CSV içe aktarma akışı

Import tek ekranda sihirli biçimde sonuç vermek yerine dört açık adıma ayrılır.

## 13.1 Adım 1 — Dosya seç

Başlık: `Öğrenci listesini içe aktar`

```text
Excel veya CSV dosyanızı seçin.
Dosya cihazınızda işlenir; hiçbir veri sunucuya gönderilmez.

[ Dosya seç ]

Desteklenen: .xlsx, .csv
```

Telefon: büyük dosya seçim kartı.
Desktop: drag-and-drop 1.0 için zorunlu değildir; file picker temel yol.

## 13.2 Adım 2 — Kolon eşleştirme

Dosya header'ları otomatik tahmin edilir fakat kullanıcıya gösterilir.

```text
Dosyadaki kolon       Ölçerim alanı
-----------------------------------
Öğrenci No            [ Okul numarası ▾ ]
Ad Soyad               [ Ad soyad ▾ ]
Şube                   [ Kullanma ▾ ]
```

Zorunlu alanlar:
- Ad soyad

Okul numarası önerilir; ürün kararı gerektiriyorsa zorunluluk domain belgesinde sabitlenir.

Primary: `Önizlemeye devam et`.

## 13.3 Adım 3 — Önizleme ve doğrulama

Üst özet:

```text
31 satır bulundu
29 hazır · 2 dikkat gerekiyor
```

Filtre chipleri:
- `Tümü 31`
- `Hazır 29`
- `Sorunlu 2`

Tablo:

| Satır | No | Ad soyad | Durum |
|---|---|---|---|
| 2 | 1234 | Ayşe Demir | Hazır |
| 7 | — | Mehmet Kaya | Okul no eksik |

Hatalı satır error container içinde boyanmaz; satır başında küçük error ikon + durum metni yeterlidir.

Import stratejisi:
- bloklayan hata varsa primary disabled ve `Sorunları düzeltmeden içe aktaramazsınız.`
- yalnız warning varsa kullanıcı açık biçimde devam edebilir.

Primary: `29 öğrenciyi içe aktar`.

## 13.4 Adım 4 — Sonuç

Başarı:

```text
✓ 29 öğrenci içe aktarıldı

2 satır içe aktarılmadı.
[ Sorunlu satırları görüntüle ]

[ Sınıfa dön ]
```

Tam başarısızlıkta kullanıcıya teknik exception değil:

`Dosya okunamadı. Dosyanın bozuk olmadığını ve desteklenen biçimde olduğunu kontrol edin.`

---

# 14. Değerlendirmeler listesi

## Kart içeriği

```text
Konuşma Becerisi
10/A · 14 Ağu 2026

24 / 31 tamamlandı
[progress bar]

Devam ediyor
```

Durumlar:
- `Taslak`
- `Devam ediyor`
- `Tamamlandı`

Telefon:
- liste + `+ Değerlendirme` FAB.

Tablet/Mac:
- toolbar `Yeni değerlendirme`.
- filtre chipleri üstte.

Kart tıklanınca:
- devam ediyorsa değerlendirme oturumuna,
- tamamlandıysa sonuç özetine.

---

# 15. Yeni değerlendirme oluştur

Akış tek uzun form yerine kısa karar adımları olarak düzenlenir.

## Adım 1 — Sınıf

Sınıf kartlarından birini seç.

## Adım 2 — Değerlendirme tipi

1. `Rubrik`
2. `Hızlı derecelendirme`

Her kartta bir cümle açıklama.

## Adım 3 — Rubrik / ölçek

Seçenekler:

- `Kayıtlı rubrikten seç`
- `Yeni rubrik oluştur`

## Adım 4 — Detay

- Değerlendirme adı
- Tarih
- Opsiyonel açıklama

Primary: `Değerlendirmeyi oluştur`.

Oluşturma sonrası başarı sayfası yerine doğrudan değerlendirme detayına gidilir ve belirgin `Değerlendirmeyi başlat` CTA gösterilir.

---

# 16. Rubrikler / şablon kütüphanesi

## 16.1 Liste

Kart:

```text
Konuşma Becerisi
5 kriter · 100 puan
Son kullanım: 10/A · 14 Ağu

                                  ⋮
```

Filtre:
- `Tümü`
- `Benim rubriklerim`
- `Hazır şablonlar` yalnız şablon paketi ürün içine alınırsa.

Ana CTA: `Yeni rubrik`.

## 16.2 Empty state

```text
Henüz rubriğiniz yok

Kriterlerinizi bir kez oluşturun,
farklı sınıflarda tekrar kullanın.

[ Rubrik oluştur ]
```

---

# 17. Rubrik editörü — Basit mod

## 17.1 Üst bölüm

Alanlar:
- `Rubrik adı`
- `Açıklama` opsiyonel

Özet chip:
- `Toplam: 100 puan`

## 17.2 Kriter kartı

```text
≡  İçerik                           ⋮
   Maksimum puan: [ 20 ]
   Açıklama: ...
```

- Drag handle tablet/Mac'te desteklenebilir.
- Telefonda sürükleme + alternatif `Yukarı/Aşağı taşı` accessibility menüsü.
- Kriter ekle butonu: tonal `+ Kriter ekle`.

## 17.3 Sticky footer

Telefon:
- `İptal` text
- `Rubriği kaydet` filled

Mac:
- toolbar/sağ üst Save.

Save sırasında duplicate isim bloklayıcı olmak zorunda değildir; aynı isim mümkünse küçük context göstermek gerekir. Domain kararı ayrı sabitlenir.

---

# 18. Rubrik editörü — Gelişmiş mod

Gelişmiş mod Basit modun üstüne performans seviyeleri ekler.

Desktop/tablet tablo:

| Kriter | 4 — Çok iyi | 3 — İyi | 2 — Gelişiyor | 1 — Yetersiz |
|---|---|---|---|---|
| İçerik | açıklama | açıklama | açıklama | açıklama |

Telefon:
- tek kriter kartı açılır.
- seviyeler dikey accordion/section.

Her seviye:
- başlık
- açıklama
- puan veya puan aralığı

Kural: yatay dört kolon telefon ekranına sıkıştırılmaz.

---

# 19. Değerlendirme oturumu — Telefon

Bu ekran ürünün en kritik UX ekranıdır.

## 19.1 Tam ekran odak modu

Alt ana navigation gizlenir.

AppBar:

```text
← Konuşma Becerisi                 ⋮
10/A · 12 / 31
```

İkinci satır progress: `12 / 31` + ince progress bar.

## 19.2 Öğrenci header

```text
12
Ayşe Demir
```

- okul no küçük secondary.
- öğrenci adı `22–24 sp`, semibold.
- sağda durum chip: `Eksik` / `Tamamlandı`.

## 19.3 Kriter puanlama

Rubrik seviye bazlıysa büyük seçenekler:

```text
İçerik                           18 / 20

[ 5 ] [ 10 ] [ 15 ] [ 20 ]
```

veya seviyeler:

```text
[ Yetersiz ]
[ Gelişiyor ]
[ İyi ]
[ Çok iyi ]
```

Seçili seçenek primaryContainer + güçlü border/indicator.

Kriter açıklaması gerekiyorsa başlığın altında kısa metin; uzun açıklama `Açıklamayı göster` ile açılır.

Kriterler dikey scroll.

## 19.4 Not

Alt section:

`Öğretmen notu` multiline text field.

Not alanı puanlamayı engellemez ve optionaldır.

## 19.5 Öğrenci navigasyonu

Ekranın altındaki sticky toolbar:

```text
[ ← Önceki ]                   [ Sonraki → ]
```

Ortada veya üstte:
- `12 / 31`

`Sonraki` primary yalnız anlamı “kaydet” değildir; puan zaten auto-save. Öğrenciyi değiştirir.

Swipe gesture öğrenci değiştirmek için varsayılan yol yapılmaz; yanlışlıkla veri bağlamı değiştirebilir. İstenirse ikincil kısayol olur.

## 19.6 Eksik öğrenci davranışı

Kullanıcı sonraki öğrenciye geçerken boş kriter varsa bloklama yapılmaz.

Durum `Eksik` olur.

Oturum sonunda:

`4 öğrencide eksik kriter var` banner'ı gösterilir ve `Eksikleri görüntüle` eylemi sunulur.

---

# 20. Değerlendirme oturumu — Tablet / Mac tablo modu

## 20.1 Temel yapı

Sol sabit kolon:
- öğrenci no
- öğrenci adı

Sağda yatay scroll kriterler:

```text
No  Öğrenci       İçerik  Akıcılık  Dil  Sunum  Toplam
12  Ayşe Demir       18       17     19    16      70
13  Mehmet Kaya      —        —      —     —       —
```

## 20.2 Hücre davranışı

- Tek tıklama/tap: hücreyi seç.
- Seviye tabanlı rubrikte popover/compact selector açılır.
- Numeric ise inline edit.
- Enter: değeri onaylar ve bir sonraki mantıklı hücreye geçer.
- Tab: sağ hücre.
- Shift+Tab: sol hücre.
- Ok tuşları: seçim navigasyonu.

## 20.3 Sabit alanlar

- öğrenci adları yatay scroll sırasında sabit kalır.
- header satırı dikey scroll sırasında sticky.

## 20.4 Durum göstergesi

Öğrenci satırında küçük durum:
- hollow circle = değerlendirilmedi
- warning icon = eksik
- check = tamamlandı

Renk tek başına kullanılmaz.

## 20.5 Sağ detay paneli

Expanded genişlikte seçili öğrenci için opsiyonel `320–360 dp` sağ panel:

- öğrenci adı
- toplam
- kısa not
- durum

Bu panel tabloyu sıkıştırıyorsa kapatılabilir.

## 20.6 Toolbar

- değerlendirme adı
- sınıf
- filtre
- arama
- `Eksikler` chip
- `Sonuçları görüntüle`
- save status: `Kaydedildi`

---

# 21. Hızlı derecelendirme ekranı

Rubrikten daha hafif kullanım için.

Telefon öğrenci kartı:

```text
Ayşe Demir

Hazırlıklı gelme
[ Yetersiz ] [ Gelişiyor ] [ İyi ] [ Çok iyi ]

Katılım
[ Yetersiz ] [ Gelişiyor ] [ İyi ] [ Çok iyi ]
```

Eğer yalnız tek özellik değerlendiriliyorsa seçenekler daha büyük ve tek satır/2x2 grid olabilir.

Tablet/Mac yine gradebook benzeri tablo kullanır.

---

# 22. Değerlendirme sonuçları — Sınıf özeti

## 22.1 Üst özet

Kartlar:

- `Sınıf ortalaması` — `76,4`
- `Tamamlanan` — `28 / 31`
- `En güçlü kriter` — `İçerik`
- `Gelişim alanı` — `Akıcılık`

Telefon: 2x2 grid.
Tablet/Mac: 4 kolon.

## 22.2 Kriter dağılımı

Basit bar listesi; gereksiz chart çeşitliliği yok.

```text
İçerik      █████████░  18,2 / 20
Akıcılık    ███████░░░  14,6 / 20
Dil         ████████░░  16,1 / 20
Sunum       █████████░  18,7 / 20
```

Renk primary tek ton; düşük skor otomatik kırmızıya boyanmaz.

## 22.3 Öğrenci tablosu

- No
- Öğrenci
- Toplam
- Durum

Satıra tıklayınca öğrenci sonucu.

## 22.4 Ana eylemler

- `Rapor oluştur`
- `Değerlendirmeye dön`

Tamamlanmamış değerlendirmede banner:

`3 öğrenci henüz tamamlanmadı.` — `Eksikleri aç`

---

# 23. Öğrenci sonuç detayı

Header:

```text
Ayşe Demir
10/A · Konuşma Becerisi
67 / 80
```

Kriter satırları:

```text
İçerik       18 / 20
Akıcılık     14 / 20
Dil          16 / 20
Sunum        19 / 20
```

Altında öğretmen notu.

Eylemler:
- `Değerlendirmeyi düzenle`
- `Öğrenci PDF'i oluştur`

1.0'da öğrenciler arası ranking gösterilmez; performans ölçümü rekabet ekranına dönüştürülmez.

---

# 24. Raporlar ekranı

## 24.1 Rapor türleri

Kartlar:

1. `Sınıf değerlendirme çizelgesi`
2. `Öğrenci değerlendirme formu`
3. `Excel/CSV sonuç tablosu`

Her kart:
- ikon
- isim
- tek cümle açıklama
- `Oluştur`

## 24.2 Filtre bağlamı

Rapor oluşturulmadan önce:
- eğitim yılı
- sınıf
- değerlendirme

seçilir.

Seçimler dependency sırasıyla açılır; sınıf seçilmeden değerlendirme alanı disabled.

---

# 25. Rapor önizleme ve export

## Telefon

- PDF sayfası fit-width preview.
- alt sticky toolbar:
  - `Paylaş`
  - `Yazdır`
  - overflow: `Dosyalara kaydet` desteklenen platform akışına göre.

## Tablet/Mac

- solda sayfa thumbnail listesi (`80–100 dp`).
- ortada sayfa preview.
- üst toolbar export actions.

## Kurallar

- Dosya oluşturulduktan sonra yalnız sandbox path gösterilmez.
- Sistem share sheet açılır.
- Başarı metni teknik path içermez.

Örnek:

`PDF hazır. Paylaşmak veya cihazınıza kaydetmek için aşağıdaki seçenekleri kullanın.`

---

# 26. Ayarlar ana ekranı

Gruplar:

## Görünüm
- `Tema` — Sistem / Açık / Koyu
- `Metin ve erişilebilirlik` yalnız özel ayar gerçekten gerekirse; esas olarak sistem ayarına saygı.

## Veri
- `Yedekleme ve geri yükleme`
- `Arşivlenen veriler`

## Uygulama
- `Hakkında Ölçerim`
- `Sürüm`
- `Gizlilik`
- `Destek`

Ayarlar standart grouped list görünümündedir; kart duvarı yapılmaz.

---

# 27. Yedekleme ve geri yükleme

Bu ekran güven hissi vermeli ve veri kaybı riskini açık anlatmalıdır.

## 27.1 Üst durum kartı

```text
Verileriniz bu cihazda saklanıyor

Cihazınızı kaybetmeniz veya uygulamayı silmeniz durumunda
verileri geri getirmek için düzenli olarak yedek alın.
```

Primary: `Yedek oluştur`
Secondary: `Yedekten geri yükle`

Son yedek bilgisi uygulama bunu güvenilir biçimde izleyebiliyorsa:

`Son yedek: 14 Ağustos 2026, 21:42`

## 27.2 Yedek oluştur

Akış:

1. `Yedek oluştur`
2. parola/koruma yöntemi tasarım kararı kesinleştirilmişse güvenli giriş
3. veri hazırlanıyor progress
4. sistem share sheet

Kullanıcıya şifre unutulursa geri dönüş yoksa açık uyarı gösterilir.

Parola alanı:
- show/hide
- confirmation
- password manager/autofill engellenmez.

## 27.3 Restore — dosya seç

`Yedek dosyası seç`.

Dosya doğrulandıktan sonra **hemen restore yapılmaz**.

## 27.4 Restore önizleme

```text
Ölçerim yedeği
14 Ağustos 2026 · 21:42

6 sınıf
184 öğrenci
12 rubrik
28 değerlendirme

Veritabanı sürümü: 4
```

Uyarı:

`Geri yükleme, cihazdaki mevcut Ölçerim verilerini bu yedekteki verilerle değiştirecektir.`

Primary destructive-toned action:
`Yedeği geri yükle`

Secondary:
`İptal`

## 27.5 Restore progress

- modal kapatılamaz veya işlem güvenli şekilde iptal edilemiyorsa kapatma kontrolü yoktur.
- linear progress veya indeterminate + aşama:
  - `Yedek doğrulanıyor…`
  - `Veriler hazırlanıyor…`
  - `Geri yükleme tamamlanıyor…`

Başarı:

`✓ Veriler geri yüklendi`

Primary: `Sınıflara dön`

Hata:

`Yedek geri yüklenemedi. Mevcut verileriniz değiştirilmedi.`

Bu cümle atomik restore invariantını kullanıcı diline çevirir.

---

# 28. Arşivlenen veriler

Tabs/segmented:
- `Sınıflar`
- `Öğrenciler`
- `Rubrikler`

Satır eylemi:
- `Geri yükle`

Kalıcı silme 1.0'da şart değildir. Eğer eklenirse ayrı riskli akış olarak tasarlanmalıdır.

---

# 29. Hazır rubrik şablonları

Lansman paketine dahil edilirse şablon galerisi:

- Sözlü Sunum
- Konuşma Becerisi
- Proje Değerlendirme
- Grup Çalışması
- Okuma Becerisi
- Yazma Becerisi

Kart:

```text
Konuşma Becerisi
5 kriter · 100 puan

İçerik, akıcılık, telaffuz, beden dili, süre kullanımı

[ Önizle ]   [ Kullan ]
```

`Kullan` doğrudan immutable sistem şablonunu düzenlemez; kullanıcı için kopya oluşturur.

---

# 30. Empty, loading, error ve permission durumları

## 30.1 Empty state standardı

Her empty state üç parçadan oluşur:

1. ne eksik?
2. kullanıcı neden bunu eklemeli?
3. tek ana CTA.

Generic `Kayıt bulunamadı` kullanılmaz.

## 30.2 Loading

Yerel DB ekranında uzun tam ekran spinner kullanılmaz. Eğer query hızlıysa doğrudan içerik.

Import/export/backup gibi dosya işlemlerinde progress + açıklama.

## 30.3 Error

Hata mesajı:

```text
Ne oldu?
Kullanıcı ne yapabilir?
```

Örnek:

Yanlış:
`SqliteException(2067)`

Doğru:
`Bu öğrenci numarası sınıfta zaten kullanılıyor. Farklı bir numara girin.`

## 30.4 Dosya izinleri

Platform izinleri “önceden” istenmez. Kullanıcı dosya seçme/paylaşma eylemini başlattığında sistem picker/share sheet kullanılır.

---

# 31. Erişilebilirlik

Minimum standartlar:

- Dokunma hedefi `>= 48x48 dp`.
- Metin ölçeği büyüdüğünde ana akış bozulmamalı.
- Renk hiçbir statusun tek taşıyıcısı olmamalı.
- `Semantics` label'ları ikon butonlarda zorunlu.
- VoiceOver/TalkBack sırası görsel sırayla uyumlu.
- Tablo hücrelerinde `Öğrenci + kriter + değer` birlikte okunabilir semantic label.
- Focus indicator desktop'ta görünür.
- Keyboard-only gradebook kullanımı mümkün olmalı.
- Dialog focus trap doğru uygulanmalı.
- Animasyonlar kısa; sistem reduced motion tercihi varsa azaltılmalı.

Örnek hücre semantiği:

`Ayşe Demir, Akıcılık, 17 üzerinden 20`.

---

# 32. Motion ve mikro etkileşim

Ölçerim eğlence uygulaması gibi animasyon kullanmaz.

Standart:

- route transition: platform varsayılanı.
- kart state değişimi: `150–200 ms`.
- chip/selection: `120–180 ms`.
- progress değişimi: yumuşak ama gecikmesiz.

Yasak:

- değerlendirmede her puanda confetti,
- bounce animasyonu,
- uzun success ekranları,
- veri girişini bekleten geçişler.

---

# 33. Microcopy standardı

Dil Türkçe ve eylem odaklıdır.

## Butonlar

İyi:
- `Sınıf oluştur`
- `29 öğrenciyi içe aktar`
- `Değerlendirmeyi başlat`
- `Yedek oluştur`

Kaçınılacak:
- `Tamam`
- `Devam`
- `İşlem yap`

Eylem bağlamdan açık değilse fiil + nesne kullanılır.

## Hata

Suçlayıcı dil yok.

Yanlış:
`Geçersiz veri girdiniz.`

Doğru:
`Maksimum puan 0'dan büyük olmalıdır.`

## Veri güvenliği

Yedekleme ve restore metinleri teknik olmayan ama kesin olmalıdır.

---

# 34. Platform özel davranışlar

## Android

- Material 3 navigation ve sistem back.
- Scoped Storage ile sistem picker/share akışı.
- Edge-to-edge layout, safe insets.

## iOS / iPadOS

- sistem share sheet.
- swipe-back route davranışı uygun ekranlarda korunur.
- iPad'de split/master-detail kullanımı.
- text input ve keyboard inset dikkatle yönetilir.

## macOS

- geniş sidebar.
- hover ve tooltips.
- keyboard shortcuts.
- pencere minimum boyutu ürün akışını kırmayacak seviyede tanımlanır; hedef minimum içerik yaklaşık `900x600` değerlendirilmelidir.
- resize sırasında layout breakpoint'lere göre canlı adapte olur.

---

# 35. Tasarımın Flutter'a uygulanması

## 35.1 Önerilen theme token yapısı

```text
lib/app/theme/
├── app_theme.dart
├── app_colors.dart
├── app_spacing.dart
├── app_radius.dart
├── app_typography.dart
└── app_component_themes.dart
```

Hard-coded renk/spacing ekran dosyalarına dağılmamalıdır.

## 35.2 Responsive yardımcıları

```text
lib/app/layout/
├── app_breakpoints.dart
├── adaptive_scaffold.dart
└── content_constraints.dart
```

Telefon/tablet/Mac için üç ayrı business screen kopyası yaratmak yerine shared domain/controller + adaptive presentation tercih edilir. Ancak gradebook gibi gerçekten farklı yoğunluk isteyen ekranlarda ayrı layout widget'ları olabilir.

## 35.3 Ortak bileşenler

```text
lib/core/widgets/
├── app_empty_state.dart
├── app_error_state.dart
├── app_status_chip.dart
├── app_section_header.dart
├── app_confirm_dialog.dart
├── app_async_action_button.dart
└── app_save_status.dart
```

Her feature kendi özel widget'ını feature altında tutar.

---

# 36. Screen map

Ölçerim 1.0'ın tasarlanmış ekran envanteri:

```text
App Launch
└── Welcome

Sınıflar
├── Class List
├── Create/Edit Class
├── Class Detail / Student Roster
├── Add/Edit Student
└── Student Import
    ├── File Select
    ├── Column Mapping
    ├── Validation Preview
    └── Import Result

Değerlendirmeler
├── Assessment List
├── New Assessment
├── Assessment Detail
├── Phone Evaluation Session
├── Tablet/Mac Gradebook Session
├── Quick Rating Session
├── Class Results
└── Student Result Detail

Rubrikler
├── Rubric Library
├── Simple Rubric Editor
├── Advanced Rubric Editor
└── Template Preview

Raporlar
├── Report Types
├── Report Filters
└── Report Preview / Export

Ayarlar
├── Settings Home
├── Backup & Restore
│   ├── Create Backup
│   ├── Restore File Select
│   ├── Restore Metadata Preview
│   ├── Restore Progress
│   └── Restore Result
├── Archived Data
├── Privacy
└── About / Support
```

---

# 37. UX kabul kriterleri

## Sınıf oluşturma

- Boş uygulamadan ilk sınıfı oluşturmak için kullanıcı navigasyonda kaybolmaz.
- Form tek ekrana sığar veya doğal scroll ile tamamlanır.
- Duplicate açıklaması teknik değildir.

## Import

- Kullanıcı import öncesi hangi satırların kaydolacağını bilir.
- Hatalı satırlar tek tek görülebilir.
- UI ağır dosyada donmaz.

## Rubrik

- 5 kriterli rubrik telefonda rahat oluşturulur.
- Kriter sırası erişilebilir biçimde değiştirilebilir.
- Toplam puan sürekli görünür.

## Değerlendirme

- Puan girişi auto-save.
- Sonraki öğrenciye geçmek tek açık eylem.
- Eksik kriter kullanıcıyı bloke etmez ama görünür kalır.
- Tablet/Mac'te klavye ile hücreler arasında dolaşılabilir.

## Sonuç

- Öğretmen sınıf ortalamasını, eksik sayısını ve kriter ortalamalarını ilk viewport'ta görür.
- Öğrenci detayına tek tıklama/tap.

## Rapor

- PDF önizlenebilir.
- Kullanıcı standart sistem paylaşımına ulaşabilir.
- Sandbox file path kullanıcıya ana çıktı olarak sunulmaz.

## Backup/restore

- Backup çıkışı sistem share sheet ile kullanıcıya teslim edilir.
- Restore öncesi metadata gösterilir.
- Başarısız restore mevcut veriyi değiştirmediğini açıkça söyler.

---

# 38. Golden / responsive test matrisi

Kritik ekranlar en az şu viewportlarda kontrol edilir:

| Profil | Örnek viewport |
|---|---|
| Küçük telefon | `360 x 800` |
| Standart telefon | `390 x 844` |
| Büyük telefon | `430 x 932` |
| Tablet portrait | `834 x 1194` |
| Tablet landscape | `1194 x 834` |
| Mac küçük pencere | `1024 x 700` |
| Mac standart | `1440 x 900` |

Golden/test önceliği:

1. Welcome
2. Class List
3. Import Preview
4. Rubric Editor
5. Phone Evaluation
6. Gradebook Evaluation
7. Results
8. Backup Restore Preview

Text scale için en az `1.0`, `1.3`, `2.0` senaryoları kritik ekranlarda kontrol edilir.

---

# 39. UX'te özellikle yapılmayacaklar

1. Ana ekrana gereksiz dashboard chart'ları doldurmak.
2. Öğretmeni puan vermek için birden fazla modal zincirinden geçirmek.
3. Her alan değişiminde snackbar göstermek.
4. Öğrenci listesini kart içinde kart yapılarıyla şişirmek.
5. Telefon gradebook'unu masaüstü tablosunu küçülterek üretmek.
6. Mac ekranını yalnız büyük telefon UI'ı gibi göstermek.
7. Renkleri not/başarı yargısının tek taşıyıcısı yapmak.
8. Kalıcı silmeyi hızlı swipe hareketine bağlamak.
9. Backup dosyasını yalnız uygulama sandbox'ında bırakmak.
10. UI'da `DAO`, `SQLite`, `migration`, `schema`, `exception` gibi teknik terimler göstermek.
11. 1.0 dışı AI/OCR/cloud öğeleri için disabled butonlar veya “yakında” alanları ekleyerek UI'ı şişirmek.

---

# 40. Tasarım kararlarının önceliği

Geliştirme sırasında bir ekran tasarımıyla ilgili çelişki oluşursa karar sırası:

1. [`PRODUCT_SCOPE.md`](PRODUCT_SCOPE.md) — ürün kapsamı ve sınırlar
2. Bu belge — UX ve görsel davranış
3. [`ROADMAP.md`](ROADMAP.md) — geliştirme sırası
4. Mevcut implementasyon

Yani mevcut kod, bu UX belgesiyle çelişiyorsa ve ürün kapsamı aksini söylemiyorsa **kod tasarıma göre değiştirilir**; belge mevcut yanlış implementasyonu meşrulaştırmak için değiştirilmez.

---

# 41. Ölçerim 1.0 tasarım özeti

Ölçerim 1.0'ın tasarım karakteri şu cümleyle özetlenir:

> **Sakin yüzeyler, net indigo vurgu, büyük ve anlaşılır eylemler, telefonlarda öğrenci odaklı akış, tablet ve Mac'te güçlü tablo deneyimi, otomatik kayıt ve her kritik veri işleminde güven veren açık geri bildirim.**

Bu spesifikasyon, tasarım/uygulama sırasında varsayılan kaynak olarak kullanılmalıdır. Yeni bir 1.0 ekranı eklenirse önce `PRODUCT_SCOPE.md` ile kapsamı doğrulanmalı, sonra bu dokümana ekran davranışı eklenmelidir.
