import 'package:flutter/material.dart';
import 'package:greencyle_fe/core/theme/app_theme.dart';
import 'package:greencyle_fe/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenCycle',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
