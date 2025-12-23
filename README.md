# Harita & Konum Yönetimi

Geliştirilen flutter projesi, 'Terra-Flutter-Task-v2.pdf' kapsamında istenen gereksinimleri karşılamak ve üzerine ek özellikler katarak geliştirdiğim flutter uygulamasıdır.

Uygulamanın temel amacı;
  Kullanıcıların harita üzerinde konumlarını yönetebilmesi, canlı konum takibi yapabilmesi ve rota kayıtlarını yerel veritabanında güvenli bir şekilde saklayabilmesidir.

# Proje Özellikleri ve Yaptıklarım

Görevin maddelerine uygun olarak geliştirdiğim özellikler şunlardır:

# 1. Konum Yönetimi (SQLite)
- Konum verilerinin kalıcı olması için 'sqflite' paketiyle yerel bir veritabanı yapısı kurdum.
- Kullanıcılar harita üzerinde istedikleri yere 'uzun basarak' veya manuel koordinat girerek konum ekleyebiliyor.
- Eklenen konumlar liste halinde görüntülenip güncellenebiliyor veya silinebiliyor.

# 2. Harita ve Görsellik
- 'Google Maps' entegrasyonunu tamamladım ve başlangıç noktası olarak istenen Konya konumunu ayarladım.
- Uygulamanın gece modunda da şık görünmesi için 'Dynamic Map Style' özelliği ekledim. Cihaz temasına göre harita otomatik olarak koyu moda geçiyor.
- Özel marker ikonları kullanarak kullanıcı deneyimini iyileştirdim.

# 3. Rota Kaydı
- 'geolocator' paketini kullanarak hassas konum takibi sağladım.
- "Başlat" butonuna basıldığında arka planda bir zamanlayıcı (timer) ve konum dinleyicisi çalışıyor.
- Rota kaydı sırasında geçen süre, toplam mesafe ve anlık hız gibi verileri kullanıcıya canlı olarak gösteriyorum.
- Geçmiş rotalar veritabanında, rotanın her bir noktasıyla (koordinat, zaman damgası) birlikte saklanıyor.

# Mimari ve Kod Yapısı

Projede sürdürülebilirlik ve test edilebilirlik açısından 'Clean Architecture' prensiplerine sadık kalmaya çalıştım. Klasör yapısını katmanlara ayırdım

- Providers: State management için `Provider` paketini kullandım. UI ve Business Logic'i birbirinden ayırdım.
- Services: Veritabanı ve konum servislerini ayrı sınıflar olarak yazdım (`DatabaseService`, `LocationService`).
- Models: Veri tutarlılığı için güçlü tip tanımları (LocationModel, RouteModel) kullandım.
- Core: Uygulama genelindeki sabitleri, temaları ve yardımcı fonksiyonları burada topladım.

# Kurulum Notları

Projeyi çalıştırmak için standart Flutter adımlarını takip edebilirsiniz:

1.  Bağımlılıkları yükleyin ardından uygulamayı çalıştırın:
    - flutter pub get
    - flutter run

Not: `AndroidManifest.xml` ve `Info.plist` dosyaları hali hazırda yapılandırılmıştır. Google Maps API Key tanımlıdir.
Şimdilik sadece 'android' için yapılandırılmıştır.

# Teslimat İçeriği

- Kaynak Kod: Tüm proje dosyaları.
- APK: build/app/outputs/flutter-apk/app-release.apk dizininde release edilmiş APK dosyası mevcuttur.