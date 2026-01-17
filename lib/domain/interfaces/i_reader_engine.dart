import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 阅读引擎接口（Domain 层核心抽象）
/// 定义书籍渲染和解析的抽象操作，便于后续切换不同的解析引擎
abstract class IReaderEngine {
  /// 初始化引擎
  Future<void> initialize();

  /// 解析书籍文件
  /// [filePath] 文件路径
  /// 返回解析后的书籍内容
  Future<BookContent> parseBook(String filePath);

  /// 渲染书籍内容
  /// [content] 书籍内容
  /// 返回渲染后的 Widget
  Widget renderContent(BookContent content);

  /// 获取书籍元数据
  /// [filePath] 文件路径
  /// 返回书籍元数据
  Future<BookMetadata> getMetadata(String filePath);

  /// 预加载指定范围的页面
  /// [filePath] 文件路径
  /// [start] 起始页码（从 0 开始）
  /// [count] 要预加载的页面数量
  /// 返回预加载是否成功
  Future<bool> preloadPages(String filePath, int start, int count);

  /// 获取书籍封面
  /// [filePath] 文件路径
  /// 返回封面数据（字节数组），如果不存在则返回 null
  Future<Uint8List?> getCover(String filePath);
}

/// 书籍内容数据模型
class BookContent {
  final String bookName;
  final List<String> pages;
  final Map<String, dynamic>? extraData;

  BookContent({
    required this.bookName,
    required this.pages,
    this.extraData,
  });
}

/// 书籍元数据
class BookMetadata {
  final String title;
  final String? author;
  final int? pageCount;
  final DateTime? publishDate;
  final Map<String, dynamic>? extraData;

  BookMetadata({
    required this.title,
    this.author,
    this.pageCount,
    this.publishDate,
    this.extraData,
  });
}
