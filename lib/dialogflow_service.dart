import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class DialogflowService {
  final String _projectId = '[UR PROJECT ID]'; // Replace with your Dialogflow project ID
  final String _sessionId = 'flutter-session'; // Any unique session ID
  final String _languageCode = 'en';

  Future<String> detectIntent(String message) async {
    final serviceAccount = json.decode(
      await rootBundle.loadString('assets/dialogflow_key.json'),
    );

    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

    final client = await clientViaServiceAccount(credentials, scopes);

    final url =
        'https://dialogflow.googleapis.com/v2/projects/$_projectId/agent/sessions/$_sessionId:detectIntent';

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode({
        'queryInput': {
          'text': {
            'text': message,
            'languageCode': _languageCode,
          }
        }
      }),
    );

    final responseBody = json.decode(response.body);
    return responseBody['queryResult']['fulfillmentText'] ?? 'No reply';
  }
}
