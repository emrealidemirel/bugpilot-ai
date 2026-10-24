# Hazırlık sonrası durum — 24 Ekim 2026

Backend kullanıcının isteğiyle eklenmedi. Bu nedenle uygulama henüz mağazaya dağıtılmaya hazır değildir; aşağıdaki ilk denetim bulguları tarihsel kayıttır.

Doğrulama: `flutter analyze` temiz; 135/135 Flutter testi geçti; Android debug APK ve iOS Simulator debug uygulaması derlendi. Android release AAB, imza dosyası olmadan beklenen açık hata ile durdu. `git diff --check` temiz.

Tamamlananlar: şifreli rapor ve ayar depoları, şifreli profil fotoğrafı migrasyonu, açık onaylı eski rapor aktarımı, hesap değişiminde ekran/taslak sıfırlama, e-posta doğrulama ve AI paylaşım onayı, yeniden kimlik doğrulamalı hesap silme ve kesilen yerel temizliğin yeniden denenmesi, başlangıç hatalarında tekrar deneme, Android yedekleme kısıtları, debug imzasıyla release üretiminin engellenmesi, HTTP istemcilerinin kapatılması, mock servislerin test dizinine taşınması ve artık olmayan backend CI işinin kaldırılması. Hesap silme ve önceki cihaz raporu aktarımı Ayarlar içindeki üst ikonlu “Hesap ve veriler” bölümünde toplandı.

Sınırlar: ekran görüntüleri uygulama sandbox'ında dosya olarak tutulur; aktarılmamış eski rapor kutusu henüz şifreli değildir. Yeni veriler hesap bazında şifrelidir. Yerel veriler cihazlar arasında senkronize edilmez. Hesap silme bu cihazdaki kopyaları temizler; başka cihazların çevrimdışı kopyalarını uzaktan silemez.

API anahtarı yalnızca özel debug kullanımında okunur; profile/release AI güvenli sunucu hazırlanmadığından çalışmaz. `.env` dosyasının Git dışında kalması derlenmiş debug uygulamasındaki anahtarı gizlemez. README'de bu ayrım ve kalan kurulumlar açıklanmıştır.

Kalan dış bağımlılıklar: güvenli AI sunucusu, kalıcı uygulama kimlikleri ve yayın imzaları, Apple giriş konsol/capability kurulumu, gerçek yasal URL/iletişim bilgileri ve harici hesap silme talep adresi, Firebase konsol denetimi, gerçek cihaz ve mağaza doğrulamaları. Uygulama yayınlanmadı, backend dağıtılmadı, gerçek kullanıcı hesabı silinmedi.

“%100 clean code” veya koşulsuz güvenlik garantisi verilmez. Mevcut lib katman yapısı korundu; büyük ekranları gereksiz toplu yeniden yazmak yerine yeni güvenlik sorumlulukları ayrı servis/widget'lara ayrıldı. Testler dağıtılan pakete girmez ve silinmemelidir.

---

## İlk denetim (değişikliklerden önce)

# Yayına hazırlık incelemesi — 24 Ekim 2026

**Karar: Mevcut sürüm genel mağaza dağıtımına hazır değil.** İşlevsel bir geliştirme sürümü; premium/reklam eklenmesi aşağıdaki güvenlik ve yayın eksiklerini çözmez. İnceleme kaynak kodu, yerel testler ve derlemeler üzerindedir; Firebase/Google Cloud/mağaza konsollarının canlı yapılandırması denetlenmedi. Bu çalışma bir penetrasyon testi veya mağaza kabul garantisi değildir.

## Doğrulananlar

