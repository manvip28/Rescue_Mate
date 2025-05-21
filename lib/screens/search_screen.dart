import 'package:flutter/material.dart';
import 'emergency_data.dart'; // Import the emergency data system
import 'emergency_video_player.dart'; // Import the video player

class SearchScreen extends StatefulWidget {
  final String query;
  const SearchScreen({super.key, required this.query});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late String detectedEmergencyType;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Process the search query through the emergency detection system
    _processQuery();
  }

  void _processQuery() {
    // Use the improved emergency detection function
    detectedEmergencyType = identifyDetailedEmergencyType(widget.query);

    setState(() {
      isLoading = false;
    });

    // Directly navigate to video screen after a short delay
    // This gives users a moment to see what was detected
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showEmergencyInstructions();
      }
    });
  }

  void _showEmergencyInstructions() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyVideoScreen(emergencyType: detectedEmergencyType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Processing Emergency'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 20),
              Text('Analyzing emergency information...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // This actually won't be shown because we navigate away in initState
    // But it's here as a fallback
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Detected'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Detected: ${emergencyTemplates[detectedEmergencyType]?['title'] ?? detectedEmergencyType}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showEmergencyInstructions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Show Instructions', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}