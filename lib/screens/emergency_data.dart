import 'package:hive/hive.dart';

// Emergency types and their corresponding template videos/images
final Map<String, Map<String, dynamic>> emergencyTemplates = {
  'cpr_adult': {
    'title': 'Adult CPR Instructions',
    'videoAsset': 'assets/emergency_videos/cpr_man.mp4',
  },
  'cpr_woman': {
    'title': 'Woman CPR Instructions',
    'videoAsset': 'assets/emergency_videos/cpr_women.mp4',
  },
  'cpr_baby': {
    'title': 'Infant CPR Instructions',
    'videoAsset': 'assets/emergency_videos/cpr_baby.mp4',
  },
  'choking_adult': {
    'title': 'Adult Choking Response',
    'videoAsset': 'assets/emergency_videos/choking_woman.mp4',
  },
  'choking_baby': {
    'title': 'Infant Choking Response',
    'videoAsset': 'assets/emergency_videos/choking_baby.mp4',
  },
};

// Emergency NLP keywords for classification
final Map<String, List<String>> emergencyKeywords = {
  'cpr_adult': ['cpr man', 'adult cpr', 'man heart attack', 'man cardiac arrest', 'adult heart', 'man not breathing', 'adult unconscious', 'adult resuscitation', 'man collapsed', 'man chest pain', 'man heart'],
  'cpr_woman': ['cpr woman', 'woman cpr', 'woman heart attack', 'woman cardiac arrest', 'woman heart', 'woman not breathing', 'woman unconscious', 'woman resuscitation', 'woman collapsed', 'woman chest pain', 'women heart attack', 'women cpr', 'women cardiac', 'women heart', 'women not breathing', 'women unconscious', 'women collapsed', 'women chest pain', 'female heart attack', 'female cpr', 'female cardiac', 'female heart', 'female not breathing', 'lady heart attack', 'lady cpr'],
  'cpr_baby': ['cpr baby', 'infant cpr', 'baby heart attack', 'baby cardiac arrest', 'baby heart', 'baby not breathing', 'infant not breathing', 'baby unconscious', 'infant unconscious', 'baby resuscitation', 'infant resuscitation', 'child cpr', 'child heart', 'kid cpr', 'kid heart attack', 'kid cardiac', 'kid heart', 'kid not breathing', 'kid unconscious', 'kid collapsed', 'child heart attack', 'child cardiac', 'child not breathing', 'child unconscious', 'child collapsed', 'children cpr', 'children heart'],
  'choking_adult': ['choking adult', 'adult choking', 'man choking', 'woman choking', 'women choking', 'adult can\'t breathe', 'adult airway blocked', 'heimlich adult', 'man heimlich', 'woman heimlich', 'women heimlich', 'adult food stuck', 'person choking', 'female choking'],
  'choking_baby': ['choking baby', 'baby choking', 'infant choking', 'child choking', 'baby can\'t breathe', 'infant can\'t breathe', 'baby airway blocked', 'infant airway blocked', 'baby food stuck', 'child food stuck', 'kid choking', 'kid can\'t breathe', 'kid airway blocked', 'kid food stuck', 'children choking'],
};

// Function to identify emergency type with gender/age specificity
String identifyDetailedEmergencyType(String description) {
  String normalizedText = description.toLowerCase();
  Map<String, int> scores = {};

  // Initialize scores
  emergencyKeywords.forEach((type, _) => scores[type] = 0);

  // First pass: Check for exact matches
  for (var entry in emergencyKeywords.entries) {
    String type = entry.key;
    List<String> keywords = entry.value;

    for (String keyword in keywords) {
      if (normalizedText.contains(keyword)) {
        scores[type] = scores[type]! + 1;

        // Boost score for more specific matches
        if (keyword.length > 10) {  // Longer phrases get higher weights
          scores[type] = scores[type]! + 1;
        }
      }
    }
  }

  // Second pass: Check for gender and age indicators
  bool hasWomanIndicator = normalizedText.contains('woman') ||
      normalizedText.contains('women') ||
      normalizedText.contains('female') ||
      normalizedText.contains('lady');

  bool hasChildIndicator = normalizedText.contains('baby') ||
      normalizedText.contains('infant') ||
      normalizedText.contains('child') ||
      normalizedText.contains('kid') ||
      normalizedText.contains('children');

  bool hasChokingIndicator = normalizedText.contains('chok') ||
      normalizedText.contains('heimlich') ||
      normalizedText.contains('airway') ||
      normalizedText.contains('can\'t breathe');

  // Apply specific boosting for gender/age indicators
  if (hasWomanIndicator) {
    if (hasChokingIndicator) {
      // If both woman and choking are mentioned, heavily boost choking_adult
      scores['choking_adult'] = scores['choking_adult']! + 5;
    } else {
      // Otherwise boost cpr_woman for heart attacks, etc.
      scores['cpr_woman'] = scores['cpr_woman']! + 3;
    }
  }

  if (hasChildIndicator) {
    if (hasChokingIndicator) {
      // If both child and choking are mentioned, heavily boost choking_baby
      scores['choking_baby'] = scores['choking_baby']! + 5;
    } else {
      // Otherwise boost cpr_baby
      scores['cpr_baby'] = scores['cpr_baby']! + 3;
    }
  }

  // Find highest score
  int highestScore = 0;
  String primaryType = '';

  scores.forEach((type, score) {
    if (score > highestScore) {
      highestScore = score;
      primaryType = type;
    }
  });

  // Fallback logic based on keyword presence
  if (primaryType.isEmpty || highestScore == 0) {
    bool hasChokingIndicator = normalizedText.contains('chok') ||
        normalizedText.contains('heimlich') ||
        normalizedText.contains('airway') ||
        normalizedText.contains('can\'t breathe');

    // First check if it's a choking emergency
    if (hasChokingIndicator) {
      if (hasChildIndicator) {
        return 'choking_baby';
      } else {
        return 'choking_adult'; // Default to adult choking
      }
    }
    // Then check if it's a CPR/cardiac emergency
    else if (normalizedText.contains('cpr') ||
        normalizedText.contains('heart') ||
        normalizedText.contains('cardiac')) {

      if (hasWomanIndicator) {
        return 'cpr_woman';
      } else if (hasChildIndicator) {
        return 'cpr_baby';
      } else {
        return 'cpr_adult'; // Default to adult male CPR
      }
    }

    // Final default
    return 'cpr_adult';
  }

  return primaryType;
}

// Class to handle offline emergency data
class EmergencyDataManager {
  late final Box _box;

  EmergencyDataManager() {
    _box = Hive.box('offlineEmergencyData');
  }

  // Store emergency data for offline use
  Future<void> storeEmergencyData(Map<String, dynamic> data) async {
    await _box.put('emergencyTemplates', data);
  }

  // Get emergency data
  Map<String, dynamic> getEmergencyData() {
    return _box.get('emergencyTemplates', defaultValue: emergencyTemplates);
  }

  // Check if we have the latest emergency data
  bool hasLatestData(String version) {
    String storedVersion = _box.get('dataVersion', defaultValue: '');
    return storedVersion == version;
  }

  // Update data version
  Future<void> updateDataVersion(String version) async {
    await _box.put('dataVersion', version);
  }
}