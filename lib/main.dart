import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/screens/tokeninput.dart';
import 'package:testflutter/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('GitHubToken');

  runApp(
    ProviderScope(
      child: MyApp(
        initialScreen: token?.isNotEmpty == true
            ? const HomeScreen()
            : const TokenInputScreen(),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialScreen,
    );
  }
}
