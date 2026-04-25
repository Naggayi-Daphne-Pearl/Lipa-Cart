import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class TrainingQuestion {
  final int id;
  final int order;
  final String prompt;
  final String optionA;
  final String optionB;
  final String optionC;

  TrainingQuestion({
    required this.id,
    required this.order,
    required this.prompt,
    required this.optionA,
    required this.optionB,
    required this.optionC,
  });

  factory TrainingQuestion.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>? ?? const {};
    return TrainingQuestion(
      id: json['id'] as int,
      order: json['order'] as int,
      prompt: (json['prompt'] ?? '').toString(),
      optionA: (options['a'] ?? '').toString(),
      optionB: (options['b'] ?? '').toString(),
      optionC: (options['c'] ?? '').toString(),
    );
  }
}

class TrainingFeedback {
  final int questionId;
  final String? submitted;
  final bool correct;
  final String correctOption;
  final String? explanation;

  TrainingFeedback({
    required this.questionId,
    required this.submitted,
    required this.correct,
    required this.correctOption,
    required this.explanation,
  });

  factory TrainingFeedback.fromJson(Map<String, dynamic> json) {
    return TrainingFeedback(
      questionId: json['questionId'] as int,
      submitted: json['submitted'] as String?,
      correct: json['correct'] as bool? ?? false,
      correctOption: (json['correctOption'] ?? '').toString(),
      explanation: json['explanation'] as String?,
    );
  }
}

class TrainingResult {
  final int score;
  final int total;
  final int passMark;
  final bool passed;
  final List<TrainingFeedback> feedback;

  TrainingResult({
    required this.score,
    required this.total,
    required this.passMark,
    required this.passed,
    required this.feedback,
  });

  factory TrainingResult.fromJson(Map<String, dynamic> json) {
    return TrainingResult(
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      passMark: json['passMark'] as int? ?? 4,
      passed: json['passed'] as bool? ?? false,
      feedback: (json['feedback'] as List<dynamic>? ?? const [])
          .map((f) => TrainingFeedback.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrainingService {
  static String get _apiUrl => AppConstants.apiUrl;

  static Future<List<TrainingQuestion>> fetchQuestions(String role) async {
    final url = '$_apiUrl/training-questions?role=$role';
    final response = await http
        .get(Uri.parse(url))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load questions: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .map((q) => TrainingQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  static Future<TrainingResult> submitAttempt({
    required String role,
    required Map<int, String> answers,
    required String token,
  }) async {
    final url = '$_apiUrl/training-attempts';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'data': {
        'role': role,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      },
    });

    final response = await http
        .post(Uri.parse(url), headers: headers, body: body)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to submit attempt: ${response.statusCode}');
    }

    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    return TrainingResult.fromJson(outer['data'] as Map<String, dynamic>);
  }

  static Future<TrainingStatus> fetchStatus(String token) async {
    final url = '$_apiUrl/training-attempts/status';
    final response = await http
        .get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load training status: ${response.statusCode}');
    }

    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (outer['data'] as Map<String, dynamic>? ?? const {});
    final completedAtRaw = data['completed_at'];
    return TrainingStatus(
      passed: data['passed'] as bool? ?? false,
      completedAt: completedAtRaw == null
          ? null
          : DateTime.tryParse(completedAtRaw.toString()),
    );
  }
}

class TrainingStatus {
  final bool passed;
  final DateTime? completedAt;

  const TrainingStatus({required this.passed, required this.completedAt});
}
