INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Kotlin 协程与 Flow',
    'kotlin-coroutines-flow',
    '全面解析 Kotlin 协程和 Flow，从基础概念到高级用法，深入理解结构化并发、冷流热流、状态管理，以及与 RxJava 的对比，掌握现代 Kotlin 异步编程。',
    $doc$
# Kotlin 协程与 Flow：现代异步编程指南

Kotlin 协程（Coroutines）彻底改变了 Android 和后端开发中的异步编程方式。本文将从基础概念出发，深入探讨协程的各种用法、Flow 响应式流，以及与 RxJava 的对比。

## 为什么选择协程？

传统的回调式异步编程导致代码难以阅读和维护，俗称"回调地狱"。Kotlin 协程提供了**挂起函数（Suspending Functions）**，让异步代码像同步代码一样简洁。

> 协程不是线程，线程也不是协程。协程是**可挂起的计算**，可以在单个线程上运行多个协程。

## 协程基础

### 启动协程

Kotlin 提供了三种启动协程的方式：

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    // 1. launch - 启动新协程，不返回结果
    val job = launch {
        delay(1000L)
        println("World!")
    }

    // 2. async - 启动新协程，返回 Deferred（ future/promise）
    val deferred = async {
        delay(500L)
        "Hello"
    }

    // 3. runBlocking - 阻塞当前线程等待协程完成
    println("${deferred.await()}, ${job.join()}")
}
```

| 构建器 | 返回类型 | 用途 |
|--------|----------|------|
| `launch` | `Job` | 启动"开火即忘"的协程 |
| `async` | `Deferred<T>` | 启动返回结果的协程 |
| `runBlocking` | `T` | 桥接阻塞和非阻塞代码 |

### 挂起函数

挂起函数是协程的核心，可以在不阻塞线程的情况下暂停执行：

```kotlin
import kotlinx.coroutines.*

suspend fun fetchUserData(userId: String): User {
    // 模拟网络请求
    delay(1000) // 挂起 1 秒，不阻塞线程
    return User(userId, "John Doe", "john@example.com")
}

suspend fun fetchUserOrders(userId: String): List<Order> {
    delay(800)
    return listOf(
        Order("1", 99.99),
        Order("2", 149.99)
    )
}

// 组合挂起函数
suspend fun getUserProfile(userId: String): UserProfile {
    val user = fetchUserData(userId)
    val orders = fetchUserOrders(userId)
    return UserProfile(user, orders)
}
```

### CoroutineScope 和上下文

```kotlin
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext

// 自定义 Scope
class Activity : CoroutineScope {
    private val job = Job()

    override val coroutineContext: CoroutineContext
        get() = Dispatchers.Main + job

    fun destroy() {
        job.cancel() // 取消所有子协程
    }

    fun loadData() {
        launch {
            try {
                val data = fetchData()
                updateUI(data)
            } catch (e: CancellationException) {
                println("Coroutine cancelled")
            }
        }
    }

    private suspend fun fetchData(): String {
        delay(2000)
        return "Data loaded"
    }

    private fun updateUI(data: String) {
        println("UI updated: $data")
    }
}
```

## 结构化并发

### 父子关系

协程形成树形结构，父协程取消会自动取消所有子协程：

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    val parentJob = launch {
        // 子协程 1
        launch {
            repeat(10) { i ->
                println("Child 1: $i")
                delay(100)
            }
        }

        // 子协程 2
        launch {
            repeat(10) { i ->
                println("Child 2: $i")
                delay(150)
            }
        }

        delay(300)
        println("Parent: Cancelling...")
    }

    parentJob.join()
    println("All coroutines completed")
}
```

### SupervisorJob

当不希望子协程的失败影响其他子协程时，使用 SupervisorJob：

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    val supervisor = SupervisorJob()

    with(CoroutineScope(coroutineContext + supervisor)) {
        // 第一个子协程 - 会失败
        val job1 = launch {
            delay(100)
            throw RuntimeException("Oops!")
        }

        // 第二个子协程 - 不受影响继续运行
        val job2 = launch {
            repeat(5) { i ->
                println("Job2: $i")
                delay(100)
            }
        }

        joinAll(job1, job2)
    }
}
```

## Flow：响应式流

### 冷流（Cold Flow）

Flow 是 Kotlin 的响应式流实现，采用**冷流**模式 —— 数据在订阅时才产生：

```kotlin
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

