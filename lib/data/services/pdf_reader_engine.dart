import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../domain/interfaces/i_reader_engine.dart';

/// PDF 阅读引擎实现（Data 层）
/// 基于 pdfrx 的真实 PDF 解析和渲染引擎
class PdfReaderEngine implements IReaderEngine {
  // PDF 文档缓存（文件路径 -> PdfDocument）
  final Map<String, PdfDocument> _documentCache = {};
  
  // 页面渲染缓存（文件路径_页码 -> ui.Image）
  final Map<String, ui.Image> _pageImageCache = {};

  @override
  Future<void> initialize() async {
    // 初始化引擎，清理过期缓存等
  }

  /// 获取或加载 PDF 文档
  Future<PdfDocument?> _getDocument(String filePath) async {
    try {
      if (_documentCache.containsKey(filePath)) {
        return _documentCache[filePath];
      }

      final document = await PdfDocument.openFile(filePath);
      _documentCache[filePath] = document;
      return document;
    } catch (e) {
      debugPrint('加载 PDF 文档失败: $e');
      return null;
    }
  }

  @override
  Future<BookContent> parseBook(String filePath) async {
    try {
      final document = await _getDocument(filePath);
      if (document == null) {
        throw Exception('无法加载 PDF 文档');
      }

      final pageCount = document.pagesCount;
      final pages = <String>[];
      
      // 解析每一页（简化版本，实际可以根据需要提取文本）
      for (int i = 0; i < pageCount; i++) {
        pages.add('第 ${i + 1} 页');
      }

      return BookContent(
        bookName: filePath.split('/').last,
        pages: pages,
        extraData: {
          'pageCount': pageCount,
          'filePath': filePath,
        },
      );
    } catch (e) {
      debugPrint('解析 PDF 失败: $e');
      rethrow;
    }
  }

  @override
  Widget renderContent(BookContent content) {
    final filePath = content.extraData?['filePath'] as String?;
    if (filePath == null) {
      return const Center(child: Text('无效的书籍路径'));
    }

    return PdfViewer.file(
      filePath,
      params: PdfViewerParams(
        enableKeyboard: true,
        enablePointerNavigation: true,
      ),
    );
  }

  /// 创建支持缩放和翻页的 PDF 查看器
  Widget buildPdfViewer(String filePath, {
    required int currentPage,
    required Function(int) onPageChanged,
    double scale = 1.0,
    Function(double)? onScaleChanged,
  }) {
    return PdfViewer.file(
      filePath,
      params: PdfViewerParams(
        pageNumber: currentPage,
        enableKeyboard: true,
        enablePointerNavigation: true,
        onPageChanged: (page) {
          onPageChanged(page);
        },
      ),
    );
  }

  @override
  Future<BookMetadata> getMetadata(String filePath) async {
    try {
      final document = await _getDocument(filePath);
      if (document == null) {
        throw Exception('无法加载 PDF 文档');
      }

      return BookMetadata(
        title: filePath.split('/').last,
        pageCount: document.pagesCount,
        extraData: {
          'filePath': filePath,
        },
      );
    } catch (e) {
      debugPrint('获取元数据失败: $e');
      return BookMetadata(
        title: filePath.split('/').last,
      );
    }
  }

  @override
  Future<bool> preloadPages(String filePath, int start, int count) async {
    try {
      final document = await _getDocument(filePath);
      if (document == null) {
        return false;
      }

      final totalPages = document.pagesCount;
      final end = (start + count).clamp(0, totalPages);
      
      // 异步预加载页面到内存缓存
      final futures = <Future>[];
      for (int i = start; i < end; i++) {
        final cacheKey = '${filePath}_$i';
        if (_pageImageCache.containsKey(cacheKey)) {
          continue; // 已缓存，跳过
        }

        // 异步预加载页面（pdfrx 会自动处理缓存）
        futures.add(_preloadPageToCache(document, i, cacheKey));
      }

      // 等待所有预加载完成
      await Future.wait(futures);
      return true;
    } catch (e) {
      debugPrint('预加载页面失败: $e');
      return false;
    }
  }

  /// 预加载单页到缓存
  Future<void> _preloadPageToCache(
    PdfDocument document,
    int pageIndex,
    String cacheKey,
  ) async {
    try {
      // pdfrx 会自动处理页面缓存
      // 这里触发页面预加载（通过获取页面对象）
      final page = await document.getPage(pageIndex);
      if (page != null) {
        // 页面已预加载到 pdfrx 的内部缓存
        // 这里可以额外实现位图预渲染逻辑
      }
    } catch (e) {
      debugPrint('预加载单页失败: $e');
    }
  }

  @override
  Future<Uint8List?> getCover(String filePath) async {
    try {
      final document = await _getDocument(filePath);
      if (document == null) {
        return null;
      }

      // 获取第一页作为封面
      final page = await document.getPage(0);
      if (page == null) {
        return null;
      }

      // 这里可以渲染第一页为图片
      // pdfrx 可能需要额外处理
      // 暂时返回 null，使用默认封面
      return null;
    } catch (e) {
      debugPrint('获取封面失败: $e');
      return null;
    }
  }

  /// 清理缓存
  void clearCache() {
    _documentCache.clear();
    // 清理页面图片缓存
    _pageImageCache.forEach((key, image) {
      image.dispose();
    });
    _pageImageCache.clear();
  }
}
