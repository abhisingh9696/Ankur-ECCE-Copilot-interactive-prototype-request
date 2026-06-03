import '../models/child_model.dart';

/// Simulates the TFLite multi-label classifier for domain tagging.
/// In production, this would use a <15MB INT8-quantized TFLite model.
/// For this prototype, it uses keyword matching with language-aware rules.
class ClassifierService {
  /// Analyze observation text and return domain tags with confidence
  static Map<String, double> classify(String text, [String lang = 'en']) {
    final textLower = text.toLowerCase();
    final Map<String, double> scores = {};

    // Check keywords for each domain across languages
    for (final domain in ncfDomains) {
      final keywords = domainKeywords[domain.id] ?? [];
      int matches = 0;

      for (final kw in keywords) {
        if (textLower.contains(kw.toLowerCase())) {
          matches++;
        }
      }

      // Calculate normalized score
      double score = keywords.isNotEmpty
          ? (matches / (keywords.length * 0.15)).clamp(0.0, 1.0)
          : 0.0;

      // Boost from positive-sentiment words
      if (_hasPositiveSentiment(textLower)) {
        score = (score + 0.05).clamp(0.0, 1.0);
      }

      // Boost from developmental milestone words
      if (_hasMilestoneWords(textLower, domain.id)) {
        score = (score + 0.1).clamp(0.0, 1.0);
      }

      scores[domain.id] = score;
    }

    return scores;
  }

  /// Get top domains above threshold
  static List<String> getTopDomains(Map<String, double> scores,
      {double threshold = 0.15}) {
    final entries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Always return at least one domain
    if (entries.isEmpty) return ['language'];

    final maxScore = entries.first.value;
    final result = <String>[];

    for (final entry in entries) {
      if (entry.value >= threshold || entry.value >= maxScore * 0.5) {
        result.add(entry.key);
      }
    }

    // If nothing above threshold, return cognitive + language as default
    if (result.isEmpty) {
      return ['cognitive', 'language'];
    }

    return result;
  }

  static bool _hasPositiveSentiment(String text) {
    const positive = [
      'good', 'well', 'great', 'excellent', 'happy', 'smile', 'laugh',
      'independent', 'success', 'proud', 'correct', 'properly',
      'अच्छा', 'बढ़िया', 'खुश', 'हँस', 'सफल',
      'நல்ல', 'சிறந்த', 'மகிழ்', 'சிரி', 'வெற்றி',
      'સારું', 'ઉત્તમ', 'ખુશ', 'હસવું', 'સફળ',
    ];
    return positive.any((w) => text.contains(w));
  }

  static bool _hasMilestoneWords(String text, String domain) {
    final milestones = {
      'physical': ['stack', 'walk', 'run', 'jump', 'climb', 'hold', 'grip', 'balance', 'block', 'tower'],
      'socio': ['share', 'friend', 'help', 'together', 'play', 'group', 'comfort'],
      'cognitive': ['count', 'sort', 'match', 'color', 'shape', 'number', 'puzzle', 'remember'],
      'language': ['speak', 'word', 'phrase', 'sentence', 'sing', 'story', 'talk', 'name'],
      'aesthetic': ['draw', 'paint', 'color', 'create', 'dance', 'sing', 'beautiful'],
      'habits': ['wash', 'clean', 'brush', 'toilet', 'routine', 'organize'],
    };
    return (milestones[domain] ?? []).any((w) => text.contains(w));
  }
}

/// Jadui Pitara activity retrieval engine
class ActivityService {
  static Map<String, dynamic>? getActivity(
      String domain, String lang) {
    final activities = _activities[domain] ?? _activities['language']!;
    return activities[lang] ?? activities['en'];
  }

