class TransactionModel {
  final int entryId;
  final String entryType;
  final double amount;
  final DateTime createdAt;
  final int transactionId;
  final String txCategory;
  final String txStatus;
  final String receiptId;

  TransactionModel({
    required this.entryId, required this.entryType, required this.amount, required this.createdAt,
    required this.transactionId, required this.txCategory, required this.txStatus, required this.receiptId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      entryId: int.tryParse(json['entry_id'].toString()) ?? 0,
      entryType: json['entry_type'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      transactionId: int.tryParse(json['transaction_id'].toString()) ?? 0,
      txCategory: json['tx_category'] ?? '',
      txStatus: json['tx_status'] ?? '',
      receiptId: json['receipt_id'] ?? '',
    );
  }

  bool get isCredit => entryType == 'credit';
  String get categoryLabel {
    switch (txCategory) {
      case 'deposit': return 'إيداع';
      case 'withdrawal': return 'سحب';
      case 'transfer': return 'حوالة';
      default: return txCategory;
    }
  }

  String get categoryLabelEn {
    switch (txCategory) {
      case 'deposit': return 'DEPOSIT';
      case 'withdrawal': return 'WITHDRAWAL';
      case 'transfer': return 'TRANSFER';
      default: return txCategory.toUpperCase();
    }
  }
}

class PaginationModel {
  final int currentPage; final int perPage; final int totalRecords; final int totalPages; final bool hasMore;
  PaginationModel({required this.currentPage, required this.perPage, required this.totalRecords, required this.totalPages, required this.hasMore});

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['current_page'] ?? 1, perPage: json['per_page'] ?? 20,
      totalRecords: json['total_records'] ?? 0, totalPages: json['total_pages'] ?? 0, hasMore: json['has_more'] ?? false,
    );
  }
}
