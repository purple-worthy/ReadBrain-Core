import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/service_locator.dart';
import '../../domain/interfaces/i_book_service.dart';

class PdfViewerWidget extends StatefulWidget {
  final String bookName;
  final String filePath;

  // 构造函数：移除 const 以支持内部变量初始化
  PdfViewerWidget({super.key, required this.bookName, required this.filePath});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late final IBookService _bookService;
  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 搜索控制器
  final PdfTextSearcher _searcher = PdfTextSearcher();

  int _currentPage = 1;
  int _totalPages = 0;
  double _currentZoom = 1.0;
  Timer? _savePageTimer;
  bool _showControls = true;
  bool _isSearching = false; 

  final TextEditingController _searchTextController = TextEditingController();
  List<dynamic>? _outlines;

  @override
  void initState() {
    super.initState();
    _bookService = ServiceLocator.get<IBookService>();
    _controller.addListener(() {
      if (mounted) {
        setState(() => _currentZoom = _controller.currentZoom);
      }
    });
    // 初始化时加载上次阅读进度
    _loadLastReadPage();
  }

  // 搜索逻辑
  void _onSearch(String text) {
    if (text.isEmpty) {
      _searcher.startTextSearch(""); // 清空搜索内容
    } else {
      _searcher.startTextSearch(text);
    }
  }

  @override
  void dispose() {
    _savePageTimer?.cancel();
    _searchTextController.dispose();
    _searcher.dispose(); // 销毁搜索器
    super.dispose();
  }

  Future<void> _loadLastReadPage() async {
    try {
      final lastPage = await _bookService.getLastReadPage(widget.bookName);
      if (lastPage != null && mounted) {
        setState(() => _currentPage = lastPage);
        // 延迟跳转确保文档已加载
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _controller.goToPage(pageNumber: _currentPage);
        });
      }
    } catch (e) {
      debugPrint('进度加载失败: $e');
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F0F2),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // PDF 阅读核心区
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: PdfViewer.file(
              widget.filePath,
              controller: _controller,
              params: PdfViewerParams(
                // 关键点：绑定搜索器
                //textSearcher: _searcher, 
                margin: 16.0,
                backgroundColor: const Color(0xFFF0F0F2),
                onPageChanged: (page) {
                  if (page != null && mounted) {
                    setState(() => _currentPage = page);
                    _scheduleSavePage(page);
                  }
                },
                onViewerReady: (document, controller) async {
                  setState(() => _totalPages = document.pages.length);
                  final outline = await document.loadOutline();
                  if (mounted) setState(() => _outlines = outline);
                },
              ),
            ),
          ),

          // 顶部工具栏
          if (_showControls)
            Positioned(
              top: 20, left: 20, right: 20,
              child: Column(
                children: [
                  _buildTopToolbar(),
                  if (_isSearching) _buildSearchBar(), 
                ],
              ),
            ),

          // 底部翻页栏
          if (_showControls)
            Positioned(bottom: 30, left: 0, right: 0, child: _buildBottomNav()),
        ],
      ),
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
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Text(
              widget.bookName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.search_off : Icons.search),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
          // 显示当前缩放比例，消除 _currentZoom 标黄
          Text("${(_currentZoom * 100).toInt()}%", style: const TextStyle(fontSize: 10)),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => _controller.setZoom(Offset.zero, _controller.currentZoom / 1.2),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _controller.setZoom(Offset.zero, _controller.currentZoom * 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: TextField(
        controller: _searchTextController,
        onSubmitted: _onSearch,
        decoration: InputDecoration(
          hintText: "输入关键字搜索...",
          border: InputBorder.none,
          // 搜索导航按钮
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: () => _searcher.goToPrevMatch(),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () => _searcher.goToNextMatch(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(child: Center(child: Text('书籍目录'))),
          Expanded(
            child: _outlines == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _outlines!.length,
                    itemBuilder: (context, index) => _buildOutlineItem(
                      _outlines![index] as PdfOutlineNode,
                      0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineItem(PdfOutlineNode node, int depth) {
    return ListTile(
      title: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: Text(node.title, style: const TextStyle(fontSize: 14)),
      ),
      onTap: () {
        if (node.dest?.pageNumber != null) {
          _controller.goToPage(pageNumber: node.dest!.pageNumber);
          Navigator.pop(context);
        }
      },
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
              onPressed: _currentPage > 1 ? () => _controller.goToPage(pageNumber: _currentPage - 1) : null,
            ),
            Text('$_currentPage / $_totalPages', style: const TextStyle(color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _currentPage < _totalPages ? () => _controller.goToPage(pageNumber: _currentPage + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}