  static final Map<String, Map<String, Map<String, String>>> _activities = {
    'physical': {
      'en': {
        'name': 'Interactive Building Blocks',
        'desc': 'Encourage stacking at least 5 blocks. Praise when successful. Builds eye-hand coordination.',
      },
      'hi': {
        'name': 'इंटरैक्टिव ब्लॉक खेल',
        'desc': 'कम से कम 5 ब्लॉक एक साथ रखने को प्रोत्साहित करें। सफल होने पर प्रशंसा करें। आंख-हाथ समन्वय बढ़ाता है।',
      },
      'ta': {
        'name': 'ஊடாடும் கட்டிடத் தொகுதிகள்',
        'desc': 'குறைந்தது 5 தொகுதிகளை அடுக்க ஊக்குவிக்கவும். வெற்றியடையும் போது பாராட்டவும். கண்-கை ஒருங்கிணைப்பை உருவாக்குகிறது.',
      },
      'gu': {
        'name': 'ઇન્ટરેક્ટિવ બિલ્ડિંગ બ્લોક્સ',
        'desc': 'ઓછામાં ઓછા 5 બ્લોક્સ એકસાથે ગોઠવવા પ્રોત્સાહિત કરો. સફળ થાય ત્યારે પ્રશંસા કરો. આંખ-હાથ સંકલન વધારે છે.',
      },
    },
    'socio': {
      'en': {
        'name': 'Share a Toy Activity',
        'desc': 'Group children in pairs. Provide one box of toys. Guide sharing and taking turns carefully.',
      },
      'hi': {
        'name': 'खिलौने साझा करने का खेल',
        'desc': 'बच्चों को जोड़ियों में बाँटें। एक बॉक्स खिलौने दें। बारी-बारी से खेलने का निर्देश दें।',
      },
      'ta': {
        'name': 'பொம்மை பகிர்வு செயல்பாடு',
        'desc': 'குழந்தைகளை ஜோடிகளாகப் பிரிக்கவும். ஒரு பெட்டி பொம்மைகளை வழங்கவும். மாறி மாறி விளையாட வழிகாட்டவும்.',
      },
      'gu': {
        'name': 'રમકડાં વહેંચવાની પ્રવૃત્તિ',
        'desc': 'બાળકોને જોડીમાં વિભાજીત કરો. એક બોક્સ રમકડાં આપો. વારાફરતી રમવાનું માર્ગદર્શન આપો.',
      },
    },
    'cognitive': {
      'en': {
        'name': 'Color Sorting Puzzle',
        'desc': 'Ask child to separate mixed colored balls into matching baskets. Tests category logic.',
      },
      'hi': {
        'name': 'रंग छँटाई पहेली',
        'desc': 'मिश्रित रंगीन गेंदों को मिलान वाली टोकरियों में छाँटने को कहें। श्रेणी तर्क का परीक्षण करता है।',
      },
      'ta': {
        'name': 'வண்ண வரிசைப்படுத்தும் புதிர்',
        'desc': 'கலந்த வண்ண பந்துகளை பொருந்தும் கூடைகளில் பிரிக்கச் சொல்லவும். வகை தர்க்கத்தை சோதிக்கிறது.',
      },
      'gu': {
        'name': 'રંગ વર્ગીકરણ કોયડો',
        'desc': 'મિશ્ર રંગીન દડાઓને મેળ ખાતી ટોપલીઓમાં અલગ કરવા કહો. શ્રેણી તર્કનું પરીક્ષણ કરે છે.',
      },
    },
    'language': {
      'en': {
        'name': 'Two-Word Sound Echo',
        'desc': 'Speak small phrases clearly. Ask child to repeat. Use picture cards to prompt speech.',
      },
      'hi': {
        'name': 'शब्द अनुकरण खेल',
        'desc': 'छोटे वाक्य स्पष्ट बोलें। बच्चे को दोहराने को कहें। चित्र कार्ड दिखाकर बातचीत शुरू करें।',
      },
      'ta': {
        'name': 'இரண்டு சொல் ஒலி எதிரொலி',
        'desc': 'சிறிய சொற்றொடர்களை தெளிவாகப் பேசவும். குழந்தையை மீண்டும் சொல்லச் சொல்லவும். பட அட்டைகளைக் காட்டி பேச்சைத் தூண்டவும்.',
      },
      'gu': {
        'name': 'બે-શબ્દ ધ્વનિ પડઘો',
        'desc': 'નાના વાક્યો સ્પષ્ટ બોલો. બાળકને પુનરાવર્તન કરવા કહો. ચિત્ર કાર્ડ બતાવીને વાતચીત શરૂ કરો.',
      },
    },
    'aesthetic': {
      'en': {
        'name': 'Fingerprint Tree Drawing',
        'desc': 'Provide water colors and blank sheet. Let children make colorful leaf prints using thumbs.',
      },
      'hi': {
        'name': 'अंगूठे की छाप पेंटिंग',
        'desc': 'पानी के रंग और कोरा कागज दें। बच्चों को अंगूठे से रंगीन पत्तियों की छाप बनाने दें।',
      },
      'ta': {
        'name': 'கைரேகை மர ஓவியம்',
        'desc': 'நீர் வண்ணங்கள் மற்றும் வெற்று தாளை வழங்கவும். குழந்தைகள் கட்டைவிரலால் வண்ண இலை அச்சுகளை உருவாக்கட்டும்.',
      },
      'gu': {
        'name': 'અંગૂઠાની છાપ ચિત્ર',
        'desc': 'પાણીના રંગો અને ખાલી કાગળ આપો. બાળકોને અંગૂઠાથી રંગીન પાંદડાની છાપ બનાવવા દો.',
      },
    },
    'habits': {
      'en': {
        'name': 'Handwash Parade',
        'desc': 'Lead children to handwash station singing a 20-second step-by-step washing rhyme.',
      },
      'hi': {
        'name': 'हाथ धोने की परेड',
        'desc': 'बच्चों को 20 सेकंड की हाथ धोने की कविता गाते हुए हैंडवॉश स्टेशन पर ले जाएं।',
      },
      'ta': {
        'name': 'கை கழுவும் அணிவகுப்பு',
        'desc': '20 வினாடி படிப்படியான கை கழுவும் பாடலைப் பாடி குழந்தைகளை கை கழுவும் இடத்திற்கு அழைத்துச் செல்லவும்.',
      },
      'gu': {
        'name': 'હાથ ધોવાની પરેડ',
        'desc': '20 સેકન્ડની હાથ ધોવાની કવિતા ગાતા બાળકોને હેન્ડવોશ સ્ટેશન પર લઈ જાઓ.',
      },
    },
  };

  /// Get all activity names for TTS
  static List<Map<String, String>> getAllActivities(String lang) {
    final result = <Map<String, String>>[];
    for (final domain in ['physical', 'socio', 'cognitive', 'language', 'aesthetic', 'habits']) {
      final act = _activities[domain]?[lang] ?? _activities[domain]?['en'];
      if (act != null) {
        result.add(act);
      }
    }
    return result;
  }
}
