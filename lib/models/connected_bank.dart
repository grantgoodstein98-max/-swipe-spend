/// Model representing a connected bank account via Plaid
class ConnectedBank {
  final String institutionId;
  final String institutionName;
  final String accessToken;
  final String? accountMask; // Last 4 digits
  final String? accountType; // Checking, Savings, Credit, etc.
  final DateTime connectedAt;
  final DateTime? lastSyncedAt;
  final BankConnectionStatus status;
  final String? errorMessage;
  final int lastSyncTransactionCount;
  final String? logoUrl;
  final String? nickname; // Optional user-defined name

  ConnectedBank({
    required this.institutionId,
    required this.institutionName,
    required this.accessToken,
    this.accountMask,
    this.accountType,
    required this.connectedAt,
    this.lastSyncedAt,
    this.status = BankConnectionStatus.connected,
    this.errorMessage,
    this.lastSyncTransactionCount = 0,
    this.logoUrl,
    this.nickname,
  });

  String get displayName => nickname ?? institutionName;

  String get lastSyncText {
    if (lastSyncedAt == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(lastSyncedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else {
      return 'More than a week ago';
    }
  }

  ConnectedBank copyWith({
    String? institutionId,
    String? institutionName,
    String? accessToken,
    String? accountMask,
    String? accountType,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
    BankConnectionStatus? status,
    String? errorMessage,
    int? lastSyncTransactionCount,
    String? logoUrl,
    String? nickname,
  }) {
    return ConnectedBank(
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      accessToken: accessToken ?? this.accessToken,
      accountMask: accountMask ?? this.accountMask,
      accountType: accountType ?? this.accountType,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTransactionCount: lastSyncTransactionCount ?? this.lastSyncTransactionCount,
      logoUrl: logoUrl ?? this.logoUrl,
      nickname: nickname ?? this.nickname,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institutionId': institutionId,
      'institutionName': institutionName,
      'accessToken': accessToken,
      'accountMask': accountMask,
      'accountType': accountType,
      'connectedAt': connectedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
      'lastSyncTransactionCount': lastSyncTransactionCount,
      'logoUrl': logoUrl,
      'nickname': nickname,
    };
  }

  factory ConnectedBank.fromJson(Map<String, dynamic> json) {
    return ConnectedBank(
      institutionId: json['institutionId'],
      institutionName: json['institutionName'],
      accessToken: json['accessToken'],
      accountMask: json['accountMask'],
      accountType: json['accountType'],
      connectedAt: DateTime.parse(json['connectedAt']),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'])
          : null,
      status: BankConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BankConnectionStatus.connected,
      ),
      errorMessage: json['errorMessage'],
      lastSyncTransactionCount: json['lastSyncTransactionCount'] ?? 0,
      logoUrl: json['logoUrl'],
      nickname: json['nickname'],
    );
  }
}

enum BankConnectionStatus {
  connected,
  needsReauth,
  error,
  syncing,
}

extension BankConnectionStatusExtension on BankConnectionStatus {
  String get displayText {
    switch (this) {
      case BankConnectionStatus.connected:
        return 'Connected';
      case BankConnectionStatus.needsReauth:
        return 'Needs Reauth';
      case BankConnectionStatus.error:
        return 'Error';
      case BankConnectionStatus.syncing:
        return 'Syncing...';
    }
  }
}