fun simpleFlow(): Flow<Int> = flow {
    println("Flow started")
    for (i in 1..3) {
        delay(100)
        emit(i) // 发射值
    }
}

fun main() = runBlocking {
    val flow = simpleFlow()

    println("First collection:")
    flow.collect { value ->
        println("Received: $value")
    }

    println("\nSecond collection:")
    flow.collect { value ->
        println("Received again: $value")
    }
}
```

### 操作符

Flow 提供了丰富的操作符，类似于 RxJava：

```kotlin
import kotlinx.coroutines.flow.*

fun processNumbers(): Flow<Int> = flow {
    (1..10).forEach { emit(it) }
}

suspend fun demonstrateOperators() {
    val result = processNumbers()
        .filter { it % 2 == 0 }      // 过滤偶数
        .map { it * it }              // 平方
        .take(3)                      // 取前 3 个
        .onEach { println("Processing: $it") }
        .toList()                     // 收集为列表

    println("Result: $result")
}
```

| 操作符类别 | 示例 | 说明 |
|-----------|------|------|
| 转换 | `map`, `transform` | 转换每个元素 |
| 过滤 | `filter`, `take`, `drop` | 筛选元素 |
| 组合 | `zip`, `combine`, `merge` | 组合多个 Flow |
| 错误处理 | `catch`, `retry` | 处理异常 |
| 终端 | `collect`, `reduce`, `fold` | 收集结果 |

### StateFlow 和 SharedFlow

StateFlow 和 SharedFlow 是**热流**，适合状态管理和事件分发：

```kotlin
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class NewsViewModel {
    // StateFlow - 总是有值，适合 UI 状态
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    // SharedFlow - 适合一次性事件
    private val _events = MutableSharedFlow<String>()
    val events: SharedFlow<String> = _events.asSharedFlow()

    fun loadNews() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading

            try {
                val news = repository.fetchNews()
                _uiState.value = UiState.Success(news)
            } catch (e: Exception) {
                _uiState.value = UiState.Error(e.message ?: "Unknown error")
                _events.emit("Failed to load news")
            }
        }
    }
}

sealed class UiState {
    object Loading : UiState()
    data class Success(val data: List<News>) : UiState()
    data class Error(val message: String) : UiState()
}
```

## 异常处理

### try-catch 在协程中

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    val job = launch {
        try {
            riskyOperation()
        } catch (e: Exception) {
            println("Caught: ${e.message}")
        }
    }

    job.join()
}

suspend fun riskyOperation() {
    delay(100)
    throw RuntimeException("Something went wrong")
}
```

### CoroutineExceptionHandler

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    val handler = CoroutineExceptionHandler { _, exception ->
        println("Caught $exception")
    }

    val job = GlobalScope.launch(handler) {
        throw AssertionError("My Error")
    }

    val deferred = GlobalScope.async(handler) {
        throw ArithmeticException()
    }

    joinAll(job, deferred)
}
```

### Flow 异常处理

```kotlin
import kotlinx.coroutines.flow.*

fun safeFlow(): Flow<Int> = flow {
    emit(1)
    emit(2)
    throw RuntimeException("Error!")
}.catch { e ->
    println("Caught: ${e.message}")
    emit(-1) // 发射默认值
}.onCompletion { cause ->
    if (cause != null) {
        println("Flow completed with error")
    } else {
        println("Flow completed successfully")
    }
}
```

## 与 RxJava 对比

| 特性 | Kotlin Flow | RxJava |
|------|-------------|---------|
| 学习曲线 | 平缓 | 陡峭 |
| 内存开销 | 低 | 较高 |
| Android 支持 | 原生（官方推荐） | 需要额外依赖 |
| 线程切换 | `withContext` | `subscribeOn`/`observeOn` |
| 背压支持 | `buffer`, `conflate` | 内置 Backpressure |
| 取消机制 | 结构化并发 | Disposable |
| 冷/热流 | 明确区分 | 较模糊 |

### 从 RxJava 迁移示例

```kotlin
// RxJava 方式
Observable.fromIterable(users)
    .subscribeOn(Schedulers.io())
    .observeOn(AndroidSchedulers.mainThread())
    .map { it.name }
    .subscribe { println(it) }

// Flow 方式
users.asFlow()
    .flowOn(Dispatchers.IO)
    .map { it.name }
    .collect { println(it) }
