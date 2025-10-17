import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for interacting with Claude AI API
class AiService {
  /// Send a message to Claude and get a response
  Future<String> sendMessage(String userMessage, String spendingContext) async {
    if (!ApiConfig.isConfigured) {
      throw Exception(
        'API key not configured. Please add your Anthropic API key in lib/config/api_config.dart',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.anthropicApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiConfig.anthropicApiKey,
          'anthropic-version': ApiConfig.apiVersion,
        },
        body: jsonEncode({
          'model': ApiConfig.claudeModel,
          'max_tokens': ApiConfig.maxTokens,
          'system': ApiConfig.getSystemPrompt(spendingContext),
          'messages': [
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract text from the response
        if (data['content'] != null && data['content'] is List && data['content'].isNotEmpty) {
          return data['content'][0]['text'] as String;
        }

        throw Exception('Unexpected response format from API');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Anthropic API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error: $errorMessage');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      rethrow;
    }
  }

  /// Prepare spending context from transaction data
  String prepareSpendingContext(String spendingReport) {
    return spendingReport;
  }

  /// Get a quick analysis of spending (uses pre-built prompt)
  Future<String> analyzeSpending(String spendingContext) async {
    const prompt = '''Please analyze my spending and provide:
1. An overview of my spending habits
2. Categories where I'm spending the most
3. Specific suggestions for where I can save money
4. A realistic budget recommendation for each category''';

    return await sendMessage(prompt, spendingContext);
  }

  /// Get budget suggestions
  Future<String> getBudgetSuggestions(String spendingContext) async {
    const prompt = '''Based on my spending patterns, please suggest a monthly budget for each category.
Make sure the budgets are realistic and achievable based on my current spending.''';

    return await sendMessage(prompt, spendingContext);
  }

  /// Identify saving opportunities
  Future<String> findSavingOpportunities(String spendingContext) async {
    const prompt = '''Please identify specific areas where I'm overspending and provide actionable tips
to reduce my expenses in those categories.''';

    return await sendMessage(prompt, spendingContext);
  }

  /// Check if user is overspending
  Future<String> checkOverspending(String spendingContext) async {
    const prompt = '''Am I overspending in any categories? Please analyze my spending patterns and
let me know if there are any red flags or concerning trends.''';

    return await sendMessage(prompt, spendingContext);
  }
}
