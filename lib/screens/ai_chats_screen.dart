import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../dialogflow_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final DialogflowService _dialogflowService = DialogflowService();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _response = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final reply = await _dialogflowService.detectIntent(message);
    setState(() {
      _response = reply;
    });
    _controller.clear();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          _controller.text = result.recognizedWords;
          if (result.finalResult) {
            _stopListening();
            _sendMessage(result.recognizedWords);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage('assets/images/profile.png'), // replace with your asset
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good morning', style: TextStyle(fontSize: 12)),
                          Text('Ukshita',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity, // Ensures full width like in SOS
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.question_mark_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'How can I help you today?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Quickly describe the situation,\nand I\'ll provide guidance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14), // Optional: match SOS's look more
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bot Response:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(_response),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        filled: true,
                        fillColor: Colors.grey[200],
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic),
                          onPressed:
                          _isListening ? _stopListening : _startListening,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _sendMessage(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    child: const Text('Send', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
