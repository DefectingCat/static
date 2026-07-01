INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Dart 与 Flutter：跨平台开发实战',
    'dart-flutter-crossplatform',
    'Flutter 用一套代码同时跑在 iOS、Android、Web 和桌面端。Dart 语言的设计简洁实用，配合 Flutter 的声明式 UI，开发效率极高。本文深入 Dart 语言特性和 Flutter 实战技巧。',
    $doc$
# Dart 与 Flutter：跨平台开发实战

2017 年，Google 发布了 Flutter 的第一个稳定版本。那时候跨平台框架已经有 React Native、Xamarin、Cordova 等不少选择。Flutter 的差异化策略很清晰：不是把 WebView 或原生控件包一层，而是自己渲染 UI——用 Skia 图形引擎在每帧都绘制像素。

这个决策让 Flutter 获得了近乎原生的性能，但也引来了质疑："自己画 UI？那不是跟游戏引擎一样重了？"三年后的今天，Flutter 已经是 GitHub 上 stars 最多的跨平台框架之一。字节跳动、阿里巴巴、腾讯都在用。我维护的一个 Flutter 项目，同时跑在 iOS、Android、macOS 和 Web 上，核心代码共享率超过 85%。

Dart 这门语言也挺有意思。它最初是想替代 JavaScript，失败了；后来想替代 Java，也没成。最后给 Flutter 当亲儿子，反而找到了最合适的定位。

## Dart 语言核心特性

Dart 的语法对 Java、C#、JavaScript 开发者都很友好。它既有静态类型，又支持动态编程；既能编译成机器码（AOT），又能解释执行（JIT）。

### 空安全（Null Safety）

Dart 2.12 引入的空安全是我认为最重要的语言特性。它把 nullable 和 non-nullable 类型在编译期就区分开。

```dart
// Non-nullable——不能为空
String name = 'Alice';
// name = null;  // 编译错误！

// Nullable——可以空
String? nickname;
nickname = null;  // OK

// 使用 nullable 变量需要处理 null
String greeting = 'Hello, ${nickname ?? 'Guest'}';

// 强制解包（确定不为空时才用）
String displayName = nickname!;  // 如果 nickname 为 null，运行时抛异常

// 条件访问
int? length = nickname?.length;  // nickname 为 null 时，length 也是 null
```

空安全迁移是 breaking change。我给一个 5 万行的 Dart 项目做过迁移，IDE 的自动重构处理了 80% 的工作，剩下的手动调整花了一周。迁移完成后，生产环境的 NullPointerException 基本绝迹。

### 扩展方法（Extension Methods）

Dart 2.7 引入的扩展方法让你能给现有类型添加方法，不用继承或包装。

```dart
// 给 String 添加扩展方法
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isValidEmail {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(this);
  }
}

// 使用——像原生方法一样调用
var name = 'alice';
print(name.capitalize());  // "Alice"
print('test@example.com'.isValidEmail);  // true
```

扩展方法在 Flutter 里特别有用。比如给 `BuildContext` 添加导航快捷方式：

```dart
extension NavigationExtension on BuildContext {
  void push(Widget page) {
    Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));
  }

  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
}

// 使用
context.push(DetailPage(id: 123));
```

### 混入（Mixin）

Dart 的 mixin 是一种代码复用机制，比继承更灵活。

```dart
mixin Logger {
  void log(String message) {
    print('[${DateTime.now()}] $message');
  }

  void logError(String message, Object error) {
    print('[${DateTime.now()}] ERROR: $message - $error');
  }
}

mixin Cacheable {
  final Map<String, dynamic> _cache = {};

  T? getCached<T>(String key) => _cache[key] as T?;

  void setCached<T>(String key, T value) {
    _cache[key] = value;
  }
}

// 使用 mixin
class UserRepository with Logger, Cacheable {
  Future<User> getUser(int id) async {
    log('Fetching user $id');

    var cached = getCached<User>('user_$id');
    if (cached != null) {
      log('Cache hit for user $id');
      return cached;
    }

    // ... 网络请求
    var user = await fetchFromNetwork(id);
    setCached('user_$id', user);
    return user;
  }
}
```

`with` 关键字应用 mixin，`extends` 用于继承。一个类可以继承一个父类，但混入多个 mixin。Flutter 的 Widget 体系大量用 mixin，比如 `SingleTickerProviderStateMixin`。

