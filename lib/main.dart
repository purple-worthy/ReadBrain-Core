import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用入口点
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  
  // 配置窗口属性：大小 1200x800，居中显示
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
  
  // 初始化 BookManager 单例
  await BookManager.instance.initialize();
  
  runApp(const ReadBrainApp());
}

/// 主应用 Widget
class ReadBrainApp extends StatelessWidget {
  const ReadBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadBrain 阅读器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主界面：包含左侧导航栏、顶部标签页、中间内容区
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 当前选中的导航项索引
  int _selectedNavIndex = 0;
  
  // 导航项列表
  final List<NavItem> _navItems = [
    NavItem(title: '书籍库', icon: Icons.library_books),
    NavItem(title: '导入', icon: Icons.add_circle_outline),
    NavItem(title: '目录', icon: Icons.menu_book),
    NavItem(title: '设置', icon: Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    // 监听 BookManager 的状态变化，以便更新 UI
    BookManager.instance.addListener(_onBookManagerChanged);
  }

  @override
  void dispose() {
    // 移除监听器
    BookManager.instance.removeListener(_onBookManagerChanged);
    super.dispose();
  }

  /// BookManager 状态变化回调
  void _onBookManagerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏（200px 宽度）
          _buildNavigationBar(),
          // 右侧主内容区
          Expanded(
            child: Column(
              children: [
                // 顶部标签页区域
                _buildTabBar(),
                // 中间内容展示区
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

  /// 构建左侧导航栏
  Widget _buildNavigationBar() {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        children: [
          // 导航项列表
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;
                
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? Colors.blue : Colors.grey[700],
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedNavIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部标签页区域
  Widget _buildTabBar() {
    final openBooks = BookManager.instance.getOpenBooks();
    final currentIndex = BookManager.instance.getCurrentIndex();
    
    if (openBooks.isEmpty) {
      return Container(
        height: 50,
        color: Colors.grey[100],
        child: const Center(
          child: Text(
            '暂无打开的书籍',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      color: Colors.grey[100],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openBooks.length,
        itemBuilder: (context, index) {
          final bookName = openBooks[index];
          final isActive = index == currentIndex;
          
          return GestureDetector(
            onTap: () {
              // 切换标签页
              BookManager.instance.switchToBook(index);
            },
            child: Container(
              margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.grey[300],
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 书名
                  Text(
                    bookName,
                    style: TextStyle(
                      color: isActive ? Colors.blue : Colors.grey[700],
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 关闭按钮（X）
                  GestureDetector(
                    onTap: () {
                      // 关闭标签页
                      BookManager.instance.closeBook(index);
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isActive ? Colors.blue : Colors.grey[600],
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

  /// 构建中间内容展示区
  Widget _buildContentArea() {
    final currentBook = BookManager.instance.getCurrentBook();
    
    // 如果有打开的书籍，优先显示书籍内容
    if (currentBook != null) {
      return BookContentView(bookName: currentBook);
    }
    
    // 如果没有打开的书籍，根据选中的导航项显示不同内容
    switch (_selectedNavIndex) {
      case 0:
        return const BookLibraryPage();
      case 1:
        return const ImportPage();
      case 2:
        return const CatalogPage();
      case 3:
        return const SettingsPage();
      default:
        return const Center(child: Text('未知页面'));
    }
  }
}

/// 导航项数据模型
class NavItem {
  final String title;
  final IconData icon;

  NavItem({required this.title, required this.icon});
}

/// 书籍库页面
class BookLibraryPage extends StatelessWidget {
  const BookLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final allBooks = BookManager.instance.getAllBooks();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '书籍库',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: allBooks.isEmpty
                ? const Center(
                    child: Text(
                      '暂无书籍，请点击"导入"添加书籍',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: allBooks.length,
                    itemBuilder: (context, index) {
                      final bookName = allBooks[index];
                      return ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(bookName),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // 打开书籍
                            final success = BookManager.instance.openBook(bookName);
                            if (!success) {
                              // 页签已达上限，显示提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('页签数量已达上限（${BookManager.maxTabs} 个），请先关闭部分标签页'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: const Text('打开'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 导入页面
class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '导入书籍',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // 模拟导入：随机生成一个书名
                final random = Random();
                final bookNumber = random.nextInt(1000);
                final bookName = '测试书籍$bookNumber.pdf';
                
                // 添加到书籍库
                BookManager.instance.addBook(bookName);
                
                // 自动打开书籍
                final success = BookManager.instance.openBook(bookName);
                
                // 显示提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? '已导入并打开：$bookName'
                        : '已导入：$bookName，但页签数量已达上限（${BookManager.maxTabs} 个），请先关闭部分标签页'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('模拟导入书籍'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '说明：当前为模拟导入功能，点击按钮会随机生成一个测试书名并添加到书籍库。',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// 目录页面
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentBook = BookManager.instance.getCurrentBook();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '目录',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (currentBook == null)
            const Center(
              child: Text(
                '请先打开一本书籍',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('第一章：开始'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('第二章：发展'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('第三章：高潮'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('第四章：结局'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 书籍内容显示页面
class BookContentView extends StatelessWidget {
  final String bookName;
  
  const BookContentView({super.key, required this.bookName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 书籍标题
          Text(
            bookName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          // 模拟书籍内容
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildParagraph('这是 $bookName 的内容展示区域。'),
                  _buildParagraph('当前为模拟内容，实际阅读功能将在后续阶段实现。'),
                  _buildParagraph('您可以在这里看到书籍的文本内容、图片等内容。'),
                  _buildParagraph('点击不同的标签页可以切换查看不同的书籍。'),
                  _buildParagraph('每个标签页都会显示对应书籍的内容。'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建段落文本
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.8,
        ),
      ),
    );
  }
}

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          // 启动时自动恢复状态开关
          ValueListenableBuilder<bool>(
            valueListenable: BookManager.instance.autoRestoreNotifier,
            builder: (context, autoRestore, child) {
              return SwitchListTile(
                title: const Text('启动时自动恢复状态'),
                subtitle: const Text('应用启动时自动恢复上次打开的书籍和标签页'),
                value: autoRestore,
                onChanged: (value) {
                  BookManager.instance.setAutoRestore(value);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          // 清除所有数据按钮
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清除'),
                  content: const Text('确定要清除所有书籍数据吗？此操作不可恢复。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        BookManager.instance.clearAllData();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已清除所有数据')),
                        );
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清除所有数据'),
          ),
        ],
      ),
    );
  }
}

/// BookManager 单例类 - 管理书籍和标签页状态（Clean Architecture 核心逻辑层）
class BookManager extends ChangeNotifier {
  // 单例实例
  static final BookManager _instance = BookManager._internal();
  
  /// 获取单例实例
  static BookManager get instance => _instance;
  
  // 私有构造函数
  BookManager._internal();

  // 页签上限常量
  static const int maxTabs = 10;

  // 所有书籍列表（模拟书籍库）
  final List<String> _allBooks = [];
  
  // 当前打开的书籍列表（标签页）
  final List<String> _openBooks = [];
  
  // 当前选中的标签页索引
  int _currentIndex = -1;
  
  // 自动恢复状态开关
  bool _autoRestore = true;
  
  // SharedPreferences 实例
  SharedPreferences? _prefs;
  
  // 自动恢复状态通知器（用于 UI 绑定）
  final ValueNotifier<bool> autoRestoreNotifier = ValueNotifier<bool>(true);

  /// 初始化 BookManager
  Future<void> initialize() async {
    // 加载 SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // 加载自动恢复设置
    _autoRestore = _prefs?.getBool('auto_restore') ?? true;
    autoRestoreNotifier.value = _autoRestore;
    
    // 如果启用自动恢复，则恢复状态
    if (_autoRestore) {
      await _restoreState();
    }
  }

  /// 恢复应用状态（从 SharedPreferences 加载）
  Future<void> _restoreState() async {
    if (_prefs == null) return;
    
    // 加载打开的书籍列表
    final openBooksJson = _prefs!.getStringList('open_books');
    if (openBooksJson != null && openBooksJson.isNotEmpty) {
      _openBooks.clear();
      _openBooks.addAll(openBooksJson);
      
      // 加载当前选中的索引
      _currentIndex = _prefs!.getInt('current_index') ?? 0;
      
      // 确保索引有效
      if (_currentIndex < 0 || _currentIndex >= _openBooks.length) {
        _currentIndex = _openBooks.isNotEmpty ? 0 : -1;
      }
      
      // 将打开的书籍也添加到书籍库（如果不存在）
      for (final book in _openBooks) {
        if (!_allBooks.contains(book)) {
          _allBooks.add(book);
        }
      }
      
      notifyListeners();
    }
  }

  /// 保存应用状态（到 SharedPreferences）
  Future<void> _saveState() async {
    if (_prefs == null) return;
    
    // 保存打开的书籍列表
    await _prefs!.setStringList('open_books', _openBooks);
    
    // 保存当前选中的索引
    await _prefs!.setInt('current_index', _currentIndex);
    
    // 保存自动恢复设置
    await _prefs!.setBool('auto_restore', _autoRestore);
  }

  /// 添加书籍到书籍库
  void addBook(String bookName) {
    if (!_allBooks.contains(bookName)) {
      _allBooks.add(bookName);
      notifyListeners();
    }
  }

  /// 获取所有书籍列表
  List<String> getAllBooks() {
    return List.unmodifiable(_allBooks);
  }

  /// 打开书籍（添加到标签页）
  /// [bookName] 书籍名称
  /// 返回 true 表示成功，false 表示失败（页签已达上限）
  bool openBook(String bookName) {
    // 检查页签上限
    if (_openBooks.length >= maxTabs) {
      // 返回 false 表示失败，由 UI 层处理提示
      return false;
    }
    
    // 如果书籍不在书籍库中，先添加到书籍库
    if (!_allBooks.contains(bookName)) {
      _allBooks.add(bookName);
    }
    
    // 如果书籍已经打开，则切换到该标签页
    final existingIndex = _openBooks.indexOf(bookName);
    if (existingIndex != -1) {
      _currentIndex = existingIndex;
      notifyListeners();
      _saveState();
      return true;
    }
    
    // 添加新标签页
    _openBooks.add(bookName);
    _currentIndex = _openBooks.length - 1;
    
    notifyListeners();
    _saveState();
    return true;
  }

  /// 关闭书籍（移除标签页）
  /// [index] 要关闭的标签页索引
  void closeBook(int index) {
    if (index < 0 || index >= _openBooks.length) return;
    
    _openBooks.removeAt(index);
    
    // 调整当前索引
    if (_openBooks.isEmpty) {
      _currentIndex = -1;
    } else if (_currentIndex >= _openBooks.length) {
      _currentIndex = _openBooks.length - 1;
    } else if (_currentIndex > index) {
      _currentIndex--;
    }
    
    notifyListeners();
    _saveState();
  }

  /// 切换到指定标签页
  /// [index] 标签页索引
  void switchToBook(int index) {
    if (index >= 0 && index < _openBooks.length) {
      _currentIndex = index;
      notifyListeners();
      _saveState();
    }
  }

  /// 获取当前打开的书籍列表
  List<String> getOpenBooks() {
    return List.unmodifiable(_openBooks);
  }

  /// 获取当前选中的标签页索引
  int getCurrentIndex() {
    return _currentIndex;
  }

  /// 获取当前选中的书籍名称
  String? getCurrentBook() {
    if (_currentIndex >= 0 && _currentIndex < _openBooks.length) {
      return _openBooks[_currentIndex];
    }
    return null;
  }

  /// 设置自动恢复状态
  /// [value] 是否自动恢复
  void setAutoRestore(bool value) {
    _autoRestore = value;
    autoRestoreNotifier.value = value;
    _saveState();
  }

  /// 清除所有数据
  void clearAllData() {
    _allBooks.clear();
    _openBooks.clear();
    _currentIndex = -1;
    notifyListeners();
    _saveState();
  }
}
