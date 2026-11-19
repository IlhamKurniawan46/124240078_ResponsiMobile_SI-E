import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/list_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/favorite_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String list = '/list';
  static const String detail = '/detail';
  static const String favorite = '/favorite';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        home: (context) => const HomeScreen(),
        list: (context) => const ListScreen(),
        detail: (context) => const DetailScreen(),
        favorite: (context) => const FavoriteScreen(),
      };
}