## Flutter Widget 体系

Flutter 的核心设计哲学是"一切皆 Widget"。不同于 Android 的 View 和 iOS 的 UIView，Widget 不是 UI 元素本身，而是 UI 的配置描述。

### StatelessWidget 与 StatefulWidget

```dart
// 无状态 Widget——只依赖传入的参数
class Greeting extends StatelessWidget {
  final String name;

  const Greeting({required this.name, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hello, $name!',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

// 有状态 Widget——内部维护状态
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

`setState` 标记状态变化，Flutter 框架会重新调用 `build` 方法。关键原则：**build 方法必须无副作用、必须是纯函数**。

### 布局 Widget

Flutter 的布局系统跟 Web 的 CSS 或 Android 的 ConstraintLayout 都不太一样。核心是几个基础 Widget 的组合：

```dart
// 常用布局 Widget
Column(           // 垂直排列
  mainAxisAlignment: MainAxisAlignment.center,
  children: [widget1, widget2, widget3],
)

Row(              // 水平排列
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [widget1, widget2],
)

Stack(            // 堆叠
  children: [
    backgroundImage,
    Positioned(bottom: 16, right: 16, child: floatingButton),
  ],
)

Expanded(         // 占据剩余空间
  flex: 2,        // 比例
  child: SomeWidget(),
)

Container(        // 装饰性容器
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: const Text('内容'),
)
```

布局性能对比：

| Widget | 适用场景 | 性能 | 复杂度 |
|--------|---------|------|--------|
| Column/Row | 简单线性布局 | 高 | 低 |
| Stack | 重叠元素 | 高 | 中 |
| ListView | 长列表 | 高（懒加载） | 低 |
| GridView | 网格布局 | 高（懒加载） | 低 |
| CustomPaint | 自定义绘制 | 最高 | 高 |
| CustomMultiChildLayout | 复杂自定义布局 | 中 | 高 |

### 响应式编程与 Stream

Dart 的 `Stream` 配合 Flutter 的 `StreamBuilder` 实现响应式 UI：

```dart
class UserProfile extends StatelessWidget {
  final Stream<User> userStream;

  const UserProfile({required this.userStream, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final user = snapshot.data!;
        return Column(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(user.avatar)),
            Text(user.name),
            Text(user.email),
          ],
        );
      },
    );
  }
}
```

## 状态管理：从简单到复杂

Flutter 的状态管理方案很多，从轻量的 ValueNotifier 到重量级的 Bloc，各有适用场景。

### 方案对比

| 方案 | 适用场景 | 复杂度 | 学习曲线 |
|------|---------|--------|---------|
| setState | 局部状态、简单页面 | 低 | 平缓 |
| InheritedWidget | 跨组件共享状态 | 中 | 陡峭 |
| Provider | 中小型应用 | 低 | 平缓 |
| Riverpod | 中大型应用 | 中 | 中等 |
| Bloc | 大型应用、复杂业务逻辑 | 高 | 陡峭 |
| GetX | 快速开发、小型项目 | 低 | 平缓 |

### Provider

Provider 是 Flutter 团队推荐的轻量级状态管理方案。

```dart
// 定义状态
class CounterModel extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

// 在 Widget 树顶部提供状态
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CounterModel(),
      child: const MyApp(),
    ),
  );
}

// 在子 Widget 中消费状态
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterModel>();
    return Text('Count: ${counter.count}');
  }
}

class CounterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.read<CounterModel>().increment(),
      child: const Text('+1'),
    );
  }
}
```

### Riverpod

Riverpod 是 Provider 的作者写的下一代状态管理方案，解决了 Provider 的一些设计问题。

```dart
// 定义 Provider
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
  void decrement() => state--;
}

