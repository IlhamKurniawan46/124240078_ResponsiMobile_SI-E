import 'package:flutter/material.dart';
import '../models/content_type.dart';
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
        list: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final type = args is ContentType ? args : ContentType.recipes;
          return ListScreen(type: type);
        },
        detail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final type = args['type'] as ContentType? ?? ContentType.recipes;
            final id = args['id'] as int? ?? 0;
            return DetailScreen(type: type, id: id);
          }
          return const DetailScreen();
        },
        favorite: (context) => const FavoriteScreen(),
      };
}