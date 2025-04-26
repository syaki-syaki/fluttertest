// lib/app.dart
import 'package:flutter/material.dart';
import 'package:testflutter/routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: AppRoutes.routes, // ← ここで「地図を読み込んでる」
    );
  }
}
