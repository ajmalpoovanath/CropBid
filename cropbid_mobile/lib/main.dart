import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // <--- Import the new file

void main() {
  runApp(const CropBidApp());
}

class CropBidApp extends StatelessWidget {
  const CropBidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CropBid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // <--- Point to the Login Screen
    );
  }
}