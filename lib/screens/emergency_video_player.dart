import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'emergency_data.dart';

class EmergencyVideoPlayer extends StatefulWidget {
  final String emergencyType;

  const EmergencyVideoPlayer({super.key, required this.emergencyType});

  @override
  _EmergencyVideoPlayerState createState() => _EmergencyVideoPlayerState();
}

class _EmergencyVideoPlayerState extends State<EmergencyVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final String videoPath = _getVideoPathForEmergency(widget.emergencyType);

      _videoPlayerController = VideoPlayerController.asset(videoPath);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading video: $e";
        });
      }
      print("Video player error: $e");
    }
  }

  String _getVideoPathForEmergency(String emergencyType) {
    // Use the emergency template's videoAsset directly if it exists
    if (emergencyTemplates.containsKey(emergencyType)) {
      return emergencyTemplates[emergencyType]!['videoAsset'] as String;
    }

    // Fall back to default videos based on primary category
    if (emergencyType.startsWith('cpr')) {
      return 'assets/emergency_videos/cpr_man.mp4'; // Default to adult male CPR
    } else if (emergencyType.startsWith('choking')) {
      return 'assets/emergency_videos/choking_woman.mp4'; // Default to adult choking
    }

    // Final fallback
    return 'assets/emergency_videos/cpr_man.mp4';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: Text('Controller not initialized')),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Emergency: ${emergencyTemplates.containsKey(widget.emergencyType) ?
            emergencyTemplates[widget.emergencyType]!['title'] :
            widget.emergencyType}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}

class EmergencyVideoScreen extends StatelessWidget {
  final String emergencyType;

  const EmergencyVideoScreen({super.key, required this.emergencyType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Instructions'),
        backgroundColor: Colors.red,
      ),
      body: EmergencyVideoPlayer(emergencyType: emergencyType),
    );
  }
}