// 在 Widget 中使用
class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Scaffold(
      body: Center(child: Text('Count: $count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Riverpod 的优势在于：编译时安全（不会出现 ProviderNotFoundException）、支持刷新自动处理、代码更可测试。

### Bloc

Bloc（Business Logic Component）适合大型应用，把业务逻辑和 UI 彻底分离。

```dart
// 事件
abstract class CounterEvent {}
class CounterIncrementPressed extends CounterEvent {}
class CounterDecrementPressed extends CounterEvent {}

// 状态
class CounterState {
  final int count;
  const CounterState(this.count);
}

// Bloc
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(0)) {
    on<CounterIncrementPressed>((event, emit) => emit(CounterState(state.count + 1)));
    on<CounterDecrementPressed>((event, emit) => emit(CounterState(state.count - 1)));
  }
}

// UI
class CounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      builder: (context, state) {
        return Scaffold(
          body: Center(child: Text('Count: ${state.count}')),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () => context.read<CounterBloc>().add(CounterIncrementPressed()),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## 性能优化

Flutter 的性能优化核心在于减少不必要的 Widget 重建。

### const 构造函数

```dart
// 使用 const 让 Widget 在编译期就确定，不需要重建
const Text('Hello')

// 自定义 Widget 也支持 const
class MyButton extends StatelessWidget {
  final String label;
  const MyButton({required this.label, super.key});  // const 构造函数

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () {}, child: Text(label));
  }
}
```

### Keys 的使用

```dart
// 列表中使用 key，帮助 Flutter 识别元素身份
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),  // 唯一 key
      title: Text(items[index].title),
    );
  },
)
```

没有 key 时，如果列表中间插入一个元素，Flutter 会重建插入点之后的所有 Widget。有 key 时，Flutter 知道哪些元素是新加入的、哪些只是位置变了，只做最少量的重建。

### RepaintBoundary

```dart
// 把频繁重绘的区域隔离，避免影响整个页面
RepaintBoundary(
  child: AnimatedWidget(...),  // 这个 Widget 频繁重绘
)
```

### 图片优化

```dart
// 使用缓存的网络图片
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheWidth: 200,  // 限制缓存大小
)
```

## 平台通道：调用原生代码

Flutter 无法直接访问平台特定 API，需要通过 Platform Channel 跟原生代码通信。

```dart
// Dart 端
class BatteryService {
  static const platform = MethodChannel('samples.flutter.dev/battery');

  static Future<int> getBatteryLevel() async {
    try {
      final level = await platform.invokeMethod<int>('getBatteryLevel');
      return level ?? -1;
    } on PlatformException catch (e) {
      print('Failed to get battery level: ${e.message}');
      return -1;
    }
  }
}
```

```kotlin
// Android 端
class MainActivity : FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getBatteryLevel") {
                    val batteryLevel = getBatteryLevel()
                    result.success(batteryLevel)
                } else {
                    result.notImplemented()
                }
            }
    }
}
```

对于常见的平台功能（相机、定位、通知等），优先使用社区维护的 plugin，比如 `image_picker`、`geolocator`、`flutter_local_notifications`。只有遇到特殊需求时才自己写 Platform Channel。


## Widget 生命周期与渲染原理

理解 Flutter 的渲染流程对性能优化至关重要。

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Widget 第一次插入到树中
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依赖的 InheritedWidget 发生变化时
  }

  @override
  void didUpdateWidget(covariant MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget 的配置发生变化（父 Widget rebuild）
  }

  @override
  Widget build(BuildContext context) {
    // 每次 setState 或依赖变化时调用
    return Container();
  }

  @override
  void deactivate() {
    super.deactivate();
    // Widget 从树中移除，但可能重新插入
  }

  @override
  void dispose() {
    super.dispose();
    // Widget 永久移除，释放资源
  }
}
```

Flutter 的三棵树：

| 树 | 作用 | 持久性 |
|---|------|--------|
| Widget Tree | UI 配置描述 | 轻量，每次重建 |
| Element Tree | 连接 Widget 和 RenderObject | 持久，决定复用 |
| RenderObject Tree | 实际布局和绘制 | 持久，只更新变化 |

Element 的复用机制是 Flutter 高效的关键。当 `setState` 触发重建时，Flutter 会比较新旧 Widget Tree，尽可能复用现有的 Element 和 RenderObject。

## Navigation 2.0：声明式路由

Flutter 的 Navigation 2.0 提供了声明式的路由管理方式，适合深链接和 Web 场景。

```dart
class AppRouterDelegate extends RouterDelegate<RoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RoutePath> {

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _selectedUserId;

  void showUserDetails(String userId) {
    _selectedUserId = userId;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        const MaterialPage(child: UserListPage()),
        if (_selectedUserId != null)
          MaterialPage(
            child: UserDetailPage(userId: _selectedUserId!),
            key: ValueKey('user_$_selectedUserId'),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        _selectedUserId = null;
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(RoutePath configuration) async {
    if (configuration.isUserPage) {
      _selectedUserId = configuration.userId;
    }
  }
}
```

