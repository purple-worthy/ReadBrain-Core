import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../core/service_locator.dart';
import '../../domain/interfaces/i_book_service.dart';

/// PDF 查看器组件
/// 支持缩放、翻页、页码记录等功能
class PdfViewerWidget extends StatefulWidget {
  final String bookName;
  final String filePath;

  const PdfViewerWidget({
    super.key,
    required this.bookName,
    required this.filePath,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late final IBookService _bookService;
  PdfViewerController? _controller;
  int _currentPage = 0;
  int _totalPages = 0;
  Timer? _preloadTimer;
  Timer? _savePageTimer;

  @override
  void initState() {
    super.initState();
    _bookService = ServiceLocator.get<IBookService>();
    _loadLastReadPage();
    // 延迟初始化控制器监听
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupControllerListener();
    });
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    _savePageTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// 设置控制器监听
  void _setupControllerListener() {
    // pdfrx 会自动处理页面变化
    // 这里可以添加额外的监听逻辑
  }

  /// 加载最后阅读页码
  Future<void> _loadLastReadPage() async {
    try {
      final lastPage = await _bookService.getLastReadPage(widget.bookName);
      if (lastPage != null && mounted) {
        setState(() {
          _currentPage = lastPage;
        });
      }
    } catch (e) {
      debugPrint('加载最后阅读页码失败: $e');
    }
  }

  /// 保存当前页码（延迟保存，避免频繁写入）
  void _scheduleSavePage(int pageNumber) {
    _savePageTimer?.cancel();
    _savePageTimer = Timer(const Duration(seconds: 1), () {
      _bookService.saveLastReadPage(widget.bookName, pageNumber);
    });
  }

  /// 触发预加载（当用户停留在某页超过 1 秒时）
  void _schedulePreload(int currentPage) {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(seconds: 1), () {
      _triggerPreload(currentPage);
    });
  }

  /// 触发预加载逻辑
  Future<void> _triggerPreload(int currentPage) async {
    try {
      final readerEngine = ServiceLocator.get<IReaderEngine>();
      // 预加载当前页+1 到当前页+3
      await readerEngine.preloadPages(
        widget.filePath,
        currentPage + 1,
        3,
      );
    } catch (e) {
      debugPrint('预加载失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        _buildToolbar(),
        // PDF 查看器
        Expanded(
          child: PdfViewer.file(
            widget.filePath,
            controller: _controller = PdfViewerController(
              params: PdfViewerParams(
                initialPageNumber: _currentPage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 上一页按钮
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentPage > 0
                ? () {
                    _controller?.goToPageNumber(_currentPage - 1);
                  }
                : null,
          ),
          // 页码显示
          FutureBuilder<int>(
            future: _controller?.pageCount ?? Future.value(0),
            builder: (context, snapshot) {
              final totalPages = snapshot.data ?? _totalPages;
              return Text(
                '${_currentPage + 1} / ${totalPages}',
                style: const TextStyle(fontSize: 14),
              );
            },
          ),
          // 下一页按钮
          FutureBuilder<int>(
            future: _controller?.pageCount ?? Future.value(0),
            builder: (context, snapshot) {
              final totalPages = snapshot.data ?? _totalPages;
              return IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        _controller?.goToPageNumber(_currentPage + 1);
                      }
                    : null,
              );
            },
          ),
          const Spacer(),
          // 缩放控制
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _controller?.zoomOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _controller?.zoomIn();
            },
          ),
        ],
      ),
    );
  }
}
