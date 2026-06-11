INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'C++ RAII 与智能指针：现代 C++ 内存管理完全指南',
    'cpp-raii',
    '深入理解 C++ 的 RAII 原则、智能指针（unique_ptr、shared_ptr、weak_ptr）以及三/五/零法则，写出内存安全的现代 C++ 代码。',
    $doc$
# C++ RAII 与智能指针：现代 C++ 内存管理完全指南

C++ 是一门赋予程序员极大自由度的语言，这种自由既带来了高性能，也带来了内存管理的挑战。手动管理内存容易引发内存泄漏、悬垂指针、双重释放等问题。为了解决这些问题，C++ 社区发展出了 **RAII**（Resource Acquisition Is Initialization，资源获取即初始化）原则，以及一套智能指针工具。掌握这些现代 C++ 特性，是编写健壮 C++ 代码的关键。

本文将系统介绍 RAII 原则、智能指针的使用、三/五/零法则，以及实际开发中的最佳实践。

## 什么是 RAII？

RAII 是 C++ 的核心编程范式，由 Bjarne Stroustrup 提出。其核心思想是：**将资源的生命周期与对象的生命周期绑定，在对象构造时获取资源，在对象析构时释放资源**。

由于 C++ 的栈对象在离开作用域时会自动调用析构函数，这一机制天然地保证了资源的正确释放，即使在发生异常的情况下也是如此。

### 基础示例：文件句柄

```cpp
#include <cstdio>
#include <stdexcept>

class FileHandle {
    FILE* file;
    
public:
    // 构造函数：获取资源
    explicit FileHandle(const char* filename, const char* mode = "r") 
        : file(std::fopen(filename, mode)) {
        if (!file) {
            throw std::runtime_error("无法打开文件");
        }
    }
    
    // 析构函数：释放资源
    ~FileHandle() {
        if (file) {
            std::fclose(file);
        }
    }
    
    // 禁用拷贝（资源不可复制）
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
    
    // 允许移动（C++11）
    FileHandle(FileHandle&& other) noexcept : file(other.file) {
        other.file = nullptr;
    }
    
    FileHandle& operator=(FileHandle&& other) noexcept {
        if (this != &other) {
            if (file) std::fclose(file);
            file = other.file;
            other.file = nullptr;
        }
        return *this;
    }
    
    FILE* get() const { return file; }
};

// 使用
void processFile(const char* filename) {
    FileHandle fh(filename); // 打开文件
    // 处理文件...
    // 即使发生异常，fh 的析构函数也会确保文件被关闭
}
```

## 三/五/零法则

### 三法则（Rule of Three）

在 C++98/03 时代，如果一个类需要自定义以下三个函数中的任意一个，通常需要定义全部三个：

1. **析构函数**（Destructor）
2. **拷贝构造函数**（Copy Constructor）
3. **拷贝赋值运算符**（Copy Assignment Operator）

这是因为这三个函数都与资源管理密切相关。如果你需要自定义其中一个，说明你的类管理着某种资源，因此三个都需要自定义。

### 五法则（Rule of Five）

C++11 引入了移动语义，五法则在三法则基础上增加了：

4. **移动构造函数**（Move Constructor）
5. **移动赋值运算符**（Move Assignment Operator）

```cpp
class Resource {
    int* data;
    size_t size;
    
public:
    // 构造函数
    explicit Resource(size_t n) : data(new int[n]), size(n) {}
    
    // 1. 析构函数
    ~Resource() {
        delete[] data;
    }
    
    // 2. 拷贝构造函数
    Resource(const Resource& other) : data(new int[other.size]), size(other.size) {
        std::copy(other.data, other.data + size, data);
    }
    
    // 3. 拷贝赋值运算符
    Resource& operator=(const Resource& other) {
        if (this != &other) {
            Resource temp(other); // 拷贝并交换惯用法
            std::swap(data, temp.data);
            std::swap(size, temp.size);
        }
        return *this;
    }
    
    // 4. 移动构造函数
    Resource(Resource&& other) noexcept : data(other.data), size(other.size) {
        other.data = nullptr;
        other.size = 0;
    }
    
    // 5. 移动赋值运算符
    Resource& operator=(Resource&& other) noexcept {
        if (this != &other) {
            delete[] data;
            data = other.data;
            size = other.size;
            other.data = nullptr;
            other.size = 0;
        }
        return *this;
    }
};
```