Navigation 2.0 比 1.0 复杂得多，但对于需要处理浏览器 URL、Android 返回按钮、深链接的场景，它是必须的。如果只是简单的 App 内导航，用 `Navigator.push` 配合 `GoRouter` 这样的第三方库会更简单。

## Flutter 测试策略

Flutter 的测试分三层：

| 测试类型 | 运行环境 | 速度 | 用途 |
|---------|---------|------|------|
| Unit Test | Dart VM | 极快 | 纯逻辑、算法 |
| Widget Test | 虚拟 UI 环境 | 快 | Widget 交互 |
| Integration Test | 真机/模拟器 | 慢 | 端到端 |

```dart
// Widget 测试
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CounterPage()));

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();  // 触发重建

    expect(find.text('1'), findsOneWidget);
  });
}
```

Golden 测试（截图对比）：

```dart
testWidgets('Profile page matches golden', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
  await expectLater(
    find.byType(ProfilePage),
    matchesGoldenFile('profile_page.png'),
  );
});
```

集成测试：

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整购物流程', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('商品列表'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('加入购物车'));
    await tester.pumpAndSettle();

    expect(find.text('购物车 (1)'), findsOneWidget);
  });
}
```

## BuildContext 深度理解

`BuildContext` 是每个 Flutter 开发者天天用但很多人没真正理解的概念。

```dart
// BuildContext 实际上是 Element 的包装
abstract class BuildContext {
  Widget get widget;
  bool get mounted;
  RenderObject? findRenderObject();
  T? dependOnInheritedWidgetOfExactType<T>();
  // ...
}
```

`BuildContext` 的生命周期跟 Widget 绑定。在 `async` 操作后使用 `context` 之前，必须检查 `mounted`：

```dart
Future<void> loadData() async {
  final data = await api.fetchData();

  // 必须检查 mounted，因为 await 期间 Widget 可能被移除
  if (!mounted) return;

  setState(() {
    _data = data;
  });
}
```

`context` 不能跨异步间隙使用的原因：在 `await` 期间，用户可能导航到了别的页面，原来的 Widget 已经被 `dispose` 了。这时候调用 `setState` 会抛出异常。

InheritedWidget 和 `BuildContext` 的关系：

```dart
// 获取最近的 Theme
final theme = Theme.of(context);  // 等价于 context.dependOnInheritedWidgetOfExactType<Theme>()

// 获取 Navigator
final navigator = Navigator.of(context);

// 获取 MediaQuery（屏幕尺寸等）
final mediaQuery = MediaQuery.of(context);
```

每次 `dependOnInheritedWidgetOfExactType` 被调用，当前 Widget 就会在 InheritedWidget 变化时自动重建。这是 Flutter 数据流的基础。

## Widget 生命周期与渲染原理

理解 Flutter 的渲染流程对性能优化至关重要。

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Widget 第一次插入到树中
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依赖的 InheritedWidget 发生变化时
  }

  @override
  void didUpdateWidget(covariant MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget 的配置发生变化（父 Widget rebuild）
  }

  @override
  Widget build(BuildContext context) {
    // 每次 setState 或依赖变化时调用
    return Container();
  }

  @override
  void dispose() {
    super.dispose();
    // Widget 永久移除，释放资源
  }
}
```

Flutter 的三棵树：

| 树 | 作用 | 持久性 |
|---|------|--------|
| Widget Tree | UI 配置描述 | 轻量，每次重建 |
| Element Tree | 连接 Widget 和 RenderObject | 持久，决定复用 |
| RenderObject Tree | 实际布局和绘制 | 持久，只更新变化 |

Element 的复用机制是 Flutter 高效的关键。当 `setState` 触发重建时，Flutter 会比较新旧 Widget Tree，尽可能复用现有的 Element 和 RenderObject。

## Navigation 2.0：声明式路由

Flutter 的 Navigation 2.0 提供了声明式的路由管理方式，适合深链接和 Web 场景。

