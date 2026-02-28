import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/elite_theme.dart';
import '../core/elite_alerts.dart';

class SecurityDevicesScreen extends StatelessWidget {
  const SecurityDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteColors.nightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إعدادات الأمان للأجهزة', style: TextStyle(color: EliteColors.goldPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: EliteBackgroundPainter())),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الجهاز الحالي', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildDeviceCard(
                  context,
                  deviceName: 'Samsung Galaxy S24 Ultra',
                  location: 'Palestine, Gaza (IP: 192.168.1.1)',
                  lastActive: 'متصل الآن',
                  icon: Icons.smartphone,
                  isCurrent: true,
                ),
                const SizedBox(height: 30),
                const Text('الأجهزة المتصلة مسبقاً', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildDeviceCard(
                  context,
                  deviceName: 'Chrome Browser (Windows)',
                  location: 'Unknown Location (IP: 45.33.22.1)',
                  lastActive: 'نشط قبل ساعتين',
                  icon: Icons.laptop_mac,
                  isCurrent: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, {required String deviceName, required String location, required String lastActive, required IconData icon, required bool isCurrent}) {
    return Container(
      decoration: BoxDecoration(
        color: EliteColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCurrent ? EliteColors.success.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isCurrent ? EliteColors.success.withOpacity(0.1) : Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(icon, color: isCurrent ? EliteColors.success : Colors.white70, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(lastActive, style: TextStyle(color: isCurrent ? EliteColors.success : EliteColors.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          if (!isCurrent) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Colors.white12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EliteColors.danger.withOpacity(0.1),
                  foregroundColor: EliteColors.danger,
                  elevation: 0,
                  side: const BorderSide(color: EliteColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.block),
                label: const Text('إلغاء اتصال هذا الجهاز', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  EliteAlerts.show(context, title: 'إجراء أمني', message: 'تم إرسال أمر فصل الجهاز للسيرفر بنجاح.', isSuccess: true);
                },
              ),
            )
          ]
        ],
      ),
    );
  }
}