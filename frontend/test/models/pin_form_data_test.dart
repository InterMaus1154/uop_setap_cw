import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/pin_form_data.dart';

void main() {
  group('PinFormData', () {
    PinFormData build({
      int? subCatId = 3,
      String? description = 'Near the library',
      int ttlMinutes = 60,
      DateTime? customExpiry,
    }) {
      return PinFormData(
        catId: 2,
        subCatId: subCatId,
        title: 'Lost wallet',
        description: description,
        latitude: 50.798,
        longitude: -1.098,
        ttlMinutes: ttlMinutes,
        customExpiry: customExpiry,
      );
    }

    test('toJson produces correct backend keys', () {
      final json = build().toJson();

      expect(json['cat_id'], 2);
      expect(json['sub_cat_id'], 3);
      expect(json['pin_title'], 'Lost wallet');
      expect(json['pin_description'], 'Near the library');
      expect(json['pin_latitude'], 50.798);
      expect(json['pin_longitude'], -1.098);
      expect(json.containsKey('pin_expire_at'), true);
    });

    test('toJson includes null sub_cat_id and description when absent', () {
      final json = build(subCatId: null, description: null).toJson();

      expect(json.containsKey('sub_cat_id'), true);
      expect(json['sub_cat_id'], isNull);
      expect(json.containsKey('pin_description'), true);
      expect(json['pin_description'], isNull);
    });

    test('expiresAt uses customExpiry when provided', () {
      final custom = DateTime(2030, 1, 1, 12);
      final formData = build(customExpiry: custom);
      expect(formData.expiresAt, custom);
    });

    test('expiresAt is computed from ttlMinutes when no customExpiry', () {
      final before = DateTime.now().add(const Duration(minutes: 60));
      final formData = build(ttlMinutes: 60);
      final after = DateTime.now().add(const Duration(minutes: 60));

      // Computed expiry should land between the two reference points.
      expect(
        formData.expiresAt.isAfter(before.subtract(const Duration(seconds: 5))),
        true,
      );
      expect(
        formData.expiresAt.isBefore(after.add(const Duration(seconds: 5))),
        true,
      );
    });

    test('toJson serialises expiresAt as an ISO 8601 string', () {
      final custom = DateTime(2030, 1, 1, 12);
      final json = build(customExpiry: custom).toJson();
      expect(json['pin_expire_at'], custom.toIso8601String());
    });
  });
}
