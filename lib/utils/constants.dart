class AppConstants {
  AppConstants._();

  // SharedPreferences Keys
  static const String keyIsLoggedIn = 'loginData';
  static const String keyCurrentUser = 'key_current_user';
  static const String keyFavorites = 'favorite_recipes';

  static const String validUsername = 'ilham';
  static const String validPassword = '078';

  // Standard Messages
  static const String loginFailedMessage = 'Username atau password salah';
  static const String addedToFavoriteMessage = 'Ditambahkan ke favorite';
  static const String removedFromFavoriteMessage = 'Dihapus dari favorite';
}
