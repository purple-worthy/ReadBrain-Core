import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/interfaces/i_reader_engine.dart';

/// 模拟阅读引擎实现（Data 层）
/// 当前阶段使用模拟实现，后续可以替换为真实的 PDF 解析引擎或大模型解析引擎
class MockReaderEngine implements IReaderEngine {
  @override
  Future<void> initialize() async {
    // 模拟引擎初始化，实际实现中可以加载必要的资源
  }

  @override
  Future<BookContent> parseBook(String filePath) async {
    // 模拟解析书籍，返回模拟内容
    return BookContent(
      bookName: filePath.split('/').last,
      pages: [
        '这是 $filePath 的第一页内容。',
        '这是 $filePath 的第二页内容。',
        '这是 $filePath 的第三页内容。',
      ],
    );
  }

  @override
  Widget renderContent(BookContent content) {
    // 模拟渲染内容
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.bookName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content.pages.map((page) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      page,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<BookMetadata> getMetadata(String filePath) async {
    // 模拟获取元数据
    return BookMetadata(
      title: filePath.split('/').last,
      author: '模拟作者',
      pageCount: 3,
      publishDate: DateTime.now(),
    );
  }

  @override
  Future<bool> preloadPages(String filePath, int start, int count) async {
    // 模拟预加载页面
    // 实际实现中，这里可以提前解析和缓存指定范围的页面
    try {
      // 模拟异步操作
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List?> getCover(String filePath) async {
    // 模拟获取封面
    // 实际实现中，这里应该从文件中提取封面图片
    // 当前返回 null 表示没有封面
    return null;
  }
}
