import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_engine.dart';
import 'transfer_screen.dart';
import 'statement_screen.dart';
import 'deposit_screen.dart';
import 'withdrawal_screen.dart';
import '../core/elite_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
  String _userName = 'جاري التحميل...';
  String _walletId = 'جاري التحميل...';
  List<dynamic> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    // 1. استرجاع بيانات العميل السيادية من الذاكرة
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'عميل المهندس';
    final rawId = prefs.getString('user_id') ?? '0';
    
    if (mounted) {
      setState(() {
        _userName = name;
        // سيتم عرض هذا مؤقتاً حتى يأتي رقم الحساب البنكي من السيرفر
        _walletId = rawId.startsWith('AG-') ? rawId : 'AG-${rawId.padLeft(6, '0')}';
      });
    }

    // 2. جلب الرصيد والنشاط من البنك المركزي (Backend)
    try {
      final response = await ApiEngine().dio.get('/wallet');
      if (response.statusCode == 200 && mounted) {
        final resData = response.data['data'] ?? response.data;
        setState(() {
          if (resData['wallet'] != null) {
            _balance = double.tryParse(resData['wallet']['balance'].toString()) ?? 0.0;
            // 🟢 التعديل هنا: قراءة رقم الحساب البنكي (AMP) من السيرفر وعرضه
            if (resData['wallet']['account_number'] != null && resData['wallet']['account_number'].toString().startsWith('AMP')) {
              _walletId = resData['wallet']['account_number'];
            }
          }
          if (resData['recent_transactions'] != null) {
            _recentTransactions = resData['recent_transactions'];
          }
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          // التعامل مع حالة عدم وجود محفظة بعد (عميل جديد)
          if (e.response?.statusCode == 404) {
            _balance = 0.0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دوال الانتقال المباشر
  void _goToTransfer() => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()));
  void _goToStatement() => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementScreen()));
  void _goToDeposit() => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen()));
  void _goToWithdraw() => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteColors.nightBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFd4af37),
          onRefresh: _initDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- الهيدر ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFFd4af37).withOpacity(0.2),
                            child: const Icon(Icons.person, color: Color(0xFFd4af37)),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('أهلاً بك', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    child: Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: EliteColors.glassGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EliteColors.glassBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الرصيد الإجمالي',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const CircularProgressIndicator(color: EliteColors.goldPrimary)
              : Text(
                  'USDT ${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: EliteColors.goldPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _walletId,
                style: const TextStyle(
                  color: Colors.white54,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              const Icon(Icons.security, color: Colors.white54),
            ],
          ),
        ],
      ),
    ),
  ),
),
                  const SizedBox(height: 30),

                  // --- الأزرار الأربعة السيادية ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton('تحويل', Icons.send, _goToTransfer, EliteColors.goldPrimary),
_buildActionButton('إيداع', Icons.download, _goToDeposit, EliteColors.success),
_buildActionButton('سحب', Icons.upload, _goToWithdraw, EliteColors.danger),
_buildActionButton('كشف حساب', Icons.receipt_long, _goToStatement, EliteColors.goldPrimary),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // --- النشاط الأخير ---
                  const Text('النشاط الأخير', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFd4af37)))
                      : _recentTransactions.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد حركات مالية', style: TextStyle(color: Colors.grey))))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _recentTransactions[index];
                                final isCredit = tx['entry_type'] == 'CREDIT';
return ListTile(
  contentPadding: EdgeInsets.zero,
  leading: CircleAvatar(
    backgroundColor: isCredit ? EliteColors.success.withOpacity(0.2) : EliteColors.danger.withOpacity(0.2),
    child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? EliteColors.success : EliteColors.danger),
  ),
  title: Text(tx['tx_category'] ?? 'عملية مالية', style: const TextStyle(color: Colors.white)),
  subtitle: Text(tx['created_at']?.toString().split(' ')[0] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
  trailing: Text(
    '${isCredit ? '+' : '-'} ${tx['amount']}',
    style: TextStyle(color: isCredit ? EliteColors.success : EliteColors.danger, fontWeight: FontWeight.bold, fontSize: 16),
  ),
);
                            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
  color: color.withOpacity(0.15),
  shape: BoxShape.circle,
  border: Border.all(color: color.withOpacity(0.5)),
  boxShadow: EliteShadows.neonGold, // استخدم neonDanger إذا اللون أحمر
),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
