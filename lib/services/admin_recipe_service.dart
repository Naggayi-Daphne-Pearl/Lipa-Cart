import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class AdminRecipeIngredientInput {
  final String name;
  final double? quantity;
  final String? unit;
  final String? notes;
  final bool isOptional;
  final String? productDocumentId;
  final String? productName;

  const AdminRecipeIngredientInput({
    required this.name,
    this.quantity,
    this.unit,
    this.notes,
    this.isOptional = false,
    this.productDocumentId,
    this.productName,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (quantity != null) 'quantity': quantity,
    if (unit != null && unit!.trim().isNotEmpty) 'unit': unit,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    'is_optional': isOptional,
    if (productDocumentId != null && productDocumentId!.trim().isNotEmpty)
      'product_document_id': productDocumentId,
    if (productName != null && productName!.trim().isNotEmpty)
      'product_name': productName,
  };
}

class AdminRecipeInstructionInput {
  final int stepNumber;
  final String description;
  final int? durationMinutes;

  const AdminRecipeInstructionInput({
    required this.stepNumber,
    required this.description,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'step_number': stepNumber,
    'description': description,
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
  };
}

class AdminRecipeInput {
  final String title;
  final String description;
  final String category;
  final String authorName;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final List<String> tags;
  final List<AdminRecipeIngredientInput> ingredients;
  final List<AdminRecipeInstructionInput> instructions;
  final int? imageMediaId;

  const AdminRecipeInput({
    required this.title,
    required this.description,
    required this.category,
    required this.authorName,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.tags,
    required this.ingredients,
    required this.instructions,
    this.imageMediaId,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'author_name': authorName,
    'prep_time': prepTime,
    'cook_time': cookTime,
    'servings': servings,
    'difficulty': difficulty,
    'tags': tags,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'instructions': instructions.map((i) => i.toJson()).toList(),
    if (imageMediaId != null) 'image': imageMediaId,
  };
}

class AdminRecipeService {
  static String get _apiUrl => AppConstants.apiUrl;

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message']?.toString();
          if (message != null && message.trim().isNotEmpty) {
            return message;
          }
        }
        final message = decoded['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore JSON parse failures and fall back to raw body.
    }

    final raw = response.body.trim();
    if (raw.isNotEmpty) {
      return raw;
    }
    return fallback;
  }

  static Future<List<Map<String, dynamic>>> listRecipes({
    required String token,
    String? search,
    String? category,
  }) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty)
      params['search'] = search.trim();
    if (category != null && category.trim().isNotEmpty)
      params['category'] = category.trim();

    final uri = Uri.parse(
      '$_apiUrl/admin/recipes',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      final message = _extractErrorMessage(response, 'Unable to load recipes');
      throw Exception(
        'Failed to load recipes: ${response.statusCode} $message',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return data;
  }

  static Future<Map<String, dynamic>> getRecipe({
    required String token,
    required String recipeDocumentId,
  }) async {
    final response = await http
        .get(
          Uri.parse('$_apiUrl/admin/recipes/$recipeDocumentId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      final message = _extractErrorMessage(response, 'Unable to load recipe');
      throw Exception('Failed to load recipe: ${response.statusCode} $message');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createRecipe({
    required String token,
    required AdminRecipeInput input,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiUrl/admin/recipes'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'data': input.toJson()}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessage(response, 'Unable to create recipe');
      throw Exception(
        'Failed to create recipe: ${response.statusCode} $message',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateRecipe({
    required String token,
    required String recipeDocumentId,
    required AdminRecipeInput input,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_apiUrl/admin/recipes/$recipeDocumentId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'data': input.toJson()}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      final message = _extractErrorMessage(response, 'Unable to update recipe');
      throw Exception(
        'Failed to update recipe: ${response.statusCode} $message',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteRecipe({
    required String token,
    required String recipeDocumentId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_apiUrl/admin/recipes/$recipeDocumentId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final message = _extractErrorMessage(response, 'Unable to delete recipe');
      throw Exception(
        'Failed to delete recipe: ${response.statusCode} $message',
      );
    }
  }
}