```dart
class AppRouterDelegate extends RouterDelegate<RoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RoutePath> {

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _selectedUserId;

  void showUserDetails(String userId) {
    _selectedUserId = userId;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        const MaterialPage(child: UserListPage()),
        if (_selectedUserId != null)
          MaterialPage(
            child: UserDetailPage(userId: _selectedUserId!),
            key: ValueKey('user_$_selectedUserId'),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        _selectedUserId = null;
        notifyListeners();
        return true;
      },
    );
  }
}
```

Navigation 2.0 比 1.0 复杂得多，但对于需要处理浏览器 URL、Android 返回按钮、深链接的场景，它是必须的。如果只是简单的 App 内导航，用 `GoRouter` 这样的第三方库会更简单。

## Flutter 测试策略

Flutter 的测试分三层：

| 测试类型 | 运行环境 | 速度 | 用途 |
|---------|---------|------|------|
| Unit Test | Dart VM | 极快 | 纯逻辑、算法 |
| Widget Test | 虚拟 UI 环境 | 快 | Widget 交互 |
| Integration Test | 真机/模拟器 | 慢 | 端到端 |

```dart
// Widget 测试
testWidgets('Counter increments', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: CounterPage()));
  expect(find.text('0'), findsOneWidget);

  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

Golden 测试（截图对比）适合 UI 回归测试。集成测试用 `IntegrationTestWidgetsFlutterBinding` 做端到端验证。

## BuildContext 深度理解

`BuildContext` 是每个 Flutter 开发者天天用但很多人没真正理解的概念。它实际上是 Element 的包装，生命周期跟 Widget 绑定。

```dart
// 在 async 操作后使用 context 之前，必须检查 mounted
Future<void> loadData() async {
  final data = await api.fetchData();
  if (!mounted) return;  // Widget 可能已被移除
  setState(() { _data = data; });
}
```

`dependOnInheritedWidgetOfExactType` 被调用时，当前 Widget 就会在 InheritedWidget 变化时自动重建。这是 Flutter 数据流的基础。

## Flutter 的 Key：控制 Widget 的复用

Key 决定了框架在重建时如何匹配新旧 Widget。

```dart
// 没有 Key 的问题：删掉 'B' 后状态错乱
Column(
  children: items.map((item) => TodoItem(text: item)).toList(),
)

// 加上 Key 后：Flutter 能正确识别每个 Widget
Column(
  children: items.map((item) => 
    TodoItem(key: ValueKey(item), text: item)
  ).toList(),
)
```

Key 的类型：ValueKey（基于值）、ObjectKey（基于对象）、UniqueKey（每次唯一）、GlobalKey（全局唯一）。GlobalKey 可以跨 Widget 树访问 State，常用于 Form 验证。

## 响应式编程：Stream 和 RxDart

Dart 的 Stream 是响应式编程的基础。RxDart 提供了更强大的操作符：

```dart
// 防抖搜索
_searchSubject
  .debounceTime(const Duration(milliseconds: 500))
  .distinct()
  .switchMap((query) => Stream.fromFuture(searchApi(query)))
  .listen((results) {
    setState(() => _results = results);
  });
```

常用操作符：map（转换）、where（过滤）、debounceTime（防抖）、throttleTime（节流）、switchMap（切换最新流）、combineLatest（组合最新值）。

## Platform Channel 进阶

对于复杂的原生功能集成，Platform Channel 需要更细致的处理。

```dart
class BatteryChannel {
  static const MethodChannel _channel = 
      MethodChannel('com.example.app/battery');
  static const EventChannel _eventChannel = 
      EventChannel('com.example.app/battery_events');

  static Future<int> getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level ?? -1;
    } on PlatformException catch (e) {
      throw BatteryException(e.message ?? 'Unknown error');
    }
  }

  static Stream<int> get batteryLevelStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as int);
  }
}
```

Platform Channel 的性能开销：每次调用涉及 Dart -> JNI/Objective-C -> 原生的序列化传输。对于高频调用（如每帧 60 次的传感器数据），应该批量传输或使用二进制编码。

## 发布与构建优化

Flutter 的 release 构建做了很多优化：

```bash
# Android Release 构建
flutter build apk --release --split-per-abi

# iOS Release 构建
flutter build ios --release

# Web 构建
flutter build web --release --web-renderer canvaskit

