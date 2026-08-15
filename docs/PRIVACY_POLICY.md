# Ölçerim Gizlilik Politikası — Taslak 1.0

Son güncelleme: 15 Ağustos 2026

Ölçerim, öğretmenlerin öğrenci performans değerlendirmelerini kendi cihazlarında tutmasına yardımcı olan yerel-öncelikli bir uygulamadır.

## Uygulama tarafından işlenen veriler

Öğretmen uygulamaya sınıf, öğrenci adı, okul numarası, rubrik, değerlendirme puanı ve öğretmen notu girebilir. Bu bilgiler Ölçerim 1.0'da cihazdaki yerel SQLite veritabanında saklanır.

## Sunucu ve hesap

Ölçerim 1.0'ın temel uygulamasında Ölçerim hesabı, uygulama sunucusu veya otomatik bulut senkronizasyonu yoktur. Uygulama öğrenci değerlendirme verisini geliştiricinin sunucusuna göndermez.

## Dosya içe/dışa aktarma

Kullanıcı Excel/CSV sınıf listesi seçebilir ve PDF/Excel/CSV raporu oluşturabilir. Dosya seçimi ve paylaşımı işletim sisteminin dosya seçici / paylaşım mekanizmaları üzerinden, kullanıcının başlattığı işlem sonucunda yapılır.

## Yedekleme

Kullanıcı manuel olarak şifreli Ölçerim yedeği oluşturabilir. Yedek AES-GCM authenticated encryption ile korunur ve kullanıcı sistem paylaşım ekranından istediği hedefe aktarır. Ölçerim bu dosyanın kullanıcı tarafından hangi üçüncü taraf servise gönderildiğini yönetmez.

## Tracking ve reklam

Ölçerim 1.0 uygulama içi reklam, çapraz uygulama tracking veya davranışsal reklam profili kullanmaz.

## Analitik

Ölçerim 1.0 uzaktan ürün analitiği veya crash telemetry göndermeyecek şekilde tasarlanmıştır. Uygulama içi teknik loglar cihaz dışına otomatik gönderilmez.

## Veri silme

Öğretmen sınıf, öğrenci ve rubrikleri uygulamada arşivleyebilir. Uygulamanın cihazdan kaldırılması yerel uygulama verilerini platformun normal kaldırma davranışına göre silebilir; bu nedenle önemli veriler için manuel şifreli yedek önerilir.

## Çocuklar ve öğrenciler

Ölçerim öğrencilerin doğrudan kullandığı bir hesap sistemi değildir. Öğrenci verisini uygulamaya giren öğretmen/kurum, yürürlükteki veri koruma ve kurum politikalarına uygun kullanım sorumluluğunu taşır.

## Değişiklikler

Uygulamaya bulut, hesap, telemetry veya başka veri işleme özelliği eklenirse bu politika ve store privacy beyanları yayınlanmadan önce güncellenmelidir.

## İletişim

Yayın öncesinde store listing'de kullanılacak destek ve gizlilik iletişim adresi eklenmelidir. Bu alan gerçek destek kanalı kesinleşmeden uydurma adresle doldurulmaz.
