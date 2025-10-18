import 'dart:convert';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

/// Service for importing transactions from CSV and Excel files
class ImportService {
  static const _uuid = Uuid();

  /// Parse CSV file and return list of transactions
  static Future<List<Transaction>> parseCSV(PlatformFile file) async {
    try {
      // Use bytes instead of file path (web compatibility)
      if (file.bytes == null) {
        throw Exception('Unable to read file data');
      }

      final bytes = file.bytes!;
      final csvString = utf8.decode(bytes);

      debugPrint('📄 CSV file size: ${bytes.length} bytes');
      debugPrint('📄 First 200 chars: ${csvString.substring(0, min(200, csvString.length))}');

      // Parse CSV
      final fields = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
      );

      debugPrint('📊 Found ${fields.length} rows');

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Assume first row is headers
      final headers = fields[0].map((e) => e.toString().toLowerCase().trim()).toList();
      debugPrint('📋 Headers: $headers');

      final transactions = <Transaction>[];

      // Find column indices with more variations
      final dateIndex = _findColumnIndex(headers, [
        'date',
        'transaction date',
        'posting date',
        'posted date',
        'trans date',
      ]);
      final nameIndex = _findColumnIndex(headers, [
        'description',
        'name',
        'merchant',
        'payee',
        'memo',
        'transaction',
        'details',
      ]);
      final amountIndex = _findColumnIndex(headers, [
        'amount',
        'debit',
        'credit',
        'price',
        'transaction amount',
      ]);

      debugPrint('📍 Column indices - Date: $dateIndex, Name: $nameIndex, Amount: $amountIndex');

      if (dateIndex == -1 || nameIndex == -1 || amountIndex == -1) {
        throw Exception(
          'Required columns not found.\n\n'
          'Found columns: ${headers.join(", ")}\n\n'
          'Need: Date, Description, and Amount',
        );
      }

      // Parse each row (skip header)
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length <= max(dateIndex, max(nameIndex, amountIndex))) {
          debugPrint('⚠️ Row $i has insufficient columns, skipping');
          continue;
        }

        try {
          final date = _parseDate(row[dateIndex].toString());
          final name = row[nameIndex].toString().trim();
          final amount = _parseAmount(row[amountIndex].toString());

          if (name.isEmpty || amount == 0.0) {
            debugPrint('⏭️ Skipping row $i: empty name or zero amount');
            continue;
          }

          transactions.add(Transaction(
            id: _uuid.v4(),
            plaidId: 'imported_${_uuid.v4()}',
            name: name,
            amount: amount.abs(), // Always use positive amounts
            date: date,
            merchantName: name,
            isCategorized: false,
          ));

          debugPrint('✅ Parsed transaction $i: $name - \$${amount.abs()}');
        } catch (e) {
          debugPrint('❌ Error parsing row $i: $e');
          continue;
        }
      }

      debugPrint('🎉 Successfully parsed ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      throw Exception('Error parsing CSV file: $e');
    }
  }

  /// Parse Excel file and return list of transactions
  static Future<List<Transaction>> parseExcel(PlatformFile file) async {
    try {
      // Use bytes instead of file path (web compatibility)
      if (file.bytes == null) {
        throw Exception('Unable to read file data');
      }

      final bytes = file.bytes!;
      debugPrint('📄 Excel file size: ${bytes.length} bytes');

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in Excel file');
      }

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel sheet is empty');
      }

      final rows = sheet.rows;
      debugPrint('📊 Sheet: $sheetName, Rows: ${rows.length}');

      final transactions = <Transaction>[];

      // Assume first row is headers
      final headers = rows[0].map((cell) =>
        cell?.value?.toString().toLowerCase().trim() ?? ''
      ).toList();

      debugPrint('📋 Headers: $headers');

      // Find column indices with more variations
      final dateIndex = _findColumnIndex(headers, [
        'date',
        'transaction date',
        'posting date',
        'posted date',
        'trans date',
      ]);
      final nameIndex = _findColumnIndex(headers, [
        'description',
        'name',
        'merchant',
        'payee',
        'memo',
        'transaction',
        'details',
      ]);
      final amountIndex = _findColumnIndex(headers, [
        'amount',
        'debit',
        'credit',
        'price',
        'transaction amount',
      ]);

      debugPrint('📍 Column indices - Date: $dateIndex, Name: $nameIndex, Amount: $amountIndex');

      if (dateIndex == -1 || nameIndex == -1 || amountIndex == -1) {
        throw Exception(
          'Required columns not found.\n\n'
          'Found columns: ${headers.join(", ")}\n\n'
          'Need: Date, Description, and Amount',
        );
      }

      // Parse each row (skip header)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length <= max(dateIndex, max(nameIndex, amountIndex))) {
          debugPrint('⚠️ Row $i has insufficient columns, skipping');
          continue;
        }

        try {
          final dateCell = row[dateIndex]?.value;
          final nameCell = row[nameIndex]?.value;
          final amountCell = row[amountIndex]?.value;

          if (dateCell == null || nameCell == null || amountCell == null) {
            debugPrint('⏭️ Skipping row $i: null values');
            continue;
          }

          final date = _parseDate(dateCell.toString());
          final name = nameCell.toString().trim();
          final amount = _parseAmount(amountCell.toString());

          if (name.isEmpty || amount == 0.0) {
            debugPrint('⏭️ Skipping row $i: empty name or zero amount');
            continue;
          }

          transactions.add(Transaction(
            id: _uuid.v4(),
            plaidId: 'imported_${_uuid.v4()}',
            name: name,
            amount: amount.abs(), // Always use positive amounts
            date: date,
            merchantName: name,
            isCategorized: false,
          ));

          debugPrint('✅ Parsed transaction $i: $name - \$${amount.abs()}');
        } catch (e) {
          debugPrint('❌ Error parsing row $i: $e');
          continue;
        }
      }

      debugPrint('🎉 Successfully parsed ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      throw Exception('Error parsing Excel file: $e');
    }
  }

  /// Find column index by matching against common column names
  static int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      for (final name in possibleNames) {
        if (header.contains(name.toLowerCase())) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Parse date from various formats
  static DateTime _parseDate(String dateStr) {
    dateStr = dateStr.trim();

    // Try ISO format first (YYYY-MM-DD)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Try MM/DD/YYYY format
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    // Try DD-MM-YYYY format
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3 && parts[0].length <= 2) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    throw Exception('Unable to parse date: $dateStr');
  }

  /// Parse amount from string, handling various formats
  static double _parseAmount(String amountStr) {
    amountStr = amountStr.trim();

    // Remove currency symbols and commas
    amountStr = amountStr.replaceAll(RegExp(r'[^\d.-]'), '');

    if (amountStr.isEmpty) {
      return 0.0;
    }

    try {
      return double.parse(amountStr);
    } catch (_) {
      return 0.0;
    }
  }
}