### 零法则（Rule of Zero）

现代 C++ 的最佳实践是**零法则**：

> **如果一个类不需要自定义析构函数、拷贝/移动构造函数或赋值运算符，那就不要自定义。**

通过使用智能指针和标准库容器，你可以让编译器自动生成这些函数：

```cpp
// ✅ 遵循零法则
class ModernResource {
    std::unique_ptr<int[]> data;
    size_t size;
    
public:
    explicit ModernResource(size_t n) : data(std::make_unique<int[]>(n)), size(n) {}
    
    // 编译器自动生成的析构函数、拷贝/移动函数都能正确工作
    // 因为 unique_ptr 已经正确管理了内存
};
```

## 智能指针

C++11 引入了三种智能指针，分别适用于不同的所有权模型：

### std::unique_ptr：独占所有权

`unique_ptr` 表示对对象的**独占所有权**，同一时间只能有一个 `unique_ptr` 指向给定对象。当 `unique_ptr` 被销毁时，它所指向的对象也会被自动删除。

```cpp
#include <memory>
#include <iostream>

class Widget {
public:
    Widget() { std::cout << "Widget 构造\\n"; }
    ~Widget() { std::cout << "Widget 析构\\n"; }
    void doSomething() { std::cout << "Widget 工作中\\n"; }
};

void uniquePtrDemo() {
    // 创建 unique_ptr
    std::unique_ptr<Widget> ptr1 = std::make_unique<Widget>();
    ptr1->doSomething();
    
    // 转移所有权
    std::unique_ptr<Widget> ptr2 = std::move(ptr1);
    // ptr1 现在为空
    // ptr2->doSomething(); // ✅
    
    // 自动释放
} // Widget 在此处被销毁

// 工厂函数返回 unique_ptr
std::unique_ptr<Widget> createWidget() {
    return std::make_unique<Widget>();
}
```

**最佳实践**：
- 默认使用 `std::make_unique` 创建（C++14）
- 用于表示独占所有权
- 作为函数参数传递时，使用 `std::move` 转移所有权

### std::shared_ptr：共享所有权

`shared_ptr` 通过**引用计数**实现共享所有权。多个 `shared_ptr` 可以同时指向同一个对象，当最后一个 `shared_ptr` 被销毁时，对象才被删除。

```cpp
#include <memory>
#include <iostream>

void sharedPtrDemo() {
    // 创建 shared_ptr
    std::shared_ptr<Widget> ptr1 = std::make_shared<Widget>();
    {
        std::shared_ptr<Widget> ptr2 = ptr1; // 引用计数 +1
        std::cout << "引用计数: " << ptr1.use_count() << "\\n"; // 2
    } // ptr2 销毁，引用计数 -1
    
    std::cout << "引用计数: " << ptr1.use_count() << "\\n"; // 1
} // Widget 在此处被销毁
```

### std::weak_ptr：弱引用

`weak_ptr` 是一种**不控制对象生命周期**的智能指针。它指向一个由 `shared_ptr` 管理的对象，但不会增加引用计数。它主要用于解决 **循环引用** 问题：

```cpp
#include <memory>
#include <iostream>

class B; // 前向声明

class A {
public:
    std::shared_ptr<B> b_ptr;
    ~A() { std::cout << "A 析构\\n"; }
};

class B {
public:
    // 使用 weak_ptr 避免循环引用
    std::weak_ptr<A> a_ptr;
    ~B() { std::cout << "B 析构\\n"; }
};

void weakPtrDemo() {
    {
        std::shared_ptr<A> a = std::make_shared<A>();
        std::shared_ptr<B> b = std::make_shared<B>();
        
        a->b_ptr = b;
        b->a_ptr = a; // weak_ptr，不增加引用计数
        
        // 检查对象是否还存在
        if (auto shared = b->a_ptr.lock()) {
            std::cout << "A 仍然存在\\n";
        }
    } // A 和 B 都被正确析构
}
```

## 智能指针对比