- Tam Flutter test paketi: **124 test geçti**.
- `flutter analyze`: **No issues found**. İlk eşzamanlı Flutter çalıştırmasında üretilen ephemeral dosya silme hatası vardı; testler bittikten sonraki bağımsız analiz başarılı.
- `git diff --check`: temiz.
- `flutter build appbundle --release`: başarılı, 58.8 MB AAB üretildi. Gerçek anahtar derlemeye verilmedi; bu yalnızca paketleme kontrolüdür, AI işlev testi değildir. Mevcut Gradle ayarı debug imzası kullandığı için bu artifact mağazaya yüklenmeye hazır sayılmaz. Firebase eklentileri için gelecekteki Flutter/Kotlin geçişine ilişkin uyarı çıktı; derleme hatası olmadı.
- Önceki aynı oturumda güncel iOS simulator debug build başarılı; profil, menü ve silme onayı görsel olarak incelendi. Gerçek cihaz release/TestFlight kontrolü yapılmadı.
- Bu denetimde canlı AI çağrısı tekrarlanmadı; önceki oturumda gerçek servis ve simülatör çağrısı başarılıydı. Otomatik testlerin bir kısmı mock/fake servis kullanır; canlı servis güvencesi sayılmaz.
- `.env`: dosya modu `0600`, Git tarafından dışlanıyor. Mevcut anahtar, izlenen çalışma dosyalarında ve yerelde mevcut tüm Git geçmişinde bulunmadı. Uzakta yerel geçmişte olmayan ref, issue, log ve eski anahtarlar bu taramanın kapsamı dışındadır.
- Anahtarın **derlenmiş iOS simülatör uygulamasında bulunduğu** yalnızca boolean sonuçla doğrulandı; anahtar yazdırılmadı.

## Yayından önce çözülmesi gerekenler

### 1. Kritik — OpenAI anahtarı istemci uygulamasına gömülüyor

Kanıt: `lib/constants/app_config.dart:2`, `lib/app/app.dart:107`, `lib/services/openai_responses_client.dart:150`.

`.env` ve `.gitignore` kaynak kodunu korur; `--dart-define-from-file` değerini mobil binary içinde gizlemez. Anahtarı çıkaran kişi uygulamadaki giriş ve ileride eklenecek premium sınırlarını atlayarak geliştirici hesabından API çağrısı yapabilir.

Gerekli: geliştirici anahtarını yalnızca sunucuda tutmak; backend'de Firebase ID token doğrulamak, kullanıcı bazlı kota/hız/istek boyutu sınırları ve harcama kontrolü uygulamak. Premium yetkisi de sunucuda doğrulanmalı. İstemciden gelen kullanıcı ID veya premium boolean değerine güvenilmemeli. Backend'e geçildikten sonra dağıtılmış test binary'leri varsa mevcut anahtar döndürülmeli.

### 2. Yüksek — Raporlar hesaplara göre izole değil

Kanıt: `lib/main.dart:25`, `lib/repositories/hive_bug_repository.dart:15`, `lib/repositories/hive_bug_repository.dart:38`, `lib/app/app.dart` içindeki tek repository yaşam döngüsü; `lib/models/bug_report.dart` içinde sahiplik alanı yok.

Hesap A çıkış yapıp aynı kurulumda B giriş yaptığında aynı `bug_reports` kutusu kullanılır. Kod akışına göre B, A'nın yerel raporlarını görebilir/değiştirebilir; mükerrer analiz adayları da bu ortak depodan gelir. Bu, iki gerçek hesapla canlı deneme değil, veri yolu incelemesiyle doğrulanmış bir izolasyon eksikliğidir.

Gerekli: UID bazlı repository, attachment dizinleri ve cache ayrımı; oturum değişiminde açık sayfa/taslak/async işlemlerin sıfırlanması. Mevcut ortak verinin hangi kullanıcıya taşınacağı ayrıca belirlenmeli; otomatik olarak yeni giriş yapan hesaba atanmamalı. A/B hesap geçiş testi eklenmeli.

### 3. Yüksek — Hesap silme yok

Kanıt: `lib/services/auth_service.dart`, `lib/services/firebase_auth_service.dart`, `lib/pages/auth/profile_page.dart`: kayıt/giriş/çıkış var, hesap silme işlemi yok. Yerel profil fotoğrafları için de silme API'si bulunmuyor.

Gerekli: yeniden kimlik doğrulama gerektiğinde bunu yöneten hesap silme akışı; Firebase hesabı, kullanıcının raporları, ekleri ve profil verilerinin uygun şekilde temizlenmesi. Google Play için uygulama dışından erişilen silme talebi web adresi de gerekli.

