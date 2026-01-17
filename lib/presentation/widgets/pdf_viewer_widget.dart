import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/service_locator.dart';
import '../../domain/interfaces/i_book_service.dart';

class PdfViewerWidget extends StatefulWidget {
  final String bookName;
  final String filePath;
  
  //构造函数
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
  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // 用于控制侧边栏

  int _currentPage = 1;
  int _totalPages = 0;
  double _currentZoom = 1.0;
  Timer? _savePageTimer;
  bool _showControls = true;

  // 目录数据：使用 dynamic 避免 2.1.0 版本类名不匹配导致的爆红
  List<dynamic>? _outlines;

  @override
  void initState() {
    super.initState();
    _bookService = ServiceLocator.get<IBookService>();
    _loadLastReadPage();

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _currentZoom = _controller.currentZoom;
        });
      }
    });
  }

  @override
  void dispose() {
    _savePageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastReadPage() async {
    try {
      final lastPage = await _bookService.getLastReadPage(widget.bookName);
      if (lastPage != null && mounted) {
        setState(() => _currentPage = lastPage);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _controller.goToPage(pageNumber: _currentPage);
        });
      }
    } catch (e) {
      debugPrint('加载进度失败: $e');
    }
  }

  void _scheduleSavePage(int pageNumber) {
    _savePageTimer?.cancel();
    _savePageTimer = Timer(const Duration(seconds: 2), () {
      _bookService.saveLastReadPage(widget.bookName, pageNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // 绑定 Key
      backgroundColor: const Color(0xFFF0F0F2),
      // --- 添加侧边栏 Drawer ---
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: PdfViewer.file(
              widget.filePath,
              controller: _controller,
              params: PdfViewerParams(
                maxScale: 5.0,
                minScale: 1.0,
                margin: 16.0,
                backgroundColor: const Color(0xFFF0F0F2),
                onPageChanged: (page) {
                  if (page != null && mounted) {
                    setState(() => _currentPage = page);
                    _scheduleSavePage(page);
                  }
                },
                onViewerReady: (document, controller) async {
                  setState(() {
                    _totalPages = document.pages.length;
                  });
                  // 加载目录
                  final outline = await document.loadOutline();
                  if (mounted) {
                    setState(() {
                      _outlines = outline;
                    });
                  }
                },
              ),
            ),
          ),

          // 顶部工具栏
          if (_showControls)
            Positioned(top: 20, left: 20, right: 20, child: _buildTopToolbar()),

          // 底部翻页栏
          if (_showControls)
            Positioned(bottom: 30, left: 0, right: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  // 构建目录侧边栏
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2C3E50)),
            child: Center(
              child: Text(
                '书籍目录',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _outlines == null || _outlines!.isEmpty
                ? const Center(child: Text('暂无目录信息'))
                : ListView.builder(
                    itemCount: _outlines!.length,
                    itemBuilder: (context, index) {
                      final node = _outlines![index];
                      // 这里的 node 强转为 PdfOutlineNode
                      return _buildOutlineItem(node as PdfOutlineNode, 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 递归构建目录项
  Widget _buildOutlineItem(PdfOutlineNode node, int depth) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: 16.0 + (depth * 16.0),
            right: 16,
          ),
          title: Text(
            node.title,
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          onTap: () {
            if (node.dest?.pageNumber != null) {
              _controller.goToPage(pageNumber: node.dest!.pageNumber);
              Navigator.pop(context); // 关闭侧边栏
            }
          },
        ),
        if (node.children.isNotEmpty)
          ...node.children
              .map((child) => _buildOutlineItem(child, depth + 1))
              .toList(),
      ],
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          // --- 新增：菜单按钮用于打开目录 ---
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF2C3E50)),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const VerticalDivider(width: 10, indent: 15, endIndent: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              widget.bookName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () =>
                _controller.setZoom(Offset.zero, _controller.currentZoom / 1.2),
          ),
          Text(
            "${(_currentZoom * 100).toInt()}%",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                _controller.setZoom(Offset.zero, _controller.currentZoom * 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50).withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _currentPage > 1
                  ? () => _controller.goToPage(pageNumber: _currentPage - 1)
                  : null,
            ),
            Text(
              '$_currentPage / $_totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _currentPage < _totalPages
                  ? () => _controller.goToPage(pageNumber: _currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
