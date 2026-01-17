import 'dart:io';
import 'package:flutter/material.dart';

/// 书籍封面卡片组件
/// 如果封面不存在，显示渐变色卡片
class BookCoverCard extends StatelessWidget {
  final String bookName;
  final String? coverPath;
  final VoidCallback? onTap;

  const BookCoverCard({
    super.key,
    required this.bookName,
    this.coverPath,
    this.onTap,
  });

  /// 生成渐变色
  List<Color> _generateGradientColors(String name) {
    // 根据书名生成稳定的渐变色
    final hash = name.hashCode;
    final colors = [
      [
        const Color(0xFF667EEA),
        const Color(0xFF764BA2),
      ],
      [
        const Color(0xFFF093FB),
        const Color(0xFFF5576C),
      ],
      [
        const Color(0xFF4FACFE),
        const Color(0xFF00F2FE),
      ],
      [
        const Color(0xFF43E97B),
        const Color(0xFF38F9D7),
      ],
      [
        const Color(0xFFFA709A),
        const Color(0xFFFEE140),
      ],
      [
        const Color(0xFF30CFD0),
        const Color(0xFF330867),
      ],
      [
        const Color(0xFFA8EDEA),
        const Color(0xFFFED6E3),
      ],
      [
        const Color(0xFFD299C2),
        const Color(0xFFFEF9D7),
      ],
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildCover(),
        ),
      ),
    );
  }

  Widget _buildCover() {
    // 如果有封面路径且文件存在，显示封面
    if (coverPath != null) {
      final file = File(coverPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildGradientCard();
          },
        );
      }
    }

    // 否则显示渐变色卡片
    return _buildGradientCard();
  }

  Widget _buildGradientCard() {
    final colors = _generateGradientColors(bookName);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.book,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                bookName,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
