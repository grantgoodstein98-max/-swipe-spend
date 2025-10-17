import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/ai_service.dart';
import '../utils/spending_analyzer.dart';

/// Provider for managing chat messages and AI interactions
class ChatProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _storageKey = 'chat_messages';
  static const int _maxStoredMessages = 10;

  ChatProvider() {
    _loadMessages();
    _addWelcomeMessage();
  }

  /// Load saved messages from storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_storageKey);

      if (messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        _messages.clear();
        _messages.addAll(
          decoded.map((json) => ChatMessage.fromJson(json)),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// Save messages to storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only save last N messages to avoid storage bloat
      final messagesToSave = _messages.length > _maxStoredMessages
          ? _messages.sublist(_messages.length - _maxStoredMessages)
          : _messages;

      final messagesJson = jsonEncode(
        messagesToSave.map((m) => m.toJson()).toList(),
      );

      await prefs.setString(_storageKey, messagesJson);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  /// Add welcome message if no messages exist
  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage.assistant(
          "Hi! I'm your budget assistant. I can analyze your spending and help you save money. Ask me anything about your finances!",
        ),
      );
      notifyListeners();
    }
  }

  /// Add a message to the chat
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
    _saveMessages();
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(
    String text,
    List<Transaction> transactions,
    List<Category> categories,
  ) async {
    if (text.trim().isEmpty) return;

    // Clear any previous errors
    _error = null;

    // Add user message
    final userMessage = ChatMessage.user(text);
    addMessage(userMessage);

    // Check if there are transactions to analyze
    if (transactions.isEmpty) {
      final errorMessage = ChatMessage.assistant(
        "You need to categorize some transactions first before I can help! Head to the Swipe tab to categorize your transactions.",
      );
      addMessage(errorMessage);
      return;
    }

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Generate spending context
      final spendingReport = SpendingAnalyzer.generateSpendingReport(
        transactions,
        categories,
      );

      // Get AI response
      final response = await _aiService.sendMessage(text, spendingReport);

      // Add AI response
      final aiMessage = ChatMessage.assistant(response);
      addMessage(aiMessage);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');

      // Add error message to chat
      final errorMessage = ChatMessage.assistant(
        "Sorry, I encountered an error: $_error",
      );
      addMessage(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick action: Analyze spending
  Future<void> analyzeSpending(
    List<Transaction> transactions,
    List<Category> categories,
  ) async {
    if (transactions.isEmpty) {
      final errorMessage = ChatMessage.assistant(
        "You need to categorize some transactions first! Head to the Swipe tab to get started.",
      );
      addMessage(errorMessage);
      return;
    }

    // Add user message showing what was requested
    addMessage(ChatMessage.user("Analyze my spending"));

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final spendingReport = SpendingAnalyzer.generateSpendingReport(
        transactions,
        categories,
      );

      final response = await _aiService.analyzeSpending(spendingReport);

      addMessage(ChatMessage.assistant(response));
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      addMessage(
        ChatMessage.assistant("Sorry, I encountered an error: $_error"),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick action: Find savings
  Future<void> findSavings(
    List<Transaction> transactions,
    List<Category> categories,
  ) async {
    if (transactions.isEmpty) {
      addMessage(
        ChatMessage.assistant(
          "You need to categorize some transactions first!",
        ),
      );
      return;
    }

    addMessage(ChatMessage.user("Where can I save money?"));

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final spendingReport = SpendingAnalyzer.generateSpendingReport(
        transactions,
        categories,
      );

      final response = await _aiService.findSavingOpportunities(spendingReport);

      addMessage(ChatMessage.assistant(response));
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      addMessage(
        ChatMessage.assistant("Sorry, I encountered an error: $_error"),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick action: Check overspending
  Future<void> checkOverspending(
    List<Transaction> transactions,
    List<Category> categories,
  ) async {
    if (transactions.isEmpty) {
      addMessage(
        ChatMessage.assistant(
          "You need to categorize some transactions first!",
        ),
      );
      return;
    }

    addMessage(ChatMessage.user("Am I overspending?"));

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final spendingReport = SpendingAnalyzer.generateSpendingReport(
        transactions,
        categories,
      );

      final response = await _aiService.checkOverspending(spendingReport);

      addMessage(ChatMessage.assistant(response));
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      addMessage(
        ChatMessage.assistant("Sorry, I encountered an error: $_error"),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all messages
  Future<void> clearChat() async {
    _messages.clear();
    _error = null;
    _addWelcomeMessage();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
