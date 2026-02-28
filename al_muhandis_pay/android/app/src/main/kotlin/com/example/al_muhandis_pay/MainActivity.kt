package com.example.al_muhandis_pay // تأكد أن هذا السطر يطابق اسم الـ package الخاص بك، وإلا اتركه كما هو في ملفك الأصلي.

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle

class MainActivity: FlutterFragmentActivity() {
        override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
                    GeneratedPluginRegistrant.registerWith(flutterEngine)
        }

            override fun onCreate(savedInstanceState: Bundle?) {
                        super.onCreate(savedInstanceState)
                                
                                        // 🟢 تم إيقاف حماية التقاط الشاشة مؤقتاً لأغراض التطوير
                                                // window.setFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE, android.view.WindowManager.LayoutParams.FLAG_SECURE)
            }
}
            }
        }
}