/// Data class for pin creation form submission
class PinFormData {
  final int catId;
  final int? subCatId;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final int ttlMinutes;

  PinFormData({
    required this.catId,
    this.subCatId,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.ttlMinutes,
  });

  DateTime get expiresAt => DateTime.now().add(Duration(minutes: ttlMinutes));

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'cat_id': catId,
      'sub_cat_id': subCatId,
      'pin_title': title,
      'pin_description': description,
      'pin_latitude': latitude,
      'pin_longitude': longitude,
      'pin_expire_at': expiresAt.toIso8601String(),
    };
  }
}
