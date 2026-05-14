import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/category.dart';

void main() {
  group('CategoryLevel', () {
    final validJson = {
      'cat_level_id': 1,
      'cat_level_name': 'Danger',
      'cat_level_ttl_mins': 60,
    };

    test('fromJson maps all fields correctly', () {
      final level = CategoryLevel.fromJson(validJson);

      expect(level.catLevelId, 1);
      expect(level.catLevelName, 'Danger');
      expect(level.catLevelTtlMins, 60);
    });

    test('fromJson reads cat_level_ttl_mins into catLevelTtlMins', () {
      // Regression: this key was previously mis-mapped (catLevelPins).
      final level = CategoryLevel.fromJson({...validJson, 'cat_level_ttl_mins': 120});
      expect(level.catLevelTtlMins, 120);
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('cat_level_ttl_mins');
      expect(
        () => CategoryLevel.fromJson(incomplete),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Category', () {
    final validJson = {
      'cat_id': 2,
      'cat_level_id': 1,
      'cat_name': 'Hazard',
    };

    test('fromJson maps all fields correctly', () {
      final category = Category.fromJson(validJson);

      expect(category.catId, 2);
      expect(category.catLevelId, 1);
      expect(category.catName, 'Hazard');
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)..remove('cat_name');
      expect(() => Category.fromJson(incomplete), throwsA(isA<TypeError>()));
    });
  });

  group('SubCategory', () {
    final validJson = {
      'sub_cat_id': 3,
      'cat_id': 2,
      'sub_cat_name': 'Spillage',
    };

    test('fromJson maps all fields correctly', () {
      final subCategory = SubCategory.fromJson(validJson);

      expect(subCategory.subCatId, 3);
      expect(subCategory.catId, 2);
      expect(subCategory.subCatName, 'Spillage');
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('sub_cat_name');
      expect(() => SubCategory.fromJson(incomplete), throwsA(isA<TypeError>()));
    });
  });
}
