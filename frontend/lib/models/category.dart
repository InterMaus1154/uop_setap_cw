class CategoryLevel {
  final int catLevelId;
  final String catLevelName;
  final int catLevelPins;

  CategoryLevel({
    required this.catLevelId,
    required this.catLevelName,
    required this.catLevelPins,
  });

  factory CategoryLevel.fromJson(Map<String, dynamic> json) {
    return CategoryLevel(
      catLevelId: json['cat_level_id'],
      catLevelName: json['cat_level_name'],
      catLevelPins: json['cat_level_pins'],
    );
  }
}

class Category {
  final int catId;
  final int catLevelId;
  final String catName;

  Category({
    required this.catId,
    required this.catLevelId,
    required this.catName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      catId: json['cat_id'],
      catLevelId: json['cat_level_id'],
      catName: json['cat_name'],
    );
  }
}

class SubCategory {
  final int subCatId;
  final int catId;
  final String subCatName;

  SubCategory({
    required this.subCatId,
    required this.catId,
    required this.subCatName,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      subCatId: json['sub_cat_id'],
      catId: json['cat_id'],
      subCatName: json['sub_cat_name'],
    );
  }
}
