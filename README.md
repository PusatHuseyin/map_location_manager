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

- Providers: State management için 'Provider' paketini kullandım. UI ve Business Logic'i birbirinden ayırdım.
- Services: Veritabanı ve konum servislerini ayrı sınıflar olarak yazdım ('DatabaseService', 'LocationService').
- Models: Veri tutarlılığı için güçlü tip tanımları (LocationModel, RouteModel) kullandım.
- Core: Uygulama genelindeki sabitleri, temaları ve yardımcı fonksiyonları burada topladım.

# Veritabanı Yapısı (SQLite)

Veritabanı: 'map_location_manager.db'

'locations' - Kaydedilen konumlar
- sql
CREATE TABLE locations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL
)


'routes' - Kaydedilen rotalar
- sql
CREATE TABLE routes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  total_distance REAL,
  duration INTEGER
)


'route_points' - Rota GPS noktaları
- sql
CREATE TABLE route_points (
  id TEXT PRIMARY KEY,
  route_id TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  timestamp TEXT NOT NULL,
  speed REAL,
  accuracy REAL,
  FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE CASCADE
)
CREATE INDEX idx_route_points_route_id ON route_points(route_id)


# API Key

Projede test amaçlı Google Maps API Key tanımlı: 'android/app/src/main/AndroidManifest.xml'

xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyCIY75THHoQNZU5J0SD3AsxovqvM2VBp7s" />