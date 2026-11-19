import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/list_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/favorite_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String list = '/list';
  static const String detail = '/detail';
  static const String favorite = '/favorite';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        list: (context) => const ListScreen(),
        detail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is int) {
            return DetailScreen(id: args);
          }
          if (args is Map<String, dynamic>) {
            final id = args['id'] as int? ?? 0;
            return DetailScreen(id: id);
          }
          return const DetailScreen();
        },
        favorite: (context) => const FavoriteScreen(),
      };
}
