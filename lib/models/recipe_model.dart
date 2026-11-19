import 'content_type.dart';
export 'content_type.dart';

class RecipeModel {
  final int id;
  final String name;
  final String? imageUrl;
  final String tags;
  final String summary;
  final String publishedAt;
  final String url;
  final ContentType type;

  const RecipeModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.tags,
    required this.summary,
    required this.publishedAt,
    required this.url,
    required this.type,
  });

  factory RecipeModel.fromJson(
    Map<String, dynamic> json, {
    ContentType? defaultType,
  }) {
    ContentType resolvedType = defaultType ?? ContentType.recipes;
    if (json['type'] != null) {
      final typeString = json['type'].toString().trim().toLowerCase();
      for (final val in ContentType.values) {
        if (val.name.toLowerCase() == typeString) {
          resolvedType = val;
          break;
        }
      }
    }

    String resolvedtags = 'Unknown';
    if (json['news_site'] != null &&
        json['news_site'].toString().trim().isNotEmpty) {
      resolvedtags = json['news_site'].toString().trim();
    } else if (json['tags'] != null &&
        json['tags'].toString().trim().isNotEmpty) {
      resolvedtags = json['tags'].toString().trim();
    } else if (json['tags'] is List && (json['tags'] as List).isNotEmpty) {
      final first = (json['tags'] as List).first;
      if (first is Map && first['name'] != null) {
        resolvedtags = first['name'].toString().trim();
      }
    }

    return RecipeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      tags: resolvedtags,
      summary: json['summary'] as String? ?? '',
      publishedAt: json['published_at'] as String? ??
          json['publishedAt'] as String? ??
          '',
      url: json['url'] as String? ?? '',
      type: resolvedType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'tags': tags,
      'summary': summary,
      'publishedAt': publishedAt,
      'url': url,
      'type': type.name,
    };
  }

  factory RecipeModel.fromMap(Map<String, dynamic> map) =>
      RecipeModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'RecipeModel(id: $id, name: $name, tags: $tags, type: ${type.name})';
  }
}