# 分析包大小
flutter build apk --analyze-size
```

包大小优化技巧：资源压缩（flutter_image_compress）、代码混淆（--obfuscate）、分 ABI 构建（--split-per-abi）、延迟加载（deferred-components）。Tree shaking 在 release 模式下自动移除未使用的代码。

## 总结

Flutter + Dart 的组合在跨平台开发领域已经是第一梯队的选择。性能接近原生，开发效率接近 Web，一套代码跑遍所有平台。

| 方面 | Dart/Flutter 的表现 | 评价 |
|------|-------------------|------|
| 开发效率 | Hot Reload、声明式 UI | ⭐⭐⭐⭐⭐ |
| 性能 | Skia 自绘，接近原生 | ⭐⭐⭐⭐ |
| 生态 | pub.dev 超过 3 万包 | ⭐⭐⭐⭐ |
| 平台覆盖 | iOS/Android/Web/桌面 | ⭐⭐⭐⭐⭐ |
| 学习曲线 | 有 React/JS 基础的话很快 | ⭐⭐⭐⭐ |

Flutter 不是银弹。如果你的应用重度依赖平台特定功能（比如 ARKit、复杂的音频处理），或者团队完全没有移动端经验，可能需要更谨慎地评估。但对于大多数 CRUD 类 App、电商、社交、工具类应用，Flutter 的 ROI 非常高。

我现在的判断是：Flutter 在移动端已经站稳了脚跟，Web 和桌面端还在快速成熟中。如果你需要一个跨平台的解决方案，Flutter 应该是首选之一。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
        NULL,
        NULL,
        '<ul>
<li><a href="#dart-语言核心特性">Dart 语言核心特性</a></li>
<ul>
<li><a href="#空安全-null-safety">空安全（Null Safety）</a></li>
<li><a href="#扩展方法-extension-methods">扩展方法（Extension Methods）</a></li>
<li><a href="#混入-mixin">混入（Mixin）</a></li>
</ul>
<li><a href="#flutter-widget-体系">Flutter Widget 体系</a></li>
<ul>
<li><a href="#statelesswidget-与-statefulwidget">StatelessWidget 与 StatefulWidget</a></li>
<li><a href="#布局-widget">布局 Widget</a></li>
<li><a href="#响应式编程与-stream">响应式编程与 Stream</a></li>
</ul>
<li><a href="#状态管理-从简单到复杂">状态管理：从简单到复杂</a></li>
<ul>
<li><a href="#方案对比">方案对比</a></li>
<li><a href="#provider">Provider</a></li>
<li><a href="#riverpod">Riverpod</a></li>
<li><a href="#bloc">Bloc</a></li>
</ul>
<li><a href="#性能优化">性能优化</a></li>
<ul>
<li><a href="#const-构造函数">const 构造函数</a></li>
<li><a href="#keys-的使用">Keys 的使用</a></li>
<li><a href="#repaintboundary">RepaintBoundary</a></li>
<li><a href="#图片优化">图片优化</a></li>
</ul>
<li><a href="#平台通道-调用原生代码">平台通道：调用原生代码</a></li>
<li><a href="#widget-生命周期与渲染原理">Widget 生命周期与渲染原理</a></li>
<li><a href="#navigation-2-0-声明式路由">Navigation 2.0：声明式路由</a></li>
<li><a href="#flutter-测试策略">Flutter 测试策略</a></li>
<li><a href="#buildcontext-深度理解">BuildContext 深度理解</a></li>
<li><a href="#widget-生命周期与渲染原理">Widget 生命周期与渲染原理</a></li>
<li><a href="#navigation-2-0-声明式路由">Navigation 2.0：声明式路由</a></li>
<li><a href="#flutter-测试策略">Flutter 测试策略</a></li>
<li><a href="#buildcontext-深度理解">BuildContext 深度理解</a></li>
<li><a href="#flutter-的-key-控制-widget-的复用">Flutter 的 Key：控制 Widget 的复用</a></li>
<li><a href="#响应式编程-stream-和-rxdart">响应式编程：Stream 和 RxDart</a></li>
<li><a href="#platform-channel-进阶">Platform Channel 进阶</a></li>
<li><a href="#发布与构建优化">发布与构建优化</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
        2297,
        12,
        'published',
    NOW() - INTERVAL '18 days',
    NOW() - INTERVAL '18 days',
    NOW() - INTERVAL '18 days'
) ON CONFLICT DO NOTHING;
