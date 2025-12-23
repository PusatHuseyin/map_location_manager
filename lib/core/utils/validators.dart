// Input validation utilities
class Validators {
  // Validates required fields
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  // Validates latitude (-90 to 90)
  static String? latitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enlem gerekli';
    }

    final lat = double.tryParse(value);
    if (lat == null) {
      return 'Geçerli bir sayı girin';
    }

    if (lat < -90 || lat > 90) {
      return 'Enlem -90 ile 90 arası olmalıdır';
    }

    return null;
  }

  // Validates longitude (-180 to 180)
  static String? longitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Boylam gerekli';
    }

    final lng = double.tryParse(value);
    if (lng == null) {
      return 'Geçerli bir sayı girin';
    }

    if (lng < -180 || lng > 180) {
      return 'Boylam -180 ile 180 arası olmalıdır';
    }

    return null;
  }

  static String? minLength(String? value, int min, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }

    if (value.trim().length < min) {
      return '$fieldName en az $min karakter olmalıdır';
    }

    return null;
  }

  static String? maxLength(String? value, int max, String fieldName) {
    if (value != null && value.trim().length > max) {
      return '$fieldName en fazla $max karakter olmalıdır';
    }

    return null;
  }

  static String? numeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName geçerli bir sayı olmalıdır';
    }

    return null;
  }

  static String? range(
    String? value,
    double min,
    double max,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }

    final num = double.tryParse(value);
    if (num == null) {
      return '$fieldName geçerli bir sayı olmalıdır';
    }

    if (num < min || num > max) {
      return '$fieldName $min ile $max arası olmalıdır';
    }

    return null;
  }
}
