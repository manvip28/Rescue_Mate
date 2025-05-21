import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import "package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart";
import 'package:permission_handler/permission_handler.dart';
import 'emergency_data.dart';
import 'emergency_video_player.dart';

class EmergencyHomePage extends StatefulWidget {
  const EmergencyHomePage({Key? key}) : super(key: key);

  @override
  _EmergencyHomePageState createState() => _EmergencyHomePageState();
}

class _EmergencyHomePageState extends State<EmergencyHomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  String _transcription = '';
  String _detectedEmergency = '';
  bool _processingRequest = false;
  String? _generatedVideoPath;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _showTextInput = false;
  bool _micPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInitSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  // New method to check permissions first, then initialize speech
  Future<void> _checkPermissionsAndInitSpeech() async {
    // First check and request microphone permission
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      // Microphone permission granted, initialize speech
      await _initSpeech();
    } else {
      // Permission denied, update UI to show text input by default
      setState(() {
        _showTextInput = true;
        _micPermissionDenied = true;
      });

      // Show a persistent notice
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice recognition. Please enable in settings.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done') {
            setState(() {
              _isListening = false;
            });
            _processEmergencyDescription();
          }
        },
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            _isListening = false;
            _showTextInput = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: $error. Please use text input instead.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      );

      if (!available) {
        print("Speech recognition not available on this device");
        setState(() {
          _showTextInput = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device. Please use text input.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print("Error initializing speech recognition: $e");
      setState(() {
        _showTextInput = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize speech recognition: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _startListening() async {
    if (_micPermissionDenied) {
      // If permission was previously denied, try requesting it again
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        // Still denied, show settings option
        setState(() {
          _showTextInput = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission denied. Please enable in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      } else {
        // Permission granted now, reinitialize speech
        setState(() {
          _micPermissionDenied = false;
        });
        await _initSpeech();
      }
    }

    if (!_isListening) {
      setState(() {
        _transcription = '';
        _detectedEmergency = '';
        _generatedVideoPath = null;
        _videoInitialized = false;
        _videoController?.dispose();
        _videoController = null;
      });

      try {
        bool available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _transcription = result.recognizedWords;
              });
            },
            listenFor: Duration(seconds: 30),
            pauseFor: Duration(seconds: 3),
            partialResults: true,
          );
        } else {
          // Show text input if speech recognition is not available
          setState(() {
            _showTextInput = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available. Please use text input instead.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print("Error starting speech recognition: $e");
        setState(() {
          _showTextInput = true;
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start listening: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _submitTextInput() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _transcription = _textController.text;
        _textController.clear();
        _showTextInput = false;
      });
      _processEmergencyDescription();
    }
  }

  void _toggleTextInput() {
    setState(() {
      _showTextInput = !_showTextInput;
    });
  }

  void _processEmergencyDescription() async {
    if (_transcription.isEmpty) return;
    setState(() => _processingRequest = true);

    // Use the new detailed emergency identification function
    String emergencyType = identifyDetailedEmergencyType(_transcription);

    setState(() => _detectedEmergency = emergencyType);
    await _openEmergencyVideo(emergencyType);
    setState(() => _processingRequest = false);
  }

  Future<void> _openEmergencyVideo(String emergencyType) async {
    // Validate emergency type exists in templates
    if (!emergencyTemplates.containsKey(emergencyType)) {
      // Default to adult CPR if not found
      emergencyType = 'cpr_adult';
    }

    // Speak the emergency instructions
    _speakEmergencyTitle(emergencyType);

    // Open the video screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyVideoScreen(emergencyType: emergencyType),
      ),
    );
  }

  void _speakEmergencyTitle(String emergencyType) async {
    if (!emergencyTemplates.containsKey(emergencyType)) return;

    final title = emergencyTemplates[emergencyType]!['title'] as String;
    await _flutterTts.speak("Emergency: $title");
  }

  void _showEmergencyInstructions() {
    if (_detectedEmergency.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyVideoScreen(emergencyType: _detectedEmergency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency AI Assistant'),
        actions: [
          IconButton(
            icon: Icon(_showTextInput ? Icons.mic : Icons.keyboard),
            onPressed: _toggleTextInput,
            tooltip: _showTextInput ? 'Use voice input' : 'Use text input',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Describe the medical emergency',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_showTextInput)
                Column(
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type emergency description here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _submitTextInput,
                        ),
                      ),
                      maxLines: 3,
                      onSubmitted: (_) => _submitTextInput(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _submitTextInput,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Process Emergency'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isListening ? 'Listening...' : 'Press the microphone button to describe the emergency',
                        style: const TextStyle(fontSize: 16), textAlign: TextAlign.center,
                      ),
                    ),
                    // Add buttons for voice mode
                    if (_transcription.isNotEmpty && !_isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          onPressed: _processEmergencyDescription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Process Emergency'),
                        ),
                      ),
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          onPressed: _stopListening,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Stop Listening'),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              if (_transcription.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('You said: $_transcription', style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 20),
              if (_detectedEmergency.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                      'Detected emergency: ${emergencyTemplates[_detectedEmergency]?['title'] ?? _detectedEmergency}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              if (_detectedEmergency.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: _showEmergencyInstructions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Show Emergency Instructions', style: TextStyle(fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 20),
              if (_processingRequest)
                Column(children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Processing emergency...'),
                ]),

              // Error message for microphone permission denial
              if (_micPermissionDenied)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: GestureDetector(
                    onTap: () => openAppSettings(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.mic_off, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Microphone permission required for voice recognition. Tap to open settings.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
      floatingActionButton: _showTextInput ? null : FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: _isListening ? 'Stop' : 'Listen',
        child: Icon(_isListening ? Icons.stop : Icons.mic_none),
        backgroundColor: _isListening ? Colors.grey : Colors.red,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}