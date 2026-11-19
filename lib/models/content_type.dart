enum ContentType {
  recipes;

  String get endpoint {
    switch (this) {
      case ContentType.recipes:
        return 'recipes';
    }
  }

  String get displayName {
    switch (this) {
      case ContentType.recipes:
        return 'recipes';
    }
  }
}