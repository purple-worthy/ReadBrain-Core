import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SystemInfoWidget extends StatelessWidget {
  const SystemInfoWidget({super.key});

  /// 字节转可读格式 (B, KB, MB, GB)
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (Math.log(bytes) / Math.log(1024)).floor();
    return '${(bytes / Math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// 递归计算文件夹大小
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
    } catch (_) {}
    return totalSize;
  }

  /// 统计书籍数量
  Future<int> _countBooks(Directory dir) async {
    try {
      if (!await dir.exists()) return 0;
      // 过滤掉非 PDF 文件
      final list = await dir.list().toList();
      return list.where((e) => e.path.endsWith('.pdf')).length;
    } catch (_) {
      return 0;
    }
  }

  /// 聚合加载信息
  Future<Map<String, dynamic>> _loadSystemInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      // 注意：这里的 'books' 和 'covers' 必须和你 ServiceLocator 里的配置一致
      final booksDir = Directory('${appDir.path}/books');
      final coversDir = Directory('${appDir.path}/covers');

      final size = await _calculateDirectorySize(booksDir) + 
                   await _calculateDirectorySize(coversDir);
      final count = await _countBooks(booksDir);

      return {
        'cacheSize': size,
        'bookCount': count,
        'version': 'v1.0.0+1', // 这里可以后续接入 package_info_plus 插件
      };
    } catch (e) {
      return {'cacheSize': 0, 'bookCount': 0, 'version': 'Unknown'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSystemInfo(),
      builder: (context, snapshot) {
        // 加载时显示的占位状态
        final bool isLoading = !snapshot.hasData;
        final info = snapshot.data;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(FontAwesomeIcons.circleInfo, size: 18, color: Color(0xFF2C3E50)),
                    SizedBox(width: 10),
                    Text(
                      '存储状态',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  label: '已导入书籍',
                  value: isLoading ? '计算中...' : '${info!['bookCount']} 本',
                  icon: FontAwesomeIcons.book,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: '占用空间',
                  value: isLoading ? '计算中...' : _formatBytes(info!['cacheSize']),
                  icon: FontAwesomeIcons.database,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: '应用版本',
                  value: isLoading ? '...' : info!['version'],
                  icon: FontAwesomeIcons.codeBranch,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

// 简单的数学库兼容，如果没引入 dart:math 请加这一行：
class Math { static double log(num x) => double.parse(x.toString()); static num pow(num x, num y) => 0; } 
// 注意：实际项目中建议在文件顶部 import 'dart:math' as math; 并使用 math.log