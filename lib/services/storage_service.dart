import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';
import '../utils/constants.dart';

class StorageService {
  final SharedPreferences? prefs;

  StorageService({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  Future<bool> login(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser == AppConstants.validUsername &&
        trimmedPass == AppConstants.validPassword) {
      final prefs = await _instance;
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyCurrentUser, trimmedUser);
      return true;
    }

    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  Future<String?> getCurrentUser() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.keyCurrentUser);
  }

  Future<void> logout() async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyCurrentUser);
  }

  Future<List<Recipe>> getFavorites() async {
    final prefs = await _instance;
    final jsonString = prefs.getString(AppConstants.keyFavorites);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isFavorite(int id) async {
    final favorites = await getFavorites();
    return favorites.any((recipe) => recipe.id == id);
  }

  Future<bool> addFavorite(Recipe recipe) async {
    final prefs = await _instance;
    final favorites = await getFavorites();

    favorites.removeWhere((item) => item.id == recipe.id);
    favorites.add(recipe);

    final jsonString =
        jsonEncode(favorites.map((item) => item.toJson()).toList());
    return await prefs.setString(AppConstants.keyFavorites, jsonString);
  }

  Future<bool> removeFavorite(int id) async {
    final prefs = await _instance;
    final favorites = await getFavorites();
    final initialLength = favorites.length;

    favorites.removeWhere((item) => item.id == id);

    if (favorites.length != initialLength) {
      final jsonString =
          jsonEncode(favorites.map((item) => item.toJson()).toList());
      await prefs.setString(AppConstants.keyFavorites, jsonString);
      return true;
    }
    return false;
  }

  Future<bool> toggleFavorite(Recipe recipe) async {
    final exists = await isFavorite(recipe.id);
    if (exists) {
      await removeFavorite(recipe.id);
      return false;
    } else {
      await addFavorite(recipe);
      return true;
    }
  }
}
