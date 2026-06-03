import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../services/data_service.dart';
import '../services/classifier_service.dart';

class AppProvider extends ChangeNotifier {
  List<Child> _children = [];
  Child? _selectedChild;
  String _language = 'en';
  int _outboxCount = 12;
  final List<CryptoLog> _cryptoLogs = [];
  bool _showSandbox = true;

  // Recording state
  bool _isRecording = false;
  String _transcript = '';
  List<String> _tags = [];
  bool _isSimulatedVoice = false;

  // Navigation
  String _currentScreen = 'home';

  // Getters
  List<Child> get children => _children;
  Child? get selectedChild => _selectedChild;
  String get language => _language;
  int get outboxCount => _outboxCount;
  List<CryptoLog> get cryptoLogs => _cryptoLogs;
  bool get showSandbox => _showSandbox;
  bool get isRecording => _isRecording;
  String get transcript => _transcript;
  List<String> get tags => _tags;
  bool get isSimulatedVoice => _isSimulatedVoice;
  String get currentScreen => _currentScreen;
  bool get canGoBack => _currentScreen != 'home';

  List<Child> get filteredChildren {
    return _children; // Search filter applied in UI
  }

  void initialize() {
    _language = DataService.getLanguage();
    _children = DataService.loadChildren();
    if (_children.isEmpty) {
      _children = createSeedChildren();
      DataService.saveChildren(_children);
    }
    if (_children.isNotEmpty) _selectedChild = _children.first;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    DataService.setLanguage(lang);
    notifyListeners();
  }

  void toggleSandbox() {
    _showSandbox = !_showSandbox;
    notifyListeners();
  }

