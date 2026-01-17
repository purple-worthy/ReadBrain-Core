import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async'; // 必须导入这个，解决 Completer 报错
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path/path.dart' as p;
import '../../domain/interfaces/i_reader_engine.dart';

class PdfReaderEngine implements IReaderEngine {
  final Map<String, PdfDocument> _documentCache = {};

  @override
  Future<void> initialize() async {}

  Future<PdfDocument?> _getOrOpenDocument(String filePath) async {
    try {
      if (_documentCache.containsKey(filePath)) {
        return _documentCache[filePath];
      }
      final document = await PdfDocument.openFile(filePath);
      _documentCache[filePath] = document;
      return document;
    } catch (e) {
      debugPrint('PDF 引擎错误: $e');
      return null;
    }
  }

  @override
  Future<BookContent> parseBook(String filePath) async {
    final doc = await _getOrOpenDocument(filePath);
    final totalPages = doc?.pages.length ?? 0;

    return BookContent(
      bookName: p.basename(filePath),
      pages: List.generate(totalPages, (i) => '第 ${i + 1} 页'),
      extraData: {
        'pageCount': totalPages,
        'filePath': filePath,
      },
    );
  }

  @override
  Widget renderContent(BookContent content) {
    final filePath = content.extraData?['filePath'] as String?;
    if (filePath == null) return const Center(child: Text('路径无效'));

    return PdfViewer.file(filePath);
  }

  @override
  Future<BookMetadata> getMetadata(String filePath) async {
    final doc = await _getOrOpenDocument(filePath);
    return BookMetadata(
      title: p.basename(filePath),
      pageCount: doc?.pages.length ?? 0,
    );
  }

  @override
  Future<bool> preloadPages(String filePath, int start, int count) async {
    final doc = await _getOrOpenDocument(filePath);
    if (doc == null) return false;
    try {
      final end = (start + count).clamp(0, doc.pages.length);
      for (int i = start; i < end; i++) {
        final _ = doc.pages[i]; 
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List?> getCover(String filePath) async {
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(filePath);
      if (doc == null || doc.pages.isEmpty) return null;

      final page = doc.pages[0];
      
      // 2.1.0 的 render 返回 PdfImage?，需要加 await 并处理 null
      final pdfImage = await page.render(
        width: 300, 
        height: 400,
      );

      // 【核心修复】空安全检查
      if (pdfImage == null) return null;

      final completer = Completer<ui.Image>();
      
      // 使用 ! 强转，因为我们已经在上面检查过 pdfImage != null
      ui.decodeImageFromPixels(
        pdfImage.pixels, 
        pdfImage.width, 
        pdfImage.height, 
        ui.PixelFormat.rgba8888,
        (ui.Image image) {
          completer.complete(image);
        },
      );

      final uiImage = await completer.future;
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      
      uiImage.dispose();
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('封面合成失败: $e');
      return null;
    } finally {
      // 这里的 dispose 非常重要，防止文件被锁定
      await doc?.dispose();
    }
  }

  void dispose() {
    for (var doc in _documentCache.values) {
      doc.dispose();
    }
    _documentCache.clear();
  }
}