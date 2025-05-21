import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sos_alert_screen.dart'; // your SosScreen file
import 'ai_chats_screen.dart';
import 'emergency_data.dart'; // Import emergency data system
import 'emergency_video_player.dart'; // Import the video player
import 'emergency_home_page.dart'; // Import the Emergency home page for direct voice input option

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emergencySearchController = TextEditingController();
  bool _isEmergencySearchLoading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _requestPermissions(); // Updated to request all needed permissions
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emergencySearchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    // Request all permissions needed for the app
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.sms,
      Permission.notification, // For Android 13+
      Permission.microphone, // For voice input in emergency
    ].request();

    // Check microphone permission specifically
    if (statuses[Permission.microphone]?.isDenied == true) {
      // Show dialog explaining why microphone is needed
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text("Microphone Permission Required"),
            content: const Text(
                "This app uses voice recognition to quickly process emergency information. "
                    "Please grant microphone access for this feature to work."
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Later"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
      }
    }

    // Additionally request Geolocator's permission for location
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

  // Handle the general search submission
  void _handleSearchSubmitted(String value) {
    if (value.trim().isEmpty) return;

    // Process search query (could be modified to handle all searches in one place)
    _processEmergencyQuery(value);
  }

  // Direct emergency search handling - integrated from SearchScreen
  void _processEmergencyQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isEmergencySearchLoading = true;
    });

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Analyzing emergency information...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );

    // Add slight delay to show loading state
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Use the emergency detection system
      String detectedEmergencyType = identifyDetailedEmergencyType(query);

      // Close loading dialog
      Navigator.of(context).pop();

      // Reset loading state
      setState(() {
        _isEmergencySearchLoading = false;
        _emergencySearchController.clear(); // Clear the search field
      });

      // Navigate to video instructions screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmergencyVideoScreen(emergencyType: detectedEmergencyType),
        ),
      );
    } catch (e) {
      // Handle errors
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        _isEmergencySearchLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing emergency: $e')),
      );
    }
  }

  // Navigate to voice input emergency page
  void _openVoiceEmergencyInput() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyHomePage()),
    );
  }

  // Method to handle tab navigation
  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatbotScreen()),
      ).then((_) {
        setState(() {
          _currentIndex = 0; // Reset to Home when returning
        });
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SosScreen()),
      ).then((_) {
        setState(() {
          _currentIndex = 0;
        });
      });
    }
  }


  // Main home screen content
  Widget _buildHomeContent() {
    return SafeArea(
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
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _handleSearchSubmitted,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.grey),
                      onPressed: _openVoiceEmergencyInput,
                      tooltip: 'Voice input for emergency',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Emergency Instruction Search with integrated functionality
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
                            controller: _emergencySearchController,
                            decoration: InputDecoration(
                              hintText: "Ex. Choking, Burns, 'CPR'",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSubmitted: _processEmergencyQuery,
                            enabled: !_isEmergencySearchLoading,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isEmergencySearchLoading
                              ? null
                              : () => _processEmergencyQuery(_emergencySearchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isEmergencySearchLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("Search"),
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
                      _onTabTapped(1); // Just call this once, no need to setState twice
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


                  // SOS button
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

              // Voice Emergency Assistant
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: GestureDetector(
                  onTap: _openVoiceEmergencyInput,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.red, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Voice Emergency Assistant",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Describe the emergency situation with your voice",
                                style: TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'SOS Alert'),
        ],
      ),
    );
  }
}