/// Application constants for Spaceflight News app
class AppConstants {
  AppConstants._();

  // SharedPreferences Keys
  static const String keyRegisteredUsers = 'key_registered_users';
  static const String keyIsLoggedIn = 'key_is_logged_in';
  static const String keyCurrentUser = 'key_current_user';
  static const String keyFavoritesPrefix = 'key_favorites_';

  // Standard Messages per PRD & Exam Specs
  static const String loginFailedMessage =
      'Login Gagal! Pastikan sudah Register atau cek password.';
  static const String openWebErrorMessage = 'Gagal membuka tautan web';
  static const String addedToFavoriteMessage = 'Ditambahkan ke favorite';
  static const String removedFromFavoriteMessage = 'Dihapus dari favorite';
}