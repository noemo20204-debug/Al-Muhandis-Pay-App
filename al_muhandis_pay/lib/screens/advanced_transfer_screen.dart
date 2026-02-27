import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart'; 
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import '../widgets/sovereign_receipt_widget.dart'; // 👈 استيراد المحرك الذي زرعناه

class AdvancedTransferScreen extends StatefulWidget {
  const AdvancedTransferScreen({super.key});

  @override
  _AdvancedTransferScreenState createState() => _AdvancedTransferScreenState();
}

class _AdvancedTransferScreenState extends State<AdvancedTransferScreen> {
  final _amountController = TextEditingController();
  final _receiverController = TextEditingController();
  bool _isProcessing = false;

  String _generateSecureSignature(Map<String, dynamic> data, String timestamp) {
    var key = utf8.encode("AL_MUHANDIS_CORE_VAULT_KEY_2026_X9"); 
    var bytes = utf8.encode(jsonEncode(data) + timestamp);
    var hmacSha256 = Hmac(sha256, key); 
    return hmacSha256.convert(bytes).toString();
  }

  // 🛡️ محرك عرض الإيصال السيادي (الذي طلبته)
  void _showSovereignReceipt(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF00101D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SovereignReceipt(txData: data), 
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd4af37),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text("العودة للرئيسية", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processSovereignTransfer() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool isAuthorized = await auth.authenticate(
      localizedReason: 'تأكيد الهوية السيادية مطلوب لتنفيذ الحوالة',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (!isAuthorized) return;
    setState(() => _isProcessing = true);

    try {
      final String ts = DateTime.now().millisecondsSinceEpoch.toString();
      final Map<String, dynamic> txData = {
        'receiver_id': _receiverController.text,
        'amount': double.parse(_amountController.text),
        'description': 'حوالة سيادية مؤمنة',
      };

      final String sig = _generateSecureSignature(txData, ts);

      final response = await http.post(
        Uri.parse('https://al-muhandis.com/api/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'X-Hmac-Signature': sig,
          'X-Timestamp': ts,
        },
        body: jsonEncode(txData),
      );

      final resultData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 🚀 استدعاء محرك العرض اللحظي فور النجاح
        _showSovereignReceipt(resultData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultData['message'] ?? "فشلت العملية")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل في الاتصال بالسيرفر")));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00101D),
      appBar: AppBar(title: const Text("تحويل سيادي", style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _receiverController, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'), decoration: const InputDecoration(hintText: "رقم المستلم", hintStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 20),
            TextField(controller: _amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'), decoration: const InputDecoration(hintText: "المبلغ", hintStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFd4af37), minimumSize: const Size(double.infinity, 55)),
              onPressed: _isProcessing ? null : _processSovereignTransfer,
              child: _isProcessing ? const CircularProgressIndicator(color: Colors.black) : const Text("تأكيد الحوالة الآن", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }
}
