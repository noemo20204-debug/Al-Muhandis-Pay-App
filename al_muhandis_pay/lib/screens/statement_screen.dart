import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../services/statement_service.dart';

class _EliteColors {
  static const Color nightBg     = Color(0xFF0B101E);
  static const Color cardBg      = Color(0xFF161C2D);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight   = Color(0xFFE8D48B);
  static const Color success     = Color(0xFF2ECC71);
  static const Color danger      = Color(0xFFE74C3C);
  static const Color glassBorder = Color(0xFF1E2740);
}

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});
  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final StatementService _service = StatementService();
  final ScrollController _scrollController = ScrollController();
  List<TransactionModel> _transactions = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _selectedType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all',        'label': 'الكل'},
    {'value': 'deposit',    'label': 'إيداع'},
    {'value': 'withdrawal', 'label': 'سحب'},
    {'value': 'transfer',   'label': 'حوالة'},
  ];

  final DateFormat _displayDateFormat = DateFormat('yyyy/MM/dd');
  final DateFormat _apiDateFormat     = DateFormat('yyyy-MM-dd');

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchStatement() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _errorMessage = null; _currentPage = 1; _transactions = []; _hasMore = true; });
    try {
      final response = await _service.fetchStatement(
        page: 1, limit: 20, type: _selectedType,
        startDate: _startDate != null ? _apiDateFormat.format(_startDate!) : null,
        endDate: _endDate != null ? _apiDateFormat.format(_endDate!) : null,
      );
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
      final response = await _service.fetchStatement(
        page: nextPage, limit: 20, type: _selectedType,
        startDate: _startDate != null ? _apiDateFormat.format(_startDate!) : null,
        endDate: _endDate != null ? _apiDateFormat.format(_endDate!) : null,
      );
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
      firstDate: DateTime(2020), lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: _EliteColors.goldPrimary, onPrimary: Colors.black, surface: _EliteColors.cardBg, onSurface: Colors.white),
            dialogBackgroundColor: _EliteColors.nightBg,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) { setState(() { if (isStart) _startDate = picked; else _endDate = picked; }); }
  }

  // ════════════════════════════════════════════════════════
  //  شاشة الإيصال المنبثقة + التصوير والمشاركة
  // ════════════════════════════════════════════════════════
  void _showReceipt(TransactionModel tx) {
    final bool isCredit = tx.isCredit;
    final Color amountColor = isCredit ? _EliteColors.success : _EliteColors.danger;
    
    // مفتاح الكاميرا لالتقاط صورة الإيصال
    final GlobalKey receiptKey = GlobalKey();
    bool isSharing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 📸 الجزء الذي سيتم تصويره
                    RepaintBoundary(
                      key: receiptKey,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        decoration: BoxDecoration(
                          color: _EliteColors.nightBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _EliteColors.goldPrimary.withOpacity(0.4), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 16), width: 50, height: 4,
                              decoration: BoxDecoration(color: _EliteColors.goldPrimary.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(color: amountColor.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: amountColor.withOpacity(0.3), width: 1.5)),
                                    child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: amountColor, size: 32),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(tx.categoryLabel, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(tx.categoryLabelEn, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500, letterSpacing: 3)),
                                  const SizedBox(height: 20),
                                  Text(
                                    '${isCredit ? '+' : '-'} ${tx.amount.toStringAsFixed(2)} USDT',
                                    style: GoogleFonts.cairo(fontSize: 34, fontWeight: FontWeight.bold, color: amountColor),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: List.generate(40, (i) => Expanded(
                                  child: Container(height: 1, color: i.isEven ? _EliteColors.goldPrimary.withOpacity(0.3) : Colors.transparent),
                                )),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                              child: Column(
                                children: [
                                  _receiptRow('رقم العملية', tx.shortTxId),
                                  _receiptRow('نوع القيد', tx.isCredit ? 'دائن (Credit)' : 'مدين (Debit)'),
                                  _receiptRow('الحالة', tx.txStatus == 'completed' ? 'مكتملة ✅' : tx.txStatus),
                                  _receiptRow('التاريخ', DateFormat('yyyy/MM/dd').format(tx.createdAt)),
                                  _receiptRow('الوقت', DateFormat('HH:mm:ss').format(tx.createdAt)),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: _EliteColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _EliteColors.glassBorder)),
                              child: Row(
                                children: [
                                  const Icon(Icons.fingerprint, color: _EliteColors.goldPrimary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Transaction ID', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500)),
                                        const SizedBox(height: 2),
                                        Text(tx.transactionId, style: GoogleFonts.sourceCodePro(fontSize: 10, color: _EliteColors.goldLight, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: _EliteColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _EliteColors.glassBorder)),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline, color: _EliteColors.goldPrimary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Receipt Hash', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500)),
                                        const SizedBox(height: 2),
                                        Text(tx.receiptId.isNotEmpty ? tx.receiptId : 'N/A', style: GoogleFonts.sourceCodePro(fontSize: 10, color: _EliteColors.goldLight, letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                              child: Column(
                                children: [
                                  const Icon(Icons.security, color: _EliteColors.goldPrimary, size: 22),
                                  const SizedBox(height: 6),
                                  Text('Al-Muhandis Pay', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: _EliteColors.goldPrimary)),
                                  Text('Secured Transaction Receipt', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 📤 زر المشاركة
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _EliteColors.goldPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                          ),
                          onPressed: isSharing ? null : () async {
                            setModalState(() => isSharing = true);
                            try {
                              // التقاط الصورة بدقة عالية
                              RenderRepaintBoundary boundary = receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                              ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                              ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                              Uint8List pngBytes = byteData!.buffer.asUint8List();

                              // حفظ الصورة في ملف مؤقت
                              final directory = await getTemporaryDirectory();
                              final imagePath = await File('${directory.path}/AlMuhandis_Receipt_${tx.shortTxId}.png').create();
                              await imagePath.writeAsBytes(pngBytes);

                              // مشاركة الصورة
                              await Share.shareXFiles(
                                [XFile(imagePath.path)], 
                                text: 'إيصال معاملة من تطبيق المهندس Pay\nرقم العملية: ${tx.shortTxId}'
                              );
                            } catch (e) {
                              debugPrint('Error sharing receipt: $e');
                            } finally {
                              setModalState(() => isSharing = false);
                            }
                          },
                          icon: isSharing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.share, size: 24),
                          label: Text(
                            isSharing ? 'جاري التجهيز...' : 'مشاركة الإيصال', 
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400)),
          Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _EliteColors.nightBg,
        appBar: AppBar(
          title: Text('كشف الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _EliteColors.goldPrimary)),
          backgroundColor: _EliteColors.nightBg, foregroundColor: _EliteColors.goldPrimary,
          elevation: 0, iconTheme: const IconThemeData(color: _EliteColors.goldPrimary),
        ),
        body: Column(children: [_buildFilterBar(), Expanded(child: _buildBody())]),
      ),
    );
  }

  Widget _buildFilterBar() {
    final bool hasActiveFilters = _selectedType != 'all' || _startDate != null || _endDate != null;
    return Container(
      color: _EliteColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: _EliteColors.glassBorder), borderRadius: BorderRadius.circular(12), color: _EliteColors.nightBg),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType, isExpanded: true, dropdownColor: _EliteColors.cardBg,
                      icon: const Icon(Icons.keyboard_arrow_down, color: _EliteColors.goldPrimary),
                      items: _typeOptions.map((o) => DropdownMenuItem<String>(value: o['value'], child: Text(o['label']!, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)))).toList(),
                      onChanged: (v) { if (v != null) { setState(() => _selectedType = v); _applyFilter(); } },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasActiveFilters) TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 16, color: _EliteColors.danger),
                label: Text('مسح', style: GoogleFonts.cairo(color: _EliteColors.danger, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDateChip(label: _startDate != null ? _displayDateFormat.format(_startDate!) : 'من تاريخ', isActive: _startDate != null, onTap: () => _pickDate(isStart: true))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: _EliteColors.goldPrimary)),
              Expanded(child: _buildDateChip(label: _endDate != null ? _displayDateFormat.format(_endDate!) : 'إلى تاريخ', isActive: _endDate != null, onTap: () => _pickDate(isStart: false))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _applyFilter,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_EliteColors.goldPrimary, Color(0xFFB8952C)]), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.search, size: 20, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({required String label, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: isActive ? _EliteColors.goldPrimary : _EliteColors.glassBorder), borderRadius: BorderRadius.circular(12), color: isActive ? _EliteColors.goldPrimary.withOpacity(0.08) : _EliteColors.nightBg),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: isActive ? _EliteColors.goldPrimary : Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: GoogleFonts.cairo(fontSize: 12, color: isActive ? _EliteColors.goldPrimary : Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _EliteColors.goldPrimary));

    if (_errorMessage != null) return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade600), const SizedBox(height: 16),
          Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchStatement,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(border: Border.all(color: _EliteColors.goldPrimary), borderRadius: BorderRadius.circular(12)),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: _EliteColors.goldPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (_transactions.isEmpty) return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade600), const SizedBox(height: 16),
        Text('لا توجد حركات مالية', style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 16)),
      ]),
    );

    return RefreshIndicator(
      onRefresh: _onRefresh, color: _EliteColors.goldPrimary, backgroundColor: _EliteColors.cardBg,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _EliteColors.goldPrimary)));
          }
          return _buildTransactionCard(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final bool isCredit = tx.isCredit;
    final Color amountColor = isCredit ? _EliteColors.success : _EliteColors.danger;

    return InkWell(
      onTap: () => _showReceipt(tx),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _EliteColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _EliteColors.glassBorder)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: amountColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: amountColor.withOpacity(0.2))),
              child: Icon(
                tx.txCategory == 'deposit' ? Icons.arrow_downward_rounded : tx.txCategory == 'withdrawal' ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded,
                color: amountColor, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.categoryLabel, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(
                    '${tx.shortTxId}  •  ${DateFormat('yyyy/MM/dd - HH:mm').format(tx.createdAt)}',
                    style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${isCredit ? '+' : '-'} ${tx.amount.toStringAsFixed(2)}', style: GoogleFonts.cairo(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('USDT', style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
