import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_engine.dart';
import '../core/elite_theme.dart';
import '../core/elite_alerts.dart'; 
import 'login_screen.dart'; // 🟢 التوجيه للشاشة الأساسية الأصلية
import 'security_devices_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String walletId;
  final String? avatarUrl;

  const ProfileScreen({super.key, required this.userName, required this.walletId, this.avatarUrl});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  String? _currentAvatar;

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.avatarUrl;
  }

  Future<void> _contactSupport() async {
    final Uri url = Uri.parse('https://wa.me/970592283824?text=${Uri.encodeComponent("مرحباً قيادة المهندس، أواجه مشكلة تقنية في حسابي البنكي وأحتاج لتدخل الدعم الفني المباشر.")}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) EliteAlerts.show(context, title: 'خطأ في النظام', message: 'لم نتمكن من فتح تطبيق الواتساب.', isSuccess: false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      FormData formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(image.path, filename: "avatar.jpg"),
      });

      final response = await ApiEngine().dio.post('user/avatar', data: formData);
      if (response.statusCode == 200) {
        setState(() => _currentAvatar = response.data['data']['avatar_url']);
        EliteAlerts.show(context, title: 'عملية ناجحة', message: 'تم تحديث صورتك الشخصية في النظام المركزي.', isSuccess: true);
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? 'الخادم لا يستجيب للطلب.';
      EliteAlerts.show(context, title: 'فشل الاتصال', message: errorMsg, isSuccess: false);
    } catch (e) {
      EliteAlerts.show(context, title: 'خطأ داخلي', message: 'حدث خطأ أثناء معالجة الصورة.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _startPasswordChangeFlow() async {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final g2faCtrl = TextEditingController();

    bool? proceed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EliteColors.surface,
        title: const Text('تغيير كلمة المرور', style: TextStyle(color: EliteColors.goldPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', labelStyle: TextStyle(color: Colors.white54))),
            const SizedBox(height: 10),
            TextField(controller: newPassCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', labelStyle: TextStyle(color: Colors.white54))),
            const SizedBox(height: 10),
            TextField(controller: confirmPassCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EliteColors.goldPrimary),
            onPressed: () {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                EliteAlerts.show(context, title: 'تنبيه أمني', message: 'كلمة المرور الجديدة غير متطابقة!', isSuccess: false);
                return;
              }
              if (newPassCtrl.text.length < 8) {
                EliteAlerts.show(context, title: 'تنبيه أمني', message: 'يجب أن تكون كلمة المرور 8 أحرف على الأقل.', isSuccess: false);
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('متابعة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (proceed != true || oldPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) return;

    final LocalAuthentication auth = LocalAuthentication();
    bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (canAuthenticate) {
      bool authenticated = await auth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك الحيوية للمتابعة',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (!authenticated) return;
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: EliteColors.goldPrimary)));
      final resInit = await ApiEngine().dio.post('user/password/init', data: {
        'old_password': oldPassCtrl.text,
        'new_password': newPassCtrl.text,
      });
      Navigator.pop(context);

      String tempTicket = resInit.data['data']['ticket'];

      bool? finalProceed = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: EliteColors.surface,
          title: const Text('المصادقة الثنائية', style: TextStyle(color: EliteColors.goldPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تم إرسال كود التحقق لبريدك الإلكتروني.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 15),
              TextField(controller: otpCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'رمز البريد الإلكتروني (OTP)')),
              const SizedBox(height: 10),
              TextField(controller: g2faCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'رمز تطبيق Authenticator')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EliteColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد التغيير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (finalProceed != true) return;

      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: EliteColors.goldPrimary)));
      await ApiEngine().dio.post('user/password/confirm', data: {
        'ticket': tempTicket,
        'email_otp': otpCtrl.text,
        'google_code': g2faCtrl.text,
      });
      Navigator.pop(context);

      EliteAlerts.show(context, title: 'أمان الحساب', message: 'تم تغيير كلمة المرور بنجاح! يرجى تسجيل الدخول مجدداً.', isSuccess: true);
      
      // 🟢 التوجه للشاشة الأساسية الرسمية
      final prefs = await SharedPreferences.getInstance(); await prefs.clear();
      const storage = FlutterSecureStorage(); await storage.deleteAll();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);

    } on DioException catch (e) {
      Navigator.pop(context); 
      EliteAlerts.show(context, title: 'رفض العملية', message: e.response?.data['message'] ?? 'فشل الإجراء، يرجى المحاولة لاحقاً', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: EliteColors.goldPrimary, width: 2), boxShadow: EliteShadows.neonGold),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: EliteColors.surface,
                    backgroundImage: _currentAvatar != null ? NetworkImage(_currentAvatar!) : null,
                    child: _currentAvatar == null ? const Icon(Icons.person, color: EliteColors.goldPrimary, size: 50) : null,
                  ),
                ),
                if (_isUploading) const Positioned.fill(child: CircularProgressIndicator(color: EliteColors.goldPrimary)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: EliteColors.goldPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(widget.walletId, style: const TextStyle(color: EliteColors.goldPrimary, fontSize: 14, letterSpacing: 2)),
          const SizedBox(height: 40),

          _buildSettingsTile(Icons.lock_outline, 'تغيير كلمة المرور', 'حماية بيومترية ومصادقة ثنائية', onTap: _startPasswordChangeFlow),
          _buildSettingsTile(Icons.security, 'إعدادات الأمان', 'إدارة الأجهزة المتصلة بالحساب', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityDevicesScreen()));
          }),
          _buildSettingsTile(Icons.support_agent, 'التواصل مع الدعم الفني', 'المساعدة والمحادثة المباشرة', onTap: _contactSupport),
          
          const SizedBox(height: 30),
          _buildSettingsTile(Icons.exit_to_app, 'تسجيل الخروج', 'إنهاء الجلسة الحالية', isDanger: true, onTap: () async {
            final prefs = await SharedPreferences.getInstance(); await prefs.clear();
            const storage = FlutterSecureStorage(); await storage.deleteAll();
            // 🟢 التوجه للشاشة الأساسية الرسمية
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {bool isDanger = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: EliteColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDanger ? EliteColors.danger.withOpacity(0.1) : EliteColors.goldPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: isDanger ? EliteColors.danger : EliteColors.goldPrimary)),
        title: Text(title, style: TextStyle(color: isDanger ? EliteColors.danger : Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
      ),
    );
  }
}