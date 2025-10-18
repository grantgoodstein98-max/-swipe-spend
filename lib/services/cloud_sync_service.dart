import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart' as model;
import '../models/budget.dart';
import 'auth_service.dart';

/// Service for syncing data with Firebase Firestore
class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Sync transactions to cloud
  Future<void> syncTransactions(
      String userId, List<model.Transaction> transactions) async {
    try {
      final batch = _firestore.batch();

      for (var transaction in transactions) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(transaction.id);

        batch.set(docRef, transaction.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ Synced ${transactions.length} transactions to cloud');
    } catch (e) {
      debugPrint('❌ Error syncing transactions: $e');
      rethrow;
    }
  }

  /// Load transactions from cloud
  Future<List<model.Transaction>> loadTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      final transactions = snapshot.docs
          .map((doc) => model.Transaction.fromJson(doc.data()))
          .toList();

      debugPrint('✅ Loaded ${transactions.length} transactions from cloud');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      return [];
    }
  }

  /// Sync categories to cloud
  Future<void> syncCategories(
      String userId, List<model.Category> categories) async {
    try {
      final batch = _firestore.batch();

      for (var category in categories) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(category.id);

        batch.set(docRef, category.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ Synced ${categories.length} categories to cloud');
    } catch (e) {
      debugPrint('❌ Error syncing categories: $e');
      rethrow;
    }
  }

  /// Load categories from cloud
  Future<List<model.Category>> loadCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      final categories = snapshot.docs
          .map((doc) => model.Category.fromJson(doc.data()))
          .toList();

      debugPrint('✅ Loaded ${categories.length} categories from cloud');
      return categories;
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      return [];
    }
  }

  /// Sync budgets to cloud
  Future<void> syncBudgets(String userId, List<Budget> budgets) async {
    try {
      final batch = _firestore.batch();

      for (var budget in budgets) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc(budget.id);

        batch.set(docRef, budget.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ Synced ${budgets.length} budgets to cloud');
    } catch (e) {
      debugPrint('❌ Error syncing budgets: $e');
      rethrow;
    }
  }

  /// Load budgets from cloud
  Future<List<Budget>> loadBudgets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .get();

      final budgets =
          snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList();

      debugPrint('✅ Loaded ${budgets.length} budgets from cloud');
      return budgets;
    } catch (e) {
      debugPrint('❌ Error loading budgets: $e');
      return [];
    }
  }

  /// Sync all data at once
  Future<void> syncAll(
    String userId, {
    required List<model.Transaction> transactions,
    required List<model.Category> categories,
    required List<Budget> budgets,
  }) async {
    try {
      await Future.wait([
        syncTransactions(userId, transactions),
        syncCategories(userId, categories),
        syncBudgets(userId, budgets),
      ]);

      // Update last sync time
      await _firestore.collection('users').doc(userId).set({
        'lastSync': FieldValue.serverTimestamp(),
        'email': _authService.userEmail,
      }, SetOptions(merge: true));

      debugPrint('✅ Synced all data to cloud');
    } catch (e) {
      debugPrint('❌ Error syncing all data: $e');
      rethrow;
    }
  }

  /// Load all data at once
  Future<Map<String, dynamic>> loadAll(String userId) async {
    try {
      final results = await Future.wait([
        loadTransactions(userId),
        loadCategories(userId),
        loadBudgets(userId),
      ]);

      debugPrint('✅ Loaded all data from cloud');

      return {
        'transactions': results[0] as List<model.Transaction>,
        'categories': results[1] as List<model.Category>,
        'budgets': results[2] as List<Budget>,
      };
    } catch (e) {
      debugPrint('❌ Error loading all data: $e');
      return {
        'transactions': <model.Transaction>[],
        'categories': <model.Category>[],
        'budgets': <Budget>[],
      };
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['lastSync'] != null) {
        final timestamp = doc.data()!['lastSync'] as Timestamp;
        return timestamp.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting last sync time: $e');
      return null;
    }
  }
}
