import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/interfaces/i_book_service.dart';
import '../../core/service_locator.dart';
import '../widgets/pdf_viewer_widget.dart'; // 确保路径指向你之前的 PDF 渲染组件

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final IBookService _bookService;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  // 获取当前正在显示的 PDF Widget 的引用
  final GlobalKey<_PdfViewerWidgetState> _pdfKey = GlobalKey(); // 用于通过 Key 找到子组件方法

  @override
  void initState() {
    super.initState();
    // 从服务定位器获取书籍服务实例
    _bookService = ServiceLocator.get<IBookService>();
  }

  /// 供外部调用的点击书籍方法
  /// 比如在书架页面点击某本书时调用：ReaderScreen.of(context).onBookTap(name);
  void onBookTap(String bookName) {
    setState(() {
      bool success = _bookService.openBook(bookName);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('最多只能同时打开 ${_bookService.getMaxTabs()} 本书')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final openBooks = _bookService.getOpenBooks();
    final currentBook = _bookService.getCurrentBook();
    final currentIndex = _bookService.getCurrentIndex();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS 系统级灰色背景
      body: SafeArea(
        child: Column(
          children: [
            //添加全文搜索框
            _buildTabHeader(openBooks, currentIndex),
            // 新增：搜索工具条
            if (_isSearching) _buildSearchBar(), 
            Expanded(
              child: currentBook != null
                  ? PdfViewerWidget(
                      // 修改点：添加 key 方便我们调用它的搜索方法
                      key: ValueKey(currentBook), 
                      bookName: currentBook,
                      filePath: _bookService.getBookFilePath(currentBook)!,
                    )
                  : _buildEmptyState(),
            ),
            // 1. 顶部页签栏
            if (openBooks.isNotEmpty) _buildTabHeader(openBooks, currentIndex),
            
            // 2. 主体阅读区
            Expanded(
              child: currentBook != null
                  ? PdfViewerWidget(
                      // 使用 ValueKey 是核心：当 currentBook 改变时，PdfViewerWidget 会被销毁并重新初始化
                      key: ValueKey(currentBook), 
                      bookName: currentBook,
                      filePath: _bookService.getBookFilePath(currentBook)!,
                    )
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建页签头部
  Widget _buildTabHeader(List<String> openBooks, int currentIndex) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E5EA),
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openBooks.length,
        itemBuilder: (context, index) {
          final bool isActive = index == currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _bookService.switchToBook(index)),
            child: Container(
              margin: const EdgeInsets.only(top: 6, left: 4, right: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.filePdf,
                    size: 12,
                    color: isActive ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    openBooks[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.black : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 关闭页签按钮
                  GestureDetector(
                    onTap: () => setState(() => _bookService.closeBook(index)),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? Colors.black54 : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 无书籍时的占位界面
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            '尚未打开任何书籍',
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            '从书架中选择一本开始阅读吧',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Colors.white,
    child: Row(
      children: [
        const Icon(Icons.search, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '搜索文档内容...',
              border: InputBorder.none,
            ),
            onSubmitted: (value) {
              // 这里我们需要一种方式调用子组件的 searchText
              // 建议使用通知模式或通过 Service 传递，简单做法是给子组件加 static 引用
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
          },
        ),
      ],
    ),
  );
}
}