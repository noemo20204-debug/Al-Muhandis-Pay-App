import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/transaction_model.dart';
import '../services/statement_service.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});
  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final StatementService _service = StatementService();
  final ScrollController _scrollController = ScrollController();
  List<TransactionModel> _transactions = [];
  int _currentPage = 1; bool _isLoading = false; bool _isLoadingMore = false; bool _hasMore = true; String? _errorMessage;
  String _selectedType = 'all'; DateTime? _startDate; DateTime? _endDate;
  final List<Map<String, String>> _typeOptions = [{'value': 'all', 'label': 'الكل'}, {'value': 'deposit', 'label': 'إيداع'}, {'value': 'withdrawal', 'label': 'سحب'}, {'value': 'transfer', 'label': 'حوالة'}];
  final DateFormat _displayDateFormat = DateFormat('yyyy/MM/dd');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fetchStatement();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMore();
  }

  Future<void> _fetchStatement() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _errorMessage = null; _currentPage = 1; _transactions = []; _hasMore = true; });
    try {
      final response = await _service.fetchStatement(page: 1, limit: 20, type: _selectedType, startDate: _startDate != null ? _apiDateFormat.format(_startDate!) : null, endDate: _endDate != null ? _apiDateFormat.format(_endDate!) : null);
      if (!mounted) return;
      setState(() { _transactions = response.transactions; _hasMore = response.pagination.hasMore; _currentPage = 1; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'فشل في تحميل كشف الحساب. تحقق من الاتصال.'; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await _service.fetchStatement(page: nextPage, limit: 20, type: _selectedType, startDate: _startDate != null ? _apiDateFormat.format(_startDate!) : null, endDate: _endDate != null ? _apiDateFormat.format(_endDate!) : null);
      if (!mounted) return;
      setState(() { _transactions.addAll(response.transactions); _hasMore = response.pagination.hasMore; _currentPage = nextPage; _isLoadingMore = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async => await _fetchStatement();
  void _applyFilter() => _fetchStatement();
  void _clearFilters() { setState(() { _selectedType = 'all'; _startDate = null; _endDate = null; }); _fetchStatement(); }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1A5276), onPrimary: Colors.white, surface: Colors.white)), child: child!);
      },
    );
    if (picked != null) { setState(() { if (isStart) _startDate = picked; else _endDate = picked; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(title: const Text('كشف الحساب', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white, elevation: 0),
        body: Column(children: [_buildFilterBar(), Expanded(child: _buildBody())]),
      ),
    );
  }

  Widget _buildFilterBar() {
    final bool hasActiveFilters = _selectedType != 'all' || _startDate != null || _endDate != null;
    return Container(
      color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedType, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down), items: _typeOptions.map((option) => DropdownMenuItem<String>(value: option['value'], child: Text(option['label']!, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (value) { if (value != null) { setState(() => _selectedType = value); _applyFilter(); } })))),
          const SizedBox(width: 8),
          if (hasActiveFilters) TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.clear, size: 18), label: const Text('مسح'), style: TextButton.styleFrom(foregroundColor: Colors.red.shade600)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildDateChip(label: _startDate != null ? _displayDateFormat.format(_startDate!) : 'من تاريخ', icon: Icons.calendar_today, isActive: _startDate != null, onTap: () => _pickDate(isStart: true))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey)),
          Expanded(child: _buildDateChip(label: _endDate != null ? _displayDateFormat.format(_endDate!) : 'إلى تاريخ', icon: Icons.calendar_today, isActive: _endDate != null, onTap: () => _pickDate(isStart: false))),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _applyFilter, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), child: const Icon(Icons.search, size: 20)),
        ]),
      ]),
    );
  }

  Widget _buildDateChip({required String label, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: isActive ? const Color(0xFF1A5276) : Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: isActive ? const Color(0xFF1A5276).withOpacity(0.05) : null),
        child: Row(children: [Icon(icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 6), Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isActive ? const Color(0xFF1A5276) : Colors.grey.shade600), overflow: TextOverflow.ellipsis))]),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A5276)));
    if (_errorMessage != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400), const SizedBox(height: 16), Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600, fontSize: 15), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton.icon(onPressed: _fetchStatement, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white))]));
    if (_transactions.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400), const SizedBox(height: 16), Text('لا توجد حركات مالية', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]));
    return RefreshIndicator(
      onRefresh: _onRefresh, color: const Color(0xFF1A5276),
      child: ListView.builder(
        controller: _scrollController, physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A5276))));
          return _buildTransactionCard(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final bool isCredit = tx.isCredit; final Color amountColor = isCredit ? Colors.green.shade700 : Colors.red.shade700;
    final IconData txIcon = _getTxIcon(tx.txCategory); final Color iconBgColor = isCredit ? Colors.green.shade50 : Colors.red.shade50;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)), child: Icon(txIcon, color: amountColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tx.categoryLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 4), Text('#${tx.transactionId}  •  ${DateFormat('yyyy/MM/dd - HH:mm').format(tx.createdAt)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))])),
        Text('${isCredit ? '+' : '-'} ${tx.amount.toStringAsFixed(2)}', style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  IconData _getTxIcon(String category) {
    switch (category) { case 'deposit': return Icons.arrow_downward_rounded; case 'withdrawal': return Icons.arrow_upward_rounded; case 'transfer': return Icons.swap_horiz_rounded; default: return Icons.receipt; }
  }
}
