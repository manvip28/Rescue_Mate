import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class MyTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      print('🔔 Foreground task running: ${DateTime.now()}');
      // Add your emergency logic here (e.g., listen for volume button trigger)
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // This gets called repeatedly every interval (5 seconds here)
    print('🔁 Repeating foreground task at $timestamp');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _timer?.cancel();
  }

  @override
  void onButtonPressed(String id) {
    print('🔘 Notification button pressed: $id');
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/");
  }
}
