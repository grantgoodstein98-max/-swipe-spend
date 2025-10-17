import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/suggested_prompt_chip.dart';
import '../config/api_config.dart';

/// AI-powered budget assistant chat screen
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSuggestions = true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.isConfigured) {
      return _buildApiKeyMissingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, size: 24),
            SizedBox(width: 8),
            Text('Budget Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPrivacyInfo,
            tooltip: 'Privacy Info',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: chatProvider.messages.length +
                      (chatProvider.isLoading ? 1 : 0) +
                      (_showSuggestions &&
                              chatProvider.messages.length == 1
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    // Show suggested prompts after welcome message
                    if (_showSuggestions &&
                        chatProvider.messages.length == 1 &&
                        index == 1) {
                      return _buildSuggestedPrompts();
                    }

                    // Show typing indicator
                    if (chatProvider.isLoading &&
                        index == chatProvider.messages.length) {
                      return const TypingIndicator();
                    }

                    // Show message
                    final message = chatProvider.messages[index];
                    return ChatBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Input field
          _buildInputField(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzeSpending,
        icon: const Icon(Icons.analytics),
        label: const Text('Analyze Spending'),
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try asking:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              SuggestedPromptChip(
                label: 'Analyze my spending',
                icon: Icons.analytics,
                onTap: () {
                  setState(() => _showSuggestions = false);
                  _analyzeSpending();
                },
              ),
              SuggestedPromptChip(
                label: 'Where can I save?',
                icon: Icons.savings,
                onTap: () {
                  setState(() => _showSuggestions = false);
                  _findSavings();
                },
              ),
              SuggestedPromptChip(
                label: 'Am I overspending?',
                icon: Icons.warning_amber,
                onTap: () {
                  setState(() => _showSuggestions = false);
                  _checkOverspending();
                },
              ),
              SuggestedPromptChip(
                label: 'Create a budget',
                icon: Icons.account_balance_wallet,
                onTap: () {
                  setState(() => _showSuggestions = false);
                  _sendMessage('Please help me create a realistic budget based on my spending patterns.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask about your finances...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return IconButton(
                  onPressed: chatProvider.isLoading ? null : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: chatProvider.isLoading
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.primary,
                  ),
                  iconSize: 28,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyMissingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Assistant'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.key,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'API Key Required',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To use the AI Budget Assistant, you need an Anthropic API key.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Open Anthropic console (you would implement this with url_launcher)
                  _showApiKeyInstructions();
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Get API Key'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showApiKeyInstructions,
                icon: const Icon(Icons.help_outline),
                label: const Text('Setup Instructions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage([String? text]) {
    final message = text ?? _messageController.text;
    if (message.trim().isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    setState(() => _showSuggestions = false);

    chatProvider.sendMessage(
      message,
      transactionProvider.transactions,
      categoryProvider.categories,
    );

    _messageController.clear();
  }

  void _analyzeSpending() {
    final chatProvider = context.read<ChatProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    setState(() => _showSuggestions = false);

    chatProvider.analyzeSpending(
      transactionProvider.transactions,
      categoryProvider.categories,
    );
  }

  void _findSavings() {
    final chatProvider = context.read<ChatProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    chatProvider.findSavings(
      transactionProvider.transactions,
      categoryProvider.categories,
    );
  }

  void _checkOverspending() {
    final chatProvider = context.read<ChatProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    chatProvider.checkOverspending(
      transactionProvider.transactions,
      categoryProvider.categories,
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text(
          'This will delete all chat messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(context);
              setState(() => _showSuggestions = true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Data Usage'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How your data is used:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Your financial data is sent to Claude AI for analysis only',
              ),
              Text(
                '• Data is transmitted securely over HTTPS',
              ),
              Text(
                '• Your data is NOT permanently stored by the AI service',
              ),
              Text(
                '• The AI has READ-ONLY access to your spending data',
              ),
              Text(
                '• Chat history is saved locally on your device only',
              ),
              SizedBox(height: 16),
              Text(
                'Learn more:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Anthropic Privacy Policy: anthropic.com/privacy',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Get an API key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('   • Visit console.anthropic.com'),
              Text('   • Sign up or log in'),
              Text('   • Navigate to API Keys'),
              Text('   • Create a new API key'),
              SizedBox(height: 16),
              Text(
                '2. Add the key to your app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('   • Open lib/config/api_config.dart'),
              Text('   • Replace YOUR_API_KEY_HERE with your actual key'),
              Text('   • Save and restart the app'),
              SizedBox(height: 16),
              Text(
                'Note: Keep your API key secure and never share it publicly!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
