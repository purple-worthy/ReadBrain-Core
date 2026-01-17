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
}
