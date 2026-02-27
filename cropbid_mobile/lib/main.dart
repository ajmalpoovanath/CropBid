import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAa47T_ryubpWvAjYSIP5-id9-6VH69ge4',
        appId: '1:536277474699:ios:897424f4e068ee2194638e',
        messagingSenderId: '536277474699',
        projectId: 'cropbid-e19f1',
      ),
    );
    
    print("Firebase connected manually! 🔥");

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }

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
      home: const LoginScreen(),
    );
  }
}