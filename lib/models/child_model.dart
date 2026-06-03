import 'dart:convert';

class Child {
  final String id;
  final String pseudoId;
  final String name;
  final String age;
  final String gender;
  String status; // 'onTrack', 'watch', 'redFlag'
  Map<String, double> profile;
  List<Observation> observations;

  Child({
    required this.id,
    required this.pseudoId,
    required this.name,
    required this.age,
    required this.gender,
    required this.status,
    required this.profile,
    this.observations = const [],
  });

  Child copyWith({
    String? id,
    String? pseudoId,
    String? name,
    String? age,
    String? gender,
    String? status,
    Map<String, double>? profile,
    List<Observation>? observations,
  }) {
    return Child(
      id: id ?? this.id,
      pseudoId: pseudoId ?? this.pseudoId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      profile: profile ?? this.profile,
      observations: observations ?? this.observations,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pseudoId': pseudoId,
        'name': name,
        'age': age,
        'gender': gender,
        'status': status,
        'profile': profile,
        'observations': observations.map((o) => o.toJson()).toList(),
      };

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        pseudoId: json['pseudoId'] as String,
        name: json['name'] as String,
        age: json['age'] as String,
        gender: json['gender'] as String,
        status: json['status'] as String,
        profile: Map<String, double>.from(json['profile'] as Map),
        observations: (json['observations'] as List?)
                ?.map((o) =>
                    Observation.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static Child fromJsonString(String jsonString) =>
      Child.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());
}

class Observation {
  final String date;
  final String text;
  final String method; // 'voice', 'voice_sim', 'manual'
  final List<String> domains;

  Observation({
    required this.date,
    required this.text,
    required this.method,
    required this.domains,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'text': text,
        'method': method,
        'domains': domains,
      };

  factory Observation.fromJson(Map<String, dynamic> json) => Observation(
        date: json['date'] as String,
        text: json['text'] as String,
        method: json['method'] as String,
        domains: List<String>.from(json['domains'] as List),
      );
}

class NcfDomain {
  final String id;
  final Map<String, String> labels; // language code -> label

  const NcfDomain({
    required this.id,
    required this.labels,
  });

  String label(String lang) => labels[lang] ?? labels['en'] ?? id;
}

const ncfDomains = [
  NcfDomain(id: 'physical', labels: {
    'en': 'Physical & Motor',
    'hi': 'शारीरिक',
    'ta': 'உடல் இயக்கம்',
    'gu': 'શારીરિક',
  }),
  NcfDomain(id: 'socio', labels: {
    'en': 'Socio-Emotional',
    'hi': 'सामाजिक-भावनात्मक',
    'ta': 'சமூக உணர்வு',
    'gu': 'સામાજિક-ભાવનાત્મક',
  }),
  NcfDomain(id: 'cognitive', labels: {
    'en': 'Cognitive',
    'hi': 'संज्ञानात्मक',
    'ta': 'அறிவாற்றல்',
    'gu': 'જ્ઞાનાત્મક',
  }),
  NcfDomain(id: 'language', labels: {
    'en': 'Language & Literacy',
    'hi': 'भाषा एवं साक्षरता',
    'ta': 'மொழி & எழுத்தறிவு',
    'gu': 'ભાષા અને સાક્ષરતા',
  }),
  NcfDomain(id: 'aesthetic', labels: {
    'en': 'Aesthetic & Creative',
    'hi': 'सौंदर्यबोध',
    'ta': 'அழகியல் & படைப்பாற்றல்',
    'gu': 'સૌંદર્યલક્ષી',
  }),
  NcfDomain(id: 'habits', labels: {
    'en': 'Positive Habits',
    'hi': 'सकारात्मक आदतें',
    'ta': 'நல்ல பழக்கங்கள்',
    'gu': 'સકારાત્મક ટેવો',
  }),
];

const domainKeywords = {
  'physical': [
    'khel', 'run', 'jump', 'motor', 'physical', 'ball', 'daud', 'block',
    'tower', 'stack', 'climb', 'walk', 'throw', 'catch', 'hop', 'skip',
    'balance', 'coordination', 'fine motor', 'gross motor',
    'पकड़ना', 'गेंद', 'दौड़', 'कूद', 'चल', 'ब्लॉक', 'टॉवर',
    'ஓட', 'குதி', 'பந்து', 'நட', 'ஏற', 'விளையாட்டு',
    'દોડ', 'કૂદ', 'બ્લોક', 'ચાલ', 'રમત',
  ],
  'socio': [
    'share', 'friend', 'feel', 'dost', 'group', 'happy', 'crying', 'saath',
    'milkar', 'help', 'smile', 'play together', 'comfort',
    'बाँटना', 'मित्र', 'मदद', 'साथ', 'दोस्त', 'खुश', 'रोना',
    'பகிர்', 'நண்பர்', 'உதவி', 'சிரி', 'ஒன்றாக',
    'મિત્ર', 'વહેંચણી', 'મદદ', 'સાથે', 'હસવું',
  ],
  'cognitive': [
    'puzzle', 'count', 'sort', 'color', 'think', 'soch', 'rang', 'pattern',
    'number', 'shape', 'remember', 'solve', 'match', 'compare',
    'संख्या', 'गिनती', 'रंग', 'आकार', 'सोच',
    'எண்', 'நிற', 'வடிவ', 'சிந்தி', 'ஞாபக',
    'ગણ', 'રંગ', 'આકાર', 'વિચાર', 'યાદ',
  ],
  'language': [
    'talk', 'speak', 'word', 'say', 'sing', 'song', 'story', 'bola', 'kaha',
    'phrase', 'sentence', 'respond', 'name', 'call', 'repeat', 'tell',
    'गीत', 'कहानी', 'भाषा', 'बोला', 'बात', 'गाना',
    'பாட', 'கதை', 'சொல்', 'பேச', 'மொழி',
    'ગીત', 'વાર્તા', 'ભાષા', 'બોલ', 'કહે',
  ],
  'aesthetic': [
    'draw', 'paint', 'sketch', 'color', 'aesthetic', 'sundar', 'art',
    'create', 'beautiful', 'decorate', 'design', 'dance',
    'चित्र', 'सुंदर', 'चित्रकारी', 'रंगोली', 'नृत्य',
    'ஓவிய', 'அழகு', 'வரை', 'நடன', 'கலை',
    'ચિત્ર', 'સુંદર', 'રંગોળી', 'નૃત્ય', 'કલા',
  ],
  'habits': [
    'wash', 'toilet', 'hand', 'brush', 'clean', 'habit', 'routine',
    'hygiene', 'eat', 'dress', 'organize', 'tidy',
    'हाथ', 'साफ', 'आदत', 'स्वच्छ', 'धोना',
    'கை', 'சுத்த', 'பழக', 'கழுவ', 'உண',
    'હાથ', 'સાફ', 'ટેવ', 'સ્વચ્છ', 'ધોવું',
  ],
};
