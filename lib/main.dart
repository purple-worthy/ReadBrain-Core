import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'core/service_locator.dart';
import 'domain/interfaces/i_book_service.dart';
import 'domain/interfaces/i_config_service.dart';
import 'domain/interfaces/i_reader_engine.dart';
import 'presentation/widgets/error_snackbar.dart';
import 'presentation/widgets/loading_overlay.dart';
import 'presentation/widgets/book_cover_card.dart';
import 'presentation/widgets/book_context_menu.dart';
import 'presentation/widgets/pdf_viewer_widget.dart';
import 'presentation/widgets/system_info_widget.dart';

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
  
  // 初始化服务定位器（依赖注入）
  await ServiceLocator.setup();
  
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

/// 主界面：包含左侧导航栏、顶部标签页、中间内容区
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 当前选中的导航项索引
  int _selectedNavIndex = 0;
  
  // 导航项列表（使用 FontAwesome 图标）
  final List<NavItem> _navItems = [
    NavItem(title: '书籍库', icon: FontAwesomeIcons.book),
    NavItem(title: '导入', icon: FontAwesomeIcons.plusCircle),
    NavItem(title: '目录', icon: FontAwesomeIcons.list),
    NavItem(title: '设置', icon: FontAwesomeIcons.gear),
  ];

  // 获取书籍服务
  IBookService get _bookService => ServiceLocator.get<IBookService>();

  @override
  void initState() {
    super.initState();
    // 监听书籍服务的状态变化
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).addListener(_onBookServiceChanged);
    }
  }

  @override
  void dispose() {
    // 移除监听器
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).removeListener(_onBookServiceChanged);
    }
    super.dispose();
  }

  /// 书籍服务状态变化回调
  void _onBookServiceChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏（200px 宽度，带呼吸灯效果）
          _buildNavigationBar(),
          // 右侧主内容区
          Expanded(
            child: Column(
              children: [
                // 顶部标签页区域（浏览器风格）
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

  /// 构建左侧导航栏（带呼吸灯效果）
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
          // Logo 区域
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
          // 导航项列表
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                return _buildNavItem(_navItems[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航项（带呼吸灯效果）
  Widget _buildNavItem(NavItem item, int index) {
    final isSelected = _selectedNavIndex == index;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() {});
      },
      onExit: (_) {
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: ListTile(
          leading: Icon(
            item.icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 20,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedNavIndex = index;
            });
          },
        ),
      ),
    );
  }

  /// 构建顶部标签页区域（浏览器风格）
  Widget _buildTabBar() {
    final openBooks = _bookService.getOpenBooks();
    final currentIndex = _bookService.getCurrentIndex();
    
    if (openBooks.isEmpty) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openBooks.length,
        itemBuilder: (context, index) {
          final bookName = openBooks[index];
          final isActive = index == currentIndex;
          
          return GestureDetector(
            onTap: () {
              _bookService.switchToBook(index);
            },
            child: Container(
              margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.blue[300]! : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 书名
                  Text(
                    bookName,
                    style: TextStyle(
                      color: isActive ? Colors.blue[700] : Colors.grey[700],
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 关闭按钮（X）
                  GestureDetector(
                    onTap: () {
                      _bookService.closeBook(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        FontAwesomeIcons.xmark,
                        size: 12,
                        color: isActive ? Colors.grey[600] : Colors.grey[500],
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

  /// 构建中间内容展示区
  Widget _buildContentArea() {
    final currentBook = _bookService.getCurrentBook();
    
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

/// 书籍库页面（使用 GridView）
class BookLibraryPage extends StatefulWidget {
  const BookLibraryPage({super.key});

  @override
  State<BookLibraryPage> createState() => _BookLibraryPageState();
}

class _BookLibraryPageState extends State<BookLibraryPage> {
  IBookService get _bookService => ServiceLocator.get<IBookService>();

  @override
  void initState() {
    super.initState();
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    if (_bookService is ChangeNotifier) {
      (_bookService as ChangeNotifier).removeListener(_onChanged);
    }
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  /// 显示重命名对话框
  void _showRenameDialog(BuildContext context, String bookName) {
    final controller = TextEditingController(text: bookName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名书籍'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新书名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现重命名逻辑
              Navigator.of(context).pop();
              ErrorSnackbar.showInfo(context, '重命名功能待实现');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示移除对话框
  void _showRemoveDialog(BuildContext context, String bookName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要从库中移除 "$bookName" 吗？\n文件不会被删除，只是从库中移除记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现移除逻辑（仅从库中移除，不删除文件）
              Navigator.of(context).pop();
              ErrorSnackbar.showInfo(context, '移除功能待实现');
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = _bookService.getAllBooks();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.book, size: 28),
              const SizedBox(width: 12),
              const Text(
                '书籍库',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: allBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.bookOpen,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无书籍，请点击"导入"添加书籍',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // 响应式布局：根据宽度自动调整列数
                      final crossAxisCount = (constraints.maxWidth / 200).floor().clamp(2, 8);
                      
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: allBooks.length,
                        itemBuilder: (context, index) {
                          final bookName = allBooks[index];
                          return FutureBuilder<String?>(
                            future: _bookService.getCoverCachePath(bookName),
                            builder: (context, snapshot) {
                              return GestureDetector(
                                onSecondaryTap: () {
                                  // 右键菜单
                                  showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      constraints.maxWidth / 2,
                                      constraints.maxHeight / 2,
                                      constraints.maxWidth / 2,
                                      constraints.maxHeight / 2,
                                    ),
                                    items: [
                                      PopupMenuItem(
                                        value: 'open',
                                        child: Row(
                                          children: [
                                            const Icon(FontAwesomeIcons.bookOpen, size: 16),
                                            const SizedBox(width: 12),
                                            const Text('打开'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            const Icon(FontAwesomeIcons.pen, size: 16),
                                            const SizedBox(width: 12),
                                            const Text('重命名'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'remove',
                                        child: Row(
                                          children: [
                                            const Icon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                                            const SizedBox(width: 12),
                                            const Text('从库中移除', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ).then((value) {
                                    if (value == 'open') {
                                      final success = _bookService.openBook(bookName);
                                      if (!success) {
                                        ErrorSnackbar.show(
                                          context,
                                          '页签数量已达上限（${_bookService.getMaxTabs()} 个），请先关闭部分标签页',
                                        );
                                      }
                                    } else if (value == 'rename') {
                                      _showRenameDialog(context, bookName);
                                    } else if (value == 'remove') {
                                      _showRemoveDialog(context, bookName);
                                    }
                                  });
                                },
                                child: BookCoverCard(
                                  bookName: bookName,
                                  coverPath: snapshot.data,
                                  onTap: () {
                                    final success = _bookService.openBook(bookName);
                                    if (!success) {
                                      ErrorSnackbar.show(
                                        context,
                                        '页签数量已达上限（${_bookService.getMaxTabs()} 个），请先关闭部分标签页',
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
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
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isLoading = false;
  IBookService get _bookService => ServiceLocator.get<IBookService>();

  Future<void> _importBook() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 使用 file_picker 选择 PDF 文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final filePath = result.files.single.path!;

      // 导入书籍
      final result_either = await _bookService.importBook(filePath);
      
      setState(() {
        _isLoading = false;
      });

      result_either.fold(
        (error) {
          ErrorSnackbar.show(context, error);
        },
        (bookName) {
          ErrorSnackbar.showSuccess(context, '已导入：$bookName');
          
          // 自动打开书籍
          final success = _bookService.openBook(bookName);
          if (!success) {
            ErrorSnackbar.show(
              context,
              '已导入：$bookName，但页签数量已达上限（${_bookService.getMaxTabs()} 个），请先关闭部分标签页',
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorSnackbar.show(context, '导入失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(FontAwesomeIcons.plusCircle, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '导入书籍',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importBook,
                icon: const Icon(FontAwesomeIcons.filePdf),
                label: const Text('选择 PDF 文件'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.circleInfo, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '支持导入 PDF 格式的书籍文件。导入后文件将保存到应用目录。',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 目录页面
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookService = ServiceLocator.get<IBookService>();
    final currentBook = bookService.getCurrentBook();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.list, size: 28),
              const SizedBox(width: 12),
              const Text(
                '目录',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (currentBook == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.bookOpen,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '请先打开一本书籍',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.fileLines),
                    title: const Text('第一章：开始'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.fileLines),
                    title: const Text('第二章：发展'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.fileLines),
                    title: const Text('第三章：高潮'),
                    subtitle: Text('来自：$currentBook'),
                  ),
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.fileLines),
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

/// 书籍内容显示页面（使用真实的 PDF 查看器）
class BookContentView extends StatelessWidget {
  final String bookName;
  
  const BookContentView({super.key, required this.bookName});

  @override
  Widget build(BuildContext context) {
    final bookService = ServiceLocator.get<IBookService>();
    final filePath = bookService.getBookFilePath(bookName);
    
    if (filePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.exclamationTriangle, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              '无法找到书籍文件：$bookName',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return PdfViewerWidget(
      bookName: bookName,
      filePath: filePath,
    );
  }
}

/// 背景色配置
const Map<String, String> _backgroundColors = {
  'ffffff': '纯白',
  'f5f5dc': '羊皮纸黄',
  '000000': '深空黑',
  'd8e7eb': '灰绿',
  'e9faff': '浅蓝',
  'ffffed': '明黄',
  'eefaee': '淡绿',
  'cce8cf': '草绿',
  'fcefff': '红粉',
  'c0d3d7': '仿墨水屏',
  'd2b48c': '茶色',
  'c0c0c0': '银色',
  '00B800': '黑绿',
  'f5f1e8': '浅黄',
  '002b36': '午夜',
  'd9e0e8': '浅灰',
  '555555': '漆黑',
};

String _getBackgroundColorName(String color) {
  return _backgroundColors[color] ?? color;
}

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configService = ServiceLocator.get<IConfigService>();
    final bookService = ServiceLocator.get<IBookService>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.gear, size: 28),
              const SizedBox(width: 12),
              const Text(
                '设置',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 启动时自动恢复状态开关
          Builder(
            builder: (context) {
              // 获取 ConfigService 实例（需要访问 autoRestoreNotifier）
              final configServiceInstance = configService;
              // 由于接口中没有定义 autoRestoreNotifier，需要通过类型检查访问
              if (configServiceInstance is dynamic && 
                  configServiceInstance.autoRestoreNotifier != null) {
                return ValueListenableBuilder<bool>(
                  valueListenable: configServiceInstance.autoRestoreNotifier,
                  builder: (context, autoRestore, child) {
                    return Card(
                      child: SwitchListTile(
                        title: const Text('启动时自动恢复状态'),
                        subtitle: const Text('应用启动时自动恢复上次打开的书籍和标签页'),
                        value: autoRestore,
                        onChanged: (value) async {
                          await configService.setAutoRestore(value);
                        },
                      ),
                    );
                  },
                );
              } else {
                // 降级方案：使用 FutureBuilder
                return FutureBuilder<bool>(
                  future: configService.getAutoRestore(),
                  builder: (context, snapshot) {
                    final autoRestore = snapshot.data ?? true;
                    return Card(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return SwitchListTile(
                            title: const Text('启动时自动恢复状态'),
                            subtitle: const Text('应用启动时自动恢复上次打开的书籍和标签页'),
                            value: autoRestore,
                            onChanged: (value) async {
                              await configService.setAutoRestore(value);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              }
            },
          ),
          const SizedBox(height: 24),
          // 阅读背景色选择
          FutureBuilder<String>(
            future: configService.getReadingBackgroundColor(),
            builder: (context, snapshot) {
              final currentColor = snapshot.data ?? 'ffffff';
              return Card(
                child: ListTile(
                  leading: const Icon(FontAwesomeIcons.palette),
                  title: const Text('阅读背景色'),
                  subtitle: Text('当前：${_getBackgroundColorName(currentColor)}'),
                  trailing: DropdownButton<String>(
                    value: currentColor,
                    items: _backgroundColors.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(int.parse('FF${entry.key}', radix: 16)),
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.value),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        configService.setReadingBackgroundColor(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已设置为：${_getBackgroundColorName(value)}')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
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
                        min: 12,
                        max: 32,
                        divisions: 20,
                        label: '${fontSize.toInt()}px',
                        onChanged: (value) {
                          configService.setFontSize(value);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // 系统信息
          const SystemInfoWidget(),
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
                    if (mounted) {
                      ErrorSnackbar.showSuccess(
                        context,
                        '已清除 $successCount 个封面缓存',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ErrorSnackbar.show(context, '清除缓存失败：$e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('清除'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 清除所有数据按钮
          Card(
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red),
              title: const Text('清除所有数据'),
              subtitle: const Text('清除所有书籍数据和设置，此操作不可恢复'),
              trailing: ElevatedButton(
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
                            bookService.clearAllData();
                            Navigator.of(context).pop();
                            ErrorSnackbar.showSuccess(context, '已清除所有数据');
                          },
                          child: const Text('确定', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('清除'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
