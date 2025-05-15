import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sos_alert_screen.dart'; // your SosScreen file
import 'ai_chats_screen.dart';

class Contact {
  String name;
  String phone;

  Contact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory Contact.fromJson(Map<String, dynamic> json) =>
      Contact(name: json['name'], phone: json['phone']);
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer player = AudioPlayer();
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _requestPermissions(); // Updated to request all needed permissions
  }

  Future<void> _requestPermissions() async {
    // Request all permissions needed for the app
    await [
      Permission.location,
      Permission.sms,
      Permission.notification, // For Android 13+
    ].request();

    // Additionally request Geolocator's permission
    await Geolocator.requestPermission();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> contactList = jsonDecode(contactsJson);
      setState(() {
        contacts = contactList.map((e) => Contact.fromJson(e)).toList();
      });
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return null;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions denied')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions permanently denied, please enable in settings'),
        ),
      );
      return null;
    }

    // Get current position
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
      return null;
    }
  }

  Future<void> sendSOSNotification() async {
    // Check notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is required for proper operation')),
        );
      }
    }

    Position? position = await _determinePosition();

    String locationLink = position != null
        ? '\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}'
        : '';

    final message = 'I need help! This is an emergency. $locationLink';

    for (var contact in contacts) {
      print('Sending SOS to ${contact.name} (${contact.phone}): $message');
      // TODO: Integrate SMS sending API or method here
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS Notification Sent!')),
    );
  }

  void _onSosPressed() async {
    try {
      // Ensure notification permission is granted
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      await player.setAsset('assets/sounds/alarm.mp3');
      await player.play();
      await Future.delayed(const Duration(seconds: 3));
      await player.stop();

      await sendSOSNotification();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SosScreen()),
      );
    } catch (e) {
      print('Error during SOS sequence: $e');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SosScreen()),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with greeting and profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage('assets/images/profile.png'),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good morning', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('Ukshita', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.notifications),
                  ],
                ),
                const SizedBox(height: 20),

                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(Icons.mic, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Emergency Instruction Search
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("What Is Your Emergency?",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter the type of medical emergency to find a relevant instructional video",
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Ex. Choking, Burns, ‘CPR’",
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onSubmitted: (value) {
                                // Navigate to the search result page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchScreen(query: value),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Handle search action if needed separately
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Search"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons: AI Chatbot & SOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // AI Chatbot button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Image.asset('assets/images/chatbot.png', height: 60),
                            const SizedBox(height: 8),
                            const Text("AI Chatbot", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),

                    // SOS button (already functional)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Alert Your Loved Ones!",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: contacts.isEmpty ? null : _onSosPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('SOS'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Chatbot')),
    body: const Center(child: Text('Chatbot Coming Soon...')),
  );
}

class SearchScreen extends StatelessWidget {
  final String query;
  const SearchScreen({super.key, required this.query});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Instructional Videos')),
    body: Center(child: Text('Search Results for "$query"')),
  );
}
