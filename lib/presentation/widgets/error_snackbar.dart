import 'package:flutter/material.dart';

/// 统一反馈通知组件 - 综合优化版
class ErrorSnackbar {
  /// 显示错误提示 (红色)
  static void show(BuildContext context, String message, {Duration? duration}) {
    _display(context, message, Icons.error_outline, Colors.red[700]!, duration ?? const Duration(seconds: 3));
  }

  /// 显示成功提示 (绿色)
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    _display(context, message, Icons.check_circle_outline, Colors.green[700]!, duration ?? const Duration(seconds: 2));
  }

  /// 显示信息提示 (蓝色)
  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    _display(context, message, Icons.info_outline, Colors.blue[700]!, duration ?? const Duration(seconds: 2));
  }

  /// 内部统一显示逻辑
  static void _display(
    BuildContext context,
    String message,
    IconData icon,
    Color bgColor,
    Duration duration,
  ) {
    // 在显示新的 SnackBar 之前先清除旧的，避免堆积
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20), // 悬浮位置微调
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}