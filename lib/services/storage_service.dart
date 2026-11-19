import 'dart:convert';
import 'package:latres/models/recipe_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Service for managing local persistence via SharedPreferences.
///
/// Handles user registration, authentication session, active user tracking,
/// and per-user favorite content synchronization without external state management.
class StorageService {
  final SharedPreferences? prefs;

  StorageService({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  // ==========================================
  // AUTHENTICATION & SESSION MANAGEMENT
  // ==========================================

  /// Retrieves list of all registered users
  Future<List<UserModel>> getRegisteredUsers() async {
    final prefs = await _instance;
    final jsonString = prefs.getString(AppConstants.keyRegisteredUsers);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Checks if a username is already registered (case-insensitive)
  Future<bool> isUsernameTaken(String username) async {
    final users = await getRegisteredUsers();
    final normalized = username.trim().toLowerCase();
    return users.any((u) => u.username.trim().toLowerCase() == normalized);
  }

  /// Registers a new user.
  ///
  /// Returns `true` if registered successfully.
  /// Returns `false` if username is empty, password is empty, or username already exists.
  Future<bool> register(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      return false;
    }

    if (await isUsernameTaken(trimmedUser)) {
      return false;
    }

    final users = await getRegisteredUsers();
    users.add(UserModel(username: trimmedUser, password: trimmedPass));

    final prefs = await _instance;
    final jsonString = jsonEncode(users.map((u) => u.toJson()).toList());
    return await prefs.setString(AppConstants.keyRegisteredUsers, jsonString);
  }

  /// Authenticates a user against registered credentials.
  ///
  /// If credentials match:
  /// - Sets [keyIsLoggedIn] to `true`
  /// - Sets [keyCurrentUser] to the registered username
  /// Returns `true` on success, `false` otherwise.
  Future<bool> login(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      return false;
    }

    final users = await getRegisteredUsers();
    final userIndex = users.indexWhere(
      (u) =>
          u.username.trim().toLowerCase() == trimmedUser.toLowerCase() &&
          u.password == trimmedPass,
    );

    if (userIndex != -1) {
      final matchedUser = users[userIndex];
      final prefs = await _instance;
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyCurrentUser, matchedUser.username);
      return true;
    }

    return false;
  }

  /// Checks if there is an active logged-in session (auto-login check)
  Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Returns the username of the active logged-in user
  Future<String?> getCurrentUser() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.keyCurrentUser);
  }

  /// Logs out the user by clearing active session flags
  Future<void> logout() async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyCurrentUser);
  }

  // ==========================================
  // FAVORITE CONTENT PERSISTENCE & SYNC
  // ==========================================

  ContentType _normalizeType(dynamic type) {
    if (type is ContentType) return type;
    final str = type.toString().trim().toLowerCase();
    for (final val in ContentType.values) {
      if (val.name.toLowerCase() == str) return val;
    }
    if (str == 'recipes') return ContentType.recipes;
    return ContentType.recipes;
  }

  Future<String> _resolveUser(String? username) async {
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    final current = await getCurrentUser();
    if (current != null && current.trim().isNotEmpty) {
      return current.trim();
    }
    return 'guest';
  }

  /// Retrieves list of favorite articles for the specified or current active user.
  Future<List<RecipeModel>> getFavorites({String? username}) async {
    final user = await _resolveUser(username);
    final prefs = await _instance;
    final key = '${AppConstants.keyFavoritesPrefix}$user';
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Checks if an article with [type] and [id] is favorited by the active user.
  Future<bool> isFavorite(dynamic type, int id, {String? username}) async {
    final targetType = _normalizeType(type);
    final favorites = await getFavorites(username: username);
    return favorites.any(
      (item) => _normalizeType(item.type) == targetType && item.id == id,
    );
  }

  /// Adds an article to favorites for the active user.
  /// Identitas = type + id.
  /// Yang disimpan cukup: type, id, title, imageUrl, author.
  Future<bool> addFavorite(dynamic item, {String? username}) async {
    final user = await _resolveUser(username);
    final prefs = await _instance;
    final key = '${AppConstants.keyFavoritesPrefix}$user';

    ContentType targetType;
    int id;
    String title;
    String? imageUrl;
    String author;

    if (item is RecipeModel) {
      targetType = item.type;
      id = item.id;
      title = item.name;
      imageUrl = item.imageUrl;
      author = item.tags;
    } else if (item is Map<String, dynamic>) {
      targetType = _normalizeType(item['type']);
      id = item['id'] is int
          ? item['id'] as int
          : int.tryParse(item['id']?.toString() ?? '0') ?? 0;
      title = item['title']?.toString() ?? '';
      imageUrl = item['imageUrl']?.toString() ?? item['image_url']?.toString();
      author = item['author']?.toString() ??
          item['news_site']?.toString() ??
          'Unknown';
    } else {
      return false;
    }

    final itemMap = {
      'type': targetType.name,
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'author': author,
    };

    final jsonString = prefs.getString(key);
    List<dynamic> rawList = [];
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        rawList = jsonDecode(jsonString);
      } catch (_) {
        rawList = [];
      }
    }

    // Avoid duplicates with composite identity: type + id
    rawList.removeWhere((entry) {
      if (entry is! Map) return false;
      final mType = _normalizeType(entry['type']);
      final mId = entry['id'] is int
          ? entry['id'] as int
          : int.tryParse(entry['id']?.toString() ?? '0') ?? 0;
      return mType == targetType && mId == id;
    });

    rawList.add(itemMap);
    return await prefs.setString(key, jsonEncode(rawList));
  }

  /// Removes an article with [type] and [id] from the active user's favorites.
  Future<bool> removeFavorite(dynamic type, int id, {String? username}) async {
    final user = await _resolveUser(username);
    final prefs = await _instance;
    final key = '${AppConstants.keyFavoritesPrefix}$user';

    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return false;
    }

    try {
      final List<dynamic> rawList = jsonDecode(jsonString);
      final targetType = _normalizeType(type);
      final initialLength = rawList.length;

      rawList.removeWhere((entry) {
        if (entry is! Map) return false;
        final mType = _normalizeType(entry['type']);
        final mId = entry['id'] is int
            ? entry['id'] as int
            : int.tryParse(entry['id']?.toString() ?? '0') ?? 0;
        return mType == targetType && mId == id;
      });

      if (rawList.length != initialLength) {
        await prefs.setString(key, jsonEncode(rawList));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Toggles favorite status for an item. Returns true if now favorited, false if removed.
  Future<bool> toggleFavorite(dynamic item, {String? username}) async {
    ContentType targetType;
    int id;

    if (item is RecipeModel) {
      targetType = item.type;
      id = item.id;
    } else if (item is Map<String, dynamic>) {
      targetType = _normalizeType(item['type']);
      id = item['id'] is int
          ? item['id'] as int
          : int.tryParse(item['id']?.toString() ?? '0') ?? 0;
    } else {
      return false;
    }

    final exists = await isFavorite(targetType, id, username: username);
    if (exists) {
      await removeFavorite(targetType, id, username: username);
      return false;
    } else {
      await addFavorite(item, username: username);
      return true;
    }
  }
}