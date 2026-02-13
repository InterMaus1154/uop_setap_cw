class CategoryLevel {
  final int catLevelId;
  final String catLevelName;
  final int catLevelTtlMins;

  CategoryLevel({
    required this.catLevelId,
    required this.catLevelName,
    required this.catLevelTtlMins,
  });

  factory CategoryLevel.fromJson(Map<String, dynamic> json) {
    return CategoryLevel(
      catLevelId: json['cat_level_id'] as int,
      catLevelName: json['cat_level_name'] as String,
      catLevelTtlMins: json['cat_level_ttl_mins'] as int,
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
      catId: json['cat_id'] as int,
      catLevelId: json['cat_level_id'] as int,
      catName: json['cat_name'] as String,
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
      subCatId: json['sub_cat_id'] as int,
      catId: json['cat_id'] as int,
      subCatName: json['sub_cat_name'] as String,
    );
  }
}