```

## 实际应用：MVVM 架构

```kotlin
import androidx.lifecycle.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class UserViewModel(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // 搜索用户，自动去抖
    val users: StateFlow<List<User>> = _searchQuery
        .debounce(300) // 等待 300ms 无输入才搜索
        .flatMapLatest { query ->
            if (query.isEmpty()) {
                flowOf(emptyList())
            } else {
                userRepository.searchUsers(query)
            }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun refreshUsers() {
        viewModelScope.launch {
            try {
                userRepository.refreshUsers()
            } catch (e: Exception) {
                // 处理错误
            }
        }
    }
}
```

## 总结

Kotlin 协程和 Flow 提供了一套完整的异步编程解决方案：

1. **轻量级**：协程比线程更轻量，单线程可运行数千协程
2. **结构化并发**：自动管理协程生命周期，避免泄漏
3. **Flow 响应式**：声明式处理数据流，操作符丰富
4. **异常安全**：完善的异常处理机制
5. **与 Android 深度集成**：ViewModelScope、LifecycleScope 等

> 掌握协程和 Flow，是成为现代 Kotlin 开发者的必备技能。

通过本文的学习，你应该能够在实际项目中熟练使用协程进行网络请求、数据库操作、UI 更新等异步任务，并使用 Flow 构建响应式的数据流。

## Channel：协程间的通信桥梁

虽然 Flow 是处理数据流的强大工具，但在某些场景下，我们需要更底层的协程间通信机制。Channel 提供了类似阻塞队列的 API，但完全是非阻塞的。

### Channel 基础

```kotlin
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.*

fun main() = runBlocking {
    // 创建无缓冲的 Channel（默认）
    val channel = Channel<Int>()
    
    // 生产者协程
    launch {
        for (x in 1..5) {
            println("发送: $x")
            channel.send(x) // 挂起直到有消费者接收
        }
        channel.close() // 关闭 channel
    }
    
    // 消费者协程
    launch {
        for (value in channel) { // 使用 for 循环接收
            println("接收: $value")
            delay(100) // 模拟处理时间
        }
        println("Channel 已关闭")
    }
}
```

### 带缓冲的 Channel

```kotlin
import kotlinx.coroutines.channels.*

suspend fun bufferedChannelExample() {
    // 容量为 3 的有缓冲 channel
    val channel = Channel<Int>(capacity = 3)
    
    // 发送前 3 个不会挂起
    channel.send(1)
    channel.send(2)
    channel.send(3)
    
    // 第 4 个会挂起，直到有消费者接收
    // channel.send(4) // 挂起等待
    
    channel.close()
}
```

| Channel 类型 | 创建方式 | 特点 |
|-------------|---------|------|
| `Channel.RENDEZVOUS` | `Channel()` | 无缓冲，发送和接收必须同时发生 |
| `Channel.BUFFERED` | `Channel(Channel.BUFFERED)` | 使用默认缓冲区大小（64） |
| `Channel.CONFLATED` | `Channel(Channel.CONFLATED)` | 只保留最新值，旧值被覆盖 |
| `Channel.UNLIMITED` | `Channel(Channel.UNLIMITED)` | 无限缓冲区，不会挂起 |
| 指定容量 | `Channel(n)` | 自定义缓冲区大小 |

### Channel 与 Flow 的对比

```kotlin
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.*
import kotlinx.coroutines.flow.*

// Channel 示例：热流，多播
fun channelExample(): ReceiveChannel<Int> = CoroutineScope(Dispatchers.Default).produce {
    var i = 0
    while (isActive) {
        send(i++)
        delay(100)
    }
}

// Flow 示例：冷流，独立执行
fun flowExample(): Flow<Int> = flow {
    var i = 0
    while (true) {
        emit(i++)
        delay(100)
    }
}

fun main() = runBlocking {
    // Channel：多个消费者共享同一个值
    val channel = channelExample()
    launch {
        for (value in channel) {
            println("消费者 1: $value")
            if (value >= 3) break
        }
    }
    launch {
        for (value in channel) {
            println("消费者 2: $value")
            if (value >= 5) break
        }
    }
    
    delay(1000)
    channel.cancel()
    
    // Flow：每个消费者独立执行
    val flow = flowExample()
    launch {
        flow.take(3).collect { println("Flow 消费者 1: $it") }
    }
    launch {
        flow.take(3).collect { println("Flow 消费者 2: $it") }
    }
}
```

## 协程测试

测试异步代码一直是个挑战。Kotlin 提供了 `kotlinx-coroutines-test` 库，让协程测试变得简单。

### 基本测试

```kotlin
import kotlinx.coroutines.test.*
import kotlin.test.*

class CoroutineTest {
    
    @Test
    fun testAsyncOperation() = runTest {
        // 虚拟时间，不会真正等待
        val result = async {
            delay(1000) // 在虚拟时间中立即执行
            "Hello"
        }.await()
        
        assertEquals("Hello", result)
        // 测试在几毫秒内完成，而不是 1 秒
    }
    
    @Test
    fun testTimeout() = runTest {
        assertFailsWith<TimeoutCancellationException> {
            withTimeout(100) {
                delay(200) // 超过超时时间
            }
        }
    }
}
```

### Flow 测试

```kotlin
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*

class FlowTest {
    
    @Test
    fun testFlowEmissions() = runTest {
        val flow = flow {
            emit(1)
            emit(2)
            emit(3)
        }
        
        // 使用 Turbine 库测试 Flow
        flow.test {
            assertEquals(1, awaitItem())
            assertEquals(2, awaitItem())
            assertEquals(3, awaitItem())
            awaitComplete()
        }
    }
    
    @Test
    fun testStateFlow() = runTest {
        val stateFlow = MutableStateFlow(0)
        
        // 收集所有状态变化
        val values = mutableListOf<Int>()
        val job = launch {
            stateFlow.collect { values.add(it) }
        }
        
        stateFlow.value = 1
        stateFlow.value = 2
        stateFlow.value = 3
        
        // 等待状态更新传播
        advanceUntilIdle()
        
        assertEquals(listOf(0, 1, 2, 3), values)
        job.cancel()
    }
}
```

| 测试工具 | 用途 | 依赖 |
|---------|------|------|
| `runTest` | 虚拟时间环境 | kotlinx-coroutines-test |
| `TestDispatcher` | 控制协程调度 | kotlinx-coroutines-test |
| `Turbine` | Flow 断言库 | app.cash.turbine:turbine |
| `advanceTimeBy` | 快进虚拟时间 | kotlinx-coroutines-test |

## 性能优化与最佳实践

### 1. 避免在协程中阻塞线程

```kotlin
// ❌ 错误：在协程中阻塞线程
suspend fun badExample() {
    Thread.sleep(1000) // 阻塞整个线程！
}

// ✅ 正确：使用 delay 或 withContext
suspend fun goodExample() {
    delay(1000) // 挂起协程，不阻塞线程
}

// ✅ 正确：将阻塞操作移到 IO 调度器
suspend fun ioOperation() = withContext(Dispatchers.IO) {
    // 执行阻塞 IO 操作
    FileReader("data.txt").readText()
}
```

### 2. 合理选择 Dispatcher

```kotlin
import kotlinx.coroutines.Dispatchers

// CPU 密集型计算
suspend fun calculate() = withContext(Dispatchers.Default) {
    // 使用 CPU 核心数 - 1 的线程池
    heavyComputation()
}

// IO 密集型操作
suspend fun fetchData() = withContext(Dispatchers.IO) {
    // 最多 64 个线程（或更多）
    makeNetworkRequest()
}

// UI 更新（Android）
suspend fun updateUI() = withContext(Dispatchers.Main) {
    // 在主线程执行
    textView.text = "Updated"
}
```

| Dispatcher | 线程数 | 适用场景 |
|-----------|--------|---------|
| `Dispatchers.Default` | CPU 核心数 | CPU 密集型计算 |
| `Dispatchers.IO` | 64+ | 网络、文件 IO |
| `Dispatchers.Main` | 1 | UI 更新 |
| `Dispatchers.Unconfined` | 不固定 | 特殊调试用途 |

### 3. 内存泄漏防护

```kotlin
import androidx.lifecycle.*
import kotlinx.coroutines.*

class SafeViewModel : ViewModel() {
    
    // 使用 viewModelScope，自动在 ViewModel 清除时取消
    fun loadData() {
        viewModelScope.launch {
            try {
                val data = repository.fetchData()
                _uiState.value = UiState.Success(data)
            } catch (e: CancellationException) {
                // 正常取消，不需要处理
                throw e
            } catch (e: Exception) {
                _uiState.value = UiState.Error(e.message)
            }
        }
    }
    
    // 对于需要长期运行的操作，使用 SupervisorJob
    private val supervisor = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.Main + supervisor)
    
    fun startBackgroundTask() {
        scope.launch {
            while (isActive) {
                // 后台任务
                delay(5000)
            }
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        supervisor.cancel() // 取消所有子协程
    }
}
```

### 4. 结构化并发实践

```kotlin
import kotlinx.coroutines.*

// ✅ 使用 coroutineScope 确保所有子任务完成
suspend fun fetchAllData() = coroutineScope {
    val users = async { fetchUsers() }
    val posts = async { fetchPosts() }
    val comments = async { fetchComments() }
    
    // 等待所有请求完成
    DashboardData(users.await(), posts.await(), comments.await())
}

// ✅ 使用 withTimeout 设置超时
suspend fun fetchWithTimeout() = withTimeout(5000) {
    fetchCriticalData()
}

// ✅ 使用 supervisorScope 隔离失败
suspend fun fetchWithFallback() = supervisorScope {
    val primary = async { fetchFromPrimary() }
    val backup = async { fetchFromBackup() }
    
    try {
        primary.await()
    } catch (e: Exception) {
        backup.await()
    }
}
```

> **最佳实践**：始终使用结构化并发，避免使用 `GlobalScope`。在 Android 中优先使用 `lifecycleScope` 和 `viewModelScope`。

通过本文的学习，你应该能够在实际项目中熟练使用协程进行网络请求、数据库操作、UI 更新等异步任务，并使用 Flow 构建响应式的数据流。
$doc$,
    NULL,
    '/images/covers/kotlin-coroutines-flow.jpg',
    '<ul>
<li><a href="#为什么选择协程">为什么选择协程？</a></li>
<li><a href="#协程基础">协程基础</a></li>
<ul>
<li><a href="#启动协程">启动协程</a></li>
<li><a href="#挂起函数">挂起函数</a></li>
<li><a href="#coroutinescope-和上下文">CoroutineScope 和上下文</a></li>
</ul>
<li><a href="#结构化并发">结构化并发</a></li>
<ul>
<li><a href="#父子关系">父子关系</a></li>
<li><a href="#supervisorjob">SupervisorJob</a></li>
</ul>
<li><a href="#flow-响应式流">Flow：响应式流</a></li>
<ul>
<li><a href="#冷流-cold-flow">冷流（Cold Flow）</a></li>
<li><a href="#操作符">操作符</a></li>
<li><a href="#stateflow-和-sharedflow">StateFlow 和 SharedFlow</a></li>
</ul>
<li><a href="#异常处理">异常处理</a></li>
<ul>
<li><a href="#try-catch-在协程中">try-catch 在协程中</a></li>
<li><a href="#coroutineexceptionhandler">CoroutineExceptionHandler</a></li>
<li><a href="#flow-异常处理">Flow 异常处理</a></li>
</ul>
<li><a href="#与-rxjava-对比">与 RxJava 对比</a></li>
<ul>
<li><a href="#从-rxjava-迁移示例">从 RxJava 迁移示例</a></li>
</ul>
<li><a href="#实际应用-mvvm-架构">实际应用：MVVM 架构</a></li>
<li><a href="#总结">总结</a></li>
<li><a href="#channel-协程间的通信桥梁">Channel：协程间的通信桥梁</a></li>
<ul>
<li><a href="#channel-基础">Channel 基础</a></li>
<li><a href="#带缓冲的-channel">带缓冲的 Channel</a></li>
<li><a href="#channel-与-flow-的对比">Channel 与 Flow 的对比</a></li>
</ul>
<li><a href="#协程测试">协程测试</a></li>
<ul>
<li><a href="#基本测试">基本测试</a></li>
<li><a href="#flow-测试">Flow 测试</a></li>
</ul>
<li><a href="#性能优化与最佳实践">性能优化与最佳实践</a></li>
<ul>
<li><a href="#1-避免在协程中阻塞线程">1. 避免在协程中阻塞线程</a></li>
<li><a href="#2-合理选择-dispatcher">2. 合理选择 Dispatcher</a></li>
<li><a href="#3-内存泄漏防护">3. 内存泄漏防护</a></li>
<li><a href="#4-结构化并发实践">4. 结构化并发实践</a></li>
</ul>
</ul>',
    1461,
    8,
    'published',
    NOW() - INTERVAL '15 minutes',
    NOW() - INTERVAL '15 minutes',
    NOW() - INTERVAL '15 minutes'
) ON CONFLICT DO NOTHING;
