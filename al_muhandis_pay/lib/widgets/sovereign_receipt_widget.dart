import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class SovereignReceipt extends StatefulWidget {
  final Map<String, dynamic> txData;
  const SovereignReceipt({super.key, required this.txData});

  @override
  State<SovereignReceipt> createState() => _SovereignReceiptState();
}

class _SovereignReceiptState extends State<SovereignReceipt> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;
  bool _isSharing = false;

  // 💾 بروتوكول الحفظ في المعرض
  Future<void> _captureAndSave() async {
    setState(() => _isSaving = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        await Gal.putImageBytes(imageBytes);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ الوثيقة الرسمية في المعرض 🦅", style: TextStyle(fontFamily: 'Cairo'))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل في حفظ الوثيقة", style: TextStyle(fontFamily: 'Cairo'))));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 📤 بروتوكول المشاركة الفورية (Share Intent)
  Future<void> _captureAndShare() async {
    setState(() => _isSharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        // إنشاء ملف مؤقت لمشاركته
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/Al_Muhandis_Receipt_${widget.txData['transaction_id']}.png').create();
        await imagePath.writeAsBytes(imageBytes);

        // إطلاق نافذة المشاركة (واتساب، تيليجرام، إلخ)
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'إيصال حوالة رسمية من تطبيق المهندس Pay 🦅\nرقم العملية: ${widget.txData['transaction_id']}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل في مشاركة الوثيقة", style: TextStyle(fontFamily: 'Cairo'))));
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Screenshot(
          controller: _screenshotController,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFd4af37).withOpacity(0.5), width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFFd4af37), size: 50),
                const SizedBox(height: 10),
                const Text("إيصال تحويل رسمي", style: TextStyle(fontFamily: 'Cairo', fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                const Text("AL-MUHANDIS PAY SECURED", style: TextStyle(fontSize: 10, color: Color(0xFFd4af37), letterSpacing: 2)),
                const Divider(color: Colors.white24, height: 30),
                _buildInfoRow("رقم العملية", widget.txData['transaction_id']?.toString() ?? '5124483B'),
                _buildInfoRow("المستفيد", widget.txData['receiver'] ?? 'BARAA ZOUROB'),
                _buildInfoRow("المبلغ", "${widget.txData['amount']} USDT", isRed: true),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Receipt Hash (HMAC Signature):", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(widget.txData['hash'] ?? 'e80ec8b96021c664e61e00fb446329e0', style: const TextStyle(fontSize: 10, color: Color(0xFFd4af37), fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        // 🎛️ لوحة التحكم المزدوجة (حفظ + مشاركة)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _captureAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  side: const BorderSide(color: Color(0xFFd4af37)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download, color: Color(0xFFd4af37)),
                label: const Text("حفظ", style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _captureAndShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd4af37),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSharing ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.share, color: Colors.black),
                label: const Text("مشاركة", style: TextStyle(fontFamily: 'Cairo', color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(fontFamily: 'Cairo', color: isRed ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
