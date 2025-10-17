import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

/// Service for importing transactions from CSV and Excel files
class ImportService {
  static const _uuid = Uuid();

  /// Parse CSV file and return list of transactions
  static Future<List<Transaction>> parseCSV(File file) async {
    try {
      final input = await file.readAsString();
      final fields = const CsvToListConverter().convert(input);

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Assume first row is headers
      final headers = fields[0].map((e) => e.toString().toLowerCase()).toList();
      final transactions = <Transaction>[];

      // Find column indices
      final dateIndex = _findColumnIndex(headers, ['date', 'transaction date', 'posting date', 'trans date']);
      final nameIndex = _findColumnIndex(headers, ['description', 'name', 'merchant', 'transaction', 'details']);
      final amountIndex = _findColumnIndex(headers, ['amount', 'debit', 'transaction amount']);

      if (dateIndex == -1 || nameIndex == -1 || amountIndex == -1) {
        throw Exception('Could not find required columns (Date, Name, Amount) in CSV file');
      }

      // Parse each row (skip header)
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length <= dateIndex || row.length <= nameIndex || row.length <= amountIndex) {
          continue; // Skip invalid rows
        }

        try {
          final date = _parseDate(row[dateIndex].toString());
          final name = row[nameIndex].toString().trim();
          final amount = _parseAmount(row[amountIndex].toString());

          if (name.isEmpty || amount == 0.0) {
            continue; // Skip empty or zero transactions
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
        } catch (e) {
          // Skip rows that can't be parsed
          continue;
        }
      }

      return transactions;
    } catch (e) {
      throw Exception('Error parsing CSV file: $e');
    }
  }

  /// Parse Excel file and return list of transactions
  static Future<List<Transaction>> parseExcel(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('Excel file has no sheets');
      }

      // Get the first sheet
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel sheet is empty');
      }

      final transactions = <Transaction>[];

      // Assume first row is headers
      final headers = sheet.rows[0].map((cell) =>
        cell?.value?.toString().toLowerCase() ?? ''
      ).toList();

      // Find column indices
      final dateIndex = _findColumnIndex(headers, ['date', 'transaction date', 'posting date', 'trans date']);
      final nameIndex = _findColumnIndex(headers, ['description', 'name', 'merchant', 'transaction', 'details']);
      final amountIndex = _findColumnIndex(headers, ['amount', 'debit', 'transaction amount']);

      if (dateIndex == -1 || nameIndex == -1 || amountIndex == -1) {
        throw Exception('Could not find required columns (Date, Name, Amount) in Excel file');
      }

      // Parse each row (skip header)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length <= dateIndex || row.length <= nameIndex || row.length <= amountIndex) {
          continue; // Skip invalid rows
        }

        try {
          final dateCell = row[dateIndex]?.value;
          final nameCell = row[nameIndex]?.value;
          final amountCell = row[amountIndex]?.value;

          if (dateCell == null || nameCell == null || amountCell == null) {
            continue;
          }

          final date = _parseDate(dateCell.toString());
          final name = nameCell.toString().trim();
          final amount = _parseAmount(amountCell.toString());

          if (name.isEmpty || amount == 0.0) {
            continue; // Skip empty or zero transactions
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
        } catch (e) {
          // Skip rows that can't be parsed
          continue;
        }
      }

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
