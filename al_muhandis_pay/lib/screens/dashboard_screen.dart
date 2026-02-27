import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_engine.dart';
import 'transfer_screen.dart';
import 'statement_screen.dart';
import 'deposit_screen.dart';
import 'withdrawal_screen.dart';

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
          } else {
            // خطأ آخر
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
      backgroundColor: const Color(0xFF00101D),
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

                  // --- البطاقة الزجاجية (الخزنة) ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الرصيد الإجمالي', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 10),
                            _isLoading 
                              ? const CircularProgressIndicator(color: Color(0xFFd4af37))
                              : Text('USDT ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFd4af37), fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_walletId, style: const TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2)),
                                const Icon(Icons.credit_card, color: Colors.white54),
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
                      _buildActionButton('تحويل', Icons.send, _goToTransfer, Colors.blue),
                      _buildActionButton('إيداع', Icons.download, _goToDeposit, Colors.green),
                      _buildActionButton('سحب', Icons.upload, _goToWithdraw, Colors.orange),
                      _buildActionButton('كشف حساب', Icons.receipt_long, _goToStatement, Colors.purple),
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
                                    backgroundColor: isCredit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                                  ),
                                  title: Text(tx['tx_category'] ?? 'عملية مالية', style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(tx['created_at']?.toString().split(' ')[0] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  trailing: Text('${isCredit ? '+' : '-'} ${tx['amount']}', style: TextStyle(color: isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                );
                              },
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
