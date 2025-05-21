import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/ai_chats_screen.dart';
import 'screens/sos_alert_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';  // Import your auth provider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission(); // ✅ Ask notification permission
  runApp(const RescueMateApp());
}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final androidVersion = int.tryParse(Platform.version.split(" ").first);
    if (androidVersion != null && androidVersion >= 33) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }
}

class RescueMateApp extends StatelessWidget {
  const RescueMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add any other providers your app needs here
      ],
      child: MaterialApp(
        title: 'RescueMate',
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    const ChatbotScreen(),
    const SosScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'SOS Alert'),
        ],
      ),
    );
  }
}