# Sprint E — Hızlı Notlandırma Akışını Tamamlama

## Amaç

Ölçerim'in çekirdek öğretmen akışındaki iki UX boşluğunu kapatmak:

1. Değerlendirme oluşturulduktan sonra kullanıcıyı yeniden listeye döndürmeden doğrudan puanlama ekranına geçirmek.
2. Rubrik kurmadan klasik okul kullanımı için 0–100 arası hızlı not girişi sağlamak.

## Mimari kararlar

- Yeni assessment tipi eklenmeyecek.
- 0–100 not girişi mevcut `quickScale` domain'i içinde sürekli sayısal preset olarak tutulacak.
- DB şeması değişmeyecek; migration gerekmeyecek.
- Puan yazımı için yalnız mevcut canonical yol kullanılacak:

```text
QuickScaleGradingView
→ EvaluationRepository.score()
→ EvaluationDao.upsertScore()
→ SQLite
```

- `EvaluationDao` içindeki 0..maxScore doğrulaması korunacak; UI ikinci bir bağımsız doğrulama motoru oluşturmayacak.

## İş paketleri

### E1 — Oluştur ve doğrudan puanla

- `CreateAssessmentView` başarıyla assessment oluşturduğunda oluşturma ekranını uygun puanlama ekranıyla değiştirecek.
- Rubrik değerlendirmesi → `GradingSessionView`
- Hızlı derecelendirme → `QuickScaleGradingView`
- Geri tuşu kullanıcıyı assessment oluşturduğu önceki ekrana döndürecek.

**Kabul kriteri:**

```text
Sınıf
→ Değerlendirme başlat
→ oluştur
→ doğrudan puanlama
```

arasında ek sekme/list navigasyonu gerekmemeli.

### E2 — 0–100 hızlı not preset'i

- `QuickScalePreset.numericHundred` eklenecek.
- Tek kriter `maxScore = 100` olacak.
- Rubrik seviyesi üretilmeyecek; bu preset sürekli sayısal giriş olarak yorumlanacak.

**Kabul kriteri:** 0–100 arası puan canonical score path ile kaydedilmeli; 100 üzeri değer DAO tarafından reddedilmeli.

### E3 — Hızlı sayısal giriş UI

- Her öğrenci kartında doğrudan puan alanı bulunacak.
- Enter/Next ile kaydetme desteklenmeli.
- Dokunmatik kullanım için açık bir kaydet aksiyonu bulunmalı.
- Mevcut puan tekrar açıldığında görünmeli.
- Öğretmen notu, kriter notu ve gözlem notu davranışı korunmalı.

### E4 — Regresyon koruması

- 0–100 preset'in tek kriter ve sıfır level oluşturduğu test edilmeli.
- 87 gibi geçerli bir puanın sonuçlara yansıdığı doğrulanmalı.
- 101 gibi sınır dışı puanın reddedildiği doğrulanmalı.
- Mevcut 1–5 ve sözel quick-scale testleri korunmalı.

## Sprint çıkış kriteri

- Sınıf → öğrenci → değerlendirme → doğrudan puanlama zinciri kesintisiz.
- 0–100 hızlı notlandırma rubrik kurmadan kullanılabilir.
- Puanlar mevcut SQLite/repository/DAO zincirinden kaydedilir.
- Mevcut quick-scale davranışlarında regression oluşmaz.
- Analyze/test kalite kapısı yeşildir.