| 特性 | `unique_ptr` | `shared_ptr` | `weak_ptr` |
|------|-------------|-------------|-----------|
| 所有权 | 独占 | 共享 | 无（弱引用） |
| 引用计数 | 无 | 有 | 无 |
| 可拷贝 | ❌ | ✅ | ✅ |
| 可移动 | ✅ | ✅ | ✅ |
| 内存开销 | 最小 | 引用计数 + 控制块 | 最小 |
| 适用场景 | 独占资源 | 共享资源 | 打破循环引用 |

## RAII 在标准库中的应用

C++ 标准库大量使用了 RAII 原则：

```cpp
// 容器
std::vector<int> vec = {1, 2, 3}; // 自动管理内存

// 锁
std::mutex mtx;
{
    std::lock_guard<std::mutex> lock(mtx); // 自动加锁
    // 临界区...
} // 自动解锁

// 文件流
{
    std::ofstream file("data.txt");
    file << "Hello, RAII!";
} // 自动关闭文件

// 线程
{
    std::thread t([]() {
        std::cout << "后台任务\\n";
    });
    t.join(); // 或者使用 RAII 包装器
}
```

## 总结

现代 C++ 的内存管理已经不再是噩梦。通过遵循以下原则，你可以写出既高效又安全的代码：

1. **优先使用智能指针**：`unique_ptr` > `shared_ptr` > 原始指针
2. **遵循零法则**：使用标准库工具管理资源
3. **使用 `std::make_unique` 和 `std::make_shared`**：异常安全且高效
4. **理解所有权语义**：明确谁拥有资源，谁只是借用
5. **注意循环引用**：使用 `weak_ptr` 打破循环

> **C++ 之父的名言**："C++ 中，资源管理即对象管理。" —— Bjarne Stroustrup

## 自定义删除器与资源管理扩展

智能指针的强大之处在于可以自定义删除器，从而管理各种类型的资源，而不仅限于堆内存。

### unique_ptr 自定义删除器

```cpp
#include <memory>
#include <iostream>
#include <cstdio>

// 自定义删除器：关闭文件句柄
struct FileDeleter {
    void operator()(FILE* file) const {
        if (file) {
            std::cout << "关闭文件\n";
            std::fclose(file);
        }
    }
};

// 使用自定义删除器的 unique_ptr
using FilePtr = std::unique_ptr<FILE, FileDeleter>;

FilePtr openFile(const char* filename, const char* mode) {
    return FilePtr(std::fopen(filename, mode));
}

// Lambda 删除器
void lambdaDeleterDemo() {
    // 使用 lambda 作为删除器
    auto socketDeleter = [](int* socket) {
        if (socket && *socket >= 0) {
            std::cout << "关闭 socket: " << *socket << "\n";
            close(*socket);
            delete socket;
        }
    };
    
    std::unique_ptr<int, decltype(socketDeleter)> 
        socket(new int(42), socketDeleter);
}
```

### 管理数组资源

```cpp
#include <memory>

void arrayManagement() {
    // 管理动态数组
    std::unique_ptr<int[]> arr(new int[100]);
    
    // 使用 make_unique 创建数组（C++14）
    auto arr2 = std::make_unique<int[]>(100);
    
    // 自定义数组删除器
    struct ArrayDeleter {
        void operator()(int* p) const {
            std::cout << "释放数组\n";
            delete[] p;
        }
    };
    
    std::unique_ptr<int, ArrayDeleter> customArr(new int[50]);
}
```

### 管理非内存资源

```cpp
#include <memory>
#include <pthread.h>

// 管理 POSIX 线程
struct ThreadDeleter {
    void operator()(pthread_t* thread) const {
        pthread_cancel(*thread);
        delete thread;
    }
};

using ThreadPtr = std::unique_ptr<pthread_t, ThreadDeleter>;

// 管理内存映射
struct MMapDeleter {
    size_t length;
    
    void operator()(void* addr) const {
        munmap(addr, length);
    }
};

using MMapPtr = std::unique_ptr<void, MMapDeleter>;
```

## 智能指针与多线程

### shared_ptr 的线程安全性

`shared_ptr` 的引用计数操作是线程安全的，但对象本身的访问不是：

