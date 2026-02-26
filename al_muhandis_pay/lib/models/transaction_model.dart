/// ════════════════════════════════════════════════════════════
///  Al-Muhandis Pay — Transaction Model v3 (DB-Compatible)
///  الملف: lib/models/transaction_model.dart
/// ════════════════════════════════════════════════════════════
///  الإصلاحات:
///   ✅ transactionId → String (لأن transactions.id = char(36) UUID)
///   ✅ entry_type مقارنة بـ CREDIT/DEBIT (حروف كبيرة كما في الداتابيز)
///   ✅ entryId → String (لأن ledger_entries.id = bigint لكن يرجع كنص من JSON)
/// ════════════════════════════════════════════════════════════

class TransactionModel {
  final String entryId;
    final String entryType;       // 'CREDIT' أو 'DEBIT' (حروف كبيرة من الداتابيز)
      final double amount;
        final DateTime createdAt;
          final String transactionId;   // char(36) UUID — ليس int!
            final String txCategory;
              final String txStatus;
                final String receiptId;

                  TransactionModel({
                      required this.entryId,
                          required this.entryType,
                              required this.amount,
                                  required this.createdAt,
                                      required this.transactionId,
                                          required this.txCategory,
                                              required this.txStatus,
                                                  required this.receiptId,
                                                    });

                                                      factory TransactionModel.fromJson(Map<String, dynamic> json) {
                                                          return TransactionModel(
                                                                entryId: json['entry_id']?.toString() ?? '0',
                                                                      entryType: json['entry_type']?.toString() ?? '',
                                                                            amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
                                                                                  createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
                                                                                        transactionId: json['transaction_id']?.toString() ?? '',
                                                                                              txCategory: json['tx_category']?.toString() ?? '',
                                                                                                    txStatus: json['tx_status']?.toString() ?? '',
                                                                                                          receiptId: json['receipt_id']?.toString() ?? '',
                                                                                                              );
                                                                                                                }

                                                                                                                  /// ════════════════════════════════════════════════════
                                                                                                                    ///  الداتابيز تخزن CREDIT/DEBIT بحروف كبيرة
                                                                                                                      ///  نقارن case-insensitive لضمان التوافق
                                                                                                                        /// ════════════════════════════════════════════════════
                                                                                                                          bool get isCredit => entryType.toUpperCase() == 'CREDIT';
                                                                                                                            bool get isDebit  => entryType.toUpperCase() == 'DEBIT';

                                                                                                                              String get categoryLabel {
                                                                                                                                  switch (txCategory) {
                                                                                                                                        case 'deposit':    return 'إيداع';
                                                                                                                                              case 'withdrawal': return 'سحب';
                                                                                                                                                    case 'transfer':   return 'حوالة';
                                                                                                                                                          case 'fee':        return 'رسوم';
                                                                                                                                                                default:           return txCategory;
                                                                                                                                                                    }
                                                                                                                                                                      }

                                                                                                                                                                        String get categoryLabelEn {
                                                                                                                                                                            switch (txCategory) {
                                                                                                                                                                                  case 'deposit':    return 'DEPOSIT';
                                                                                                                                                                                        case 'withdrawal': return 'WITHDRAWAL';
                                                                                                                                                                                              case 'transfer':   return 'TRANSFER';
                                                                                                                                                                                                    case 'fee':        return 'FEE';
                                                                                                                                                                                                          default:           return txCategory.toUpperCase();
                                                                                                                                                                                                              }
                                                                                                                                                                                                                }

                                                                                                                                                                                                                  /// رمز الحركة المختصر للعرض (أول 8 أحرف من UUID)
                                                                                                                                                                                                                    String get shortTxId {
                                                                                                                                                                                                                        if (transactionId.length >= 8) {
                                                                                                                                                                                                                              return transactionId.substring(0, 8).toUpperCase();
                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                      return transactionId;
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        }

                                                                                                                                                                                                                                        class PaginationModel {
                                                                                                                                                                                                                                          final int currentPage;
                                                                                                                                                                                                                                            final int perPage;
                                                                                                                                                                                                                                              final int totalRecords;
                                                                                                                                                                                                                                                final int totalPages;
                                                                                                                                                                                                                                                  final bool hasMore;

                                                                                                                                                                                                                                                    PaginationModel({
                                                                                                                                                                                                                                                        required this.currentPage,
                                                                                                                                                                                                                                                            required this.perPage,
                                                                                                                                                                                                                                                                required this.totalRecords,
                                                                                                                                                                                                                                                                    required this.totalPages,
                                                                                                                                                                                                                                                                        required this.hasMore,
                                                                                                                                                                                                                                                                          });

                                                                                                                                                                                                                                                                            factory PaginationModel.fromJson(Map<String, dynamic> json) {
                                                                                                                                                                                                                                                                                return PaginationModel(
                                                                                                                                                                                                                                                                                      currentPage:  json['current_page']  ?? 1,
                                                                                                                                                                                                                                                                                            perPage:      json['per_page']      ?? 20,
                                                                                                                                                                                                                                                                                                  totalRecords: json['total_records'] ?? 0,
                                                                                                                                                                                                                                                                                                        totalPages:   json['total_pages']   ?? 0,
                                                                                                                                                                                                                                                                                                              hasMore:      json['has_more']      ?? false,
                                                                                                                                                                                                                                                                                                                  );
                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                                    