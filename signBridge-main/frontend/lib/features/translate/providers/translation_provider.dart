import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/audio_player_service.dart';

enum AppUserRole {
  passenger, // Deaf & Hard-of-Hearing Commuters & Waiting Hall Kiosks
  stationMaster, // Station Masters, PA Announcers & Dispatch Control
}

enum AnnouncementInputMode {
  quickDispatch, // Station Master Quick Train Dispatch
  presets, // Curated Regional Railway Presets
  text, // Live PA Speech & Custom Text
  simulation, // Acoustic Simulation & Benchmark Lab (YouTube/File)
  video, // Direct Video file upload
  youtube, // YouTube audio link
  audio, // Audio recording stream
}

class HistoryItem {
  final String? id;
  final String translation;
  final String? originalText;
  final String? station;
  final String? targetLang;
  final DateTime timestamp;

  HistoryItem({
    this.id,
    required this.translation,
    this.originalText,
    this.station,
    this.targetLang,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'translation': translation,
        'originalText': originalText,
        'station': station,
        'targetLang': targetLang,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id']?.toString(),
      translation: json['translation']?.toString() ?? '',
      originalText: json['originalText']?.toString(),
      station: json['station']?.toString(),
      targetLang: json['targetLang']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory HistoryItem.fromMap(Map<String, String> map) {
    return HistoryItem(
      id: map['id'],
      translation: map['translation'] ?? '',
      originalText: map['original_text'],
      station: map['station'],
      targetLang: map['target_lang'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class TranslationProvider extends ChangeNotifier {
  // TTS Engine
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  // Station & Role (Default to Dakshina Kannada: Mangaluru Central MAQ)
  String _selectedStationCode = 'MAQ';
  String _selectedStationName = 'Mangaluru Central (Dakshina Kannada)';

  // Dedicated Role Station Separation (Station Master duty vs. Passenger boarding)
  String _stationMasterStationCode = 'MAQ';
  String _stationMasterStationName = 'Mangaluru Central (Dakshina Kannada)';
  String _passengerStationCode = 'MAQ';
  String _passengerStationName = 'Mangaluru Central (Dakshina Kannada)';

  // Broadcast Origin Station (Which station issued the active announcement)
  String _broadcastStationCode = '';
  String _broadcastStationName = '';
  String _broadcastTrainNo = '';
  String _broadcastTrainName = '';

  AppUserRole _userRole = AppUserRole.passenger;
  AnnouncementInputMode _inputMode = AnnouncementInputMode.quickDispatch;
  String _watchedTrainNumber = '20631';
  String _passengerDestination = 'Thiruvananthapuram Central';

  // Processing & State
  bool _isProcessing = false;
  String _processingStatus = '';
  String? _errorMessage;

  // Role and Watch Alert Getters
  AppUserRole get userRole => _userRole;
  bool get isStationMaster => _userRole == AppUserRole.stationMaster;
  String get watchedTrainNumber => _watchedTrainNumber;
  String get passengerDestination => _passengerDestination;
  bool get hasActiveBroadcast => _originalTranscription.trim().isNotEmpty;

  String get stationMasterStationCode => _stationMasterStationCode;
  String get stationMasterStationName => _stationMasterStationName;
  String get passengerStationCode => _passengerStationCode;
  String get passengerStationName => _passengerStationName;
  String get broadcastStationCode => _broadcastStationCode;
  String get broadcastStationName => _broadcastStationName;
  String get broadcastTrainNo => _broadcastTrainNo;
  String get broadcastTrainName => _broadcastTrainName;

  /// Station code dynamically resolved by active user role
  String get selectedStationCode => isStationMaster ? _stationMasterStationCode : _passengerStationCode;
  String get selectedStationName => isStationMaster ? _stationMasterStationName : _passengerStationName;

  /// Station isolation: An announcement dispatched at Station X only appears on Station X passenger boards,
  /// UNLESS it is an emergency or safety alert which affects all passengers universally.
  bool get isBroadcastForPassengerStation {
    if (!hasActiveBroadcast) return false;
    if (isEmergencyOrSafetyAlert) return true;
    if (_broadcastStationCode.isEmpty || _broadcastStationCode == 'ALL') return true;
    return _broadcastStationCode.trim().toUpperCase() == _passengerStationCode.trim().toUpperCase();
  }

  bool get hasWatchedTrainAlert {
    if (!hasActiveBroadcast) return false;
    if (_watchedTrainNumber.trim().isEmpty) return false;
    final target = _watchedTrainNumber.trim();
    for (final ent in _namedEntities) {
      if (ent['entity_type'] == 'TRAIN_NUMBER' && ent['text']?.toString().contains(target) == true) {
        return true;
      }
    }
    return _originalTranscription.contains(target) || _translatedAnnouncement.contains(target);
  }

  bool get hasDestinationAlert {
    if (!hasActiveBroadcast) return false;
    if (_passengerDestination.trim().isEmpty) return false;
    final target = _passengerDestination.trim().toLowerCase();
    for (final ent in _namedEntities) {
      if ((ent['entity_type'] == 'DESTINATION' || ent['entity_type'] == 'STATION') &&
          ent['text']?.toString().toLowerCase().contains(target) == true) {
        return true;
      }
    }
    return _originalTranscription.toLowerCase().contains(target) ||
           _translatedAnnouncement.toLowerCase().contains(target);
  }

  bool get hasTripAlert => hasDestinationAlert || hasWatchedTrainAlert;

  /// Emergency or Public Safety Notice: Affects all commuters universally regardless of destination.
  bool get isEmergencyOrSafetyAlert {
    if (!hasActiveBroadcast) return false;
    final category = _stagedAnnouncement?['announcement_category']?.toString().toLowerCase() ?? '';
    if (category == 'station_safety') return true;

    final lower = (_originalTranscription + ' ' + _translatedAnnouncement).toLowerCase();
    final safetyWords = [
      'security alert', 'security', 'safety alert', 'emergency', 'danger', 'caution',
      'unattended', 'unclaimed', 'suspicious', 'missing child', 'lost child',
      'missing person', 'lost person', 'lost wallet', 'lost phone', 'lost bag',
      'evacuate', 'rpf', 'railway police', 'helpline 139', '139'
    ];
    for (final w in safetyWords) {
      if (lower.contains(w)) return true;
    }
    return false;
  }

  /// Platform display: Strictly follows Rule 8 (never invents fake platforms like defaulting to 1).
  String get currentPlatformDisplay {
    for (final ent in _namedEntities) {
      if (ent['entity_type'] == 'PLATFORM') {
        final val = ent['text']?.toString().trim() ?? '';
        if (val.isNotEmpty && val != '0' && val != '?') return val;
      }
    }
    final match = RegExp(r'platform\s*(?:number|no\.?)?\s*(\d+)', caseSensitive: false).firstMatch(_originalTranscription);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    return 'Standby / TBA';
  }

  bool get hasPlatformAssigned => currentPlatformDisplay != 'Standby / TBA';

  List<Map<String, dynamic>> _matchedTrains = [];
  List<Map<String, dynamic>> get matchedTrains => _matchedTrains;
  bool _isLoadingTrains = false;
  bool get isLoadingTrains => _isLoadingTrains;

  Future<void> updateJourneyMatches() async {
    if (_passengerDestination.trim().isEmpty) {
      _matchedTrains = [];
      notifyListeners();
      return;
    }
    _isLoadingTrains = true;
    notifyListeners();
    try {
      final matches = await ApiService.matchPassengerJourney(
        fromStation: _selectedStationCode,
        destination: _passengerDestination,
      );
      _matchedTrains = matches;
    } catch (_) {
      _matchedTrains = [];
    } finally {
      _isLoadingTrains = false;
      notifyListeners();
    }
  }

  // Staging for Station Master Review Before Broadcasting
  Map<String, dynamic>? _stagedAnnouncement;
  Map<String, dynamic>? get stagedAnnouncement => _stagedAnnouncement;
  bool get hasStagedAnnouncement => _stagedAnnouncement != null;
  bool get isStagedRailwayAnnouncement => _stagedAnnouncement?['is_railway_announcement'] ?? true;
  String get stagedValidationReason => _stagedAnnouncement?['railway_validation_reason']?.toString() ?? '';

  // YouTube & Audio Input
  String _youtubeUrl = '';
  Map<String, dynamic>? _videoMetadata;

  // Content
  String _originalTranscription = '';
  String _detectedLanguage = 'English';
  String _targetLanguage = 'en'; // English by default
  String _translatedAnnouncement = '';
  String _latinTransliteration = '';
  Map<String, dynamic> _allTranslations = {};
  List<Map<String, dynamic>> _namedEntities = [];
  List<Map<String, dynamic>> _fingerspellingCards = [];

  // Indian Sign Language (ISL) Sequence & Player
  List<Map<String, dynamic>> _islSequence = [];
  int _activeGestureIndex = 0;
  bool _isPlayingISL = false;
  bool _isSequenceCompleted = false;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;
  Timer? _gestureTimer;
  String? _customVideoUrl;

  // History & Cache
  List<HistoryItem> _history = [];
  bool _isLoadingHistory = false;

  String get currentTranslation => _translatedAnnouncement;
  bool get isConnected => true;

  void clearCurrentTranslation() {
    _translatedAnnouncement = '';
    notifyListeners();
  }

  // Getters
  FlutterTts get tts => _tts;
  bool get isSpeaking => _isSpeaking;
  AnnouncementInputMode get inputMode => _inputMode;
  bool get isProcessing => _isProcessing;
  String get processingStatus => _processingStatus;
  String? get errorMessage => _errorMessage;

  String get youtubeUrl => _youtubeUrl;
  Map<String, dynamic>? get videoMetadata => _videoMetadata;
  String get originalTranscription => _originalTranscription;
  String get detectedLanguage => _detectedLanguage;
  String get targetLanguage => _targetLanguage;
  String get translatedAnnouncement => _translatedAnnouncement;
  String get latinTransliteration => _latinTransliteration;
  Map<String, dynamic> get allTranslations => _allTranslations;
  String? _uploadedVideoName;
  String? get uploadedVideoName => _uploadedVideoName;
  void clearUploadedVideo() {
    _uploadedVideoName = null;
    notifyListeners();
  }

  String get detectedLanguageCode {
    if (_originalTranscription.isEmpty) return 'en';
    int enCount = 0;
    int knCount = 0;
    int teCount = 0;
    int taCount = 0;
    int hiCount = 0;
    int bnCount = 0;
    int mlCount = 0;
    int guCount = 0;

    for (int i = 0; i < _originalTranscription.length; i++) {
      int c = _originalTranscription.codeUnitAt(i);
      if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 48 && c <= 57)) {
        enCount++;
      } else if (c >= 0x0C80 && c <= 0x0CFF) {
        knCount++;
      } else if (c >= 0x0C00 && c <= 0x0C7F) {
        teCount++;
      } else if (c >= 0x0B80 && c <= 0x0BFF) {
        taCount++;
      } else if (c >= 0x0900 && c <= 0x097F) {
        hiCount++;
      } else if (c >= 0x0980 && c <= 0x09FF) {
        bnCount++;
      } else if (c >= 0x0D00 && c <= 0x0D7F) {
        mlCount++;
      } else if (c >= 0x0A80 && c <= 0x0AFF) {
        guCount++;
      }
    }

    int indicTotal = knCount + teCount + taCount + hiCount + bnCount + mlCount + guCount;
    if (enCount >= indicTotal && enCount > 0) return 'en';
    if (knCount >= hiCount && knCount > 0) return 'kn';
    if (hiCount > 0) return 'hi';
    if (teCount > 0) return 'te';
    if (taCount > 0) return 'ta';
    if (bnCount > 0) return 'bn';
    if (mlCount > 0) return 'ml';
    if (guCount > 0) return 'gu';
    return 'en';
  }

  bool _showAllLanguagesTogether = false;
  bool get showAllLanguagesTogether => _showAllLanguagesTogether;
  void setShowAllLanguagesTogether(bool val) {
    _showAllLanguagesTogether = val;
    notifyListeners();
  }
  void toggleShowAllLanguagesTogether() {
    _showAllLanguagesTogether = !_showAllLanguagesTogether;
    notifyListeners();
  }

  String get transliterationLabel {
    switch (_targetLanguage) {
      case 'te':
        return 'Tenglish (Telugu in Latin script)';
      case 'kn':
        return 'Kannglish (Kannada in Latin script)';
      case 'hi':
        return 'Hinglish (Hindi in Latin script)';
      case 'ta':
        return 'Tanglish (Tamil in Latin script)';
      case 'mr':
        return 'Marathish (Marathi in Latin script)';
      case 'bn':
        return 'Banglish (Bengali in Latin script)';
      case 'ml':
        return 'Manglish (Malayalam in Latin script)';
      case 'gu':
        return 'Gujarati (Latin script)';
      default:
        return 'Phonetic English';
    }
  }

  List<Map<String, dynamic>> get namedEntities => _namedEntities;
  List<Map<String, dynamic>> get fingerspellingCards => _fingerspellingCards;

  List<Map<String, dynamic>> get islSequence => _islSequence;
  int get activeGestureIndex => _activeGestureIndex;
  bool get isPlayingISL => _isPlayingISL;
  bool get isSequenceCompleted => _isSequenceCompleted;
  double get playbackSpeed => _playbackSpeed;
  bool get isLooping => _isLooping;
  String? get customVideoUrl => _customVideoUrl;
  List<HistoryItem> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;

  TranslationProvider() {
    _initTts();
    _loadSampleDefault();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString('app_user_role');
      if (roleStr == 'stationMaster') {
        _userRole = AppUserRole.stationMaster;
        _inputMode = AnnouncementInputMode.quickDispatch;
      } else {
        _userRole = AppUserRole.passenger;
        _inputMode = AnnouncementInputMode.presets;
      }
      _watchedTrainNumber = prefs.getString('watched_train_number') ?? '0245';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.85);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (_) {}
  }

  void _loadSampleDefault() {
    // Start with a clean, authentic idle state. No fake or premature broadcast on startup!
    _originalTranscription = '';
    _translatedAnnouncement = '';
    _latinTransliteration = '';
    _allTranslations = {};
    _namedEntities = [];
    _islSequence = [];
  }

  /// Official Varanasi Rajdhani Express Announcement (Pre-translated across 9 languages for instant 0ms dispatch)
  void broadcastVaranasiRajdhani() {
    _originalTranscription =
        'May I have your attention please. Train number 0245 Rajdhani Express from Mangaluru Central to Varanasi is arriving on platform number 2. Passengers please take note.';
    
    // Instant pre-cached translations across 9 regional languages (0 wait time)
    _allTranslations = {
      'kn': {
        'native': 'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಗಾಡಿ ಸಂಖ್ಯೆ 0245 ಮಂಗಳೂರು ಸೆಂಟ್ರಲ್‌ನಿಂದ ವಾರಣಾಸಿಗೆ ತೆರಳುವ ರಾಜಧಾನಿ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 2 ಕ್ಕೆ ಬರಲಿದೆ. ಪ್ರಯಾಣಿಕರು ಗಮನಿಸಬೇಕಾಗಿ ವಿನಂತಿ.',
        'latin': 'Prayāṇikara gamanakke. Gāḍi saṅkhye 0245 Mangaluru Central ninḍa Varanasi ge teraluva Rajadhani Express platform 2 kke baralide. Prayanikaru gamanisabekagi vinanti.',
        'name': 'ಕನ್ನಡ (Kannada)',
      },
      'hi': {
        'native': 'यात्रियों कृपया ध्यान दें। गाड़ी संख्या 0245 मंगलुरु सेंट्रल से वाराणसी जाने वाली राजधानी एक्सप्रेस प्लेटफॉर्म संख्या 2 पर आ रही है। यात्रीगण कृपया ध्यान दें।',
        'latin': 'Yatriyon kripya dhyan dein. Gaadi sankhya 0245 Mangaluru Central se Varanasi jaane wali Rajdhani Express platform sankhya 2 par aa rahi hai. Yatreegan kripya dhyan dein.',
        'name': 'हिन्दी (Hindi)',
      },
      'en': {
        'native': 'May I have your attention please. Train number 0245 Rajdhani Express from Mangaluru Central to Varanasi is arriving on platform number 2. Passengers please take note.',
        'latin': 'May I have your attention please. Train number 0245 Rajdhani Express from Mangaluru Central to Varanasi is arriving on platform number 2. Passengers please take note.',
        'name': 'English',
      },
      'te': {
        'native': 'ప్రయాణీకుల గమనిక. మంగళూరు సెంట్రల్ నుండి వారణాసికి వెళ్లే రైలు నెంబర్ 0245 రాజధాని ఎక్స్‌ప్రెస్ ప్లాట్‌ఫారమ్ నెంబర్ 2 కి చేరుకుంటుంది. ప్రయాణీకులు గమనించగలరు.',
        'latin': 'Prayaneekula gamanika. Mangaluru Central nundi Varanasi ki velle railu number 0245 Rajdhani Express platform number 2 ki cherukuntundi. Prayaneekulu gamaninchagalaru.',
        'name': 'తెలుగు (Telugu)',
      },
      'ta': {
        'native': 'பயணிகள் கவனத்திற்கு. மங்களூரு சென்ட்ரலில் இருந்து வாரணாசி செல்லும் ரயில் எண் 0245 ராஜ்தானி எக்ஸ்பிரஸ் நடைமேடை 2-ல் வருகிறது. பயணிகள் குறித்துக் கொள்க.',
        'latin': 'Payanigal kavanathirku. Mangaluru Central-ilirunthu Varanasi sellum train number 0245 Rajdhani Express nadaimedai 2-il varugirathu. Payanigal kurithuk kolga.',
        'name': 'தமிழ் (Tamil)',
      },
      'mr': {
        'native': 'प्रवाशांनी कृपया लक्ष द्या. मंगळुरू सेंट्रल ते वाराणसी जाणारी गाडी क्रमांक 0245 राजधानी एक्सप्रेस प्लॅटफॉर्म क्रमांक 2 वर येत आहे. प्रवाशांनी नोंद घ्यावी.',
        'latin': 'Pravashanni krupaya laksha dya. Mangaluru Central te Varanasi jaanari gaadi kramank 0245 Rajdhani Express platform kramank 2 var yet aahe. Pravashanni nond ghyavi.',
        'name': 'मराठी (Marathi)',
      },
      'bn': {
        'native': 'যাত্রী সাধারণের দৃষ্টি আকর্ষণ করা হচ্ছে। ম্যাঙ্গালোর সেন্ট্রাল থেকে বারাণসীগামী ট্রেন নম্বর 0245 রাজধানী এক্সপ্রেস 2 নম্বর প্ল্যাটফর্মে আসছে। যাত্রীরা লক্ষ্য করুন।',
        'latin': 'Yatri shadharoner drishti aakorshon kora hochhe. Mangaluru Central theke Varanasi gami train number 0245 Rajdhani Express 2 number platforme aasche. Yatria lokkho korun.',
        'name': 'বাংলা (Bengali)',
      },
      'ml': {
        'native': 'യാത്രക്കാരുടെ ശ്രദ്ധയ്ക്ക്. മംഗളൂരു സെൻട്രലിൽ നിന്ന് വാരാണസിയിലേക്കുള്ള ട്രെയിൻ നമ്പർ 0245 രാജധാനി എക്സ്പ്രസ് പ്ലാറ്റ്‌ഫോം 2-ൽ എത്തിച്ചേരുന്നു. ദയവായി ശ്രദ്ധിക്കുക.',
        'latin': 'Yaathrakkarude shraddhaykku. Mangaluru Central-il ninnu Varanasikku ulla train number 0245 Rajdhani Express platform 2-il ethichcherunnu. Dayavayi shraddhikkuka.',
        'name': 'മലയാളം (Malayalam)',
      },
      'gu': {
        'native': 'યાત્રીઓ કૃપા કરીને ધ્યાન આપો. મેંગલોર સેન્ટ્રલથી વારાણસી જતી ટ્રેન નંબર 0245 રાજધાની એક્સપ્રેસ પ્લેટફોર્મ નંબર 2 પર આવી રહી છે. યાત્રીઓ નોંધ લે.',
        'latin': 'Yatrio krupa karine dhyan aapo. Mangaluru Central thi Varanasi jati train number 0245 Rajdhani Express platform number 2 par aavi rahi chhe. Yatrio nondh le.',
        'name': 'ગુજરાતી (Gujarati)',
      },
    };

    if (_allTranslations.containsKey(_targetLanguage)) {
      final t = _allTranslations[_targetLanguage];
      if (t is Map) {
        _translatedAnnouncement = t['native']?.toString() ?? '';
        _latinTransliteration = t['latin']?.toString() ?? '';
      }
    } else {
      _translatedAnnouncement = _allTranslations['en']?['native'] ?? _originalTranscription;
      _latinTransliteration = _allTranslations['kn']?['latin'] ?? '';
    }

    _namedEntities = [
      {
        'text': '0245',
        'entity_type': 'TRAIN_NUMBER',
        'label': 'Train 0245',
        'fingerspell': ['0', '2', '4', '5']
      },
      {
        'text': 'Rajdhani Express',
        'entity_type': 'TRAIN_NAME',
        'label': 'Rajdhani Express',
        'fingerspell': ['R', 'A', 'J', 'D', 'H', 'A', 'N', 'I']
      },
      {
        'text': 'Mangaluru Central',
        'entity_type': 'STATION',
        'label': 'Origin: Mangaluru Central',
        'fingerspell': ['M', 'A', 'Q']
      },
      {
        'text': 'Varanasi',
        'entity_type': 'DESTINATION',
        'label': 'Destination: Varanasi',
        'fingerspell': ['V', 'A', 'R', 'A', 'N', 'A', 'S', 'I'],
        'explanation': 'Heading to Varanasi Junction (Banaras / Kashi)'
      },
      {
        'text': '2',
        'entity_type': 'PLATFORM',
        'label': 'Platform 2',
        'fingerspell': ['2']
      }
    ];
    _islSequence = ApiService.getFallbackISLSequence('chennai_exp');
    notifyListeners();
    processText(_originalTranscription);
  }

  /// Instant 1-tap pre-cached broadcast for Train 20608 Vande Bharat Express to Puttur (PF 1)
  /// Verified Train 20631 Vande Bharat Express (Mangaluru Central to Thiruvananthapuram)
  void broadcastVandeBharat20631() {
    broadcastCustomAnnouncement(
      trainNo: '20631',
      trainName: 'Vande Bharat Express',
      platform: '1',
      destination: 'Thiruvananthapuram Central',
      originStationCode: 'MAQ',
      originStationName: 'Mangaluru Central',
      customText: 'May I have your attention please. Train number 20631 Vande Bharat Express from Mangaluru Central to Thiruvananthapuram Central is ready for departure on platform number 1. Passengers please take note.'
    );
  }

  /// Verified Train 12620 Matsyagandha Express (Mangaluru Central to Mumbai LTT)
  void broadcastMatsyagandha12620() {
    broadcastCustomAnnouncement(
      trainNo: '12620',
      trainName: 'Matsyagandha Express',
      platform: '2',
      destination: 'Mumbai LTT',
      customText: 'May I have your attention please. Train number 12620 Matsyagandha Express from Mangaluru Central to Lokmanya Tilak Terminus Mumbai is ready for departure on platform number 2.'
    );
  }

  /// Verified Train 16595 Panchaganga Express (Bengaluru to Karwar via Western Ghats)
  void broadcastPanchaganga16595() {
    broadcastCustomAnnouncement(
      trainNo: '16595',
      trainName: 'Panchaganga Express',
      platform: '1',
      destination: 'Karwar',
      originStationCode: 'SL',
      originStationName: 'Surathkal',
      customText: 'May I have your attention please. Train number 16595 Panchaganga Express from KSR Bengaluru to Karwar via Subrahmanya Road, Kabaka Puttur, Bantwal, and Surathkal is arriving on platform number 1 at Surathkal Station.'
    );
  }

  /// Verified Train 56625 Passenger (Mangaluru Central to Subrahmanya Road)
  void broadcastSubrahmanyaPassenger56625() {
    broadcastCustomAnnouncement(
      trainNo: '56625',
      trainName: 'Passenger',
      platform: '2',
      destination: 'Subrahmanya Road',
      customText: 'May I have your attention please. Train number 56625 Passenger from Mangaluru Central to Subrahmanya Road is arriving on platform number 2.'
    );
  }

  /// Verified Emergency Security Alert (Preserved universally for all commuters)
  void broadcastEmergencySecurityAlert() {
    _broadcastStationCode = 'ALL';
    _broadcastStationName = 'All Dakshina Kannada Stations';
    _broadcastTrainNo = '';
    _broadcastTrainName = 'Security Alert';
    final alertText = 'Security alert. If you notice any suspicious, unclaimed, or unattended baggage on railway premises, please do not touch it. Immediately alert the on-duty Railway Protection Force or call railway helpline 139.';
    _originalTranscription = alertText;
    _detectedLanguage = 'English';
    _errorMessage = null;

    _namedEntities = [
      {'text': '139', 'entity_type': 'PHONE_NUMBER', 'label': 'Helpline 139', 'fingerspell': ['1', '3', '9']},
      {'text': 'RPF', 'entity_type': 'ORGANIZATION', 'label': 'Security Force', 'fingerspell': ['R', 'P', 'F']}
    ];

    _allTranslations = {
      'en': {'native': alertText, 'latin': alertText, 'name': 'English'},
      'kn': {'native': 'ಸುರಕ್ಷತಾ ಎಚ್ಚರಿಕೆ. ರೈಲ್ವೆ ಆವರಣದಲ್ಲಿ ಯಾವುದೇ ಅನುಮಾನಾಸ್ಪದ, ಮಾಲೀಕರಿಲ್ಲದ ಬ್ಯಾಗ್ ಕಂಡುಬಂದಲ್ಲಿ, ಮುಟ್ಟಬೇಡಿ. 139 ಗೆ ಕರೆ ಮಾಡಿ.', 'latin': 'Surakshata eccharike. Railve aavaranadalli yaavude bag kandubandalli muttabedi. 139 ge call maadi.', 'name': 'ಕನ್ನಡ (Kannada)'},
      'hi': {'native': 'सुरक्षा चेतावनी। यदि आपको रेलवे परिसर में लावारिस वस्तु दिखाई दे, तो उसे न छुएं। हेल्पलाइन 139 पर संपर्क करें।', 'latin': 'Suraksha chetavni. Yadi aapko railway parisar me laavaris vastu dikhayi de, to use na chhuen. Helpline 139 par sampark karein.', 'name': 'हिन्दी (Hindi)'}
    };

    _translatedAnnouncement = _allTranslations['kn']?['native'] ?? alertText;
    _latinTransliteration = _allTranslations['kn']?['latin'] ?? '';
    _islSequence = ApiService.getFallbackISLSequence('security_alert');
    _activeGestureIndex = 0;
    _isSequenceCompleted = false;
    _isPlayingISL = false;

    _addHistoryRecord(
      translation: _translatedAnnouncement,
      originalText: _originalTranscription,
      station: _selectedStationName,
      targetLang: _targetLanguage,
    );

    notifyListeners();
  }

  void broadcastPutturVandeBharat() {
    _originalTranscription =
        'May I have your attention please. Train number 20608 Vande Bharat Express from Mangaluru Central to Puttur is arriving on platform number 1. Passengers please take note.';
    _detectedLanguage = 'English';
    _customVideoUrl = null;
    _errorMessage = null;

    _allTranslations = {
      'kn': {
        'native':
            'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಮಂಗಳೂರು ಸೆಂಟ್ರಲ್‌ನಿಂದ ಪುತ್ತೂರಿಗೆ ತೆರಳುವ ರೈಲು ಸಂಖ್ಯೆ 20608 ವಂದೇ ಭಾರತ್ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 1 ಕ್ಕೆ ಆಗಮಿಸುತ್ತಿದೆ. ಪ್ರಯಾಣಿಕರು ಗಮನಿಸಬೇಕಾಗಿ ವಿನಂತಿ.',
        'latin':
            'Prayaanikara gamanakke. Mangaluru Central-ninda Putturige theraluva railu sankhye 20608 Vande Bharat Express platform sankhye 1 kke aagamisuthide. Prayaanikaru gamanisabekagi vinanthi.',
        'name': 'ಕನ್ನಡ (Kannada)',
      },
      'en': {
        'native':
            'May I have your attention please. Train number 20608 Vande Bharat Express from Mangaluru Central to Puttur is arriving on platform number 1. Passengers please take note.',
        'latin':
            'May I have your attention please. Train number 20608 Vande Bharat Express from Mangaluru Central to Puttur is arriving on platform number 1. Passengers please take note.',
        'name': 'English',
      },
      'hi': {
        'native':
            'यात्रियों कृपया ध्यान दें। मंगलुरु सेंट्रल से पुत्तूर जाने वाली गाड़ी संख्या 20608 वंदे भारत एक्सप्रेस प्लेटफॉर्म संख्या 1 पर आ रही है। यात्रीगण कृपया ध्यान दें।',
        'latin':
            'Yatriyon kripya dhyan dein. Mangaluru Central se Puttur jaane wali gaadi sankhya 20608 Vande Bharat Express platform sankhya 1 par aa rahi hai. Yatreegan kripya dhyan dein.',
        'name': 'हिन्दी (Hindi)',
      },
      'te': {
        'native':
            'ప్రయాణీకుల గమనిక. మంగళూరు సెంట్రల్ నుండి పుత్తూరు వెళ్లే రైలు నెంబర్ 20608 వందే భారత్ ఎక్స్‌ప్రెస్ ప్లాట్‌ఫారమ్ నెంబర్ 1 కి చేరుకుంటుంది. ప్రయాణీకులు గమనించగలరు.',
        'latin':
            'Prayaneekula gamanika. Mangaluru Central nundi Putturu velle railu number 20608 Vande Bharat Express platform number 1 ki cherukuntundi. Prayaneekulu gamaninchagalaru.',
        'name': 'తెలుగు (Telugu)',
      },
      'ta': {
        'native':
            'பயணிகள் கவனத்திற்கு. மங்களூரு சென்ட்ரலில் இருந்து புத்தூர் செல்லும் ரயில் எண் 20608 வந்தே பாரத் எக்ஸ்பிரஸ் நடைமேடை 1-ல் வருகிறது. பயணிகள் குறித்துக் கொள்க.',
        'latin':
            'Payanigal kavanathirku. Mangaluru Central-ilirunthu Puttur sellum train number 20608 Vande Bharat Express nadaimedai 1-il varugirathu. Payanigal kurithuk kolga.',
        'name': 'தமிழ் (Tamil)',
      },
      'mr': {
        'native':
            'प्रवाशांनी कृपया लक्ष द्या. मंगळुरू सेंट्रल ते पुत्तूर जाणारी गाडी क्रमांक 20608 वंदे भारत एक्सप्रेस प्लॅटफॉर्म क्रमांक 1 वर येत आहे. प्रवाशांनी नोंद घ्यावी.',
        'latin':
            'Pravashanni krupaya laksha dya. Mangaluru Central te Puttur jaanari gaadi kramank 20608 Vande Bharat Express platform kramank 1 var yet aahe. Pravashanni nond ghyavi.',
        'name': 'मराठी (Marathi)',
      },
      'bn': {
        'native':
            'যাত্রী সাধারণের দৃষ্টি আকর্ষণ করা হচ্ছে। ম্যাঙ্গালোর সেন্ট্রাল থেকে পুত্তুরগামী ট্রেন নম্বর 20608 বন্দে ভারত এক্সপ্রেস 1 নম্বর প্ল্যাটফর্মে আসছে। যাত্রীরা লক্ষ্য করুন।',
        'latin':
            'Yatri shadharoner drishti aakorshon kora hochhe. Mangaluru Central theke Putturgami train number 20608 Vande Bharat Express 1 number platforme aasche. Yatria lokkho korun.',
        'name': 'বাংলা (Bengali)',
      },
      'ml': {
        'native':
            'യാത്രക്കാരുടെ ശ്രദ്ധയ്ക്ക്. മംഗളൂരു സെൻട്രലിൽ നിന്ന് പുത്തൂരിലേക്കുള്ള ട്രെയിൻ നമ്പർ 20608 വന്ദേ ഭാരത് എക്സ്പ്രസ് പ്ലാറ്റ്‌ഫോം 1-ൽ എത്തിച്ചേരുന്നു. ദയവായി ശ്രദ്ധിക്കുക.',
        'latin':
            'Yaathrakkarude shraddhaykku. Mangaluru Central-il ninnu Putturilekku ulla train number 20608 Vande Bharat Express platform 1-il ethichcherunnu. Dayavayi shraddhikkuka.',
        'name': 'മലയാളം (Malayalam)',
      },
      'gu': {
        'native':
            'યાત્રીઓ કૃપા કરીને ધ્યાન આપો. મેંગલોર સેન્ટ્રલથી પુત્તૂર જતી ટ્રેન નંબર 20608 વંદે ભારત એક્સપ્રેસ પ્લેટફોર્મ નંબર 1 પર આવી રહી છે. યાત્રીઓ નોંધ લે.',
        'latin':
            'Yatrio krupa karine dhyan aapo. Mangaluru Central thi Puttur jati train number 20608 Vande Bharat Express platform number 1 par aavi rahi chhe. Yatrio nondh le.',
        'name': 'ગુજરાતી (Gujarati)',
      },
    };

    if (_allTranslations.containsKey(_targetLanguage)) {
      final t = _allTranslations[_targetLanguage];
      if (t is Map) {
        _translatedAnnouncement = t['native']?.toString() ?? '';
        _latinTransliteration = t['latin']?.toString() ?? '';
      }
    } else {
      _translatedAnnouncement = _allTranslations['en']?['native'] ?? _originalTranscription;
      _latinTransliteration = _allTranslations['kn']?['latin'] ?? '';
    }

    _namedEntities = [
      {
        'text': '20608',
        'entity_type': 'TRAIN_NUMBER',
        'label': 'Train 20608',
        'fingerspell': ['2', '0', '6', '0', '8']
      },
      {
        'text': 'Vande Bharat Express',
        'entity_type': 'TRAIN_NAME',
        'label': 'Vande Bharat Express',
        'fingerspell': ['V', 'A', 'N', 'D', 'E']
      },
      {
        'text': 'Mangaluru Central',
        'entity_type': 'STATION',
        'label': 'Origin: Mangaluru Central',
        'fingerspell': ['M', 'A', 'Q']
      },
      {
        'text': 'Puttur',
        'entity_type': 'DESTINATION',
        'label': 'Destination: Puttur',
        'fingerspell': ['P', 'U', 'T', 'T', 'U', 'R'],
        'explanation': 'Heading to Kabaka Puttur (Dakshina Kannada)'
      },
      {
        'text': '1',
        'entity_type': 'PLATFORM',
        'label': 'Platform 1',
        'fingerspell': ['1']
      }
    ];
    _islSequence = ApiService.getFallbackISLSequence('vande_bharat');
    _activeGestureIndex = 0;
    _isSequenceCompleted = false;
    _isPlayingISL = false;
    processText(_originalTranscription);
    notifyListeners();
  }

  /// Broadcast a custom announcement with verified railway entities
  void broadcastCustomAnnouncement({
    required String trainNo,
    required String trainName,
    required String platform,
    required String destination,
    String? originStationCode,
    String? originStationName,
    String? status,
    String? customText,
  }) {
    final originCode = (originStationCode != null && originStationCode.isNotEmpty)
        ? originStationCode
        : _stationMasterStationCode;
    final originName = (originStationName != null && originStationName.isNotEmpty)
        ? originStationName
        : _stationMasterStationName;
    _broadcastStationCode = originCode;
    _broadcastStationName = originName;
    _broadcastTrainNo = trainNo.trim();
    _broadcastTrainName = trainName.trim();
    final trainNum = trainNo.trim().isNotEmpty ? trainNo.trim() : '20608';
    final tName = trainName.trim().isNotEmpty ? trainName.trim() : 'Express';
    final plat = platform.trim().isNotEmpty ? platform.trim() : '1';
    final dest = destination.trim().isNotEmpty ? destination.trim() : 'Puttur';

    final fullText = (customText != null && customText.trim().isNotEmpty)
        ? customText.trim()
        : 'May I have your attention please. Train number $trainNum $tName to $dest is arriving on platform number $plat. Passengers please take note.';

    _originalTranscription = fullText;
    _detectedLanguage = 'English';
    _errorMessage = null;

    _namedEntities = [
      {'text': trainNum, 'entity_type': 'TRAIN_NUMBER', 'label': 'Train $trainNum', 'fingerspell': trainNum.split('')},
      {'text': tName, 'entity_type': 'TRAIN_NAME', 'label': tName, 'fingerspell': tName.split(' ')[0].toUpperCase().split('')},
      {'text': _selectedStationName, 'entity_type': 'STATION', 'label': 'Origin: $_selectedStationName'},
      {'text': dest, 'entity_type': 'DESTINATION', 'label': 'Destination: $dest', 'fingerspell': dest.toUpperCase().split('')},
      {'text': plat, 'entity_type': 'PLATFORM', 'label': 'Platform $plat', 'fingerspell': [plat]},
    ];

    _allTranslations = {
      'en': {
        'native': fullText,
        'latin': fullText,
        'name': 'English',
      },
      'kn': {
        'native': 'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ರೈಲು ಸಂಖ್ಯೆ $trainNum $tName $dest ಕಡೆಗೆ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ $plat ಕ್ಕೆ ಆಗಮಿಸುತ್ತಿದೆ. ಪ್ರಯಾಣಿಕರು ಗಮನಿಸಬೇಕಾಗಿ ವಿನಂತಿ.',
        'latin': 'Prayaanikara gamanakke. Train number $trainNum $tName $dest kadege platform sankhye $plat kke aagamisuthide. Prayaanikaru gamanisabekagi vinanthi.',
        'name': 'ಕನ್ನಡ (Kannada)',
      },
      'hi': {
        'native': 'यात्रियों कृपया ध्यान दें। गाड़ी संख्या $trainNum $tName $dest जाने वाली प्लेटफॉर्म संख्या $plat पर आ रही है।',
        'latin': 'Yatriyon kripya dhyan dein. Gaadi sankhya $trainNum $tName $dest jaane wali platform sankhya $plat par aa rahi hai.',
        'name': 'हिन्दी (Hindi)',
      },
      'te': {
        'native': 'ప్రయాణీకుల గమనిక. రైలు నెంబర్ $trainNum $tName $dest వెళ్లే ప్లాట్‌ఫారమ్ నెంబర్ $plat కి చేరుకుంటుంది.',
        'latin': 'Prayaneekula gamanika. Train number $trainNum $tName $dest velle platform number $plat ki cherukuntundi.',
        'name': 'తెలుగు (Telugu)',
      },
      'ta': {
        'native': 'பயணிகள் கவனத்திற்கு. ரயில் எண் $trainNum $tName $dest செல்லும் நடைமேடை $plat-ல் வருகிறது.',
        'latin': 'Payanigal kavanathirku. Train number $trainNum $tName $dest sellum nadaimedai $plat-il varugirathu.',
        'name': 'தமிழ் (Tamil)',
      },
      'mr': {
        'native': 'प्रवाशांनी कृपया लक्ष द्या. गाडी क्रमांक $trainNum $tName $dest जाणारी प्लॅटफॉर्म क्रमांक $plat वर येत आहे.',
        'latin': 'Pravashanni krupaya laksha dya. Gaadi kramank $trainNum $tName $dest jaanari platform kramank $plat var yet aahe.',
        'name': 'मराठी (Marathi)',
      },
      'bn': {
        'native': 'যাত্রী সাধারণের দৃষ্টি আকর্ষণ করা হচ্ছে। ট্রেন নম্বর $trainNum $tName $dest গামী $plat নম্বর প্ল্যাটফর্মে আসছে।',
        'latin': 'Yatri shadharoner drishti aakorshon kora hochhe. Train number $trainNum $tName $dest gami $plat number platforme aasche.',
        'name': 'বাংলা (Bengali)',
      },
      'ml': {
        'native': 'യാത്രക്കാരുടെ ശ്രദ്ധയ്ക്ക്. ട്രെയിൻ നമ്പർ $trainNum $tName $dest ലേക്കുള്ള പ്ലാറ്റ്‌ഫോം $plat-ൽ എത്തിച്ചೇരുന്നു.',
        'latin': 'Yaathrakkarude shraddhaykku. Train number $trainNum $tName $dest lekku ulla platform $plat-il ethichcherunnu.',
        'name': 'മലയാളം (Malayalam)',
      },
      'gu': {
        'native': 'યાત્રીઓ કૃપા કરીને ધ્યાન આપો. ટ્રેન નંબર $trainNum $tName $dest જતી પ્લેટફોર્મ નંબર $plat પર આવી રહી છે.',
        'latin': 'Yatrio krupa karine dhyan aapo. Train number $trainNum $tName $dest jati platform number $plat par aavi rahi chhe.',
        'name': 'ગુજરાતી (Gujarati)',
      },
    };

    if (_allTranslations.containsKey(_targetLanguage)) {
      final t = _allTranslations[_targetLanguage];
      if (t is Map) {
        _translatedAnnouncement = t['native']?.toString() ?? '';
        _latinTransliteration = t['latin']?.toString() ?? '';
      }
    } else {
      _translatedAnnouncement = _allTranslations['en']?['native'] ?? fullText;
      _latinTransliteration = _allTranslations['kn']?['latin'] ?? '';
    }

    _islSequence = ApiService.getFallbackISLSequence('vande_bharat');
    _activeGestureIndex = 0;
    _isSequenceCompleted = false;
    _isPlayingISL = false;
    processText(fullText);

    _addHistoryRecord(
      translation: _translatedAnnouncement,
      originalText: _originalTranscription,
      station: _selectedStationName,
      targetLang: _targetLanguage,
    );

    notifyListeners();
  }

  // --- Staging & Approval Workflow ---

  void stageAnnouncement(Map<String, dynamic> data) {
    _stagedAnnouncement = data;
    notifyListeners();
  }

  Map<String, dynamic> validateTextRelevance(String text) {
    if (text.trim().length < 4) {
      return {
        'is_railway': false,
        'category': 'non_railway',
        'reason': 'Announcement text is too short or empty.',
      };
    }
    final lower = text.toLowerCase();

    // 1. Song / Music / Romantic keywords
    final songKeywords = [
      'song', 'lyrics', 'singing', 'chorus', 'verse', 'melody', 'tune', 'dance',
      'beat', 'romance', 'romantic', 'music', 'dj', 'remix', 'album', 'singer',
      'love', 'baby', 'darling', 'honey', 'kiss', 'forever', 'night', 'eyes', 'smile',
      'hug', 'tears', 'pyaar', 'ishq', 'mohabbat', 'dil', 'deewana', 'deewani', 'nasha',
      'sanam', 'humdum', 'zindagi', 'aashiqui', 'preethi', 'olavu', 'kaadhal', 'prema',
      'geethe', 'haadu'
    ];
    int songMatches = 0;
    for (final kw in songKeywords) {
      if (lower.contains(kw)) songMatches++;
    }

    // 2. Station safety / Emergency / Lost & found keywords
    final safetyKeywords = [
      'child', 'kid', 'missing child', 'lost child', 'toddler', 'boy', 'girl',
      'missing person', 'missing man', 'missing woman', 'lost person',
      'family member', 'friend', 'relative', 'father', 'mother', 'sister', 'brother',
      'wallet', 'lost wallet', 'phone', 'mobile', 'cellphone', 'lost phone',
      'purse', 'lost purse', 'handbag', 'bag', 'lost bag', 'luggage', 'baggage',
      'unattended', 'unclaimed', 'separated', 'found', 'station master office',
      'rpf', 'railway police', 'police', 'helpdesk', 'enquiry counter',
      'lost and found', 'safety announcement'
    ];
    int safetyMatches = 0;
    for (final kw in safetyKeywords) {
      if (lower.contains(kw)) safetyMatches++;
    }

    // 3. Railway operations keywords
    final railwayKeywords = [
      'train', 'platform', 'express', 'superfast', 'passenger', 'arrival', 'arriving',
      'arrived', 'departure', 'departing', 'depart', 'departed', 'delayed', 'delay',
      'running late', 'running delayed', 'rescheduled', 'cancelled', 'ready for departure',
      'coach', 'coach position', 'rake', 'track', 'bogie', 'ticket', 'railway', 'railways',
      'junction', 'central', 'cantt', 'vande bharat', 'rajdhani', 'shatabdi', 'duronto',
      'sampark kranti', 'chennai', 'mangaluru', 'bengaluru', 'varanasi', 'puttur',
      'solapur', 'mumbai', 'delhi', 'goa', 'kashi', 'attention', 'passengers please note',
      'may i have your attention', 'yatri', 'dhyan', 'gamanisi', 'gamanika', 'kavanathirku'
    ];
    int railwayMatches = 0;
    for (final kw in railwayKeywords) {
      if (lower.contains(kw)) railwayMatches++;
    }

    final hasTrainNumber = RegExp(r'\b(0?\d{3,5})\b').hasMatch(text);
    final hasPlatform = RegExp(r'platform\s*(?:number|no\.?)?\s*(\d+)', caseSensitive: false).hasMatch(lower);

    final isSafety = safetyMatches >= 2 || (safetyMatches >= 1 && (lower.contains('missing') || lower.contains('lost') || lower.contains('unattended') || lower.contains('found') || lower.contains('contact') || lower.contains('office') || lower.contains('police') || lower.contains('attention')));
    final isTrain = railwayMatches >= 1 || hasTrainNumber || hasPlatform;

    if (songMatches >= 2 && !isTrain && !isSafety) {
      return {
        'is_railway': false,
        'category': 'music_song',
        'reason': 'Content detected as song lyrics / music audio. Station Master validation requires train schedules or station alerts.',
      };
    }

    if (isSafety) {
      return {
        'is_railway': true,
        'category': 'station_safety',
        'reason': 'Verified station passenger safety or lost-and-found alert.',
      };
    }

    if (isTrain) {
      return {
        'is_railway': true,
        'category': 'train_announcement',
        'reason': 'Verified railway operational announcement.',
      };
    }

    return {
      'is_railway': false,
      'category': songMatches > 0 ? 'music_song' : 'non_railway',
      'reason': songMatches > 0
          ? 'Content identified as a song or music track. Station Master validation requires railway schedules or station safety alerts.'
          : 'Content does not contain railway operational updates (arrival, departure, delay, platform) or station safety notices (missing child/person, lost wallet/phone).',
    };
  }

  void stageCustomAnnouncement({
    required String trainNo,
    required String trainName,
    required String platform,
    required String destination,
    required String customText,
    required bool isRailway,
    required String reason,
    required String category,
  }) {
    final trainNum = trainNo.trim().isNotEmpty ? trainNo.trim() : '20608';
    final tName = trainName.trim().isNotEmpty ? trainName.trim() : 'Express';
    final plat = platform.trim().isNotEmpty ? platform.trim() : '1';
    final dest = destination.trim().isNotEmpty ? destination.trim() : 'Puttur';
    final fullText = customText.trim();

    _stagedAnnouncement = {
      'source_type': 'Custom Text Input',
      'title': tName,
      'audio_transcription': fullText,
      'detected_language': 'English',
      'is_railway_announcement': isRailway,
      'announcement_category': category,
      'railway_validation_reason': reason,
      'all_translations': {
        'en': {'native': fullText, 'latin': fullText, 'name': 'English'},
        'kn': {'native': fullText, 'latin': fullText, 'name': 'ಕನ್ನಡ (Kannada)'},
      },
      'translated_announcement': fullText,
      'latin_transliteration': '',
      'named_entities': [
        if (trainNum.isNotEmpty) {'text': trainNum, 'entity_type': 'TRAIN_NUMBER', 'label': 'Train $trainNum'},
        if (tName.isNotEmpty) {'text': tName, 'entity_type': 'TRAIN_NAME', 'label': tName},
        if (plat.isNotEmpty) {'text': plat, 'entity_type': 'PLATFORM', 'label': 'Platform $plat'},
        if (dest.isNotEmpty) {'text': dest, 'entity_type': 'DESTINATION', 'label': 'Destination: $dest'},
      ],
      'isl_sequence': ApiService.getFallbackISLSequence('vande_bharat'),
      'fingerspelling_cards': [],
    };
    notifyListeners();
  }

  void discardStagedAnnouncement() {
    _stagedAnnouncement = null;
    notifyListeners();
  }

  void approveStagedAnnouncement() {
    if (_stagedAnnouncement == null) return;
    if (_stagedAnnouncement?['is_railway_announcement'] == false) {
      _errorMessage = 'Warning: Cannot broadcast non-railway content to passenger screens.';
      notifyListeners();
      return;
    }
    final data = _stagedAnnouncement!;

    _originalTranscription = data['audio_transcription']?.toString() ?? '';
    _detectedLanguage = data['detected_language']?.toString() ?? 'English';
    _allTranslations = (data['all_translations'] as Map<String, dynamic>?) ?? {};

    if (_allTranslations.containsKey(_targetLanguage)) {
      final t = _allTranslations[_targetLanguage];
      if (t is Map) {
        _translatedAnnouncement = t['native']?.toString() ?? '';
        _latinTransliteration = t['latin']?.toString() ?? '';
      } else if (t is String) {
        _translatedAnnouncement = t;
        _latinTransliteration = '';
      }
    } else {
      _translatedAnnouncement = data['translated_announcement']?.toString() ?? '';
      _latinTransliteration = data['latin_transliteration']?.toString() ?? '';
    }

    final rawEntities = data['named_entities'] as List? ?? [];
    _namedEntities = rawEntities.map((e) => Map<String, dynamic>.from(e)).toList();

    final rawSeq = data['isl_sequence'] as List? ?? [];
    _islSequence = rawSeq.map((e) => Map<String, dynamic>.from(e)).toList();

    final rawFingerspell = data['fingerspelling_cards'] as List? ?? [];
    _fingerspellingCards = rawFingerspell.map((e) => Map<String, dynamic>.from(e)).toList();

    _activeGestureIndex = 0;
    _isSequenceCompleted = false;
    _isPlayingISL = false;

    _addHistoryRecord(
      translation: _translatedAnnouncement,
      originalText: _originalTranscription,
      station: _selectedStationName,
      targetLang: _targetLanguage,
    );

    _stagedAnnouncement = null;
    notifyListeners();
  }

  void setUserRole(AppUserRole role) async {
    _userRole = role;
    if (_userRole == AppUserRole.stationMaster) {
      _inputMode = AnnouncementInputMode.quickDispatch;
    } else {
      _inputMode = AnnouncementInputMode.presets;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_user_role', role.name);
    } catch (_) {}
  }

  void setWatchedTrainNumber(String trainNo) async {
    _watchedTrainNumber = trainNo.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('watched_train_number', _watchedTrainNumber);
    } catch (_) {}
  }

  void setPassengerDestination(String dest) async {
    _passengerDestination = dest.trim();
    notifyListeners();
    updateJourneyMatches();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('passenger_destination', _passengerDestination);
    } catch (_) {}
  }

  /// Station Master Quick Dispatch: Builds standard Indian Railways announcement and translates
  Future<void> dispatchTrainAnnouncement({
    required String trainNumber,
    required String trainName,
    required String platform,
    required String eventType, // 'arrival', 'departure', 'platform_change', 'delay'
    String delayMinutes = '15',
    String? customNote,
  }) async {
    String text = '';
    if (eventType == 'arrival') {
      text =
          'May I have your attention please. Train number $trainNumber $trainName is arriving shortly on platform number $platform. Passengers please take note.';
    } else if (eventType == 'departure') {
      text =
          'May I have your attention please. Train number $trainNumber $trainName is ready for departure on platform number $platform.';
    } else if (eventType == 'platform_change') {
      text =
          'Attention please, platform change announcement. Train number $trainNumber $trainName will now arrive on platform number $platform.';
    } else if (eventType == 'delay') {
      text =
          'Attention passengers. Train number $trainNumber $trainName is running delayed by approximately $delayMinutes minutes and will arrive on platform number $platform.';
    } else {
      text =
          'May I have your attention please. Train number $trainNumber $trainName on platform number $platform.';
    }

    if (customNote != null && customNote.trim().isNotEmpty) {
      text += ' ${customNote.trim()}';
    }

    await processText(text);
  }

  void setStation(String code, String name) {
    _selectedStationCode = code;
    _selectedStationName = name;
    if (isStationMaster) {
      _stationMasterStationCode = code;
      _stationMasterStationName = name;
    } else {
      _passengerStationCode = code;
      _passengerStationName = name;
      updateJourneyMatches();
    }
    notifyListeners();
  }

  void setStationMasterStation(String code, String name) {
    _stationMasterStationCode = code;
    _stationMasterStationName = name;
    _selectedStationCode = code;
    _selectedStationName = name;
    notifyListeners();
  }

  void setPassengerStation(String code, String name) {
    _passengerStationCode = code;
    _passengerStationName = name;
    _selectedStationCode = code;
    _selectedStationName = name;
    updateJourneyMatches();
    notifyListeners();
  }

  void setInputMode(AnnouncementInputMode mode) {
    _inputMode = mode;
    notifyListeners();
  }

  void setYoutubeUrl(String url) {
    _youtubeUrl = url;
    notifyListeners();
  }

  /// Process YouTube Video URL: Extract audio, STT, Multilingual NLP, NER, and ISL
  Future<void> processYouTube(String url) async {
    if (url.trim().isEmpty) return;
    _isProcessing = true;
    _errorMessage = null;
    _youtubeUrl = url.trim();
    _processingStatus = 'Extracting audio from YouTube video...';
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _processingStatus = 'Transcribing spoken announcement sound track...';
      notifyListeners();

      final result = await ApiService.processYouTubeAnnouncement(
        youtubeUrl: _youtubeUrl,
        targetLang: _targetLanguage,
      );

      if (result['success'] == false || (result['audio_transcription'] ?? '').toString().trim().isEmpty) {
        _errorMessage = result['error']?.toString() ?? 'No spoken words could be detected in this YouTube video.';
        _originalTranscription = '';
        _allTranslations = {};
        _translatedAnnouncement = '';
        _latinTransliteration = '';
        _islSequence = [];
        return;
      }

      final isRailway = result['is_railway_announcement'] as bool? ?? true;
      final category = result['announcement_category']?.toString() ?? 'train_announcement';
      final reason = result['railway_validation_reason']?.toString() ?? '';

      _stagedAnnouncement = {
        'source_type': 'YouTube Link',
        'title': result['video_metadata']?['title'] ?? _youtubeUrl,
        'youtube_url': _youtubeUrl,
        'audio_transcription': result['audio_transcription'] ?? '',
        'detected_language': result['detected_language'] ?? detectedLanguageCode,
        'all_translations': result['all_translations'] ?? {},
        'translated_announcement': result['translated_announcement'] ?? '',
        'latin_transliteration': result['latin_transliteration'] ?? '',
        'named_entities': result['named_entities'] ?? [],
        'isl_sequence': result['isl_sequence'] ?? [],
        'fingerspelling_cards': result['fingerspelling_cards'] ?? [],
        'is_railway_announcement': isRailway,
        'announcement_category': category,
        'railway_validation_reason': reason,
      };
    } catch (e) {
      _errorMessage = 'Failed to process YouTube audio: $e';
    } finally {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  /// Process direct video file upload: extract speech/words, translate, and synthesize ISL
  Future<void> processVideoFile(List<int> bytes, String filename) async {
    _isProcessing = true;
    _errorMessage = null;
    _uploadedVideoName = filename;
    _processingStatus = 'Transcribing video and audio...';
    notifyListeners();

    try {
      final result = await ApiService.processVideoOrAudioFile(
        fileBytes: bytes,
        fileName: filename,
        targetLang: _targetLanguage,
      );

      if (result['success'] == false || (result['audio_transcription'] ?? '').toString().trim().isEmpty) {
        _errorMessage = result['error']?.toString() ?? 'No clear spoken words detected in the audio file. Please ensure clear speech and try again.';
        return;
      }

      final isRailway = result['is_railway_announcement'] as bool? ?? true;
      final category = result['announcement_category']?.toString() ?? 'train_announcement';
      final reason = result['railway_validation_reason']?.toString() ?? '';

      _stagedAnnouncement = {
        'source_type': 'Audio/Video File',
        'title': filename,
        'audio_transcription': result['audio_transcription'] ?? '',
        'detected_language': result['detected_language'] ?? detectedLanguageCode,
        'all_translations': result['all_translations'] ?? {},
        'translated_announcement': result['translated_announcement'] ?? '',
        'latin_transliteration': result['latin_transliteration'] ?? '',
        'named_entities': result['named_entities'] ?? [],
        'isl_sequence': result['isl_sequence'] ?? [],
        'fingerspelling_cards': result['fingerspelling_cards'] ?? [],
        'is_railway_announcement': isRailway,
        'announcement_category': category,
        'railway_validation_reason': reason,
      };
    } catch (e) {
      _errorMessage = 'Failed to process video: $e';
    } finally {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  /// Process text announcement directly
  Future<void> processText(String text, {String? originStationCode, String? originStationName}) async {
    if (text.trim().isEmpty) return;
    _broadcastStationCode = originStationCode ?? (isStationMaster ? _stationMasterStationCode : _passengerStationCode);
    _broadcastStationName = originStationName ?? (isStationMaster ? _stationMasterStationName : _passengerStationName);

    final match = RegExp(r'\b(\d{4,5})\b').firstMatch(text);
    if (match != null) {
      _broadcastTrainNo = match.group(1)!;
    }
    _originalTranscription = text.trim();
    // Clear previous gestures immediately so old announcement never lingers
    _islSequence = [];
    _activeGestureIndex = 0;
    _isSequenceCompleted = false;
    _isPlayingISL = false;
    _isProcessing = true;
    _errorMessage = null;
    _processingStatus = 'Synthesizing Indian Sign Language gestures...';
    notifyListeners();

    try {
      final result = await ApiService.translateAnnouncementText(
        text: _originalTranscription,
        targetLang: _targetLanguage,
      );

      _translatedAnnouncement = result['translated_text'] ?? '';
      _latinTransliteration = result['latin_transliteration'] ?? '';
      _allTranslations = (result['all_translations'] as Map<String, dynamic>?) ?? {};
      final rawEntities = result['named_entities'] as List? ?? [];
      _namedEntities = rawEntities.map((e) => Map<String, dynamic>.from(e)).toList();

      final rawSeq = result['isl_sequence'] as List? ?? [];
      _islSequence = rawSeq.map((e) => Map<String, dynamic>.from(e)).toList();

      _activeGestureIndex = 0;
      _isSequenceCompleted = false;
      _isPlayingISL = false;

      _addHistoryRecord(
        translation: _translatedAnnouncement,
        originalText: _originalTranscription,
        station: _selectedStationName,
        targetLang: _targetLanguage,
      );
    } catch (e) {
      _errorMessage = 'Translation failed: $e';
    } finally {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  /// Load a pre-curated Karnataka announcement preset
  void loadPreset(Map<String, dynamic> preset) {
    _originalTranscription = preset['transcription'] ?? '';
    _selectedStationCode = preset['station_code'] ?? _selectedStationCode;
    _selectedStationName = preset['station_name'] ?? _selectedStationName;

    final translations = preset['translations'] as Map<String, dynamic>?;
    final latinMap = preset['latin_transliterations'] as Map<String, dynamic>?;
    _allTranslations = {};
    if (translations != null) {
      translations.forEach((k, v) {
        _allTranslations[k] = {
          'native': v?.toString() ?? '',
          'latin': latinMap?[k]?.toString() ?? '',
          'name': getLanguageName(k),
        };
      });
    }

    if (translations != null && translations.containsKey(_targetLanguage)) {
      _translatedAnnouncement = translations[_targetLanguage] ?? '';
    } else {
      _translatedAnnouncement = preset['translations']?['en'] ?? _originalTranscription;
    }

    final rawEntities = preset['named_entities'] as List? ?? [];
    _namedEntities = rawEntities.map((e) => Map<String, dynamic>.from(e)).toList();

    final isChennai = preset['id'] == 'ann_chennai_exp_solapur' ||
        preset['title']?.toString().toLowerCase().contains('chennai') == true;
    _islSequence = ApiService.getFallbackISLSequence(isChennai ? 'chennai_exp' : 'karnataka_exp');
    processText(_originalTranscription);
    if (latinMap != null && latinMap.containsKey(_targetLanguage)) {
      _latinTransliteration = latinMap[_targetLanguage] ?? '';
    } else {
      _latinTransliteration = '';
    }
    _activeGestureIndex = 0;
    _isSequenceCompleted = false;
    _isPlayingISL = false;
    _customVideoUrl = preset['custom_video_url'];

    _addHistoryRecord(
      translation: _translatedAnnouncement,
      originalText: _originalTranscription,
      station: _selectedStationName,
      targetLang: _targetLanguage,
    );
    notifyListeners();
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'kn': return 'ಕನ್ನಡ (Kannada - Kannglish)';
      case 'te': return 'తెలుగు (Telugu - Tenglish)';
      case 'ta': return 'தமிழ் (Tamil - Tanglish)';
      case 'hi': return 'हिन्दी (Hindi - Hinglish)';
      case 'mr': return 'मराठी (Marathi - Marathish)';
      case 'bn': return 'বাংলা (Bengali - Banglish)';
      case 'ml': return 'മലയാളം (Malayalam - Manglish)';
      case 'gu': return 'ગુજરાતી (Gujarati)';
      case 'en': return 'English';
      default: return code.toUpperCase();
    }
  }

  /// Switch Target Language and update contextual translation
  Future<void> setTargetLanguage(String langCode) async {
    if (_targetLanguage == langCode) return;
    _targetLanguage = langCode;

    if (_allTranslations.containsKey(langCode)) {
      final data = _allTranslations[langCode];
      if (data is Map) {
        _translatedAnnouncement = data['native']?.toString() ?? '';
        _latinTransliteration = data['latin']?.toString() ?? '';
      } else if (data is String) {
        _translatedAnnouncement = data;
        _latinTransliteration = '';
      }
      notifyListeners();
      return;
    }
    notifyListeners();

    if (_originalTranscription.isNotEmpty) {
      await processText(_originalTranscription);
    }
  }

  String get targetLangName {
    switch (_targetLanguage) {
      case 'kn':
        return 'ಕನ್ನಡ (Kannada)';
      case 'te':
        return 'తెలుగు (Telugu)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'mr':
        return 'मराठी (Marathi)';
      case 'bn':
        return 'বাংলা (Bengali)';
      case 'ml':
        return 'മലയാളം (Malayalam)';
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'en':
        return 'English';
      default:
        return _targetLanguage.toUpperCase();
    }
  }

  // --- Sign Language Interactive Player Controls ---

  void playISL({bool fromStart = false}) {
    if (_islSequence.isEmpty) return;
    if (fromStart || _isSequenceCompleted || _activeGestureIndex >= _islSequence.length - 1) {
      _activeGestureIndex = 0;
      _isSequenceCompleted = false;
    }
    _isPlayingISL = true;
    _scheduleNextGesture();
    notifyListeners();
  }

  void replayISL() {
    playISL(fromStart: true);
  }

  void pauseISL() {
    _isPlayingISL = false;
    _gestureTimer?.cancel();
    notifyListeners();
  }

  void togglePlayPauseISL() {
    if (_isPlayingISL) {
      pauseISL();
    } else {
      playISL();
    }
  }

  void setGestureIndex(int index) {
    if (index >= 0 && index < _islSequence.length) {
      _activeGestureIndex = index;
      _isSequenceCompleted = false;
      notifyListeners();
    }
  }

  void stepGesture(int delta) {
    final nextIndex = _activeGestureIndex + delta;
    if (nextIndex >= 0 && nextIndex < _islSequence.length) {
      _activeGestureIndex = nextIndex;
      _isSequenceCompleted = false;
      notifyListeners();
    } else if (nextIndex >= _islSequence.length && _isLooping) {
      _activeGestureIndex = 0;
      _isSequenceCompleted = false;
      notifyListeners();
    }
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  void toggleLooping() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void setCustomVideoUrl(String? url) {
    _customVideoUrl = url;
    notifyListeners();
  }

  void _scheduleNextGesture() {
    _gestureTimer?.cancel();
    if (!_isPlayingISL || _islSequence.isEmpty) return;

    final currentGesture = _islSequence[_activeGestureIndex];
    // Natural fluid timing: words ~1400ms, digits/fingerspelling ~950ms (fluid, brisk, never dragging)
    final rawDuration = (currentGesture['duration_ms'] as int?) ?? 1400;
    final isShortSign = currentGesture['is_fingerspelling'] == true ||
        (currentGesture['sign_code'] != null && currentGesture['sign_code'].toString().length == 1);
    final baseDuration = isShortSign
        ? (rawDuration < 600 ? 950 : (rawDuration > 1200 ? 950 : rawDuration))
        : (rawDuration < 900 ? 1400 : (rawDuration > 1700 ? 1400 : rawDuration));
    final adjustedDuration = (baseDuration / _playbackSpeed).round();

    _gestureTimer = Timer(Duration(milliseconds: adjustedDuration), () {
      if (!_isPlayingISL) return;
      if (_activeGestureIndex < _islSequence.length - 1) {
        _activeGestureIndex++;
        notifyListeners();
        _scheduleNextGesture();
      } else {
        if (_isLooping) {
          _activeGestureIndex = 0;
          notifyListeners();
          _scheduleNextGesture();
        } else {
          _isPlayingISL = false;
          _isSequenceCompleted = true;
          notifyListeners();
        }
      }
    });
  }

  /// Text-to-Speech announcement pronunciation using natural neural voice
  Future<void> speakTranslation([String? overrideText, String? overrideLang]) async {
    final text = (overrideText != null && overrideText.trim().isNotEmpty)
        ? overrideText.trim()
        : _translatedAnnouncement.trim();
    if (text.isEmpty) return;

    final lang = (overrideLang != null && overrideLang.trim().isNotEmpty)
        ? overrideLang.trim()
        : _targetLanguage;

    if (_isSpeaking) {
      AudioPlayerService.stop();
      try {
        await _tts.stop();
      } catch (_) {}
      _isSpeaking = false;
      notifyListeners();
      return;
    }

    _isSpeaking = true;
    notifyListeners();

    // 1. Primary: High-Quality Natural Human Neural Voice (Kannada, Hindi, English, Tamil, Telugu, Marathi, Bengali, Gujarati, Malayalam)
    try {
      final ttsRes = await ApiService.fetchAnnouncementTTS(text: text, lang: lang);
      if (ttsRes['success'] == true && ttsRes['audio_base64'] != null) {
        AudioPlayerService.playBase64(ttsRes['audio_base64'] as String);
        return;
      }
    } catch (e) {
      debugPrint('Neural TTS fallback: $e');
    }

    // 2. Secondary Fallback: Device/Browser TTS with regional locale
    try {
      String ttsLang = 'kn-IN';
      switch (lang) {
        case 'kn': ttsLang = 'kn-IN'; break;
        case 'hi': ttsLang = 'hi-IN'; break;
        case 'en': ttsLang = 'en-IN'; break;
        case 'te': ttsLang = 'te-IN'; break;
        case 'ta': ttsLang = 'ta-IN'; break;
        case 'mr': ttsLang = 'mr-IN'; break;
        case 'bn': ttsLang = 'bn-IN'; break;
        case 'ml': ttsLang = 'ml-IN'; break;
        case 'gu': ttsLang = 'gu-IN'; break;
      }
      await _tts.setLanguage(ttsLang);
      await _tts.setSpeechRate(0.85); // Natural railway announcement pace
      await _tts.speak(text);
    } catch (_) {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Speak custom text with language code
  Future<void> speakCustomText(String text, String langCode) async {
    await speakTranslation(text, langCode);
  }

  /// Stop any ongoing speech
  Future<void> stopSpeech() async {
    AudioPlayerService.stop();
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }

  // --- History Storage ---

  void _addHistoryRecord({
    required String translation,
    String? originalText,
    String? station,
    String? targetLang,
  }) {
    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      translation: translation,
      originalText: originalText,
      station: station,
      targetLang: targetLang,
      timestamp: DateTime.now(),
    );
    _history.insert(0, item);
    if (_history.length > 50) {
      _history.removeLast();
    }
    _persistHistory();
    notifyListeners();
  }

  DateTime? _lastFetched;
  String? _currentUserId;
  String? _currentToken;
  Timer? _syncTimer;

  static const Duration cacheTtl = Duration(minutes: 5);
  static const Duration periodicSyncInterval = Duration(minutes: 5);

  DateTime? get lastFetched => _lastFetched;

  String _cacheKey(String userId) => 'history_cache_$userId';

  Future<void> _persistCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _history.map((item) => item.toJson()).toList();
      await prefs.setString(_cacheKey(userId), jsonEncode(list));
    } catch (_) {}
  }

  Future<List<HistoryItem>> _loadPersistentCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(userId));
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => HistoryItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  void _startPeriodicSyncIfNeeded(String userId, String? token) {
    _currentToken = token;
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(periodicSyncInterval, (_) {
      _fetchSilently(userId, token: _currentToken);
    });
  }

  Future<void> _fetchSilently(String userId, {String? token}) async {
    if (token == null || token.isEmpty) return;
    try {
      final rawHistory = await ApiService.getHistory(token);
      _history = rawHistory.map((r) => HistoryItem.fromMap(r)).toList();
      _lastFetched = DateTime.now();
      await _persistCache(userId);
      notifyListeners();
    } catch (_) {
      // Background sync silently fails without disturbing the user
    }
  }

  Future<void> _persistHistory() async {
    if (_currentUserId != null) {
      await _persistCache(_currentUserId!);
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = _history.map((h) => h.toJson()).toList();
        await prefs.setString('railway_history_cache', jsonEncode(list));
      } catch (_) {}
    }
  }

  /// Loads history using in-memory and persistent cache.
  /// If data is already in memory and fresh (within [cacheTtl]), does not query backend.
  /// Pass [force] = true (e.g. on pull-to-refresh) to bypass cache and fetch latest from backend.
  Future<void> loadHistory(String userId, {String? token, bool force = false}) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _lastFetched = null;
      _history = await _loadPersistentCache(userId);
      if (_history.isNotEmpty) {
        notifyListeners();
      }
    }

    _startPeriodicSyncIfNeeded(userId, token);

    final isFresh = _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) < cacheTtl;

    if (!force && _history.isNotEmpty) {
      if (isFresh) {
        return;
      }
      unawaited(_fetchSilently(userId, token: token));
      return;
    }

    if (_history.isEmpty) {
      _isLoadingHistory = true;
      notifyListeners();
    }

    try {
      final rawHistory = await ApiService.getHistory(token ?? '');
      _history = rawHistory.map((r) => HistoryItem.fromMap(r)).toList();
      _lastFetched = DateTime.now();
      await _persistCache(userId);
    } catch (e) {
      if (_history.isEmpty) {
        _history = [];
      }
      if (force) {
        _isLoadingHistory = false;
        notifyListeners();
        rethrow;
      }
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  void updateTranslation(String text) {
    _translatedAnnouncement = text;
    notifyListeners();
  }

  /// Optimistic store
  Future<HistoryItem> saveTranslation(
    String userId,
    String translation, {
    String? token,
  }) async {
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final optimisticItem = HistoryItem(
      id: tempId,
      translation: translation,
      timestamp: DateTime.now(),
    );

    _history.insert(0, optimisticItem);
    _currentUserId = userId;
    notifyListeners();
    await _persistCache(userId);

    try {
      final result = await ApiService.postHistory(translation, token ?? '');
      final backendId = result['id'];
      final backendTimestamp = DateTime.tryParse(result['timestamp'] ?? '');

      final confirmedItem = HistoryItem(
        id: (backendId != null && backendId.isNotEmpty) ? backendId : tempId,
        translation: (result['translation'] != null &&
                result['translation']!.isNotEmpty)
            ? result['translation']!
            : translation,
        timestamp: backendTimestamp ?? optimisticItem.timestamp,
      );

      final index = _history.indexWhere((item) => item.id == tempId);
      if (index != -1) {
        _history[index] = confirmedItem;
      } else {
        _history.insert(0, confirmedItem);
      }

      await _persistCache(userId);
      notifyListeners();
      return confirmedItem;
    } catch (e) {
      _history.removeWhere((item) => item.id == tempId);
      await _persistCache(userId);
      notifyListeners();
      rethrow;
    }
  }

  /// Optimistic delete
  Future<void> deleteHistoryItem(String id, {String? token}) async {
    final index = _history.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final removedItem = _history.removeAt(index);
    notifyListeners();
    if (_currentUserId != null) {
      await _persistCache(_currentUserId!);
    }

    try {
      await ApiService.deleteHistoryItem(id, token ?? '');
    } catch (e) {
      if (index <= _history.length) {
        _history.insert(index, removedItem);
      } else {
        _history.add(removedItem);
      }
      if (_currentUserId != null) {
        await _persistCache(_currentUserId!);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Optimistic clear
  Future<void> clearHistory({String? token}) async {
    if (_history.isEmpty) return;
    final previousHistory = List<HistoryItem>.from(_history);
    _history.clear();
    notifyListeners();
    if (_currentUserId != null) {
      await _persistCache(_currentUserId!);
    }

    try {
      await ApiService.clearHistory(token ?? '');
    } catch (e) {
      _history = previousHistory;
      if (_currentUserId != null) {
        await _persistCache(_currentUserId!);
      }
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _gestureTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}
