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

  // Draft auto-save state
  String? _draftTranscript;
  List<String>? _draftTags;
  String? _draftChildId;
  DateTime? _lastDraftSave;

  // Consent state
  bool _consentGiven = false;
  DateTime? _consentDate;

  // Navigation
  String _currentScreen = 'home';
  String? _previousScreen;

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
  String? get draftTranscript => _draftTranscript;
  List<String>? get draftTags => _draftTags;
  DateTime? get lastDraftSave => _lastDraftSave;
  bool get consentGiven => _consentGiven;
  DateTime? get consentDate => _consentDate;
  bool get hasDraft =>
      _draftTranscript != null && _draftTranscript!.isNotEmpty;

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
    _consentGiven = DataService.getConsent();
    _consentDate = DataService.getConsentDate();
    _loadDraft();
    // Show consent on first launch if not yet given
    if (!_consentGiven) {
      _previousScreen = _currentScreen;
      _currentScreen = 'consent';
    }
    notifyListeners();
  }

  void _loadDraft() {
    final draft = DataService.loadDraft();
    if (draft != null) {
      _draftTranscript = draft['transcript'] as String?;
      _draftTags = (draft['tags'] as List?)?.cast<String>();
      _draftChildId = draft['childId'] as String?;
      _lastDraftSave = draft['timestamp'] as DateTime?;
    }
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
    _previousScreen = _currentScreen;
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
        _currentScreen = _selectedChild != null ? 'profile' : 'home';
        break;
      case 'result':
      case 'referral':
      case 'add_child':
        _currentScreen = _selectedChild != null ? 'profile' : 'home';
        break;
      case 'settings':
      case 'consent':
        _currentScreen = _previousScreen ?? 'home';
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

  void openSettings() {
    _currentScreen = 'settings';
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

  // Navigate to record screen — mic not started yet.
  // The mic button on RecordScreen starts the actual recording.
  void startRecording() {
    _transcript = '';
    _tags = [];
    _isRecording = false; // NOT recording yet — user must tap mic
    _isSimulatedVoice = false;

    // Restore draft if available for this child
    if (_draftTranscript != null && _draftChildId == _selectedChild?.id) {
      _transcript = _draftTranscript!;
      _tags = _draftTags ?? [];
    }

    _currentScreen = 'record';
    notifyListeners();
  }

  // Called when user taps mic on RecordScreen — mic is now active.
  void onMicStarted() {
    _isRecording = true;
    notifyListeners();
  }

  void setSimulatedVoice(bool val) {
    _isSimulatedVoice = val;
    notifyListeners();
  }

  void onTranscriptUpdate(String text) {
    _transcript = text;
    // Auto-save draft periodically during recording
    if (_isRecording && text.isNotEmpty && text.length % 15 == 0) {
      _autoSaveDraft();
    }
    notifyListeners();
  }

  void cancelRecording() {
    _isRecording = false;
    _isSimulatedVoice = false;

    // Auto-save draft before canceling
    if (_transcript.isNotEmpty) {
      _autoSaveDraft();
    }

    _transcript = '';
    _currentScreen = _selectedChild != null ? 'profile' : 'home';
    notifyListeners();
  }

  // ─── Draft Auto-Save ──────────────────────────

  void _autoSaveDraft() {
    if (_transcript.isEmpty || _selectedChild == null) return;
    _draftTranscript = _transcript;
    _draftTags = _tags;
    _draftChildId = _selectedChild!.id;
    _lastDraftSave = DateTime.now();
    DataService.saveDraft(
      transcript: _transcript,
      tags: _tags,
      childId: _selectedChild!.id,
    );
  }

  void clearDraft() {
    _draftTranscript = null;
    _draftTags = null;
    _draftChildId = null;
    _lastDraftSave = null;
    DataService.clearDraft();
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
    final updatedProfile = Map<String, double>.from(_selectedChild!.profile);
    for (final tag in _tags) {
      updatedProfile[tag] =
          ((updatedProfile[tag] ?? 0.5) + 0.1).clamp(0.0, 1.0);
    }

    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    final newObs = Observation(
      date: dateStr,
      text: _transcript,
      method: _isSimulatedVoice ? 'voice_sim' : 'voice',
      domains: _tags,
    );

    // Update child
    _selectedChild!.profile = updatedProfile;
    _selectedChild!.observations = [
      newObs,
      ..._selectedChild!.observations
    ];

    // Update status based on profile
    final avg =
        updatedProfile.values.fold(0.0, (a, b) => a + b) / updatedProfile.length;
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

    // Clear draft after successful save
    clearDraft();

    _currentScreen = 'profile';
    notifyListeners();
  }

  // ─── Consent ───────────────────────────────────

  void giveConsent() {
    _consentGiven = true;
    _consentDate = DateTime.now();
    DataService.setConsent(true, _consentDate!);
    _currentScreen = 'home';
    notifyListeners();
  }

  // ─── Sync ──────────────────────────────────────

  void syncNow() {
    // Simulate sync — in production this POSTs to backend
    _outboxCount = 0;
    notifyListeners();
  }

  // ─── Export ────────────────────────────────────

  void exportData() {
    // Simulate CSV export — production uses Android MediaStore
    final obsCount =
        _children.fold(0, (sum, c) => sum + c.observations.length);
    final log = DataService.generateCryptoLog(
      action: 'EXPORT_CSV_RESEARCHER',
      childId: 'all_children',
      rawData: {'observationCount': obsCount},
      tags: [],
    );
    _cryptoLogs.insert(0, log);
    _outboxCount++;
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
