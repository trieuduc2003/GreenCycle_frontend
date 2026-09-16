import 'dart:io';

import 'package:flutter/material.dart';

import 'package:green_cycle_mobile/core/constants/app_colors.dart';
import 'package:green_cycle_mobile/features/splash/splash_screen.dart';
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
void main() {
  // Đặt ở ngay dòng đầu tiên của main()
  HttpOverrides.global = DevHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GreenCycleApp());
}


class GreenCycleApp extends StatelessWidget {
  const GreenCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenCycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}