### 4. Yüksek — Gizlilik politikası ve AI paylaşım izni eksik

Kanıt: `lib/pages/settings/settings_page.dart:586` bilgilendirme satırları içeriyor, erişilebilir bir gizlilik politikası bağlantısı/izin akışı yok. `lib/models/app_settings.dart:12` ekran görüntüsü analizini varsayılan açık tutuyor. `lib/models/duplicate_check_request.dart` mevcut raporlardan aday içeriklerini de gönderiyor.

Gerekli: veri alıcısı OpenAI ve Firebase, gönderilen alanlar/ekler, saklama-silme politikası ve iletişim bilgilerinin açıklanması; kişisel veri üçüncü taraf AI'ye gitmeden açık izin; App Privacy / Data Safety beyanları. Loglar ve ekran görüntülerindeki sırlar için kullanıcıya inceleme/çıkarma imkânı. `store: false` olumlu; tek başına tüm sağlayıcı saklama politikalarının sıfırlandığı anlamına gelmez.

### 5. Yüksek — iOS giriş seçenekleri ve zorunlu hesap gerekçesi

Kanıt: `lib/services/firebase_auth_service.dart:70` Google girişi içeriyor; eşdeğer gizlilik özelliklerine sahip alternatif giriş yok. E-posta/parola seçeneği e-postayı gizleme özelliğini karşılamaz.

Apple 4.8 istisnalarından biri uygulanmıyorsa uygun eşdeğer giriş (genellikle Sign in with Apple) eklenmeli veya üçüncü taraf giriş tasarımı değişmeli. Ayrıca bugün raporlar yerel olduğu halde giriş zorunlu; Apple 5.1.1(v) açısından anlamlı hesap bazlı özellik gerekçesi değerlendirilmeli. Backend kotası/senkronizasyon gibi gerçek hesap özellikleri bu tasarım kararını değiştirir.

### 6. Yüksek — Yayın kimliği ve Android imzası geliştirme ayarında

Kanıt: `android/app/build.gradle.kts:24` örnek applicationId; release bloğu debug signing kullanıyor. `ios/Runner.xcodeproj/project.pbxproj:391` örnek bundle ID kullanıyor.

Gerekli: kalıcı uygulama kimlikleri, Android upload key/Play App Signing, iOS distribution provisioning ve Firebase/OAuth eşleştirmeleri. Gerçek Android/iPhone release testleri, Play internal testing ve TestFlight kontrolü yapılmalı. SDK/target API, 16 KB native uyumluluğu, privacy manifest ve mağaza formları nihai artifact ve güncel konsol gereksinimleriyle ayrıca doğrulanmalı.

### 7. Orta — CI'da bulunmayan backend çalıştırılıyor

Kanıt: `.github/workflows/ci.yml:24` backend job'u `backend/package-lock.json`, `npm ci/build/test` bekliyor; çalışma ağacında backend dizini yok. Bu job mevcut haliyle başarılı olamaz. Backend kurulacaksa gerçek projeye bağlanmalı; aksi halde eski job kaldırılmalı. Yerel test başarısı GitHub CI başarısı demek değil.

## Kod ağacı, clean code ve kullanılmayan kod

