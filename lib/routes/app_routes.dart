import 'package:flutter/material.dart';
import 'package:testflutter/screens/home_screen.dart';
import 'package:testflutter/screens/tokeninput.dart';
import 'package:testflutter/screens/repositorylist.dart';

class AppRoutes {
  static final routes = {
    '/': (context) => const HomeScreen(),
    '/token': (context) => const TokenInputScreen(),
    '/search': (context) => const RepositoryListScreen(repositoryName: '', keyword: '', stars: 0),
  };
}
