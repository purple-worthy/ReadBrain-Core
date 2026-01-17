import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 系统信息组件
class SystemInfoWidget extends StatelessWidget {
  const SystemInfoWidget({super.key});

  /// 格式化字节数为可读格式
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 计算目录大小
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      // 忽略错误
    }
    return totalSize;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSystemInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final info = snapshot.data!;
        final cacheSize = info['cacheSize'] as int;
        final bookCount = info['bookCount'] as int;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '系统信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('缓存文件夹大小', _formatBytes(cacheSize)),
                const SizedBox(height: 8),
                _buildInfoRow('已导入书籍总数', '$bookCount 本'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _loadSystemInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      final coversDir = Directory('${appDir.path}/covers');

      int totalSize = 0;
      totalSize += await _calculateDirectorySize(booksDir);
      totalSize += await _calculateDirectorySize(coversDir);

      return {
        'cacheSize': totalSize,
        'bookCount': await _countBooks(booksDir),
      };
    } catch (e) {
      return {
        'cacheSize': 0,
        'bookCount': 0,
      };
    }
  }

  Future<int> _countBooks(Directory dir) async {
    try {
      if (!await dir.exists()) return 0;
      return await dir.list().length;
    } catch (e) {
      return 0;
    }
  }
}
