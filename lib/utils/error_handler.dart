import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothErrorHandler {
  static String getReadableError(dynamic error) {
    if (error is PlatformException) {
      if (error.code == 'connect_error' || 
          error.code == 'connection_failed' ||
          error.message?.contains('read failed') == true) {
        return 'فشل الاتصال. تأكد من تشغيل الجهاز وعمل الاقتران (Pair) من إعدادات الهاتف.';
      }
      if (error.message?.contains('Bluetooth is not available') == true) {
        return 'البلوتوث غير متوفر أو معطل في هذا الجهاز.';
      }
      if (error.message?.contains('Permission denied') == true) {
        return 'إذن البلوتوث مطلوب لكي يعمل التطبيق بشكل صحيح.';
      }
      return 'خطأ تقني: ${error.message ?? error.code}';
    }
    if (error.toString().contains('no device found')) {
      return 'لم يتم العثور على أجهزة بلوتوث قريبة.';
    }
    return 'خطأ غير متوقع: ${error.toString()}';
  }

  static void showGlassySnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isError ? Colors.redAccent.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isError ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: isError ? Colors.redAccent : Colors.cyanAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