  void navigateTo(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void goBack() {
    switch (_currentScreen) {
      case 'profile':
        _currentScreen = 'home';
        _selectedChild = null;
        break;
      case 'record':
        _currentScreen = 'profile';
        break;
      case 'result':
      case 'referral':
      case 'add_child':
        _currentScreen = 'profile';
        break;
      default:
        _currentScreen = 'home';
    }
    notifyListeners();
  }

  void selectChild(Child child) {
    _selectedChild = child;
    _currentScreen = 'profile';
    notifyListeners();
  }

  void openAddChild() {
    _currentScreen = 'add_child';
    notifyListeners();
  }

  void addChild({
    required String name,
    required int ageMonths,
    required String gender,
  }) {
    final id = 'child_${DateTime.now().millisecondsSinceEpoch}';
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    final child = Child(
      id: id,
      pseudoId: 'hmac_${id.hashCode.toRadixString(16)}',
      name: name,
      age: '$years yrs $months mos',
      gender: gender == 'Male' ? 'M' : 'F',
      status: 'onTrack',
      profile: {
        'physical': 0.5,
        'socio': 0.5,
        'cognitive': 0.5,
        'language': 0.5,
        'aesthetic': 0.5,
        'habits': 0.5,
      },
      observations: [],
    );
    _children = [..._children, child];
    DataService.saveChildren(_children);

    // Generate crypto log
    final log = DataService.generateCryptoLog(
      action: 'ENROLL_NEW_CHILD (AES-256-GCM)',
      childId: child.pseudoId,
      rawData: {'name': name, 'ageMonths': ageMonths, 'gender': gender},
      tags: [],
    );
    _cryptoLogs.insert(0, log);
    _outboxCount++;

    _currentScreen = 'home';
    notifyListeners();
  }

  // ─── Voice Capture ────────────────────────────

  void startRecording() {
    _transcript = '';
    _tags = [];
    _isRecording = true;
    _isSimulatedVoice = false;
    _currentScreen = 'record';
    notifyListeners();
  }

  void setSimulatedVoice(bool val) {
    _isSimulatedVoice = val;
    notifyListeners();
  }

  void onTranscriptUpdate(String text) {
    _transcript = text;
    notifyListeners();
  }

  void cancelRecording() {
    _isRecording = false;
    _isSimulatedVoice = false;
    _transcript = '';
    _currentScreen = 'profile';
    notifyListeners();
  }



  void stopRecording(String finalTranscript) {
    _isRecording = false;
    _transcript = finalTranscript;

    // Use fallback text if empty
    if (_transcript.isEmpty) {
      final fallback = {
        'en': 'Munni shared blocks with Raju and stacked them carefully.',
        'hi': 'मुन्नी ने आज राजू के साथ खिलौने बांटे और ब्लॉक सावधानी से रखे।',
        'ta': 'முன்னி இன்று ராஜூவுடன் பொம்மைகளைப் பகிர்ந்து கொண்டாள்.',
        'gu': 'મુન્નીએ આજે રાજુ સાથે રમકડાં વહેંચ્યા.',
      };
      _transcript = fallback[_language] ?? fallback['en']!;
      _isSimulatedVoice = true;
    }

    // Classify domains
    final scores = ClassifierService.classify(_transcript, _language);
    _tags = ClassifierService.getTopDomains(scores);

    _currentScreen = 'result';
    notifyListeners();
  }

  void updateTranscript(String text) {
    _transcript = text;
    if (text.isNotEmpty) {
      final scores = ClassifierService.classify(text, _language);
      _tags = ClassifierService.getTopDomains(scores);
    }
    notifyListeners();
  }

  // ─── Save Observation ──────────────────────────

  void saveObservation() {
    if (_selectedChild == null || _transcript.isEmpty) return;

    // Update profile scores
    final updatedProfile =
        Map<String, double>.from(_selectedChild!.profile);
    for (final tag in _tags) {
      updatedProfile[tag] =
          ((updatedProfile[tag] ?? 0.5) + 0.1).clamp(0.0, 1.0);
    }

    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${now.day} ${months[now.month-1]} ${now.year}';

    final newObs = Observation(
      date: dateStr,
      text: _transcript,
      method: _isSimulatedVoice ? 'voice_sim' : 'voice',
      domains: _tags,
    );

    // Update child
    _selectedChild!.profile = updatedProfile;
    _selectedChild!.observations = [newObs, ..._selectedChild!.observations];

    // Update status based on profile
    final avg = updatedProfile.values.fold(0.0, (a, b) => a + b) /
        updatedProfile.length;
    if (avg < 0.3) {
      _selectedChild!.status = 'redFlag';
    } else if (avg < 0.5) {
      _selectedChild!.status = 'watch';
    } else {
      _selectedChild!.status = 'onTrack';
    }

    // Persist
    _children = _children.map((c) {
      return c.id == _selectedChild!.id ? _selectedChild! : c;
    }).toList();
    DataService.saveChildren(_children);

    _outboxCount++;

    // Generate crypto log
    final log = DataService.generateCryptoLog(
      action: 'SAVE_OBSERVATION (AES-256-GCM + SHA256-HMAC)',
      childId: _selectedChild!.pseudoId,
      rawData: {
        'name': _selectedChild!.name,
        'transcript': _transcript,
        'updatedProfile': updatedProfile,
      },
      tags: _tags,
    );
    _cryptoLogs.insert(0, log);

    _currentScreen = 'profile';
    notifyListeners();
  }

  // ─── Referral ──────────────────────────────────

  String generateReferralReason() {
    if (_selectedChild == null) return '';
    final lang = _language;
    if (lang == 'hi') {
      return 'लगातार कम स्कोर। संज्ञानात्मक: ${_selectedChild!.profile['cognitive']}, भाषा: ${_selectedChild!.profile['language']}';
    } else if (lang == 'ta') {
      return 'தொடர்ச்சியான குறைந்த மதிப்பெண். அறிவாற்றல்: ${_selectedChild!.profile['cognitive']}, மொழி: ${_selectedChild!.profile['language']}';
    } else if (lang == 'gu') {
      return 'સતત નીચો સ્કોર. જ્ઞાનાત્મક: ${_selectedChild!.profile['cognitive']}, ભાષા: ${_selectedChild!.profile['language']}';
    }
    return 'Persistent low score in Cognitive: ${_selectedChild!.profile['cognitive']} and Language: ${_selectedChild!.profile['language']}';
  }

  void generateReferral() {
    if (_selectedChild == null) return;
    final log = DataService.generateCryptoLog(
      action: 'GENERATE_REFERRAL (DPDP-Pseudonymized Header Export)',
      childId: _selectedChild!.pseudoId,
      rawData: {
        'reason': generateReferralReason(),
        'age': _selectedChild!.age,
        'gender': _selectedChild!.gender,
      },
      tags: ['language', 'cognitive'],
    );
    _cryptoLogs.insert(0, log);
    _currentScreen = 'referral';
    notifyListeners();
  }

  void completeReferral() {
    final log = DataService.generateCryptoLog(
      action: 'EXPORT_REFERRAL_DOCUMENT',
      childId: _selectedChild?.pseudoId ?? 'unknown',
      rawData: {'referralReason': generateReferralReason()},
      tags: ['language'],
    );
    _cryptoLogs.insert(0, log);
    _currentScreen = 'profile';
    notifyListeners();
  }
}
