/// API configuration for Claude AI integration
///
/// IMPORTANT: Add your Anthropic API key here
/// Get your API key at: https://console.anthropic.com/
class ApiConfig {
  // TODO: Replace with your actual API key
  // This should ideally be stored securely (see README for best practices)
  static const String anthropicApiKey = 'YOUR_API_KEY_HERE';

  static const String anthropicApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-3-5-sonnet-20241022';
  static const int maxTokens = 1024;
  static const String apiVersion = '2023-06-01';

  /// Check if API key is configured
  static bool get isConfigured => anthropicApiKey != 'YOUR_API_KEY_HERE' && anthropicApiKey.isNotEmpty;

  /// System prompt for the AI assistant
  static String getSystemPrompt(String spendingContext) {
    return '''You are a personal finance advisor helping a user budget their money. You have READ-ONLY access to their spending data.

Here is their spending breakdown:

$spendingContext

Guidelines:
- Analyze their actual spending patterns
- Provide specific, actionable advice based on the data above
- Suggest realistic budgets for each category
- Identify areas where they can save money
- Be encouraging and supportive
- Keep responses concise (2-4 paragraphs)
- NEVER claim to save, modify, or store their data
- You only analyze data provided in this conversation
- Base all advice on the data provided above

Respond conversationally and be helpful!''';
  }
}