```cpp
#include <memory>
#include <thread>
#include <vector>
#include <iostream>
#include <mutex>

struct Data {
    int value = 0;
    std::mutex mtx;
    
    void increment() {
        std::lock_guard<std::mutex> lock(mtx);
        ++value;
    }
};

void threadSafeSharedPtr() {
    auto data = std::make_shared<Data>();
    std::vector<std::thread> threads;
    
    // 多个线程可以安全地复制 shared_ptr
    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([data]() {
            // 引用计数自动同步
            auto local = data; // 线程安全
            
            for (int j = 0; j < 100; ++j) {
                local->increment(); // 需要显式同步
            }
        });
    }
    
    for (auto& t : threads) {
        t.join();
    }
    
    std::cout << "最终值: " << data->value << "\n"; // 1000
}
```

### atomic_shared_ptr（C++20）

C++20 引入了 `std::atomic<std::shared_ptr<T>>`，允许原子地操作 shared_ptr 本身：

```cpp
#include <memory>
#include <atomic>

void atomicSharedPtrDemo() {
    std::shared_ptr<int> ptr = std::make_shared<int>(42);
    std::atomic<std::shared_ptr<int>> atomic_ptr(ptr);
    
    // 原子地加载
    auto loaded = atomic_ptr.load();
    
    // 原子地交换
    auto new_ptr = std::make_shared<int>(100);
    auto old = atomic_ptr.exchange(new_ptr);
    
    // 比较并交换（CAS）
    std::shared_ptr<int> expected = loaded;
    bool success = atomic_ptr.compare_exchange_strong(
        expected, new_ptr
    );
}
```

## 性能优化与最佳实践

### make_shared vs 直接构造

```cpp
#include <memory>

struct Expensive {
    Expensive() { /* 复杂初始化 */ }
};

void constructionComparison() {
    // 方式1：直接构造（两次分配）
    // 1. 分配 Expensive 对象
    // 2. 分配控制块
    std::shared_ptr<Expensive> p1(new Expensive());
    
    // 方式2：make_shared（一次分配）✅ 推荐
    // 对象和控制块在一个内存块中
    auto p2 = std::make_shared<Expensive>();
    
    // 优势：
    // - 更好的缓存局部性
    // - 更少的内存分配开销
    // - 异常安全
    
    // 注意：make_shared 不能配合自定义删除器
    // 此时需要使用构造函数版本
}
```

### 避免 shared_ptr 的性能陷阱

| 陷阱 | 影响 | 解决方案 |
|------|------|---------|
| 循环引用 | 内存泄漏 | 使用 weak_ptr |
| 过度使用 | 引用计数开销 | 优先使用 unique_ptr |
| 从 this 创建 | 双重所有权 | 使用 enable_shared_from_this |
| 跨 DLL 边界 | 析构问题 | 使用工厂函数 |

```cpp
#include <memory>

// enable_shared_from_this 示例
class Node : public std::enable_shared_from_this<Node> {
public:
    std::shared_ptr<Node> getShared() {
        // 安全地从 this 创建 shared_ptr
        return shared_from_this();
    }
    
    void unsafe() {
        // 错误：创建新的控制块
        // std::shared_ptr<Node> bad(this);
    }
};

void enableSharedDemo() {
    auto node = std::make_shared<Node>();
    auto another = node->getShared();
    
    // 引用计数为 2
    std::cout << node.use_count() << "\n"; // 2
}
```

### 移动语义与智能指针

```cpp
#include <memory>
#include <vector>

std::unique_ptr<int> createResource() {
    return std::make_unique<int>(42);
}

void moveSemantics() {
    // 使用移动避免拷贝
    std::vector<std::unique_ptr<int>> resources;
    
    for (int i = 0; i < 1000; ++i) {
        resources.push_back(createResource());
    }
    
    // 转移所有权
    auto resource = std::move(resources[0]);
    // resources[0] 现在为空
    
    // 安全地移除元素
    resources.erase(
        std::remove_if(resources.begin(), resources.end(),
            [](const auto& ptr) { return !ptr; }),
        resources.end()
    );
}
```

| 场景 | 推荐做法 | 原因 |
|------|---------|------|
| 工厂函数 | 返回 unique_ptr | 所有权转移，零开销 |
| 容器存储 | unique_ptr + 移动 | 避免拷贝，保持唯一所有权 |
| 共享配置 | shared_ptr | 多个对象引用同一配置 |
| 缓存对象 | weak_ptr | 允许对象被回收 |
| PIMPL 惯用法 | unique_ptr | 隐藏实现细节 |

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day'
) ON CONFLICT DO NOTHING;
