import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  // 1. This line is required to ensure system calls work before runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Set the system styles HERE, before the app loads
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Top icons (clock/battery) white
    systemNavigationBarColor: Color(0xFF0B251A), // Match your Deep Forest Green
    systemNavigationBarIconBrightness: Brightness.light, // Bottom buttons white
  ));

  runApp(const CropBidApp());
}

class CropBidApp extends StatelessWidget {
  const CropBidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CropBid',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}