import '../models/transaction_model.dart';
import 'api_engine.dart';

class StatementService {
  final _dio = ApiEngine().dio;

  Future<StatementResponse> fetchStatement({int page = 1, int limit = 20, String type = 'all', String? startDate, String? endDate}) async {
    final Map<String, dynamic> queryParams = {'page': page, 'limit': limit, 'type': type};
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

    final response = await _dio.get('/statement', queryParameters: queryParams);

    if (response.statusCode == 200) {
      final data = response.data['data'];
      return StatementResponse(
        transactions: (data['transactions'] as List).map((json) => TransactionModel.fromJson(json)).toList(),
        pagination: PaginationModel.fromJson(data['pagination']),
      );
    }
    throw Exception(response.data['message'] ?? 'فشل في جلب كشف الحساب');
  }
}

class StatementResponse {
  final List<TransactionModel> transactions;
  final PaginationModel pagination;
  StatementResponse({required this.transactions, required this.pagination});
}
