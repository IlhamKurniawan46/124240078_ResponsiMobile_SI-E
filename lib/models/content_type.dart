enum ContentType {
  recipes;

  /// Returns the corresponding SNAPI v4 endpoint segment
  String get endpoint {
    switch (this) {
      case ContentType.recipes:
        return 'recipes';
    }
  }

  /// Returns category name
  String get displayName {
    switch (this) {
      case ContentType.recipes:
        return 'recipes';
    }
  }
}