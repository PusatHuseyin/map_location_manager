// merkezi string sabitleri
class AppStrings {
  // App infos
  static const String appName = 'Harita & Konum Yönetimi';

  // general
  static const String ok = 'Tamam';
  static const String cancel = 'İptal';
  static const String save = 'Kaydet';
  static const String delete = 'Sil';
  static const String edit = 'Düzenle';
  static const String retry = 'Tekrar Dene';
  static const String loading = 'Yükleniyor...';
  static const String refresh = 'Yenile';
  static const String search = 'Ara';
  static const String filter = 'Filtrele';
  static const String sort = 'Sırala';
  static const String share = 'Paylaş';
  static const String export = 'Dışa Aktar';
  static const String settings = 'Ayarlar';

  // navigation
  static const String locations = 'Konumlar';
  static const String map = 'Harita';
  static const String routes = 'Rotalar';
  static const String analytics = 'Analitik';

  // locations
  static const String addLocation = 'Yeni Konum Ekle';
  static const String editLocation = 'Konumu Düzenle';
  static const String deleteLocation = 'Konumu Sil';
  static const String locationName = 'Konum Adı';
  static const String locationNameHint = 'Örnek: Evim, İşyerim';
  static const String latitude = 'Enlem (Latitude)';
  static const String longitude = 'Boylam (Longitude)';
  static const String description = 'Açıklama';
  static const String descriptionHint = 'Konum hakkında notlar';
  static const String useCurrentLocation = 'Mevcut konumumu kullan';
  static const String noLocations = 'Henüz konum eklenmemiş';
  static const String noLocationsSubtitle =
      'Yeni konum eklemek için + butonuna basın';
  static const String locationAdded = 'Konum başarıyla eklendi';
  static const String locationUpdated = 'Konum başarıyla güncellendi';
  static const String locationDeleted = 'Konum silindi';
  static const String deleteLocationConfirm =
      'konumunu silmek istediğinize emin misiniz?';
  static const String locationAddError = 'Konum eklenirken hata oluştu';
  static const String locationUpdateError = 'Konum güncellenirken hata oluştu';
  static const String locationDeleteError = 'Konum silinirken hata oluştu';
  static const String locationsLoadError = 'Konumlar yüklenirken hata oluştu';
  static const String currentLocationError =
      'Mevcut konum alınamadı. İzinleri kontrol edin.';

  // Validation
  static const String nameRequired = 'Konum adı gerekli';
  static const String latitudeRequired = 'Enlem gerekli';
  static const String longitudeRequired = 'Boylam gerekli';
  static const String invalidLatitude =
      'Geçerli bir enlem girin (-90 ile 90 arası)';
  static const String invalidLongitude =
      'Geçerli bir boylam girin (-180 ile 180 arası)';

  // Routes
  static const String startTracking = 'Başlat';
  static const String stopTracking = 'Bitir';
  static const String routeName = 'Rota Adı';
  static const String routeNameHint = 'Örnek: Sabah Koşusu';
  static const String saveRoute = 'Rotayı Kaydet';
  static const String deleteRoute = 'Rotayı Sil';
  static const String deleteRouteConfirm =
      'rotasını silmek istediğinize emin misiniz?';
  static const String noRoutes = 'Henüz rota kaydedilmemiş';
  static const String noRoutesSubtitle =
      'Harita ekranından rota kaydı başlatın';
  static const String routeSaved = 'Rota başarıyla kaydedildi';
  static const String routeDeleted = 'Rota silindi';
  static const String routeDeleteError = 'Rota silinirken hata oluştu';
  static const String routesLoadError = 'Rotalar yüklenirken hata oluştu';
  static const String routeDetails = 'Rota Detayları';
  static const String routeExported = 'Rota GPX formatında dışa aktarıldı';
  static const String routeExportError = 'Rota dışa aktarılırken hata oluştu';

  // Route Stats
  static const String distance = 'Mesafe';
  static const String duration = 'Süre';
  static const String avgSpeed = 'Ort. Hız';
  static const String maxSpeed = 'Maks. Hız';
  static const String points = 'Nokta';
  static const String startTime = 'Başlangıç';
  static const String endTime = 'Bitiş';

  // Map
  static const String myLocation = 'Konumum';
  static const String addLocationOnMap = 'Haritaya Konum Ekle';
  static const String longPressToAdd = 'Konum eklemek için haritaya uzun basın';
  static const String mapType = 'Harita Türü';
  static const String normal = 'Normal';
  static const String satellite = 'Uydu';
  static const String terrain = 'Arazi';
  static const String hybrid = 'Hibrit';

  // Permissions
  static const String locationPermissionDenied = 'Konum izni reddedildi';
  static const String locationPermissionRequired = 'Konum izni gerekli';
  static const String locationServiceDisabled = 'Konum servisi kapalı';
  static const String enableLocationService = 'Lütfen konum servisini açın';
  static const String openSettings = 'Ayarları Aç';

  // Settings
  static const String theme = 'Tema';
  static const String lightMode = 'Açık Tema';
  static const String darkMode = 'Koyu Tema';
  static const String systemMode = 'Sistem';
  static const String units = 'Birimler';
  static const String metric = 'Metrik (km)';
  static const String imperial = 'İngiliz (mi)';
  static const String dataManagement = 'Veri Yönetimi';
  static const String clearCache = 'Önbelleği Temizle';
  static const String exportAllData = 'Tüm Verileri Dışa Aktar';
  static const String about = 'Hakkında';
  static const String version = 'Versiyon';
  static const String licenses = 'Lisanslar';

  // Errors
  static const String errorOccurred = 'Bir hata oluştu';
  static const String tryAgain = 'Tekrar deneyin';
  static const String pullToRefresh = 'veya aşağı çekin';
  static const String noInternetConnection = 'İnternet bağlantısı yok';
  static const String serverError = 'Sunucu hatası';
  static const String unknownError = 'Bilinmeyen hata';
}
