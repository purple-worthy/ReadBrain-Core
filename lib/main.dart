import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 核心层与领域层导入
import 'core/service_locator.dart';
import 'domain/interfaces/i_book_service.dart';
import 'domain/interfaces/i_config_service.dart';

// UI 组件导入
import 'presentation/widgets/error_snackbar.dart';
import 'presentation/widgets/loading_overlay.dart';
import 'presentation/widgets/book_cover_card.dart';
import 'presentation/widgets/pdf_viewer_widget.dart';
import 'presentation/widgets/system_info_widget.dart';

/// 应用入口点
void main() async {
  // 1. 确保引擎初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. 窗口管理初始化
  await windowManager.ensureInitialized();
  
  // 3. 配置窗口属性（新增：增加最小尺寸限制，防止 UI 崩溃）
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(1000, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: "ReadBrain 阅读器",
  );
  
  // 4. 初始化组装中心（含 IStorageService, IReaderEngine 等）
  await ServiceLocator.setup();
  
  // 5. 业务逻辑初始化：预加载书籍列表（产品顾问：提升首屏体验）
  await ServiceLocator.get<IBookService>().initialize();

  // 6. 显示窗口
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const ReadBrainApp());
}

class ReadBrainApp extends StatelessWidget {
  const ReadBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadBrain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ),
        // 优化全局卡片外观
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// --- 以下是精简后且功能完整的 UI 逻辑 ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedNavIndex = 0;
  
  final List<NavItem> _navItems = [
    NavItem(title: '书籍库', icon: FontAwesomeIcons.book),
    NavItem(title: '导入', icon: FontAwesomeIcons.plusCircle),
    NavItem(title: '目录', icon: FontAwesomeIcons.list),
    NavItem(title: '设置', icon: FontAwesomeIcons.gear),
  ];

  IBookService get _bookService => ServiceLocator.get<IBookService>();

  @override
  void initState() {
    super.initState();
    // 监听书籍服务变化，自动刷新 UI
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).addListener(_onBookServiceChanged);
    }
  }

  @override
  void dispose() {
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).removeListener(_onBookServiceChanged);
    }
    super.dispose();
  }

  void _onBookServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationBar(),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(child: _buildContentArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      width: 220, // 稍微加宽一点，更显大气
      color: const Color(0xFF2C3E50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: const Text('ReadBrain', 
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;
                return ListTile(
                  leading: Icon(item.icon, color: isSelected ? Colors.white : Colors.white70, size: 18),
                  title: Text(item.title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14)),
                  selected: isSelected,
                  selectedTileColor: Colors.white.withOpacity(0.1),
                  onTap: () => setState(() {
                    _selectedNavIndex = index;
                    _bookService.switchToBook(-1); 
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final openBooks = _bookService.getOpenBooks();
    final currentIndex = _bookService.getCurrentIndex();
    
    if (openBooks.isEmpty) {
      return Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.grey[50], border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
        child: const Center(child: Text('暂无打开的书籍', style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }

    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.grey[50], border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openBooks.length,
        itemBuilder: (context, index) {
          final bookName = openBooks[index];
          final isActive = index == currentIndex;
          return GestureDetector(
            onTap: () => _bookService.switchToBook(index),
            child: Container(
              margin: const EdgeInsets.only(left: 6, top: 6, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: isActive ? Border.all(color: Colors.grey[300]!) : null,
              ),
              child: Row(
                children: [
                  Text(bookName, style: TextStyle(color: isActive ? Colors.blue[700] : Colors.grey[600], fontSize: 13)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _bookService.closeBook(index),
                    child: Icon(FontAwesomeIcons.xmark, size: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentArea() {
    final currentBook = _bookService.getCurrentBook();
    if (currentBook != null) {
      return PdfViewerWidget(bookName: currentBook, filePath: _bookService.getBookFilePath(currentBook)!);
    }
    
    switch (_selectedNavIndex) {
      case 0: return const BookLibraryPage();
      case 1: return const ImportPage();
      case 2: return const CatalogPage();
      case 3: return const SettingsPage();
      default: return const Center(child: Text('页面未找到'));
    }
  }
}

class NavItem {
  final String title;
  final IconData icon;
  NavItem({required this.title, required this.icon});
}

// --- 各个子页面实现 ---

class BookLibraryPage extends StatelessWidget {
  const BookLibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final bookService = ServiceLocator.get<IBookService>();
    final books = bookService.getAllBooks();
    
    if (books.isEmpty) return const Center(child: Text('书架空空如也，去导入一本吧！'));

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, childAspectRatio: 0.7, crossAxisSpacing: 24, mainAxisSpacing: 24),
      itemCount: books.length,
      itemBuilder: (context, index) => BookCoverCard(
        bookName: books[index],
        onTap: () => bookService.openBook(books[index]),
      ),
    );
  }
}

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});
  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FontAwesomeIcons.fileArrowUp, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.plus),
              label: const Text('选择本地 PDF 导入'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null && result.files.single.path != null) {
                  setState(() => _loading = true);
                  await ServiceLocator.get<IBookService>().importBook(result.files.single.path!);
                  if (mounted) {
                    setState(() => _loading = false);
                    ErrorSnackbar.showSuccess(context, '导入成功！');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('目录/书签（开发中）'));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configService = ServiceLocator.get<IConfigService>();
    final bookService = ServiceLocator.get<IBookService>();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('系统设置', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // 自动恢复
            ValueListenableBuilder<bool>(
              valueListenable: configService.autoRestoreState,
              builder: (context, autoRestore, _) => Card(
                child: SwitchListTile(
                  title: const Text('自动恢复上次阅读'),
                  value: autoRestore,
                  onChanged: (v) => configService.setAutoRestore(v),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const SystemInfoWidget(),
            
            const SizedBox(height: 32),
            const Text('数据管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const Divider(),
            
            ListTile(
              title: const Text('清除所有书籍数据'),
              subtitle: const Text('此操作不可撤销'),
              trailing: TextButton(
                onPressed: () => _confirmClear(context, bookService),
                child: const Text('清除', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, IBookService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.clearAllData();
              Navigator.pop(ctx);
              ErrorSnackbar.showSuccess(context, '数据已清空');
            }, 
            child: const Text('确定清除', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}


/* import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'core/service_locator.dart';
import 'domain/interfaces/i_book_service.dart';
import 'domain/interfaces/i_config_service.dart';
import 'presentation/widgets/error_snackbar.dart';
import 'presentation/widgets/loading_overlay.dart';
import 'presentation/widgets/book_cover_card.dart';
import 'presentation/widgets/pdf_viewer_widget.dart';
import 'presentation/widgets/system_info_widget.dart'; // 确保导入了系统信息组件

/// 应用入口点
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  
  // 配置窗口属性
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // 初始化服务定位器
  await ServiceLocator.setup();
  
  runApp(const ReadBrainApp());
}

class ReadBrainApp extends StatelessWidget {
  const ReadBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadBrain 阅读器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedNavIndex = 0;
  
  final List<NavItem> _navItems = [
    NavItem(title: '书籍库', icon: FontAwesomeIcons.book),
    NavItem(title: '导入', icon: FontAwesomeIcons.plusCircle),
    NavItem(title: '目录', icon: FontAwesomeIcons.list),
    NavItem(title: '设置', icon: FontAwesomeIcons.gear),
  ];

  IBookService get _bookService => ServiceLocator.get<IBookService>();

  @override
  void initState() {
    super.initState();
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).addListener(_onBookServiceChanged);
    }
  }

  @override
  void dispose() {
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).removeListener(_onBookServiceChanged);
    }
    super.dispose();
  }

  void _onBookServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationBar(),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: _buildContentArea(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'ReadBrain',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;
                return ListTile(
                  leading: Icon(item.icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
                  title: Text(item.title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14)),
                  selected: isSelected,
                  onTap: () => setState(() {
                    _selectedNavIndex = index;
                    _bookService.switchToBook(-1); // 切换回功能页时清除当前打开书籍状态
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final openBooks = _bookService.getOpenBooks();
    final currentIndex = _bookService.getCurrentIndex();
    
    if (openBooks.isEmpty) {
      return Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.grey[100], border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
        child: const Center(child: Text('暂无打开的书籍', style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.grey[100],
       border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openBooks.length,
        itemBuilder: (context, index) {
          final bookName = openBooks[index];
          final isActive = index == currentIndex;
          return GestureDetector(
            onTap: () => _bookService.switchToBook(index),
            child: Container(
              margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? Colors.blue[300]! : Colors.transparent),
              ),
              child: Row(
                children: [
                  Text(bookName, style: TextStyle(color: isActive ? Colors.blue[700] : Colors.grey[700], fontSize: 13)),
                  const SizedBox(width: 8),
                  GestureDetector(
  		    onTap: () => _bookService.closeBook(index),
                    // 使用 MouseRegion 或在外面包一层 Padding，增加点击热区
  		    child: Padding(
    		      padding: const EdgeInsets.all(4.0), // 增加 4 像素的热区，方便鼠标点击
                      child: Icon(
                        FontAwesomeIcons.xmark, 
                        size: 14, // 稍微调大一点点，14 比较适中
                        color: Colors.grey[600],
                      ),
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

  Widget _buildContentArea() {
    final currentBook = _bookService.getCurrentBook();
    if (currentBook != null) return PdfViewerWidget(bookName: currentBook, filePath: _bookService.getBookFilePath(currentBook)!);
    
    switch (_selectedNavIndex) {
      case 0: return const BookLibraryPage();
      case 1: return const ImportPage();
      case 2: return const CatalogPage();
      case 3: return const SettingsPage();
      default: return const Center(child: Text('页面错误'));
    }
  }
}

class NavItem {
  final String title;
  final IconData icon;
  NavItem({required this.title, required this.icon});
}

// 书籍库
class BookLibraryPage extends StatelessWidget {
  const BookLibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final bookService = ServiceLocator.get<IBookService>();
    final books = bookService.getAllBooks();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.7, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemCount: books.length,
      itemBuilder: (context, index) => BookCoverCard(
        bookName: books[index],
        onTap: () => bookService.openBook(books[index]),
      ),
    );
  }
}

// 导入页
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});
  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
            if (result != null) {
              setState(() => _loading = true);
              await ServiceLocator.get<IBookService>().importBook(result.files.single.path!);
              if (mounted) setState(() => _loading = false);
            }
          },
          child: const Text('选择 PDF 导入'),
        ),
      ),
    );
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('目录（开发中）'));
}

// --- 重点：整合了你刚才补充的剩余代码后的设置页面 ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configService = ServiceLocator.get<IConfigService>();
    final bookService = ServiceLocator.get<IBookService>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView( // 增加滚动防止溢出
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(FontAwesomeIcons.gear, size: 28),
                SizedBox(width: 12),
                Text('设置', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            
            // 自动恢复开关
            ValueListenableBuilder<bool>(
              valueListenable: configService.autoRestoreState,
              builder: (context, autoRestore, child) => Card(
                child: SwitchListTile(
                  title: const Text('启动时自动恢复状态'),
                  subtitle: const Text('应用启动时自动恢复上次打开的书籍'),
                  value: autoRestore,
                  onChanged: (value) => configService.setAutoRestore(value),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 字体大小调节
            FutureBuilder<double>(
              future: configService.getFontSize(),
              builder: (context, snapshot) {
                final fontSize = snapshot.data ?? 16.0;
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(FontAwesomeIcons.font),
                        title: const Text('字体大小'),
                        subtitle: Text('当前：${fontSize.toInt()}px'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Slider(
                          value: fontSize,
                          min: 12, max: 32,
                          divisions: 20,
                          label: '${fontSize.toInt()}px',
                          onChanged: (value) => configService.setFontSize(value),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const SystemInfoWidget(), // 系统信息
            const SizedBox(height: 16),

            // 清除封面缓存按钮
            Card(
              child: ListTile(
                leading: const Icon(FontAwesomeIcons.trash),
                title: const Text('清除封面缓存'),
                subtitle: const Text('清除所有书籍的封面缓存'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      final allBooks = bookService.getAllBooks();
                      int successCount = 0;
                      for (final book in allBooks) {
                        final success = await bookService.clearCoverCache(book);
                        if (success) successCount++;
                      }
                      if (context.mounted) {
                        ErrorSnackbar.showSuccess(context, '已清除 $successCount 个封面缓存');
                      }
                    } catch (e) {
                      if (context.mounted) ErrorSnackbar.show(context, '清除失败：$e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: const Text('清除'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 危险操作：清除所有数据
            Card(
              child: ListTile(
                leading: const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red),
                title: const Text('清除所有数据'),
                subtitle: const Text('清除所有书籍数据和设置'),
                trailing: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认清除'),
                        content: const Text('确定要清除所有书籍数据吗？此操作不可恢复。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                          TextButton(
                            onPressed: () {
                              bookService.clearAllData();
                              Navigator.pop(context);
                              ErrorSnackbar.showSuccess(context, '已清除所有数据');
                            },
                            child: const Text('确定', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('清除'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} */