- Mevcut README'deki katmanlı düzen korunuyor: `app`, `pages`, `services`, `repositories`, `models`, `widgets`, `utils`. Ek bir kişisel stil belgesi bulunmadı; değerlendirme repo düzenine göredir.
- Analyzer kullanılmayan import/yerel değişken uyarısı üretmedi. Import grafiğinde `main.dart` üzerinden erişilmeyen iki lib dosyası mock AI servisleri; ikisi de testlerce kullanılıyor. Körlemesine silinmemeli; `test/support` altına taşınabilir. Bu tarama her public sembolün kullanıldığının ispatı değildir.
- `ai_analysis_page.dart` 1359, `report_bug_page.dart` 1034, `bug_detail_page.dart` 981 satır. Ekranlar UI ile form, diyalog ve işlem durumunu birlikte yönetiyor. Aynı mevcut ağaç içinde controller ve daha küçük widget'lara ayrılmaları bakım kolaylığı sağlar. Dosya uzunluğu tek başına hata değildir.
- Test ağacı kısmen `features/.../presentation/data/domain`, kısmen `test/pages` ve `test/services`; lib katmanlarıyla birebir tutarlı değil.
- Yerelleştirmede `context.l10n` ve doğrudan `.tr()` birlikte kullanılıyor. Radius/padding değerlerinin bir kısmı merkezi sabit, bir kısmı yerel. Bunlar standartlaştırılabilir; yayın engeli değiller.
- HTTP istemcisinin kapatma yaşam döngüsü açıkça yönetilmiyor. Uygulama boyunca kullanılan servislerde acil sızıntı kanıtı değil, kaynak sahipliğini netleştirme konusu.
- CI eski backend işi ve şablon release TODO'ları gerçek temizlik kalemleri. Mock test servisleri veya eski veri migrasyonlarını yalnızca isimlerinden dolayı gereksiz saymak doğru değil.

## Diğer güvenlik ve dayanıklılık kontrolleri

- Şifreler uygulamanın kendi Hive deposuna yazılmıyor; giriş Firebase SDK üzerinden yürütülüyor. Profil fotoğrafları UID ile anahtarlanmış. Bunlar olumlu.
- Firebase client config / Google client ID, OpenAI gizli anahtarıyla aynı tür sır değildir. Buna rağmen konsoldaki API restrictions, OAuth SHA değerleri, parola politikası, e-posta enumeration koruması ve kotalar ayrıca kontrol edilmeli; bu inceleme bunları doğrulamadı.
- E-posta doğrulama akışı yok. Özellikle ücretsiz AI kotası ve hesap suistimali için doğrulama, hız sınırı ve gerektiğinde App Check planlanmalı; App Check tek başına yetkilendirme değildir.
- Hive rapor/fotoğraf kutuları uygulama seviyesinde şifrelenmiyor; ekler uygulama belgeler dizinine yazılıyor. Bu, verinin internetten herkese açık olduğu anlamına gelmez. OS sandbox mevcut; hassas log/ekler için şifreleme ve yedekleme politikası belirlenmeli. Android özel backup kuralları yok.
- Başlangıçta Firebase/Hive açılışı için kullanıcıya sunulan kurtarma/retry ekranı yok (`main.dart`); açılış hataları ve bozuk depolama senaryoları test edilmeli.
- AI'ye gönderilen logların boyutu istemci formunda sınırsız; backend tarafında token/byte sınırı ve timeout/cancellation politikası olmalı.
- Gerçek hesap değişimi, e-posta sıfırlama, yeniden giriş, ağ kesintisi, izin reddi, veri göçü, iPad/büyük yazı ve Android fiziksel cihaz kontrollerinin tümü bu denetimde canlı yapılmadı. Test sayısı bu kapsamın yerine geçmez.

## Premium ve reklam için sıra

1. Backend + anahtar güvenliği + kullanıcı bazlı veri izolasyonu.
2. Hesap silme, uygun iOS giriş seçenekleri, gizlilik/AI izni.
3. CI ve release yapılandırması; gerçek cihaz kabul testleri.
4. Premium: hedef pazardaki kurallara göre StoreKit/Play Billing, sunucu doğrulamalı yetki, satın alımları geri yükleme, iptal/iade/yenileme senaryoları ve kullanıcı kotası.
5. Reklam: seçilecek SDK'nın veri akışı, gerekli bölgesel onaylar ve yalnızca tracking varsa ilgili ATT akışı; Data Safety/App Privacy güncellemesi. Henüz reklam SDK'sı bulunmuyor.

## Resmî kaynaklar

24 Ekim 2026'da kontrol edildi:

- OpenAI API key safety: https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety
- Apple App Review Guidelines (3.1, 4.8, 5.1.1, 5.1.2): https://developer.apple.com/app-store/review/guidelines/
- Apple account deletion: https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/
- Google account deletion: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en
- Google payments: https://support.google.com/googleplay/android-developer/answer/10281818?hl=en
