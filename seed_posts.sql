-- 种子数据：高质量测试文章
-- 共 17 篇技术文章，覆盖 15+ 种编程语言

-- 先创建测试用户（如果不存在）
INSERT INTO users (username, email, password_hash, role)
SELECT 'testuser', 'test@example.com', '$argon2id$v=19$m=65536,t=3,p=4$testtesttesttesttesttesttest$testtesttesttesttesttesttesttesttesttest', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE role = 'admin');

-- 插入测试文章
INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Rust 所有权与生命周期：深入理解内存安全',
    'rust-ownership-lifetime',
    '本文深入探讨 Rust 的所有权系统、借用规则和生命周期注解，帮助你理解 Rust 如何在不使用垃圾回收器的情况下保证内存安全。',
    $doc$
# Rust 所有权与生命周期：深入理解内存安全

Rust 是一门专注于安全、并发和性能的系统级编程语言。自 2010 年 Mozilla 研究院发起以来，Rust 凭借其独特的内存安全保证机制，逐渐在系统编程领域占据重要地位。与 C/C++ 等语言不同，Rust 不需要依赖垃圾回收器（Garbage Collector），而是在编译期通过**所有权系统**（Ownership System）来确保内存安全。这一设计使得 Rust 程序既拥有接近 C 语言的性能，又避免了手动内存管理带来的种种安全隐患。

本文将系统性地介绍 Rust 的所有权、借用和生命周期三大核心概念，帮助你建立对 Rust 内存模型的深入理解。

## 为什么需要所有权？

在传统的系统编程语言中，内存管理通常面临两种选择：手动管理（如 C/C++）或自动垃圾回收（如 Java、Go）。手动管理虽然性能优秀，但容易引发内存泄漏、悬垂指针、双重释放等严重问题；垃圾回收虽然安全，但会带来运行时开销和不可预测的暂停时间。

Rust 提出了第三种方案：**在编译期通过所有权规则静态验证内存访问的安全性**。这意味着所有内存安全检查都在编译阶段完成，运行时几乎零开销。

## 所有权的三条基本规则

Rust 的所有权系统建立在三条简单但强大的规则之上：

1. **每个值在任意时刻都有且仅有一个所有者（owner）**
2. **当所有者离开作用域时，其拥有的值会被自动释放**
3. **所有权可以通过移动（move）或复制（copy）在不同变量之间转移**

### 所有权转移示例

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1; // s1 的所有权转移给 s2
    
    // println!("{}", s1); // 编译错误！s1 已无效
    println!("{}", s2); // 正确，s2 拥有该字符串
}
```

在上述代码中，`String::from("hello")` 在堆上分配了一块内存。当执行 `let s2 = s1` 时，Rust 执行的是**移动语义**（move semantics）—— `s1` 将堆内存的所有权转移给 `s2`，之后 `s1` 不再有效。这种设计避免了双重释放问题。

### Copy trait 与 Clone trait

并非所有类型都会执行移动语义。对于栈上分配的简单类型（如整数、浮点数、布尔值等），Rust 会自动实现 `Copy` trait，这意味着赋值时执行的是**按位复制**而非所有权转移：

```rust
fn main() {
    let x = 5;
    let y = x; // i32 实现了 Copy，x 仍然有效
    
    println!("x = {}, y = {}", x, y); // 完全正确
}
```

对于需要深拷贝的复杂类型，可以使用 `clone()` 方法：

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1.clone(); // 显式深拷贝
    
    println!("s1 = {}, s2 = {}", s1, s2); // 两者都有效
}
```

## 借用（Borrowing）：安全地共享数据

虽然所有权转移解决了内存安全问题，但在实际编程中，我们经常需要临时访问某个值而不获取其所有权。Rust 提供了**借用**机制来解决这个问题。

借用分为两种类型：不可变借用和可变借用。

### 不可变借用（Immutable Borrowing）

不可变借用允许你读取数据但不修改它。在同一作用域内，可以创建多个不可变引用：

```rust
fn calculate_length(s: &String) -> usize {
    s.len()
}

fn main() {
    let s = String::from("hello");
    let len = calculate_length(&s); // 传递不可变引用
    
    println!("'{}' 的长度是 {}.", s, len); // s 仍然有效
}
```

`&s` 语法创建了一个指向 `s` 的引用，但不会转移所有权。函数参数 `&String` 表示接受一个不可变引用。当函数返回时，引用被销毁，但原始值 `s` 仍然有效。

### 可变借用（Mutable Borrowing）

当你需要修改借用的数据时，可以使用可变引用：

```rust
fn change(some_string: &mut String) {
    some_string.push_str(", world");
}

fn main() {
    let mut s = String::from("hello");
    change(&mut s);
    println!("{}", s); // 输出: hello, world
}
```

### 借用规则

Rust 的借用检查器强制执行以下规则，这些规则在编译期就能防止数据竞争：

1. **在任意给定时刻，只能有一个可变引用** 或 **任意数量的不可变引用**
2. **引用必须始终有效**（不能指向已释放的内存）

```rust
fn main() {
    let mut s = String::from("hello");
    
    let r1 = &s; // 不可变引用
    let r2 = &s; // 另一个不可变引用（允许）
    // let r3 = &mut s; // 编译错误！不可与可变引用共存
    
    println!("{} and {}", r1, r2);
    
    // r1 和 r2 在此之后不再使用
    let r3 = &mut s; // 现在可以创建可变引用
    r3.push_str("!");
    println!("{}", r3);
}
```

Rust 编译器使用**非词法生命周期**（Non-Lexical Lifetimes, NLL）来精确追踪引用的使用范围，允许在上面的例子中，当 `r1` 和 `r2` 不再被使用时创建 `r3`。

## 生命周期（Lifetime）：引用的有效期

生命周期是 Rust 编译器用来确保引用始终指向有效数据的机制。它们描述了引用在程序执行期间的有效范围。

### 显式生命周期注解

当函数返回引用时，编译器需要知道返回的引用与哪个参数的生命周期相关联：

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let string1 = String::from("long string is long");
    let result;
    {
        let string2 = String::from("xyz");
        result = longest(string1.as_str(), string2.as_str());
        println!("最长字符串是 {}", result); // 正确
    } // string2 在此被释放
    // println!("最长字符串是 {}", result); // 编译错误！result 可能引用 string2
}
```

`'a` 是一个生命周期参数，表示 `x`、`y` 和返回值的生命周期至少是 `'a`。编译器确保返回的引用不会比任何一个输入引用活得更久。

### 结构体中的生命周期

当结构体包含引用字段时，必须为每个引用标注生命周期：

```rust
struct ImportantExcerpt<'a> {
    part: &'a str,
}

impl<'a> ImportantExcerpt<'a> {
    fn level(&self) -> i32 {
        3
    }
    
    fn announce_and_return_part(&self, announcement: &str) -> &str {
        println!("注意：{}", announcement);
        self.part
    }
}

fn main() {
    let novel = String::from("Call me Ishmael. Some years ago...");
    let first_sentence = novel.split('.').next().expect("找不到 '.'");
    let i = ImportantExcerpt {
        part: first_sentence,
    };
    // i 不能比 novel 活得更久
}
```

### 生命周期省略规则

为了减轻开发者的负担，Rust 编译器在某些情况下可以自动推断生命周期：

1. **每个引用参数都有自己的生命周期参数**
2. **如果只有一个输入生命周期参数，该生命周期被赋给所有输出生命周期参数**
3. **如果有多个输入生命周期参数，但其中一个是 `&self` 或 `&mut self`，那么 `self` 的生命周期被赋给所有输出生命周期参数**

```rust
// 以下两个函数签名等价（得益于生命周期省略）
fn first_word(s: &str) -> &str { }
fn first_word<'a>(s: &'a str) -> &'a str { }
```

## 'static 生命周期

`'static` 是 Rust 中最长的生命周期，它表示引用可以存活于整个程序运行期间。字符串字面量默认具有 `'static` 生命周期：

```rust
let s: &'static str = "我拥有 'static 生命周期";
```

需要注意的是，`'static` 并不等同于全局变量或永不释放的内存。它只是表示该引用在程序运行期间始终有效。

## 生命周期与闭包

闭包可以捕获其环境中的变量。Rust 提供了三种捕获方式，对应不同的借用语义：

```rust
fn make_adder(x: i32) -> impl Fn(i32) -> i32 {
    move |y| x + y // move 关键字强制闭包获取所有权
}

fn main() {
    let add_five = make_adder(5);
    println!("{}", add_five(3)); // 输出 8
    println!("{}", add_five(10)); // 输出 15
}
```

使用 `move` 关键字时，闭包会获取捕获变量的所有权，这在需要将闭包返回或传递给其他线程时特别有用。

## 常见陷阱与最佳实践

### 1. 悬垂引用（Dangling References）

Rust 编译器会阻止悬垂引用的产生：

```rust
fn dangle() -> &String { // 编译错误！
    let s = String::from("hello");
    &s // s 在函数结束时被释放
} // 返回的引用指向已释放的内存
```

正确的做法：返回 `String` 本身（转移所有权）或使用 `String` 的切片。

### 2. 内部可变性（Interior Mutability）

有时需要在拥有不可变引用的情况下修改数据。Rust 提供了 `RefCell<T>` 和 `Cell<T>` 等类型来实现**内部可变性**：

```rust
use std::cell::RefCell;

fn main() {
    let data = RefCell::new(5);
    
    {
        let mut borrow = data.borrow_mut();
        *borrow += 1;
    } // 可变借用在此结束
    
    println!("{}", data.borrow()); // 输出 6
}
```

### 3. 智能指针与所有权

Rust 标准库提供了多种智能指针来辅助内存管理：

| 智能指针 | 用途 | 所有权模型 |
|----------|------|-----------|
| `Box<T>` | 堆分配 | 独占所有权 |
| `Rc<T>` | 引用计数 | 共享所有权（单线程） |
| `Arc<T>` | 原子引用计数 | 共享所有权（多线程） |
| `RefCell<T>` | 运行时借用检查 | 内部可变性 |

## 总结

Rust 的所有权系统虽然初学者可能会觉得复杂，但一旦掌握，就能编写出既高效又安全的代码。核心理念可以概括为：**编译器通过所有权、借用和生命周期规则，在编译期验证所有内存访问的安全性**。

| 概念 | 核心作用 | 使用场景 |
|------|---------|---------|
| 所有权 | 管理值的生命周期 | 所有堆分配的数据 |
| 不可变借用 | 安全地读取数据 | 函数参数、迭代器 |
| 可变借用 | 安全地修改数据 | 状态修改、缓冲区操作 |
| 生命周期 | 验证引用的有效性 | 返回引用、结构体包含引用 |
| Copy trait | 自动按位复制 | 栈上的简单类型 |

Rust 的设计哲学是：**将内存安全责任从程序员转移到编译器**。虽然这意味着需要花更多时间学习与编译器"沟通"，但换来的是零成本抽象的内存安全和无与伦比的运行时性能。随着 Rust 在 Linux 内核、Web 浏览器（Firefox）、云计算（AWS、Azure）等领域的广泛应用，掌握 Rust 的所有权系统已经成为现代系统程序员的核心技能之一。

## 所有权与并发安全

Rust 的所有权系统不仅保证了内存安全，还为并发编程提供了编译期保证。通过将所有权规则与并发模型结合，Rust 彻底消除了数据竞争（Data Race）。

### Send 与 Sync trait

Rust 通过两个核心 trait 来标记类型的线程安全性：

| Trait | 含义 | 实现条件 |
|-------|------|---------|
| `Send` | 可以安全地在线程间转移所有权 | 类型不包含线程不安全的共享状态 |
| `Sync` | 可以安全地在多个线程间共享引用 | 类型内部实现了同步机制 |

```rust
use std::thread;

fn main() {
    let data = vec![1, 2, 3, 4, 5];
    
    // Vec<i32> 实现了 Send，可以移动到另一个线程
    let handle = thread::spawn(move || {
        println!("子线程: {:?}", data);
        data.iter().sum::<i32>()
    });
    
    let result = handle.join().unwrap();
    println!("总和: {}", result);
}
```

`move` 关键字强制闭包获取 `data` 的所有权，将其转移到新线程。编译器会验证 `data` 是否实现了 `Send`，否则会产生编译错误。

### 跨线程共享数据

对于需要在多个线程间共享的数据，Rust 提供了多种同步原语：

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    // Arc: 原子引用计数，线程安全的共享所有权
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            // MutexGuard 在离开作用域时自动释放锁
            let mut num = counter.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("结果: {}", *counter.lock().unwrap());
}
```

在这个例子中：
- `Arc<T>` 提供了线程安全的引用计数
- `Mutex<T>` 提供了互斥访问
- 编译器确保你无法在没有锁的情况下访问数据
- 锁的释放由 `MutexGuard` 的 `Drop` 实现自动处理

### 通道（Channel）通信

Rust 的通道基于所有权转移，确保线程间通信的安全：

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel();
    
    thread::spawn(move || {
        let val = String::from("来自子线程的消息");
        tx.send(val).unwrap();
        // val 的所有权已转移，不能再使用
        // println!("{}", val); // 编译错误！
    });
    
    let received = rx.recv().unwrap();
    println!("收到: {}", received);
}
```

## 高级生命周期模式

### 生命周期子类型化

Rust 允许生命周期之间存在子类型关系。较长的生命周期是较短生命周期的子类型：

```rust
fn longer_string<'a, 'b>(x: &'a str, y: &'b str) -> &'a str
where
    'b: 'a, // 'b 的生命周期至少与 'a 一样长
{
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

`'b: 'a` 表示 `'b` 至少和 `'a` 一样长，因此返回 `'a` 是安全的。

### HRTB（高阶 trait bound）

高阶 trait bound 允许生命周期参数被函数本身量化：

```rust
// 接受一个对任意生命周期都有效的闭包
fn process<F>(f: F)
where
    F: for<'a> Fn(&'a str) -> &'a str,
{
    let s1 = String::from("hello");
    let result = f(&s1);
    println!("{}", result);
}
```

这在处理回调函数和泛型代码时特别有用。

### 自我指涉结构体

某些情况下，结构体的字段需要引用同一结构体的其他字段。这在 Rust 中通常需要使用 `Pin` 和自定义类型：

```rust
use std::pin::Pin;

// 使用 rental 或 ouroboros crate 处理自我指涉结构体
// 或者使用索引而非引用

struct Parser<'a> {
    text: String,
    current_token: Option<&'a str>, // 引用 text 字段
}

// 更安全的做法：使用索引
struct SafeParser {
    text: String,
    token_start: usize,
    token_end: usize,
}

impl SafeParser {
    fn current_token(&self) -> &str {
        &self.text[self.token_start..self.token_end]
    }
}
```

## 所有权系统的性能影响

### 零成本抽象

Rust 的所有权系统在运行时没有开销。所有检查都在编译期完成：

```rust
// 所有权转移在编译后变为简单的指针赋值
let s1 = String::from("hello");
let s2 = s1; // 编译后：指针复制，原指针标记为无效

// 借用检查在编译后消失
let len = calculate_length(&s2); // 编译后：普通函数调用
```

### 优化机会

所有权信息帮助编译器进行更多优化：

| 优化类型 | 说明 | 示例 |
|---------|------|------|
| 别名分析 | 知道哪些指针不会别名 | 更激进的指令重排 |
| 消除 null 检查 | Option<T> 编译为可空指针 | 减少分支预测失败 |
| 栈分配优化 | 确定对象不需要逃逸 | 将堆分配转为栈分配 |
| 内联优化 | 所有权转移保证唯一引用 | 更积极的函数内联 |

### 与 C/C++ 的性能对比

| 特性 | C/C++ | Rust |
|------|-------|------|
| 内存安全 | 运行时检查（可选） | 编译期保证（零成本） |
| 并发安全 | 依赖程序员 | 编译期保证 |
| 运行时开销 | 可能使用 GC/RC | 通常无额外开销 |
| 优化信息 | 有限（程序员提供） | 丰富（编译器推断） |

Rust 的设计证明：**安全不需要牺牲性能**。通过将安全检查前移到编译期，Rust 实现了与 C/C++ 相当的运行时性能，同时提供了更强的安全保证。

---

*本文首发于 Yggdrasil 博客，转载请注明出处。*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days'
),
(
    1,
    'Python 装饰器完全指南：从入门到精通',
    'python-decorators-guide',
    '从基础到高级，全面掌握 Python 装饰器的使用方法，包括函数装饰器、类装饰器、参数化装饰器，以及 functools.wraps、lru_cache 等内置装饰器的实战应用。',
    $doc$
# Python 装饰器完全指南：从入门到精通

装饰器（Decorator）是 Python 中最优雅、最强大的特性之一。它本质上是一种**高阶函数**（Higher-Order Function），允许你在不修改原函数源代码的前提下，为函数添加额外的功能。装饰器广泛应用于日志记录、权限验证、缓存、性能监控等场景，是 Python 元编程的核心工具。

本文将从基础概念出发，逐步深入到高级用法，帮助你全面掌握 Python 装饰器。

## 什么是装饰器？

在 Python 中，函数是一等公民（First-Class Citizen），这意味着函数可以像普通变量一样被赋值、传递和返回。装饰器正是利用了这一特性：

> **装饰器是一个接受函数作为参数并返回函数的可调用对象。**

最简单的装饰器形式如下：

```python
def my_decorator(func):
    def wrapper():
        print("🚀 函数调用前")
        func()
        print("✅ 函数调用后")
    return wrapper

@my_decorator
def say_hello():
    print("Hello, World!")

say_hello()
```

输出结果：
```
🚀 函数调用前
Hello, World!
✅ 函数调用后
```

`@my_decorator` 语法糖等价于 `say_hello = my_decorator(say_hello)`，它将 `say_hello` 函数替换为了 `wrapper` 函数。

## 处理带参数的函数

上面的装饰器只能装饰无参数的函数。为了让装饰器更通用，需要使用 `*args` 和 `**kwargs`：

```python
def greeting_decorator(func):
    def wrapper(*args, **kwargs):
        print(f"🎯 正在调用: {func.__name__}")
        result = func(*args, **kwargs)
        print(f"✨ {func.__name__} 调用完成")
        return result
    return wrapper

@greeting_decorator
def greet(name, greeting="Hello"):
    return f"{greeting}, {name}!"

print(greet("Alice"))
print(greet("Bob", greeting="Hi"))
```

输出：
```
🎯 正在调用: greet
✨ greet 调用完成
Hello, Alice!
🎯 正在调用: greet
✨ greet 调用完成
Hi, Bob!
```

## 使用 functools.wraps 保留元数据

使用装饰器后，原函数的元数据（如函数名、文档字符串）会丢失：

```python
print(say_hello.__name__)  # 输出: wrapper，而不是 say_hello
```

为了解决这个问题，Python 标准库提供了 `functools.wraps`：

```python
import functools

def my_decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        """wrapper 的文档"""
        return func(*args, **kwargs)
    return wrapper

@my_decorator
def say_hello():
    """打招呼函数"""
    print("Hello!")

print(say_hello.__name__)  # 输出: say_hello
print(say_hello.__doc__)   # 输出: 打招呼函数
```

**最佳实践**：编写装饰器时务必使用 `@functools.wraps(func)`，这是专业 Python 代码的标志。

## 参数化装饰器

有时装饰器本身需要接收参数。实现参数化装饰器需要嵌套三层函数：

```python
def repeat(num=2):
    """重复执行函数 num 次"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            results = []
            for i in range(num):
                print(f"第 {i + 1} 次执行...")
                result = func(*args, **kwargs)
                results.append(result)
            return results
        return wrapper
    return decorator

@repeat(num=3)
def greet(name):
    return f"Hello, {name}!"

results = greet("Alice")
print(results)
```

输出：
```
第 1 次执行...
第 2 次执行...
第 3 次执行...
['Hello, Alice!', 'Hello, Alice!', 'Hello, Alice!']
```

执行流程：`repeat(num=3)` → 返回 `decorator` → `decorator(greet)` → 返回 `wrapper` → `greet` 被替换为 `wrapper`。

## 类装饰器

除了函数装饰器，Python 还支持**类装饰器**。类装饰器通常用于：

1. 为类添加新方法或属性
2. 修改类的行为
3. 注册类到某个注册表中

### 基础类装饰器

```python
class CountCalls:
    """统计函数被调用的次数"""
    
    def __init__(self, func):
        functools.update_wrapper(self, func)
        self.func = func
        self.num_calls = 0

    def __call__(self, *args, **kwargs):
        self.num_calls += 1
        print(f"[{self.num_calls}] {self.func.__name__} 被调用")
        return self.func(*args, **kwargs)

@CountCalls
def say_whee():
    print("Whee! 🎉")

say_whee()
say_whee()
say_whee()
print(f"总共调用了 {say_whee.num_calls} 次")
```

输出：
```
[1] say_whee 被调用
Whee! 🎉
[2] say_whee 被调用
Whee! 🎉
[3] say_whee 被调用
Whee! 🎉
总共调用了 3 次
```

### 使用类实现带状态装饰器

类装饰器特别适合需要维护状态的场景：

```python
class Cache:
    """简单的缓存装饰器"""
    
    def __init__(self, func):
        functools.update_wrapper(self, func)
        self.func = func
        self.cache = {}

    def __call__(self, *args):
        if args in self.cache:
            print(f"📦 缓存命中: {args}")
            return self.cache[args]
        
        print(f"🔍 计算中: {args}")
        result = self.func(*args)
        self.cache[args] = result
        return result

@Cache
def fibonacci(n):
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

print(f"fib(5) = {fibonacci(5)}")
print(f"fib(5) = {fibonacci(5)}")  # 第二次直接返回缓存
```

## 内置装饰器实战

Python 标准库和 functools 模块提供了多个实用的内置装饰器。

### @property：将方法变为属性

```python
class Circle:
    def __init__(self, radius):
        self._radius = radius

    @property
    def radius(self):
        """获取半径"""
        return self._radius

    @radius.setter
    def radius(self, value):
        """设置半径，支持验证"""
        if value < 0:
            raise ValueError("半径不能为负数")
        self._radius = value

    @property
    def area(self):
        """计算面积"""
        return 3.14159 * self._radius ** 2

c = Circle(5)
print(f"半径: {c.radius}")
print(f"面积: {c.area:.2f}")
c.radius = 10
print(f"新面积: {c.area:.2f}")
```

### @staticmethod 和 @classmethod

```python
class DateUtil:
    @staticmethod
    def is_leap_year(year):
        """判断闰年"""
        return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

    @classmethod
    def from_string(cls, date_str):
        """从字符串创建实例"""
        year, month, day = map(int, date_str.split('-'))
        return cls(year, month, day)

print(DateUtil.is_leap_year(2024))  # True
```

### @functools.lru_cache：自动缓存

```python
from functools import lru_cache

@lru_cache(maxsize=128)
def fibonacci(n):
    """带缓存的斐波那契数列"""
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# 计算第 100 项
print(f"fib(100) = {fibonacci(100)}")
print(f"缓存信息: {fibonacci.cache_info()}")
```

### @functools.singledispatch：函数重载

```python
from functools import singledispatch

@singledispatch
def process(arg):
    """默认实现"""
    raise NotImplementedError(f"不支持类型: {type(arg)}")

@process.register(int)
def _(arg):
    return f"整数: {arg * 2}"

@process.register(str)
def _(arg):
    return f"字符串: {arg.upper()}"

@process.register(list)
def _(arg):
    return f"列表: {len(arg)} 个元素"

print(process(42))           # 整数: 84
print(process("hello"))      # 字符串: HELLO
print(process([1, 2, 3]))    # 列表: 3 个元素
```

## 装饰器组合与顺序

多个装饰器可以叠加使用，执行顺序为**从下往上**：

```python
@decorator_a
@decorator_b
def my_func():
    pass

# 等价于: my_func = decorator_a(decorator_b(my_func))
```

## 实际应用场景

| 场景 | 装饰器实现 | 说明 |
|------|-----------|------|
| 日志记录 | `@log_call` | 记录函数调用参数和返回值 |
| 权限验证 | `@require_login` | 检查用户是否已登录 |
| 性能计时 | `@timer` | 测量函数执行时间 |
| 重试机制 | `@retry(max_attempts=3)` | 失败时自动重试 |
| 限流控制 | `@rate_limit(100)` | 限制每秒调用次数 |
| 输入验证 | `@validate_schema` | 验证函数参数格式 |

## 总结

装饰器是 Python 中最具表现力的特性之一，它让代码更加简洁、可复用和符合 DRY 原则。掌握装饰器需要理解：

1. **函数是一等公民**：函数可以作为参数传递、作为返回值返回
2. **闭包**：装饰器内部函数可以访问外部函数的变量
3. **@语法糖**：`@decorator` 等价于 `func = decorator(func)`
4. **functools.wraps**：保留原函数的元数据
5. **嵌套三层**：实现参数化装饰器需要额外的一层函数

> "Python 的装饰器让代码像诗歌一样优美，但过度使用会让代码变得晦涩难懂。" —— 遵循**显式优于隐式**的原则，在合适的场景使用装饰器，避免过度工程化。

## 装饰器模式的高级实战

### 带状态的装饰器

装饰器不仅可以包装函数，还可以维护状态信息。这在实现计数器、缓存、限流器等场景时非常有用：

```python
import functools
import time
from typing import Callable, Any

class RateLimiter:
    """限流装饰器：限制函数的调用频率"""
    
    def __init__(self, max_calls: int, period: float):
        self.max_calls = max_calls  # 周期内最大调用次数
        self.period = period        # 时间周期（秒）
        self.calls = []             # 记录调用时间戳
        functools.update_wrapper(self, None)
    
    def __call__(self, func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            now = time.time()
            # 清理过期的调用记录
            self.calls = [t for t in self.calls if now - t < self.period]
            
            if len(self.calls) >= self.max_calls:
                raise RuntimeError(f"Rate limit exceeded: {self.max_calls} calls per {self.period}s")
            
            self.calls.append(now)
            return func(*args, **kwargs)
        return wrapper

@RateLimiter(max_calls=3, period=10.0)
def send_notification(user_id: int, message: str) -> str:
    """发送通知（带限流）"""
    return f"通知已发送给用户 {user_id}: {message}"

# 测试限流
for i in range(5):
    try:
        result = send_notification(i, f"消息 {i}")
        print(result)
    except RuntimeError as e:
        print(f"第 {i+1} 次调用失败: {e}")
```

输出结果：
```
通知已发送给用户 0: 消息 0
通知已发送给用户 1: 消息 1
通知已发送给用户 2: 消息 2
第 4 次调用失败: Rate limit exceeded: 3 calls per 10.0s
第 5 次调用失败: Rate limit exceeded: 3 calls per 10.0s
```

### 方法装饰器与描述符协议

在类中装饰方法时，需要特别注意 `self` 参数的绑定问题。Python 的描述符协议（Descriptor Protocol）为此提供了解决方案：

```python
import functools
from typing import Callable

class CachedProperty:
    """实现属性缓存的装饰器（类似 @property + @functools.cached_property）"""
    
    def __init__(self, func: Callable):
        functools.update_wrapper(self, func)
        self.func = func
        self.attr_name = f"_cached_{func.__name__}"
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        
        # 检查缓存是否存在
        if not hasattr(instance, self.attr_name):
            value = self.func(instance)
            setattr(instance, self.attr_name, value)
        
        return getattr(instance, self.attr_name)
    
    def __set__(self, instance, value):
        """允许手动设置缓存值"""
        setattr(instance, self.attr_name, value)
    
    def __delete__(self, instance):
        """允许删除缓存，强制重新计算"""
        if hasattr(instance, self.attr_name):
            delattr(instance, self.attr_name)

class DataProcessor:
    def __init__(self, data: list):
        self.data = data
    
    @CachedProperty
    def statistics(self) -> dict:
        """计算统计信息（只计算一次，结果缓存）"""
        print("📊 正在计算统计信息...")
        import statistics
        return {
            'mean': statistics.mean(self.data),
            'median': statistics.median(self.data),
            'stdev': statistics.stdev(self.data) if len(self.data) > 1 else 0
        }
    
    @CachedProperty
    def sorted_data(self) -> list:
        """排序后的数据（缓存）"""
        print("🔄 正在排序...")
        return sorted(self.data)

# 使用示例
processor = DataProcessor([64, 34, 25, 12, 22, 11, 90])
print("第一次访问 statistics:")
print(processor.statistics)
print("\n第二次访问 statistics（从缓存读取）:")
print(processor.statistics)

# 删除缓存后重新计算
print("\n删除缓存后重新计算:")
del processor.statistics
print(processor.statistics)
```

### 装饰器调试与常见问题

在实际项目中，装饰器可能会带来一些调试上的挑战。以下是常见问题的解决方案：

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 函数元信息丢失 | 包装函数替换了原函数 | 使用 `@functools.wraps` |
| 参数类型注解丢失 | wraps 默认不复制注解 | 使用 `functools.wraps(func, assigned=...)` |
| 装饰器顺序影响结果 | 多个装饰器叠加时执行顺序不同 | 理解装饰器是从下往上执行的 |
| 类装饰器无法访问实例 | 装饰的是类本身，不是实例方法 | 使用描述符协议或元类 |
| 递归函数的装饰器问题 | 装饰后的函数名被替换，递归调用失效 | 确保 wraps 正确复制 `__name__` |

```python
import functools
from typing import Callable

def debug_decorator(func: Callable) -> Callable:
    """调试装饰器：打印函数调用详情"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # 获取函数签名信息
        func_name = func.__name__
        module_name = func.__module__
        
        # 格式化参数
        args_repr = [repr(a) for a in args]
        kwargs_repr = [f"{k}={v!r}" for k, v in kwargs.items()]
        signature = ", ".join(args_repr + kwargs_repr)
        
        print(f"[DEBUG] 调用 {module_name}.{func_name}({signature})")
        
        try:
            result = func(*args, **kwargs)
            print(f"[DEBUG] {func_name} 返回: {result!r}")
            return result
        except Exception as e:
            print(f"[DEBUG] {func_name} 抛出异常: {type(e).__name__}: {e}")
            raise
    
    return wrapper

# 测试调试装饰器
@debug_decorator
def divide(a: float, b: float) -> float:
    """安全除法"""
    if b == 0:
        raise ValueError("除数不能为零")
    return a / b

print(divide(10, 2))
try:
    divide(10, 0)
except ValueError:
    pass
```

## 装饰器设计模式总结

| 模式 | 实现方式 | 适用场景 | 代码复杂度 |
|------|---------|---------|-----------|
| 简单装饰器 | 嵌套函数 | 日志、计时 | ⭐ |
| 参数化装饰器 | 三层嵌套函数 | 缓存配置、重试策略 | ⭐⭐ |
| 类装饰器 | 实现 `__call__` | 需要维护状态 | ⭐⭐ |
| 描述符装饰器 | 实现 `__get__`/`__set__` | 属性缓存 | ⭐⭐⭐ |
| 带状态的装饰器 | 类 + 实例变量 | 限流器、计数器 | ⭐⭐⭐ |
| 方法装饰器 | 描述符协议 | 类方法增强 | ⭐⭐⭐ |

> **最佳实践清单**：
> 1. 始终使用 `@functools.wraps(func)` 保留元数据
> 2. 使用 `*args, **kwargs` 确保装饰器通用性
> 3. 类装饰器优先于复杂的三层函数嵌套
> 4. 在装饰器中处理异常，避免吞掉原始错误
> 5. 为装饰器编写文档字符串，说明其功能和使用场景
> 6. 使用 `typing.Callable` 标注类型，提高代码可读性

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days'
),
(
    1,
    'JavaScript 异步编程完全指南：从回调地狱到 async/await',
    'js-async-programming',
    '深入理解 JavaScript 的异步编程模型，从回调函数到 Promise，再到 async/await 的演变历程，以及事件循环的底层原理。',
    $doc$
# JavaScript 异步编程完全指南：从回调地狱到 async/await

JavaScript 是一门单线程语言，这意味着它一次只能执行一个任务。然而，现代 Web 应用需要处理大量 I/O 操作（如网络请求、文件读写、定时器等），如果采用同步方式处理，整个程序会被阻塞，用户体验极差。为了解决这一问题，JavaScript 采用了**事件驱动、非阻塞 I/O** 的编程模型，并通过**事件循环**（Event Loop）机制实现了异步编程。

本文将带你回顾 JavaScript 异步编程的完整演进历程，从最早的回调函数到现代的 async/await，帮助你建立对 JavaScript 并发模型的系统理解。

## 回调函数：异步编程的起点

在 JavaScript 早期，异步操作主要通过回调函数（Callback）来实现。回调函数是一个被作为参数传递给另一个函数的函数，当异步操作完成时被调用：

```javascript
function fetchData(callback) {
    setTimeout(() => {
        callback("数据加载完成");
    }, 1000);
}

fetchData((data) => {
    console.log(data);
});
```

回调函数简单直观，但存在两个主要问题：

### 1. 回调地狱（Callback Hell）

当多个异步操作需要按顺序执行时，代码会层层嵌套，形成"金字塔型"结构：

```javascript
getUserData(userId, (user) => {
    getOrders(user.id, (orders) => {
        getOrderDetails(orders[0].id, (details) => {
            getProductInfo(details.productId, (product) => {
                console.log(product);
            });
        });
    });
});
```

这种代码难以阅读、维护和调试。每一层嵌套都增加了认知负担，错误处理也变得异常复杂。

### 2. 错误处理困难

回调函数通常采用"错误优先"的约定（Error-First Callback）：

```javascript
fs.readFile('file.txt', (err, data) => {
    if (err) {
        console.error('读取失败:', err);
        return;
    }
    console.log('文件内容:', data);
});
```

虽然这种约定统一了错误处理方式，但在多层嵌套时，错误处理代码会散落在各个层级，导致大量重复和遗漏。

## Promise：优雅的异步解决方案

ES6（2015）引入了 **Promise**，它是对异步操作的一种抽象表示，代表一个尚未完成但预期将来会完成的操作。

### Promise 的基本用法

Promise 有三种状态：
- **Pending（待定）**：初始状态，操作尚未完成
- **Fulfilled（已完成）**：操作成功完成
- **Rejected（已拒绝）**：操作失败

```javascript
const fetchData = () => {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            const success = true;
            if (success) {
                resolve("✅ 数据加载成功");
            } else {
                reject("❌ 数据加载失败");
            }
        }, 1000);
    });
};

fetchData()
    .then(data => {
        console.log(data);
        return "处理后的数据";
    })
    .then(processedData => {
        console.log(processedData);
    })
    .catch(err => {
        console.error("错误:", err);
    })
    .finally(() => {
        console.log("无论成功还是失败，都会执行");
    });
```

### Promise 链式调用

Promise 的最大优势在于支持**链式调用**，解决了回调地狱问题：

```javascript
getUserData(userId)
    .then(user => getOrders(user.id))
    .then(orders => getOrderDetails(orders[0].id))
    .then(details => getProductInfo(details.productId))
    .then(product => console.log(product))
    .catch(err => console.error("出错了:", err));
```

每个 `.then()` 接收前一个 Promise 的返回值，并返回一个新的 Promise，形成清晰的线性流程。

### Promise.all 和 Promise.race

Promise 还提供了组合多个异步操作的方法：

```javascript
// 并行执行多个 Promise，全部完成后返回
const promises = [
    fetchUserData(),
    fetchUserSettings(),
    fetchUserNotifications()
];

Promise.all(promises)
    .then(([user, settings, notifications]) => {
        console.log("所有数据加载完成");
    })
    .catch(err => console.error("任一失败:", err));

// 返回最快完成的 Promise
Promise.race([
    fetchData(),
    new Promise((_, reject) => 
        setTimeout(() => reject("超时"), 5000)
    )
])
    .then(data => console.log(data))
    .catch(err => console.error(err));
```

## Async/Await：异步代码的同步写法

ES2017 引入了 **async/await**，它是 Promise 的语法糖，让异步代码看起来像同步代码一样直观：

```javascript
async function loadUserData(userId) {
    try {
        const user = await getUserData(userId);
        const orders = await getOrders(user.id);
        const details = await getOrderDetails(orders[0].id);
        const product = await getProductInfo(details.productId);
        
        return product;
    } catch (err) {
        console.error("加载用户数据失败:", err);
        throw err;
    } finally {
        console.log("数据加载流程结束");
    }
}

// 调用 async 函数
loadUserData(123)
    .then(product => console.log(product))
    .catch(err => console.error(err));
```

### async/await 的优势

1. **代码更扁平**：消除了 Promise 链的嵌套
2. **错误处理更自然**：使用 `try/catch`，符合同步代码的习惯
3. **调试更方便**：可以在 await 处设置断点
4. **条件语句更直观**：

```javascript
async function fetchData(shouldFetchDetails) {
    const user = await getUserData();
    
    // 条件执行异步操作
    if (shouldFetchDetails) {
        const details = await getDetails(user.id);
        return { user, details };
    }
    
    return { user };
}
```

### 并行执行 await

默认情况下，await 会按顺序执行，但可以通过 `Promise.all` 实现并行：

```javascript
async function loadDashboard() {
    // 串行执行（较慢）
    // const user = await getUserData();
    // const posts = await getPosts();
    // const notifications = await getNotifications();
    
    // 并行执行（更快）
    const [user, posts, notifications] = await Promise.all([
        getUserData(),
        getPosts(),
        getNotifications()
    ]);
    
    return { user, posts, notifications };
}
```

## 事件循环：JavaScript 的并发心脏

要真正理解 JavaScript 的异步机制，必须深入理解**事件循环**（Event Loop）。事件循环是 JavaScript 运行时（如浏览器或 Node.js）的核心机制，负责协调同步代码和异步回调的执行。

### 调用栈（Call Stack）

调用栈是一个后进先出（LIFO）的数据结构，用于追踪程序的执行位置。当函数被调用时，它被压入栈顶；当函数返回时，它从栈顶弹出。

### 任务队列（Task Queue）

异步操作完成后，其回调函数不会立即执行，而是被放入**任务队列**中等待。事件循环不断地检查调用栈是否为空，如果为空，则将任务队列中的第一个任务推入调用栈执行。

### 宏任务与微任务

JavaScript 的任务队列分为两类：

| 类型 | 包含 | 优先级 |
|------|------|--------|
| **宏任务（Macrotask）** | `setTimeout`、`setInterval`、I/O 操作、UI 渲染 | 低 |
| **微任务（Microtask）** | `Promise.then()`、`Promise.catch()`、`MutationObserver`、`queueMicrotask()` | 高 |

**执行规则**：
1. 执行当前宏任务（同步代码）
2. 执行所有微任务（清空微任务队列）
3. 渲染 UI（如果需要）
4. 从宏任务队列取出下一个任务，重复步骤 1

### 经典示例分析

```javascript
console.log("1️⃣ 同步代码");

setTimeout(() => {
    console.log("2️⃣ setTimeout（宏任务）");
}, 0);

Promise.resolve().then(() => {
    console.log("3️⃣ Promise.then（微任务）");
});

console.log("4️⃣ 同步代码结束");
```

输出顺序：
```
1️⃣ 同步代码
4️⃣ 同步代码结束
3️⃣ Promise.then（微任务）
2️⃣ setTimeout（宏任务）
```

**执行流程解析**：
1. `console.log("1️⃣")` 立即执行
2. `setTimeout` 的回调被放入宏任务队列
3. `Promise.resolve().then()` 的回调被放入微任务队列
4. `console.log("4️⃣")` 立即执行
5. 同步代码执行完毕，检查微任务队列，执行 Promise 回调
6. 微任务队列为空，从宏任务队列取出 setTimeout 回调执行

### 更复杂的示例

```javascript
console.log("Start");

setTimeout(() => {
    console.log("Timeout 1");
    Promise.resolve().then(() => {
        console.log("Promise inside timeout");
    });
}, 0);

setTimeout(() => {
    console.log("Timeout 2");
}, 0);

Promise.resolve().then(() => {
    console.log("Promise 1");
}).then(() => {
    console.log("Promise 2");
});

console.log("End");
```

输出：
```
Start
End
Promise 1
Promise 2
Timeout 1
Promise inside timeout
Timeout 2
```

## 现代异步模式

### 1. for-await-of 循环

ES2018 引入了异步迭代器，可以优雅地遍历异步数据源：

```javascript
async function* fetchPages() {
    for (let i = 1; i <= 3; i++) {
        yield await fetch(`/api/page/${i}`).then(r => r.json());
    }
}

(async () => {
    for await (const page of fetchPages()) {
        console.log(page);
    }
})();
```

### 2. AbortController 取消请求

```javascript
const controller = new AbortController();

fetch('/api/data', { signal: controller.signal })
    .then(response => response.json())
    .then(data => console.log(data))
    .catch(err => {
        if (err.name === 'AbortError') {
            console.log('请求已被取消');
        }
    });

// 5 秒后取消请求
setTimeout(() => controller.abort(), 5000);
```

### 3. Top-level await（ES2022）

```javascript
// 模块顶层直接使用 await
const data = await fetch('/api/config').then(r => r.json());
export { data };
```

## 总结

JavaScript 的异步编程经历了从回调到 Promise，再到 async/await 的演变，每一步都让代码更加优雅和易于维护。

| 机制 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| 回调函数 | 简单直观 | 回调地狱、错误处理困难 | 简单的异步操作 |
| Promise | 链式调用、组合方便 | 仍有一定嵌套 | 多步骤异步流程 |
| async/await | 同步写法、易调试 | 需要理解底层 Promise | 复杂异步逻辑 |

**关键要点**：
- 微任务优先级高于宏任务
- `await` 后面的代码会被放入微任务队列
- 使用 `Promise.all` 并行执行多个异步操作
- 始终使用 `try/catch` 处理 async/await 中的错误

> 深入理解事件循环是掌握 JavaScript 异步编程的关键。推荐阅读：[MDN - 使用 Promises](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Guide/Using_promises)

## 异步编程高级模式

### 1. Promise 并发控制

在实际开发中，我们经常需要控制并发请求的数量，避免同时发送过多请求导致服务器压力过大或浏览器限制：

```javascript
/**
 * 并发控制函数
 * @param {Function[]} tasks - 返回 Promise 的函数数组
 * @param {number} concurrency - 最大并发数
 */
async function asyncPool(tasks, concurrency = 3) {
    const results = [];
    const executing = [];
    
    for (const [index, task] of tasks.entries()) {
        const promise = task().then(result => ({ result, index }));
        results.push(promise);
        
        if (tasks.length >= concurrency) {
            const completed = promise.then(() => executing.splice(executing.indexOf(promise), 1));
            executing.push(completed);
            
            if (executing.length >= concurrency) {
                await Promise.race(executing);
            }
        }
    }
    
    // 等待所有任务完成并返回按顺序的结果
    const settled = await Promise.all(results);
    return settled.map(({ result }) => result);
}

// 使用示例：同时下载多张图片，最多3个并发
const imageUrls = [
    'https://example.com/img1.jpg',
    'https://example.com/img2.jpg',
    'https://example.com/img3.jpg',
    'https://example.com/img4.jpg',
    'https://example.com/img5.jpg'
];

const downloadTasks = imageUrls.map(url => 
    () => fetch(url).then(r => r.blob())
);

asyncPool(downloadTasks, 3)
    .then(blobs => console.log(`下载完成: ${blobs.length} 张图片`))
    .catch(err => console.error('下载失败:', err));
```

### 2. 异步任务队列

对于需要按顺序执行的异步任务，可以实现一个任务队列：

```javascript
class AsyncQueue {
    constructor() {
        this.tasks = [];
        this.running = false;
    }
    
    add(task, priority = 0) {
        this.tasks.push({ task, priority });
        this.tasks.sort((a, b) => b.priority - a.priority);
        this.run();
    }
    
    async run() {
        if (this.running) return;
        this.running = true;
        
        while (this.tasks.length > 0) {
            const { task } = this.tasks.shift();
            try {
                await task();
            } catch (error) {
                console.error('任务执行失败:', error);
            }
        }
        
        this.running = false;
    }
    
    clear() {
        this.tasks = [];
    }
}

// 使用示例
const queue = new AsyncQueue();

queue.add(async () => {
    await new Promise(resolve => setTimeout(resolve, 1000));
    console.log('✅ 任务1完成（高优先级）');
}, 2);

queue.add(async () => {
    await new Promise(resolve => setTimeout(resolve, 500));
    console.log('✅ 任务2完成');
}, 1);

queue.add(async () => {
    await new Promise(resolve => setTimeout(resolve, 200));
    console.log('✅ 任务3完成（低优先级）');
}, 0);
```

### 3. 异步错误处理与重试机制

健壮的错误处理是异步编程的重要组成部分：

```javascript
/**
 * 带重试机制的异步函数包装器
 */
async function withRetry(asyncFn, options = {}) {
    const {
        maxAttempts = 3,
        delay = 1000,
        backoff = 2,
        onRetry = null
    } = options;
    
    let lastError;
    
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            return await asyncFn();
        } catch (error) {
            lastError = error;
            
            if (attempt === maxAttempts) {
                throw new Error(
                    `在 ${maxAttempts} 次尝试后仍然失败: ${error.message}`
                );
            }
            
            const waitTime = delay * Math.pow(backoff, attempt - 1);
            
            if (onRetry) {
                onRetry(attempt, waitTime, error);
            }
            
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }
    
    throw lastError;
}

// 使用示例
async function fetchWithRetry(url) {
    return withRetry(
        () => fetch(url).then(r => {
            if (!r.ok) throw new Error(`HTTP ${r.status}`);
            return r.json();
        }),
        {
            maxAttempts: 3,
            delay: 1000,
            backoff: 2,
            onRetry: (attempt, waitTime, error) => {
                console.log(`⚠️ 第 ${attempt} 次尝试失败，${waitTime}ms 后重试: ${error.message}`);
            }
        }
    );
}

fetchWithRetry('https://api.example.com/data')
    .then(data => console.log('数据:', data))
    .catch(err => console.error('最终失败:', err));
```

## 现代异步编程最佳实践

| 场景 | 推荐方案 | 避免使用 | 原因 |
|------|---------|---------|------|
| 并行执行独立任务 | `Promise.all()` | 多个 `await` 串行 | 提高性能，减少等待时间 |
| 错误处理 | `try/catch` + `async/await` | `.catch()` 链式调用 | 代码更清晰，类似同步代码 |
| 超时控制 | `Promise.race()` + `AbortController` | `setTimeout` 手动管理 | 更优雅，支持请求取消 |
| 请求取消 | `AbortController` | 自定义标志位 | 标准API，与 `fetch` 集成 |
| 循环中异步 | `for...of` + `await` | `forEach` + `async` | `forEach` 不会等待异步完成 |
| 并发限制 | `asyncPool` 或 `p-limit` | 无限制 `Promise.all` | 防止服务器过载 |

### 循环中的异步操作注意事项

```javascript
// ❌ 错误：forEach 不会等待异步操作完成
const urls = ['/api/1', '/api/2', '/api/3'];
urls.forEach(async (url) => {
    const data = await fetch(url);
    console.log(data);
});
console.log('所有请求完成'); // 这会在请求完成前执行！

// ✅ 正确：使用 for...of 循环
async function fetchAllUrls(urls) {
    const results = [];
    for (const url of urls) {
        const response = await fetch(url);
        results.push(await response.json());
    }
    console.log('所有请求完成:', results);
    return results;
}

// ✅ 正确：使用 Promise.all 并行处理
async function fetchAllUrlsParallel(urls) {
    const promises = urls.map(url => fetch(url).then(r => r.json()));
    const results = await Promise.all(promises);
    console.log('所有请求完成:', results);
    return results;
}
```

### 内存管理与泄漏预防

异步编程中容易出现内存泄漏，特别是在使用闭包和事件监听器时：

```javascript
class EventEmitter {
    constructor() {
        this.listeners = new Map();
    }
    
    on(event, callback) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, new Set());
        }
        this.listeners.get(event).add(callback);
        
        // 返回取消订阅函数
        return () => {
            this.listeners.get(event)?.delete(callback);
        };
    }
    
    emit(event, data) {
        this.listeners.get(event)?.forEach(callback => {
            try {
                callback(data);
            } catch (error) {
                console.error('事件处理错误:', error);
            }
        });
    }
    
    removeAllListeners(event) {
        this.listeners.delete(event);
    }
}

// 使用示例：确保清理事件监听器
class DataLoader {
    constructor() {
        this.emitter = new EventEmitter();
        this.abortController = new AbortController();
    }
    
    async loadData(url) {
        try {
            const response = await fetch(url, {
                signal: this.abortController.signal
            });
            const data = await response.json();
            this.emitter.emit('dataLoaded', data);
            return data;
        } catch (error) {
            if (error.name === 'AbortError') {
                console.log('请求已取消');
            } else {
                this.emitter.emit('error', error);
                throw error;
            }
        }
    }
    
    cancel() {
        this.abortController.abort();
        this.abortController = new AbortController();
    }
    
    destroy() {
        this.cancel();
        this.emitter.removeAllListeners();
    }
}
```

> **异步编程黄金法则**：始终处理错误，始终考虑取消机制，始终注意内存泄漏，始终优先使用标准 API。

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days'
),
(
    1,
    'Go 并发模式完全指南：Goroutine、Channel 与 Select',
    'go-concurrency-patterns',
    'Go 语言以简洁的并发模型著称，本文详细介绍 goroutine、channel、select 和各种并发设计模式，帮助你写出高性能的并发程序。',
    $doc$
# Go 并发模式完全指南：Goroutine、Channel 与 Select

Go 语言自 2009 年发布以来，凭借其**简洁、高效、原生支持并发**的特性，迅速成为云原生时代的首选语言之一。Docker、Kubernetes、Prometheus 等知名项目均使用 Go 编写。Go 语言最引人注目的特性之一，就是其内置的轻量级线程 **goroutine** 和通信原语 **channel**，它们让并发编程变得简单而优雅。

与操作系统线程（通常占用数 MB 内存）不同，goroutine 的初始栈仅有 **2KB**，并且可以根据需要动态增长和收缩。这意味着在单个 Go 程序中可以轻松创建数十万个 goroutine，而不会耗尽系统资源。

本文将系统介绍 Go 的并发原语和常见并发模式，帮助你写出高效、健壮的并发程序。

## Goroutine：轻量级并发单元

在 Go 中，启动一个并发任务只需在函数调用前加上 `go` 关键字：

```go
package main

import (
    "fmt"
    "time"
)

func say(s string, times int) {
    for i := 0; i < times; i++ {
        time.Sleep(100 * time.Millisecond)
        fmt.Printf("%s (第 %d 次)\\n", s, i+1)
    }
}

func main() {
    // 启动两个 goroutine 并发执行
    go say("🌏 world", 3)
    go say("👋 hello", 3)
    
    // 主 goroutine 等待一段时间，让子 goroutine 完成
    time.Sleep(1 * time.Second)
    fmt.Println("主程序结束")
}
```

输出（顺序可能不同）：
```
👋 hello (第 1 次)
🌏 world (第 1 次)
🌏 world (第 2 次)
👋 hello (第 2 次)
👋 hello (第 3 次)
🌏 world (第 3 次)
主程序结束
```

### 使用 WaitGroup 等待 goroutine 完成

上面的示例使用了 `time.Sleep` 来等待 goroutine，这种方式不够精确。Go 提供了 `sync.WaitGroup` 来优雅地等待一组 goroutine 完成：

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func worker(id int, wg *sync.WaitGroup) {
    defer wg.Done() // 完成时减少计数器
    
    fmt.Printf("🚀 Worker %d 开始工作\\n", id)
    time.Sleep(time.Second)
    fmt.Printf("✅ Worker %d 完成工作\\n", id)
}

func main() {
    var wg sync.WaitGroup
    
    for i := 1; i <= 3; i++ {
        wg.Add(1) // 增加计数器
        go worker(i, &wg)
    }
    
    wg.Wait() // 等待所有 goroutine 完成
    fmt.Println("所有工作已完成")
}
```

## Channel：goroutine 之间的通信桥梁

Go 语言的设计哲学是：**不要通过共享内存来通信，而要通过通信来共享内存**（Do not communicate by sharing memory; instead, share memory by communicating.）。Channel 正是这一哲学的核心实现。

Channel 是一种类型安全的队列，用于在 goroutine 之间传递数据。

### 创建 Channel

```go
// 无缓冲 channel（同步通信）
ch := make(chan int)

// 有缓冲 channel（异步通信，容量为 5）
ch := make(chan int, 5)
```

### 无缓冲 Channel

无缓冲 channel 在发送和接收时会阻塞，直到对方准备好：

```go
package main

import "fmt"

func main() {
    ch := make(chan string)
    
    go func() {
        fmt.Println("📤 发送消息...")
        ch <- "Hello from goroutine!"
        fmt.Println("📤 发送完成")
    }()
    
    msg := <-ch // 阻塞等待接收
    fmt.Println("📨 收到:", msg)
}
```

### 有缓冲 Channel

有缓冲 channel 允许在阻塞前发送指定数量的数据：

```go
package main

import "fmt"

func main() {
    ch := make(chan int, 3)
    
    // 发送数据（不会阻塞，因为缓冲区未满）
    ch <- 1
    ch <- 2
    ch <- 3
    
    // ch <- 4 // 如果取消注释，此行会阻塞，因为缓冲区已满
    
    // 接收数据
    fmt.Println(<-ch) // 1
    fmt.Println(<-ch) // 2
    fmt.Println(<-ch) // 3
}
```

### 关闭 Channel

当发送方不再发送数据时，应该关闭 channel：

```go
package main

import "fmt"

func producer(ch chan<- int) {
    for i := 0; i < 5; i++ {
        ch <- i
    }
    close(ch) // 关闭 channel
}

func main() {
    ch := make(chan int)
    go producer(ch)
    
    // 使用 range 遍历 channel，自动检测关闭
    for value := range ch {
        fmt.Printf("收到: %d\\n", value)
    }
    fmt.Println("Channel 已关闭")
}
```

### 单向 Channel

Go 支持单向 channel 类型，用于限制 channel 的使用方向：

```go
func producer(ch chan<- int) { // 只发送
    ch <- 42
}

func consumer(ch <-chan int) { // 只接收
    fmt.Println(<-ch)
}
```

## Select：多路复用

`select` 语句是 Go 并发编程的瑞士军刀，它允许你同时等待多个 channel 操作，类似于网络编程中的 `select()` 系统调用：

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    ch1 := make(chan string)
    ch2 := make(chan string)
    
    go func() {
        time.Sleep(1 * time.Second)
        ch1 <- "来自 channel 1"
    }()
    
    go func() {
        time.Sleep(2 * time.Second)
        ch2 <- "来自 channel 2"
    }()
    
    // 等待两个 channel 中的任意一个
    select {
    case msg1 := <-ch1:
        fmt.Println(msg1)
    case msg2 := <-ch2:
        fmt.Println(msg2)
    }
}
```

### 超时处理

```go
select {
case res := <-c1:
    fmt.Println("结果:", res)
case <-time.After(1 * time.Second):
    fmt.Println("⏰ 超时！")
}
```

### 非阻塞操作

```go
select {
case ch <- value:
    fmt.Println("发送成功")
default:
    fmt.Println("channel 已满，跳过")
}
```

### 随机选择

当多个 case 同时就绪时，select 会**随机**选择一个执行：

```go
ch := make(chan int, 2)
ch <- 1
ch <- 2

select {
case <-ch:
    fmt.Println("收到数据 1")
case <-ch:
    fmt.Println("收到数据 2")
}
// 随机输出其中一个
```

## 常见并发模式

### 1. 生产者-消费者模式

```go
package main

import (
    "fmt"
    "time"
)

func producer(id int, ch chan<- int) {
    for i := 0; i < 3; i++ {
        item := id*10 + i
        fmt.Printf("🏭 生产者 %d 生产: %d\\n", id, item)
        ch <- item
        time.Sleep(100 * time.Millisecond)
    }
}

func consumer(id int, ch <-chan int) {
    for item := range ch {
        fmt.Printf("🛒 消费者 %d 消费: %d\\n", id, item)
        time.Sleep(200 * time.Millisecond)
    }
}

func main() {
    ch := make(chan int, 5)
    
    // 启动 2 个生产者
    for i := 1; i <= 2; i++ {
        go producer(i, ch)
    }
    
    // 启动 3 个消费者
    for i := 1; i <= 3; i++ {
        go consumer(i, ch)
    }
    
    time.Sleep(3 * time.Second)
    close(ch)
    time.Sleep(1 * time.Second)
}
```

### 2. Worker Pool（工作池）

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func worker(id int, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs {
        fmt.Printf("👷 Worker %d 处理任务 %d\\n", id, job)
        time.Sleep(time.Second) // 模拟工作
        results <- job * 2
    }
}

func main() {
    const numJobs = 10
    const numWorkers = 3
    
    jobs := make(chan int, numJobs)
    results := make(chan int, numJobs)
    
    var wg sync.WaitGroup
    for w := 1; w <= numWorkers; w++ {
        wg.Add(1)
        go worker(w, jobs, results, &wg)
    }
    
    for j := 1; j <= numJobs; j++ {
        jobs <- j
    }
    close(jobs)
    
    wg.Wait()
    close(results)
    
    for result := range results {
        fmt.Printf("📊 结果: %d\\n", result)
    }
}
```

### 3. Pipeline（管道）

```go
package main

import "fmt"

func gen(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        for _, n := range nums {
            out <- n
        }
        close(out)
    }()
    return out
}

func sq(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for n := range in {
            out <- n * n
        }
        close(out)
    }()
    return out
}

func main() {
    // 设置 pipeline: gen -> sq
    for result := range sq(sq(gen(2, 3, 4))) {
        fmt.Println(result) // 16, 81, 256 (先平方再平方)
    }
}
```

### 4. Fan-out/Fan-in（扇出/扇入）

```go
func merge(channels ...<-chan int) <-chan int {
    var wg sync.WaitGroup
    out := make(chan int)
    
    output := func(c <-chan int) {
        defer wg.Done()
        for n := range c {
            out <- n
        }
    }
    
    wg.Add(len(channels))
    for _, c := range channels {
        go output(c)
    }
    
    go func() {
        wg.Wait()
        close(out)
    }()
    
    return out
}
```

## Context：请求级控制

Go 1.7 引入了 `context` 包，用于在 goroutine 之间传递截止时间、取消信号和请求范围的值：

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func slowOperation(ctx context.Context) (string, error) {
    select {
    case <-time.After(2 * time.Second):
        return "✅ 操作完成", nil
    case <-ctx.Done():
        return "", ctx.Err()
    }
}

func main() {
    // 设置 1 秒超时
    ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
    defer cancel()
    
    result, err := slowOperation(ctx)
    if err != nil {
        fmt.Println("❌ 错误:", err) // context deadline exceeded
        return
    }
    fmt.Println(result)
}
```

### Context 链式传递

```go
func main() {
    ctx := context.Background()
    
    // 添加超时
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    // 添加取消信号
    ctx, cancel = context.WithCancel(ctx)
    defer cancel()
    
    // 添加请求 ID
    ctx = context.WithValue(ctx, "requestID", "abc-123")
    
    processRequest(ctx)
}
```

## 并发模式对比

| 模式 | 描述 | 使用场景 | 关键原语 |
|------|------|---------|---------|
| 生产者-消费者 | 通过 channel 传递数据 | 任务队列、消息处理 | `chan`, `range` |
| Worker Pool | 固定数量的 worker 处理任务 | CPU 密集型任务 | `sync.WaitGroup` |
| Pipeline | 多个 stage 串联处理 | 数据流处理 | `chan` 返回 |
| Fan-out | 多路分发 | 并行处理 | 多个 goroutine |
| Fan-in | 多路合并 | 聚合结果 | `select`, `sync.WaitGroup` |
| 超时控制 | 限制操作时间 | 网络请求、外部调用 | `context`, `time.After` |

## 总结

Go 的并发模型以其简洁和高效著称。核心要点：

1. **Goroutine** 是轻量级线程，通过 `go` 关键字启动
2. **Channel** 是 goroutine 之间的通信方式，而不是共享内存
3. **Select** 实现多路复用和超时控制
4. **Context** 管理请求级的生命周期
5. **Sync 包** 提供了锁、WaitGroup、Once、Pool 等同步原语

> **Go 并发黄金法则**：先通过 channel 思考，只有在必要时才使用共享内存和锁。

## Sync 包高级原语

除了 channel 之外，Go 的 `sync` 包还提供了一系列强大的同步原语，用于更细粒度的并发控制。

### Mutex 与 RWMutex

当多个 goroutine 需要访问共享资源时，互斥锁是最直接的同步方式：

```go
package main

import (
    "fmt"
    "sync"
)

type SafeCounter struct {
    mu    sync.RWMutex
    count int
}

func (c *SafeCounter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

func (c *SafeCounter) Value() int {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.count
}

func main() {
    counter := &SafeCounter{}
    var wg sync.WaitGroup

    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter.Inc()
        }()
    }

    wg.Wait()
    fmt.Printf("最终计数: %d\n", counter.Value())
}
```

| 锁类型 | 特点 | 适用场景 |
|--------|------|----------|
| `sync.Mutex` | 互斥锁，读写都独占 | 写操作频繁 |
| `sync.RWMutex` | 读锁共享，写锁独占 | 读多写少 |
| `atomic` | 硬件级原子操作 | 简单计数器 |

### Once、Pool 与 Cond

```go
package main

import (
    "fmt"
    "sync"
)

// sync.Once 确保某段代码只执行一次
var once sync.Once
var singleton *Config

type Config struct {
    Version string
}

func GetConfig() *Config {
    once.Do(func() {
        singleton = &Config{Version: "1.0.0"}
        fmt.Println("配置初始化完成")
    })
    return singleton
}

// sync.Pool 用于复用临时对象
var bufferPool = sync.Pool{
    New: func() interface{} {
        return make([]byte, 1024)
    },
}

func main() {
    c1 := GetConfig()
    c2 := GetConfig()
    fmt.Println(c1 == c2) // true，只初始化一次

    buf := bufferPool.Get().([]byte)
    defer bufferPool.Put(buf)
}
```

## Go 内存模型与 Happens-Before

理解 Go 的内存模型对于编写正确的并发程序至关重要。Go 的内存模型定义了在哪些情况下一个 goroutine 中对变量的写操作对另一个 goroutine 可见。

### Channel 的 Happens-Before 保证

Go 语言规范为 channel 操作提供了明确的 happens-before 关系：

| Channel 操作 | Happens-Before 关系 |
|--------------|---------------------|
| `ch <- v` | 对 `v` 的写入 happens-before 该发送完成 |
| `v := <-ch` | 从 channel 接收 happens-before 对 `v` 的读取 |
| 关闭 channel | 关闭操作 happens-before 收到零值 |
| 有缓冲 channel | 第 n 次发送 happens-before 第 n 次接收 |

```go
package main

import "fmt"

func main() {
    done := make(chan bool)
    var msg string

    go func() {
        msg = "hello, world"
        done <- true
    }()

    <-done
    // 由于 channel 的 happens-before 保证
    // 这里一定能看到 msg = "hello, world"
    fmt.Println(msg)
}
```

### 其他 Happens-Before 场景

```go
// 1. sync.Once 中的初始化 happens-before 任何调用者看到结果
var once sync.Once
var config map[string]string

once.Do(func() {
    config = loadConfig()
})
// 这里安全读取 config

// 2. sync.WaitGroup 的 Wait 返回 happens-before 所有 Done 调用
wg.Wait()
// 这里可以看到所有 goroutine 的写入

// 3. 创建 goroutine happens-before 该 goroutine 开始执行
go worker()
// worker 中可以看到创建前的所有写入
```

## 并发调试与性能优化

编写并发程序容易，调试并发程序困难。Go 提供了强大的工具来帮助我们排查问题。

### Race Detector

Go 内置的 race detector 可以发现数据竞争：

```bash
# 运行测试时启用 race detector
go test -race ./...

# 运行程序时启用 race detector
go run -race main.go

# 构建时启用
go build -race -o myapp
```

race detector 会在运行时检测多个 goroutine 对同一内存位置的无同步访问，并报告详细的堆栈信息。

### Goroutine Leak 检测

Goroutine 泄漏是常见的并发 Bug，可以使用 `go.uber.org/goleak` 进行检测：

```go
package main

import (
    "testing"
    "go.uber.org/goleak"
)

func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}

func TestMyFunction(t *testing.T) {
    defer goleak.VerifyNone(t)
    
    // 测试代码...
}
```

### 性能分析

```bash
# CPU 分析
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Goroutine 堆栈
curl http://localhost:6060/debug/pprof/goroutine?debug=1

# 阻塞分析
go tool pprof http://localhost:6060/debug/pprof/block
```

| 性能问题 | 检测方法 | 解决方案 |
|----------|----------|----------|
| 数据竞争 | `-race` | Mutex、channel、atomic |
| Goroutine 泄漏 | goleak | 确保所有 goroutine 都能退出 |
| 锁竞争 | block profile | 减小临界区、使用 RWMutex |
| 内存泄漏 | heap profile | 避免闭包捕获大对象 |
| CPU 热点 | CPU profile | 优化算法、减少 channel 操作 |

## 总结

Go 的并发模型以其简洁和高效著称。核心要点：

1. **Goroutine** 是轻量级线程，通过 `go` 关键字启动
2. **Channel** 是 goroutine 之间的通信方式，而不是共享内存
3. **Select** 实现多路复用和超时控制
4. **Context** 管理请求级的生命周期
5. **Sync 包** 提供了锁、WaitGroup、Once、Pool 等同步原语
6. **内存模型** 的 happens-before 关系是正确性基础
7. **Race detector** 和 **pprof** 是并发调试利器

> **Go 并发黄金法则**：先通过 channel 思考，只有在必要时才使用共享内存和锁。

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '4 days'
),
(
    1,
    'TypeScript 高级类型体操：从条件类型到模板字面量',
    'typescript-type-gymnastics',
    '探索 TypeScript 类型系统的极限，从条件类型到映射类型，再到模板字面量类型和类型推断，让你的代码在编译期就获得强大的类型保障。',
    $doc$
# TypeScript 高级类型体操：从条件类型到模板字面量

TypeScript 的类型系统是一门**图灵完备**的语言。这意味着，在理论上，你可以使用 TypeScript 的类型系统来实现任何可计算的程序。虽然我们不建议在真实项目中过度使用复杂的类型体操，但掌握这些高级类型技巧，可以帮助你构建更加健壮、可维护的类型定义，特别是在开发库和框架时。

本文将从基础到高级，系统介绍 TypeScript 的类型系统特性，包括条件类型、映射类型、模板字面量类型、递归类型和类型推断等。

## 为什么需要高级类型？

在日常开发中，基础类型（`string`、`number`、`boolean`）和简单的接口往往已经足够。但在以下场景中，高级类型变得至关重要：

- **开发类型安全的库**：如 Vue、React、Redux 等框架的类型定义
- **编写通用工具函数**：如 lodash 的类型定义
- **实现类型转换**：如将对象的所有属性变为可选或只读
- **约束 API 接口**：确保编译器能够推断出正确的响应类型

## 条件类型（Conditional Types）

条件类型是 TypeScript 2.8 引入的特性，它允许你根据类型关系选择不同的类型：

```typescript
type IsString<T> = T extends string ? true : false;

// 使用示例
type A = IsString<string>;  // true
type B = IsString<number>;  // false
type C = IsString<"hello">; // true（字面量类型也是 string 的子类型）
```

### extends 关键字

在条件类型中，`extends` 表示"是否是...的子类型"：

```typescript
type IsArray<T> = T extends any[] ? true : false;

type D = IsArray<number[]>; // true
type E = IsArray<string>;   // false
```

### infer 关键字：类型推断

`infer` 是 TypeScript 中最强大的关键字之一，它允许你在条件类型中"提取"类型：

```typescript
// 提取数组元素类型
type ElementType<T> = T extends (infer U)[] ? U : never;

type F = ElementType<string[]>; // string
type G = ElementType<number[]>; // number

// 提取函数返回值类型
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

function getUser() {
    return { id: 1, name: "Alice" };
}

type User = ReturnType<typeof getUser>; // { id: number; name: string; }

// 提取 Promise 的解析类型
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

type H = UnwrapPromise<Promise<string>>; // string
```

### 内置条件类型

TypeScript 标准库已经提供了许多基于条件类型的工具类型：

| 类型 | 作用 | 示例 |
|------|------|------|
| `Exclude<T, U>` | 从 T 中排除 U | `Exclude<'a' \| 'b', 'a'>` → `'b'` |
| `Extract<T, U>` | 从 T 中提取 U | `Extract<'a' \| 'b', 'a' \| 'c'>` → `'a'` |
| `NonNullable<T>` | 排除 null 和 undefined | `NonNullable<string \| null>` → `string` |
| `ReturnType<T>` | 获取函数返回类型 | `ReturnType<() => number>` → `number` |
| `Parameters<T>` | 获取函数参数类型 | `Parameters<(a: string) => void>` → `[string]` |
| `InstanceType<T>` | 获取构造函数实例类型 | `InstanceType<typeof Date>` → `Date` |

## 映射类型（Mapped Types）

映射类型允许你基于已有类型创建新类型，通过遍历属性键来转换每个属性：

### 基础映射类型

```typescript
type Readonly<T> = {
    readonly [P in keyof T]: T[P];
};

type Partial<T> = {
    [P in keyof T]?: T[P];
};

type Required<T> = {
    [P in keyof T]-?: T[P]; // -? 移除可选性
};

// 使用示例
interface User {
    name: string;
    age: number;
}

type ReadonlyUser = Readonly<User>;
// { readonly name: string; readonly age: number; }

type PartialUser = Partial<User>;
// { name?: string; age?: number; }
```

### 键重映射（Key Remapping）

TypeScript 4.1 引入了 `as` 关键字，允许在映射类型中重命名键：

```typescript
// 将每个属性名添加 "get" 前缀，类型变为函数
type Getters<T> = {
    [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface Person {
    name: string;
    age: number;
}

type PersonGetters = Getters<Person>;
// { getName: () => string; getAge: () => number; }
```

### 过滤属性

```typescript
// 只保留 string 类型的属性
type StringProperties<T> = {
    [K in keyof T as T[K] extends string ? K : never]: T[K];
};

interface User {
    name: string;
    age: number;
    email: string;
}

type StringUserProps = StringProperties<User>;
// { name: string; email: string; }
```

## 模板字面量类型（Template Literal Types）

TypeScript 4.1 引入了模板字面量类型，它允许你通过字符串字面量类型来构造新类型：

### 基础用法

```typescript
type EventName<T extends string> = `on${Capitalize<T>}`;

type ClickEvent = EventName<"click">;      // "onClick"
type HoverEvent = EventName<"mouseOver">;  // "onMouseOver"
```

### 联合类型的组合

当模板字面量类型与联合类型结合使用时，会产生**笛卡尔积**效果：

```typescript
type Horizontal = "left" | "center" | "right";
type Vertical = "top" | "center" | "bottom";

type Alignment = `${Horizontal}-${Vertical}`;
// "left-top" | "left-center" | "left-bottom" |
// "center-top" | "center-center" | "center-bottom" |
// "right-top" | "right-center" | "right-bottom"
```

### 实际应用：CSS 属性类型

```typescript
type CSSProperty = "margin" | "padding";
type CSSDirection = "top" | "right" | "bottom" | "left";

type CSSKey = `${CSSProperty}${Capitalize<CSSDirection>}` | CSSProperty;
// "margin" | "padding" | "marginTop" | "marginRight" | ...
```

## 递归类型

TypeScript 支持递归类型定义，这在处理嵌套数据结构时非常有用：

```typescript
// 深度只读类型
type DeepReadonly<T> = {
    readonly [P in keyof T]: T[P] extends object
        ? DeepReadonly<T[P]>
        : T[P];
};

interface NestedUser {
    name: string;
    address: {
        city: string;
        coordinates: {
            lat: number;
            lng: number;
        };
    };
}

type DeepReadonlyUser = DeepReadonly<NestedUser>;
// 所有嵌套属性都变为 readonly

// 深度 Partial 类型
type DeepPartial<T> = {
    [P in keyof T]?: T[P] extends object
        ? DeepPartial<T[P]>
        : T[P];
};

// 扁平化对象类型（将嵌套属性用点号连接）
type Flatten<T, Prefix = ""> = {
    [K in keyof T as K extends string
        ? Prefix extends ""
            ? K
            : `${Prefix & string}.${K}`
        : never
    ]: T[K] extends object ? Flatten<T[K], `${Prefix & string}.${K & string}`> : T[K];
};
```

## 类型守卫与类型收窄

TypeScript 的类型系统不仅在编译期工作，还能通过类型守卫在运行时收窄类型：

```typescript
// typeof 类型守卫
function processValue(value: string | number) {
    if (typeof value === "string") {
        // 此分支中 value 的类型为 string
        return value.toUpperCase();
    } else {
        // 此分支中 value 的类型为 number
        return value.toFixed(2);
    }
}

// 自定义类型守卫
type Cat = { kind: "cat"; meow: () => void };
type Dog = { kind: "dog"; bark: () => void };
type Animal = Cat | Dog;

function isCat(animal: Animal): animal is Cat {
    return animal.kind === "cat";
}

function makeSound(animal: Animal) {
    if (isCat(animal)) {
        animal.meow();
    } else {
        animal.bark();
    }
}
```

## 实用类型工具库

基于上述类型特性，你可以构建强大的类型工具库：

```typescript
// 将对象的所有嵌套属性路径提取为联合类型
type Path<T, K extends keyof T = keyof T> = K extends string
    ? T[K] extends object
        ? `${K}` | `${K}.${Path<T[K]>}`
        : `${K}`
    : never;

// 安全的深度属性访问类型
type DeepPick<T, P extends string> = P extends `${infer K}.${infer Rest}`
    ? K extends keyof T
        ? { [key in K]: DeepPick<T[K], Rest> }
        : never
    : P extends keyof T
    ? { [key in P]: T[P] }
    : never;
```

## 总结

TypeScript 的类型系统提供了丰富的工具来构建类型安全的应用程序：

| 特性 | 版本 | 作用 |
|------|------|------|
| 条件类型 | 2.8 | 基于类型关系选择类型 |
| infer | 2.8 | 在条件类型中提取类型 |
| 映射类型 | 2.1 | 遍历属性键转换类型 |
| 模板字面量 | 4.1 | 构造字符串字面量类型 |
| 键重映射 | 4.1 | 在映射中重命名属性键 |
| 递归类型 | 3.7+ | 处理嵌套数据结构 |

> ⚠️ **温馨提示**：类型体操虽有趣，但过度使用会降低代码可读性和编译性能。遵循"简单优于复杂"的原则，在合适的场景使用高级类型。对于大多数业务代码，基础类型和简单的接口已经足够。

## 类型挑战与实战

学习类型体操的最佳方式是通过实战挑战。以下是几个常见的类型编程问题及其解决方案：

### 挑战 1：实现 DeepPick

实现一个深度选择类型，可以从嵌套对象中按路径提取子集：

```typescript
type DeepPick<T, K extends string> = K extends `${infer First}.${infer Rest}`
    ? First extends keyof T
        ? { [P in First]: DeepPick<T[First], Rest> }
        : never
    : K extends keyof T
    ? { [P in K]: T[P] }
    : never;

// 使用示例
interface Company {
    name: string;
    address: {
        city: string;
        country: {
            code: string;
            name: string;
        };
    };
}

type CompanyNameAndCity = DeepPick<Company, "name" | "address.city">;
// { name: string; address: { city: string; } }
```

### 挑战 2：实现 UnionToTuple

将联合类型转换为元组类型（保留顺序）：

```typescript
type UnionToIntersection<U> = (U extends any ? (x: U) => void : never) extends (x: infer I) => void ? I : never;

type LastInUnion<U> = UnionToIntersection<U extends any ? (x: U) => void : never> extends (x: infer L) => void ? L : never;

type UnionToTuple<U, Last = LastInUnion<U>> = [U] extends [never] ? [] : [...UnionToTuple<Exclude<U, Last>>, Last];

// 使用示例
type Result = UnionToTuple<'a' | 'b' | 'c'>;
// ['a', 'b', 'c']（顺序可能因实现而异）
```

### 挑战 3：实现 AllKeys

获取对象所有层级的键的联合类型：

```typescript
type AllKeys<T> = T extends object
    ? keyof T extends infer K
        ? K extends string
            ? K | AllKeys<T[K]>
            : never
        : never
    : never;

interface Nested {
    a: { b: { c: string } };
    d: number;
}

type Keys = AllKeys<Nested>; // "a" | "b" | "c" | "d"
```

| 挑战 | 核心概念 | 难度 |
|------|---------|------|
| DeepPick | 条件类型 + 递归 + 模板字面量 | ⭐⭐⭐ |
| UnionToTuple | 逆变 + 交叉类型 + 递归 | ⭐⭐⭐⭐ |
| AllKeys | 递归 + keyof + 联合类型分发 | ⭐⭐⭐ |

## 类型安全的路由与 API

在实际项目中，类型体操最常见的应用场景之一是构建类型安全的路由系统和 API 客户端。

### 类型安全的路由参数

```typescript
// 定义路由参数映射
type RouteParams = {
    '/users/:id': { id: string };
    '/users/:id/posts/:postId': { id: string; postId: string };
    '/products/:category/:id': { category: string; id: string };
};

// 提取路径参数类型
type ExtractParams<T extends string> = 
    T extends `${infer _}/:${infer Param}/${infer Rest}`
        ? { [K in Param | keyof ExtractParams<`/${Rest}`>]: string }
        : T extends `${infer _}/:${infer Param}`
        ? { [K in Param]: string }
        : {};

// 使用
function navigate<T extends keyof RouteParams>(
    path: T,
    params: RouteParams[T]
): void {
    console.log(`Navigating to ${path} with ${JSON.stringify(params)}`);
}

navigate('/users/:id', { id: '123' }); // ✅
// navigate('/users/:id', { id: 123 }); // ❌ 类型错误
// navigate('/users/:id', { postId: '123' }); // ❌ 类型错误
```

### 类型安全的 API 客户端

```typescript
interface APIEndpoints {
    'GET /users': { response: User[] };
    'GET /users/:id': { params: { id: string }; response: User };
    'POST /users': { body: CreateUserRequest; response: User };
    'DELETE /users/:id': { params: { id: string }; response: void };
}

type Method = 'GET' | 'POST' | 'PUT' | 'DELETE';

type ExtractEndpoint<T> = T extends `${Method} ${infer Path}` ? Path : never;

type APIResponse<T extends keyof APIEndpoints> = APIEndpoints[T]['response'];

async function apiCall<T extends keyof APIEndpoints>(
    endpoint: T,
    ...args: APIEndpoints[T] extends { params: infer P }
        ? [P]
        : APIEndpoints[T] extends { body: infer B }
        ? [B]
        : []
): Promise<APIResponse<T>> {
    // 实现...
    return fetch(endpoint).then(r => r.json());
}

// 使用
const users = await apiCall('GET /users'); // User[]
const user = await apiCall('GET /users/:id', { id: '123' }); // User
```

## 编译性能优化

复杂的类型体操虽然强大，但可能导致编译时间显著增加。以下是一些优化建议：

### 1. 避免深层嵌套

```typescript
// ❌ 编译器需要递归多层
type BadExample<T> = T extends object
    ? { [K in keyof T]: BadExample<T[K]> extends object ? BadExample<BadExample<T[K]>> : T[K] }
    : T;

// ✅ 限制递归深度
type GoodExample<T, Depth extends number = 5> = 
    Depth extends 0
        ? T
        : T extends object
        ? { [K in keyof T]: GoodExample<T[K], Prev<Depth>> }
        : T;

type Prev<N extends number> = [never, 0, 1, 2, 3, 4, 5][N];
```

### 2. 使用接口而非类型别名

```typescript
// ✅ 接口支持声明合并，编译器优化更好
interface User {
    name: string;
    age: number;
}

// ❌ 复杂的类型别名会增加编译负担
type ComplexUser = {
    [K in 'name' | 'age' | 'email']: K extends 'name' ? string : K extends 'age' ? number : string;
};
```

### 3. 延迟类型计算

```typescript
// ✅ 使用接口延迟类型计算
type Lazy<T> = T extends infer U ? { [K in keyof U]: U[K] } : never;

// 只有在实际使用时才展开类型
type ComplexType = Lazy<SomeDeepNesting>;
```

| 优化策略 | 效果 | 适用场景 |
|---------|------|---------|
| 限制递归深度 | 显著减少编译时间 | 递归类型定义 |
| 使用接口 | 更好的类型缓存 | 对象类型定义 |
| 延迟计算 | 按需展开类型 | 复杂工具类型库 |

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
),
(
    1,
    'Java 泛型深度解析：从基础到通配符的PECS原则',
    'java-generics-cheatsheet',
    'Java 泛型是类型安全的基石，本文深入讲解泛型类、泛型方法、通配符及其上界下界，以及PECS原则在实际编程中的应用。',
    $doc$
# Java 泛型深度解析：从基础到通配符的 PECS 原则

Java 泛型（Generics）是自 JDK 5 引入的一项重要特性，它为 Java 语言带来了**编译期类型检查**和**类型安全**的能力。在没有泛型之前，Java 集合只能存储 `Object` 类型，取出数据时需要进行强制类型转换，这不仅繁琐，而且容易在运行时抛出 `ClassCastException`。

本文将从基础概念出发，深入探讨 Java 泛型的核心机制，包括泛型类、泛型方法、通配符、类型擦除，以及实际开发中最常用的 PECS 原则。

## 泛型的基础概念

### 泛型类

泛型类允许你在定义类时使用类型参数，这些类型参数在创建实例时被具体化：

```java
// 定义泛型类
public class Box<T> {
    private T value;
    
    public void set(T value) {
        this.value = value;
    }
    
    public T get() {
        return value;
    }
    
    public static void main(String[] args) {
        // 创建 String 类型的 Box
        Box<String> stringBox = new Box<>();
        stringBox.set("Hello Generics");
        String str = stringBox.get(); // 无需类型转换
        
        // 创建 Integer 类型的 Box
        Box<Integer> intBox = new Box<>();
        intBox.set(42);
        Integer num = intBox.get();
    }
}
```

### 泛型方法

泛型方法允许你在普通类或泛型类中定义带有类型参数的方法：

```java
public class GenericMethodExample {
    
    // 泛型方法
    public <T> void printArray(T[] array) {
        for (T element : array) {
            System.out.println(element);
        }
    }
    
    // 泛型方法 with 返回值
    public <T> T getFirst(T[] array) {
        return array.length > 0 ? array[0] : null;
    }
    
    // 泛型方法 with 多个类型参数
    public <K, V> void printPair(K key, V value) {
        System.out.println("Key: " + key + ", Value: " + value);
    }
    
    public static void main(String[] args) {
        GenericMethodExample example = new GenericMethodExample();
        
        String[] names = {"Alice", "Bob", "Charlie"};
        example.printArray(names);
        
        Integer first = example.getFirst(new Integer[]{1, 2, 3});
        example.printPair("ID", 1001);
    }
}
```

### 类型参数的约束

你可以使用 `extends` 关键字对类型参数进行约束：

```java
// T 必须是 Number 的子类
public class NumberBox<T extends Number> {
    private T value;
    
    public double getDoubleValue() {
        return value.doubleValue();
    }
}

// 使用
NumberBox<Integer> intBox = new NumberBox<>(); // ✅
NumberBox<Double> doubleBox = new NumberBox<>(); // ✅
// NumberBox<String> stringBox = new NumberBox<>(); // ❌ 编译错误
```

## 通配符（Wildcards）

泛型中的通配符 `?` 表示**未知类型**，它提供了更灵活的类型兼容性。

### 无界通配符 `?`

```java
public void printList(List<?> list) {
    for (Object obj : list) {
        System.out.println(obj);
    }
}

// 可以接受任何类型的 List
printList(new ArrayList<String>());
printList(new ArrayList<Integer>());
```

### 上界通配符 `? extends T`

`? extends T` 表示**T 的子类型**，适用于读取数据的场景：

```java
// 可以接受 Number 及其子类型的 List
public double sumNumbers(List<? extends Number> numbers) {
    double sum = 0;
    for (Number num : numbers) {
        sum += num.doubleValue();
    }
    return sum;
}

// 使用
List<Integer> ints = Arrays.asList(1, 2, 3);
List<Double> doubles = Arrays.asList(1.1, 2.2, 3.3);

sumNumbers(ints);    // ✅ Integer 是 Number 的子类
sumNumbers(doubles); // ✅ Double 是 Number 的子类
```

### 下界通配符 `? super T`

`? super T` 表示**T 的父类型**，适用于写入数据的场景：

```java
// 可以接受 Integer 及其父类型的 List
public void addIntegers(List<? super Integer> list) {
    list.add(1);
    list.add(2);
    list.add(3);
}

// 使用
List<Number> numbers = new ArrayList<>();
List<Object> objects = new ArrayList<>();

addIntegers(numbers); // ✅ Number 是 Integer 的父类
addIntegers(objects); // ✅ Object 是 Integer 的父类
// addIntegers(new ArrayList<String>()); // ❌ 编译错误
```

## PECS 原则

PECS 是 Java 泛型中最重要也最实用的原则，它是 **Producer-Extends, Consumer-Super** 的缩写：

| 原则 | 含义 | 使用场景 |
|------|------|---------|
| **Producer-Extends** | 如果数据从集合中产出（读取），使用 `? extends T` | 方法参数用于读取 |
| **Consumer-Super** | 如果数据被消费（写入），使用 `? super T` | 方法参数用于写入 |

### 实际案例：Collections.copy

Java 标准库中的 `Collections.copy` 方法完美诠释了 PECS 原则：

```java
public static <T> void copy(List<? super T> dest, List<? extends T> src) {
    for (int i = 0; i < src.size(); i++) {
        dest.set(i, src.get(i));
    }
}
```

分析：
- `src`（源列表）是**生产者**，从中读取数据，所以用 `? extends T`
- `dest`（目标列表）是**消费者**，向其中写入数据，所以用 `? super T`

### 实战示例

```java
public class PECSExample {
    
    // Producer: 从列表中读取数据
    public static double sumOfList(List<? extends Number> list) {
        double sum = 0.0;
        for (Number n : list) {
            sum += n.doubleValue();
        }
        return sum;
    }
    
    // Consumer: 向列表中写入数据
    public static void addNumbers(List<? super Integer> list) {
        for (int i = 1; i <= 5; i++) {
            list.add(i);
        }
    }
    
    public static void main(String[] args) {
        // Producer 示例
        List<Integer> ints = Arrays.asList(1, 2, 3);
        List<Double> doubles = Arrays.asList(1.1, 2.2, 3.3);
        
        System.out.println(sumOfList(ints));    // 6.0
        System.out.println(sumOfList(doubles)); // 6.6
        
        // Consumer 示例
        List<Number> numbers = new ArrayList<>();
        addNumbers(numbers);
        System.out.println(numbers); // [1, 2, 3, 4, 5]
        
        List<Object> objects = new ArrayList<>();
        addNumbers(objects);
        System.out.println(objects); // [1, 2, 3, 4, 5]
    }
}
```

## 类型擦除（Type Erasure）

Java 泛型采用了**类型擦除**机制来实现向后兼容。在编译期，所有泛型信息都会被擦除，替换为它们的上界（通常是 `Object`）：

```java
// 编译前
List<String> strings = new ArrayList<>();
String s = strings.get(0);

// 编译后（类型擦除）
List strings = new ArrayList();
String s = (String) strings.get(0); // 自动插入类型转换
```

### 类型擦除的影响

1. **不能使用基本类型**：`List<int>` 是错误的，必须使用 `List<Integer>`
2. **运行时类型检查受限**：`instanceof List<String>` 是非法的
3. **不能创建泛型数组**：`new T[10]` 是非法的
4. **可以通过反射绕过泛型检查**：

```java
List<String> strings = new ArrayList<>();
// strings.add(42); // 编译错误

// 但可以通过反射绕过
Method m = strings.getClass().getMethod("add", Object.class);
m.invoke(strings, 42); // 运行时成功添加 Integer！
```

## 泛型与继承

泛型类型之间**不协变**（not covariant）：

```java
List<Object> objects = new ArrayList<String>(); // ❌ 编译错误
```

虽然 `String` 是 `Object` 的子类，但 `List<String>` 并不是 `List<Object>` 的子类。这是为了防止以下运行时错误：

```java
// 假设允许协变
List<String> strings = new ArrayList<>();
List<Object> objects = strings; // 假设可以
objects.add(42); // 向字符串列表中添加整数！
String s = strings.get(0); // ClassCastException！
```

## 总结

Java 泛型是类型安全的基石，掌握它需要理解以下核心概念：

| 概念 | 说明 | 示例 |
|------|------|------|
| 泛型类 | 类级别的类型参数 | `class Box<T>` |
| 泛型方法 | 方法级别的类型参数 | `<T> T method(T arg)` |
| `? extends T` | 上界通配符，用于读取 | `List<? extends Number>` |
| `? super T` | 下界通配符，用于写入 | `List<? super Integer>` |
| PECS | Producer-Extends, Consumer-Super | `copy(dest, src)` |
| 类型擦除 | 编译期擦除泛型信息 | `List<String>` → `List` |

> **最佳实践**：始终遵循 PECS 原则设计 API，使用通配符增加 API 的灵活性，但不要过度使用复杂的泛型嵌套，保持代码的可读性。

## 泛型在集合框架中的深度应用

Java 集合框架是泛型最广泛的应用场景。深入理解集合的泛型设计，有助于你更好地使用和设计泛型 API。

### 集合的泛型层次结构

```java
// 集合框架的核心接口泛型定义
// Collection<E> → List<E> → ArrayList<E>
// Collection<E> → Set<E> → HashSet<E>
// Map<K, V> → HashMap<K, V>

// 示例：泛型集合的正确使用
List<String> names = new ArrayList<>();        // E = String
Set<Integer> uniqueNumbers = new HashSet<>();  // E = Integer
Map<String, Integer> scores = new HashMap<>(); // K = String, V = Integer

// 注意：数组与泛型的区别
List<String>[] arrayOfLists = new List[10]; // 警告：泛型数组创建
arrayOfLists[0] = new ArrayList<String>();
// arrayOfLists[0].add("Hello"); // 可能需要类型转换
```

### 自定义泛型集合

让我们实现一个类型安全的优先队列（最小堆）：

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Comparator;

public class GenericMinHeap<T> {
    private List<T> heap;
    private Comparator<? super T> comparator;
    
    public GenericMinHeap() {
        this.heap = new ArrayList<>();
        this.comparator = null; // 要求 T 实现 Comparable
    }
    
    public GenericMinHeap(Comparator<? super T> comparator) {
        this.heap = new ArrayList<>();
        this.comparator = comparator;
    }
    
    @SuppressWarnings("unchecked")
    private int compare(T a, T b) {
        if (comparator != null) {
            return comparator.compare(a, b);
        }
        return ((Comparable<? super T>) a).compareTo(b);
    }
    
    public void add(T element) {
        heap.add(element);
        siftUp(heap.size() - 1);
    }
    
    public T poll() {
        if (heap.isEmpty()) return null;
        T result = heap.get(0);
        T last = heap.remove(heap.size() - 1);
        if (!heap.isEmpty()) {
            heap.set(0, last);
            siftDown(0);
        }
        return result;
    }
    
    public T peek() {
        return heap.isEmpty() ? null : heap.get(0);
    }
    
    private void siftUp(int index) {
        while (index > 0) {
            int parent = (index - 1) / 2;
            if (compare(heap.get(index), heap.get(parent)) >= 0) break;
            swap(index, parent);
            index = parent;
        }
    }
    
    private void siftDown(int index) {
        int size = heap.size();
        while (true) {
            int left = 2 * index + 1;
            int right = 2 * index + 2;
            int smallest = index;
            
            if (left < size && compare(heap.get(left), heap.get(smallest)) < 0)
                smallest = left;
            if (right < size && compare(heap.get(right), heap.get(smallest)) < 0)
                smallest = right;
            
            if (smallest == index) break;
            swap(index, smallest);
            index = smallest;
        }
    }
    
    private void swap(int i, int j) {
        T temp = heap.get(i);
        heap.set(i, heap.get(j));
        heap.set(j, temp);
    }
    
    public boolean isEmpty() {
        return heap.isEmpty();
    }
    
    public int size() {
        return heap.size();
    }
}

// 使用示例
class Task implements Comparable<Task> {
    String name;
    int priority; // 数字越小优先级越高
    
    Task(String name, int priority) {
        this.name = name;
        this.priority = priority;
    }
    
    @Override
    public int compareTo(Task other) {
        return Integer.compare(this.priority, other.priority);
    }
    
    @Override
    public String toString() {
        return name + "(priority:" + priority + ")";
    }
}

// 使用自定义类型
GenericMinHeap<Task> taskQueue = new GenericMinHeap<>();
taskQueue.add(new Task("紧急修复", 1));
taskQueue.add(new Task("常规更新", 3));
taskQueue.add(new Task("文档编写", 5));

while (!taskQueue.isEmpty()) {
    System.out.println("处理: " + taskQueue.poll());
}
// 输出：紧急修复(priority:1), 常规更新(priority:3), 文档编写(priority:5)
```

## 泛型与函数式编程

Java 8 引入的 Stream API 大量使用了泛型，结合 Lambda 表达式，可以写出非常简洁的代码。

### Stream API 中的泛型

```java
import java.util.*;
import java.util.stream.*;

public class StreamGenerics {
    
    // 泛型方法处理任意类型的 Stream
    public static <T> List<T> filterAndCollect(
            Stream<T> stream, 
            Predicate<? super T> predicate) {
        return stream.filter(predicate)
                     .collect(Collectors.toList());
    }
    
    // 泛型映射
    public static <T, R> List<R> mapToList(
            List<T> list, 
            Function<? super T, ? extends R> mapper) {
        return list.stream()
                   .map(mapper)
                   .collect(Collectors.toList());
    }
    
    // 泛型归约
    public static <T> T reduce(
            List<T> list, 
            T identity, 
            BinaryOperator<T> accumulator) {
        return list.stream().reduce(identity, accumulator);
    }
    
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5);
        
        // 过滤偶数
        List<Integer> evens = filterAndCollect(
            numbers.stream(), 
            n -> n % 2 == 0
        );
        
        // 映射为字符串
        List<String> strings = mapToList(
            numbers, 
            n -> "Number: " + n
        );
        
        // 求和
        Integer sum = reduce(numbers, 0, Integer::sum);
    }
}
```

### 自定义函数式接口

```java
@FunctionalInterface
interface Converter<F, T> {
    T convert(F from);
    
    // 默认方法
    default <V> Converter<F, V> andThen(Converter<? super T, ? extends V> after) {
        return (F f) -> after.convert(convert(f));
    }
}

// 使用
Converter<String, Integer> stringToInt = Integer::parseInt;
Converter<Integer, Double> intToDouble = Integer::doubleValue;
Converter<String, Double> stringToDouble = stringToInt.andThen(intToDouble);

Double result = stringToDouble.convert("42"); // 42.0
```

| 函数式接口 | 泛型签名 | 用途 |
|-----------|---------|------|
| `Function<T, R>` | T → R | 类型转换 |
| `Predicate<T>` | T → boolean | 条件判断 |
| `Consumer<T>` | T → void | 消费数据 |
| `Supplier<T>` | () → T | 提供数据 |
| `BinaryOperator<T>` | (T, T) → T | 二元操作 |

## 实战：类型安全的缓存系统

让我们综合运用泛型知识，实现一个生产级的类型安全缓存系统：

```java
import java.util.*;
import java.util.concurrent.*;
import java.lang.ref.SoftReference;

public class GenericCache<K, V> {
    private final Map<K, CacheEntry<V>> cache;
    private final long defaultTTL; // 默认过期时间（毫秒）
    private final int maxSize;
    
    private static class CacheEntry<V> {
        V value;
        long expiryTime;
        long accessTime;
        
        CacheEntry(V value, long ttl) {
            this.value = value;
            this.expiryTime = System.currentTimeMillis() + ttl;
            this.accessTime = System.currentTimeMillis();
        }
        
        boolean isExpired() {
            return System.currentTimeMillis() > expiryTime;
        }
    }
    
    public GenericCache(int maxSize, long defaultTTL) {
        this.maxSize = maxSize;
        this.defaultTTL = defaultTTL;
        // 使用 LinkedHashMap 实现 LRU
        this.cache = new LinkedHashMap<K, CacheEntry<V>>(16, 0.75f, true) {
            @Override
            protected boolean removeEldestEntry(Map.Entry<K, CacheEntry<V>> eldest) {
                return size() > maxSize;
            }
        };
    }
    
    public synchronized void put(K key, V value) {
        put(key, value, defaultTTL);
    }
    
    public synchronized void put(K key, V value, long ttl) {
        cache.put(key, new CacheEntry<>(value, ttl));
    }
    
    public synchronized V get(K key) {
        CacheEntry<V> entry = cache.get(key);
        if (entry == null) return null;
        
        if (entry.isExpired()) {
            cache.remove(key);
            return null;
        }
        
        entry.accessTime = System.currentTimeMillis();
        return entry.value;
    }
    
    public synchronized boolean containsKey(K key) {
        return get(key) != null;
    }
    
    public synchronized void invalidate(K key) {
        cache.remove(key);
    }
    
    public synchronized void invalidateAll() {
        cache.clear();
    }
    
    public synchronized int size() {
        // 清理过期条目后返回大小
        cleanUp();
        return cache.size();
    }
    
    private void cleanUp() {
        cache.entrySet().removeIf(entry -> entry.getValue().isExpired());
    }
    
    // 批量操作
    public Map<K, V> getAll(Collection<? extends K> keys) {
        Map<K, V> result = new HashMap<>();
        for (K key : keys) {
            V value = get(key);
            if (value != null) {
                result.put(key, value);
            }
        }
        return result;
    }
    
    // 使用 Supplier 实现缓存加载
    public V getOrLoad(K key, Supplier<? extends V> loader) {
        V value = get(key);
        if (value == null) {
            value = loader.get();
            put(key, value);
        }
        return value;
    }
}

// 使用示例
class UserService {
    private final GenericCache<String, User> userCache;
    
    public UserService() {
        this.userCache = new GenericCache<>(1000, 300_000); // 1000条，5分钟过期
    }
    
    public User getUser(String userId) {
        return userCache.getOrLoad(userId, () -> loadFromDatabase(userId));
    }
    
    private User loadFromDatabase(String userId) {
        // 模拟数据库查询
        System.out.println("Loading user from DB: " + userId);
        return new User(userId, "User " + userId);
    }
}

class User {
    String id;
    String name;
    
    User(String id, String name) {
        this.id = id;
        this.name = name;
    }
}
```

这个缓存系统展示了泛型的多个重要应用：
- **类型参数**：`K` 和 `V` 分别表示键和值的类型
- **泛型方法**：`getOrLoad` 使用 `Supplier<? extends V>` 实现延迟加载
- **通配符**：`getAll` 方法接受 `Collection<? extends K>`
- **内部类**：`CacheEntry<V>` 独立于外部类的类型参数

| 特性 | 实现方式 | 优势 |
|------|---------|------|
| 类型安全 | 泛型参数 K, V | 编译期类型检查 |
| LRU 淘汰 | LinkedHashMap | 自动管理内存 |
| 过期策略 | TTL + 定时清理 | 防止脏数据 |
| 懒加载 | Supplier 函数式接口 | 按需加载，减少数据库压力 |

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days'
),
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
),
(
    1,
    'Haskell 纯函数、惰性求值与 Monad：函数式编程的精髓',
    'haskell-pure-functions',
    '深入理解 Haskell 的纯函数、惰性求值、高阶函数和 Monad，探索函数式编程的核心思想。',
    $doc$
# Haskell 纯函数、惰性求值与 Monad：函数式编程的精髓

Haskell 是一门**纯函数式编程语言**，以严格的数学基础和优雅的设计著称。与命令式语言不同，Haskell 强调函数的数学本质：**函数只是从输入到输出的映射**，没有副作用、没有状态变化、没有隐式的执行顺序。这种纯粹性带来了前所未有的代码可预测性和可组合性。

本文将深入探讨 Haskell 的三大核心特性：纯函数、惰性求值和 Monad，帮助你理解函数式编程的精髓。

## 纯函数（Pure Functions）

纯函数是函数式编程的基石。一个函数是纯函数，当且仅当满足两个条件：

1. **引用透明**（Referential Transparency）：对于相同的输入，永远返回相同的输出
2. **无副作用**（No Side Effects）：不修改外部状态，不执行 I/O 操作

### 纯函数示例

```haskell
-- 纯函数：给定输入，总有确定的输出
factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)

-- 另一个纯函数
square :: Num a => a -> a
square x = x * x

-- 纯函数可以安全地被替换为其结果（引用透明）
-- square 5 总是可以被替换为 25
```

### 纯函数的优势

| 特性 | 说明 |
|------|------|
| 可测试性 | 无需模拟外部状态，输入确定即可测试 |
| 可缓存性 | 结果可以被记忆化（memoization） |
| 可并行性 | 无共享状态，天然适合并行计算 |
| 可组合性 | 函数可以像乐高积木一样组合 |

## 高阶函数（Higher-Order Functions）

Haskell 中的函数是一等公民，可以作为参数传递，也可以作为返回值：

```haskell
-- map：对列表每个元素应用函数
map :: (a -> b) -> [a] -> [b]
doubleAll = map (* 2)
-- doubleAll [1, 2, 3] => [2, 4, 6]

-- filter：根据条件过滤列表
filter :: (a -> Bool) -> [a] -> [a]
evens = filter even
-- evens [1..10] => [2, 4, 6, 8, 10]

-- foldl / foldr：列表归约
sumList = foldl (+) 0
-- sumList [1, 2, 3, 4] => 10

-- 函数组合
(.) :: (b -> c) -> (a -> b) -> a -> c
f . g = \\x -> f (g x)

-- 使用函数组合
process = sum . map square . filter even
-- process [1..10] = sum (map square (filter even [1..10]))
```

### 自定义高阶函数

```haskell
-- 将函数应用两次
applyTwice :: (a -> a) -> a -> a
applyTwice f x = f (f x)

-- 使用
applyTwice (+ 3) 10  -- 16
applyTwice reverse [1, 2, 3]  -- [1, 2, 3]

-- 柯里化（Currying）
add :: Int -> Int -> Int
add x y = x + y

-- add 5 是一个接收 Int 返回 Int 的函数
addFive = add 5
addFive 3  -- 8
```

## 惰性求值（Lazy Evaluation）

Haskell 默认采用**惰性求值**（Lazy Evaluation），也称为**按需调用**（Call by Need）。这意味着表达式在真正需要其值时才会被计算。

### 无限列表

惰性求值最惊人的特性之一，就是可以定义**无限数据结构**：

```haskell
-- 无限自然数列表
nats :: [Integer]
nats = [0..]

-- 无限偶数列表
evens :: [Integer]
evens = [0, 2..]

-- 无限斐波那契数列
fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

-- 使用 take 只取有限部分
main = do
    print $ take 10 nats       -- [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    print $ take 10 evens      -- [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
    print $ take 15 fibs       -- [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377]
```

### 列表推导式

Haskell 的列表推导式（List Comprehension）是处理集合的强大工具：

```haskell
-- 基本列表推导式
squares = [x^2 | x <- [1..10]]
-- [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

-- 带过滤条件
evenSquares = [x^2 | x <- [1..20], even x]
-- [4, 16, 36, 64, 100, 144, 196, 256, 324, 400]

-- 多生成器
pairs = [(x, y) | x <- [1..3], y <- ['a', 'b']]
-- [(1,'a'), (1,'b'), (2,'a'), (2,'b'), (3,'a'), (3,'b')]

-- 使用 let 绑定
result = [let y = x * 2 in (x, y) | x <- [1..5]]
-- [(1,2), (2,4), (3,6), (4,8), (5,10)]
```

### 惰性求值的实际应用

```haskell
-- 只计算需要的部分
firstEvenSquareOver100 = head [x^2 | x <- [1..], even x, x^2 > 100]
-- 结果为 144（12^2），不需要计算 [1..] 的所有元素

-- 短路求值
and' :: [Bool] -> Bool
and' = foldr (&&) True
-- and' (False : undefined) => False
-- 不需要计算 undefined，因为第一个 False 已经决定了结果
```

## 类型系统与类型类

Haskell 拥有强大的静态类型系统和类型推断能力：

```haskell
-- 代数数据类型（Algebraic Data Types）
data Shape = Circle Float
           | Rectangle Float Float
           | Triangle Float Float Float
           deriving (Show, Eq)

area :: Shape -> Float
area (Circle r) = pi * r * r
area (Rectangle w h) = w * h
area (Triangle a b c) = 
    let s = (a + b + c) / 2
    in sqrt (s * (s - a) * (s - b) * (s - c))

-- 类型类（Type Classes）
class Describable a where
    describe :: a -> String

instance Describable Shape where
    describe (Circle r) = "半径为 " ++ show r ++ " 的圆"
    describe (Rectangle w h) = show w ++ " x " ++ show h ++ " 的矩形"
```

## Monad：处理副作用的优雅方式

纯函数不能执行 I/O 操作，但程序总要与外界交互。Haskell 使用 **Monad** 来在纯函数式框架内处理副作用。

### Maybe Monad：处理可能失败的计算

```haskell
-- 安全除法
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv a b = Just (a `div` b)

-- 使用 do 语法串联 Maybe 计算
calculate :: Int -> Int -> Int -> Maybe Int
calculate x y z = do
    a <- safeDiv x y    -- 如果失败，整个计算返回 Nothing
    b <- safeDiv a z
    return (b + 1)

-- 示例
calculate 10 2 3  -- Just 2
calculate 10 0 3  -- Nothing
calculate 10 2 0  -- Nothing
```

### IO Monad：处理输入输出

```haskell
-- IO 是一个 Monad，将副作用操作封装起来
greet :: IO ()
greet = do
    putStrLn "请输入你的名字:"
    name <- getLine
    putStrLn $ "你好, " ++ name ++ "!"

-- 使用 >>=（bind）操作符
main :: IO ()
main = putStrLn "Hello" >>= \_ -> putStrLn "World"
```

### 常用 Monad

| Monad | 用途 | 示例 |
|-------|------|------|
| `Maybe` | 可能失败的计算 | `safeDiv`、`lookup` |
| `Either` | 带错误信息的计算 | `parseNumber` |
| `IO` | 输入输出操作 | `readFile`、`putStrLn` |
| `List` | 非确定性计算 | 多个结果 |
| `State` | 状态传递 | 计数器、随机数生成 |
| `Reader` | 环境读取 | 配置读取 |
| `Writer` | 日志记录 | 追踪计算过程 |

## 总结

Haskell 的函数式编程范式带来了全新的编程思维方式：

| 概念 | 核心思想 | 优势 |
|------|---------|------|
| 纯函数 | 无副作用、引用透明 | 可预测、可测试、可并行 |
| 惰性求值 | 按需计算 | 无限数据结构、短路求值 |
| 高阶函数 | 函数作为一等公民 | 强大的组合能力 |
| 类型系统 | 强类型、类型推断 | 编译期捕获错误 |
| Monad | 在纯函数框架内处理副作用 | 优雅的副作用管理 |

> "学习 Haskell 不是为了在工作中使用它，而是为了以全新的方式思考编程。" —— 匿名

## Functor、Applicative 与 Monad 进阶

在理解 Monad 之前，我们需要先了解它的两个重要前身：Functor 和 Applicative。它们共同构成了 Haskell 中处理"上下文中的值"的抽象层次。

### Functor

Functor 表示可以被映射（map）的结构：

```haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b

-- Maybe 是 Functor 的实例
fmap (+1) (Just 5)        -- Just 6
fmap (+1) Nothing         -- Nothing

-- 列表也是 Functor
fmap (*2) [1, 2, 3]       -- [2, 4, 6]
```

### Applicative Functor

Applicative 允许我们将函数也包裹在上下文中：

```haskell
class Functor f => Applicative f where
    pure  :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b

-- 使用 Applicative 组合多个 Maybe 值
addMaybes :: Maybe Int -> Maybe Int -> Maybe Int
addMaybes mx my = (+) <$> mx <*> my

-- 示例
addMaybes (Just 3) (Just 4)   -- Just 7
addMaybes (Just 3) Nothing    -- Nothing

-- 列表作为 Applicative：笛卡尔积
pure (+) <*> [1, 2] <*> [10, 20]
-- [11, 21, 12, 22]
```

### Monad 与 Applicative 的关系

| 抽象 | 能力 | 核心操作 | 典型应用 |
|------|------|----------|----------|
| `Functor` | 应用普通函数到上下文值 | `fmap` | 转换容器内值 |
| `Applicative` | 应用上下文函数到上下文值 | `<*>`, `pure` | 独立计算组合 |
| `Monad` | 后续计算依赖前面结果 | `>>=`, `return` | 链式依赖计算 |

```haskell
-- 使用 liftA2（Applicative）组合独立计算
import Control.Applicative

liftA2 (+) (Just 1) (Just 2)     -- Just 3

-- 使用 >>=（Monad）组合依赖计算
half :: Int -> Maybe Int
half x = if even x then Just (x `div` 2) else Nothing

Just 20 >>= half >>= half   -- Just 5
Just 20 >>= half >>= half >>= half  -- Nothing
```

## Monad 转换器实战

实际项目中 rarely 只使用单一 Monad。Haskell 通过 Monad 转换器（Monad Transformers）来组合多个 Monad 的能力。

### 常见 Monad 转换器

```haskell
import Control.Monad.Trans.Reader
import Control.Monad.Trans.State
import Control.Monad.Trans.Writer
import Control.Monad.Trans.Except
import Control.Monad.Trans.Class (lift)

type App a = ExceptT String (ReaderT Config (StateT AppState IO)) a

-- 简化的组合示例
logAndCount :: WriterT [String] (State Int) ()
logAndCount = do
    lift $ modify (+1)
    n <- lift get
    tell ["Count incremented to: " ++ show n]
    lift $ modify (+1)
    n' <- lift get
    tell ["Count incremented to: " ++ show n']

-- 运行
runState (runWriterT logAndCount) 0
-- 返回 ((), ["Count incremented to: 1", "Count incremented to: 2"], 2)
```

### 构建 Web 应用风格的 Monad 栈

```haskell
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

import Control.Monad.Reader
import Control.Monad.Except
import Control.Monad.IO.Class

data AppConfig = AppConfig {
    dbConnection :: String,
    apiKey       :: String
}

data AppError = NotFound String | ValidationError String | DatabaseError String
    deriving (Show)

newtype AppM a = AppM {
    runAppM :: ReaderT AppConfig (ExceptT AppError IO) a
} deriving (Functor, Applicative, Monad, MonadReader AppConfig, MonadError AppError, MonadIO)

getUserById :: Int -> AppM String
getUserById userId = do
    config <- ask
    when (null (apiKey config)) $
        throwError $ ValidationError "API key is missing"
    if userId > 0
        then return $ "User " ++ show userId
        else throwError $ NotFound $ "User " ++ show userId

-- 运行
main :: IO ()
main = do
    let config = AppConfig "postgres://localhost" "secret-key"
    result <- runExceptT $ runReaderT (runAppM $ getUserById 42) config
    case result of
        Left err  -> putStrLn $ "Error: " ++ show err
        Right val -> putStrLn $ "Success: " ++ val
```

### Monad 转换器选择指南

| 场景 | 基础 Monad | 转换器 | 用途 |
|------|-----------|--------|------|
| 错误处理 | `Either` | `ExceptT` | 统一错误传播 |
| 环境读取 | `Reader` | `ReaderT` | 共享配置、依赖注入 |
| 状态管理 | `State` | `StateT` | 可变状态模拟 |
| 日志记录 | `Writer` | `WriterT` | 累积日志、审计 |
| IO 操作 | `IO` | 作为栈底 | 与外部世界交互 |

## 函数式编程模式

Haskell 丰富的类型系统催生了许多强大的编程模式。

### 递归模式与 Catamorphism

```haskell
-- fold 是列表的 catamorphism
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f z []     = z
foldr f z (x:xs) = f x (foldr f z xs)

-- 用 foldr 实现各种列表操作
sum'     = foldr (+) 0
product' = foldr (*) 1
length'  = foldr (\_ acc -> acc + 1) 0
map' f   = foldr (\x acc -> f x : acc) []
filter' p = foldr (\x acc -> if p x then x : acc else acc) []

-- unfoldr：从种子生成列表
import Data.List
fibonacci :: [Integer]
fibonacci = unfoldr (\(a, b) -> Just (a, (b, a + b))) (0, 1)
-- take 10 fibonacci => [0,1,1,2,3,5,8,13,21,34]
```

### Lens：函数式数据操作

Lens 提供了优雅的不可变数据更新方式：

```haskell
{-# LANGUAGE TemplateHaskell #-}
import Control.Lens

data Address = Address {
    _street :: String,
    _city   :: String,
    _zip    :: String
} deriving (Show)

data Person = Person {
    _name    :: String,
    _age     :: Int,
    _address :: Address
} deriving (Show)

makeLenses ''Address
makeLenses ''Person

-- 使用 Lens 更新嵌套字段
john :: Person
john = Person "John" 30 (Address "123 Main St" "NYC" "10001")

-- 更新年龄
johnAfterBirthday = age +~ 1 $ john
-- Person "John" 31 ...

-- 更新嵌套地址的城市
johnMoved = address . city .~ "Boston" $ john
-- Person "John" 30 (Address "123 Main St" "Boston" "10001")

-- 组合修改
johnUpdated = john 
    & age +~ 1
    & address . city .~ "Boston"
    & address . zip .~ "02101"
```

### 设计模式对比

| 命令式模式 | Haskell 对应 | 说明 |
|-----------|-------------|------|
| Strategy | 高阶函数 | 将行为作为参数传递 |
| Observer | FRP / STM | 响应式编程或软件事务内存 |
| Iterator | 递归 / fold / unfold | 统一遍历模式 |
| Builder | 记录语法 + Monoid | 累积式构造 |
| Singleton | 纯函数 + 缓存 | 不需要传统单例 |
| Factory | 类型类 + 智能构造函数 | 多态创建 |

## 总结

Haskell 的函数式编程范式带来了全新的编程思维方式：

| 概念 | 核心思想 | 优势 |
|------|---------|------|
| 纯函数 | 无副作用、引用透明 | 可预测、可测试、可并行 |
| 惰性求值 | 按需计算 | 无限数据结构、短路求值 |
| 高阶函数 | 函数作为一等公民 | 强大的组合能力 |
| 类型系统 | 强类型、类型推断 | 编译期捕获错误 |
| Monad | 在纯函数框架内处理副作用 | 优雅的副作用管理 |
| Monad 转换器 | 组合多种上下文 | 构建复杂应用架构 |
| Lens | 声明式不可变更新 | 优雅的嵌套数据操作 |

> "学习 Haskell 不是为了在工作中使用它，而是为了以全新的方式思考编程。" —— 匿名

Haskell 可能不是最适合所有场景的语言，但它所倡导的函数式编程思想——不可变性、纯函数、组合——已经深刻影响了现代编程语言的设计。从 JavaScript 的 `map`/`filter`/`reduce`，到 Java 的 Stream API，再到 Rust 的迭代器，函数式编程的思想无处不在。

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '12 hours',
    NOW() - INTERVAL '12 hours',
    NOW() - INTERVAL '12 hours'
),
(
    1,
    'Ruby 元编程：打开动态语言的黑箱',
    'ruby-metaprogramming',
    'Ruby 被誉为"程序员的最好朋友"，其强大的元编程能力让代码更加灵活和富有表现力。本文深入探讨 define_method、method_missing、类_eval、模块混入等核心元编程技术。',
    $doc$
# Ruby 元编程：打开动态语言的黑箱

Ruby 是一门充满魅力的动态语言，Matz（松本行弘）在设计 Ruby 时的理念是：**让编程变得快乐**。这种快乐很大程度上来自于 Ruby 强大的**元编程**（Metaprogramming）能力——即编写能够编写代码的代码。

元编程并非 Ruby 独有，但 Ruby 的元编程能力在众多语言中出类拔萃。Rails 框架的成功很大程度上归功于其巧妙运用元编程实现的"约定优于配置"哲学。

本文将深入探讨 Ruby 元编程的核心技术，帮助你理解这门动态语言的本质。

## 什么是元编程？

元编程是指在运行时创建、修改或分析代码的技术。在 Ruby 中，几乎所有事物都是对象，包括类本身。这意味着你可以像操作普通对象一样操作类——添加方法、修改方法、甚至在运行时创建全新的类。

```ruby
# 类也是对象！
puts String.class      # => Class
puts Class.class       # => Class
puts Object.class      # => Class
```

## 动态方法定义

### define_method

`define_method` 允许在运行时动态定义方法：

```ruby
class Robot
  ACTIONS = [:walk, :run, :jump, :fly]

  ACTIONS.each do |action|
    define_method(action) do |*args|
      speed = args.first || "normal"
      "🤖 Robot is #{action}ing at #{speed} speed!"
    end
  end
end

robot = Robot.new
puts robot.walk         # => 🤖 Robot is walking at normal speed!
puts robot.run("fast")  # => 🤖 Robot is running at fast speed!
puts robot.fly("super") # => 🤖 Robot is flying at super speed!
```

这种技术在框架开发中极为常见。例如，ActiveRecord 的 `find_by_*` 方法就是动态生成的。

### method_missing：拦截不存在的方法

`method_missing` 是 Ruby 元编程中最强大也最危险的工具。当调用一个不存在的方法时，Ruby 会将调用转发给 `method_missing`：

```ruby
class DynamicFinder
  def method_missing(name, *args, &block)
    if name.to_s.start_with?("find_by_")
      attribute = name.to_s.sub("find_by_", "")
      "Looking for record where #{attribute} = #{args.first}"
    else
      super # 如果不是我们处理的格式，交给父类处理
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.start_with?("find_by_") || super
  end
end

finder = DynamicFinder.new
puts finder.find_by_name("Alice")   # => Looking for record where name = Alice
puts finder.find_by_email("a@b.c") # => Looking for record where email = a@b.c
```

### const_missing：动态加载常量

```ruby
module AutoLoader
  def self.const_missing(name)
    file = name.to_s.downcase
    require_relative "./#{file}"
    const_get(name)
  rescue LoadError
    super
  end
end
```

## 打开类（Open Classes）

Ruby 允许随时重新打开已存在的类并添加或修改方法，这被称为**猴子补丁**（Monkey Patching）：

```ruby
class String
  def shout
    upcase + "!!!"
  end

  def reverse_words
    split.reverse.join(" ")
  end

  def to_slug
    downcase.strip.gsub(/\s+/, '-').gsub(/[^\w-]/, '')
  end
end

puts "hello world".shout           # => HELLO WORLD!!!
puts "hello world".reverse_words   # => world hello
puts "Hello World!".to_slug        # => hello-world
```

### 使用 Refinement 安全地扩展

为了避免猴子补丁污染全局命名空间，Ruby 2.0 引入了 **Refinement**：

```ruby
module StringExtensions
  refine String do
    def shout
      upcase + "!!!"
    end
  end
end

class MyApp
  using StringExtensions

  def self.greet(name)
    name.shout
  end
end

puts MyApp.greet("hello")  # => HELLO!!!
puts "hello".shout rescue puts "No method error"  # => No method error
```

## 类_eval 和 instance_eval

Ruby 提供了多种在特定上下文中执行代码的方式：

### class_eval（或 module_eval）

在类的上下文中执行代码，可以访问类的私有方法：

```ruby
class Person
  def initialize(name)
    @name = name
  end
end

# 为 Person 类动态添加方法
Person.class_eval do
  attr_reader :name

  def greet
    "Hello, I'm #{@name}!"
  end

  def self.species
    "Homo sapiens"
  end
end

person = Person.new("Alice")
puts person.name        # => Alice
puts person.greet       # => Hello, I'm Alice!
puts Person.species     # => Homo sapiens
```

### instance_eval

在对象的上下文中执行代码：

```ruby
class Dog
  def initialize(name)
    @name = name
  end
end

dog = Dog.new("Buddy")

dog.instance_eval do
  def bark
    "#{@name} says: Woof!"
  end
end

puts dog.bark  # => Buddy says: Woof!
# 注意：bark 方法只存在于这个实例上，其他 Dog 实例没有
```

### instance_exec（带参数）

```ruby
class Calculator
  def initialize(value)
    @value = value
  end
end

calc = Calculator.new(10)
result = calc.instance_exec(5) do |n|
  @value + n
end
puts result  # => 15
```

## 模块与混入（Mixins）

Ruby 不支持多重继承，但通过模块混入实现了更灵活的功能复用：

```ruby
module Loggable
  def log(message)
    puts "[#{Time.now}] #{self.class}: #{message}"
  end

  def self.included(base)
    puts "#{base} included #{self}"
  end
end

module Validatable
  def validate!
    raise "Invalid!" unless valid?
  end
end

class User
  include Loggable   # 实例方法
  extend Validatable # 类方法

  def valid?
    true
  end
end

user = User.new
user.log("Created")  # => [2024-...] User: Created
```

### prepend：方法前置

Ruby 2.0 引入了 `prepend`，可以将模块的方法插入到类的方法链前面：

```ruby
module Logging
  def save
    puts "Before save..."
    super
    puts "After save..."
  end
end

class Article
  prepend Logging

  def save
    puts "Saving article..."
  end
end

article = Article.new
article.save
# => Before save...
# => Saving article...
# => After save...
```

## 元编程在 Rails 中的应用

Rails 是 Ruby 元编程能力的最佳展示：

```ruby
# ActiveRecord 动态属性访问
user = User.find(1)
user.name           # 动态生成 getter
user.name = "Alice" # 动态生成 setter
user.save           # 动态生成 SQL

# 关联宏
class User < ApplicationRecord
  has_many :posts
  has_many :comments
  belongs_to :company
end

# 这背后使用元编程动态创建了 posts、comments、company 等方法
```

## 元编程最佳实践

| 技术 | 适用场景 | 注意事项 |
|------|---------|---------|
| `define_method` | 批量生成相似方法 | 比 `class_eval` 更清洁 |
| `method_missing` | 实现动态 API | 始终实现 `respond_to_missing?` |
| `class_eval` | 动态修改类 | 会改变类的全局行为 |
| `instance_eval` | DSL 设计 | 注意 `self` 的变化 |
| Refinement | 安全扩展内置类 | 只在 `using` 的作用域内生效 |

## 总结

Ruby 的元编程能力让这门语言充满了表达力和灵活性。通过动态方法定义、方法拦截、类修改和模块混入，你可以写出极其简洁和富有表现力的代码。

但元编程也是一把双刃剑：

- **优点**：代码更 DRY、更表达力、框架更强大
- **缺点**：调试困难、IDE 支持有限、可读性降低

> "Ruby 让编程变得有趣，但元编程让 Ruby 变得强大。" —— 改编自 Matz

在使用元编程时，请始终牢记：**清晰的代码胜过聪明的代码**。元编程应该用来消除重复、提高抽象层次，而不是用来炫耀技巧。

## 元编程中的反射与内省

### 对象的自我认知

Ruby 提供了丰富的反射（Reflection）机制，让对象能够在运行时检查自身的结构和状态：

```ruby
class User
  attr_accessor :name, :age
  
  def initialize(name, age)
    @name = name
    @age = age
  end
  
  def greet
    "Hello, I'm #{@name}!"
  end
  
  private
  
  def secret
    "This is private!"
  end
end

user = User.new("Alice", 30)

# 检查对象的类和方法
puts user.class                    # => User
puts user.is_a?(User)             # => true
puts user.respond_to?(:greet)     # => true
puts user.respond_to?(:secret)    # => false（私有方法默认不可见）
puts user.respond_to?(:secret, true)  # => true（包括私有方法）

# 获取实例变量
puts user.instance_variables      # => [:@name, :@age]
puts user.instance_variable_get(:@name)  # => Alice

# 动态设置实例变量
user.instance_variable_set(:@age, 31)
puts user.age                     # => 31

# 获取方法列表
puts User.instance_methods(false) # => [:name, :name=, :age, :age=, :greet]
puts User.private_instance_methods(false)  # => [:secret]
```

### 代码文档化与元数据

Ruby 的方法可以携带元数据，这在构建 DSL 和文档系统时非常有用：

```ruby
module Documentable
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def document(description, options = {})
      @documents ||= {}
      @documents[@last_defined_method] = {
        description: description,
        options: options,
        timestamp: Time.now
      }
    end
    
    def documents
      @documents || {}
    end
    
    def method_added(name)
      @last_defined_method = name
    end
  end
end

class API
  include Documentable
  
  def get_user(id)
    # 获取用户信息
  end
  document "根据ID获取用户信息", params: [:id], returns: "User"
  
  def create_user(params)
    # 创建用户
  end
  document "创建新用户", params: [:name, :email], returns: "User"
  
  def self.generate_docs
    documents.each do |method_name, info|
      puts "## #{method_name}"
      puts "描述: #{info[:description]}"
      puts "参数: #{info[:options][:params].join(', ')}"
      puts "返回值: #{info[:options][:returns]}"
      puts "定义时间: #{info[:timestamp]}"
      puts "---"
    end
  end
end

API.generate_docs
```

## 构建领域特定语言（DSL）

### 声明式配置 DSL

Ruby 的元编程能力使其成为构建内部 DSL 的理想选择：

```ruby
module Configurable
  def self.included(base)
    base.extend(DSLMethods)
  end
  
  module DSLMethods
    def setting(name, default: nil, type: nil, &validation)
      define_method(name) do
        instance_variable_get("@#{name}") || default
      end
      
      define_method("#{name}=") do |value|
        if type && !value.is_a?(type)
          raise TypeError, "#{name} 必须是 #{type} 类型"
        end
        
        if validation && !instance_exec(value, &validation)
          raise ArgumentError, "#{name} 验证失败"
        end
        
        instance_variable_set("@#{name}", value)
      end
    end
    
    def config(&block)
      define_method(:configure) do
        instance_eval(&block) if block_given?
        self
      end
    end
  end
end

class DatabaseConfig
  include Configurable
  
  setting :host, default: "localhost", type: String
  setting :port, default: 5432, type: Integer do |v|
    v > 0 && v < 65536
  end
  setting :username, default: "admin", type: String
  setting :password, type: String
  
  config do
    # 默认配置
    self.host = "localhost"
    self.port = 5432
  end
  
  def connection_string
    "postgresql://#{username}:#{password}@#{host}:#{port}/database"
  end
end

# 使用 DSL 配置
db = DatabaseConfig.new.configure do
  self.host = "db.example.com"
  self.port = 5432
  self.username = "app_user"
  self.password = "secret123"
end

puts db.connection_string
# => postgresql://app_user:secret123@db.example.com:5432/database
```

### 构建器模式 DSL

```ruby
class HTMLBuilder
  def initialize(&block)
    @content = ""
    instance_eval(&block) if block_given?
  end
  
  def method_missing(tag, *args, &block)
    attributes = args.last.is_a?(Hash) ? args.pop : {}
    text = args.first || ""
    
    attrs = attributes.map { |k, v| " #{k}=\"#{v}\"" }.join
    
    @content << "<#{tag}#{attrs}>"
    @content << text if text
    
    if block_given?
      instance_eval(&block)
    end
    
    @content << "</#{tag}>"
  end
  
  def to_html
    @content
  end
end

# 使用 HTML Builder DSL
html = HTMLBuilder.new do
  html do
    head do
      title "我的页面"
    end
    body class: "container" do
      h1 "欢迎访问"
      p "这是一个动态生成的页面"
      div class: "footer" do
        p "版权所有 © 2024"
      end
    end
  end
end

puts html.to_html
```

## 元编程高级技巧与性能

| 技术 | 性能影响 | 适用场景 | 注意事项 |
|------|---------|---------|---------|
| `define_method` | 方法调用稍慢 | 动态生成方法 | 比 `class_eval` 更清晰 |
| `method_missing` | 显著开销 | 动态 API | 总是实现 `respond_to_missing?` |
| `instance_eval` | 创建闭包 | DSL、上下文切换 | 注意 `self` 的变化 |
| `send` | 正常 | 动态方法调用 | 避免调用私有方法（除非有意） |
| `const_get/set` | 正常 | 动态常量访问 | 谨慎修改常量 |
| 猴子补丁 | 全局影响 | 修复库缺陷 | 使用 Refinement 替代 |

### 元编程性能优化

```ruby
# 使用 method_added 钩子进行性能监控
module PerformanceMonitor
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def method_added(name)
      return if @adding_method
      
      @adding_method = true
      original = instance_method(name)
      
      define_method(name) do |*args, &block|
        start_time = Time.now
        result = original.bind(self).call(*args, &block)
        elapsed = (Time.now - start_time) * 1000
        
        puts "[PERF] #{self.class}##{name} 耗时: #{elapsed.round(2)}ms"
        result
      end
      
      @adding_method = false
    end
  end
end

class DataProcessor
  include PerformanceMonitor
  
  def process_large_dataset(data)
    # 模拟耗时操作
    sleep(0.1)
    data.map { |x| x * 2 }
  end
  
  def filter_data(data, threshold)
    sleep(0.05)
    data.select { |x| x > threshold }
  end
end

processor = DataProcessor.new
processor.process_large_dataset([1, 2, 3, 4, 5])
# 输出: [PERF] DataProcessor#process_large_dataset 耗时: 100.23ms
```

> **元编程的智慧**：元编程应该服务于代码的清晰度和可维护性，而不是为了炫技。当你能用普通方法实现时，优先考虑普通方法；只有在确实需要动态性时，才使用元编程。

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days'
),
(
    1,
    'Zig 显式内存管理与编译期编程：系统级语言的新选择',
    'zig-memory-management',
    'Zig 是一门注重可读性、健壮性和最优性的系统级编程语言。没有隐式内存分配、没有隐藏的控制流，让每一行代码都清晰可控。',
    $doc$
# Zig 显式内存管理与编译期编程：系统级语言的新选择

Zig 是一门相对年轻的系统级编程语言，由 Andrew Kelley 于 2016 年开始开发。它的设计哲学可以概括为：**显式优于隐式**、**可读性优先于奇技淫巧**、**健壮性优先于方便性**。

与 C 语言相比，Zig 提供了更好的安全性、更强大的元编程能力和更友好的构建系统。与 Rust 相比，Zig 更加简单直接，没有复杂的所有权系统，而是通过显式的内存分配和错误处理来保证安全。

本文将深入探讨 Zig 的核心特性，包括显式内存管理、错误处理、编译期编程和 C 互操作性。

## 显式内存分配

Zig 最显著的特点之一是**没有隐式内存分配**。在 Zig 中，所有可能分配内存的操作都必须显式地接收一个分配器参数。

### 基础内存分配

```zig
const std = @import("std");

pub fn main() !void {
    // 创建通用分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 动态分配内存
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);  // 确保内存被释放

    // 使用内存...
    @memcpy(memory, "Hello, Zig!");
    std.debug.print("{s}\n", .{memory});
}
```

### 不同的分配器策略

Zig 标准库提供了多种分配器，适用于不同场景：

| 分配器 | 用途 | 特点 |
|--------|------|------|
| `GeneralPurposeAllocator` | 通用场景 | 安全、支持内存泄漏检测 |
| `PageAllocator` | 大块内存 | 直接向 OS 申请 |
| `FixedBufferAllocator` | 嵌入式/无堆环境 | 使用预分配缓冲区 |
| `ArenaAllocator` | 批量分配/释放 | 一次性释放所有内存 |
| `c_allocator` | C 互操作 | 使用 malloc/free |

```zig
// 使用 Arena 分配器
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const allocator = arena.allocator();

// 分配多个对象
const str1 = try allocator.dupe(u8, "Hello");
const str2 = try allocator.dupe(u8, "World");
// 所有内存会在 arena.deinit() 时一次性释放
```

### 错误处理与内存安全

Zig 的 `try` 关键字确保了错误被传播，而 `defer` 确保了资源被释放，即使在错误路径上：

```zig
fn processData(allocator: std.mem.Allocator, input: []const u8) !void {
    const buffer = try allocator.alloc(u8, input.len * 2);
    defer allocator.free(buffer);  // 无论成功与否都会执行

    if (input.len == 0) {
        return error.EmptyInput;  // buffer 仍会被释放
    }

    // 处理数据...
    @memcpy(buffer[0..input.len], input);
}
```

## 错误处理

Zig 的错误处理机制结合了错误联合类型（Error Union Types）和 `try/catch` 风格：

### 错误联合类型

```zig
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
    NotAFile,
};

fn openFile(path: []const u8) FileOpenError!std.fs.File {
    return std.fs.cwd().openFile(path, .{});
}
```

`FileOpenError!std.fs.File` 表示这个函数要么返回一个错误（`FileOpenError`），要么返回一个文件（`std.fs.File`）。

### try 与 catch

```zig
pub fn main() !void {
    // 使用 try：如果出错，立即返回错误
    const file = try openFile("data.txt");
    defer file.close();

    // 使用 catch：处理特定错误
    const alt_file = openFile("backup.txt") catch |err| {
        std.debug.print("打开备份失败: {}\n", .{err});
        return;
    };
    defer alt_file.close();

    // 使用 catch 提供默认值
    const content = readFile("config.txt") catch "default_config";
}
```

### errdefer

`errdefer` 只在函数返回错误时执行，非常适合错误路径上的清理：

```zig
fn createUser(allocator: std.mem.Allocator, name: []const u8) !User {
    const user_name = try allocator.dupe(u8, name);
    errdefer allocator.free(user_name);  // 只有出错时才释放

    const user_email = try allocator.dupe(u8, "default@example.com");
    errdefer allocator.free(user_email);

    return User{
        .name = user_name,
        .email = user_email,
    };
}
```

## 编译期编程（Comptime）

Zig 的 `comptime` 关键字允许在编译期执行代码，这是 Zig 最强大的特性之一：

### 编译期计算

```zig
fn fibonacci(comptime n: u32) u32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

const fib_10 = comptime fibonacci(10);  // 编译期计算！
```

### 类型作为参数

```zig
fn Vector(comptime T: type, comptime n: comptime_int) type {
    return struct {
        data: [n]T,

        pub fn add(self: @This(), other: @This()) @This() {
            var result: @This() = undefined;
            for (&result.data, self.data, other.data) |*r, a, b| {
                r.* = a + b;
            }
            return result;
        }
    };
}

const Vec3f = Vector(f32, 3);
var v1 = Vec3f{ .data = .{ 1, 2, 3 } };
var v2 = Vec3f{ .data = .{ 4, 5, 6 } };
const v3 = v1.add(v2);
```

### 编译期反射

```zig
fn printStructInfo(comptime T: type) void {
    const info = @typeInfo(T);
    std.debug.print("Type: {s}\n", .{@typeName(T)});

    if (info == .Struct) {
        std.debug.print("Fields:\n");
        inline for (info.Struct.fields) |field| {
            std.debug.print("  {s}: {}\n", .{ field.name, field.type });
        }
    }
}
```

## C 互操作性

Zig 与 C 的互操作性非常出色，可以直接导入 C 头文件并调用 C 函数：

```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

pub fn main() void {
    c.printf("Hello from C!\n");

    const ptr = c.malloc(100);
    defer c.free(ptr);

    // Zig 可以直接处理 C 指针
    const zig_slice = @as([*]u8, @ptrCast(ptr))[0..100];
}
```

## Zig 的哲学

| 原则 | 说明 | 示例 |
|------|------|------|
| **显式优于隐式** | 没有隐式分配、没有隐式转换 | 所有分配器必须显式传递 |
| **无隐藏控制流** | 没有运算符重载、没有隐式析构 | 资源释放用 `defer` |
| **无隐藏分配** | 内存分配一目了然 | `ArrayList` 需要传入分配器 |
| **可读性优先** | 代码应该像散文一样易读 | 简洁的语法，无冗余符号 |
| **与 C 互操作** | 无缝集成现有 C 代码库 | `@cImport` 直接导入头文件 |

## 总结

Zig 是一门为系统编程而生的现代语言，它吸收了 C 的简洁和 Rust 的安全理念，同时保持了自己的独特风格：

1. **显式内存管理**：没有垃圾回收，没有隐式分配
2. **强大的错误处理**：错误联合类型 + try/catch
3. **编译期编程**：`comptime` 提供元编程能力
4. **出色的 C 互操作**：无缝集成现有生态系统
5. **简单直接**：没有复杂的所有权系统，只有清晰的规则

> **Zig 的设计理念**："专注于调试你的应用程序而不是调试你的编程语言知识。"

对于需要高性能、低级别控制、但又不想处理 C 语言种种陷阱的项目，Zig 是一个极具吸引力的选择。

## Zig 的编译期元编程实战

Zig 的 `comptime` 不仅是简单的编译期计算，它是一套完整的元编程系统，可以在编译期执行几乎所有运行时能做的事情。

### 编译期泛型容器

利用 `comptime`，我们可以在编译期生成类型安全的泛型数据结构：

```zig
const std = @import("std");

fn Stack(comptime T: type, comptime capacity: usize) type {
    return struct {
        items: [capacity]T,
        len: usize,
        
        const Self = @This();
        
        pub fn init() Self {
            return .{
                .items = undefined,
                .len = 0,
            };
        }
        
        pub fn push(self: *Self, item: T) !void {
            if (self.len >= capacity) {
                return error.StackOverflow;
            }
            self.items[self.len] = item;
            self.len += 1;
        }
        
        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.items[self.len];
        }
        
        pub fn peek(self: *const Self) ?T {
            if (self.len == 0) return null;
            return self.items[self.len - 1];
        }
        
        pub fn isEmpty(self: *const Self) bool {
            return self.len == 0;
        }
        
        pub fn isFull(self: *const Self) bool {
            return self.len == capacity;
        }
    };
}

pub fn main() !void {
    // 编译期生成不同类型的栈
    var int_stack = Stack(i32, 10).init();
    try int_stack.push(42);
    try int_stack.push(100);
    std.debug.print("弹出: {d}\n", .{int_stack.pop().?});
    
    var float_stack = Stack(f64, 5).init();
    try float_stack.push(3.14);
    std.debug.print("浮点栈: {d}\n", .{float_stack.peek().?});
}
```

### 编译期状态机生成

```zig
const std = @import("std");

const State = enum {
    idle,
    running,
    paused,
    stopped,
};

fn StateMachine(comptime S: type) type {
    const state_info = @typeInfo(S);
    const states = state_info.Enum.fields;
    
    return struct {
        current: S,
        
        const Self = @This();
        
        pub fn init(start: S) Self {
            return .{ .current = start };
        }
        
        pub fn transition(self: *Self, new_state: S) void {
            const old = self.current;
            self.current = new_state;
            std.debug.print("状态转移: {s} -> {s}\n", .{
                @tagName(old), @tagName(new_state)
            });
        }
        
        pub fn getCurrentName(self: *const Self) []const u8 {
            return @tagName(self.current);
        }
    };
}

pub fn main() void {
    var sm = StateMachine(State).init(.idle);
    std.debug.print("初始状态: {s}\n", .{sm.getCurrentName()});
    
    sm.transition(.running);
    sm.transition(.paused);
    sm.transition(.running);
    sm.transition(.stopped);
}
```

## Zig 的构建系统与包管理

Zig 自带强大的构建系统 `zig build`，无需第三方工具如 Make 或 CMake。

### 基础构建配置

```zig
// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // 可执行文件
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    b.installArtifact(exe);
    
    // 运行命令
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "运行应用");
    run_step.dependOn(&run_cmd.step);
    
    // 测试
    const test_step = b.step("test", "运行测试");
    
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
```

### 高级构建功能

| 功能 | 说明 | 示例 |
|------|------|------|
| 条件编译 | 根据目标平台编译不同代码 | `if (target.isWindows())` |
| 自定义步骤 | 添加构建前后的处理 | 代码生成、资源打包 |
| 依赖管理 | 从 Git 或 HTTP 获取依赖 | `b.dependency("package")` |
| 交叉编译 | 为其他平台编译 | `zig build -Dtarget=x86_64-windows` |

```zig
// 条件编译示例
const builtin = @import("builtin");

pub const OS = switch (builtin.target.os.tag) {
    .windows => WindowsOS,
    .linux => LinuxOS,
    .macos => MacOS,
    else => @compileError("不支持的操作系统"),
};

const WindowsOS = struct {
    pub fn init() !OS {
        // Windows 特定初始化
        return .{};
    }
};

const LinuxOS = struct {
    pub fn init() !OS {
        // Linux 特定初始化
        return .{};
    }
};
```

## Zig 的性能分析与优化

Zig 提供了多种工具和技术来分析和优化代码性能。

### 编译期性能优化

```zig
const std = @import("std");

// 使用 comptime 进行查找表生成
const LookupTable = comptime blk: {
    var table: [256]u8 = undefined;
    for (&table, 0..) |*entry, i| {
        entry.* = @intCast((i * 9 + 128) / 256);
    }
    break :blk table;
};

pub fn fastLookup(value: u8) u8 {
    // 编译期生成的查找表，运行时O(1)
    return LookupTable[value];
}

// 编译期字符串处理
fn comptimeFormat(comptime fmt: []const u8, args: anytype) []const u8 {
    return std.fmt.comptimePrint(fmt, args);
}

const greeting = comptimeFormat("Hello, {s}!", .{"Zig"});
```

### 内存布局控制

| 特性 | 说明 | 使用场景 |
|------|------|---------|
| `packed` struct | 无填充的字节对齐 | 硬件寄存器、网络协议 |
| `extern` struct | C 兼容布局 | FFI 接口 |
| `align(n)` | 自定义对齐 | SIMD、DMA 缓冲区 |

```zig
// 精确控制内存布局
const PacketHeader = packed struct {
    version: u4,
    header_length: u4,
    type_of_service: u8,
    total_length: u16,
    identification: u16,
    flags: u3,
    fragment_offset: u13,
    time_to_live: u8,
    protocol: u8,
    checksum: u16,
    source_ip: u32,
    dest_ip: u32,
};

// 确保大小正确
const std = @import("std");
comptime {
    std.debug.assert(@sizeOf(PacketHeader) == 20);
}

// 自定义对齐
const AlignedBuffer = extern struct {
    data: [1024]u8 align(64), // 64字节对齐，适合 SIMD
};
```

### SIMD 与向量化

```zig
const std = @import("std");

pub fn vectorizedAdd(a: []const f32, b: []const f32, result: []f32) void {
    const Vector = @Vector(4, f32);
    
    var i: usize = 0;
    while (i + 4 <= a.len) : (i += 4) {
        const va: Vector = a[i..][0..4].*;
        const vb: Vector = b[i..][0..4].*;
        result[i..][0..4].* = va + vb;
    }
    
    // 处理剩余元素
    while (i < a.len) : (i += 1) {
        result[i] = a[i] + b[i];
    }
}

pub fn main() void {
    var a = [8]f32{1, 2, 3, 4, 5, 6, 7, 8};
    var b = [8]f32{8, 7, 6, 5, 4, 3, 2, 1};
    var result: [8]f32 = undefined;
    
    vectorizedAdd(&a, &b, &result);
    std.debug.print("结果: {any}\n", .{result});
}
```

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '6 hours',
    NOW() - INTERVAL '6 hours',
    NOW() - INTERVAL '6 hours'
),
(
    1,
    'Markdown 语法完全测试：渲染引擎兼容性验证',
    'markdown-syntax-test',
    '一篇专门用于测试博客系统对 Markdown 各种语法元素支持情况的文章，包含文本格式、列表、代码块、表格、数学公式、脚注等完整测试。',
    $doc$
# Markdown 语法完全测试：渲染引擎兼容性验证

这是一篇专门用于测试 Markdown 渲染效果的文章。无论你使用的是 CommonMark、GitHub Flavored Markdown (GFM)、还是其他扩展方言，本文都涵盖了最全面的语法测试用例。

Markdown 的设计目标是**易读易写**，其语法灵感来源于纯文本电子邮件的格式。本文不仅展示各种语法元素，还说明了它们的使用场景和最佳实践。

## 文本格式

Markdown 支持多种内联文本格式：

这是**粗体**（使用 `**` 或 `__` 包裹），这是*斜体*（使用 `*` 或 `_` 包裹），这是***粗斜体***（同时使用两者），这是~~删除线~~（使用 `~~` 包裹），这是`行内代码`（使用反引号包裹）。

### 强调嵌套

你可以嵌套不同的格式：这是**粗体中的_斜体_**，这是*斜体中的**粗体***。

### 转义字符

如果需要显示 Markdown 语法字符本身，可以使用反斜杠转义：\*这不是斜体\*，\`这不是代码\`。

## 标题层级

Markdown 支持六级标题，使用 `#` 的数量表示层级：

### 三级标题

三级标题常用于文章的主要小节。

#### 四级标题

四级标题用于更细分的子节。

##### 五级标题

五级标题用于细节描述。

###### 六级标题

六级标题是最深层级，一般用于列表项内的标题。

## 列表

### 无序列表

无序列表使用 `-`、`+` 或 `*` 作为标记符：

- 第一项：这是列表的第一项
- 第二项：包含子列表
  - 嵌套项 1：使用两个空格缩进
  - 嵌套项 2：可以继续嵌套
    - 更深嵌套：三层缩进
    - 混合使用不同标记符也可以
- 第三项：回到第一层

### 有序列表

有序列表使用数字加句点：

1. 第一步：准备工作
2. 第二步：执行操作
   1. 子步骤 A：检查环境
   2. 子步骤 B：执行命令
3. 第三步：验证结果

### 任务列表

GitHub Flavored Markdown 支持任务列表：

- [x] 已完成任务：设置开发环境
- [x] 已完成任务：编写核心代码
- [ ] 未完成任务：编写单元测试
- [ ] 未完成任务：部署到生产环境
- [x] 已完成任务：编写文档

## 引用块

引用块用于引用他人的话或强调重要内容：

> 这是一段普通的引用块。引用块可以包含多行内容，
> 每一行都以 `>` 开头。
>
> > 这是嵌套引用块。在引用中再引用，形成层级结构。
> > 这在回复邮件或讨论中非常常见。
>
> 回到第一层引用，继续你的论述。

### 引用块中的其他元素

> **注意**：引用块中可以包含其他 Markdown 元素。
>
> - 比如列表项
> - 比如 `行内代码`
> - 比如 [链接](https://example.com)
>
> ```python
> # 甚至可以包含代码块
> print("在引用块中执行代码")
> ```

## 代码块

代码块是技术文章的核心。Markdown 支持多种方式展示代码。

### Python

```python
def hello_world(name: str = "World") -> str:
    """返回问候语。"""
    return f"Hello, {name}!"

class Greeter:
    def __init__(self, greeting: str = "Hello"):
        self.greeting = greeting
    
    def greet(self, name: str) -> str:
        return f"{self.greeting}, {name}!"

if __name__ == "__main__":
    greeter = Greeter("Hi")
    print(greeter.greet("Alice"))
```

### Rust

```rust
fn main() {
    let name = "world";
    println!("Hello, {}!", name);
    
    let numbers = vec![1, 2, 3, 4, 5];
    let sum: i32 = numbers.iter().sum();
    println!("Sum: {}", sum);
}
```

### JavaScript

```javascript
async function fetchUserData(userId) {
    try {
        const response = await fetch(`/api/users/${userId}`);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        console.error("Failed to fetch user:", error);
        throw error;
    }
}
```

### Go

```go
package main

import (
    "fmt"
    "time"
)

func worker(id int, jobs <-chan int, results chan<- int) {
    for j := range jobs {
        fmt.Printf("Worker %d processing job %d\n", id, j)
        time.Sleep(time.Second)
        results <- j * 2
    }
}

func main() {
    jobs := make(chan int, 100)
    results := make(chan int, 100)
    
    for w := 1; w <= 3; w++ {
        go worker(w, jobs, results)
    }
    
    for j := 1; j <= 9; j++ {
        jobs <- j
    }
    close(jobs)
    
    for a := 1; a <= 9; a++ {
        <-results
    }
}
```

### JSON

```json
{
  "project": "Yggdrasil",
  "version": "1.0.0",
  "description": "A modern blog system built with Rust and Dioxus",
  "dependencies": {
    "frontend": "Dioxus 0.7",
    "backend": "tokio-postgres",
    "database": "PostgreSQL 15"
  },
  "features": [
    "Markdown support",
    "Server-side rendering",
    "Real-time preview"
  ]
}
```

### SQL

```sql
-- 获取已发布的文章列表
SELECT 
    p.id,
    p.title,
    p.slug,
    p.summary,
    p.published_at,
    u.username as author
FROM posts p
JOIN users u ON p.author_id = u.id
WHERE p.status = 'published'
  AND p.deleted_at IS NULL
ORDER BY p.published_at DESC
LIMIT 20;
```

### Bash

```bash
#!/bin/bash

# 脚本：备份数据库
echo "开始备份..."

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="backup_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"
pg_dump "$DATABASE_URL" > "$BACKUP_DIR/$FILENAME"

if [ $? -eq 0 ]; then
    echo "✅ 备份成功: $FILENAME"
    ls -lh "$BACKUP_DIR/$FILENAME"
else
    echo "❌ 备份失败"
    exit 1
fi
```

### 行内代码高亮

你也可以在段落中使用行内代码，比如 `git status`、`:wq`、`&lt;Route&gt;`、`&lt;Suspense&gt;`。

## 表格

Markdown 表格使用管道符 `|` 和连字符 `-` 构建：

### 基础表格

| 语言 | 类型 | 内存管理 | 并发模型 | 适用场景 |
|------|------|----------|----------|---------|
| Rust | 系统级 | 所有权系统 | Fearless Concurrency | 高性能系统、嵌入式 |
| Go | 系统级 | 垃圾回收 | Goroutine + Channel | 云原生、微服务 |
| Python | 高级动态 | 垃圾回收 (GIL) | 多进程/异步IO | 数据科学、Web开发 |
| JavaScript | 高级动态 | 垃圾回收 | 事件循环 + Promise | Web前端、Node.js |
| C++ | 系统级 | 手动/RAII | 线程 + 锁 | 游戏引擎、高频交易 |
| Zig | 系统级 | 显式分配 | 线程 | 系统工具、嵌入式 |

### 对齐方式

| 左对齐 | 居中对齐 | 右对齐 |
|:-------|:-------:|-------:|
| 内容 1 | 内容 2 | 内容 3 |
| A | B | 100 |
| 长文本示例 | 居中显示 | 999.99 |

## 水平线

水平线用于分隔文章的不同部分：

---

***

___

## 链接

Markdown 支持多种链接格式：

### 行内链接

[GitHub](https://github.com) - 世界上最流行的代码托管平台。

[相对链接](/) - 链接到网站首页。

[带标题的链接](https://example.com "示例网站") - 鼠标悬停显示标题。

### 引用式链接

[Google][google-link] 和 [Bing][bing-link] 是两大搜索引擎。

[google-link]: https://google.com "Google 搜索"
[bing-link]: https://bing.com "Bing 搜索"

## 图片

![Markdown Logo](https://markdown-here.com/img/icon256.png)

## HTML 内嵌

某些场景下，你可能需要直接使用 HTML：

<div style="padding: 1em; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #007bff;">
  <p><strong>提示：</strong> 这是使用 HTML 创建的自定义样式块。当 Markdown 的表达能力不足时，可以直接嵌入 HTML。但请注意，这会降低内容的可移植性。</p>
</div>

## 特殊字符

Markdown 和 HTML 实体：

- 版权符号：&copy; 2024 Yggdrasil
- 注册商标：Markdown&reg;
- 商标符号：GitHub&trade;
- 长破折号：这是&mdash;一个长破折号
- 短破折号：这是&ndash;一个短破折号
- 省略号：等等&hellip;

## 脚注

脚注是学术写作中常用的功能[^1]。你可以在同一条注释中引用多个脚注[^2][^3]。

[^1]: 这是第一个脚注的内容。脚注可以包含多行文字和格式。
[^2]: 脚注通常用于提供补充说明或引用来源。
[^3]: Markdown 的脚注语法在不同的渲染引擎中支持程度不同。

## 数学公式（LaTeX）

许多现代 Markdown 渲染引擎支持通过 MathJax 或 KaTeX 渲染 LaTeX 数学公式。

### 行内公式

行内公式使用单个美元符号包裹：$E = mc^2$ 是爱因斯坦著名的质能方程。欧拉公式 $e^{i\pi} + 1 = 0$ 被誉为最美的数学公式。

### 块级公式

块级公式使用双美元符号或反斜杠方括号：

$$
\int_{a}^{b} f(x) \, dx = F(b) - F(a)
$$

$$
\sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$

### 矩阵与分段函数

$$
A = \begin{bmatrix}
a_{11} & a_{12} & a_{13} \\
a_{21} & a_{22} & a_{23} \\
a_{31} & a_{32} & a_{33}
\end{bmatrix}
$$

$$
f(n) = \begin{cases}
n/2 & \text{if } n \text{ is even} \\
3n+1 & \text{if } n \text{ is odd}
\end{cases}
$$

### 常用数学符号测试

| 运算符 | LaTeX | 渲染效果 |
|--------|-------|----------|
| 分数 | `\frac{a}{b}` | $\frac{a}{b}$ |
| 上标 | `x^2` | $x^2$ |
| 下标 | `x_i` | $x_i$ |
| 根号 | `\sqrt{x^2 + y^2}` | $\sqrt{x^2 + y^2}$ |
| 极限 | `\lim_{x \to \infty}` | $\lim_{x \to \infty}$ |
| 偏导 | `\frac{\partial f}{\partial x}` | $\frac{\partial f}{\partial x}$ |

## Mermaid 图表

Mermaid 是许多 Markdown 平台支持的图表绘制语法，可以直接在 Markdown 中创建流程图、时序图、类图等。

### 流程图

```mermaid
graph LR
    A[开始] --> B{判断条件}
    B -->|条件成立| C[执行操作]
    B -->|条件不成立| D[结束]
    C --> D
```

### 时序图

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant D as Database

    C->>S: HTTP Request
    S->>D: SQL Query
    D-->>S: Query Result
    S-->>C: HTTP Response
```

### 类图

```mermaid
classDiagram
    class Animal {
        +String name
        +makeSound()
    }
    class Dog {
        +fetch()
    }
    class Cat {
        +climb()
    }
    Animal <|-- Dog
    Animal <|-- Cat
```

### 支持的图表类型

| 图表类型 | 用途 | 语法关键词 |
|----------|------|-----------|
| 流程图 | 展示流程和决策 | `graph TD/LR` |
| 时序图 | 展示交互过程 | `sequenceDiagram` |
| 类图 | 展示类关系 | `classDiagram` |
| 甘特图 | 项目进度 | `gantt` |
| 饼图 | 比例展示 | `pie` |
| ER 图 | 实体关系 | `erDiagram` |

## 复杂表格与嵌套元素

Markdown 表格可以表达相当复杂的结构，尤其是在支持 HTML 的渲染器中。

### 跨列与复杂对齐

| 功能模块 | 子功能 | 状态 | 优先级 | 预计工时 |
|----------|--------|:----:|:-----:|---------:|
| 用户管理 | 用户注册 | ✅ | 高 | 8h |
| 用户管理 | 登录认证 | ✅ | 高 | 16h |
| 内容管理 | 文章发布 | ⚠️ | 中 | 24h |
| 内容管理 | 评论系统 | ❌ | 低 | 40h |
| 数据分析 | 访问统计 | ❌ | 中 | 32h |

### 表格内使用 Markdown

| 特性 | 语法示例 | 渲染效果说明 |
|------|----------|-------------|
| 行内代码 | `` `fmt.Println()` `` | 使用反引号包裹代码 |
| 链接 | `[Google](https://google.com)` | 创建可点击链接 |
| 强调 | `**粗体**` 和 `*斜体*` | **粗体** 和 *斜体* |
| 删除线 | `~~删除~~` | ~~删除~~ |
| 表情符号 | `:rocket:` | 🚀 |

### 复杂嵌套列表示例

1. **项目初始化**
   - 创建仓库
     - 初始化 Git：`git init`
     - 添加远程仓库：`git remote add origin <url>`
   - 配置环境
     - [x] 安装 Node.js
     - [x] 安装依赖：`npm install`
     - [ ] 配置环境变量

2. **开发阶段**
   > 注意：开发过程中要遵循团队的代码规范。
   
   - 编码
     1. 编写核心功能
     2. 添加单元测试
     3. 运行测试：`npm test`
   - 代码审查
     - 创建 Pull Request
     - 等待审查
     - 合并到主分支

3. **部署上线**
   - 构建生产版本
   - 部署到服务器
   - 监控系统状态

### 定义列表

一些 Markdown 扩展支持定义列表（HTML `<dl>`）：

术语 1
:   这是术语 1 的定义。定义列表在学术文档和技术文档中很有用。

术语 2
:   这是术语 2 的第一个定义。
:   术语可以有多个定义。

### 折叠块

GFM 支持使用 HTML `<details>` 标签创建可折叠内容：

<details>
<summary>点击展开：高级配置选项</summary>

```json
{
  "debug": false,
  "cache": {
    "enabled": true,
    "ttl": 3600
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "pool_size": 10
  }
}
```

> 注意：修改配置后需要重启服务才能生效。

</details>

## 总结

本文测试了 Markdown 的完整语法集：

| 语法元素 | 支持情况 | 说明 |
|---------|---------|------|
| 文本格式 | ✅ | 粗体、斜体、删除线、行内代码 |
| 标题 | ✅ | 六级标题支持 |
| 列表 | ✅ | 无序、有序、嵌套、任务列表 |
| 引用块 | ✅ | 支持嵌套引用 |
| 代码块 | ✅ | 语法高亮 |
| 表格 | ✅ | 对齐方式 |
| 水平线 | ✅ | 多种分隔符 |
| 链接 | ✅ | 行内和引用式 |
| 图片 | ✅ | 外部图片 |
| HTML | ✅ | 内嵌 HTML 块 |
| 脚注 | ⚠️ | 依赖渲染引擎支持 |
| 数学公式 | ⚠️ | 需要 MathJax 或 KaTeX |
| Mermaid 图表 | ⚠️ | 依赖渲染引擎插件 |
| 定义列表 | ⚠️ | 部分扩展支持 |
| 折叠块 | ⚠️ | GFM + HTML 支持 |

如果你的渲染引擎正确显示了以上内容，说明它对 Markdown 的支持非常完善！

---

*本文用于测试 Markdown 渲染引擎的兼容性。*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 hours',
    NOW() - INTERVAL '3 hours',
    NOW() - INTERVAL '3 hours'
),
(
    1,
    'Rust 错误处理完全指南：Result、Option 与 thiserror',
    'rust-error-handling',
    'Rust 使用 Result 和 Option 类型来处理可能失败的操作和可能缺失的值，取代了传统的异常机制。本文深入讲解 Rust 的错误处理哲学和最佳实践。',
    $doc$
# Rust 错误处理完全指南：Result、Option 与 thiserror

Rust 没有异常机制（Exception）。对于习惯了 Java、Python 或 JavaScript 的开发者来说，这可能需要一些适应。但 Rust 的类型驱动错误处理——通过 `Result` 和 `Option` 类型——实际上是一种更健壮、更明确的设计。

本文将深入探讨 Rust 的错误处理哲学，从基础的 `Option` 和 `Result` 到自定义错误类型，再到 `?` 操作符和第三方库 `thiserror`。

## 为什么 Rust 没有异常？

传统的异常机制存在几个问题：

1. **不可见的控制流**：异常可以穿透任意层级的调用栈，使得代码路径难以追踪
2. **类型安全缺失**：编译器无法检查你是否处理了所有可能的异常
3. **性能开销**：异常处理通常需要运行时维护额外的栈信息

Rust 的解决方案是**将错误作为值返回**。如果一个函数可能失败，它的返回类型就明确地表示这一点。编译器会强迫你处理这个错误，否则代码无法通过编译。

## Option 类型：处理可能缺失的值

`Option<T>` 是 Rust 中表示"可能有值，也可能没有"的类型：

```rust
enum Option<T> {
    Some(T),  // 有值
    None,     // 无值
}
```

### 基础使用

```rust
fn find_char(s: &str, c: char) -> Option<usize> {
    s.find(c)  // 如果找到返回 Some(index)，否则返回 None
}

fn main() {
    // 使用 match 处理 Option
    match find_char("hello", 'e') {
        Some(index) => println!("✅ 找到字符在位置 {}", index),
        None => println!("❌ 未找到字符"),
    }
    
    // 使用 if let 简化（只关心 Some 的情况）
    if let Some(index) = find_char("hello", 'l') {
        println!("🎯 在位置 {}", index);
    }
    
    // while let：循环处理
    let mut text = "hello";
    while let Some(c) = text.chars().next() {
        println!("字符: {}", c);
        text = &text[1..];
    }
}
```

### Option 的组合子

`Option` 提供了丰富的组合子方法来链式处理：

```rust
fn main() {
    let maybe_number: Option<i32> = Some(5);
    
    // map：对 Some 中的值进行转换
    let doubled = maybe_number.map(|n| n * 2); // Some(10)
    
    // and_then：链式调用返回 Option 的函数
    let result = maybe_number
        .and_then(|n| if n > 3 { Some(n) } else { None })
        .map(|n| n * 2);
    
    // unwrap_or：提供默认值
    let value = maybe_number.unwrap_or(0); // 5
    let empty = None::<i32>.unwrap_or(0); // 0
    
    // unwrap_or_else：懒加载默认值
    let lazy = None::<i32>.unwrap_or_else(|| expensive_computation());
    
    // ok_or：将 Option 转换为 Result
    let result: Result<i32, &str> = maybe_number.ok_or("值为空");
}
```

## Result 类型：处理可能失败的操作

`Result<T, E>` 是 Rust 中表示操作可能失败的核心类型：

```rust
enum Result<T, E> {
    Ok(T),   // 成功
    Err(E),  // 失败，携带错误信息
}
```

### 基础使用

```rust
use std::fs::File;
use std::io::{self, Read};

fn read_username_from_file() -> Result<String, io::Error> {
    let mut file = File::open("hello.txt")?;
    let mut username = String::new();
    file.read_to_string(&mut username)?;
    Ok(username)
}
```

### ? 操作符：错误传播

`?` 操作符是 Rust 错误处理中最常用的语法糖。它在 `Result` 为 `Ok` 时解包值，在 `Err` 时提前返回错误：

```rust
fn read_config() -> Result<Config, io::Error> {
    let content = std::fs::read_to_string("config.json")?;  // 如果失败，直接返回 Err
    let config: Config = serde_json::from_str(&content)?;     // 如果失败，直接返回 Err
    Ok(config)
}
```

`?` 操作符的强大之处在于它可以自动进行错误类型的转换。只要当前函数的返回错误类型实现了 `From<E>`，就可以使用 `?`。

### Result 的组合子

与 `Option` 类似，`Result` 也有丰富的组合子：

```rust
fn main() {
    let result: Result<i32, &str> = Ok(42);
    
    // map：对 Ok 中的值进行转换
    let doubled = result.map(|n| n * 2); // Ok(84)
    
    // map_err：对 Err 中的值进行转换
    let with_prefix = Err("error").map_err(|e| format!("ERROR: {}", e));
    
    // and_then：链式调用
    let chained = Ok(5)
        .and_then(|n| if n > 0 { Ok(n * 2) } else { Err("负数") });
    
    // unwrap_or / unwrap_or_else
    let value = result.unwrap_or(0); // 42
    
    // expect：unwrap 的变体，可自定义 panic 消息
    let file = std::fs::read_to_string("config.txt")
        .expect("config.txt 必须存在");
}
```

## 自定义错误类型

在实际项目中，你可能需要定义自己的错误类型。Rust 提供了多种方式：

### 枚举错误类型

```rust
#[derive(Debug)]
pub enum AppError {
    Io(std::io::Error),
    Parse(std::num::ParseIntError),
    InvalidInput(String),
    NotFound { resource: String, id: i64 },
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            AppError::Io(e) => write!(f, "IO 错误: {}", e),
            AppError::Parse(e) => write!(f, "解析错误: {}", e),
            AppError::InvalidInput(msg) => write!(f, "无效输入: {}", msg),
            AppError::NotFound { resource, id } => write!(f, "{} 不存在: id={}", resource, id),
        }
    }
}

impl std::error::Error for AppError {}

// 实现 From trait 以支持 ? 操作符
impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::Io(err)
    }
}

impl From<std::num::ParseIntError> for AppError {
    fn from(err: std::num::ParseIntError) -> Self {
        AppError::Parse(err)
    }
}
```

### 使用 thiserror 简化

手动实现错误类型很繁琐。[`thiserror`](https://docs.rs/thiserror) 是一个宏库，可以大大简化这个过程：

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("IO 错误: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("解析错误: {0}")]
    Parse(#[from] std::num::ParseIntError),
    
    #[error("无效输入: {0}")]
    InvalidInput(String),
    
    #[error("{resource} 不存在: id={id}")]
    NotFound { resource: String, id: i64 },
    
    #[error("数据库错误")]
    Database {
        #[from]
        source: sqlx::Error,
    },
}

// 使用
fn load_user(id: i64) -> Result<User, AppError> {
    let content = std::fs::read_to_string("users.json")?;  // 自动转换 io::Error
    let users: Vec<User> = serde_json::from_str(&content)?;
    
    users.into_iter()
        .find(|u| u.id == id)
        .ok_or_else(|| AppError::NotFound {
            resource: "User".to_string(),
            id,
        })
}
```

### anyhow：快速原型开发

如果你不需要精细的错误分类，可以使用 [`anyhow`](https://docs.rs/anyhow) 库：

```rust
use anyhow::{Context, Result};

fn main() -> Result<()> {
    let config = std::fs::read_to_string("config.toml")
        .with_context(|| "无法读取配置文件")?;
    
    let settings: Settings = toml::from_str(&config)
        .context("配置文件格式错误")?;
    
    println!("{:?}", settings);
    Ok(())
}
```

## Option 与 Result 的转换

在实际代码中，经常需要在 `Option` 和 `Result` 之间转换：

```rust
// Option -> Result
let opt: Option<i32> = Some(5);
let res: Result<i32, &str> = opt.ok_or("值为空"); // Ok(5)
let res2 = opt.ok_or_else(|| format!("{} 为空", "value")); // Ok(5)

// Result -> Option
let res: Result<i32, &str> = Ok(5);
let opt = res.ok(); // Some(5)
let err_opt = res.err(); // None

// 在迭代中收集 Result
let numbers = vec!["1", "2", "3", "not_a_number"];
let parsed: Result<Vec<i32>, _> = numbers.iter()
    .map(|s| s.parse::<i32>())
    .collect(); // 如果有任何 Err，返回第一个 Err
```

## 错误处理最佳实践

| 场景 | 推荐方式 | 示例 |
|------|---------|------|
| 快速原型 | `anyhow::Result` | `fn main() -> anyhow::Result<()>` |
| 库开发 | `thiserror` | 定义精细的错误枚举 |
| 错误传播 | `?` 操作符 | `let x = may_fail()?;` |
| 提供默认值 | `unwrap_or` | `let x = opt.unwrap_or(0);` |
| 不可恢复错误 | `expect` | `let x = vec[0].expect("不能为空")` |
| 可选值链 | `and_then` + `map` | `opt.and_then(f).map(g)` |

## 总结

Rust 的错误处理机制强迫开发者显式处理所有错误路径，这看似繁琐，实际上带来了巨大的好处：

| 类型 | 表示 | 使用场景 |
|------|------|---------|
| `Option<T>` | `Some(T)` / `None` | 可能缺失的值 |
| `Result<T, E>` | `Ok(T)` / `Err(E)` | 可能失败的操作 |
| `?` 操作符 | 自动传播错误 | 函数内部错误处理 |
| `thiserror` | 宏生成的错误类型 | 库开发 |
| `anyhow` | 泛型错误类型 | 应用程序开发 |

Rust 的类型驱动错误处理是一种**以编译期检查换取运行时安全**的设计哲学。虽然需要写更多的错误处理代码，但换来的是程序在运行时几乎不会因为未处理的错误而崩溃。

> "在 Rust 中，如果代码通过了编译，那么它已经处理了所有可能的错误路径。" —— 这是 Rust 给予开发者的最大信心。

## 错误处理与异步编程

Rust 的异步编程模型与错误处理机制紧密结合，`?` 操作符在异步函数中同样适用，使得异步代码的错误处理保持简洁和一致。

### 异步函数中的错误传播

```rust
use tokio::fs::File;
use tokio::io::{self, AsyncReadExt};

async fn read_config_async(path: &str) -> Result<String, io::Error> {
    // 在异步函数中使用 ? 操作符
    let mut file = File::open(path).await?;
    let mut contents = String::new();
    file.read_to_string(&mut contents).await?;
    Ok(contents)
}

// 链式异步操作
async fn process_user_data(user_id: u64) -> Result<UserData, AppError> {
    let config = read_config_async("config.json").await?;
    let settings: Settings = serde_json::from_str(&config)?;
    
    let user = fetch_user(user_id).await?;
    let data = transform_data(user, &settings)?;
    
    validate_data(&data)?;
    Ok(data)
}
```

### 并发操作中的错误收集

```rust
use futures::future::join_all;

async fn fetch_multiple_users(ids: Vec<u64>) -> Vec<Result<User, AppError>> {
    // 并发获取多个用户，保留每个结果
    let futures: Vec<_> = ids
        .into_iter()
        .map(|id| fetch_user(id))
        .collect();
    
    join_all(futures).await
}

// 收集所有错误或所有成功值
async fn fetch_all_or_none(ids: Vec<u64>) -> Result<Vec<User>, Vec<AppError>> {
    let results = fetch_multiple_users(ids).await;
    
    let (successes, errors): (Vec<_>, Vec<_>) = results
        .into_iter()
        .partition(Result::is_ok);
    
    if !errors.is_empty() {
        Err(errors.into_iter()
            .filter_map(Result::err)
            .collect())
    } else {
        Ok(successes.into_iter()
            .filter_map(Result::ok)
            .collect())
    }
}
```

### 超时与取消

```rust
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout() -> Result<Data, AppError> {
    // 设置操作超时
    match timeout(Duration::from_secs(5), fetch_data()).await {
        Ok(Ok(data)) => Ok(data),
        Ok(Err(e)) => Err(e),
        Err(_) => Err(AppError::Timeout),
    }
    
    // 更简洁的写法
    // timeout(Duration::from_secs(5), fetch_data())
    //     .await
    //     .map_err(|_| AppError::Timeout)?
    //     .map_err(AppError::from)
}
```

## 错误恢复与重试策略

在实际应用中，某些错误是暂时的（如网络超时），应该自动重试而不是立即失败。

### 指数退避重试

```rust
use std::time::Duration;
use tokio::time::sleep;

async fn retry_with_backoff<F, Fut, T, E>(
    mut operation: F,
    max_retries: u32,
) -> Result<T, E>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = Result<T, E>>,
    E: std::fmt::Display,
{
    let mut last_error = None;
    
    for attempt in 0..max_retries {
        match operation().await {
            Ok(result) => return Ok(result),
            Err(e) => {
                eprintln!("尝试 {} 失败: {}", attempt + 1, e);
                last_error = Some(e);
                
                if attempt < max_retries - 1 {
                    // 指数退避：2^attempt * 100ms
                    let delay = Duration::from_millis(100 * 2u64.pow(attempt));
                    sleep(delay).await;
                }
            }
        }
    }
    
    Err(last_error.unwrap())
}

// 使用
async fn fetch_data_with_retry() -> Result<Data, NetworkError> {
    retry_with_backoff(
        || fetch_data(),
        5,
    ).await
}
```

### 断路器模式

```rust
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

#[derive(Clone)]
struct CircuitBreaker {
    failure_count: Arc<AtomicU32>,
    last_failure: Arc<std::sync::Mutex<Option<Instant>>>,
    threshold: u32,
    timeout: Duration,
}

#[derive(Debug)]
enum CircuitError {
    Open,
    Inner(Box<dyn std::error::Error>),
}

impl CircuitBreaker {
    fn new(threshold: u32, timeout_secs: u64) -> Self {
        Self {
            failure_count: Arc::new(AtomicU32::new(0)),
            last_failure: Arc::new(std::sync::Mutex::new(None)),
            threshold,
            timeout: Duration::from_secs(timeout_secs),
        }
    }
    
    async fn call<F, Fut, T, E>(&self, operation: F) -> Result<T, CircuitError>
    where
        F: FnOnce() -> Fut,
        Fut: std::future::Future<Output = Result<T, E>>,
        E: std::error::Error + 'static,
    {
        // 检查断路器是否打开
        let failures = self.failure_count.load(Ordering::Relaxed);
        if failures >= self.threshold {
            let last = self.last_failure.lock().unwrap();
            if let Some(time) = *last {
                if time.elapsed() < self.timeout {
                    return Err(CircuitError::Open);
                }
            }
            // 超时后重置计数
            self.failure_count.store(0, Ordering::Relaxed);
        }
        
        match operation().await {
            Ok(result) => {
                self.failure_count.store(0, Ordering::Relaxed);
                Ok(result)
            }
            Err(e) => {
                let count = self.failure_count.fetch_add(1, Ordering::Relaxed) + 1;
                if count >= self.threshold {
                    *self.last_failure.lock().unwrap() = Some(Instant::now());
                }
                Err(CircuitError::Inner(Box::new(e)))
            }
        }
    }
}
```

## 错误监控与日志记录

### 结构化错误日志

```rust
use tracing::{error, info, warn, instrument};

#[derive(thiserror::Error, Debug)]
enum PaymentError {
    #[error("支付网关错误: {code}")]
    Gateway { code: u32, message: String },
    
    #[error("余额不足: 需要 {required}, 可用 {available}")]
    InsufficientFunds { required: f64, available: f64 },
    
    #[error("验证失败: {0}")]
    Validation(String),
}

#[instrument(skip(card_info))]
async fn process_payment(
    amount: f64,
    user_id: u64,
    card_info: &str,
) -> Result<PaymentId, PaymentError> {
    info!(%amount, %user_id, "开始处理支付");
    
    // 验证输入
    if amount <= 0.0 {
        warn!(%amount, "无效金额");
        return Err(PaymentError::Validation(
            "金额必须大于0".to_string()
        ));
    }
    
    // 检查余额
    let balance = get_user_balance(user_id).await
        .map_err(|e| PaymentError::Validation(e.to_string()))?;
    
    if balance < amount {
        warn!(%amount, %balance, %user_id, "余额不足");
        return Err(PaymentError::InsufficientFunds {
            required: amount,
            available: balance,
        });
    }
    
    // 调用支付网关
    match call_payment_gateway(amount, card_info).await {
        Ok(id) => {
            info!(%id, %amount, %user_id, "支付成功");
            Ok(id)
        }
        Err(code) => {
            error!(%code, %amount, %user_id, "支付网关错误");
            Err(PaymentError::Gateway {
                code,
                message: gateway_error_message(code),
            })
        }
    }
}
```

### 错误聚合与上报

```rust
use std::collections::HashMap;

// 错误统计
#[derive(Default)]
struct ErrorMetrics {
    counts: HashMap<String, u64>,
    last_occurrence: HashMap<String, chrono::DateTime<chrono::Utc>>,
}

impl ErrorMetrics {
    fn record<E: std::error::Error>(&mut self, error: &E) {
        let key = error.to_string();
        *self.counts.entry(key.clone()).or_insert(0) += 1;
        self.last_occurrence.insert(key, chrono::Utc::now());
    }
    
    fn report(&self) -> String {
        let mut lines = vec!["错误统计报告:".to_string()];
        for (error, count) in &self.counts {
            let last = self.last_occurrence.get(error)
                .map(|t| t.to_rfc3339())
                .unwrap_or_default();
            lines.push(format!("  {}: {}次 (最后: {})", error, count, last));
        }
        lines.join("\n")
    }
}

// 在应用程序中使用
struct ErrorReporter {
    metrics: std::sync::Mutex<ErrorMetrics>,
}

impl ErrorReporter {
    fn report_error<E: std::error::Error>(&self, error: &E) {
        let mut metrics = self.metrics.lock().unwrap();
        metrics.record(error);
        
        // 如果错误频率过高，触发告警
        let count = metrics.counts.get(&error.to_string()).copied().unwrap_or(0);
        if count > 100 {
            // 发送告警
            tracing::error!("错误频率过高: {}", error);
        }
    }
}
```

| 监控维度 | 指标 | 告警阈值 | 处理建议 |
|---------|------|---------|---------|
| 错误频率 | 每分钟错误数 | > 100/min | 检查服务健康状态 |
| 错误类型分布 | 各类错误占比 | 某类 > 50% | 针对性优化 |
| 恢复时间 | 错误到恢复时长 | > 5min | 改进重试策略 |
| 用户体验 | 用户可见错误率 | > 1% | 前端降级处理 |

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '2 hours'
),
(
    1,
    'Python 数据类完全指南：dataclass、attrs 与 Pydantic',
    'python-dataclasses',
    'Python 3.7 引入的 dataclass 装饰器大大简化了类的定义。本文深入对比 dataclass、attrs 和 Pydantic，帮助你选择最合适的方案。',
    $doc$
# Python 数据类完全指南：dataclass、attrs 与 Pydantic

在 Python 中定义一个简单的数据容器类，传统方式需要编写大量样板代码：`__init__`、`__repr__`、`__eq__`……这些代码不仅冗余，而且容易出错。Python 3.7 引入的 **`dataclass`** 装饰器彻底解决了这个问题，让你可以用声明式的方式定义数据类。

本文将深入介绍 `dataclass`、`attrs` 和 `Pydantic` 三种数据类方案，帮助你根据场景选择最合适的工具。

## dataclass（标准库）

`dataclasses` 模块是 Python 3.7+ 的标准库，无需安装任何第三方包。

### 基础用法

```python
from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class Person:
    name: str
    age: int = 0
    email: Optional[str] = None
    hobbies: List[str] = field(default_factory=list)
    
    def greet(self) -> str:
        return f"Hello, I'm {self.name}!"
    
    def is_adult(self) -> bool:
        return self.age >= 18

# 使用
person = Person("Alice", 30, "alice@example.com", ["reading", "coding"])
print(person)
# Person(name='Alice', age=30, email='alice@example.com', hobbies=['reading', 'coding'])

print(person.greet())  # Hello, I'm Alice!
print(person == Person("Alice", 30))  # False（因为 email 和 hobbies 不同）
```

`@dataclass` 装饰器自动为你生成了 `__init__`、`__repr__`、`__eq__` 等方法。

### dataclass 参数

```python
@dataclass(init=True,      # 生成 __init__
           repr=True,      # 生成 __repr__
           eq=True,        # 生成 __eq__
           order=False,    # 生成比较方法 (__lt__, __le__, __gt__, __ge__)
           unsafe_hash=False,  # 生成 __hash__
           frozen=False,   # 不可变实例
           slots=False,    # 使用 __slots__ 节省内存
           kw_only=False)  # 关键字-only 参数
class Product:
    name: str
    price: float
    quantity: int = 0
```

### field() 函数

`field()` 提供了更精细的控制：

```python
from dataclasses import dataclass, field

@dataclass
class User:
    id: int = field(init=False)  # 不通过 __init__ 传入
    name: str
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    password: str = field(repr=False)  # 不在 __repr__ 中显示
    
    def __post_init__(self):
        self.id = hash(self.name) % 10000

user = User("alice", password="secret123")
print(user)
# User(id=1234, name='alice', created_at='2024-...')
# 注意：password 不在 repr 中
```

### frozen dataclass（不可变数据类）

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Point:
    x: float
    y: float
    
    def distance_from_origin(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5

p = Point(3.0, 4.0)
print(p.distance_from_origin())  # 5.0
# p.x = 5.0  # FrozenInstanceError: cannot assign to field 'x'
```

不可变数据类天然是线程安全的，可以作为字典的键使用。

### 继承

```python
@dataclass
class Employee(Person):
    employee_id: str
    department: str = "Engineering"
    salary: float = field(default=0.0, repr=False)

emp = Employee("Bob", 25, None, [], "E001", "Product")
print(emp)
```

## attrs（第三方库）

[`attrs`](https://www.attrs.org/) 是比 `dataclass` 更早出现的第三方库，功能更强大。

```python
import attr

@attr.s(auto_attribs=True)
class Vehicle:
    wheels: int = 4
    color: str = "red"
    brand: str = attr.ib(default="Unknown", validator=attr.validators.instance_of(str))
    
    def describe(self) -> str:
        return f"A {self.color} {self.brand} with {self.wheels} wheels"

v = Vehicle(wheels=2, color="blue", brand="Yamaha")
print(v.describe())  # A blue Yamaha with 2 wheels
```

### attrs 的优势

| 特性 | dataclass | attrs | 说明 |
|------|-----------|-------|------|
| 标准库 | ✅ | ❌ | dataclass 无需安装 |
| 验证器 | 有限 | 强大 | attrs 内置多种验证器 |
| 转换器 | 无 | 有 | attrs 支持类型转换 |
| 性能 | 好 | 更好 | attrs 生成的代码更优化 |
| 序列化 | 需手动 | 内置 | attrs 支持多种格式 |
| 元数据 | 有限 | 丰富 | attrs 的 metadata 系统 |

### attrs 验证器示例

```python
import attr

@attr.s
class User:
    name: str = attr.ib(validator=attr.validators.instance_of(str))
    age: int = attr.ib(
        validator=[
            attr.validators.instance_of(int),
            attr.validators.ge(0),  # 大于等于 0
            attr.validators.le(150) # 小于等于 150
        ]
    )
    email: str = attr.ib(
        validator=attr.validators.matches_re(r"^[\w\.-]+@[\w\.-]+\.\w+$")
    )

# 使用
try:
    user = User("Alice", -5, "alice@example.com")
except ValueError as e:
    print(f"验证失败: {e}")
```

## Pydantic：数据验证与序列化

[`Pydantic`](https://docs.pydantic.dev/) 是目前 Python 生态系统中最流行的数据验证库，基于类型提示自动进行数据验证和转换。

### 基础用法

```python
from pydantic import BaseModel, Field, EmailStr, validator
from typing import List, Optional
from datetime import datetime

class User(BaseModel):
    id: int
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr  # 自动验证邮箱格式
    age: int = Field(..., ge=0, le=150)
    is_active: bool = True
    tags: List[str] = []
    created_at: Optional[datetime] = None
    
    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Name must not be empty')
        return v.strip()

# 自动验证和转换
user = User(id=1, name="Alice", email="alice@example.com", age=30)
print(user)
# id=1 name='Alice' email='alice@example.com' age=30 is_active=True tags=[] created_at=None

# 从字典创建（自动转换类型）
user_dict = {"id": "2", "name": "Bob", "email": "bob@test.com", "age": "25"}
user2 = User(**user_dict)
print(user2.age)  # 25 (自动从 str 转换为 int)

# JSON 序列化
print(user.json())
# {"id": 1, "name": "Alice", "email": "alice@example.com", ...}
```

### Pydantic 配置

```python
from pydantic import BaseModel, Field

class Config:
    """Pydantic 配置选项"""
    pass

class User(BaseModel):
    class Config:
        # 允许从 ORM 对象创建
        orm_mode = True
        # 字段别名（如 JSON 中的 snake_case 映射到 camelCase）
        alias_generator = lambda x: x.lower()
        # 验证赋值
        validate_assignment = True
        # 错误信息使用中文
        error_msg_templates = {
            'value_error.missing': '字段必填',
        }
    
    name: str
    age: int
```

## 三者对比

| 特性 | dataclass | attrs | Pydantic |
|------|-----------|-------|----------|
| 安装 | 标准库 | `pip install attrs` | `pip install pydantic` |
| 类型转换 | ❌ | 部分 | ✅ 自动 |
| 数据验证 | ❌ | ✅ 内置 | ✅ 强大 |
| JSON 序列化 | ❌ | ✅ | ✅ 内置 |
| ORM 集成 | ❌ | ❌ | ✅ SQLAlchemy |
| 性能 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 学习曲线 | 低 | 中 | 低 |
| 适用场景 | 简单数据结构 | 复杂验证逻辑 | API 开发、配置管理 |

## 如何选择？

1. **简单数据类**：使用 `dataclass`（标准库，零依赖）
2. **需要复杂验证**：使用 `attrs`（验证器、转换器更强大）
3. **Web/API 开发**：使用 `Pydantic`（自动验证、JSON 序列化、FastAPI 原生支持）
4. **配置管理**：使用 `Pydantic`（环境变量加载、类型转换）
5. **ORM 模型**：使用 `Pydantic`（`orm_mode` 支持）

## 总结

Python 的数据类生态系统已经非常成熟：

- **`dataclass`**：简单、标准库、适合大多数场景
- **`attrs`**：功能强大、验证丰富、适合复杂业务逻辑
- **`Pydantic`**：验证 + 序列化 + ORM、Web 开发首选

三者并非互斥。你可以在项目中根据场景灵活选择。例如，内部数据模型使用 `dataclass`，API 接口使用 `Pydantic`，核心业务实体使用 `attrs`。

> **最佳实践**：不要过度设计。如果 `dataclass` 能满足需求，就不要引入额外的依赖。

## 高级数据类特性

### 使用 `__slots__` 优化内存

对于需要创建大量实例的数据类，可以使用 `slots=True` 参数显著减少内存占用：

```python
from dataclasses import dataclass
import sys

@dataclass
class RegularPoint:
    """普通数据类"""
    x: float
    y: float
    z: float = 0.0

@dataclass(slots=True)
class SlotPoint:
    """使用 __slots__ 的数据类"""
    x: float
    y: float
    z: float = 0.0

# 内存对比
regular = RegularPoint(1.0, 2.0, 3.0)
slot = SlotPoint(1.0, 2.0, 3.0)

print(f"普通实例内存: {sys.getsizeof(regular)} bytes")
print(f"Slots 实例内存: {sys.getsizeof(slot)} bytes")
print(f"内存节省: {(1 - sys.getsizeof(slot) / sys.getsizeof(regular)) * 100:.1f}%")

# slots=True 的优势：
# 1. 内存占用更少（无需 __dict__）
# 2. 属性访问更快
# 3. 无法动态添加新属性（更严格的类型安全）

# 错误示例：尝试动态添加属性
try:
    slot.w = 4.0  # AttributeError: 'SlotPoint' object has no attribute 'w'
except AttributeError as e:
    print(f"Slots 阻止了动态属性添加: {e}")
```

### 自定义序列化与反序列化

数据类经常需要与 JSON、YAML 等格式互转。以下是一些实用的模式：

```python
from dataclasses import dataclass, field, asdict
from typing import List, Optional
from datetime import datetime
import json

@dataclass
class Product:
    """产品数据类，支持自定义序列化"""
    name: str
    price: float
    tags: List[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)
    metadata: dict = field(default_factory=dict, repr=False)
    
    def to_json(self) -> str:
        """转换为 JSON 字符串"""
        data = asdict(self)
        # 自定义序列化逻辑
        data['created_at'] = self.created_at.isoformat()
        data['price'] = round(self.price, 2)  # 保留两位小数
        return json.dumps(data, ensure_ascii=False, indent=2)
    
    @classmethod
    def from_json(cls, json_str: str) -> 'Product':
        """从 JSON 字符串创建实例"""
        data = json.loads(json_str)
        # 自定义反序列化逻辑
        if isinstance(data.get('created_at'), str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if isinstance(data.get('price'), (int, float)):
            data['price'] = float(data['price'])
        return cls(**data)
    
    def to_dict(self, exclude: Optional[List[str]] = None) -> dict:
        """转换为字典，支持排除字段"""
        data = asdict(self)
        if exclude:
            for field_name in exclude:
                data.pop(field_name, None)
        return data

# 使用示例
product = Product(
    name="机械键盘",
    price=599.99,
    tags=["电子产品", "办公"],
    metadata={"warranty": "2年", "brand": "Keychron"}
)

print("JSON 序列化:")
print(product.to_json())

# 从 JSON 恢复
json_str = product.to_json()
restored = Product.from_json(json_str)
print(f"\n反序列化后: {restored}")

# 排除敏感字段导出
public_data = product.to_dict(exclude=['metadata'])
print(f"\n公开数据: {public_data}")
```

### 数据类与描述符结合

通过结合描述符协议，可以实现更复杂的属性验证和转换逻辑：

```python
from dataclasses import dataclass, field
from typing import Any, TypeVar, Generic

T = TypeVar('T')

class ValidatedField:
    """带验证的描述符"""
    
    def __init__(self, name: str, type_hint: type, default: Any = None, 
                 min_value=None, max_value=None, validator=None):
        self.name = name
        self.type_hint = type_hint
        self.default = default
        self.min_value = min_value
        self.max_value = max_value
        self.validator = validator
        self.private_name = f"_validated_{name}"
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return getattr(obj, self.private_name, self.default)
    
    def __set__(self, obj, value):
        # 类型检查
        if not isinstance(value, self.type_hint):
            try:
                value = self.type_hint(value)
            except (ValueError, TypeError):
                raise TypeError(f"{self.name} 必须是 {self.type_hint.__name__} 类型")
        
        # 范围验证
        if self.min_value is not None and value < self.min_value:
            raise ValueError(f"{self.name} 不能小于 {self.min_value}")
        
        if self.max_value is not None and value > self.max_value:
            raise ValueError(f"{self.name} 不能大于 {self.max_value}")
        
        # 自定义验证器
        if self.validator and not self.validator(value):
            raise ValueError(f"{self.name} 自定义验证失败")
        
        setattr(obj, self.private_name, value)

class Range:
    """范围验证描述符"""
    
    def __init__(self, min_value, max_value):
        self.min_value = min_value
        self.max_value = max_value
    
    def __set_name__(self, owner, name):
        self.name = name
        self.private_name = f"_range_{name}"
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return getattr(obj, self.private_name)
    
    def __set__(self, obj, value):
        if not isinstance(value, (int, float)):
            raise TypeError(f"{self.name} 必须是数字")
        if value < self.min_value or value > self.max_value:
            raise ValueError(f"{self.name} 必须在 {self.min_value} 到 {self.max_value} 之间")
        setattr(obj, self.private_name, value)

@dataclass
class Employee:
    """员工类，使用描述符进行属性验证"""
    name: str
    
    # 使用自定义描述符
    age: int = field(default=0)
    salary: float = field(default=0.0)
    
    # 使用 Range 描述符
    performance_score: float = field(default=0.0)
    years_of_service: int = field(default=0)
    
    def __post_init__(self):
        # 初始化描述符
        self._validated_age = self.age
        self._validated_salary = self.salary
        self._range_performance_score = self.performance_score
        self._range_years_of_service = self.years_of_service

# 创建带验证的 Employee 子类
class ValidatedEmployee(Employee):
    age = ValidatedField("age", int, default=0, min_value=18, max_value=100)
    salary = ValidatedField("salary", float, default=0.0, min_value=0)
    performance_score = Range(0, 100)
    years_of_service = Range(0, 50)

# 使用示例
emp = ValidatedEmployee("张三", age=25, salary=5000.0, performance_score=85.5)
print(emp)

try:
    emp.age = 150  # ValueError: age 不能大于 100
except ValueError as e:
    print(f"验证错误: {e}")

try:
    emp.performance_score = 120  # ValueError: performance_score 必须在 0 到 100 之间
except ValueError as e:
    print(f"验证错误: {e}")
```

## 数据类性能对比与选择指南

| 场景 | 推荐方案 | 内存占用 | 性能 | 代码复杂度 |
|------|---------|---------|------|-----------|
| 简单数据容器 | `dataclass` | 中等 | 良好 | 低 |
| 大量实例（>10万） | `dataclass(slots=True)` | 低 | 优秀 | 低 |
| 需要复杂验证 | `Pydantic` | 高 | 中等 | 中 |
| 需要自动序列化 | `Pydantic` | 高 | 中等 | 中 |
| ORM 集成 | `Pydantic` + SQLAlchemy | 高 | 中等 | 高 |
| 嵌套数据结构 | `attrs` 或 `Pydantic` | 中等 | 良好 | 中 |
| 不可变数据 | `dataclass(frozen=True)` | 中等 | 良好 | 低 |
| 配置管理 | `Pydantic` Settings | 高 | 中等 | 中 |

### 性能测试示例

```python
import time
from dataclasses import dataclass
from typing import List

@dataclass
class SimpleItem:
    name: str
    price: float
    quantity: int

@dataclass(slots=True)
class SlotItem:
    name: str
    price: float
    quantity: int

def benchmark(cls, iterations=100000):
    start = time.time()
    items = []
    for i in range(iterations):
        item = cls(f"item_{i}", float(i), i % 100)
        items.append(item)
        _ = item.name
        _ = item.price * item.quantity
    elapsed = time.time() - start
    return elapsed, sys.getsizeof(items[0]) if items else 0

import sys

print("性能对比测试（10万次操作）:")
print("-" * 50)

regular_time, regular_size = benchmark(SimpleItem)
print(f"普通 dataclass: {regular_time:.3f}s, 内存: {regular_size} bytes")

slot_time, slot_size = benchmark(SlotItem)
print(f"slots dataclass: {slot_time:.3f}s, 内存: {slot_size} bytes")

print(f"\n性能提升: {(1 - slot_time/regular_time) * 100:.1f}%")
print(f"内存节省: {(1 - slot_size/regular_size) * 100:.1f}%")
```

> **数据类设计原则**：
> 1. **简单优先**：从 `dataclass` 开始，只在需要时引入更复杂的方案
> 2. **明确不变性**：如果数据不应被修改，使用 `frozen=True`
> 3. **考虑内存**：大量实例时使用 `slots=True`
> 4. **验证分离**：业务验证逻辑放在方法中，而非构造函数
> 5. **类型安全**：始终使用类型注解，配合静态类型检查工具
> 6. **文档化**：为数据类添加 docstring，说明每个字段的用途

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days'
),
(
    1,
    'C 语言指针详解',
    'c-pointers-explained',
    '深入理解 C 语言指针的本质，从基础概念到高级用法，全面掌握指针与数组、函数指针、多级指针、内存管理等核心技术，避免常见的指针陷阱。',
    $doc$
# C 语言指针详解：从基础到精通

指针是 C 语言最核心的特性之一，也是最令初学者困惑的概念。理解指针的本质，是掌握 C 语言的关键一步。本文将从基础概念出发，逐步深入探讨指针的各种高级用法和常见陷阱。

## 指针的本质

### 什么是指针

指针是一个变量，其值为另一个变量的内存地址。每个变量在内存中都有一个唯一的地址，指针就是存储这个地址的特殊变量。

```c
#include <stdio.h>

int main() {
    int num = 42;
    int *ptr = &num;

    printf("Value of num: %d\n", num);
    printf("Address of num: %p\n", (void*)&num);
    printf("Value of ptr (address): %p\n", (void*)ptr);
    printf("Value pointed by ptr: %d\n", *ptr);

    return 0;
}
```

在这个例子中：

| 表达式 | 含义 |
|--------|------|
| `&num` | 取变量 num 的地址 |
| `int *ptr` | 声明一个指向 int 的指针 |
| `*ptr` | 解引用，获取指针指向的值 |
| `ptr = &num` | 将 num 的地址赋给指针 |

### 指针的大小

指针的大小取决于系统的架构，而不是指向的数据类型：

```c
#include <stdio.h>

int main() {
    int *ip;
    char *cp;
    double *dp;
    void *vp;

    printf("sizeof(int*):   %zu bytes\n", sizeof(ip));
    printf("sizeof(char*):  %zu bytes\n", sizeof(cp));
    printf("sizeof(double*):%zu bytes\n", sizeof(dp));
    printf("sizeof(void*):  %zu bytes\n", sizeof(vp));

    return 0;
}
```

在 64 位系统中，所有指针通常都是 8 字节（64 位）。

## 指针与数组

### 数组名的本质

数组名在大多数表达式中会退化为指向数组首元素的指针：

```c
#include <stdio.h>

int main() {
    int arr[5] = {10, 20, 30, 40, 50};
    int *ptr = arr;  // 等价于 &arr[0]

    // 以下四种写法等价
    printf("arr[2] = %d\n", arr[2]);
    printf("ptr[2] = %d\n", ptr[2]);
    printf("*(arr + 2) = %d\n", *(arr + 2));
    printf("*(ptr + 2) = %d\n", *(ptr + 2));

    return 0;
}
```

### 指针算术

指针算术会自动考虑数据类型的大小：

```c
#include <stdio.h>

int main() {
    int arr[5] = {10, 20, 30, 40, 50};
    int *ptr = arr;

    printf("ptr        = %p\n", (void*)ptr);
    printf("ptr + 1    = %p\n", (void*)(ptr + 1));
    printf("ptr + 2    = %p\n", (void*)(ptr + 2));

    // 差值计算的是元素个数，不是字节数
    printf("(ptr + 3) - ptr = %ld\n", (ptr + 3) - ptr);

    return 0;
}
```

> **注意**：指针算术只在指向数组元素时才有意义。对非数组对象的指针进行算术运算会导致未定义行为。

## 多级指针

### 指向指针的指针

```c
#include <stdio.h>

int main() {
    int num = 42;
    int *ptr1 = &num;
    int **ptr2 = &ptr1;
    int ***ptr3 = &ptr2;

    printf("num    = %d\n", num);
    printf("*ptr1  = %d\n", *ptr1);
    printf("**ptr2 = %d\n", **ptr2);
    printf("***ptr3 = %d\n", ***ptr3);

    // 修改值
    ***ptr3 = 100;
    printf("After modification: num = %d\n", num);

    return 0;
}
```

多级指针常用于动态二维数组和函数参数传递：

```c
#include <stdio.h>
#include <stdlib.h>

// 使用二级指针创建动态二维数组
int** create_matrix(int rows, int cols) {
    int **matrix = malloc(rows * sizeof(int*));
    for (int i = 0; i < rows; i++) {
        matrix[i] = malloc(cols * sizeof(int));
    }
    return matrix;
}

void free_matrix(int **matrix, int rows) {
    for (int i = 0; i < rows; i++) {
        free(matrix[i]);
    }
    free(matrix);
}
```

## 函数指针

### 基本语法

函数指针允许我们将函数作为参数传递，实现回调机制：

```c
#include <stdio.h>

// 函数指针类型定义
typedef int (*CompareFunc)(int, int);

int add(int a, int b) { return a + b; }
int subtract(int a, int b) { return a - b; }
int multiply(int a, int b) { return a * b; }

// 使用函数指针作为参数
int operate(int a, int b, CompareFunc op) {
    return op(a, b);
}

int main() {
    printf("add:      %d\n", operate(10, 5, add));
    printf("subtract: %d\n", operate(10, 5, subtract));
    printf("multiply: %d\n", operate(10, 5, multiply));

    return 0;
}
```

### 回调函数应用

```c
#include <stdio.h>

// 通用排序函数，使用回调比较
typedef int (*CompareFunc)(const void*, const void*);

void bubble_sort(void *arr, size_t n, size_t size, CompareFunc cmp) {
    char *base = arr;
    char temp[size];

    for (size_t i = 0; i < n - 1; i++) {
        for (size_t j = 0; j < n - i - 1; j++) {
            if (cmp(base + j * size, base + (j + 1) * size) > 0) {
                // 交换
                memcpy(temp, base + j * size, size);
                memcpy(base + j * size, base + (j + 1) * size, size);
                memcpy(base + (j + 1) * size, temp, size);
            }
        }
    }
}

int int_cmp(const void *a, const void *b) {
    return (*(int*)a - *(int*)b);
}

int main() {
    int arr[] = {64, 34, 25, 12, 22, 11, 90};
    size_t n = sizeof(arr) / sizeof(arr[0]);

    bubble_sort(arr, n, sizeof(int), int_cmp);

    printf("Sorted array: ");
    for (size_t i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");

    return 0;
}
```

## void 指针

`void*` 是一种通用指针类型，可以指向任何数据类型：

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 通用的内存拷贝函数
void* my_memcpy(void *dest, const void *src, size_t n) {
    char *d = dest;
    const char *s = src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

// 泛型交换函数
void swap(void *a, void *b, size_t size) {
    char temp[size];
    memcpy(temp, a, size);
    memcpy(a, b, size);
    memcpy(b, temp, size);
}

int main() {
    int x = 10, y = 20;
    swap(&x, &y, sizeof(int));
    printf("x = %d, y = %d\n", x, y);

    double a = 1.5, b = 2.5;
    swap(&a, &b, sizeof(double));
    printf("a = %.1f, b = %.1f\n", a, b);

    return 0;
}
```

## const 与指针

`const` 与指针的组合有四种情况，每种含义不同：

| 声明 | 读法 | 含义 |
|------|------|------|
| `int* ptr` | 指向 int 的指针 | 指针和值都可变 |
| `const int* ptr` | 指向常量的指针 | 值不可变，指针可变 |
| `int* const ptr` | 常量指针 | 值可变，指针不可变 |
| `const int* const ptr` | 指向常量的常量指针 | 都不可变 |

```c
#include <stdio.h>

int main() {
    int a = 10, b = 20;

    // 1. 指向常量的指针（常量指针）
    const int *ptr1 = &a;
    // *ptr1 = 30;  // 错误！不能通过 ptr1 修改值
    ptr1 = &b;     // 正确，可以修改指针指向

    // 2. 常量指针
    int *const ptr2 = &a;
    *ptr2 = 30;    // 正确，可以修改值
    // ptr2 = &b;  // 错误！不能修改指针指向

    // 3. 指向常量的常量指针
    const int *const ptr3 = &a;
    // *ptr3 = 40;  // 错误！
    // ptr3 = &b;   // 错误！

    printf("a = %d\n", a);

    return 0;
}
```

## 内存布局与对齐

```c
#include <stdio.h>

struct Example {
    char c;
    int i;
    char d;
};

struct PackedExample {
    char c;
    int i;
    char d;
} __attribute__((packed));

int main() {
    printf("sizeof(Example):      %zu\n", sizeof(struct Example));
    printf("sizeof(PackedExample): %zu\n", sizeof(struct PackedExample));

    struct Example ex;
    printf("Address of c: %p\n", (void*)&ex.c);
    printf("Address of i: %p\n", (void*)&ex.i);
    printf("Address of d: %p\n", (void*)&ex.d);

    return 0;
}
```

## 常见指针陷阱

### 1. 未初始化的指针

```c
int *ptr;       // 野指针，指向随机地址
*ptr = 10;      // 未定义行为！可能导致程序崩溃
```

### 2. 内存泄漏

```c
void leak_example() {
    int *ptr = malloc(sizeof(int) * 100);
    // ... 使用 ptr
    // 忘记 free(ptr) —— 内存泄漏！
}
```

### 3. 悬空指针

```c
int* dangling_pointer() {
    int local = 42;
    return &local;  // 危险！返回局部变量的地址
}
```

### 4. 数组越界

```c
int arr[5] = {1, 2, 3, 4, 5};
int *ptr = arr;
ptr[5] = 10;  // 越界访问！未定义行为
```

## 总结

指针是 C 语言强大而灵活的工具，掌握指针需要理解：

1. **内存模型**：理解变量在内存中的存储方式
2. **类型系统**：指针类型决定了指针算术的步长
3. **生命周期**：确保指针始终指向有效的内存
4. **所有权**：谁分配、谁释放，避免内存泄漏

> "C 语言让你可以做出所有你想要的错误，包括那些你可能没想到的。" —— 对指针最好的描述

通过本文的学习，你应该能够自信地使用指针，并避免常见的陷阱。记住，**理解指针的本质是理解内存**，这是成为优秀 C 程序员的关键。

## 指针与数据结构实现

指针是实现复杂数据结构的基石。通过指针，我们可以构建链表、树、图等动态数据结构。

### 单链表实现

```c
#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
    int data;
    struct Node* next;
} Node;

// 创建新节点
Node* create_node(int value) {
    Node* new_node = (Node*)malloc(sizeof(Node));
    if (new_node == NULL) {
        fprintf(stderr, "内存分配失败\n");
        exit(1);
    }
    new_node->data = value;
    new_node->next = NULL;
    return new_node;
}

// 在头部插入
void push(Node** head, int value) {
    Node* new_node = create_node(value);
    new_node->next = *head;
    *head = new_node;
}

// 在尾部插入
void append(Node** head, int value) {
    Node* new_node = create_node(value);
    
    if (*head == NULL) {
        *head = new_node;
        return;
    }
    
    Node* current = *head;
    while (current->next != NULL) {
        current = current->next;
    }
    current->next = new_node;
}

// 删除指定值
void delete_node(Node** head, int key) {
    Node* temp = *head;
    Node* prev = NULL;
    
    // 头节点就是要删除的节点
    if (temp != NULL && temp->data == key) {
        *head = temp->next;
        free(temp);
        return;
    }
    
    // 查找要删除的节点
    while (temp != NULL && temp->data != key) {
        prev = temp;
        temp = temp->next;
    }
    
    if (temp == NULL) return; // 未找到
    
    prev->next = temp->next;
    free(temp);
}

// 打印链表
void print_list(Node* head) {
    Node* current = head;
    while (current != NULL) {
        printf("%d -> ", current->data);
        current = current->next;
    }
    printf("NULL\n");
}

// 释放整个链表
void free_list(Node* head) {
    Node* current = head;
    while (current != NULL) {
        Node* next = current->next;
        free(current);
        current = next;
    }
}

int main() {
    Node* head = NULL;
    
    append(&head, 1);
    append(&head, 2);
    append(&head, 3);
    push(&head, 0);
    
    printf("链表: ");
    print_list(head);  // 0 -> 1 -> 2 -> 3 -> NULL
    
    delete_node(&head, 2);
    printf("删除 2 后: ");
    print_list(head);  // 0 -> 1 -> 3 -> NULL
    
    free_list(head);
    return 0;
}
```

### 二叉搜索树实现

```c
#include <stdio.h>
#include <stdlib.h>

typedef struct TreeNode {
    int data;
    struct TreeNode* left;
    struct TreeNode* right;
} TreeNode;

// 创建新节点
TreeNode* create_tree_node(int value) {
    TreeNode* node = (TreeNode*)malloc(sizeof(TreeNode));
    if (node == NULL) {
        fprintf(stderr, "内存分配失败\n");
        exit(1);
    }
    node->data = value;
    node->left = node->right = NULL;
    return node;
}

// 插入节点
TreeNode* insert(TreeNode* root, int value) {
    if (root == NULL) {
        return create_tree_node(value);
    }
    
    if (value < root->data) {
        root->left = insert(root->left, value);
    } else if (value > root->data) {
        root->right = insert(root->right, value);
    }
    
    return root;
}

// 中序遍历（左-根-右）
void inorder_traversal(TreeNode* root) {
    if (root != NULL) {
        inorder_traversal(root->left);
        printf("%d ", root->data);
        inorder_traversal(root->right);
    }
}

// 查找最小值
TreeNode* find_min(TreeNode* root) {
    if (root == NULL) return NULL;
    while (root->left != NULL) {
        root = root->left;
    }
    return root;
}

// 删除节点
TreeNode* delete_node(TreeNode* root, int value) {
    if (root == NULL) return root;
    
    if (value < root->data) {
        root->left = delete_node(root->left, value);
    } else if (value > root->data) {
        root->right = delete_node(root->right, value);
    } else {
        // 找到要删除的节点
        if (root->left == NULL) {
            TreeNode* temp = root->right;
            free(root);
            return temp;
        } else if (root->right == NULL) {
            TreeNode* temp = root->left;
            free(root);
            return temp;
        }
        
        // 有两个子节点：找到右子树的最小值
        TreeNode* temp = find_min(root->right);
        root->data = temp->data;
        root->right = delete_node(root->right, temp->data);
    }
    
    return root;
}

// 释放树
void free_tree(TreeNode* root) {
    if (root != NULL) {
        free_tree(root->left);
        free_tree(root->right);
        free(root);
    }
}

int main() {
    TreeNode* root = NULL;
    int values[] = {50, 30, 70, 20, 40, 60, 80};
    int n = sizeof(values) / sizeof(values[0]);
    
    for (int i = 0; i < n; i++) {
        root = insert(root, values[i]);
    }
    
    printf("中序遍历: ");
    inorder_traversal(root);  // 20 30 40 50 60 70 80
    printf("\n");
    
    root = delete_node(root, 30);
    printf("删除 30 后: ");
    inorder_traversal(root);  // 20 40 50 60 70 80
    printf("\n");
    
    free_tree(root);
    return 0;
}
```

### 指针实现的数据结构对比

| 数据结构 | 插入 | 删除 | 查找 | 空间复杂度 | 特点 |
|---------|------|------|------|-----------|------|
| 单链表 | O(1) | O(n) | O(n) | O(n) | 实现简单，顺序访问 |
| 双向链表 | O(1) | O(1) | O(n) | O(n) | 双向遍历，删除高效 |
| 二叉搜索树 | O(h) | O(h) | O(h) | O(n) | 有序存储，h为树高 |
| 平衡二叉树 | O(log n) | O(log n) | O(log n) | O(n) | 自平衡，保证性能 |

## 指针与内存池技术

内存池是一种预先分配大块内存，然后按需切分使用的技术，可以减少内存碎片和分配开销。

### 简单内存池实现

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct MemoryPool {
    uint8_t* buffer;      // 内存池缓冲区
    size_t buffer_size;   // 总大小
    size_t used;          // 已使用大小
    size_t block_size;    // 块大小
    void** free_list;     // 空闲块链表
    size_t free_count;    // 空闲块数量
} MemoryPool;

// 创建内存池
MemoryPool* pool_create(size_t block_size, size_t block_count) {
    MemoryPool* pool = (MemoryPool*)malloc(sizeof(MemoryPool));
    if (!pool) return NULL;
    
    pool->buffer_size = block_size * block_count;
    pool->buffer = (uint8_t*)malloc(pool->buffer_size);
    if (!pool->buffer) {
        free(pool);
        return NULL;
    }
    
    pool->block_size = block_size;
    pool->used = 0;
    pool->free_list = (void**)malloc(sizeof(void*) * block_count);
    pool->free_count = 0;
    
    // 初始化空闲链表
    for (size_t i = 0; i < block_count; i++) {
        pool->free_list[i] = pool->buffer + i * block_size;
    }
    pool->free_count = block_count;
    
    return pool;
}

// 从内存池分配
void* pool_alloc(MemoryPool* pool) {
    if (pool->free_count > 0) {
        return pool->free_list[--pool->free_count];
    }
    
    // 内存池满了，回退到 malloc
    return malloc(pool->block_size);
}

// 释放到内存池
void pool_free(MemoryPool* pool, void* ptr) {
    if (ptr >= (void*)pool->buffer && 
        ptr < (void*)(pool->buffer + pool->buffer_size)) {
        // 是内存池中的块
        pool->free_list[pool->free_count++] = ptr;
    } else {
        // 不是内存池中的块
        free(ptr);
    }
}

// 销毁内存池
void pool_destroy(MemoryPool* pool) {
    if (pool) {
        free(pool->buffer);
        free(pool->free_list);
        free(pool);
    }
}

// 使用示例
typedef struct Particle {
    float x, y, z;
    float vx, vy, vz;
    int lifetime;
} Particle;

int main() {
    MemoryPool* pool = pool_create(sizeof(Particle), 1000);
    
    // 分配粒子
    Particle* p1 = (Particle*)pool_alloc(pool);
    p1->x = 100.0f;
    p1->y = 200.0f;
    p1->lifetime = 100;
    
    // 使用完释放
    pool_free(pool, p1);
    
    pool_destroy(pool);
    return 0;
}
```

### 内存池优势对比

| 特性 | 标准 malloc/free | 内存池 |
|------|-----------------|--------|
| 分配速度 | 慢（可能系统调用） | 快（O(1)） |
| 内存碎片 | 容易产生 | 极少 |
| 内存局部性 | 不确定 | 连续存储，缓存友好 |
| 线程安全 | 依赖实现 | 需要额外同步 |
| 适用场景 | 通用 | 固定大小对象频繁分配 |

## 高级指针技巧

### 不透明指针（Opaque Pointer）

隐藏实现细节，只暴露接口：

```c
// api.h - 公开接口
#ifndef API_H
#define API_H

typedef struct Database* DatabaseHandle;

DatabaseHandle db_open(const char* path);
int db_query(DatabaseHandle db, const char* sql);
void db_close(DatabaseHandle db);

#endif
```

```c
// database.c - 实现细节
#include "api.h"
#include <stdlib.h>
#include <string.h>

struct Database {
    char* path;
    int connection_count;
    // 其他内部字段...
};

DatabaseHandle db_open(const char* path) {
    DatabaseHandle db = (DatabaseHandle)malloc(sizeof(struct Database));
    db->path = strdup(path);
    db->connection_count = 0;
    return db;
}

int db_query(DatabaseHandle db, const char* sql) {
    // 实现查询逻辑
    (void)sql;
    db->connection_count++;
    return 0;
}

void db_close(DatabaseHandle db) {
    free(db->path);
    free(db);
}
```

###  tagged union（带标签联合体）

```c
#include <stdio.h>

typedef enum {
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_STRING,
    TYPE_POINTER
} ValueType;

typedef struct {
    ValueType type;
    union {
        int i;
        float f;
        char* s;
        void* p;
    } data;
} Value;

void print_value(Value* v) {
    switch (v->type) {
        case TYPE_INT:
            printf("整数: %d\n", v->data.i);
            break;
        case TYPE_FLOAT:
            printf("浮点数: %.2f\n", v->data.f);
            break;
        case TYPE_STRING:
            printf("字符串: %s\n", v->data.s);
            break;
        case TYPE_POINTER:
            printf("指针: %p\n", v->data.p);
            break;
    }
}

int main() {
    Value v1 = {.type = TYPE_INT, .data.i = 42};
    Value v2 = {.type = TYPE_STRING, .data.s = "Hello"};
    
    print_value(&v1);
    print_value(&v2);
    
    return 0;
}
```

### 指针别名与 restrict 关键字

```c
#include <stdio.h>

// restrict 承诺：指针是该内存唯一且最初的访问方式
void vector_add(
    int* restrict dest,
    const int* restrict src1,
    const int* restrict src2,
    size_t n
) {
    for (size_t i = 0; i < n; i++) {
        dest[i] = src1[i] + src2[i];
    }
}

int main() {
    int a[] = {1, 2, 3, 4, 5};
    int b[] = {10, 20, 30, 40, 50};
    int c[5];
    
    vector_add(c, a, b, 5);
    
    for (int i = 0; i < 5; i++) {
        printf("%d ", c[i]);  // 11 22 33 44 55
    }
    printf("\n");
    
    return 0;
}
```

| 关键字 | 作用 | 使用场景 |
|--------|------|---------|
| `const` | 值不可变 | 保护输入数据 |
| `volatile` | 禁止优化 | 硬件寄存器、信号处理 |
| `restrict` | 指针别名提示 | 高性能计算、向量化 |

$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour'
),
(
    1,
    'Elixir 并发与容错',
    'elixir-concurrency',
    '深入探索 Elixir 的并发模型和容错机制，从 OTP 进程到 Supervisor 监督树，理解 Actor 模型和 Let it crash 哲学，构建高可用的分布式系统。',
    $doc$
# Elixir 并发与容错：构建高可用系统

Elixir 构建在 Erlang VM（BEAM）之上，继承了 Erlang 强大的并发和容错能力。本文将深入探讨 Elixir 的并发模型、进程隔离、Supervisor 监督机制以及分布式系统的构建方法。

## 为什么选择 Elixir？

Elixir 不是另一种 Web 框架，而是一种全新的编程范式。它基于 **Actor 模型**，提供了轻量级进程和消息传递机制，让并发编程变得简单而安全。

> WhatsApp 使用 Erlang/OTP 处理每天超过 650 亿条消息，每台服务器维护超过 200 万个并发连接。这就是 BEAM 虚拟机的实力。

## Elixir 进程模型

### 轻量级进程

在 Elixir 中，"进程"不是操作系统进程，而是由 BEAM 虚拟机管理的轻量级执行单元：

```elixir
# 创建一个新进程
pid = spawn(fn ->
  IO.puts("Hello from a new process!")
  IO.puts("Process PID: #{inspect(self())}")
end)

IO.puts("Main process PID: #{inspect(self())}")
IO.puts("Spawned process PID: #{inspect(pid)}")
```

特点对比：

| 特性 | OS 进程 | Elixir 进程 |
|------|---------|-------------|
| 内存占用 | MB 级别 | ~300 字节 |
| 创建时间 | 毫秒级 | 微秒级 |
| 最大数量 | 数千 | 数百万 |
| 通信方式 | 共享内存 | 消息传递 |
| 调度 | 抢占式 | 协作式 |

### 进程隔离

每个 Elixir 进程都有自己独立的内存空间，进程之间不共享状态：

```elixir
defmodule Counter do
  def start(initial_value \\ 0) do
    spawn(fn -> loop(initial_value) end)
  end

  defp loop(current_value) do
    receive do
      {:get, caller} ->
        send(caller, {:value, current_value})
        loop(current_value)

      {:increment} ->
        loop(current_value + 1)

      {:decrement} ->
        loop(current_value - 1)

      {:add, amount} ->
        loop(current_value + amount)
    end
  end
end

# 使用示例
counter = Counter.start(10)

send(counter, {:increment})
send(counter, {:add, 5})
send(counter, {:get, self()})

receive do
  {:value, value} -> IO.puts("Current value: #{value}")
after
  1000 -> IO.puts("Timeout!")
end
```

## 消息传递机制

### 异步消息

Elixir 进程通过异步消息传递进行通信：

```elixir
defmodule Messenger do
  def send_message(to_pid, message) do
    send(to_pid, {self(), message})
  end

  def wait_for_reply(timeout \\\\ 5000) do
    receive do
      {_from, reply} -> {:ok, reply}
    after
      timeout -> {:error, :timeout}
    end
  end
end

# 创建接收进程
receiver = spawn(fn ->
  receive do
    {from, msg} ->
      IO.puts("Received: #{msg}")
      send(from, {self(), "Reply: #{msg}"})
  end
end)

Messenger.send_message(receiver, "Hello Elixir!")
case Messenger.wait_for_reply() do
  {:ok, reply} -> IO.puts("Got reply: #{reply}")
  {:error, reason} -> IO.puts("Failed: #{reason}")
end
```

### 消息邮箱

每个进程都有一个消息邮箱，消息按到达顺序排队：

```elixir
defmodule MessageProcessor do
  def process_messages do
    receive do
      message ->
        IO.puts("Processing: #{inspect(message)}")
        process_messages()
    end
  end
end

processor = spawn(&MessageProcessor.process_messages/0)

send(processor, :first)
send(processor, :second)
send(processor, {:complex, [1, 2, 3]})
```

## GenServer：状态机模式

GenServer 是 OTP 行为（Behaviour）之一，提供了一种标准化的方式来构建有状态的服务器进程：

```elixir
defmodule KeyValueStore do
  use GenServer

  # 客户端 API
  def start_link(initial_state \\\\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  # 服务器回调
  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end
end

# 使用示例
{:ok, _pid} = KeyValueStore.start_link()
KeyValueStore.put(:name, "Elixir")
KeyValueStore.put(:version, "1.15")
IO.inspect(KeyValueStore.get(:name))
```

### GenServer 回调详解

| 回调函数 | 用途 | 返回值 |
|----------|------|--------|
| `init/1` | 初始化状态 | `{:ok, state}` |
| `handle_call/3` | 同步请求 | `{:reply, reply, state}` |
| `handle_cast/2` | 异步请求 | `{:noreply, state}` |
| `handle_info/2` | 处理普通消息 | `{:noreply, state}` |
| `terminate/2` | 清理资源 | 任意 |

## Supervisor 监督策略

### 容错哲学：Let it crash

Elixir 的核心哲学是 **Let it crash**。进程崩溃不应该影响整个系统，Supervisor 会负责重启失败的进程。

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # 工作进程
      {KeyValueStore, %{}},
      # 另一个工作进程
      {MyApp.Worker, []},
      # 动态监督者
      {DynamicSupervisor, strategy: :one_for_one, name: MyApp.DynamicSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
```

### 监督策略对比

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| `:one_for_one` | 只重启失败的子进程 | 独立的服务 |
| `:one_for_all` | 重启所有子进程 | 相互依赖的服务 |
| `:rest_for_one` | 重启失败进程及其后续进程 | 有启动顺序依赖 |
| `:simple_one_for_one` | 动态添加子进程 | 需要动态创建进程 |

### 重启策略

```elixir
defmodule MyApp.Worker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    # 如果初始化失败，Supervisor 会根据重启策略处理
    case connect_to_database(args) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> {:stop, reason}
    end
  end

  defp connect_to_database(_args) do
    # 模拟数据库连接
    {:ok, %{} }
  end
end
```

## 容错机制实践

### 链接进程（Linking）

进程可以相互链接，一个进程崩溃会导致链接的进程也崩溃：

```elixir
defmodule LinkExample do
  def run do
    parent = self()

    child = spawn_link(fn ->
      receive do
        :crash -> raise "Simulated error"
        :normal -> IO.puts("Normal exit")
      end
    end)

    Process.flag(:trap_exit, true)

    send(child, :crash)

    receive do
      {:EXIT, ^child, reason} ->
        IO.puts("Child exited with reason: #{inspect(reason)}")
    end
  end
end
```

### 监控进程（Monitoring）

监控是单向的，被监控进程崩溃不会导致监控进程崩溃：

```elixir
defmodule MonitorExample do
  def run do
    target = spawn(fn ->
      Process.sleep(1000)
      exit(:normal)
    end)

    ref = Process.monitor(target)

    receive do
      {:DOWN, ^ref, :process, ^target, reason} ->
        IO.puts("Process down: #{inspect(reason)}")
    end
  end
end
```

### 选择策略

| 特性 | Link | Monitor |
|------|------|---------|
| 方向 | 双向 | 单向 |
| 影响 | 相互影响 | 仅通知 |
| 用途 | 构建 Supervision Tree | 观察进程状态 |
| 退出传播 | 是 | 否 |

## 分布式 Elixir

### 节点间通信

Elixir 进程可以在不同机器间透明通信：

```elixir
# 启动节点 1（机器 A）
# iex --sname node1@machine_a --cookie secret

# 启动节点 2（机器 B）
# iex --sname node2@machine_b --cookie secret

# 在 node2 上连接到 node1
Node.connect(:"node1@machine_a")

# 在 node2 上向 node1 发送消息
send({:some_process, :"node1@machine_a"}, :hello_from_node2)

# 在 node1 上接收
receive do
  msg -> IO.puts("Received: #{inspect(msg)}")
end
```

### 分布式任务

```elixir
defmodule DistributedTask do
  def run_on_all_nodes(task) do
    nodes = [Node.self() | Node.list()]

    Enum.map(nodes, fn node ->
      Task.Supervisor.async_nolink({MyApp.TaskSupervisor, node}, fn ->
        result = task.()
        {node, result}
      end)
    end)
    |> Enum.map(&Task.await/1)
  end
end

# 在所有节点上执行计算
results = DistributedTask.run_on_all_nodes(fn ->
  # 计算密集型任务
  Enum.sum(1..1_000_000)
end)

IO.inspect(results)
```

## 实际应用：构建容错计数器

```elixir
defmodule FaultTolerantCounter do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def increment do
    GenServer.cast(__MODULE__, :increment)
  end

  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  @impl true
  def init(state) do
    # 设置陷阱退出，处理链接进程的错误
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    IO.puts("Linked process exited: #{inspect(reason)}")
    {:noreply, state}
  end
end

# Supervisor 配置
defmodule CounterSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {FaultTolerantCounter, []}
    ]

    # 使用 transient 重启策略，只在异常退出时重启
    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 10
    )
  end
end
```

## OTP Application 与系统启动

完整的 Elixir/Erlang 系统通常以 OTP Application 的形式组织，它定义了应用的启动顺序、依赖关系和生命周期。

### Application 行为

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # 启动 ETS 表
      {MyApp.Cache, []},
      # 启动 GenServer
      {MyApp.ConfigStore, %{}},
      # 启动 Supervisor
      MyApp.Supervisor,
      # 启动动态监督者
      {DynamicSupervisor, strategy: :one_for_one, name: MyApp.TaskSupervisor}
    ]

    # 使用 one_for_one 监督策略
    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.TopSupervisor)
  end
end
```

### 启动阶段与依赖

| 启动阶段 | 说明 | 常用操作 |
|----------|------|----------|
| `compile` | 编译代码和依赖 | N/A |
| `load` | 加载 application 资源文件 | 读取 `.app` 文件 |
| `start` | 调用 `Application.start/2` | 启动监督树 |
| `临时应用` | 不强制要求 | 可选依赖 |
| `永久应用` | 崩溃时整个节点停止 | 核心依赖 |

```elixir
# mix.exs 中配置 application
def application do
  [
    mod: {MyApp.Application, []},
    extra_applications: [:logger, :runtime_tools]
  ]
end

# 启动应用
Application.ensure_all_started(:my_app)
```

## ETS 与并发数据共享

虽然 Elixir 强调"不共享状态"，但 ETS（Erlang Term Storage）提供了一种进程间高效共享数据的机制。

### ETS 表类型与用例

```elixir
defmodule MyApp.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    # 创建 public ETS 表，允许任何进程读写
    :ets.new(__MODULE__, [
      :set,         # 表类型：set（唯一键）
      :public,      # 访问权限
      :named_table, # 使用模块名作为表名
      read_concurrency: true,
      write_concurrency: true
    ])
    {:ok, nil}
  end

  def put(key, value) do
    :ets.insert(__MODULE__, {key, value})
  end

  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end
end
```

| ETS 表类型 | 特点 | 时间复杂度 | 适用场景 |
|-----------|------|-----------|----------|
| `:set` | 键唯一，无序 | O(1) | 键值缓存 |
| `:ordered_set` | 键唯一，有序 | O(log N) | 范围查询 |
| `:bag` | 键可重复，值唯一 | O(1) | 多值索引 |
| `:duplicate_bag` | 键和值都可重复 | O(1) | 日志存储 |

### ETS 安全模型

```elixir
# ETS 表归创建它的进程所有
# 所有者进程终止时，ETS 表会被销毁
# 可以通过将 ETS 所有者设为 Supervisor 下的 GenServer 来保证持久性

# 使用 :ets.give_away/3 转移表所有权
defmodule ETSOwner do
  use GenServer

  def init(_) do
    table = :ets.new(:my_table, [:set, :public])
    {:ok, table}
  end

  # 监控使用 ETS 的进程
  def monitor_user(pid) do
    Process.monitor(pid)
  end
end
```

## 并发测试与 ExUnit

Elixir 提供了强大的测试工具 ExUnit，特别适合测试并发代码。

### 异步测试

```elixir
defmodule MyApp.CacheTest do
  use ExUnit.Case, async: true

  setup do
    # 每个异步测试都有独立的进程
    {:ok, _pid} = MyApp.Cache.start_link([])
    :ok
  end

  test "stores and retrieves values" do
    MyApp.Cache.put(:user_1, %{name: "Alice"})
    assert {:ok, %{name: "Alice"}} == MyApp.Cache.get(:user_1)
  end

  test "returns error for missing keys" do
    assert :error == MyApp.Cache.get(:missing)
  end
end
```

### 测试并发行为

```elixir
defmodule CounterLoadTest do
  use ExUnit.Case

  test "concurrent increments are atomic" do
    {:ok, pid} = AtomicCounter.start_link(0)

    tasks = for _ <- 1..100 do
      Task.async(fn ->
        for _ <- 1..1000 do
          AtomicCounter.increment(pid)
        end
      end)
    end

    Enum.each(tasks, &Task.await/1)
    assert AtomicCounter.get(pid) == 100_000
  end

  test "process exit is detected" do
    pid = spawn(fn -> Process.exit(self(), :kill) end)
    ref = Process.monitor(pid)

    assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1000
  end
end
```

### ExUnit 特性一览

| 特性 | 语法 | 说明 |
|------|------|------|
| 异步测试 | `async: true` | 测试并行运行 |
| 临时捕获 | `capture_log` | 捕获日志输出 |
| 超时控制 | `@tag timeout: 5000` | 自定义测试超时 |
| 跳过测试 | `@tag :skip` | 跳过某些测试 |
| 测试分组 | `describe "group" do` | 逻辑分组 |
| 共享 setup | `setup_all` | 每个测试模块只执行一次 |

## 总结

Elixir 的并发和容错能力源于其独特的设计哲学：

1. **隔离性**：进程完全隔离，一个崩溃不影响其他
2. **监督**：Supervisor 自动重启失败进程
3. **消息传递**：避免共享状态带来的复杂性
4. **热升级**：不停机更新运行中的系统
5. **分布式透明**：跨节点通信与本地通信 API 一致
6. **OTP 框架**：Application、GenServer、Supervisor 提供标准化架构
7. **ETS**：在必要时提供高效并发数据共享
8. **测试友好**：ExUnit 原生支持并发测试

> "Let it crash" 不是忽视错误，而是设计系统时的基本假设 —— 组件会失败，但系统必须继续运行。

通过掌握这些概念，你可以构建出真正高可用、容错的分布式系统，充分利用多核 CPU 和集群环境。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes'
),
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
    'published',
    NOW() - INTERVAL '15 minutes',
    NOW() - INTERVAL '15 minutes',
    NOW() - INTERVAL '15 minutes'
),
(
    1,
    'Swift 现代语法速览',
    'swift-modern-syntax',
    '全面梳理 Swift 现代语法特性，从可选类型到属性包装器，深入理解值类型与引用类型、协议扩展、泛型和错误处理，掌握 Swift 编程的核心概念和最佳实践。',
    $doc$
# Swift 现代语法速览

Swift 是 Apple 推出的现代编程语言，结合了 C 和 Objective-C 的优点，同时引入了函数式编程和类型安全的特性。本文将全面梳理 Swift 的核心语法，帮助你快速掌握这门语言。

## 为什么选择 Swift？

Swift 的设计目标是安全、快速、表达力强。它消除了 C 语言家族中许多不安全的特性，同时提供了现代化的语法和强大的类型系统。

> Swift 结合了编译型语言的性能和脚本语言的交互性，是现代 Apple 平台开发的首选语言。

## 基础语法

### 常量与变量

```swift
// 常量 - 不可变
let pi = 3.14159
let greeting = "Hello, Swift!"

// 变量 - 可变
var counter = 0
counter += 1

// 类型注解（通常可以省略，编译器会自动推断）
let explicitDouble: Double = 70.0
let implicitDouble = 70.0 // 同样是 Double

// 多行字符串
let multiline = """
    Swift is a powerful and intuitive
    programming language for iOS, iPadOS,
    macOS, watchOS, and tvOS.
    """
```

### 基本数据类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `Int` | 整数 | `let age: Int = 25` |
| `Double` | 双精度浮点 | `let price: Double = 19.99` |
| `String` | 字符串 | `let name = "Swift"` |
| `Bool` | 布尔 | `let isActive = true` |
| `Array` | 数组 | `let numbers = [1, 2, 3]` |
| `Dictionary` | 字典 | `let scores = ["A": 90]` |

### 字符串插值和运算

```swift
let name = "World"
let message = "Hello, \(name)!"

// 字符串操作
var str = "Swift"
str.append("!")
str += " Programming"

// 多行字符串保留格式
let poem = """
    Swift as the wind,
    Strong as a mountain,
    Elegant as poetry.
    """
```

## 可选类型（Optionals）

### 什么是可选类型

可选类型表示一个值可能存在，也可能不存在（nil）：

```swift
// 可选整数
var optionalNumber: Int? = 42
optionalNumber = nil

// 强制解包（危险！如果为 nil 会崩溃）
let forced = optionalNumber!

// 安全解包方式
if let number = optionalNumber {
    print("The number is \(number)")
} else {
    print("No number")
}

// Nil 合并运算符
let defaultNumber = optionalNumber ?? 0

// 可选链
let uppercased = optionalNumber?.description.uppercased()
```

### guard 语句

`guard` 语句用于提前退出，提高代码可读性：

```swift
func processUser(age: Int?, name: String?) {
    guard let validAge = age, validAge >= 0 else {
        print("Invalid age")
        return
    }

    guard let validName = name, !validName.isEmpty else {
        print("Invalid name")
        return
    }

    print("User: \(validName), Age: \(validAge)")
}

// 使用
processUser(age: 25, name: "Alice")  // 成功
processUser(age: -5, name: "Bob")    // Invalid age
processUser(age: 30, name: nil)      // Invalid name
```

### if let 和 guard let 对比

| 特性 | `if let` | `guard let` |
|------|----------|-------------|
| 作用域 | 仅在 if 块内 | 在 guard 之后的代码 |
| 使用场景 | 条件分支处理 | 前置条件检查 |
| 代码风格 | 嵌套可能较深 | 减少嵌套，提前退出 |

## 集合类型

### 数组和字典

```swift
// 数组
var fruits = ["Apple", "Banana", "Orange"]
fruits.append("Mango")
fruits.insert("Grape", at: 1)
let firstFruit = fruits[0]

// 字典
var scores: [String: Int] = [
    "Alice": 95,
    "Bob": 87,
    "Charlie": 92
]

scores["David"] = 88
if let aliceScore = scores["Alice"] {
    print("Alice scored \(aliceScore)")
}

// 遍历字典
for (name, score) in scores {
    print("\(name): \(score)")
}
```

### Set 集合

```swift
let favoriteGenres: Set<String> = ["Rock", "Classical", "Hip hop"]
let otherGenres: Set<String> = ["Jazz", "Rock", "Electronic"]

// 集合运算
let intersection = favoriteGenres.intersection(otherGenres)
let union = favoriteGenres.union(otherGenres)
let difference = favoriteGenres.symmetricDifference(otherGenres)

print("Both like: \(intersection)")
print("All genres: \(union)")
```

## 控制流

### 高级 switch

```swift
let character: Character = "a"

switch character {
case "a", "e", "i", "o", "u":
    print("\(character) is a vowel")
case "b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
     "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z":
    print("\(character) is a consonant")
default:
    print("\(character) is not a letter")
}

// 区间匹配
let count = 62
switch count {
case 0:
    print("none")
case 1..<5:
    print("a few")
case 5..<12:
    print("several")
case 12..<100:
    print("dozens")
case 100..<1000:
    print("hundreds")
default:
    print("many")
}

// 元组匹配
let point = (1, 1)
switch point {
case (0, 0):
    print("origin")
case (_, 0):
    print("on x-axis")
case (0, _):
    print("on y-axis")
case (-2...2, -2...2):
    print("inside the box")
default:
    print("outside")
}
```

### for-in 循环

```swift
// 遍历范围
for index in 1...5 {
    print("\(index) times 5 is \(index * 5)")
}

// 遍历数组
let names = ["Anna", "Alex", "Brian", "Jack"]
for name in names {
    print("Hello, \(name)!")
}

// 遍历字典
let numberOfLegs = ["spider": 8, "ant": 6, "cat": 4]
for (animalName, legCount) in numberOfLegs {
    print("\(animalName)s have \(legCount) legs")
}

// 带索引的遍历
for (index, name) in names.enumerated() {
    print("\(index + 1). \(name)")
}

// stride 函数
let minutes = 60
let minuteInterval = 5
for tickMark in stride(from: 0, to: minutes, by: minuteInterval) {
    print("Tick mark at \(tickMark) minutes")
}
```

## 函数和闭包

### 函数定义

```swift
// 基本函数
func greet(person: String) -> String {
    return "Hello, \(person)!"
}

// 参数标签和参数名
func greet(person: String, from hometown: String) -> String {
    return "Hello \(person)! Glad you could visit from \(hometown)."
}

let greeting = greet(person: "Bill", from: "Cupertino")

// 默认参数
func greet(person: String, nicely: Bool = true) -> String {
    if nicely {
        return "Hello, \(person)!"
    } else {
        return "Oh no, it's \(person) again..."
    }
}

print(greet(person: "Tim"))           // Hello, Tim!
print(greet(person: "Tim", nicely: false))  // Oh no, it's Tim again...

// 可变参数
func arithmeticMean(_ numbers: Double...) -> Double {
    var total: Double = 0
    for number in numbers {
        total += number
    }
    return total / Double(numbers.count)
}

print(arithmeticMean(1, 2, 3, 4, 5))
```

### 闭包（Closures）

```swift
// 基本闭包
let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]

// 完整写法
let reversedNames = names.sorted(by: { (s1: String, s2: String) -> Bool in
    return s1 > s2
})

// 类型推断简化
let reversedNames2 = names.sorted(by: { s1, s2 in return s1 > s2 })

// 隐式返回
let reversedNames3 = names.sorted(by: { s1, s2 in s1 > s2 })

// 简写参数名
let reversedNames4 = names.sorted(by: { \$0 > \$1 })

// 尾随闭包
let reversedNames5 = names.sorted { \$0 > \$1 }

// 捕获值
func makeIncrementer(forIncrement amount: Int) -> () -> Int {
    var runningTotal = 0
    func incrementer() -> Int {
        runningTotal += amount
        return runningTotal
    }
    return incrementer
}

let incrementByTen = makeIncrementer(forIncrement: 10)
print(incrementByTen()) // 10
print(incrementByTen()) // 20
```

## 结构体与类

### 值类型 vs 引用类型

```swift
// 结构体 - 值类型
struct Resolution {
    var width = 0
    var height = 0
}

// 类 - 引用类型
class VideoMode {
    var resolution = Resolution()
    var interlaced = false
    var frameRate = 0.0
    var name: String?
}

let hd = Resolution(width: 1920, height: 1080)
var cinema = hd // 值拷贝
cinema.width = 2048

print("hd width: \(hd.width)")         // 1920
print("cinema width: \(cinema.width)")  // 2048

let tenEighty = VideoMode()
tenEighty.resolution = hd
tenEighty.interlaced = true
tenEighty.name = "1080i"
tenEighty.frameRate = 25.0

let alsoTenEighty = tenEighty // 引用拷贝
alsoTenEighty.frameRate = 30.0

print("tenEighty frameRate: \(tenEighty.frameRate)")  // 30.0
```

### 属性观察器

```swift
class StepCounter {
    var totalSteps: Int = 0 {
        willSet(newTotalSteps) {
            print("About to set totalSteps to \(newTotalSteps)")
        }
        didSet {
            if totalSteps > oldValue  {
                print("Added \(totalSteps - oldValue) steps")
            }
        }
    }
}

let stepCounter = StepCounter()
stepCounter.totalSteps = 200
// About to set totalSteps to 200
// Added 200 steps
stepCounter.totalSteps = 360
// About to set totalSteps to 360
// Added 160 steps
```

## 协议与扩展

### 协议定义

```swift
protocol FullyNamed {
    var fullName: String { get }
}

protocol RandomNumberGenerator {
    func random() -> Double
}

// 协议继承
protocol NamedAndAged: FullyNamed {
    var age: Int { get }
}

// 遵循协议
struct Person: FullyNamed {
    var firstName: String
    var lastName: String

    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

let john = Person(firstName: "John", lastName: "Appleseed")
print(john.fullName)
```

### 扩展

```swift
// 扩展现有类型
extension Int {
    func repetitions(task: () -> Void) {
        for _ in 0..<self {
            task()
        }
    }

    var squared: Int {
        return self * self
    }
}

3.repetitions {
    print("Hello!")
}

print(5.squared) // 25

// 协议扩展提供默认实现
extension RandomNumberGenerator {
    func randomBool() -> Bool {
        return random() > 0.5
    }
}
```

## 泛型

### 泛型函数和类型

```swift
// 泛型函数
func swapTwoValues<T>(_ a: inout T, _ b: inout T) {
    let temporaryA = a
    a = b
    b = temporaryA
}

var someInt = 3
var anotherInt = 107
swapTwoValues(&someInt, &anotherInt)

var someString = "hello"
var anotherString = "world"
swapTwoValues(&someString, &anotherString)

// 泛型类型
struct Stack<Element> {
    private var items: [Element] = []

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element {
        return items.removeLast()
    }

    var topItem: Element? {
        return items.isEmpty ? nil : items[items.count - 1]
    }

    var isEmpty: Bool {
        return items.isEmpty
    }
}

var stackOfStrings = Stack<String>()
stackOfStrings.push("uno")
stackOfStrings.push("dos")
stackOfStrings.push("tres")
print(stackOfStrings.pop()) // tres

// 泛型约束
func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
    for (index, value) in array.enumerated() {
        if value == valueToFind {
            return index
        }
    }
    return nil
}
```

## 错误处理

### 定义和抛出错误

```swift
enum PrinterError: Error {
    case outOfPaper
    case noToner
    case onFire
}

func send(job: Int, toPrinter printerName: String) throws -> String {
    if printerName == "Never Has Toner" {
        throw PrinterError.noToner
    }
    return "Job sent"
}

// 使用 do-catch
func processPrintJob() {
    do {
        let printerResponse = try send(job: 1040, toPrinter: "Bi Sheng")
        print(printerResponse)
    } catch PrinterError.onFire {
        print("I'll just put this over here, with the rest of the fire.")
    } catch let printerError as PrinterError {
        print("Printer error: \(printerError).")
    } catch {
        print(error)
    }
}

// try? 转换为可选
let printerSuccess = try? send(job: 1884, toPrinter: "Mergenthaler")
let printerFailure = try? send(job: 1885, toPrinter: "Never Has Toner")

// defer
func processFile(filename: String) throws {
    let file = open(filename)
    defer {
        close(file)
    }
    // 处理文件...
    // 无论是否抛出错误，defer 都会执行
}
```

## 属性包装器

```swift
@propertyWrapper
struct TwelveOrLess {
    private var number = 0
    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, 12) }
    }
}

struct SmallRectangle {
    @TwelveOrLess var height: Int
    @TwelveOrLess var width: Int
}

var rectangle = SmallRectangle()
print(rectangle.height) // 0

rectangle.height = 10
print(rectangle.height) // 10

rectangle.height = 24
print(rectangle.height) // 12
```

## 总结

Swift 是一门现代化的编程语言，提供了丰富的特性：

1. **类型安全**：可选类型消除空指针异常
2. **值类型优先**：结构体和枚举都是值类型，减少副作用
3. **协议导向**：通过协议和扩展实现多态
4. **函数式特性**：闭包、高阶函数、不可变性
5. **现代语法**：类型推断、字符串插值、模式匹配

> Swift 的设计哲学是安全、快速、表达力强。它不仅仅是一门 iOS 开发语言，也是一门通用的现代编程语言。

通过本文的学习，你应该已经掌握了 Swift 的核心语法特性，可以开始构建 iOS、macOS 或其他平台的应用程序了。

## 结果类型与错误传播

Swift 5.0 引入了 `Result` 类型，为异步操作和可能失败的计算提供了类型安全的错误处理方式。

### Result 类型基础

```swift
enum NetworkError: Error {
    case badURL
    case noData
    case decodingError
}

func fetchUserData(userID: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
    guard let url = URL(string: "https://api.example.com/users/\(userID)") else {
        completion(.failure(.badURL))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            completion(.success(user))
        } catch {
            completion(.failure(.decodingError))
        }
    }.resume()
}

// 使用
fetchUserData(userID: "123") { result in
    switch result {
    case .success(let user):
        print("获取用户成功: \(user.name)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

### Result 的链式操作

```swift
// map：转换成功值
let result: Result<Int, NetworkError> = .success(10)
let doubled = result.map { $0 * 2 } // .success(20)

// flatMap：链式可能失败的操作
let stringResult = doubled.flatMap { value -> Result<String, NetworkError> in
    if value > 0 {
        return .success(String(value))
    }
    return .failure(.noData)
}

// 获取值或默认值
let value = result.mapError { _ in NetworkError.noData }.getOrElse(0)
```

| Result 方法 | 作用 | 返回值 |
|------------|------|--------|
| `map` | 转换成功值 | `Result<U, E>` |
| `mapError` | 转换错误 | `Result<T, F>` |
| `flatMap` | 链式操作 | `Result<U, E>` |
| `get` | 获取成功值（可能抛出） | `T` |
| `getOrElse` | 获取值或默认值 | `T` |

## 异步/等待（Async/Await）

Swift 5.5 引入了 async/await 语法，彻底改变了 Swift 的并发编程方式。

### 基本用法

```swift
// 定义异步函数
func fetchUser async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: userURL)
    let user = try JSONDecoder().decode(User.self, from: data)
    return user
}

// 调用异步函数
func updateUI() async {
    do {
        let user = try await fetchUser()
        print("欢迎, \(user.name)!")
    } catch {
        print("获取用户失败: \(error)")
    }
}

// 在 Task 中执行
Task {
    await updateUI()
}
```

### 并发执行多个任务

```swift
// 顺序执行（较慢）
func fetchSequential() async throws -> (User, Order) {
    let user = try await fetchUser()
    let order = try await fetchOrder()
    return (user, order)
}

// 并发执行（更快）
func fetchConcurrent() async throws -> (User, Order) {
    async let userTask = fetchUser()
    async let orderTask = fetchOrder()
    
    let user = try await userTask
    let order = try await orderTask
    return (user, order)
}

// 使用 TaskGroup 处理动态数量的任务
func fetchAllUsers(userIDs: [String]) async -> [User] {
    await withTaskGroup(of: User.self) { group in
        for id in userIDs {
            group.addTask {
                await fetchUser(id: id)
            }
        }
        
        var users: [User] = []
        for await user in group {
            users.append(user)
        }
        return users
    }
}
```

### MainActor 与 UI 更新

```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    
    func loadUser(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            user = try await fetchUser(id: id)
        } catch {
            print("Error: \(error)")
        }
    }
}

// 在视图中使用
struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        VStack {
            if let user = viewModel.user {
                Text(user.name)
            }
        }
        .task {
            await viewModel.loadUser(id: "123")
        }
    }
}
```

| 并发特性 | 用途 | 引入版本 |
|---------|------|---------|
| `async/await` | 异步编程 | Swift 5.5 |
| `Task` | 创建异步任务 | Swift 5.5 |
| `async let` | 并发绑定 | Swift 5.5 |
| `TaskGroup` | 动态任务组 | Swift 5.5 |
| `@MainActor` | 主线程安全 | Swift 5.5 |
| `Continuation` | 桥接回调式 API | Swift 5.5 |

## SwiftUI 与属性包装器实战

SwiftUI 大量使用了属性包装器来管理状态和数据流。

### 核心属性包装器

```swift
import SwiftUI

struct ContentView: View {
    // @State：视图内部的可变状态
    @State private var count = 0
    
    // @Binding：父子视图间的双向绑定
    @Binding var isPresented: Bool
    
    // @ObservedObject：引用外部可观察对象
    @ObservedObject var viewModel: UserViewModel
    
    // @StateObject：视图拥有的可观察对象（生命周期绑定）
    @StateObject private var settings = Settings()
    
    // @Environment：读取环境值
    @Environment(\.colorScheme) var colorScheme
    
    // @AppStorage：自动同步 UserDefaults
    @AppStorage("username") var username = ""
    
    // @SceneStorage：状态恢复
    @SceneStorage("selectedTab") var selectedTab = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            
            Button("Increment") {
                count += 1
            }
            
            Toggle("Presented", isOn: $isPresented)
        }
    }
}
```

### 自定义属性包装器

```swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// 使用
struct Settings {
    @UserDefault(key: "isDarkMode", defaultValue: false)
    var isDarkMode: Bool
    
    @UserDefault(key: "fontSize", defaultValue: 16)
    var fontSize: Int
}

var settings = Settings()
settings.isDarkMode = true // 自动保存到 UserDefaults
print(settings.isDarkMode) // 从 UserDefaults 读取
```

### 状态管理架构对比

| 方案 | 适用场景 | 复杂度 | 数据流 |
|------|---------|--------|--------|
| `@State` | 简单视图状态 | 低 | 单向 |
| `@StateObject` | 视图拥有对象 | 低 | 单向 |
| `MVVM` | 中等复杂度应用 | 中 | 双向绑定 |
| `Redux/Observable` | 复杂全局状态 | 高 | 单向数据流 |
| `@EnvironmentObject` | 跨视图共享状态 | 中 | 依赖注入 |

```swift
// MVVM 示例
class TodoViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var filter: Filter = .all
    
    var filteredTodos: [Todo] {
        switch filter {
        case .all: return todos
        case .active: return todos.filter { !$0.isCompleted }
        case .completed: return todos.filter { \$0.isCompleted }
        }
    }
    
    func addTodo(title: String) {
        todos.append(Todo(id: UUID(), title: title))
    }
    
    func toggleTodo(id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
        }
    }
}

struct TodoListView: View {
    @StateObject private var viewModel = TodoViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.filteredTodos) { todo in
                TodoRow(todo: todo) {
                    viewModel.toggleTodo(id: todo.id)
                }
            }
        }
    }
}
```

> **SwiftUI 最佳实践**：优先使用值类型（`struct`）和 `@State`，只有在需要共享状态或处理复杂逻辑时才使用 `ObservableObject` 和 `@StateObject`。

通过本文的学习，你应该已经掌握了 Swift 的核心语法特性，可以开始构建 iOS、macOS 或其他平台的应用程序了。
$doc$,
    NULL,
    'published',
    NOW(),
    NOW(),
    NOW()
),
(
    1,
    'PHP 8+ 现代特性完全指南',
    'php-modern-features',
    'PHP 8 带来了一系列革命性的改进。从联合类型、枚举到 Fiber 协程和 JIT 编译器，PHP 终于甩掉了"玩具语言"的帽子。本文系统梳理 PHP 8+ 的核心新特性，帮你写出更现代、更可靠的 PHP 代码。',
    $doc$
# PHP 8+ 现代特性完全指南

我从 2006 年开始写 PHP，那时候还是 PHP 4 的时代。没有命名空间，没有闭包，数组函数 return 的还都是新数组。十几年下来，PHP 被人诟病最多的不是语法丑，而是类型系统太弱、API 设计混乱、项目容易变成意大利面条。

PHP 8 的发布改变了很多东西。联合类型、命名参数、match 表达式、枚举、Fiber、JIT——这些特性让 PHP 终于有了一门现代编程语言该有的样子。当然，PHP 的数组设计确实有点混乱，但用了十几年也习惯了。

本文不是入门教程。假设你已经会写 PHP，我们直接深入 PHP 8.0 到 8.3 带来的核心变化，看看这些特性怎么用、什么时候用、以及有哪些坑。

## 类型系统的进化：从弱类型到强表达

PHP 的类型系统经历过漫长的进化。PHP 5 引入了类型提示，PHP 7 加了标量类型声明和返回类型，PHP 8 则把类型系统推到了一个新高度。

### 联合类型（Union Types）

PHP 8.0 引入了联合类型，允许一个参数或返回值接受多种类型：

```php
function parseValue(string $input): int|float|null
{
    if (is_numeric($input)) {
        return strpos($input, '.') !== false
            ? (float) $input
            : (int) $input;
    }
    return null;
}

// 使用
$result = parseValue("42");     // int(42)
$result = parseValue("3.14");   // float(3.14)
$result = parseValue("abc");    // null
```

在 PHP 8 之前，这种场景通常只能写 `/** @return int|float|null */` 然后让 IDE 和静态分析工具去猜。联合类型把这种约定变成了编译器级别的约束。

联合类型不能包含 `void`，因为 `void` 表示"不返回值"，跟其他类型不兼容。也不能把 `null` 单独用，必须配合其他类型写成 `?string` 或 `string|null`。

### 交集类型（Intersection Types）

PHP 8.1 引入了交集类型，表示一个值必须同时实现多个接口：

```php
interface Logger {
    public function log(string $message): void;
}

interface Cacheable {
    public function cacheKey(): string;
}

// 参数必须同时实现 Logger 和 Cacheable
function process(Logger&Cacheable $service): void
{
    $service->log("Processing: " . $service->cacheKey());
}
```

我在一个项目里用交集类型来约束"必须是 Repository 且必须是 Cacheable"的场景。以前只能写成接口继承，但那样会引入不必要的接口层次。交集类型让约束更灵活。

联合类型和交集类型的对比：

| 类型 | 语法 | 含义 | 引入版本 |
|------|------|------|---------|
| 联合类型 | `A\|B` | A 或 B | PHP 8.0 |
| 交集类型 | `A&B` | A 且 B | PHP 8.1 |
| 可空类型 | `?A` | A 或 null | PHP 7.1 |
| 混合类型 | `mixed` | 任意类型 | PHP 8.0 |

### 枚举（Enum）

PHP 8.1 的枚举是我最喜欢的特性之一。终于不用再写一堆类常量来模拟枚举了。

```php
enum Status: string
{
    case Draft = 'draft';
    case Published = 'published';
    case Archived = 'archived';

    public function label(): string
    {
        return match($this) {
            self::Draft => '草稿',
            self::Published => '已发布',
            self::Archived => '已归档',
        };
    }

    public function canEdit(): bool
    {
        return $this !== self::Archived;
    }
}

// 使用
$status = Status::Published;
echo $status->value;        // "published"
echo $status->label();      // "已发布"
echo $status->canEdit();    // true
```

枚举可以带方法、可以实现接口、可以有静态方法。但枚举不能继承其他类（因为底层继承自 Enum），也不能被实例化（除了内部机制）。

纯枚举（不关联标量值）和 Backed Enum（关联 int/string）的区别：

```php
// 纯枚举——没有底层值
enum Direction
{
    case North;
    case South;
    case East;
    case West;
}

// Backed Enum——可以序列化为数据库
enum Priority: int
{
    case Low = 1;
    case Medium = 2;
    case High = 3;
}
```

数据库里存枚举的时候，用 Backed Enum 的 `value` 属性。读取时直接用 `Status::from($dbValue)` 转换，如果值不存在会抛出 `ValueError`。

## 属性（Attributes）：原生的注解系统

PHP 8.0 引入了属性（Attributes），终于有了原生的注解机制。不再需要依赖 DocBlock 注释和反射解析。

```php
use Attribute;

#[Attribute(Attribute::TARGET_METHOD | Attribute::TARGET_FUNCTION)]
class Route
{
    public function __construct(
        public string $path,
        public string $method = 'GET',
        public array $middleware = []
    ) {}
}

class UserController
{
    #[Route('/users', method: 'GET')]
    public function index(): array
    {
        return User::all()->toArray();
    }

    #[Route('/users', method: 'POST', middleware: [AuthMiddleware::class])]
    public function store(Request $request): User
    {
        return User::create($request->validated());
    }
}
```

属性的读取通过反射完成：

```php
$reflector = new ReflectionClass(UserController::class);

foreach ($reflector->getMethods() as $method) {
    $attributes = $method->getAttributes(Route::class);
    foreach ($attributes as $attribute) {
        $route = $attribute->newInstance();
        echo "{$route->method} {$route->path}\n";
    }
}
```

我迁移过一个项目，从 Doctrine Annotations 切到 PHP 8 原生属性。代码量减少了 30%，反射解析速度也快了不少。原生属性是在编译期解析的，比运行时正则解析 DocBlock 可靠得多。

属性常见用途：

| 场景 | 属性示例 | 说明 |
|------|---------|------|
| 路由定义 | `#[Route('/api/users')]` | 替代路由配置文件 |
| ORM 映射 | `#[Column(type: 'string')]` | 替代注解 |
| 验证规则 | `#[Assert\Email]` | Symfony Validator |
| 依赖注入 | `#[Inject]` | 标记自动注入 |
| 序列化控制 | `#[JsonIgnore]` | 控制 JSON 序列化 |
| 测试标记 | `#[Test]` | PHPUnit 10+ |

## 构造函数提升：告别样板代码

PHP 8.0 的构造函数参数提升（Constructor Property Promotion）是我每天都在用的特性。它把属性声明和构造函数赋值合二为一。

```php
// PHP 7 的写法——8 行代码
class User
{
    private string $name;
    private int $age;
    private ?string $email;

    public function __construct(string $name, int $age, ?string $email = null)
    {
        $this->name = $name;
        $this->age = $age;
        $this->email = $email;
    }
}

// PHP 8 的写法——3 行代码
class User
{
    public function __construct(
        private string $name,
        private int $age,
        private ?string $email = null,
    ) {}
}
```

构造函数提升支持可见性修饰符（public/private/protected）、只读属性（PHP 8.1）、属性（Attribute），甚至默认值。

结合只读属性（readonly），可以写出不可变的 DTO：

```php
readonly class CreateUserDto
{
    public function __construct(
        public string $name,
        public int $age,
        public ?string $email = null,
    ) {}
}

// 所有属性只读，类实例化后不能修改
$dto = new CreateUserDto('Alice', 30);
// $dto->name = 'Bob'; // Error: Cannot modify readonly property
```

PHP 8.2 引入了只读类（readonly class），整个类的所有属性自动只读。这对 DTO、Value Object 简直是量身定做的。

## Match 表达式：Switch 的现代替代

PHP 8.0 的 `match` 表达式是 `switch` 的现代化替代品。它是表达式（返回值），不是语句，且默认严格比较。

```php
// 老式的 switch
function getStatusLabel($status): string
{
    switch ($status) {
        case 'active':
            return '激活';
        case 'inactive':
            return '未激活';
        default:
            return '未知';
    }
}

// match 表达式
function getStatusLabel(string $status): string
{
    return match ($status) {
        'active' => '激活',
        'inactive' => '未激活',
        default => '未知',
    };
}
```

`match` 的几个关键区别：

1. **严格比较**：`match` 用 `===`，`switch` 用 `==`。`match (1) { '1' => ... }` 不会匹配。
2. **单分支匹配**：`match` 只匹配一个分支，不会 fallthrough。不需要 `break`。
3. **必须是表达式**：每个分支都必须返回一个值。
4. **可以匹配多个条件**：

```php
$result = match ($status) {
    'draft', 'pending' => '未发布',
    'published', 'live' => '已发布',
    'archived', 'deleted' => '已归档',
    default => throw new \InvalidArgumentException("未知状态: $status"),
};
```

我特别喜欢在枚举里配合 `match` 使用，处理状态转换逻辑非常清晰。

## Fiber 协程：轻量级并发

PHP 8.1 引入了 Fiber，这是 PHP 并发模型的重大突破。Fiber 是一种协作式多任务机制，可以在单个线程内实现"伪并行"。

```php
$fiber = new Fiber(function (): void {
    echo "Fiber 开始\n";

    // 挂起 Fiber，把值传回调用者
    $value = Fiber::suspend('第一个值');
    echo "Fiber 恢复，收到: $value\n";

    $value = Fiber::suspend('第二个值');
    echo "Fiber 再次恢复，收到: $value\n";

    echo "Fiber 结束\n";
});

// 启动 Fiber
$result = $fiber->start();
echo "主线程收到: $result\n";

// 恢复 Fiber，传入新值
$result = $fiber->resume('Hello');
echo "主线程收到: $result\n";

$result = $fiber->resume('World');
echo "主线程收到: $result\n";
```

输出：
```
Fiber 开始
主线程收到: 第一个值
Fiber 恢复，收到: Hello
主线程收到: 第二个值
Fiber 再次恢复，收到: World
Fiber 结束
```

Fiber 本身不是异步 I/O。它只是提供了用户态的上下文切换能力。真正的威力在于配合事件循环实现异步编程：

```php
use React\Promise\Promise;

function asyncFetch(string $url): Fiber
{
    return new Fiber(function () use ($url): string {
        // 发起异步 HTTP 请求，立即挂起
        $response = Fiber::suspend($url);
        return $response;
    });
}

// 简化的调度器
$fiber = asyncFetch('https://api.example.com/data');
$url = $fiber->start();

// 异步获取数据，完成后恢复 Fiber
fetchAsync($url, function ($response) use ($fiber) {
    $fiber->resume($response);
});
```

Fiber 对比其他并发方案：

| 方案 | 开销 | 适用场景 | PHP 支持 |
|------|------|---------|---------|
| 进程（pcntl） | 高 | 独立任务、隔离性要求高 | 内置 |
| 线程（pthreads/parallel） | 中 | 共享内存并行 | 扩展 |
| Fiber | 极低 | 协程、异步 I/O | PHP 8.1+ |
| Swoole/FrankenPHP | 低 | 高性能服务器 | 扩展 |

Fiber 让 PHP 的异步编程变得更优雅。ReactPHP、Amphp 这些库已经在深度集成 Fiber。

## JIT 编译器：性能的最后一块拼图

PHP 8.0 引入了 JIT（Just-In-Time）编译器，把热点字节码编译成原生机器码执行。

启用 JIT 很简单，在 php.ini 里加几行：

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=100M
opcache.jit=tracing
```

JIT 有两种模式：

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| `tracing` | 追踪热点代码路径，编译整段 trace | 一般推荐 |
| `function` | 逐个函数编译 | 内存受限环境 |

JIT 对不同类型的代码效果差异很大：

```php
// 这种纯计算密集型代码，JIT 提升巨大（5-20 倍）
function fibonacci(int $n): int
{
    return $n < 2 ? $n : fibonacci($n - 1) + fibonacci($n - 2);
}

// 这种 I/O 密集型代码，JIT 几乎没帮助
function fetchUsers(): array
{
    $pdo = new PDO('mysql:host=localhost;dbname=test', 'user', 'pass');
    $stmt = $pdo->query('SELECT * FROM users');
    return $stmt->fetchAll();
}
```

我在一个图像处理服务里测试过 JIT。大量的像素运算循环，开启 JIT 后整体吞吐量提升了 3 倍。但在一个典型的 REST API 项目里，提升不到 5%——因为时间主要花在数据库查询和序列化上。

JIT 的坑也不少：
- 启动时有一定预热时间
- 内存占用增加（需要为 JIT 代码分配 buffer）
- 调试变困难（JIT 代码的堆栈跟踪跟普通代码不同）
- 某些扩展跟 JIT 不兼容

## 命名参数：可读性的提升

PHP 8.0 支持命名参数，调用函数时可以按参数名传值，不用记参数顺序。

```php
// 以前：必须按顺序传，中间不想传的还要写 null
htmlspecialchars($string, ENT_QUOTES, 'UTF-8', false);

// 现在：按名字传，顺序无所谓
htmlspecialchars($string, double_encode: false);

// 结合构造函数提升，实例化更清晰
$user = new User(
    name: 'Alice',
    age: 30,
    email: 'alice@example.com',
);
```

命名参数对参数多的函数特别友好。我在重构一个 legacy 项目时，把一堆 `createOrder($customerId, null, null, null, 'urgent')` 改成了 `createOrder(customerId: $customerId, priority: 'urgent')`，代码可读性提升了一个档次。

注意：命名参数在继承方法时必须匹配父类的方法签名参数名。改了参数名会破坏兼容性。

## Nullsafe 运算符：告别嵌套判断

PHP 8.0 的 `?->` 运算符让链式调用中的 null 检查变得优雅：

```php
// PHP 7：层层嵌套的判断
$country = null;
if ($user !== null) {
    $profile = $user->getProfile();
    if ($profile !== null) {
        $address = $profile->getAddress();
        if ($address !== null) {
            $country = $address->getCountry();
        }
    }
}

// PHP 8：一行搞定
$country = $user?->getProfile()?->getAddress()?->getCountry();
```

`?->` 的语义是：如果左侧为 null，整个表达式返回 null，不再继续调用。否则正常调用右侧方法。

nullsafe 运算符也可以用于属性访问：

```php
$city = $user?->profile?->address?->city;
```

但不能用于赋值左侧：`$user?->profile = new Profile()` 是语法错误。nullsafe 是只读的。

## 其他值得关注的特性

### 命名参数与构造函数提升的组合

```php
class Point
{
    public function __construct(
        public float $x = 0.0,
        public float $y = 0.0,
    ) {}
}

// 只传 y，x 用默认值
$point = new Point(y: 10.0);
```

### 字符串包含函数（PHP 8.0）

```php
// 更直观的字符串检查
str_contains($haystack, $needle);   // 替代 strpos !== false
str_starts_with($haystack, $needle); // 替代 substr ===
str_ends_with($haystack, $needle);   // 替代 substr ===
```

### 混合类型（mixed）

```php
// 显式声明接受任意类型
function dumpValue(mixed $value): void
{
    var_dump($value);
}
```

### 静态返回类型（static）

```php
class Base
{
    public static function create(): static
    {
        return new static();
    }
}

class Derived extends Base {}

$instance = Derived::create(); // 类型是 Derived，不是 Base
```

### 新的类常量可见性（PHP 7.1+，但 PHP 8 普及）

```php
class Config
{
    public const VERSION = '1.0';
    protected const INTERNAL_KEY = 'secret';
    private const CACHE_TTL = 3600;
}
```

### 可丢弃的参数（PHP 8.0）

```php
// 故意不用的参数，用 $ 前缀避免 IDE 警告
[$x, $, $z] = [1, 2, 3];
```

### throw 表达式（PHP 8.0）

```php
// throw 现在是一个表达式，可以用在三元运算符里
$value = $input ?? throw new InvalidArgumentException('Input required');

// 箭头函数里也能用
$callback = fn($x) => $x > 0 ? $x : throw new RangeException('Must be positive');
```

## PHP 8 性能实测数据

说这么多特性，不如看实际数据。我在一个电商项目上做过 PHP 7.4 到 8.2 的升级测试。

测试环境：AWS c5.xlarge（4 vCPU, 8GB RAM），PHP-FPM + Nginx + PostgreSQL。

| 指标 | PHP 7.4 | PHP 8.0 | PHP 8.1 | PHP 8.2 | 提升 |
|------|---------|---------|---------|---------|------|
| 首页响应时间 | 45ms | 38ms | 36ms | 35ms | -22% |
| 订单列表（复杂 Join） | 120ms | 105ms | 102ms | 98ms | -18% |
| 并发请求（RPS） | 850 | 1100 | 1150 | 1180 | +39% |
| 内存占用（峰值） | 512MB | 480MB | 465MB | 458MB | -11% |
| 启动时间 | 2.1s | 1.8s | 1.7s | 1.6s | -24% |

这些数据是在关闭 JIT 的情况下测的。开启 JIT 后，计算密集型的接口（比如报表生成、数据导出）还能再快 20-50%。

opcode 缓存方面，PHP 8 的 opcache 也有改进。新增 `opcache.jit` 配置，以及更好的预加载（preload）支持：

```php
// preload.php —— 在 php.ini 的 opcache.preload 中指定
require_once '/var/www/vendor/autoload.php';

// 预加载常用类
opcache_compile_file('/var/www/src/Models/User.php');
opcache_compile_file('/var/www/src/Services/OrderService.php');
```

预加载在 PHP-FPM 启动时就把指定文件编译并缓存到共享内存里。所有 worker 进程共享这些缓存，避免了重复编译的开销。

## 命名空间与自动加载的现代实践

Composer 的 PSR-4 自动加载已经是 PHP 项目的标配。PHP 8 配合现代 IDE，类型系统和自动加载可以做得很好：

```php
// composer.json
{
    "autoload": {
        "psr-4": {
            "App\\\\": "src/"
        }
    }
}

// src/Controllers/UserController.php
namespace App\Controllers;

use App\Services\UserService;
use App\DTOs\CreateUserDto;

readonly class UserController
{
    public function __construct(
        private UserService $userService
    ) {}

    public function store(CreateUserDto $dto): UserResource
    {
        $user = $this->userService->create($dto);
        return new UserResource($user);
    }
}
```

`readonly class` 是 PHP 8.2 的新特性。整个类的所有属性都是只读的，实例化后不能修改。这非常适合 DTO、Value Object、Resource 类。

## 错误处理：从异常到类型

PHP 8 统一了很多内部函数的错误行为。以前返回 `false` 的函数，现在抛出异常。

```php
// PHP 7: 返回 false，需要手动检查
$file = fopen('nonexistent.txt', 'r');
if ($file === false) {
    // 处理错误
}

// PHP 8: 直接抛异常
$file = fopen('nonexistent.txt', 'r');  // ValueError
```

`str_contains`、`str_starts_with`、`str_ends_with` 这些新函数也解决了老 API 不一致的问题。以前要判断字符串包含，得用 `strpos($haystack, $needle) !== false`，既难读又容易写错成 `> 0`（漏掉在开头的情况）。

自定义异常层次：

```php
namespace App\Exceptions;

abstract class DomainException extends \Exception {}

class UserNotFoundException extends DomainException {
    public function __construct(int $userId) {
        parent::__construct("User not found: {$userId}");
    }
}

class InsufficientBalanceException extends DomainException {
    public function __construct(
        public readonly float $current,
        public readonly float $required
    ) {
        parent::__construct(
            "Insufficient balance: required {$required}, current {$current}"
        );
    }
}
```

异常属性用 `readonly`，异常抛出后属性不可修改，保证异常信息的完整性。

## 升级建议

如果你还在用 PHP 7.4 或更早版本，升级到 PHP 8 的收益是巨大的。以下是我的升级经验：

| 版本 | 关键特性 | 升级难度 |
|------|---------|---------|
| 7.4 -> 8.0 | JIT、命名参数、match、联合类型、nullsafe | 低（主要是废弃警告） |
| 8.0 -> 8.1 | 枚举、Fiber、交集类型、readonly | 中（枚举重构工作量大） |
| 8.1 -> 8.2 | 只读类、敏感参数、null/false/true 独立类型 | 低 |
| 8.2 -> 8.3 | 类型化类常量、json_validate、随机数扩展 | 低 |

升级前先用 PHPCompatibility 做静态扫描，把废弃特性清理掉。然后逐步开启严格类型，利用新类型系统加固代码。

PHP 8 确实让这门语言焕然一新。类型系统、枚举、Fiber、JIT——这些不是语法糖，是编程范式的升级。如果你因为 PHP 5/7 的印象而排斥 PHP，现在是时候重新看看它了。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '16 days',
    NOW() - INTERVAL '16 days',
    NOW() - INTERVAL '16 days'
),
(
    1,
    'C# 与 .NET 生态系统深度解析',
    'csharp-dotnet-ecosystem',
    'C# 和 .NET 是微软最成功的产品之一。从 LINQ 到 async/await，从 Span<T> 到记录类型，.NET 平台的现代化程度远超很多人想象。本文深入解析 .NET 生态的核心技术。',
    $doc$
# C# 与 .NET 生态系统深度解析

我最早接触 C# 是在 2008 年，Visual Studio 2008 + .NET 3.5 的年代。那时候 LINQ 刚出来，lambda 表达式还是个新鲜玩意儿。十几年过去了，C# 从一门"Windows 专属语言"变成了跨平台的全栈语言，.NET 也从 Framework 演变成了统一的 .NET 8+。

很多人对 C# 的印象还停留在 ASP.NET Web Forms 和 Windows Forms 时代。那个拖控件写代码的年代确实给很多人留下了心理阴影。但现代 C# 是一门设计精良、性能优秀、生态丰富的语言。LINQ、async/await、Span<T>、记录类型、模式匹配——这些特性放在任何语言里都是一流的设计。

## LINQ：革命性的数据查询

LINQ（Language Integrated Query）是 C# 3.0 引入的，至今仍是 C# 最具标志性的特性。它把查询能力直接集成到语言中，统一了对象、数据库、XML 的查询语法。

```csharp
// 方法语法
var adults = people
    .Where(p => p.Age >= 18)
    .OrderBy(p => p.LastName)
    .ThenBy(p => p.FirstName)
    .Select(p => new { p.FirstName, p.LastName, p.Age })
    .ToList();

// 查询语法
var adults = from p in people
             where p.Age >= 18
             orderby p.LastName, p.FirstName
             select new { p.FirstName, p.LastName, p.Age };
```

两种语法等价，编译器会把查询语法翻译成方法调用。我通常用方法语法写简单查询，查询语法写复杂的多表 join。

LINQ 的高级操作：

```csharp
// Group By
var peopleByCity = people
    .GroupBy(p => p.City)
    .Select(g => new {
        City = g.Key,
        Count = g.Count(),
        AverageAge = g.Average(p => p.Age)
    });

// Join
var userOrders = from u in users
                 join o in orders on u.Id equals o.UserId
                 select new { u.Name, o.OrderDate, o.Total };

// 聚合
var stats = orders
    .GroupBy(o => o.Status)
    .ToDictionary(
        g => g.Key,
        g => new {
            Count = g.Count(),
            Total = g.Sum(o => o.Total),
            Average = g.Average(o => o.Total)
        }
    );
```

LINQ to Objects 在内存中操作集合，LINQ to Entities（Entity Framework）则把同样的查询翻译成 SQL：

```csharp
// 这行代码会被 EF Core 翻译成高效的 SQL
var recentOrders = await context.Orders
    .Where(o => o.OrderDate > DateTime.Now.AddDays(-30))
    .Include(o => o.Customer)
    .OrderByDescending(o => o.Total)
    .Take(10)
    .ToListAsync();
```

LINQ 的延迟执行是个容易踩的坑。`Where`、`Select` 返回的是 `IEnumerable<T>`，实际查询直到调用 `ToList()`、`ToArray()` 或开始遍历时才执行。

## Async/Await：异步编程的黄金标准

C# 5.0 引入的 async/await 可能是编程语言史上最成功的异步模型之一。它让异步代码写起来像同步代码一样直观。

```csharp
public async Task<User> GetUserAsync(int id)
{
    // 等待但不阻塞线程
    var response = await httpClient.GetAsync($"/api/users/{id}");
    response.EnsureSuccessStatusCode();

    var json = await response.Content.ReadAsStringAsync();
    return JsonSerializer.Deserialize<User>(json);
}

// 调用
var user = await GetUserAsync(123);
```

`await` 的关键在于它不阻塞线程。当遇到 I/O 操作时，线程被释放回线程池去处理其他请求，I/O 完成后再继续执行。这在高并发场景下至关重要——一个线程可以服务成百上千个并发请求。

并行执行多个异步操作：

```csharp
public async Task<DashboardData> LoadDashboardAsync()
{
    // 三个任务同时启动
    var userTask = GetUserAsync(currentUserId);
    var ordersTask = GetRecentOrdersAsync();
    var notificationsTask = GetNotificationsAsync();

    // 等待全部完成
    await Task.WhenAll(userTask, ordersTask, notificationsTask);

    return new DashboardData
    {
        User = await userTask,
        Orders = await ordersTask,
        Notifications = await notificationsTask
    };
}
```

async/await 的常见陷阱：

| 问题 | 错误代码 | 正确做法 |
|------|---------|---------|
| 死锁 | `task.Result` 在 UI 线程 | 全程用 `await` |
| 未等待任务 | `DoWorkAsync()` 没 await | `await DoWorkAsync()` |
| 异常丢失 | `async void` 方法抛异常 | 用 `async Task` |
| 并行循环 | `foreach + await` | `Task.WhenAll` |

```csharp
// 错误：顺序执行，慢
foreach (var url in urls)
{
    await DownloadAsync(url);  // 一个一个下载
}

// 正确：并行执行
var tasks = urls.Select(url => DownloadAsync(url));
var results = await Task.WhenAll(tasks);
```

## Span<T>：零拷贝内存操作

`Span<T>` 是 .NET Core 2.1 引入的，它代表一段连续的内存，可以是数组、栈内存、或者非托管内存。

```csharp
// 从数组创建 Span
int[] array = { 1, 2, 3, 4, 5 };
Span<int> span = array;

// 切片——零拷贝
Span<int> slice = span.Slice(1, 3);  // [2, 3, 4]
slice[0] = 99;  // 修改会反映到原数组

// 栈上分配 Span（无堆分配）
Span<byte> stackSpan = stackalloc byte[256];
```

`Span<T>` 的核心价值是避免不必要的内存分配和拷贝：

```csharp
// 以前：substr 会创建新字符串
string ProcessHeader(string header)
{
    var parts = header.Split(':');  // 分配新数组和新字符串
    return parts[0].Trim();
}

// 现在：Span 零拷贝解析
ReadOnlySpan<char> ProcessHeader(ReadOnlySpan<char> header)
{
    var colonIndex = header.IndexOf(':');
    return colonIndex >= 0
        ? header.Slice(0, colonIndex).Trim()
        : header;
}
```

我在一个日志解析服务里用 `Span<byte>` 替代了字符串操作，GC 压力减少了 70%，吞吐量提升了 4 倍。对于高频、小对象分配的场景，`Span<T>` 是神器。

`Memory<T>` 是 `Span<T>` 的堆分配版本，可以存储在字段中（`Span<T>` 只能存在于栈上）：

```csharp
public class BufferManager
{
    private Memory<byte> _buffer;  // 可以存为字段

    public BufferManager(byte[] buffer)
    {
        _buffer = buffer;
    }

    public Span<byte> GetSpan(int start, int length)
    {
        return _buffer.Span.Slice(start, length);
    }
}
```

## 记录类型（Record）：不可变数据的优雅表达

C# 9.0 引入的 record 是一种引用类型，但语义上更偏向值类型——它天生适合表示不可变数据。

```csharp
// 定义一个 record——一行代码
public record Person(string FirstName, string LastName, int Age);

// 实例化
var person = new Person("Alice", "Smith", 30);

// 编译器自动生成的方法
Console.WriteLine(person);  // Person { FirstName = Alice, LastName = Smith, Age = 30 }

// 解构
var (first, last, age) = person;

// "修改"（创建新实例）
var olderPerson = person with { Age = 31 };
```

record 会自动生成 `Equals`、`GetHashCode`、`ToString`、`Deconstruct`，而且相等性比较基于值而非引用：

```csharp
var p1 = new Person("Alice", "Smith", 30);
var p2 = new Person("Alice", "Smith", 30);

Console.WriteLine(p1 == p2);  // True（值相等）
Console.WriteLine(ReferenceEquals(p1, p2));  // False（不同对象）
```

record 适合 DTO、事件、消息等不可变数据场景。对于需要可变状态的业务实体，还是用传统的 class。

record 的继承：

```csharp
public record Employee(string FirstName, string LastName, int Age, string Department)
    : Person(FirstName, LastName, Age);

var emp = new Employee("Bob", "Jones", 25, "Engineering");
var person = emp with { Age = 26 };  // 创建 Person，Department 丢失
```

## 模式匹配：比 switch 强大十倍

C# 7 开始引入模式匹配，后续版本不断增强，现在已经可以处理非常复杂的条件逻辑。

```csharp
// 基本模式匹配
string Describe(object obj) => obj switch
{
    int i when i > 0 => $"正整数: {i}",
    int i when i < 0 => $"负整数: {i}",
    0 => "零",
    string s => $"字符串: {s}",
    null => "空值",
    _ => "其他"
};

// 属性模式
string GetLocation(Person p) => p switch
{
    { City: "Beijing" } => "帝都",
    { City: "Shanghai" } => "魔都",
    { Age: < 18 } => "未成年",
    { Age: >= 60 } => "退休",
    _ => "其他"
};

// 元组模式
string GetQuadrant(Point p) => (p.X, p.Y) switch
{
    (> 0, > 0) => "第一象限",
    (< 0, > 0) => "第二象限",
    (< 0, < 0) => "第三象限",
    (> 0, < 0) => "第四象限",
    (0, _) => "Y轴上",
    (_, 0) => "X轴上",
    _ => "原点"
};
```

模式匹配在 C# 8+ 的 switch 表达式里特别强大，支持列表模式（C# 11）：

```csharp
int[] numbers = { 1, 2, 3 };

string result = numbers switch
{
    [] => "空数组",
    [1] => "只有一个元素 1",
    [1, 2, 3] => "正好 [1,2,3]",
    [1, .., 5] => "以1开头，以5结尾",
    [_, _, _] => "三个元素的数组",
    _ => "其他"
};
```

## 依赖注入：.NET 的核心设计模式

.NET Core 内置了强大的依赖注入容器，这已经成为 .NET 开发的标准实践。

```csharp
// 服务接口
public interface IEmailService
{
    Task SendAsync(string to, string subject, string body);
}

// 实现
public class SmtpEmailService : IEmailService
{
    private readonly ILogger<SmtpEmailService> _logger;

    // 构造函数注入
    public SmtpEmailService(ILogger<SmtpEmailService> logger)
    {
        _logger = logger;
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        _logger.LogInformation("Sending email to {To}", to);
        // ... SMTP 逻辑
    }
}

// 注册服务
builder.Services.AddSingleton<IEmailService, SmtpEmailService>();

// 使用
public class OrderController : ControllerBase
{
    private readonly IEmailService _emailService;

    public OrderController(IEmailService emailService)
    {
        _emailService = emailService;
    }
}
```

服务生命周期：

| 生命周期 | 注册方法 | 说明 |
|---------|---------|------|
| 单例 | `AddSingleton` | 整个应用共享一个实例 |
| 作用域 | `AddScoped` | 每个请求一个实例 |
| 瞬态 | `AddTransient` | 每次注入创建新实例 |

生命周期选错是 DI 最常见的 bug。Singleton 里注入 Scoped 服务会导致 Scoped 服务变成事实上的单例。在 ASP.NET Core 里，这种情况会抛出异常。

## ASP.NET Core：现代化的 Web 框架

ASP.NET Core 是 .NET 平台上统一、高性能、跨平台的 Web 框架。

```csharp
var builder = WebApplication.CreateBuilder(args);

// 注册服务
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

// 极简 API（.NET 6+）
app.MapGet("/api/users", async (IUserService userService) =>
{
    return Results.Ok(await userService.GetAllAsync());
});

app.MapGet("/api/users/{id:int}", async (int id, IUserService userService) =>
{
    var user = await userService.GetByIdAsync(id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});

app.MapPost("/api/users", async (CreateUserDto dto, IUserService userService) =>
{
    var user = await userService.CreateAsync(dto);
    return Results.Created($"/api/users/{user.Id}", user);
});

app.Run();
```

.NET 6 引入的 Minimal APIs 让写小型服务变得极其简洁。一个文件、几十行代码就能跑起一个 REST API。当然，大型项目还是推荐用 Controller 模式来组织代码。

中间件管道：

```csharp
app.Use(async (context, next) =>
{
    var stopwatch = Stopwatch.StartNew();
    await next();
    stopwatch.Stop();
    Console.WriteLine($"{context.Request.Method} {context.Request.Path} took {stopwatch.ElapsedMilliseconds}ms");
});

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
```

## Entity Framework Core：现代化的 ORM

EF Core 是 .NET 平台的官方 ORM，经过多年迭代，性能和功能都已经非常成熟。

```csharp
// 实体定义
public class Blog
{
    public int Id { get; set; }
    public string Title { get; set; }
    public string Content { get; set; }
    public DateTime CreatedAt { get; set; }

    // 导航属性
    public List<Post> Posts { get; set; } = new();
}

// DbContext
public class AppDbContext : DbContext
{
    public DbSet<Blog> Blogs { get; set; }
    public DbSet<Post> Posts { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Blog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.HasIndex(e => e.CreatedAt);
        });
    }
}
```

LINQ 查询自动翻译成 SQL：

```csharp
// 这个 LINQ 查询会被翻译成高效的 SQL
var recentBlogs = await context.Blogs
    .Where(b => b.CreatedAt > DateTime.Now.AddMonths(-1))
    .Include(b => b.Posts.Where(p => !p.IsDeleted))
    .OrderByDescending(b => b.CreatedAt)
    .Take(10)
    .AsNoTracking()  // 只读查询，不跟踪变化
    .ToListAsync();
```

EF Core 的性能对比（我自己的测试数据）：

| 操作 | EF Core | Dapper | Raw ADO.NET |
|------|---------|--------|-------------|
| 简单查询 | ~1.2x | 1x | 0.9x |
| 复杂查询 | ~1.5x | 1x | 0.9x |
| 批量插入 | ~3x | 1.5x | 1x |
| 单条查询 | ~1.1x | 1x | 0.95x |

EF Core 在简单查询上的性能差距已经很小了。开发效率的提升通常值得这点性能开销。但批量操作还是建议用原生 SQL 或 Dapper。

## .NET 性能优化技巧

### 对象池

```csharp
// 高频创建的对象用 ArrayPool 复用
var pool = ArrayPool<byte>.Shared;
var buffer = pool.Rent(4096);

try
{
    // 使用 buffer
    await stream.ReadAsync(buffer);
}
finally
{
    pool.Return(buffer);  // 归还到池里
}
```

### ValueTask

```csharp
// 缓存命中的场景，用 ValueTask 避免 Task 分配
public ValueTask<byte[]> GetAsync(string key)
{
    if (_cache.TryGetValue(key, out var value))
    {
        return new ValueTask<byte[]>(value);  // 同步路径，零分配
    }

    return new ValueTask<byte[]>(LoadFromDiskAsync(key));  // 异步路径
}
```

### Source Generators

C# 9 引入的 Source Generators 可以在编译期生成代码，替代运行时反射：

```csharp
// System.Text.Json 的源生成器
[JsonSerializable(typeof(Person))]
[JsonSerializable(typeof(Order))]
internal partial class AppJsonContext : JsonSerializerContext { }

// 使用——编译期生成序列化代码，比反射快得多
var person = JsonSerializer.Deserialize(json, AppJsonContext.Default.Person);
```


## .NET GC 与内存管理

.NET 的垃圾回收器（GC）是分代的（Generational），分三代：0 代、1 代、2 代（LOH 算特殊的一代）。

```csharp
// 查看 GC 信息
Console.WriteLine($"Total memory: {GC.GetTotalMemory(false) / 1024 / 1024} MB");

// 强制回收（一般不要手动调用）
GC.Collect();

// 使用 using 确保资源释放
using var stream = new FileStream("data.txt", FileMode.Open);
using var reader = new StreamReader(stream);
var content = await reader.ReadToEndAsync();
```

GC 模式选择：

| 模式 | 适用场景 | 延迟 | 吞吐量 |
|------|---------|------|--------|
| Workstation | 桌面应用、客户端 | 低 | 中 |
| Server | 服务器应用 | 中 | 高 |
| Background | 默认，后台回收 | 低 | 高 |

Server GC 在多核机器上利用多个线程并行回收，适合 ASP.NET Core 应用。在 .csproj 里配置：

```xml
<PropertyGroup>
  <ServerGarbageCollection>true</ServerGarbageCollection>
</PropertyGroup>
```

## .NET 配置系统

.NET Core 的配置系统非常灵活，支持多种来源：

```csharp
var builder = WebApplication.CreateBuilder(args);

// 优先级从低到高：
// 1. appsettings.json
// 2. appsettings.{Environment}.json
// 3. 环境变量
// 4. 命令行参数

// 强类型配置
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));

// 使用
public class OrderService
{
    private readonly EmailSettings _settings;

    public OrderService(IOptions<EmailSettings> options)
    {
        _settings = options.Value;
    }
}
```

配置绑定到类：

```csharp
public class EmailSettings
{
    public string SmtpServer { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public bool UseSsl { get; set; } = true;
}
```

## AOT 编译：.NET 的未来

.NET 7+ 支持 Native AOT，把 C# 代码编译成原生机器码，不需要 JIT。

```bash
# 发布 AOT 应用
dotnet publish -c Release -r linux-x64 -p:PublishAot=true
```

AOT 的优势：
- 启动速度极快（没有 JIT 预热）
- 内存占用更小
- 可以运行在不允许 JIT 的环境（如某些容器安全策略）

AOT 的限制：
- 不支持动态代码生成（如 Emit、Expression.Compile）
- 反射受限（需要提前 trim 分析）
- 某些序列化库不支持（但 System.Text.Json 的源生成器支持）

```csharp
// AOT 兼容的 JSON 序列化——必须用源生成器
[JsonSerializable(typeof(Person))]
public partial class PersonJsonContext : JsonSerializerContext { }

// 使用
var person = JsonSerializer.Deserialize(json, PersonJsonContext.Default.Person);
```

AOT 特别适合 CLI 工具、微服务、Serverless 函数这些对启动时间敏感的场景。AWS Lambda 的 .NET 托管运行时已经支持 AOT，冷启动时间从几百毫秒降到几十毫秒。

## .NET GC 与内存管理

.NET 的垃圾回收器（GC）是分代的（Generational），分三代：0 代、1 代、2 代（LOH 算特殊的一代）。

```csharp
// 查看 GC 信息
Console.WriteLine($"Total memory: {GC.GetTotalMemory(false) / 1024 / 1024} MB");

// 使用 using 确保资源释放
using var stream = new FileStream("data.txt", FileMode.Open);
using var reader = new StreamReader(stream);
var content = await reader.ReadToEndAsync();
```

GC 模式选择：

| 模式 | 适用场景 | 延迟 | 吞吐量 |
|------|---------|------|--------|
| Workstation | 桌面应用、客户端 | 低 | 中 |
| Server | 服务器应用 | 中 | 高 |
| Background | 默认，后台回收 | 低 | 高 |

Server GC 在多核机器上利用多个线程并行回收，适合 ASP.NET Core 应用。在 .csproj 里配置：

```xml
<PropertyGroup>
  <ServerGarbageCollection>true</ServerGarbageCollection>
</PropertyGroup>
```

## .NET 配置系统

.NET Core 的配置系统非常灵活，支持多种来源：

```csharp
var builder = WebApplication.CreateBuilder(args);

// 优先级从低到高：
// 1. appsettings.json
// 2. appsettings.{Environment}.json
// 3. 环境变量
// 4. 命令行参数

// 强类型配置
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));
```

配置绑定到类：

```csharp
public class EmailSettings
{
    public string SmtpServer { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public bool UseSsl { get; set; } = true;
}
```

## AOT 编译：.NET 的未来

.NET 7+ 支持 Native AOT，把 C# 代码编译成原生机器码，不需要 JIT。

```bash
# 发布 AOT 应用
dotnet publish -c Release -r linux-x64 -p:PublishAot=true
```

AOT 的优势：启动速度极快、内存占用更小、可以运行在不允许 JIT 的环境。限制：不支持动态代码生成、反射受限。

```csharp
// AOT 兼容的 JSON 序列化——必须用源生成器
[JsonSerializable(typeof(Person))]
public partial class PersonJsonContext : JsonSerializerContext { }

// 使用
var person = JsonSerializer.Deserialize(json, PersonJsonContext.Default.Person);
```

AOT 特别适合 CLI 工具、微服务、Serverless 函数这些对启动时间敏感的场景。AWS Lambda 的 .NET 托管运行时已经支持 AOT，冷启动时间从几百毫秒降到几十毫秒。

## 中间件与管道

ASP.NET Core 的请求处理管道由中间件组成：

```csharp
public class RequestTimingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestTimingMiddleware> _logger;

    public RequestTimingMiddleware(RequestDelegate next, ILogger<RequestTimingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var requestPath = context.Request.Path;

        _logger.LogInformation("Request {Method} {Path} started", 
            context.Request.Method, requestPath);

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            var statusCode = context.Response.StatusCode;
            _logger.LogInformation(
                "Request {Method} {Path} completed in {ElapsedMs}ms with status {StatusCode}",
                context.Request.Method, requestPath, stopwatch.ElapsedMilliseconds, statusCode);
        }
    }
}
```

中间件的执行顺序很重要。通常：异常处理 -> HTTPS 重定向 -> 静态文件 -> 路由 -> 认证授权 -> 端点。

## 验证与模型绑定

ASP.NET Core 的数据注解验证：

```csharp
public class CreateOrderRequest
{
    [Required(ErrorMessage = "用户ID是必需的")]
    [Range(1, int.MaxValue, ErrorMessage = "用户ID必须大于0")]
    public int UserId { get; set; }

    [Required]
    [MinLength(1, ErrorMessage = "至少需要一个订单项")]
    public List<OrderItemRequest> Items { get; set; } = new();

    [StringLength(500, ErrorMessage = "备注不能超过500字符")]
    public string? Notes { get; set; }
}
```

FluentValidation 提供了更强大的验证能力，支持复杂规则组合和异步验证。

## gRPC：高性能 RPC

.NET 对 gRPC 有一流的支持，特别适合服务间通信：

```protobuf
syntax = "proto3";

service OrderService {
    rpc CreateOrder (CreateOrderRequest) returns (OrderResponse);
    rpc StreamOrders (StreamOrdersRequest) returns (stream OrderResponse);
}
```

```csharp
// 服务端
public class OrderServiceImpl : OrderService.OrderServiceBase
{
    public override async Task<OrderResponse> CreateOrder(
        CreateOrderRequest request, ServerCallContext context)
    {
        var order = await _orderManager.CreateAsync(request);
        return new OrderResponse { OrderId = order.Id, Status = order.Status };
    }
}
```

gRPC 基于 HTTP/2，支持流式传输、头部压缩、多路复用。在微服务架构中，它比 REST JSON 更高效。

## 总结

.NET 平台在过去十年经历了脱胎换骨的变化。从封闭走向开放，从 Windows 专属走向跨平台，从拖控件走向现代化开发。

| 特性 | 版本 | 适用场景 |
|------|------|---------|
| LINQ | C# 3.0+ | 任何集合/数据查询 |
| async/await | C# 5.0+ | I/O 操作、并发 |
| Span<T> | .NET Core 2.1+ | 高性能内存操作 |
| Record | C# 9.0+ | DTO、不可变数据 |
| 模式匹配 | C# 7.0+ | 复杂条件分支 |
| Minimal API | .NET 6+ | 小型服务、微服务 |
| Source Generators | C# 9.0+ | 编译期代码生成 |

如果你上次写 C# 还是 .NET Framework 4.x 的时代，现在绝对值得重新看看。Visual Studio 2022 的体验、.NET 8 的性能、C# 12 的语法——这套组合拳的竞争力，比你想象的要强。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '17 days',
    NOW() - INTERVAL '17 days',
    NOW() - INTERVAL '17 days'
),
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
    'published',
    NOW() - INTERVAL '18 days',
    NOW() - INTERVAL '18 days',
    NOW() - INTERVAL '18 days'
),
(
    1,
    'SQL 高级查询与性能优化',
    'sql-advanced-optimization',
    '慢查询是后端性能的头号杀手。本文从执行计划分析入手，深入讲解索引策略、窗口函数、CTE 递归查询、查询重写技巧和事务锁机制，帮你建立系统化的 SQL 优化方法论。',
    $doc$
# SQL 高级查询与性能优化

我面试后端工程师的时候，通常会问一个 SQL 优化的问题。有一半的候选人会开始背诵"加索引"三个字，但继续追问"什么场景下索引会失效""覆盖索引是什么""什么时候不该加索引"，能回答上来的不到三分之一。

SQL 优化不是调几个参数、加几个索引那么简单。它需要对数据库引擎如何执行查询有深入理解，需要从数据分布、查询模式、业务场景多个维度去分析。我见过太多因为盲目加索引导致写入性能暴跌的案例，也见过因为查询写法问题导致索引完全没被使用的悲剧。

本文以 PostgreSQL 为主要参考（大部分概念也适用于 MySQL），覆盖执行计划分析、索引策略、窗口函数、CTE、查询重写和事务锁机制。

## 执行计划分析：优化的起点

优化 SQL 的第一步是看执行计划。PostgreSQL 用 `EXPLAIN`（或 `EXPLAIN ANALYZE`）展示查询的执行过程。

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT u.username, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.username
HAVING COUNT(o.id) > 5
ORDER BY order_count DESC
LIMIT 10;
```

执行计划的关键节点类型：

| 节点类型 | 说明 | 开销 |
|---------|------|------|
| Seq Scan | 顺序扫描整张表 | 高（大表） |
| Index Scan | 索引扫描 + 回表 | 中 |
| Index Only Scan | 覆盖索引扫描 | 低 |
| Bitmap Heap Scan | 位图扫描 | 中 |
| Nested Loop | 嵌套循环 Join | 小数据集 |
| Hash Join | 哈希 Join | 大数据集 |
| Merge Join | 排序合并 Join | 已排序数据 |
| Sort | 排序操作 | 高（内存/磁盘） |
| Aggregate | 聚合操作 | 视数据量 |

看到一个查询的执行计划时，重点关注：
1. 是否有 Seq Scan 在大表上——通常需要索引
2. 实际行数（Actual Rows）和估计行数（Estimated Rows）的差异——可能是统计信息过期
3. 高成本的 Sort 节点——是否可以用索引避免排序
4. 嵌套循环的内外表选择——小表在外、大表在内

```sql
-- 分析一个实际案例
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'pending';

-- 结果
Seq Scan on orders  (cost=0.00..18406.00 rows=1500 width=200)
                     (actual time=0.023..120.456 rows=3 loops=1)
  Filter: (status = 'pending'::text)
  Rows Removed by Filter: 999997
Planning Time: 0.234 ms
Execution Time: 120.512 ms
```

100 万行里只找到 3 行，但扫描了整张表。这就是典型的需要加索引的场景。

## 索引策略：不是越多越好

索引是数据库优化的双刃剑。读快写慢，这是铁律。

### B-tree 索引

B-tree 是默认的索引类型，适合等值查询和范围查询。

```sql
-- 单列索引
CREATE INDEX idx_orders_status ON orders(status);

-- 复合索引——最左前缀原则
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- 部分索引——只索引符合条件的行
CREATE INDEX idx_orders_pending ON orders(created_at)
WHERE status = 'pending';
```

复合索引的最左前缀原则：

```sql
-- 索引: (user_id, created_at)

-- 能用上索引
WHERE user_id = 1
WHERE user_id = 1 AND created_at > '2024-01-01'
WHERE user_id IN (1, 2, 3)

-- 不能用上索引（缺少最左列）
WHERE created_at > '2024-01-01'

-- 可能只用上部分索引
WHERE user_id = 1 ORDER BY created_at  -- user_id 用索引，created_at 可能文件排序
```

我在一个项目里见过这样的复合索引：`(status, user_id, created_at)`。但查询几乎都是 `WHERE user_id = ? AND created_at > ?`，`status` 放在最前面导致索引完全没被用到。调整成 `(user_id, created_at, status)` 后，查询从 800ms 降到 5ms。

### 哈希索引

PostgreSQL 10+ 的哈希索引已经支持 WAL（Write-Ahead Logging），可以安全用于生产。

```sql
CREATE INDEX idx_users_email_hash ON users USING HASH(email);
```

哈希索引只支持等值查询（`=`），不支持范围查询。但对于 UUID 或长字符串的等值查询，哈希索引比 B-tree 更小、更快。

### 覆盖索引

覆盖索引（Covering Index）指查询需要的所有列都在索引中，不需要回表查数据。

```sql
-- 查询只需要 user_id 和 total
SELECT user_id, total FROM orders WHERE status = 'completed';

-- 覆盖索引——INCLUDE 把非键列附加到索引
CREATE INDEX idx_orders_status_covering ON orders(status)
INCLUDE (user_id, total);
```

覆盖索引的 `INCLUDE` 列不参与索引排序，只作为"附加重量"存储在索引叶子节点。这使得索引可以覆盖更多查询，同时不影响索引的维护成本。

索引策略对比：

| 索引类型 | 适用查询 | 写操作开销 | 存储开销 |
|---------|---------|-----------|---------|
| B-tree | =, <, >, BETWEEN, LIKE 'abc%' | 中 | 中 |
| Hash | = | 低 | 低 |
| GiST | 全文检索、几何数据 | 高 | 高 |
| GIN | 数组、JSONB、全文检索 | 高 | 高 |
| BRIN | 大块有序数据 | 极低 | 极低 |

### 不该加索引的场景

- 数据量很小的表（< 1000 行）——顺序扫描更快
- 写多读少的表——索引维护成本可能超过查询收益
- 低选择性的列（如性别、布尔值）——索引过滤效果差
- 频繁更新的列——索引维护开销大

## 窗口函数：分析查询的利器

窗口函数（Window Function）在 PostgreSQL 8.4+ 就有了，但很多人还是只会用自连接或子查询来实现排名、累计等分析需求。

```sql
-- 每个用户最近 3 笔订单
SELECT user_id, order_id, total, created_at,
       ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
FROM orders
QUALIFY rn <= 3;  -- PostgreSQL 用子查询，MySQL 8+ 支持 QUALIFY

-- PostgreSQL 写法
WITH ranked AS (
  SELECT user_id, order_id, total, created_at,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
  FROM orders
)
SELECT * FROM ranked WHERE rn <= 3;
```

常见窗口函数：

| 函数 | 作用 | 示例 |
|------|------|------|
| ROW_NUMBER() | 行号，无重复 | 排名 |
| RANK() | 排名，有跳跃 | 1, 2, 2, 4 |
| DENSE_RANK() | 密集排名 | 1, 2, 2, 3 |
| LAG()/LEAD() | 前后行取值 | 同比环比 |
| FIRST_VALUE()/LAST_VALUE() | 首尾值 | 分组边界值 |
| SUM()/AVG() OVER | 累计求和/平均 | 累计销售额 |
| NTILE(n) | 分桶 | 四分位数 |

累计求和的例子：

```sql
-- 每日累计销售额
SELECT
    date_trunc('day', created_at) as day,
    SUM(total) as daily_total,
    SUM(SUM(total)) OVER (ORDER BY date_trunc('day', created_at)) as cumulative_total
FROM orders
GROUP BY date_trunc('day', created_at)
ORDER BY day;
```

移动平均的例子：

```sql
-- 7 日移动平均
SELECT
    date,
    daily_sales,
    AVG(daily_sales) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7d
FROM daily_sales;
```

## CTE 递归查询：处理树形结构

CTE（Common Table Expression）让复杂查询更易读，递归 CTE 则可以处理树形、图状数据。

```sql
-- 组织架构——查某个人的所有下属
WITH RECURSIVE subordinates AS (
    -- 锚点：找到起始员工
    SELECT id, name, manager_id, 0 as level
    FROM employees
    WHERE id = 1  -- CEO

    UNION ALL

    -- 递归：找到下属的下级
    SELECT e.id, e.name, e.manager_id, s.level + 1
    FROM employees e
    INNER JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates ORDER BY level, name;
```

递归 CTE 的限制：
- 必须有一个非递归部分（锚点）和一个递归部分，用 UNION ALL 连接
- 递归部分只能引用 CTE 一次，且不能在子查询中引用
- 默认有递归深度限制（PostgreSQL 默认 100 层，可通过 `max_recursion_depth` 调整）

树形路径查询：

```sql
-- 查从根节点到当前节点的完整路径
WITH RECURSIVE path AS (
    SELECT id, name, parent_id, ARRAY[id] as path
    FROM categories
    WHERE id = 42  -- 目标节点

    UNION ALL

    SELECT c.id, c.name, c.parent_id, c.id || p.path
    FROM categories c
    INNER JOIN path p ON c.id = p.parent_id
)
SELECT * FROM path WHERE parent_id IS NULL;  -- 根节点
```

## 查询重写技巧

有时候查询的性能问题不在索引，而在写法本身。

### 避免 SELECT *

```sql
-- 坏：读取所有列，增加 I/O
SELECT * FROM users WHERE id = 1;

-- 好：只读需要的列
SELECT id, username, email FROM users WHERE id = 1;
```

### 用 EXISTS 替代 IN

```sql
-- 慢：子查询返回大量数据
SELECT * FROM orders
WHERE user_id IN (SELECT id FROM users WHERE status = 'vip');

-- 快：半连接，找到就停
SELECT * FROM orders o
WHERE EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = o.user_id AND u.status = 'vip'
);
```

### 分页优化

```sql
-- 坏： OFFSET 越大越慢
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10 OFFSET 100000;

-- 好：用游标/键集分页
SELECT * FROM orders
WHERE created_at < '2024-06-01 12:00:00'  -- 上一页最后一条的时间
ORDER BY created_at DESC
LIMIT 10;
```

### UNION ALL 替代 UNION

```sql
-- UNION 会去重，需要排序或哈希操作
SELECT user_id FROM orders_2023
UNION
SELECT user_id FROM orders_2024;

-- UNION ALL 不去重，效率更高
SELECT user_id FROM orders_2023
UNION ALL
SELECT user_id FROM orders_2024;
```

如果确定不会有重复，或者业务上不关心重复，用 `UNION ALL`。

### 批量插入优化

```sql
-- 慢：逐条插入
INSERT INTO logs (message) VALUES ('msg1');
INSERT INTO logs (message) VALUES ('msg2');

-- 快：批量插入
INSERT INTO logs (message) VALUES ('msg1'), ('msg2'), ('msg3');

-- 更快：COPY（PostgreSQL）
COPY logs (message) FROM '/tmp/logs.csv' WITH CSV;
```

## 事务隔离级别与并发控制

事务隔离级别决定了一个事务能看到其他事务的哪些修改。

```sql
-- 设置隔离级别
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- ... 业务逻辑 ...
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

四种隔离级别：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 | 实现方式 |
|---------|------|-----------|------|---------|
| READ UNCOMMITTED | 可能 | 可能 | 可能 | 几乎不用 |
| READ COMMITTED | 否 | 可能 | 可能 | 默认（PostgreSQL/MySQL） |
| REPEATABLE READ | 否 | 否 | 可能 | MVCC |
| SERIALIZABLE | 否 | 否 | 否 | 锁/MVCC + 冲突检测 |

### 锁机制

PostgreSQL 的锁分几个层次：

```sql
-- 表级锁
LOCK TABLE orders IN SHARE MODE;  -- 共享锁
LOCK TABLE orders IN EXCLUSIVE MODE;  -- 排他锁

-- 行级锁（自动获取）
SELECT * FROM orders WHERE id = 1 FOR UPDATE;  -- 排他锁
SELECT * FROM orders WHERE id = 1 FOR SHARE;   -- 共享锁

-- 跳过已锁定的行
SELECT * FROM orders WHERE status = 'pending'
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

`SKIP LOCKED` 是实现队列的利器。多个 worker 同时消费任务表时，用 `FOR UPDATE SKIP LOCKED` 可以避免竞争：

```sql
-- Worker 1
BEGIN;
SELECT * FROM jobs WHERE status = 'pending'
ORDER BY created_at
FOR UPDATE SKIP LOCKED
LIMIT 1;
-- 拿到 job_id = 1

-- Worker 2（同时执行）
SELECT * FROM jobs WHERE status = 'pending'
ORDER BY created_at
FOR UPDATE SKIP LOCKED
LIMIT 1;
-- 跳过被锁的 job_id = 1，拿到 job_id = 2
```

### 死锁检测

死锁发生时，数据库会自动检测并终止其中一个事务（通常是修改更少的事务）。

避免死锁的原则：
1. **固定加锁顺序**：所有事务都按相同顺序访问表/行
2. **尽量缩短事务**：长事务持有锁的时间长，更容易冲突
3. **一次性获取所有锁**：如果可能，在事务开始时就把需要的锁都拿到

```sql
-- 坏：不同顺序导致死锁
-- 事务 A: 先锁 account 1，再锁 account 2
-- 事务 B: 先锁 account 2，再锁 account 1

-- 好：统一按 ID 排序后加锁
UPDATE accounts SET balance = balance - 100 WHERE id = LEAST(from_id, to_id);
UPDATE accounts SET balance = balance + 100 WHERE id = GREATEST(from_id, to_id);
```

## 统计信息与查询优化器

查询优化器依赖统计信息来做成本估算。统计信息过期会导致错误的执行计划。

```sql
-- 查看表的统计信息
SELECT
    attname,
    n_distinct,
    most_common_vals,
    most_common_freqs,
    correlation
FROM pg_stats
WHERE tablename = 'orders';

-- 手动更新统计信息
ANALYZE orders;

-- 更新特定列的统计信息
ANALYZE orders (status, user_id);
```

自动清理配置：

```sql
-- autovacuum 自动更新统计信息
ALTER TABLE orders SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);
```


## 分区表：大数据量的利器

当单表数据量超过千万行时，即使加了索引，查询和写入性能都会下降。分区表把大表拆成多个小表，查询时只扫描相关分区。

```sql
-- PostgreSQL 范围分区
CREATE TABLE orders (
    id bigint,
    user_id int,
    total decimal(10,2),
    created_at timestamp
) PARTITION BY RANGE (created_at);

-- 创建分区
CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE orders_2024_03 PARTITION OF orders
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
```

分区表查询的优势：

```sql
-- 这个查询只扫描 orders_2024_01 分区
SELECT * FROM orders WHERE created_at BETWEEN '2024-01-01' AND '2024-01-15';
```

分区策略对比：

| 分区类型 | 适用场景 | 优点 | 缺点 |
|---------|---------|------|------|
| 范围分区 | 时间序列数据 | 查询高效 | 热点集中在最新分区 |
| 列表分区 | 分类明确的枚举值 | 精准定位 | 分区数量受限 |
| 哈希分区 | 均匀分布的数据 | 负载均衡 | 范围查询需扫描全部分区 |

分区表的维护：

```sql
-- 查看分区信息
SELECT
    parent.relname as parent_table,
    child.relname as partition_name,
    pg_get_expr(child.relpartbound, child.oid) as partition_bounds
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
WHERE parent.relname = 'orders';

-- 创建新分区（按月自动分区通常用触发器或 pg_partman 扩展）
CREATE TABLE orders_2024_04 PARTITION OF orders
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

-- 删除旧分区（比 DELETE 快得多）
DROP TABLE orders_2023_01;
```

## 物化视图：预计算复杂查询

物化视图把查询结果存储为物理表，定时刷新，适合读多写少、计算复杂的场景。

```sql
-- 创建物化视图
CREATE MATERIALIZED VIEW daily_revenue AS
SELECT
    date_trunc('day', created_at) as day,
    COUNT(*) as order_count,
    SUM(total) as revenue,
    AVG(total) as avg_order_value
FROM orders
GROUP BY date_trunc('day', created_at)
ORDER BY day;

-- 创建索引（物化视图支持索引）
CREATE INDEX idx_daily_revenue_day ON daily_revenue(day);

-- 手动刷新
REFRESH MATERIALIZED VIEW daily_revenue;

-- 并发刷新（不阻塞读）
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_revenue;
```

物化视图的刷新策略：

| 策略 | 实现 | 适用场景 |
|------|------|---------|
| 手动刷新 | `REFRESH MATERIALIZED VIEW` | 数据变化不频繁 |
| 定时刷新 | pg_cron 或系统定时任务 | 日报、周报 |
| 触发器刷新 | INSERT/UPDATE 触发器 | 近实时需求 |
| 增量刷新 | pg_ivm 扩展 | 大数据量频繁更新 |

## 连接池：管理好数据库连接

数据库连接是昂贵的资源。创建连接需要 TCP 握手、认证、内存分配。连接池复用连接，避免频繁创建销毁。

连接池关键参数：

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| min_pool_size | 最小连接数 | 5-10 |
| max_pool_size | 最大连接数 | 20-50（视数据库配置） |
| connection_timeout | 连接超时 | 30s |
| idle_timeout | 空闲超时 | 10min |
| max_lifetime | 连接最大存活时间 | 30min |

PostgreSQL 的连接成本比 MySQL 高。如果并发连接数很高（> 100），考虑用 PgBouncer 做连接池代理：

```ini
# pgbouncer.ini
databases
    mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

`pool_mode = transaction` 模式下，连接在事务结束后归还到池里，下一个请求可以复用。这比会话级复用更高效，但需要注意 `SET` 命令的影响不会跨事务保留。

## 查询计划缓存与参数化查询

参数化查询不仅可以防止 SQL 注入，还能利用查询计划缓存。

```sql
-- 参数化查询（计划缓存）
PREPARE get_user (int) AS
    SELECT * FROM users WHERE id = $1;

EXECUTE get_user(1);
EXECUTE get_user(2);
EXECUTE get_user(3);

DEALLOCATE get_user;
```

但在某些情况下，参数化查询会导致计划缓存不理想：

```sql
-- 问题：status = 'pending' 只有 3 行，status = 'completed' 有 99 万行
-- 参数化查询可能用一个通用的计划，对两种情况的性能都一般

-- 解决：条件分支（PostgreSQL 12+ 的 plan cache 已经改善了这个问题）
SELECT * FROM orders WHERE status = $1;

-- 或者对特定值使用字面量（需要权衡 SQL 注入风险）
```

PostgreSQL 的 `plan_cache_mode` 参数控制计划缓存行为：
- `auto`：自动选择（默认）
- `force_generic_plan`：总是使用通用计划
- `force_custom_plan`：总是重新生成计划

## 数据库监控与慢查询分析

持续的监控是性能优化的基础。

```sql
-- 查看当前运行的查询
SELECT
    pid,
    now() - query_start as duration,
    state,
    left(query, 100) as query_snippet
FROM pg_stat_activity
WHERE state = 'active'
  AND query NOT LIKE '%pg_stat_activity%'
ORDER BY duration DESC;

-- 查看锁等待
SELECT
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

PostgreSQL 的 `pg_stat_statements` 扩展是慢查询分析的利器：

```sql
-- 安装扩展
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 查看最耗时的查询
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows,
    shared_blks_hit,
    shared_blks_read
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

生产环境建议开启 `log_min_duration_statement` 记录慢查询：

```ini
# postgresql.conf
log_min_duration_statement = 1000  -- 记录执行超过 1 秒的查询
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

## 分区表：大数据量的利器

当单表数据量超过千万行时，即使加了索引，查询和写入性能都会下降。分区表把大表拆成多个小表，查询时只扫描相关分区。

```sql
-- PostgreSQL 范围分区
CREATE TABLE orders (
    id bigint,
    user_id int,
    total decimal(10,2),
    created_at timestamp
) PARTITION BY RANGE (created_at);

-- 创建分区
CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

分区策略对比：

| 分区类型 | 适用场景 | 优点 | 缺点 |
|---------|---------|------|------|
| 范围分区 | 时间序列数据 | 查询高效 | 热点集中在最新分区 |
| 列表分区 | 分类明确的枚举值 | 精准定位 | 分区数量受限 |
| 哈希分区 | 均匀分布的数据 | 负载均衡 | 范围查询需扫描全部分区 |

分区表的维护：

```sql
-- 查看分区信息
SELECT parent.relname as parent_table, child.relname as partition_name
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
WHERE parent.relname = 'orders';

-- 删除旧分区（比 DELETE 快得多）
DROP TABLE orders_2023_01;
```

## 物化视图：预计算复杂查询

物化视图把查询结果存储为物理表，定时刷新，适合读多写少、计算复杂的场景。

```sql
-- 创建物化视图
CREATE MATERIALIZED VIEW daily_revenue AS
SELECT
    date_trunc('day', created_at) as day,
    COUNT(*) as order_count,
    SUM(total) as revenue,
    AVG(total) as avg_order_value
FROM orders
GROUP BY date_trunc('day', created_at)
ORDER BY day;

-- 创建索引（物化视图支持索引）
CREATE INDEX idx_daily_revenue_day ON daily_revenue(day);

-- 手动刷新
REFRESH MATERIALIZED VIEW daily_revenue;

-- 并发刷新（不阻塞读）
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_revenue;
```

物化视图的刷新策略：手动刷新（数据变化不频繁）、定时刷新（pg_cron 或系统定时任务）、触发器刷新（近实时需求）、增量刷新（pg_ivm 扩展）。

## 连接池：管理好数据库连接

数据库连接是昂贵的资源。创建连接需要 TCP 握手、认证、内存分配。连接池复用连接，避免频繁创建销毁。

连接池关键参数：

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| min_pool_size | 最小连接数 | 5-10 |
| max_pool_size | 最大连接数 | 20-50 |
| connection_timeout | 连接超时 | 30s |
| idle_timeout | 空闲超时 | 10min |
| max_lifetime | 连接最大存活时间 | 30min |

PostgreSQL 的连接成本比 MySQL 高。如果并发连接数很高（> 100），考虑用 PgBouncer 做连接池代理。`pool_mode = transaction` 模式下，连接在事务结束后归还到池里，下一个请求可以复用。

## 查询计划缓存与参数化查询

参数化查询不仅可以防止 SQL 注入，还能利用查询计划缓存。

```sql
-- 参数化查询（计划缓存）
PREPARE get_user (int) AS
    SELECT * FROM users WHERE id = $1;

EXECUTE get_user(1);
EXECUTE get_user(2);
DEALLOCATE get_user;
```

但在某些情况下，参数化查询会导致计划缓存不理想。比如 `status = 'pending'` 只有 3 行，`status = 'completed'` 有 99 万行，参数化查询可能用一个通用的计划。PostgreSQL 12+ 的 plan cache 已经改善了这个问题，可以通过 `plan_cache_mode` 参数控制。

## 数据库监控与慢查询分析

持续的监控是性能优化的基础。

```sql
-- 查看当前运行的查询
SELECT pid, now() - query_start as duration, state, left(query, 100) as query_snippet
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

-- 查看锁等待
SELECT blocked_locks.pid AS blocked_pid, blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

PostgreSQL 的 `pg_stat_statements` 扩展是慢查询分析的利器：

```sql
-- 查看最耗时的查询
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

生产环境建议开启 `log_min_duration_statement` 记录慢查询。

## 总结

SQL 优化是一门实践性很强的技能。读十篇优化文章不如实际分析一个慢查询的执行计划。

| 优化手段 | 效果 | 复杂度 | 风险 |
|---------|------|--------|------|
| 添加索引 | 显著提升读性能 | 低 | 写性能下降、存储增加 |
| 查询重写 | 中等提升 | 中 | 可能改变结果 |
| 覆盖索引 | 避免回表 | 中 | 索引变大 |
| 分区表 | 大数据量查询 | 高 | 维护复杂 |
| 物化视图 | 预计算复杂查询 | 中 | 数据延迟 |
| 连接池 | 减少连接开销 | 低 | 配置不当可能溢出 |

优化的黄金法则：
1. 先分析执行计划，再决定优化方案
2. 索引不是越多越好，每个索引都要有明确的查询支撑
3. 写优化和读优化要平衡，不要顾此失彼
4. 大数据量分页用游标，不要用 OFFSET
5. 事务尽量短，锁尽量小

> "过早优化是万恶之源"——Knuth 这句话在 SQL 优化里同样适用。先把查询写对，再分析瓶颈，最后有针对性地优化。不要凭直觉加索引。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '19 days',
    NOW() - INTERVAL '19 days',
    NOW() - INTERVAL '19 days'
),

(
    1,
    'Scala：融合面向对象与函数式编程',
    'scala-fp-oop',
    'Scala 是一门将面向对象与函数式编程完美融合的语言。本文深入探讨 case class、模式匹配、隐式转换、高阶函数、特质、for-comprehension、Option/Either 以及 Akka Actor 等核心特性。',
    $doc$
# Scala：融合面向对象与函数式编程

我第一次接触 Scala 是在 2012 年，那时候 Twitter 刚刚从 Ruby 迁移到 Scala，整个社区都在讨论这门"更好的 Java"。十年过去了，Scala 的江湖地位起起伏伏，但它在某些领域依然是不可替代的存在。Spark、Kafka、Play Framework 这些重量级项目都是 Scala 写的。如果你做大数据或者分布式系统，绕不开它。

Scala 的野心很大：它想同时讨好面向对象阵营和函数式编程阵营。Martin Odersky 的设计思路很明确——不强迫你选择阵营，而是把两种范式揉在一起，让你按需取用。这种设计带来了极大的灵活性，也让学习曲线变得异常陡峭。我在面试中见过太多自称"精通 Scala"的候选人，连 `implicit` 的解析规则都说不清楚。

说个实话，Scala 的生态最近几年确实在走下坡路。Typesafe 改名 Lightbend 之后商业重心转移，社区里吵吵闹闹，Scala 3 的推出也没能挽回颓势。但瘦死的骆驼比马大，Spark 一天不死，Scala 就一天不会消亡。况且，学会 Scala 之后再看其他 JVM 语言，都会有一种"降维打击"的感觉。

## case class：不可变数据的优雅表达

case class 是我最喜欢的 Scala 特性之一。它比 Java 的 record 早出现很多年，功能也更强大。

```scala
// 定义一个 case class
case class User(name: String, email: String, age: Int)

// 创建实例——不需要 new 关键字
val alice = User("Alice", "alice@example.com", 28)

// 自动生成的 equals 和 hashCode
val alice2 = User("Alice", "alice@example.com", 28)
alice == alice2  // true

// 模式匹配解构
val User(n, e, a) = alice
// n = "Alice", e = "alice@example.com", a = 28

// copy 方法创建修改后的副本
val olderAlice = alice.copy(age = 29)
```

case class 会自动生成一堆有用的方法：`apply`、`unapply`、`copy`、`equals`、`hashCode`、`toString`。在模式匹配中，`unapply` 方法让解构变得异常自然。我在生产环境里大量用 case class 来建模领域对象，配合不可变性，消除了很多由状态突变引发的 bug。

有个细节很多人没注意到：case class 默认是 `Serializable` 的。这在分布式系统里非常重要——Spark 的 RDD 操作要求数据必须可序列化，用 case class 就省了很多事。Java 的 record 直到 Java 14 才出现，而且功能远没有 case class 丰富。

```scala
// case class 支持嵌套和递归
case class Address(city: String, zip: String)
case class Person(name: String, address: Address)

val person = Person("Bob", Address("NYC", "10001"))

// 深层 copy
val moved = person.copy(
  address = person.address.copy(city = "Boston")
)

// case object——单例的 case class
sealed trait Status
case object Pending extends Status
case object Approved extends Status
case object Rejected extends Status
```

## 模式匹配：不只是 switch 的高级版

很多从 Java 转过来的程序员把 Scala 的模式匹配当成"更好的 switch"。这完全是低估了它。模式匹配是 Scala 最核心的表达式之一，它能解构任意复杂的数据结构。

```scala
sealed trait Expr
case class Num(value: Int) extends Expr
case class Add(left: Expr, right: Expr) extends Expr
case class Mul(left: Expr, right: Expr) extends Expr

// 求值一个表达式树
def eval(expr: Expr): Int = expr match {
  case Num(value) => value
  case Add(l, r)  => eval(l) + eval(r)
  case Mul(l, r)  => eval(l) * eval(r)
}

val expr = Add(Mul(Num(2), Num(3)), Num(4))  // 2 * 3 + 4
eval(expr)  // 10
```

`sealed trait` 配合模式匹配是 Scala 中实现代数数据类型（ADT）的标准做法。编译器能检查模式匹配是否穷尽，如果你漏了某个 case，编译器会警告你。这种在编译期就捕获错误的能力，是我坚持用 Scala 做核心业务逻辑的主要原因。

我在一个支付系统里用 ADT 建模了所有交易状态。`sealed trait TransactionStatus` 下面有 `Pending`、`Completed`、`Failed`、`Refunded` 等 case class。状态转换逻辑用模式匹配实现，编译器确保我不会漏掉任何状态。结果三年下来，状态机相关的 bug 为零。

```scala
// 列表的模式匹配
def sumList(list: List[Int]): Int = list match {
  case Nil          => 0
  case head :: tail => head + sumList(tail)
}

// 守卫条件
def describe(x: Any): String = x match {
  case i: Int if i > 0 => s"正整数: $i"
  case i: Int if i < 0 => s"负整数: $i"
  case 0               => "零"
  case s: String       => s"字符串: $s"
  case _               => "其他"
}

// 提取器模式
object Email {
  def unapply(str: String): Option[(String, String)] = {
    val parts = str.split("@")
    if (parts.length == 2) Some((parts(0), parts(1))) else None
  }
}

"alice@example.com" match {
  case Email(user, domain) => s"User: $user, Domain: $domain"
  case _                   => "Not an email"
}
```

## 隐式转换：又爱又恨的黑魔法

隐式转换是 Scala 最有争议的 feature。用得好，它能让代码优雅到极致；用不好，它就是调试噩梦。

```scala
// 隐式类：为现有类型添加方法
implicit class RichInt(val n: Int) {
  def times(f: => Unit): Unit = (1 to n).foreach(_ => f)
}

// 现在所有 Int 都有 times 方法了
3.times(println("Hello!"))  // 打印三次
```

我在项目里见过最离谱的隐式转换链条：从一个字符串出发，经过三层隐式转换，最终变成数据库连接池。代码作者是三个月前离职的，现在没人敢碰那段代码。Scala 3 引入了 `given` 和 `using` 来替代老的 `implicit`，很大程度上就是为了解决隐式解析不透明的问题。

其实隐式转换本身不是问题，问题在于滥用。Scala 社区有个不成文的规矩：隐式转换只用于两种场景——类型类（type class）和扩展方法。超出这个范围，就是在给自己挖坑。

```scala
// Scala 3 的 given/using 语法
trait Ord[T] {
  def compare(x: T, y: T): Int
}

given Ord[Int] with {
  def compare(x: Int, y: Int): Int = x - y
}

def sort[T](list: List[T])(using ord: Ord[T]): List[T] =
  list.sorted(Ordering.by[T, Int](x => ord.compare(x, x)))  // 简化示意

// 使用——编译器自动找到 given 实例
sort(List(3, 1, 4, 1, 5))  // List(1, 1, 3, 4, 5)
```

## 高阶函数与函数组合

Scala 把函数提升为一等公民。你可以像传递变量一样传递函数，可以把函数作为返回值，还可以在运行时动态构造函数。

```scala
val numbers = List(1, 2, 3, 4, 5)

// map、filter、reduce——函数式编程三板斧
val doubled = numbers.map(_ * 2)           // List(2, 4, 6, 8, 10)
val evens = numbers.filter(_ % 2 == 0)     // List(2, 4)
val sum = numbers.reduce(_ + _)            // 15

// 函数组合
val addOne = (x: Int) => x + 1
val multiplyByTwo = (x: Int) => x * 2
val addOneThenDouble = addOne andThen multiplyByTwo
addOneThenDouble(3)  // 8

// 偏应用函数
def greet(greeting: String, name: String): String = s"$greeting, $name!"
val sayHello = greet("Hello", _: String)
sayHello("Alice")  // "Hello, Alice!"
```

函数组合是函数式编程的灵魂。在 Scala 里，你可以用 `andThen` 和 `compose` 把多个小函数拼接成复杂的处理管道。我在数据处理流水线里大量使用这种模式——每个阶段都是一个纯函数，组合起来就是完整的数据流。

```scala
// 柯里化
def add(x: Int)(y: Int): Int = x + y
val addFive = add(5)  // Int => Int
addFive(3)  // 8

// 函数作为参数——自定义控制结构
def timed[T](block: => T): T = {
  val start = System.nanoTime()
  val result = block
  val elapsed = (System.nanoTime() - start) / 1e6
  println(s"Elapsed: $elapsed ms")
  result
}

timed {
  Thread.sleep(100)
  42
}
```

## 特质（trait）：比接口更灵活

Scala 的 trait 是 Java 接口的超集。它可以有方法实现，可以持有抽象成员，还可以混入（mixin）到类中。Scala 通过 trait 实现了多重继承的能力，但避免了菱形继承问题。

```scala
trait Logger {
  def log(message: String): Unit = println(s"[LOG] $message")
}

trait TimestampLogger extends Logger {
  abstract override def log(message: String): Unit =
    super.log(s"${java.time.Instant.now()} $message")
}

trait FilterLogger extends Logger {
  val filterLevel: String
  abstract override def log(message: String): Unit =
    if (message.contains(filterLevel)) super.log(message)
}

// 通过 with 混入多个特质
class Service extends Logger with TimestampLogger with FilterLogger {
  val filterLevel = "ERROR"
}

val svc = new Service
svc.log("ERROR: Database connection failed")  // 会打印，带时间戳
svc.log("INFO: Request processed")             // 不会打印，被过滤了
```

`abstract override` 是 Scala 的一个独特概念，它允许你在特质中调用 `super` 的方法，即使这个方法在当前特质中还没有实现。这种线性化的混入机制，让 Scala 的 trait 比 Java 8 的默认方法灵活得多。

我在一个项目里用 trait 实现了审计日志的横切关注点。业务类只需要 `extends Auditable`，所有的数据库操作就会自动记录到审计表。这比 Spring AOP 的实现方式更轻量，也不需要任何运行时代理。

## for-comprehension：语法糖背后的 monad

Scala 的 for-comprehension 是对 monadic 操作的语法糖。它让嵌套的 `flatMap` 和 `map` 调用看起来像命令式代码。

```scala
val result = for {
  user    <- fetchUser(id)      // Option[User]
  profile <- user.profile       // Option[Profile]
  address <- profile.address    // Option[Address]
} yield address.city

// 上面的代码等价于：
// fetchUser(id).flatMap(_.profile).flatMap(_.profile.address).map(_.city)
```

我在团队里推广过 for-comprehension，发现大部分 Scala 开发者都停留在"用 for 替代嵌套 flatMap"的层面，很少有人真正理解它背后的 monad Laws。这没关系，能写出可读的代码就够了。但如果你要设计自己的 monad，那些定律是逃不掉的。

```scala
// 多个列表的笛卡尔积
val pairs = for {
  x <- List(1, 2)
  y <- List(''a'', ''b'')
} yield (x, y)
// List((1,''a''), (1,''b''), (2,''a''), (2,''b''))

// 带条件的 for-comprehension
val result = for {
  x <- List(1, 2, 3, 4, 5)
  if x > 2
  y = x * x
} yield y
// List(9, 16, 25)

// Future 的 for-comprehension
import scala.concurrent.{Future, ExecutionContext}
import scala.concurrent.duration._

implicit val ec: ExecutionContext = ExecutionContext.global

val result: Future[String] = for {
  user     <- fetchUserAsync(id)
  orders   <- fetchOrdersAsync(user.id)
  summary  <- generateSummaryAsync(orders)
} yield summary
```

## Option 与 Either：消灭 NullPointerException

Tony Hoare 称 null 引用是他"十亿美元的错误"。Scala 用 `Option` 和 `Either` 来从根本上解决这个问题。

```scala
// Option: 表示可能有值，也可能没有
val maybeValue: Option[Int] = Some(42)
val noValue: Option[Int] = None

// 安全地获取值
val result = maybeValue.getOrElse(0)  // 42
val fallback = noValue.getOrElse(0)   // 0

// 链式操作
val processed = maybeValue
  .map(_ * 2)
  .filter(_ > 50)
  .getOrElse(0)

// Either: 表示两种可能的结果类型
val success: Either[String, Int] = Right(42)
val failure: Either[String, Int] = Left("Invalid input")

// 处理错误
val finalResult = success match {
  case Right(value) => s"Success: $value"
  case Left(error)  => s"Error: $error"
}
```

在 Scala 代码里，null 应该像瘟疫一样被消灭。如果一个值可能不存在，用 `Option`；如果一个操作可能失败，用 `Either`。刚开始团队里会有人抱怨"总是需要 unwrap 太麻烦"，但三个月后，生产环境里的 NPE 基本绝迹，那些抱怨的人就闭嘴了。

```scala
// 从可能返回 null 的 Java API 安全转换
import scala.util.Try

def parseInt(str: String): Option[Int] = Try(str.toInt).toOption

// 累积错误——Either 的链式处理
import cats.implicits._

def validateName(name: String): Either[String, String] =
  if (name.nonEmpty) Right(name) else Left("Name cannot be empty")

def validateAge(age: Int): Either[String, Int] =
  if (age >= 0) Right(age) else Left("Age must be non-negative")

val validated = for {
  n <- validateName("Alice")
  a <- validateAge(25)
} yield (n, a)
// Right(("Alice", 25))
```

## Akka Actor：并发编程的另一种思路

Akka 的 Actor 模型是我在 Scala 生态里用过最久的并发框架。它的核心思想很简单：不要共享状态，通过消息传递来通信。

```scala
import akka.actor.{Actor, ActorRef, ActorSystem, Props}

// 定义一个 Actor
class Counter extends Actor {
  var count = 0

  def receive = {
    case "increment" => count += 1
    case "get"       => sender() ! count
    case "reset"     => count = 0
  }
}

// 创建 Actor 系统
val system = ActorSystem("MySystem")
val counter = system.actorOf(Props[Counter], "counter")

// 发送消息（异步、无阻塞）
counter ! "increment"
counter ! "increment"
counter ! "get"  // 收到 2
```

每个 Actor 有一个 mailbox，消息按 FIFO 顺序处理。因为 Actor 不共享状态，你不需要锁，不需要 synchronized，也不用担心死锁。Akka 让并发编程的复杂度大幅下降。

不过说实话，Akka 2.6 之后 License 改成了 BSL，商业使用有很多限制。Lightbend 的这个决策在社区里引起很大争议。如果你今天才开始一个新项目，我建议先评估一下 Akka Pekko（Apache fork）或者其他替代方案。

```scala
// 使用 ask 模式获取响应
import akka.pattern.ask
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

implicit val timeout: akka.util.Timeout = 5.seconds

val future = counter ? "get"  // Future[Any]
future.map { count =>
  println(s"当前计数: $count")
}

// Actor 层次结构和监督策略
import akka.actor.SupervisorStrategy._

class ParentActor extends Actor {
  override val supervisorStrategy =
    OneForOneStrategy(maxNrOfRetries = 10, withinTimeRange = 1.minute) {
      case _: ArithmeticException      => Resume
      case _: NullPointerException     => Restart
      case _: IllegalArgumentException => Stop
      case _: Exception                => Escalate
    }

  def receive = {
    case p: Props => sender() ! context.actorOf(p)
  }
}
```

## Future 与异步编程

Scala 标准库提供了 `Future` 来处理异步计算。配合 `flatMap` 和 `for-comprehension`，你可以写出优雅的异步代码。

```scala
import scala.concurrent.{Future, ExecutionContext}
import scala.concurrent.duration._
import scala.util.{Success, Failure}

implicit val ec: ExecutionContext = ExecutionContext.global

// 创建 Future
val f1 = Future { Thread.sleep(100); 42 }
val f2 = Future { Thread.sleep(50); 100 }

// 组合 Future
val combined = for {
  a <- f1
  b <- f2
} yield a + b  // Future(142)

// 处理失败
combined.onComplete {
  case Success(value) => println(s"Result: $value")
  case Failure(ex)    => println(s"Failed: ${ex.getMessage}")
}

// 超时控制
import scala.concurrent.Await
val result = Await.result(combined, 5.seconds)
```

## 总结

Scala 是一门让人又爱又恨的语言。它的类型系统强大到有时候你自己都不知道在写什么，编译器的错误信息长得能当论文读。但一旦跨过那个门槛，你会发现它的表达力和抽象能力几乎没有对手。

| 特性 | 作用 | 适用场景 |
|------|------|---------|
| case class | 不可变数据建模 | 领域对象、DTO |
| 模式匹配 | 数据结构解构 | 表达式求值、状态机 |
| 隐式/given | 类型类、扩展方法 | 库设计、DSL |
| 高阶函数 | 函数组合、抽象 | 数据处理管道 |
| trait | 代码复用、横切关注点 | 日志、缓存、验证 |
| for-comprehension | monadic 操作语法糖 | Option/Either/List 链式操作 |
| Option/Either | 空值与错误处理 | 所有可能失败的场景 |
| Actor | 消息驱动并发 | 分布式系统、高并发服务 |
| Future | 异步计算组合 | 非阻塞 I/O |

Scala 不适合所有人。如果你的团队以 Java 背景为主，强行切 Scala 可能会导致生产力下降和代码质量参差不齐。但如果你有充足的学习时间，并且项目确实需要高抽象层次的表达，Scala 是值得投入的选择。毕竟，Spark 和 Kafka 不会用一门烂语言来构建。

---

*本文首发于 Yggdrasil 博客*

    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '20 days'
),
(
    1,
    'Clojure：Lisp 的现代复兴',
    'clojure-lisp-revival',
    'Clojure 是 Lisp 家族在 JVM 上的现代复兴。本文探讨其 S-expression 语法、不可变数据结构、STM 软件事务内存、宏系统、多方法、Java 互操作以及 REPL 驱动开发等核心特性。',
    $doc$
# Clojure：Lisp 的现代复兴

Lisp 诞生于 1958 年，比 C 还早十几年。在编程语言的进化树上，Lisp 是一个异常长寿的分支——Fortran 已经变得面目全非，Cobol 变成了古董，但 Lisp 的精神通过各种方言延续至今。Clojure 就是其中最成功的现代变体之一。

Rich Hickey 在 2007 年创造了 Clojure。他没有选择重新发明虚拟机，而是直接寄生在 JVM 上。这个决策极其聪明：Java 生态里有海量的库和成熟的基础设施，Clojure 程序员可以直接调用。加上不可变数据结构和 STM（软件事务内存），Clojure 成为了一门既有历史底蕴又有现代特性的语言。

我第一次在生产环境用 Clojure 是 2015 年，做一个金融数据处理的 ETL 管道。三年下来，代码量只有 Java 版本的三分之一，bug 数量更是少了一个数量级。那之后我对这门语言彻底改观。说个不怕得罪人的话：Clojure 的代码质量在同等项目里通常是最高的，因为 mutable state 少了，自然就少了很多莫名其妙的问题。

## 括号不是问题：S-expression 的真相

每一个讨论 Lisp 的帖子下面，都会有人抱怨"括号太多了"。这种批评通常是外行的标志。Clojure 的语法实际上极其简洁——整个语言的语法规则用一页纸就能写完。

```clojure
;; 函数调用：(函数名 参数1 参数2 ...)
(+ 1 2 3)           ; => 6
(str "Hello" " " "World")  ; => "Hello World"

;; 定义变量
(def pi 3.14159)

;; 定义函数
(defn greet [name]
  (str "Hello, " name "!"))

(greet "Alice")    ; => "Hello, Alice!"

;; 条件表达式
(if (> 10 5)
  "yes"
  "no")           ; => "yes"
```

前缀表示法（operator 在前，操作数在后）的好处是完全没有优先级歧义。你不需要记 `*` 和 `+` 哪个优先级高，表达式 `(+ (* 2 3) 4)` 的意思一目了然。而且，因为代码和数据使用完全相同的结构（S-expression），宏系统才能成为可能。

```clojure
;; 数据结构——同样是括号，但含义不同
[1 2 3]             ; 向量（Vector）
{:a 1 :b 2}         ; 映射（Map）
#{1 2 3}            ; 集合（Set）
''(1 2 3)            ; 列表（List），不执行

;; 函数也是一等公民
(def operations [+ - * /])
((operations 0) 1 2 3)  ; => 6，等价于 (+ 1 2 3)
```

## 不可变数据结构：持久化数据结构的妙用

Clojure 的所有核心数据结构都是不可变的。但你可能担心：如果每次修改都复制整个结构，性能岂不是要爆炸？

答案在于**持久化数据结构**（Persistent Data Structures）。它们通过结构共享来实现不可变性，时间复杂度接近可变数据结构。

```clojure
(def v1 [1 2 3])
(def v2 (conj v1 4))    ; v2 = [1 2 3 4]，v1 仍然是 [1 2 3]

;; v1 和 v2 共享大部分内部结构，只在新节点分配内存
v1  ; => [1 2 3]
v2  ; => [1 2 3 4]

;; 映射也是不可变的
(def m1 {:name "Alice" :age 28})
(def m2 (assoc m1 :city "NYC"))

m1  ; => {:name "Alice", :age 28}
m2  ; => {:name "Alice", :age 28, :city "NYC"}
```

我在一个实时数据处理系统里用 Clojure 的不可变向量作为滑动窗口的数据结构。窗口每秒滑动一次，每次产生新窗口时只需要创建少数新节点，内存占用和 GC 压力都比 Java 的 ArrayList 方案小得多。这就是持久化数据结构的威力。

```clojure
;; 嵌套数据结构的更新——用 -> 宏串联操作
(def user
  {:name "Alice"
   :address {:city "NYC"
             :zip "10001"}})

(def updated-user
  (-> user
      (assoc :age 29)
      (assoc-in [:address :city] "Boston")
      (update-in [:address :zip] str "-new")))

;; updated-user =>
;; {:name "Alice", :age 29,
;;  :address {:city "Boston", :zip "10001-new"}}
;; user 本身完全没有变化

;; 集合操作——不可变但高效
(def s1 #{1 2 3})
(def s2 (conj s1 4))     ; #{1 2 3 4}
(def s3 (disj s2 2))     ; #{1 3 4}

;; 映射的合并
(def defaults {:timeout 30 :retries 3})
(def config (merge defaults {:timeout 60}))
;; config => {:timeout 60, :retries 3}
```

## STM：软件事务内存的优雅

并发编程的两大噩梦是死锁和竞态条件。Clojure 的 STM（Software Transaction Memory）提供了一种优雅的解决方案：把共享状态的修改当成数据库事务来处理。

```clojure
(def account-a (ref 1000))
(def account-b (ref 2000))

;; 转账操作——原子性、一致性、隔离性
(defn transfer [from to amount]
  (dosync
    (let [from-balance @from]
      (when (< from-balance amount)
        (throw (Exception. "Insufficient funds"))))
    (alter from - amount)
    (alter to + amount)))

(transfer account-a account-b 300)
@account-a  ; => 700
@account-b  ; => 2300
```

`dosync` 块里的所有操作要么全部成功，要么全部回滚。如果有两个事务同时修改同一个 ref，STM 会自动重试其中一个。你不需要显式加锁，不需要担心锁的顺序，也不需要写任何同步代码。

我在一个交易系统里用过 STM 来处理订单状态机。每天处理几百万笔订单，零死锁，零竞态条件。当然，STM 也有局限：如果事务太大或者冲突太频繁，重试开销会急剧上升。这时候你就需要考虑把大事务拆小，或者改用 Agent/Atom。

```clojure
;; Agent：异步、串行的状态更新
(def counter (agent 0))

(send counter + 1)    ; 异步发送增量操作
(send counter + 5)

(await counter)       ; 等待所有操作完成
@counter              ; => 6

;; Agent 的错误处理
(def safe-counter (agent 0
                    :error-handler (fn [agent err]
                                     (println "Error:" err))
                    :error-mode :continue))

;; Atom：同步、无协调的 CAS 更新
(def visits (atom 0))
(swap! visits inc)    ; 原子地增加
@visits               ; => 1

;; Atom 支持验证函数
(def valid-counter (atom 0 :validator #(>= % 0)))
;; (reset! valid-counter -1)  ; 抛出 IllegalStateException
```

## 宏系统：代码即数据，数据即代码

宏是 Lisp 的灵魂。因为 Clojure 代码本身就是数据结构（S-expression），你可以在编译期随意构造、分析和修改代码。这比 C 的文本替换宏强大太多了。

```clojure
;; 自定义 when 宏
(defmacro my-when [condition & body]
  `(if ~condition
     (do ~@body)
     nil))

;; 使用
(my-when (> 5 3)
  (println "Condition is true")
  (+ 1 2 3))
;; 展开后等价于：
;; (if (> 5 3)
;;   (do (println "Condition is true") (+ 1 2 3))
;;   nil)
```

我在项目里写过一个 `defapi` 宏，用来简化 REST API 端点的定义。原本需要写二十几行样板代码，用宏之后只要三行。宏的力量在于它能消除所有机械重复的代码，让你的 DSL 看起来像语言原生的一部分。

```clojure
;; 带计时的宏
(defmacro timed [expr]
  `(let [start# (System/nanoTime)
         result# ~expr
         elapsed# (/ (- (System/nanoTime) start#) 1e6)]
     (println (str "Elapsed: " elapsed# " ms"))
     result#))

(timed (reduce + (range 1000000)))
;; Elapsed: 45.231 ms
;; => 499999500000

;; 自定义的线程安全宏
(defmacro synchronized [lock & body]
  `(locking ~lock
     ~@body))
```

但要注意，宏是编译期的魔法。滥用宏会让代码难以理解和调试。我的原则是：只有出现明显的重复模式时，才考虑写宏。不要为了炫技而写宏。

## 多方法：超越传统多态

Clojure 的 multimethod 是一种基于任意 dispatch 函数的多态机制。它不限于类型 dispatch，可以根据任何逻辑来决定调用哪个方法。

```clojure
;; 基于类型的 dispatch
(defmulti encounter (fn [x y] [(:species x) (:species y)]))

(defmethod encounter [:bunny :lion] [b l]
  :run-away)

(defmethod encounter [:lion :bunny] [l b]
  :eat)

(defmethod encounter [:lion :lion] [l1 l2]
  :fight)

(defmethod encounter :default [x y]
  :ignore)

(encounter {:species :bunny} {:species :lion})   ; => :run-away
(encounter {:species :lion} {:species :lion})    ; => :fight
```

这比 Java 的面向对象多态灵活得多。你可以根据多个参数的值来 dispatch，可以根据参数的属性来 dispatch，甚至可以根据运行时状态来 dispatch。我在一个规则引擎里用 multimethod 来实现策略分发，代码清晰得不像话。

```clojure
;; 基于计算结果的 dispatch
(defmulti tax-rate :country)

(defmethod tax-rate "US" [_] 0.08)
(defmethod tax-rate "UK" [_] 0.20)
(defmethod tax-rate "JP" [_] 0.10)
(defmethod tax-rate :default [_] 0.0)

(tax-rate {:country "UK"})  ; => 0.20
(tax-rate {:country "FR"})  ; => 0.0

;; 更复杂的 dispatch——基于自定义逻辑
(defmulti process-request
  (fn [request]
    (cond
      (contains? request :file-upload) :file
      (> (:payload-size request 0) 1000000) :large
      :else :normal)))

(defmethod process-request :file [req]
  (str "Processing file upload: " (:filename req)))

(defmethod process-request :large [req]
  "Processing large payload asynchronously")

(defmethod process-request :normal [req]
  "Processing normal request")
```

## 与 Java 互操作：站在巨人肩膀上

Clojure 最大的优势之一就是能无缝调用 Java 代码。JVM 上二十多年的生态积累，你直接拿来用。

```clojure
;; 创建 Java 对象
(import ''[java.util Date ArrayList])
(def now (Date.))
(.getTime now)           ; => 1640000000000

;; 调用 Java 方法
(def list (ArrayList.))
(.add list "Hello")
(.add list "World")
(.size list)             ; => 2

;; 更 Clojure 风格的方式
(doto (ArrayList.)
  (.add "Hello")
  (.add "World"))

;; 使用 Java 8 Stream
(import ''[java.util Arrays])
(-> (Arrays/stream (into-array Integer [1 2 3 4 5]))
    (.filter (reify java.util.function.Predicate
               (test [_ x] (> x 2))))
    (.map (reify java.util.function.Function
            (apply [_ x] (* x x))))
    (.toList))
;; 当然，Clojure 自带的序列操作更简洁...
```

Java 互操作意味着你可以用 Clojure 写业务逻辑，用 Java 写性能敏感的底层代码。我们团队在一个高性能计算项目里就是这么做：核心算法用 Java 写，数据流编排和配置用 Clojure 写，两边配合得天衣无缝。

```clojure
;; 使用 Java 的并发工具
(import ''[java.util.concurrent Executors CountDownLatch])

(def executor (Executors/newFixedThreadPool 4))
(def latch (CountDownLatch. 3))

(dotimes [i 3]
  (.execute executor
    #(do
       (println (str "Task " i " running on " (.getName (Thread/currentThread))))
       (.countDown latch))))

(.await latch)
(.shutdown executor)

;; 调用 Apache Commons 等第三方库
;; [org.apache.commons/commons-lang3 "3.12.0"]
(import ''[org.apache.commons.lang3 StringUtils])
(StringUtils/reverse "hello")  ; => "olleh"
```

## REPL 驱动开发：实时编程

Clojure 的 REPL（Read-Eval-Print Loop）是我用过的最 productive 的开发环境之一。它不是那种 toy REPL——它是真正的开发环境，可以在运行时修改生产代码。

```clojure
;; 在 REPL 中实时开发
user=> (defn process-data [data]
  #_=>   (map inc data))
user=> (process-data [1 2 3 4 5])
(2 3 4 5 6)

;; 发现 bug，立即修复
user=> (defn process-data [data]
  #_=>   (map #(+ % 10) data))
user=> (process-data [1 2 3])
(11 12 13)

;; 检查运行时状态
user=> (def state (atom {:count 0 :items []}))
user=> (swap! state update :count inc)
{:count 1, :items []}
```

Clojure 的 REPL 驱动开发流程是这样的：你在编辑器里写函数，按一个快捷键把代码发送到 REPL 执行，立即看到结果。发现不对就修改再发送。整个过程以秒为单位循环，而不是以分钟为单位编译-运行-调试。

我曾在凌晨两点接到生产环境告警，连上 REPL，定位到问题函数，修改代码发送到运行中的进程，问题当场解决。整个过程没有重启服务，没有部署，没有停机。这种能力在其他语言里几乎不存在。

```clojure
;; 使用 tools.namespace 实现代码热重载
(require ''[clojure.tools.namespace.repl :refer [refresh]])

;; 修改源文件后
(refresh)
;; :reloading (my-project.core my-project.utils)
;; :ok

;; Stuart Sierra 的 Component 库管理应用生命周期
(require ''[com.stuartsierra.component :as component])

(defrecord Database [host port connection]
  component/Lifecycle
  (start [this]
    (println "Starting database connection...")
    (assoc this :connection (connect host port)))
  (stop [this]
    (println "Stopping database connection...")
    (.close connection)
    (assoc this :connection nil)))
```

## Transducers：高阶抽象的极致

Transducer 是 Rich Hickey 在 2014 年引入的一个概念。它把 map、filter、take 等序列操作从数据源（列表、流、channel）中解耦出来，成为一种可复用的转换逻辑。

```clojure
;; 定义一个 transducer
(def xform
  (comp
    (filter odd?)
    (map inc)
    (take 5)))

;; 应用于不同数据源
(into [] xform (range 100))
;; => [2 4 6 8 10]

;; 应用于 channel
(require ''[clojure.core.async :refer [chan pipeline]]))

(def input (chan))
(def output (chan))
(pipeline 4 output xform input)
```

Transducer 的优雅之处在于零开销组合。`(comp (filter f) (map g))` 在遍历序列时只遍历一次，而不是先过滤整个序列再映射整个序列。对于大数据流，这个区别可能是性能上的天壤之别。

```clojure
;; 自定义 transducer
(defn mapping [f]
  (fn [rf]
    (fn
      ([] (rf))
      ([result] (rf result))
      ([result input]
       (rf result (f input))))))

(defn filtering [pred]
  (fn [rf]
    (fn
      ([] (rf))
      ([result] (rf result))
      ([result input]
       (if (pred input)
         (rf result input)
         result)))))

;; 使用自定义 transducer
(into [] (comp (filtering even?) (mapping #(* % %))) (range 10))
;; => [0 4 16 36 64]
```

## Spec：数据规范与验证

Clojure 1.9 引入了 `clojure.spec`，提供了一种声明式的数据规范机制。跟静态类型不同，spec 在运行时验证数据，并且可以用于生成测试数据、文档和错误信息。

```clojure
(require ''[clojure.spec.alpha :as s])

;; 定义规范
(s/def ::name string?)
(s/def ::age (s/and int? #(>= % 0)))
(s/def ::email (s/and string? #(re-matches #".+@.+" %)))
(s/def ::person (s/keys :req [::name ::age] :opt [::email]))

;; 验证数据
(s/valid? ::person {::name "Alice" ::age 28})
;; => true

(s/valid? ::person {::name "Bob" ::age -5})
;; => false

(s/explain ::person {::name "Bob" ::age -5})
;; -5 - failed: (>= % 0)

;; 用 spec 生成测试数据
(require ''[clojure.spec.gen.alpha :as gen])
(gen/sample (s/gen ::person) 3)
;; => ({:user/name "" :user/age 0}
;;     {:user/name "x" :user/age 1 :user/email "a@b"}
;;     {:user/name "yz" :user/age 2})
```

我在 API 接口层大量使用 spec 来做输入验证。它比手写验证逻辑清晰得多，而且 `s/explain` 生成的错误信息可以直接返回给客户端。

## 总结

Clojure 不是一门大众语言，但它的设计哲学深刻影响了很多现代语言。不可变数据结构被 JavaScript（Immutable.js）、Java（Vavr）广泛借鉴；STM 的概念启发了数据库和分布式系统的设计；宏系统虽然难以在其他语言中复制，但其"代码即数据"的思想被各种 AST 转换工具继承。

| 特性 | 作用 | 学习难度 |
|------|------|---------|
| S-expression | 统一的代码/数据表示 | 低（克服括号恐惧后） |
| 不可变数据结构 | 安全、可预测的代码 | 中（改变思维方式） |
| STM | 无锁并发 | 中 |
| 宏 | 编译期元编程 | 高 |
| 多方法 | 灵活的多态 | 低 |
| Java 互操作 | 生态复用 | 低 |
| REPL | 实时开发 | 低 |
| Transducers | 零开销序列转换 | 中 |
| Spec | 数据验证与生成 | 低 |

Clojure 适合什么样的人？如果你喜欢函数式编程，如果你厌倦了 null 和 mutable state 带来的痛苦，如果你想用 Lisp 的智慧来解决实际问题——Clojure 是你的菜。但如果你对括号有生理厌恶，或者你的团队无法接受 Lisp 的思维方式，那还是不要勉强。

---

*本文首发于 Yggdrasil 博客*

    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '21 days'
),
(
    1,
    'Julia：高性能科学计算的新选择',
    'julia-scientific-computing',
    'Julia 是为科学计算设计的高性能动态语言。本文深入讲解多重派发、类型系统、数组操作、并行计算、与 Python/C 互操作、Plots 绘图、微分方程求解以及性能优化技巧。',
    $doc$
# Julia：高性能科学计算的新选择

2012 年，四位 MIT 的研究员发布了 Julia 的第一个公开版本。他们的动机很直接：现有的科学计算工具要么太慢（Python、R、MATLAB），要么太难写（C、Fortran）。能不能有一门语言，既有脚本语言的易用性，又有编译语言的性能？

Julia 给出的答案是：能。

我在 2018 年开始用 Julia 做数值模拟。第一印象是"这语法跟 Python 也太像了"，第二印象是"卧槽这速度跟 C 一样"。Julia 的性能不是靠 C 扩展实现的，而是靠 LLVM JIT 编译和精心设计的类型系统。这意味着你写的 Julia 代码本身就是高性能代码，不需要为了速度去写 C 扩展。

Julia 的社区文化我也很喜欢。它不像 Python 那样什么都想包圆，而是专注在科学计算这个垂直领域做到极致。如果你做物理模拟、金融工程、机器学习研究，Julia 是目前最好的选择之一。

## 多重派发：Julia 的设计灵魂

Julia 最核心的设计决策是**多重派发**（Multiple Dispatch）。这不是什么新发明——Common Lisp 的 CLOS 几十年前就有了——但 Julia 把它做到了极致。

```julia
# 定义一个抽象类型
abstract type Shape end

# 具体子类型
struct Circle <: Shape
    radius::Float64
end

struct Rectangle <: Shape
    width::Float64
    height::Float64
end

# 基于类型的多重派发
area(c::Circle) = π * c.radius^2
area(r::Rectangle) = r.width * r.height

# 调用——Julia 在运行时选择最合适的方法
c = Circle(5.0)
r = Rectangle(4.0, 6.0)

area(c)  # 78.5398...
area(r)  # 24.0
```

多重派发的美妙之处在于，你可以在不修改原有代码的情况下，为新的类型添加行为。这在科学计算里特别有用——比如某个第三方库定义了 `Matrix` 类型，你可以直接为自己的自定义类型扩展 `*`、`+` 等运算符，而不需要继承或者 monkey patch。

```julia
# 为自定义类型定义加法
struct Point{T}
    x::T
    y::T
end

Base.:+(a::Point, b::Point) = Point(a.x + b.x, a.y + b.y)
Base.:*(s::Number, p::Point) = Point(s * p.x, s * p.y)

p1 = Point(1.0, 2.0)
p2 = Point(3.0, 4.0)
p1 + p2           # Point{Float64}(4.0, 6.0)
2 * p1            # Point{Float64}(2.0, 4.0)

# 多重派发的威力——为现有函数添加新类型支持
Base.show(io::IO, p::Point) = print(io, "Point(", p.x, ", ", p.y, ")")
println(p1)  # Point(1.0, 2.0)
```

## 类型系统：灵活与性能的平衡

Julia 的类型系统是可选的。你可以完全不写类型注解，代码照样运行；也可以在关键路径上加上类型标注，让编译器生成更高效的机器码。

```julia
# 无类型注解——动态、灵活
function greet(name)
    "Hello, $name!"
end

# 有类型注解——编译器可以优化
function greet_typed(name::String)::String
    "Hello, $name!"
end

# 参数化类型
struct Container{T}
    value::T
end

# T 可以是任何类型
c1 = Container(42)       # Container{Int64}
c2 = Container("hello")  # Container{String}
```

Julia 的类型系统有一个独特的概念叫**类型稳定性**（Type Stability）。如果一个函数的返回类型可以从输入类型推断出来，Julia 编译器就能生成高度优化的 LLVM IR。反之，如果返回类型不确定，编译器只能生成保守的代码，性能会大打折扣。

```julia
# 类型不稳定的函数——性能差
function unstable(x)
    if x > 0
        x            # 返回 Int
    else
        "negative"   # 返回 String
    end
end

# 类型稳定的函数——性能好
function stable(x)::Int
    if x > 0
        x
    else
        0
    end
end
```

我调优过一个数值积分程序，发现 80% 的时间花在了一个类型不稳定的辅助函数上。加了一个类型注解，性能直接提升了 4 倍。Julia 的 `@code_warntype` 宏是这类优化的神器：

```julia
@code_warntype unstable(5)
# 输出中红色标注的位置就是类型不稳定的点
```

类型推断是 Julia 编译器的核心能力。你写 `x = 5`，编译器知道 x 是 Int64；你写 `y = [1.0, 2.0, 3.0]`，编译器知道 y 是 Vector{Float64}。这些类型信息在编译期就被确定下来，生成的机器码跟 C 一样快。

## 数组操作：向量化与广播

科学计算离不开数组。Julia 的数组操作设计得极其优雅，融合了 NumPy 的便利性和 MATLAB 的直观性。

```julia
# 创建数组
A = [1 2 3; 4 5 6; 7 8 9]    # 3x3 矩阵
v = [1, 2, 3]                  # 列向量

# 索引和切片
A[1, 2]        # 2（Julia 是 1-based 索引，MATLAB 用户狂喜）
A[1:2, 2:3]    # 2x2 子矩阵
A[:, 1]        # 第一列

# 广播——自动扩展维度
x = [1, 2, 3]
y = [10, 20, 30]
x .+ y         # [11, 22, 33]——点号表示逐元素操作

# 更复杂的广播
f(x, y) = x^2 + y
f.(x, 10)      # [11, 14, 19]——10 被广播到每个元素
```

Julia 的广播机制比 NumPy 的 broadcasting 更通用。任何函数前面加点号，就会自动逐元素应用。这不仅适用于内置函数，也适用于你自己的函数。

```julia
# 自定义函数的广播
myfunc(x) = x > 0 ? log(x) : 0.0
myfunc.([-1, 0.5, 1, 2])   # [0.0, -0.693..., 0.0, 0.693...]

# 矩阵运算
B = rand(3, 3)
A * B           # 矩阵乘法
A .* B          # 逐元素乘法（Hadamard 积）
A''              # 共轭转置
inv(A)          # 矩阵求逆（需要 import LinearAlgebra）

# 特殊的数组构造
zeros(3, 3)     # 3x3 零矩阵
ones(2, 4)      # 2x4 全1矩阵
rand(5)         # 长度为5的随机向量
fill(42, 2, 3)  # 2x3 全42矩阵
```

## 并行计算：从多核到分布式

Julia 内置了强大的并行计算支持，从单机多核到分布式集群，API 风格高度统一。

```julia
using Base.Threads

# 多线程并行
function parallel_sum(arr)
    total = Atomic{Int64}(0)
    @threads for i in 1:length(arr)
        atomic_add!(total, arr[i])
    end
    total[]
end

# 更简洁的并行方式——使用 @parallel 或 @distributed
using Distributed
addprocs(4)  # 启动 4 个 worker 进程

# 并行映射
result = pmap(x -> expensive_computation(x), 1:100)

# 分布式数组
using DistributedArrays
A = drand((1000, 1000), workers())  # 在多个 worker 上分布
```

Julia 的并行设计有一个我特别喜欢的地方：它区分了**任务并行**（多线程，共享内存）和**数据并行**（多进程，分布式）。前者适合计算密集型任务，后者适合内存密集型任务。这种清晰的区分在 Python 里是不存在的（Python 的 GIL 让多线程形同虚设）。

```julia
# 使用 @spawn 进行任务并行
function fib(n)
    if n < 2
        return n
    end
    t = @spawn fib(n - 2)  # 在另一个线程启动任务
    return fib(n - 1) + fetch(t)  # fetch 等待结果
end

fib(20)  # 6765

# @distributed 用于数据并行
using Distributed

@distributed (+) for i in 1:100_000_000
    i^2
end
```

## 与 Python/C 互操作：拥抱现有生态

Julia 的生态系统虽然成长迅速，但跟 Python 比还是小巫见大巫。所以 Julia 提供了非常成熟的互操作机制。

```julia
using PyCall

# 调用 Python 库
np = pyimport("numpy")
arr = np.array([1, 2, 3, 4, 5])
np.mean(arr)   # 3.0

# 调用 Python 的 pandas
pd = pyimport("pandas")
df = pd.DataFrame(Dict("A" => [1, 2, 3], "B" => ["a", "b", "c"]))

# 调用 C 函数——零开销
using Libdl

# 直接调用 C 标准库函数
ccall((:getpid, "libc"), Cint, ())

# 或者更简洁的 @ccall 宏
@ccall getpid()::Cint
```

`PyCall` 的效率出奇地高。Julia 和 Python 对象之间的转换开销很小，因为很多 Julia 数组可以直接作为 NumPy 数组的底层存储使用，不需要复制。我在一个项目里用 Julia 做核心计算，用 Python 的 matplotlib 做可视化，两边数据共享内存，切换没有任何成本。

```julia
# 双向调用——Python 也可以调用 Julia
# 使用 PyJulia 包
# from julia import Main
# Main.eval("1 + 2")  # 3

# 直接操作 Python 对象
py"""
def python_add(x, y):
    return x + y
"""
py"python_add"(1, 2)  # 3
```

## Plots.jl：可视化生态

Julia 的绘图生态经历了几次迭代，最终 `Plots.jl` 成为了主流选择。它提供了一个统一的 API，底层可以切换多个后端（GR、PyPlot、Plotly 等）。

```julia
using Plots

# 简单的线图
x = 0:0.1:2π
y = sin.(x)
plot(x, y, label="sin(x)", linewidth=2)
plot!(x, cos.(x), label="cos(x)")  # ! 表示在现有图上叠加

# 散点图
scatter(rand(100), rand(100), markersize=3, alpha=0.5)

# 热图
heatmap(rand(50, 50), color=:viridis)

# 3D 曲面
x = y = range(-2, 2, length=100)
surface(x, y, (x, y) -> sin(x) * cos(y))
```

Plots.jl 的默认样式比 matplotlib 好看不少，API 也更简洁。如果你需要交互式可视化，`PlotlyJS.jl` 后端可以生成完全交互的 HTML 图表。我在报告里经常直接导出 Plotly 的 HTML 文件发给同事，他们打开浏览器就能缩放、旋转、查看数据点。

```julia
# 多子图
p1 = plot(x, sin.(x), title="Sine")
p2 = plot(x, cos.(x), title="Cosine")
p3 = scatter(rand(50), rand(50), title="Random")
p4 = histogram(randn(1000), title="Normal Distribution")

plot(p1, p2, p3, p4, layout=(2, 2), size=(800, 600))

# 动画
@gif for i in 1:0.1:5
    plot(x, sin.(x .+ i), ylim=(-1.5, 1.5), title="Frame $i")
end
```

## 微分方程：DifferentialEquations.jl

`DifferentialEquations.jl` 是 Julia 生态里最令人印象深刻的包之一。它解决了从 ODE、SDE 到 DDE、DAE 的各种微分方程，性能号称是同类库中最快的。

```julia
using DifferentialEquations
using Plots

# 定义 Lorenz 吸引子
def lorenz!(du, u, p, t)
    σ, ρ, β = p
    du[1] = σ * (u[2] - u[1])
    du[2] = u[1] * (ρ - u[3]) - u[2]
    du[3] = u[1] * u[2] - β * u[3]
end

u0 = [1.0, 0.0, 0.0]       # 初始条件
p = [10.0, 28.0, 8/3]      # 参数 σ, ρ, β
tspan = (0.0, 100.0)       # 时间范围

prob = ODEProblem(lorenz!, u0, tspan, p)
sol = solve(prob)

# 绘制结果
plot(sol, vars=(1, 2, 3), title="Lorenz Attractor")
```

这个库的速度有多夸张？我做过一个对比：同样的刚性 ODE 问题，Julia 比 MATLAB 快 10 倍，比 SciPy 快 100 倍。而且 API 极其简洁——定义方程、指定初值、调用 solve，三行代码搞定。

```julia
# 参数扫描——求解多组参数
using EnsembleAnalysis

prob_func(prob, i, repeat) = remake(prob, p=[10.0, 28.0, i])
ensemble_prob = EnsembleProblem(prob, prob_func=prob_func)
sim = solve(ensemble_prob, Tsit5(), EnsembleThreads(), trajectories=100)

# 分析 ensemble 结果
timeseries_steps_mean(sim)

# 事件处理——在特定条件下触发动作
function condition(u, t, integrator)
    u[1] - 10  # 当 u[1] == 10 时触发
end

function affect!(integrator)
    integrator.u[3] += 5  # 给 u[3] 加 5
end

cb = ContinuousCallback(condition, affect!)
sol = solve(prob, callback=cb)
```

## 性能优化：让代码飞起来的技巧

Julia 的默认性能已经很好了，但如果你想榨干最后一滴性能，还有一些技巧。

```julia
# 1. 避免全局变量
const GLOBAL_ARRAY = [1, 2, 3]  # const 让编译器知道类型不变

# 2. 使用 @inbounds 跳过边界检查
function sum_fast(arr)
    s = zero(eltype(arr))
    @inbounds for i in eachindex(arr)
        s += arr[i]
    end
    s
end

# 3. 使用 @simd 向量化循环
function sum_simd(arr)
    s = zero(eltype(arr))
    @simd for i in eachindex(arr)
        s += arr[i]
    end
    s
end

# 4. 预分配输出数组——避免重复分配
function process!(output, input)
    @inbounds for i in eachindex(input)
        output[i] = input[i]^2 + 1
    end
end

output = similar(input)
process!(output, input)
```

Julia 还有一个独特的性能分析工具叫 `@profile`，可以生成火焰图来定位热点。配合 `BenchmarkTools.jl` 的 `@benchmark` 宏，你可以精确到纳秒级别地比较不同实现的性能。

```julia
using BenchmarkTools

@benchmark sum_fast(rand(10000))
# BenchmarkTools.Trial:
#   memory estimate:  0 bytes
#   allocs estimate:  0
#   minimum time:     2.341 μs
#   median time:      2.410 μs

# 对比不同实现
@benchmark sum(rand(10000))           # base sum
@benchmark sum_fast(rand(10000))      # 我们的优化版本
@benchmark sum_simd(rand(10000))      # SIMD 版本
```

## 元编程：代码生成的艺术

Julia 的元编程能力虽然不如 Lisp 的宏系统强大，但在数值计算领域已经够用了。你可以用 quote 和 eval 来动态生成代码，也可以用宏来在编译期转换代码。

```julia
# 表达式对象
expr = :(x + y)
expr.head   # :call
expr.args   # [:(+), :x, :y]

# 宏定义
macro unless(condition, action)
    quote
        if !($condition)
            $action
        end
    end
end

# 使用宏
@unless x > 0 println("x is not positive")

# 代码生成——为不同数值类型生成特化版本
for T in [Float32, Float64]
    @eval function mysum(arr::Vector{$T})
        s = zero($T)
        @inbounds for x in arr
            s += x
        end
        s
    end
end
```

元编程在科学计算库的开发中非常常见。比如 `DifferentialEquations.jl` 就大量使用元编程来根据用户提供的方程自动生成最优的求解器代码。作为普通用户，你通常不需要自己写宏，但了解它的存在有助于理解 Julia 生态里那些"魔法"般的高性能库是怎么实现的。

## 总结

Julia 是我见过的最适合科学计算的语言。它把动态语言的开发效率、静态语言的运行性能和数学家的表达习惯完美地结合在了一起。

| 特性 | 优势 | 适用场景 |
|------|------|---------|
| 多重派发 | 灵活、可扩展的多态 | 算法库设计 |
| 类型系统 | 可选、渐进、高性能 | 数值计算核心 |
| 数组操作 | 简洁、高效、广播友好 | 矩阵运算、信号处理 |
| 并行计算 | 内置、统一 API | 大规模模拟 |
| Python/C 互操作 | 零成本复用生态 | 数据科学工作流 |
| 可视化 | 多后端、高颜值 | 论文图表、报告 |
| 微分方程 | 世界级性能 | 物理模拟、控制理论 |
| 元编程 | 编译期代码生成 | 库开发、DSL |

Julia 的弱点也很明显：编译时间慢（JIT 的代价）、包生态系统不如 Python 成熟、在生产环境部署的经验积累还不够。但如果你做的东西是计算密集型的科学研究或工程模拟，Julia 几乎是不二之选。

---

*本文首发于 Yggdrasil 博客*

    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '22 days',
    NOW() - INTERVAL '22 days',
    NOW() - INTERVAL '22 days'
),
(
    1,
    'R 语言：数据科学与统计分析',
    'r-data-science',
    'R 语言是统计分析和数据可视化的利器。本文深入讲解向量化运算、dplyr 数据处理、ggplot2 可视化、统计建模、Shiny 交互应用、tidyverse 生态以及与 Python 的对比选择。',
    $doc$
# R 语言：数据科学与统计分析

R 语言的出身很纯粹——它是为统计学家设计的。1993 年，Ross Ihaka 和 Robert Gentleman 在新西兰奥克兰大学开发了 R，初衷是给统计系的学生提供一个免费的替代 S-PLUS 的工具。三十年过去了，R 已经成为数据科学领域最重要的语言之一。

我在 2014 年第一次用 R，那时候 dplyr 和 ggplot2 刚刚兴起，tidyverse 的理念正在重塑整个社区。十年用下来，我对 R 的感情很复杂：它的语法有时候很诡异，包管理系统让人抓狂，但它在统计分析和可视化方面的能力，至今没有任何语言能全面超越。

很多人看不起 R，觉得它"只是统计学家用的玩具"。这种偏见通常来自没真正用过 R 的人。当你需要做一个复杂的混合效应模型、画一张 publication-ready 的图、或者搭建一个交互式分析平台的时候，R 的优势就体现得淋漓尽致。

## 向量化运算：R 的核心思维方式

如果你从 Python 或 C 转来 R，最大的冲击就是向量化思维。在 R 里，几乎 everything is a vector，标量只是长度为 1 的向量。

```r
# 向量——R 的基本数据类型
x <- c(1, 2, 3, 4, 5)
y <- c(10, 20, 30, 40, 50)

# 向量化运算——不需要写循环
x + y          # [1] 11 22 33 44 55
x * 2          # [1]  2  4  6  8 10
x > 3          # [1] FALSE FALSE FALSE  TRUE  TRUE

# 内置函数都是向量化的
sqrt(x)        # [1] 1.000 1.414 1.732 2.000 2.236
log(x)         # [1] 0.000 0.693 1.099 1.386 1.609
```

R 的向量化运算背后是用 C 和 Fortran 实现的高效循环。你写的 `x + y` 实际上调用的是编译后的底层代码，速度比手写的 R 循环快几十倍。我在一个项目里把同事写的三层嵌套 `for` 循环改成了向量化操作，运行时间从 3 小时降到了 2 分钟。

```r
# 序列生成
1:10                    # 1 到 10
seq(0, 1, by = 0.1)     # 0.0, 0.1, 0.2, ..., 1.0
rep(1:3, each = 2)      # 1 1 2 2 3 3

# 逻辑索引——这是 R 最美妙的特性之一
x <- c(10, 20, 30, 40, 50)
x[x > 25]               # [1] 30 40 50

# 缺失值处理
z <- c(1, 2, NA, 4, 5)
is.na(z)                # [1] FALSE FALSE  TRUE FALSE FALSE
mean(z, na.rm = TRUE)   # 3

# 因子（Factor）——分类变量的利器
gender <- factor(c("M", "F", "F", "M", "F"), levels = c("M", "F"))
table(gender)           # M F
                        # 2 3
```

## dplyr：数据处理的艺术

dplyr 是 tidyverse 的核心包，它提供了一套动词化的数据操作语法。R 社区有句话："dplyr 让数据清洗变成了一种享受。"我用了之后觉得这话不算夸张。

```r
library(dplyr)

# 创建示例数据
df <- data.frame(
  name = c("Alice", "Bob", "Charlie", "Alice", "Bob"),
  department = c("Sales", "IT", "Sales", "IT", "Sales"),
  salary = c(50000, 60000, 55000, 65000, 52000),
  years = c(2, 5, 3, 4, 2)
)

# select——选择列
df %>% select(name, salary)

# filter——过滤行
df %>% filter(salary > 55000)

# mutate——创建新列
df %>% mutate(bonus = salary * 0.1)

# arrange——排序
df %>% arrange(desc(salary))

# summarise——汇总
df %>% summarise(
  avg_salary = mean(salary),
  total = n()
)

# group_by——分组操作
df %>%
  group_by(department) %>%
  summarise(
    avg_salary = mean(salary),
    headcount = n()
  )
```

管道操作符 `%>%`（或者 R 4.1+ 的原生管道 `|>`）让数据流变得极其可读。你可以从左到右阅读代码：先选这个，再过滤那个，然后创建新列，最后分组汇总。这种线性思维跟数据处理的自然流程完全吻合。

```r
# 复杂的数据处理管道
library(dplyr)
library(lubridate)

sales_data %>%
  filter(year(date) == 2024) %>%
  mutate(month = month(date, label = TRUE)) %>%
  group_by(region, month) %>%
  summarise(
    total_revenue = sum(revenue, na.rm = TRUE),
    avg_order_value = mean(order_value, na.rm = TRUE),
    n_orders = n()
  ) %>%
  filter(total_revenue > 100000) %>%
  arrange(region, desc(total_revenue))
```

dplyr 的另一个杀手锏是它能处理比内存大的数据。通过 `dbplyr`，你可以把 dplyr 操作翻译成 SQL，直接在数据库里执行。对大数据团队来说，这意味着分析师可以用熟悉的 R 语法操作 TB 级别的数据，不需要写一行 SQL。

```r
# 连接数据库，像操作本地数据框一样操作数据库表
library(DBI)
library(dbplyr)

con <- dbConnect(RPostgres::Postgres(), dbname = "sales")
orders <- tbl(con, "orders")

# 这段代码不会把数据拉到内存，而是生成 SQL 在数据库执行
orders %>%
  filter(amount > 100) %>%
  group_by(customer_id) %>%
  summarise(total = sum(amount)) %>%
  arrange(desc(total)) %>%
  head(10)
```

## ggplot2：图层的哲学

ggplot2 的设计哲学来自 Leland Wilkinson 的《The Grammar of Graphics》。核心思想是：任何统计图形都是由数据（data）、映射（mapping）、几何对象（geom）和标度（scale）组合而成的。

```r
library(ggplot2)

# 基础散点图
ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point(aes(color = factor(cyl)), size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "汽车重量与油耗关系",
    x = "重量 (1000 lbs)",
    y = "每加仑英里数",
    color = "气缸数"
  ) +
  theme_minimal()
```

ggplot2 的分层设计让复杂图表的构建变得模块化。你可以先画散点，再叠加回归线，再改颜色标度，再调整主题——每一步都是独立的图层，互不影响。我在论文里做过的最复杂的图有十几层：散点、拟合线、置信区间、注释、分面、自定义颜色映射……全部用 ggplot2 堆叠出来，代码依然清晰可读。

```r
# 分面图——按类别自动分格子
ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_wrap(~ cyl, labeller = label_both) +
  theme_bw()

# 热力图
ggplot(mtcars, aes(x = factor(cyl), y = factor(gear))) +
  geom_tile(aes(fill = mpg), color = "white") +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(x = "气缸数", y = "档位", fill = "MPG")

# 箱线图 + 抖动散点
ggplot(mtcars, aes(x = factor(cyl), y = mpg)) +
  geom_boxplot(alpha = 0.5) +
  geom_jitter(width = 0.2, alpha = 0.6, aes(color = factor(am)))

# 保存高分辨率图片
ggsave("output.png", width = 10, height = 6, dpi = 300)
```

ggplot2 的扩展生态也是它强大的原因。`ggrepel` 自动解决标签重叠，`ggridges` 画山脊图，`gganimate` 做动画，`plotly` 转交互式。几乎任何你能想到的统计可视化，ggplot2 生态里都有现成的解决方案。

## 统计建模：从 lm 到 glm

R 是统计学的原生语言，它的建模能力是很多数据科学家选择 R 的首要原因。

```r
# 线性回归
model <- lm(mpg ~ wt + hp + factor(cyl), data = mtcars)
summary(model)

# 输出包含：
# - 系数估计和显著性检验
# - R² 和调整 R²
# - F 统计量和 p 值
# - 残差诊断信息

# 逻辑回归
data(mtcars)
mtcars$am_factor <- factor(mtcars$am, labels = c("Auto", "Manual"))
logit_model <- glm(am_factor ~ wt + mpg, data = mtcars, family = binomial)
summary(logit_model)

# 预测
new_data <- data.frame(wt = c(2.5, 3.5), mpg = c(25, 18))
predict(logit_model, newdata = new_data, type = "response")
```

R 的统计建模生态极其丰富：`lme4` 做混合效应模型，`survival` 做生存分析，`forecast` 做时间序列预测，`caret` 和 `tidymodels` 做机器学习。这些包背后往往是领域内的顶尖研究者维护，算法实现的质量和文档的详尽程度都是一流的。

```r
# 时间序列分析
library(forecast)

# ARIMA 模型
fit <- auto.arima(AirPassengers)
forecast_values <- forecast(fit, h = 24)  # 预测未来 24 个月
plot(forecast_values)

# 模型诊断
checkresiduals(fit)

# 混合效应模型
library(lme4)
model <- lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy)
summary(model)
```

我在金融风控项目里用过 R 的 `randomForest` 和 `xgboost` 包。跟 Python 的 scikit-learn 相比，R 的接口更贴近统计学传统——比如模型输出默认包含置信区间、显著性检验和诊断信息，而不是只给你一个准确率数字。对于需要解释性的业务场景，这是巨大的优势。

## Shiny：让数据动起来

Shiny 是 R 社区最激动人心的创新之一。它让你可以用纯 R 代码构建交互式 Web 应用，不需要懂 HTML、CSS 或 JavaScript。

```r
library(shiny)

# UI 定义
ui <- fluidPage(
  titlePanel("数据探索应用"),
  sidebarLayout(
    sidebarPanel(
      selectInput("xvar", "X 轴变量:", choices = names(mtcars)),
      selectInput("yvar", "Y 轴变量:", choices = names(mtcars)),
      sliderInput("alpha", "透明度:", min = 0, max = 1, value = 0.7)
    ),
    mainPanel(
      plotOutput("scatterPlot"),
      verbatimTextOutput("summaryStats")
    )
  )
)

# Server 逻辑
server <- function(input, output) {
  output$scatterPlot <- renderPlot({
    ggplot(mtcars, aes_string(x = input$xvar, y = input$yvar)) +
      geom_point(alpha = input$alpha, size = 3, color = "steelblue") +
      theme_minimal()
  })

  output$summaryStats <- renderPrint({
    summary(mtcars[, c(input$xvar, input$yvar)])
  })
}

# 运行应用
shinyApp(ui = ui, server = server)
```

Shiny 的革命性在于它把 Web 开发的门槛降到了零。一个懂数据分析但不了解前端的分析师，花一下午就能做出一个可以分享给老板的交互式 Dashboard。我在前公司用 Shiny 做过一个实时销售监控系统，对接了数据库和缓存层，五十多个业务部门每天用来看数据。整个项目就我一个人维护，代码量不到 2000 行。

```r
# 响应式编程——Shiny 的核心
library(shiny)

server <- function(input, output) {
  # reactive——缓存计算结果，只在输入变化时重新执行
  filtered_data <- reactive({
    mtcars %>%
      filter(mpg >= input$mpg_range[1],
             mpg <= input$mpg_range[2])
  })

  # reactive 表达式可以被多个输出复用
  output$plot <- renderPlot({
    ggplot(filtered_data(), aes(x = wt, y = hp)) +
      geom_point()
  })

  output$table <- renderDataTable({
    filtered_data()
  })
}

# 模块化的 Shiny 应用
# 把复杂应用拆分成可复用的模块
counterUI <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(ns("increment"), "Increment"),
    verbatimTextOutput(ns("count"))
  )
}

counterServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    count <- reactiveVal(0)
    observeEvent(input$increment, {
      count(count() + 1)
    })
    output$count <- renderText({ count() })
  })
}
```

## tidyverse：一个完整的生态系统

tidyverse 不是单个包，而是一系列遵循共同设计理念的 R 包的集合。Hadley Wickham 和他的团队用十年时间打造了这个生态，彻底改变了 R 的编程范式。

```r
library(tidyverse)

# tidyverse 包含的核心包：
# ggplot2——可视化
diamonds %>%
  ggplot(aes(x = carat, y = price, color = cut)) +
  geom_point(alpha = 0.3) +
  facet_wrap(~ clarity)

# dplyr——数据处理
starwars %>%
  filter(species == "Human") %>%
  select(name, height, mass, homeworld) %>%
  mutate(bmi = mass / (height/100)^2) %>%
  arrange(desc(bmi))

# tidyr——数据整形
# 宽格式转长格式（pivot_longer）
pivot_longer(
  data = table4a,
  cols = c(`1999`, `2000`),
  names_to = "year",
  values_to = "cases"
)

# readr——读取数据
# read_csv 比 base R 的 read.csv 快 10 倍，自动推断类型
read_csv("data/large_file.csv")

# purrr——函数式编程
# 替代 lapply/sapply，API 更一致
map(1:3, ~ .x^2)           # 列表
map_dbl(1:3, ~ .x^2)       # 数值向量
map_chr(c("a", "b"), toupper)

# stringr——字符串处理
str_detect(c("apple", "banana"), "a")   # [1] TRUE TRUE
str_replace("hello world", "world", "R")  # "hello R"

# forcats——因子处理
fct_relevel(factor(c("b", "a", "c")), "c", "a", "b")
```

tidyverse 的设计哲学可以概括为三个原则：

1. **复用数据结构**：tidyverse 函数接受和返回的都是数据框（data frame/tibble），不需要在十几种数据结构之间转换。
2. **管道化操作**：通过管道把多个简单操作串联成复杂的数据流。
3. **函数设计的一致性**：所有函数都遵循相同的命名约定和参数设计模式。

我在培训新人的时候，tidyverse 的学习曲线明显比 base R 平缓。一周时间，一个完全没有编程背景的分析师就能用 dplyr 做基本的数据清洗，用 ggplot2 画出像样的图。

```r
# readr 的自动类型推断
library(readr)

# 自动识别列类型
spec_csv("data/customers.csv")
# cols(
#   id = col_double(),
#   name = col_character(),
#   signup_date = col_date(format = ""),
#   revenue = col_number()
# )

# purrr 处理嵌套数据
library(purrr)

models <- mtcars %>%
  group_by(cyl) %>%
  nest() %>%
  mutate(model = map(data, ~ lm(mpg ~ wt, data = .x)),
         r_squared = map_dbl(model, ~ summary(.x)$r.squared))
```

## R Markdown：可重复研究

R Markdown 是 R 社区另一个杀手级工具。它让你可以把代码、输出和文字叙述整合在一个文档里，生成 PDF、HTML、Word 甚至幻灯片。

```markdown
---
title: "数据分析报告"
output: html_document
---

## 数据概览

```{r}
library(ggplot2)
summary(mtcars)
```

## 可视化

```{r}
ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  geom_smooth(method = "lm")
```
```

R Markdown 的核心价值在于**可重复性**。你写报告时引用的每一个数字、每一张图，都直接来自代码。数据更新了？重新 knit 一下，整篇报告自动更新。这在学术界和业界都是革命性的——再也不用怕"这个图表是怎么算出来的"这种尴尬问题了。

```r
# 参数化报告
---
title: "区域销售报告"
params:
  region: "North"
  year: 2024
---

# 使用参数
sales_data %>%
  filter(region == params$region, year == params$year) %>%
  summarise(total = sum(revenue))

# 批量生成多个报告
library(rmarkdown)
regions <- c("North", "South", "East", "West")
for (region in regions) {
  render("report.Rmd", params = list(region = region))
}
```

## R vs Python：该怎么选

这个问题在数据科学社区争论了十多年。我的经验是：没有绝对的好坏，只有适合的场景。

| 维度 | R | Python |
|------|---|--------|
| 统计分析 | 原生支持，生态最丰富 | 需要 scipy/statsmodels，不如 R 深入 |
| 可视化 | ggplot2 无与伦比 | matplotlib/seaborn 够用但不够优雅 |
| 机器学习 | caret/tidymodels 不错 | scikit-learn 是行业标准 |
| 深度学习 | 几乎不存在 | PyTorch/TensorFlow/JAX |
| 工程部署 | Shiny 够用，但不如 Flask/Django 成熟 | Web 框架成熟，部署经验丰富 |
| 社区规模 | 统计/生物信息学领域强 | 更通用，覆盖面更广 |

我的建议是：如果你的工作以探索性数据分析、统计建模和可视化为主，选 R；如果你需要构建生产级的机器学习系统、做深度学习或者跟工程团队深度协作，选 Python。

当然，很多团队是双持的。我在一个项目里用 Python 做数据管道和模型训练，用 R 做探索性分析和可视化报告，两边通过 Parquet 文件交换数据。这种混合工作流在大公司里越来越常见。

## 总结

R 语言是一面镜子——它反映了统计学和数据科学社区的需求和价值观。它的语法不完美，性能不算顶尖，但在统计分析和可视化这两个核心领域，它依然是王者。

| 特性 | R 的做法 | 为什么好用 |
|------|---------|-----------|
| 向量化 | 原生支持，everything is vector | 代码简洁，底层高效 |
| dplyr | 动词化管道操作 | 符合数据处理的自然思维 |
| ggplot2 | 图层化的图形语法 | 模块化构建复杂图表 |
| 统计建模 | 函数简洁，输出详尽 | 统计学家的工具箱 |
| Shiny | 纯 R 写 Web 应用 | 降低交互式开发门槛 |
| tidyverse | 统一的设计哲学 | 学习曲线平缓，代码可维护 |
| R Markdown | 代码+输出+文字一体化 | 可重复研究 |

如果你做数据分析，R 是值得投入时间精力的。即使你的主语言是 Python，了解 R 的 tidyverse 思维方式也会让你写 Python 时更注意代码的清晰度和可组合性。毕竟，好的数据科学不仅在于你用了什么工具，更在于你如何思考问题。

---

*本文首发于 Yggdrasil 博客*

    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '23 days',
    NOW() - INTERVAL '23 days',
    NOW() - INTERVAL '23 days'
),
(
    1,
    'Lua：轻量级嵌入式脚本语言',
    'lua-embedded-scripting',
    'Lua 是一门小巧但强大的嵌入式脚本语言，以其独特的表结构、元表机制和协程模型闻名。本文深入探讨 Lua 的核心设计哲学及其在游戏开发、配置文件和嵌入式系统中的应用。',
    $doc$
# Lua：轻量级嵌入式脚本语言

Lua 诞生于 1993 年的巴西里约热内卢天主教大学。Roberto Ierusalimschy 和他的团队设计这门语言的初衷很简单：让非程序员也能为应用程序编写扩展逻辑。30 多年过去了，Lua 的这份初心从未改变——它依然是那个体积不到 200KB、却能撑起魔兽世界、Nginx 和 Redis 的小家伙。

我第一次认真用 Lua 是给一个 C++ 游戏引擎写脚本系统。当时的感受是：怎么有一种语言，看起来跟玩具一样简单，真用起来却处处藏着巧思？表（table）既是数组又是字典还能当对象用，协程（coroutine）让异步代码写起来像同步一样自然，元表（metatable）则像是给这门语言装了一个插件系统。这些设计单独看都不复杂，组合在一起却产生了惊人的表达力。

Lua 的语法极简。没有 `class` 关键字，没有 `switch` 语句，没有 `continue`，连 `+=` 这样的复合赋值运算符都没有。但正是这份克制，让 Lua 保持了极小的体积和极快的启动速度。一个完整的 Lua 解释器静态链接后不到 200KB，这意味着你可以把它塞进路由器、打印机、甚至智能手表里。

本文将从 Lua 的核心数据结构出发，逐步深入到元表、协程、LuaJIT 性能优化、C 嵌入接口、Love2D 游戏开发和模块系统。读完之后，你会理解为什么这么多大型项目选择 Lua 作为它们的脚本层。

## 表（Table）：万物归一的数据结构

Lua 最让初学者困惑也最让老手着迷的设计，就是**表（table）**作为唯一的复合数据结构。数组？是表。字典？是表。对象？还是表。模块？依然是表。在 Lua 的世界里，table 就是一切。

```lua
-- 表既可以当数组用
local colors = {"red", "green", "blue"}
print(colors[1])  -- "red"（注意，Lua 数组从 1 开始！）
print(colors[2])  -- "green"
print(#colors)    -- 3，长度运算符

-- 也可以当字典（哈希表）用
local user = {
    name = "Alice",
    age = 30,
    active = true
}
print(user["name"])  -- "Alice"
print(user.name)     -- 等价写法，更常见
print(user.email)    -- nil，不存在的键返回 nil

-- 甚至可以混着用
local mixed = {"a", "b", key = "value", [42] = "forty-two"}
for k, v in pairs(mixed) do
    print(k, v)
end
```

数组从 1 开始这个设定，曾让我踩过不少坑。写 `colors[0]` 返回 `nil` 的时候，我愣了三秒钟。后来习惯了，反而觉得这样跟数学上的索引更一致。Python 和 C 的 0-based 索引是为了指针偏移方便，Lua 既然没有指针运算，从 1 开始也没什么不对。当然，这个设计在社区里争议很大，每次有人提起都会引发一场"圣战"。

表的内部实现很有意思。Lua 用了一种混合结构：当键是连续的整数时，底层用数组存储；出现非连续键或字符串键时，自动切换到哈希表。这种"自适应"设计让 Lua 表在不同使用场景下都能保持较好的性能。遍历数组用 `ipairs`，遍历字典用 `pairs`，这是 Lua 编程的基本功。

```lua
-- ipairs 只遍历数组部分（从 1 开始的连续整数键）
for index, value in ipairs(colors) do
    print(index, value)  -- 1 red, 2 green, 3 blue
end

-- pairs 遍历所有键值对
for key, value in pairs(user) do
    print(key, value)  -- name Alice, age 30, active true
end

-- 表作为对象：在表中放函数
local Counter = {
    count = 0,
    increment = function(self)
        self.count = self.count + 1
    end,
    getCount = function(self)
        return self.count
    end
}

Counter:increment()  -- 语法糖，等价于 Counter.increment(Counter)
Counter:increment()
print(Counter:getCount())  -- 2
```

冒号调用（`:`）是 Lua 的一个语法糖，会自动把调用者本身作为第一个参数传入。这个设计看似小巧，却是 Lua 面向对象编程的基石。没有 `class` 关键字？没关系，用表 + 元表就能模拟出完整的面向对象系统。

表的另一个妙用是作为命名空间或模块：

```lua
-- 用表组织代码
local MathUtils = {}

function MathUtils.add(a, b)
    return a + b
end

function MathUtils.factorial(n)
    if n <= 1 then return 1 end
    return n * MathUtils.factorial(n - 1)
end

print(MathUtils.factorial(5))  -- 120
```

## 元表与元方法：打开 Lua 的魔法盒

如果表是 Lua 的躯体，**元表（metatable）**就是它的灵魂。元表允许你自定义表在面对各种操作时的行为——加法、索引访问、函数调用，甚至是打印输出。这是 Lua 扩展性的核心机制。

```lua
local t1 = {10, 20, 30}
local t2 = {40, 50, 60}

-- 直接相加会报错：attempt to add two table values
-- local sum = t1 + t2  -- ERROR!

-- 通过元表定义加法行为
local mt = {
    __add = function(a, b)
        local result = {}
        for i = 1, math.max(#a, #b) do
            result[i] = (a[i] or 0) + (b[i] or 0)
        end
        return result
    end,
    __tostring = function(t)
        return "{" .. table.concat(t, ", ") .. "}"
    end
}

setmetatable(t1, mt)
setmetatable(t2, mt)

local sum = t1 + t2
print(sum)  -- {50, 70, 90}
```

我第一次看到 `__index` 的时候，突然理解了 JavaScript 原型链的本质。Lua 的 `__index` 元方法在访问不存在的键时触发，这不就是原型继承的核心机制吗？JavaScript 的 `__proto__` 和 Lua 的 `__index` 在概念上是相通的，只不过 Lua 的设计更简洁、更可控。

```lua
-- 用 __index 实现原型继承
local Animal = {
    name = "unknown",
    speak = function(self)
        print(self.name .. " makes some sound")
    end
}

local Dog = {
    breed = "mixed"
}

-- Dog 找不到的方法，去 Animal 里找
setmetatable(Dog, {__index = Animal})

local dog = {}
setmetatable(dog, {__index = Dog})

dog.name = "Buddy"
dog:speak()  -- "Buddy makes some sound"
print(dog.breed)  -- "mixed"（从 Dog 原型继承）
```

元方法一览：

| 元方法 | 触发时机 | 典型用途 |
|--------|---------|---------|
| `__index` | 访问不存在的键 | 原型继承、默认值、惰性加载 |
| `__newindex` | 给不存在的键赋值 | 拦截写入、只读保护、数据校验 |
| `__add` | `+` 运算符 | 向量加法、自定义数值类型 |
| `__sub` | `-` 运算符 | 向量减法 |
| `__mul` | `*` 运算符 | 向量点积、标量乘法 |
| `__div` | `/` 运算符 | 向量除法 |
| `__eq` | `==` 运算符 | 自定义相等逻辑 |
| `__lt` | `<` 运算符 | 自定义比较逻辑 |
| `__le` | `<=` 运算符 | 自定义比较逻辑 |
| `__call` | 把表当函数调用 | 构造函数、函数对象、柯里化 |
| `__tostring` | `tostring()` 或 `print()` | 格式化输出 |
| `__gc` | 表被垃圾回收时 | 资源清理（userdata 的 __gc 在 5.1+，table 的 __gc 在 5.2+） |
| `__len` | `#` 运算符 | 自定义长度计算 |
| `__pairs` | `pairs()` | 自定义遍历行为（Lua 5.2+） |

`__newindex` 在写防御式代码时特别有用。我见过有人用它实现只读表：

```lua
function make_readonly(t)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function(_, k, v)
            error("attempt to modify read-only table", 2)
        end,
        __pairs = function()
            return pairs(t)
        end,
        __len = function()
            return #t
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

local config = make_readonly({debug = false, port = 8080, host = "localhost"})
print(config.port)      -- 8080
-- config.port = 9090   -- ERROR: attempt to modify read-only table
```

元表的强大之处在于它是**运行时**的。你可以在程序运行的任何时候修改一个表的元表，改变它的行为。这种动态性让 Lua 特别适合写 DSL（领域特定语言）和配置系统。

## 协程：轻量级的协作式多任务

Lua 的 **coroutine**（协程）是我最喜欢它的原因之一。与操作系统的线程不同，协程是协作式的——它们自己决定何时让出控制权，而不是被抢占。这意味着没有锁、没有竞态条件、没有上下文切换的开销。

```lua
local co = coroutine.create(function(a, b)
    print("协程开始，接收参数:", a, b)
    
    -- yield 挂起协程，返回一个值给调用者
    local c = coroutine.yield(a + b)
    
    print("协程恢复，接收新参数:", c)
    return a + b + c
end)

-- 启动协程
local ok, result = coroutine.resume(co, 10, 20)
print("第一次 resume 返回:", result)  -- 30

-- 再次恢复，传入新参数
ok, result = coroutine.resume(co, 5)
print("第二次 resume 返回:", result)  -- 35

print("协程状态:", coroutine.status(co))  -- "dead"
```

协程的状态机在脑袋里转一圈就明白了：`suspended`（挂起）、`running`（运行中）、`normal`（被内部协程 yield）、`dead`（结束）。比线程的状态机干净多了。

协程最适合的场景是迭代器和生成器：

```lua
-- 用协程实现一个可以 "暂停" 的斐波那契生成器
function fibonacci()
    return coroutine.wrap(function()
        local a, b = 0, 1
        while true do
            coroutine.yield(a)
            a, b = b, a + b
        end
    end)
end

local fib = fibonacci()
for i = 1, 10 do
    print(fib())  -- 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
end
```

`coroutine.wrap()` 返回一个函数，调用这个函数就相当于 `resume` + `yield` 的语法糖。写起来比原始的 `create`/`resume`/`yield` trio 清爽不少。

协程跟线程的根本区别在于：线程切换由操作系统调度器决定，你控制不了；协程切换由代码中的 `yield` 决定，完全在你的掌控之中。这意味着协程没有锁、没有竞态条件、没有上下文切换的开销。在 Lua 中创建一万个协程，内存占用不到几 MB。

协程还可以用来实现异步编程：

```lua
-- 用协程实现简单的 async/await 风格
function async(f)
    local co = coroutine.create(f)
    local function step(...)
        local ok, result = coroutine.resume(co, ...)
        if not ok then
            error(result)
        end
        if coroutine.status(co) == "dead" then
            return result
        end
        -- result 应该是一个回调函数，接受 continue 函数
        result(function(...)
            step(...)
        end)
    end
    step()
end

-- 模拟异步操作
function delay(ms, callback)
    -- 实际实现会用事件循环或定时器
    print("Waiting " .. ms .. "ms...")
    callback("done")
end

async(function()
    local result = coroutine.yield(function(continue)
        delay(1000, continue)
    end)
    print("First delay:", result)
    
    result = coroutine.yield(function(continue)
        delay(500, continue)
    end)
    print("Second delay:", result)
end)
```

## LuaJIT：让 Lua 飞起来

如果说标准 Lua（PUC-Rio Lua）是一个稳重的 interpreter，那 **LuaJIT** 就是一匹脱缰的野马。Mike Pall 写的这个 JIT 编译器，能把 Lua 代码编译成机器码，性能提升 10 到 100 倍不是夸张。

```lua
-- 这段代码在 LuaJIT 中会飞起来
local sum = 0
for i = 1, 1e8 do
    sum = sum + i
end
print(sum)
```

LuaJIT 的秘密武器是 **trace compiler**。它不会编译整个函数，而是追踪热点代码路径（trace），把频繁执行的循环编译成机器码。这种方式既保留了 interpreter 的快速启动，又获得了 JIT 的运行时性能。当 interpreter 发现某个循环被执行了足够多次，LuaJIT 就会开始追踪这个路径，记录执行的指令流，然后把它编译成高度优化的机器码。后续执行直接走机器码，跳过 interpreter 的解释开销。

LuaJIT 还引入了一个杀手级特性：**FFI（Foreign Function Interface）**。不用写 C 扩展，直接就能调用 C 函数：

```lua
local ffi = require("ffi")

-- 直接声明 C 函数原型
ffi.cdef[[
    int printf(const char *fmt, ...);
    double sin(double x);
    double cos(double x);
    void *malloc(size_t size);
    void free(void *ptr);
]]

-- 调用 C 标准库函数
ffi.C.printf("Hello from %s!
", "LuaJIT")
print(ffi.C.sin(3.14159 / 2))  -- 约等于 1.0
print(ffi.C.cos(0))             -- 约等于 1.0

-- 直接操作内存
local buf = ffi.C.malloc(1024)
ffi.fill(buf, 1024, 0)
ffi.C.free(buf)
```

FFI 调用几乎没有 overhead，比标准 Lua 的 C API 快得多。我在一个数据处理项目里用 FFI 调用了 zlib，解压速度比纯 Lua 实现快了大概 50 倍。FFI 还能直接操作 C 数据结构：

```lua
ffi.cdef[[
    typedef struct {
        float x, y, z;
    } Vec3;
]]

local v = ffi.new("Vec3", {1.0, 2.0, 3.0})
print(v.x, v.y, v.z)  -- 1.0  2.0  3.0
v.x = 10.0
```

不过 LuaJIT 也有痛点。它只支持 Lua 5.1 语法，对 5.3/5.4 的新特性（整数类型、位运算、UTF-8 库）支持有限。而且 Mike Pall 在 2015 年之后基本停止了 LuaJIT 的活跃开发，社区维护的版本（OpenResty 的 LuaJIT）成了事实上的主流。OpenResty 维护的 LuaJIT 2.1 分支添加了很多新特性，比如 GC64 模式、调试支持改进等。

## 与 C/C++ 的嵌入艺术

Lua 最初就是为嵌入而生的。把它塞进 C/C++ 程序里，只需要包含一个头文件、链接一个库。

```c
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main() {
    lua_State *L = luaL_newstate();  // 创建 Lua 虚拟机
    luaL_openlibs(L);                 // 打开标准库
    
    // 加载并执行 Lua 代码
    if (luaL_dostring(L, "print('Hello from Lua!')") != LUA_OK) {
        fprintf(stderr, "Error: %s
", lua_tostring(L, -1));
    }
    
    // 调用 Lua 函数
    lua_getglobal(L, "math");
    lua_getfield(L, -1, "sqrt");
    lua_pushnumber(L, 16.0);
    lua_call(L, 1, 1);  // 1 个参数，1 个返回值
    printf("sqrt(16) = %f
", lua_tonumber(L, -1));
    lua_pop(L, 2);  // 清理栈
    
    lua_close(L);
    return 0;
}
```

Lua 的 C API 基于**虚拟栈**。所有数据交换都通过这个栈进行，Lua 负责管理栈的内存。这个设计有一个巨大的好处：C 代码不需要操心 Lua 的垃圾回收，Lua 也不会去碰 C 的指针。双方通过栈这个"中立地带"打交道。

把 C 函数暴露给 Lua 同样简单：

```c
// C 函数，接收 Lua 栈上的参数
static int l_add(lua_State *L) {
    double a = luaL_checknumber(L, 1);  // 检查并获取第1个参数
    double b = luaL_checknumber(L, 2);  // 检查并获取第2个参数
    lua_pushnumber(L, a + b);            // 把结果压入栈
    return 1;  // 返回1个值
}

// 注册到 Lua
lua_pushcfunction(L, l_add);
lua_setglobal(L, "add");

// 现在在 Lua 里可以这样用：
// local result = add(10, 20)
```

说实话，Lua 的 C API 是我用过最省心的脚本绑定方案。Python 的 C API 复杂得像天文数字，V8 的嵌入接口更是让人望而生畏。Lua 的栈模型虽然有点繁琐，但学习曲线平缓，出错率低，调试也容易。

更高级的做法是把 C 函数组织成模块：

```c
static const struct luaL_Reg mylib[] = {
    {"add", l_add},
    {"sub", l_sub},
    {"mul", l_mul},
    {NULL, NULL}  // 结束标记
};

int luaopen_mylib(lua_State *L) {
    luaL_newlib(L, mylib);
    return 1;
}
```

然后 Lua 里用 `local mylib = require("mylib")` 就能加载这个模块。

## 游戏开发：Love2D 与更多

Lua 在游戏开发领域的地位不可撼动。从魔兽世界的插件系统，到 Angry Birds 的物理引擎配置，再到 Roblox 的脚本语言，Lua 无处不在。

**Love2D** 是一个用 Lua 编写的 2D 游戏框架，轻量、易学、功能齐全。它封装了 SDL2、OpenGL 和 OpenAL，提供了跨平台的窗口、图形、音频和输入处理。

```lua
-- Love2D 的 "Hello World"
function love.load()
    -- 加载资源
    player = {
        x = 100, y = 100,
        speed = 200,
        image = love.graphics.newImage("player.png")
    }
    
    -- 加载字体
    font = love.graphics.newFont(24)
    love.graphics.setFont(font)
end

function love.update(dt)
    -- 每帧更新，dt 是上一帧的时间（秒）
    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("up") then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("down") then
        player.y = player.y + player.speed * dt
    end
end

function love.draw()
    -- 渲染
    love.graphics.draw(player.image, player.x, player.y)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    love.graphics.print("Use arrow keys to move", 10, 40)
end
```

Love2D 的 API 设计遵循了一个原则：约定大于配置。`love.load`、`love.update`、`love.draw` 这些回调函数名是固定的，框架自动调用。你不需要注册事件监听器、不需要写消息循环，只需要填好这些函数就行。这种设计让原型开发极快。我曾在 48 小时的 Game Jam 里用 Love2D 做了一个完整的平台跳跃游戏，从空白到可玩只用了 6 个小时。

除了 Love2D，Lua 在游戏领域的应用还包括：
- **魔兽世界**：插件系统完全基于 Lua
- **Nginx/OpenResty**：用 Lua 编写高性能 Web 应用
- **Redis**：支持 Lua 脚本做原子操作
- **Adobe Lightroom**：插件脚本语言
- **Civilization V**：游戏逻辑和 MOD 系统

## 模块系统：简单而有效

Lua 的模块系统简单到几乎不存在，但用顺手了会发现它够用而且不添乱。

```lua
-- mymodule.lua
local M = {}

local function internal_helper()  -- 局部函数，不导出
    return "helper"
end

function M.greet(name)
    return "Hello, " .. name .. "!"
end

function M.add(a, b)
    return a + b
end

function M.factorial(n)
    if n <= 1 then return 1 end
    return n * M.factorial(n - 1)
end

return M
```

```lua
-- main.lua
local mymodule = require("mymodule")

print(mymodule.greet("Lua"))  -- "Hello, Lua!"
print(mymodule.add(1, 2))     -- 3
print(mymodule.factorial(5))  -- 120
```

`require` 函数加载模块时会做缓存，同一个模块只加载一次。模块本质上就是一个返回表的 Lua 文件。没有复杂的命名空间、没有包管理器的强制要求，就是一个表，干净利索。这种设计让模块之间的依赖关系非常透明：你看一个模块返回什么表，就知道它提供了什么接口。

LuaRocks 是 Lua 的社区包管理器，虽然生态不如 npm 或 PyPI 庞大，但常用的库（HTTP 客户端、JSON 解析、数据库驱动）都能找到。安装一个包很简单：

```bash
luarocks install lua-cjson
```

然后在 Lua 里：

```lua
local cjson = require("cjson")
local data = {name = "Alice", age = 30}
local json_str = cjson.encode(data)
print(json_str)  -- {"name":"Alice","age":30}
```

## 总结

Lua 是一门让人又爱又恨的语言。爱的是它的简洁、小巧、嵌入方便；恨的是它某些反直觉的设计（数组从 1 开始、全局变量默认不加修饰词）。但瑕不掩瑜，Lua 在嵌入式脚本领域有着无可替代的地位。

| 特性 | 说明 | 适用场景 |
|------|------|---------|
| 表 | 唯一数据结构，数组+字典+对象 | 数据组织、配置、对象系统 |
| 元表 | 运算符重载、原型继承 | DSL、面向对象、自定义行为 |
| 协程 | 协作式多任务 | 迭代器、状态机、异步编程 |
| LuaJIT | JIT 编译器+FFI | 高性能计算、游戏、数据处理 |
| C 嵌入 | 栈式 API，双向调用 | 脚本系统、配置引擎、游戏逻辑 |
| 模块 | 简单的表导出 | 代码组织、库开发 |

如果你需要一个能塞进 200KB 空间的脚本引擎，Lua 是首选。如果你需要在 C/C++ 项目里加一个可扩展的配置层，Lua 依然是首选。如果你要写一个 2D 独立游戏，Love2D + Lua 的组合会让你事半功倍。

Lua 的哲学很简单：**用最小的核心提供最大的灵活性**。它不给你太多语法糖，但给你的表和元表机制，足以模拟出几乎任何编程范式。这种"少即是多"的设计，在 30 年后依然散发着独特的魅力。

> "Lua 不是最好的语言，但它是最适合嵌入的语言。" —— 这是我用 Lua 多年后的真实感受。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '24 days',
    NOW() - INTERVAL '24 days',
    NOW() - INTERVAL '24 days'
),
(
    1,
    'Bash 脚本编程完全指南',
    'bash-scripting-guide',
    'Shell 脚本写多了，你会发现自己在一堆引号和转义符号里迷失。本文从变量、引号、条件测试到进程替换、trap 信号处理，系统梳理 Bash 脚本的方方面面。',
    $doc$
# Bash 脚本编程完全指南

写 Bash 脚本是一件让人既爱又恨的事情。爱的是它随手就能写，打开终端三行代码解决一个问题；恨的是一旦脚本超过 50 行，各种引号、转义、空格问题就开始折磨你。我见过有人因为一行没加引号的 `rm -rf $dir` 把整个 `/home` 目录删掉的。我也见过有人用 `if [ $var == "something" ]` 判断，结果变量为空的时候语法错误。

我写过一条 200 行的 Bash 部署脚本，上线第一天就因为一个未加引号的变量导致把整个生产目录给删了。那次之后，我花了两周时间系统学习了 Bash 的每一个角落。这篇文章就是那些血泪教训的总结。

Bash 是 Linux 世界的通用语言。每个服务器上都有它，每个 DevOps 工程师都用它。掌握 Bash 不是可选技能，是基础设施。本文覆盖变量与引号、条件测试、循环结构、函数定义、数组与关联数组、进程替换、here document、trap 信号处理和实用技巧。

## 变量与引号：Bash 的第一道坎

Bash 的变量赋值看起来简单，实则暗藏杀机。

```bash
# 正确赋值：等号两边不能有空格！
name="Alice"

# 错误：会被解析成命令 name，参数是 "=Alice"
name = "Alice"  # bash: name: command not found

# 错误：会被解析成命令 name，参数是 "Alice"
name= "Alice"   # bash: Alice: command not found
```

这个反直觉的设计源于 Bash 的语法继承。在 shell 里，`name=value command` 是一种环境变量传参的语法，所以等号两侧的空格会让解析器误判。`name` 被当作命令，`=` 和 `"Alice"` 被当作参数。

变量引用有两种方式：

```bash
name="Alice"
echo $name       # Alice

# 推荐用花括号，避免歧义
filename="data"
echo "$filename.txt"      # data.txt

# 不加花括号会怎样？
echo "$filenametxt"       # 空值，因为变量名被解析为 filenametxt
```

花括号 `{}` 的作用很明确：界定变量名的边界。这在字符串插值时尤其重要。比如 `"${prefix}_${suffix}"` 这种写法，没有花括号就乱了。

### 引号的三重境界

Bash 有三种引用方式，它们的区别是很多人搞不清的：

| 引号类型 | 变量扩展 | 命令替换 | 转义 |
|---------|---------|---------|------|
| 双引号 `"` | 扩展 | 扩展 | `\` 有效 |
| 单引号 `'` | 不扩展 | 不扩展 | `\` 不识别 |
| 反引号 `` ` `` | 已废弃 | 执行命令 | 特殊处理 |

```bash
name="Alice"

# 双引号：变量会被扩展
echo "Hello, $name"        # Hello, Alice

# 单引号：原样输出
echo 'Hello, $name'        # Hello, $name

# 混合使用：外层单引号，内层双引号
echo 'Hello, '"$name"'!'   # Hello, Alice!

# 更优雅的做法：在双引号里用转义
echo "The price is \$5"    # The price is $5
```

单引号里的内容没有任何特殊含义，连反斜杠也只是普通字符。这有时候会很烦人：

```bash
# 想要输出一个带单引号的字符串？
echo 'It'''s a trap!'     # It's a trap!
# 技巧：用 ''' 来跳出单引号环境

# 或者干脆用双引号
echo "It's a trap!"        # 简单多了
```

还有一个坑：双引号里的命令替换 `` `cmd` `` 或 `$(cmd)` 会执行：

```bash
date_str="Today is $(date +%Y-%m-%d)"
echo "$date_str"  # Today is 2024-01-15
```

### 特殊变量

Bash 内置了一大堆特殊变量，记不住没关系，常用的就这几个：

```bash
#!/bin/bash

echo "脚本名: $0"
echo "第一个参数: $1"
echo "第二个参数: $2"
echo "参数总数: $#"
echo "所有参数(分开): $@"
echo "所有参数(作为一个字符串): $*"
echo "上一个命令的退出码: $?"
echo "当前进程 PID: $$"
echo "最后一个后台进程 PID: $!"

# 实际用法
if [ $# -lt 2 ]; then
    echo "用法: $0 <源文件> <目标文件>"
    exit 1
fi
```

`$@` 和 `$*` 的区别很多人说不清。用双引号包围时，`"$@"` 把每个参数当作独立的单词（推荐），`"$*"` 把所有参数合并成一个字符串。绝大多数情况下你应该用 `"$@"`。比如 `"$@"` 能正确处理带空格的文件名，而 `"$*"` 会把所有参数粘在一起。

## 条件测试：方括号里的学问

Bash 的条件测试有三种写法：`test`、`[ ]`、`[[ ]]`。新手一般用 `[ ]`，老手都用 `[[ ]]`。

```bash
name="Alice"

# 旧式写法：[ ] 是一个命令，参数之间必须有空格
if [ "$name" = "Alice" ]; then
    echo "Hello, Alice"
fi

# 新式写法：[[ ]] 是关键字，更强大、更安全
if [[ $name == "Alice" ]]; then
    echo "Hello, Alice"
fi
```

`[[ ]]` 相比 `[ ]` 的优势：

1. **不需要对变量加引号**：`[[ $name == "Alice" ]]` 即使 `name` 为空也不会报错。用 `[ ]` 时如果变量为空，会变成 `[ == "Alice" ]`，语法错误。
2. **支持模式匹配**：`[[ $name == A* ]]` 匹配以 A 开头的字符串。
3. **支持正则表达式**：`[[ $name =~ ^[A-Z][a-z]+$ ]]` 可以用正则匹配。
4. **`&&` 和 `||` 直接在内部使用**：`[[ $a == 1 && $b == 2 ]]`，而 `[ ]` 需要用 `-a` 和 `-o`，容易跟文件名冲突。

```bash
# 文件测试
file="/etc/passwd"

if [[ -e $file ]]; then           # 文件存在？
    echo "$file 存在"
fi

if [[ -f $file ]]; then           # 是普通文件？
    echo "$file 是普通文件"
fi

if [[ -d /tmp ]]; then            # 是目录？
    echo "/tmp 是目录"
fi

if [[ -r $file && -w $file ]]; then
    echo "$file 可读且可写"
fi

if [[ -x /bin/ls ]]; then         # 可执行？
    echo "/bin/ls 可执行"
fi

if [[ -s $file ]]; then           # 非空文件？
    echo "$file 非空"
fi

if [[ -L /bin/sh ]]; then         # 是符号链接？
    echo "/bin/sh 是符号链接"
fi

# 字符串测试
str=""

if [[ -z $str ]]; then            # 字符串为空？
    echo "字符串为空"
fi

if [[ -n "hello" ]]; then         # 字符串非空？
    echo "字符串非空"
fi

if [[ "$str" == "" ]]; then      # 另一种空字符串判断
    echo "确实是空"
fi

# 数值比较（注意：必须用 -eq, -ne, -lt, -le, -gt, -ge）
num=42
if [[ $num -eq 42 ]]; then
    echo "等于 42"
fi

if [[ $num -ne 0 ]]; then
    echo "不等于 0"
fi

if [[ $num -gt 40 ]]; then
    echo "大于 40"
fi

# 或者用 (( )) 做算术比较（更推荐）
if (( num > 40 && num < 50 )); then
    echo "在 40 和 50 之间"
fi

if (( num % 2 == 0 )); then
    echo "偶数"
fi
```

有一个坑必须提醒：`=` 和 `==` 在 `[[ ]]` 里效果一样，但在 `[ ]` 里只能用 `=`。数值比较如果用 `=` 会按字符串比较，`[[ 10 -gt 2 ]]` 是对的，`[[ 10 > 2 ]]` 会按字符串比较得出错误结果。另一个坑是 `==` 在 `[[ ]]` 里是模式匹配，不是精确字符串匹配。如果要精确匹配字符串，用 `=` 更安全。

## 循环结构：for、while 与 until

### for 循环

```bash
# 遍历列表
for name in Alice Bob Charlie; do
    echo "Hello, $name"
done

# 遍历文件
for file in *.txt; do
    echo "处理: $file"
done

# 处理带空格的文件名
for file in *.txt; do
    if [[ -f "$file" ]]; then
        echo "处理: '$file'"
    fi
done

# C 风格（需要 Bash）
for ((i = 0; i < 5; i++)); do
    echo "i = $i"
done

# 递减
for ((i = 10; i > 0; i--)); do
    echo "倒计时: $i"
done

# 遍历命令输出
for user in $(cut -d: -f1 /etc/passwd); do
    echo "用户: $user"
done

# 更安全的做法（处理带空格的文件名）
while IFS= read -r line; do
    echo "行: $line"
done < file.txt
```

遍历命令输出时用 `$(...)` 比用反引号 `` `...` `` 好，因为可以嵌套，而且转义规则更直观。比如 `$(basename $(dirname $path))` 这种嵌套用反引号就很难写。

### while 与 until

```bash
# while 循环
count=0
while (( count < 5 )); do
    echo "count = $count"
    ((count++))
done

# 读取文件行 by 行
while IFS= read -r line; do
    echo "读取: $line"
done < input.txt

# 读取命令输出
while IFS= read -r line; do
    echo "输出: $line"
done < <(ls -la)

# until 循环（条件为假时执行）
num=0
until (( num >= 5 )); do
    echo "num = $num"
    ((num++))
done

# 无限循环
while true; do
    echo "按 Ctrl+C 退出"
    sleep 1
done

# 带 break 和 continue
for i in {1..10}; do
    if (( i == 3 )); then
        continue  # 跳过 3
    fi
    if (( i == 7 )); then
        break     # 到 7 停止
    fi
    echo "i = $i"
done
```

`IFS=` 和 `read -r` 是读取文件时的最佳实践。`IFS=` 防止行首行尾的空格被截断，`read -r` 防止反斜杠被当作转义字符处理。如果不用 `-r`，`read` 会把行尾的 `\` 当作续行符处理，这在处理 Windows 路径时尤其危险。

## 函数定义：作用域是个坑

```bash
#!/bin/bash

# 定义函数
greet() {
    local name=$1     # local 关键字限定作用域
    echo "Hello, $name"
}

# 带返回值的函数（只能返回 0-255 的整数）
add() {
    local a=$1
    local b=$2
    echo $((a + b))   # 用 stdout 返回结果
}

# 调用
result=$(add 10 20)
echo "10 + 20 = $result"

# 获取函数返回值（exit status）
check_file() {
    [[ -f $1 ]]
}

if check_file "/etc/passwd"; then
    echo "文件存在"
fi
```

Bash 函数的"返回值"非常受限，只能返回 0 到 255 的整数。如果需要返回复杂数据，通常用 `echo` 输出到 stdout，然后用命令替换捕获。另一种方式是设置全局变量，但这在并发场景下会有问题。

**函数作用域是新手最容易踩的坑**。默认情况下，函数里定义的变量是全局的！

```bash
x=10

bad_function() {
    x=20    # 修改了全局变量！
}

good_function() {
    local x=30    # 只在这个函数里有效
    local y=50    # 局部变量
}

bad_function
echo "x = $x"    # x = 20（被修改了！）

good_function
echo "x = $x"    # x = 20（good_function 没影响）
echo "y = $y"    # y = （空，因为 y 是局部的）
```

养成在函数里对所有变量使用 `local` 的习惯。这是写好 Bash 脚本的第一条军规。我见过太多 bug 是因为函数里忘了加 `local`，把全局变量给覆盖了。

## 字符串操作：Bash 的瑞士军刀

Bash 内置了强大的字符串操作能力，不需要调用 `sed` 或 `awk` 就能完成很多常见的文本处理任务。

```bash
str="Hello, World!"

# 获取长度
len=${#str}
echo "长度: $len"    # 13

# 截取子串（从索引 0 开始）
echo "${str:0:5}"    # Hello
echo "${str:7}"      # World!
echo "${str: -6}"    # World!（注意空格，从末尾数）

# 删除前缀
echo "${str#Hello, }"     # World!
echo "${str#*, }"         # World!（最短匹配）
echo "${str##*, }"        # World!（最长匹配）

# 删除后缀
filename="document.txt.tar.gz"
echo "${filename%.txt*}"     # document
echo "${filename%%.*}"       # document（最长匹配）

# 查找替换
echo "${str/World/Bash}"      # Hello, Bash!
echo "${str//l/L}"            # HeLLo, WorLd!（全局替换）
echo "${str/l}"               # Helo, World!（删除第一个匹配）

# 大小写转换
echo "${str^^}"        # HELLO, WORLD!（全大写）
echo "${str,,}"        # hello, world!（全小写）
echo "${str^}"         # Hello, World!（首字母大写）

# 默认值
unset var
echo "${var:-default}"      # default（var 为空或未定义时返回 default）
echo "${var:=default}"      # default（同时设置 var = default）
echo "${var:?error}"        # 报错：var: error
var="hello"
echo "${var:+set}"          # set（var 非空时返回 set）
```

这些参数扩展在处理文件名、路径和配置时非常有用。比如批量重命名文件：

```bash
for file in *.txt; do
    # 去掉 .txt 后缀，加上 .bak
    newname="${file%.txt}.bak"
    mv "$file" "$newname"
done
```

## 数组与关联数组

Bash 4.0 引入了关联数组（哈希表），让 Bash 终于有点现代语言的样子了。

```bash
#!/bin/bash

# 索引数组
colors=("red" "green" "blue")
echo "第一种颜色: ${colors[0]}"
echo "所有颜色: ${colors[@]}"
echo "数组长度: ${#colors[@]}"

# 遍历数组
for color in "${colors[@]}"; do
    echo "颜色: $color"
done

# 遍历索引
for i in "${!colors[@]}"; do
    echo "索引 $i: ${colors[$i]}"
done

# 追加元素
colors+=("yellow")
colors+=("purple" "orange")

# 删除元素
unset 'colors[2]'    # 删除索引 2 的元素

# 切片
echo "前两个: ${colors[@]:0:2}"
echo "从索引1开始: ${colors[@]:1}"

# 关联数组（Bash 4.0+）
declare -A user
user[name]="Alice"
user[age]=30
user[city]="Beijing"
user[role]="admin"

echo "姓名: ${user[name]}"
echo "所有键: ${!user[@]}"
echo "所有值: ${user[@]}"

# 遍历关联数组
for key in "${!user[@]}"; do
    echo "$key = ${user[$key]}"
done

# 检查键是否存在
if [[ -n "${user[email]}" ]]; then
    echo "有邮箱"
else
    echo "没邮箱"
fi
```

关联数组在 Bash 4 之前是不存在的，这也是为什么很多老脚本用 `eval` 搞出各种黑科技来模拟哈希表。如果你还在用 Bash 3（macOS 默认就是），考虑升级到 Bash 5 或者用 zsh。macOS 用户可以用 `brew install bash` 安装新版 Bash。

## 进程替换：Bash 的黑魔法

进程替换（Process Substitution）是 Bash 的一个高级特性，很多人听说过但不知道怎么用。

```bash
# 语法：<(command) 生成一个可读的文件描述符
#        >(command) 生成一个可写的文件描述符

# 例子：比较两个命令的输出
diff <(ls dir1) <(ls dir2)

# 例子：把多个命令的输出合并处理
cat <(echo "Header") <(cat data.txt) <(echo "Footer")

# 例子：把输出重定向到另一个命令（少见）
cat file.txt > >(grep "error" > errors.log)

# 用进程替换读取命令输出到 while 循环
while IFS= read -r line; do
    echo "处理: $line"
done < <(find . -name "*.txt")
```

进程替换的本质是创建了一个命名管道（named pipe），让命令的输出可以像文件一样被其他命令读取。这对于不接受标准输入的命令特别有用。比如 `diff` 需要两个文件参数，用进程替换可以直接比较两个命令的输出。

```bash
# 不用进程替换的丑陋写法
cat file1 file2 > /tmp/combined.txt
grep "pattern" /tmp/combined.txt
rm /tmp/combined.txt

# 用进程替换
grep "pattern" <(cat file1 file2)
```

进程替换在写复杂管道时简直是救命稻草。不过要注意，它创建的 "文件" 实际上是一个 `/dev/fd/xx` 特殊文件，某些不支持这种文件类型的程序可能会报错。另外，进程替换创建的子进程是异步运行的，如果处理不当可能导致竞争条件。

### xargs：管道的好搭档

`xargs` 把标准输入转换成命令行参数，是管道处理中不可或缺的工具。

```bash
# 基本用法：把 find 的结果传给 rm
find . -name "*.tmp" | xargs rm

# 处理带空格的文件名
find . -name "*.txt" -print0 | xargs -0 rm

# 限制每次传递的参数数量
find . -name "*.log" | xargs -n 100 rm

# 并行执行（-P 指定并发数）
find . -name "*.jpg" | xargs -P 4 -I {} convert {} {}.png

# 从文件读取参数
cat urls.txt | xargs -n 1 curl -O

# 配合 -I 做替换
ls *.txt | xargs -I {} cp {} {}.bak
```

`xargs -0` 是处理带空格文件名的标准做法。`-print0` 让 `find` 用 NUL 字符分隔文件名，`xargs -0` 用 NUL 字符解析，这样文件名里的空格、换行都不会造成问题。

## Here Document 与 Here String

Here Document 让你可以在脚本里嵌入多行文本：

```bash
# Here Document
cat << EOF
这是一个多行文本。
当前用户: $USER
当前目录: $PWD
当前时间: $(date)
EOF

# 禁止变量扩展（在定界符加引号）
cat << 'EOF'
这是纯文本，$USER 不会被扩展。
$(date) 也不会执行。
EOF

# 忽略前导制表符（在 << 后加减号）
cat <<-EOF
	这一行的制表符会被去掉
		这一行也是
				全部去掉
EOF

# Here String（单行）
grep "pattern" <<< "this is a test string"

# 等价于
echo "this is a test string" | grep "pattern"
```

Here Document 在生成配置文件或 SQL 语句时特别方便：

```bash
# 生成配置文件
cat > config.ini << EOF
[database]
host = localhost
port = 5432
name = myapp
user = admin

[server]
port = 8080
workers = 4
max_connections = 100

[logging]
level = info
file = /var/log/app.log
EOF

# 执行 SQL
mysql -u root -p << 'SQL'
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (name, email) VALUES 
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com');
SQL
```

注意上面 SQL heredoc 用了 `'SQL'` 来禁止变量扩展，防止 SQL 里的 `$` 被误解析。如果 SQL 里有 `$` 符号（比如 PostgreSQL 的占位符 `$1`），不加引号的话 Bash 会把它当变量处理。

## 后台作业与并行执行

Bash 支持把任务放到后台执行，配合 `wait` 可以实现简单的并行处理。

```bash
# 后台执行命令
long_task() {
    echo "开始任务 $1"
    sleep "$2"
    echo "任务 $1 完成"
}

# 启动多个后台任务
long_task "A" 3 &
long_task "B" 2 &
long_task "C" 4 &

# 等待所有后台任务完成
echo "等待所有任务完成..."
wait
echo "全部完成"

# 查看后台作业列表
jobs

# 把最近的后台作业调到前台
fg %1

# 暂停当前作业，放到后台
# Ctrl+Z 暂停，然后 bg 放到后台继续执行
```

用 `&` 启动后台任务时，Bash 会输出作业号和进程 ID。`wait` 命令等待所有子进程结束，这在批量处理时非常有用。我曾经用它并行处理几百个日志文件，比串行处理快了将近 10 倍。

但要注意，后台任务的输出会跟前台输出混在一起。如果需要收集每个任务的结果，可以把输出重定向到不同的文件：

```bash
for file in *.log; do
    process_log "$file" > "${file%.log}.out" 2>&1 &
done
wait
```

## Trap：优雅地处理信号

脚本被 `Ctrl+C` 中断时，临时文件没清理，数据库事务没回滚，这种事情你遇到过吗？`trap` 命令就是用来解决这类问题的。

```bash
#!/bin/bash

# 设置临时目录
TMPDIR=$(mktemp -d)
echo "临时目录: $TMPDIR"

# 退出时清理
cleanup() {
    echo "清理临时文件..."
    rm -rf "$TMPDIR"
    echo "完成"
}

# 捕获 EXIT 信号（脚本退出时，无论正常还是异常）
trap cleanup EXIT

# 捕获 SIGINT (Ctrl+C)
trap 'echo "收到中断信号，正在退出..."; exit 1' INT

# 捕获 SIGTERM (kill 默认信号)
trap 'echo "收到终止信号"; exit 1' TERM

# 模拟工作
echo "开始处理..."
sleep 5
echo "处理完成"

# 正常退出时，EXIT trap 会自动执行 cleanup
```

`trap` 的常见用法：

```bash
# 忽略信号
trap '' INT    # 忽略 Ctrl+C
trap '-' INT   # 恢复默认处理

# 捕获多个信号
trap 'echo "收到信号"; cleanup' INT TERM EXIT

# 查看当前设置的 trap
trap -p

# 在函数里局部设置 trap（Bash 4.0+）
process_with_cleanup() {
    local temp=$(mktemp)
    trap "rm -f $temp" RETURN    # 函数返回时执行
    # 处理...
    echo "处理文件: $temp"
}

# 嵌套 trap
set -E  # 继承 ERR trap
set -T  # 继承 DEBUG 和 RETURN trap
```

`trap` 配合临时文件处理是写健壮脚本的必修课。我见过太多脚本在 `/tmp` 里留下成堆的垃圾文件，就是因为没做清理。`mktemp` + `trap cleanup EXIT` 是标准搭配。

## 实用技巧与最佳实践

### 严格模式

在脚本开头加上这几行，能避免 80% 的常见问题：

```bash
#!/bin/bash
set -euo pipefail
IFS=$'
	'
```

- `set -e`：命令失败（返回非 0）时立即退出。但要注意，它在某些情况下不生效（比如管道中间失败、if 条件里的命令）。
- `set -u`：使用未定义变量时报错。防止 `rm -rf $uninitialized/` 这种悲剧。
- `set -o pipefail`：管道中任一命令失败，整个管道返回非 0。防止 `grep | something` 中 grep 没找到但管道返回成功。
- `IFS=$'
	'`：把字段分隔符设为换行和制表符，避免空格引起的拆分问题。

### 调试技巧

```bash
#!/bin/bash
set -x          # 开启调试模式，打印每条执行的命令
# ... 脚本代码 ...
set +x          # 关闭调试模式

# 或者运行脚本时开启调试
bash -x script.sh

# 只在特定部分调试
set -x
critical_function
set +x

# 打印执行的命令但不执行（dry run）
set -n

# 更精细的调试
PS4='+ ${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
```

### 处理命令失败

```bash
# 检查命令是否成功
if ! command -v node &> /dev/null; then
    echo "node 未安装"
    exit 1
fi

# 或者使用 ||
grep "pattern" file.txt || echo "未找到匹配"

# 使用 && 确保前一条成功才执行下一条
mkdir -p "$dir" && cd "$dir" || exit 1

# 管道中的错误处理
set -o pipefail
some_command | grep "filter" | head -n 10
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "some_command 失败了"
fi

# 显式检查退出码
rm "$file"
exit_code=$?
if (( exit_code != 0 )); then
    echo "删除失败，退出码: $exit_code"
fi
```

### 正则表达式与文本处理

Bash 3.2+ 支持正则表达式匹配，配合 `grep`、`sed`、`awk` 可以完成复杂的文本处理。

```bash
# Bash 内置正则匹配
if [[ "hello@example.com" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "邮箱格式正确"
fi

# 提取匹配的组
string="version=1.2.3"
if [[ $string =~ version=([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "主版本: ${BASH_REMATCH[1]}"
    echo "次版本: ${BASH_REMATCH[2]}"
    echo "修订: ${BASH_REMATCH[3]}"
fi

# sed 常用技巧
sed 's/old/new/g' file.txt          # 替换所有 old 为 new
sed '/^#/d' file.txt                # 删除以 # 开头的行
sed -n '10,20p' file.txt            # 打印第 10-20 行
sed 's/  */ /g' file.txt            # 多个空格合并为一个

# awk 常用技巧
awk '{print $1}' file.txt           # 打印第一列
awk -F',' '{print $2}' file.csv     # 以逗号分隔，打印第二列
awk '$3 > 100 {print $0}' data.txt  # 第三列大于 100 的行
awk '{sum+=$1} END {print sum}' nums.txt  # 求和
```

### 环境变量与配置文件

脚本经常需要读取环境变量或配置文件。处理这些时要注意默认值和安全性。

```bash
# 读取环境变量（带默认值）
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export LOG_LEVEL="${LOG_LEVEL:-info}"

# 检查必需的环境变量
: "${API_KEY:?API_KEY 环境变量必须设置}"

# 读取 .env 文件
load_env() {
    local env_file="${1:-.env}"
    if [[ -f "$env_file" ]]; then
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            # 去除首尾空格
            key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            # 去除引号
            value="${value%\"}"
            value="${value#\"}"
            export "$key=$value"
        done < "$env_file"
    fi
}

# 生成配置文件
generate_config() {
    cat > config.ini << EOF
[app]
name = ${APP_NAME:-myapp}
version = ${VERSION:-1.0.0}
environment = ${ENV:-development}

[database]
host = ${DB_HOST:-localhost}
port = ${DB_PORT:-5432}
pool_size = ${DB_POOL:-10}
EOF
}
```

环境变量的处理有一个常见陷阱：在脚本里 `export` 的变量会传递给子进程，但不会影响父 shell。如果你运行 `./script.sh`，脚本里的 `export` 对当前终端无效；要用 `source script.sh` 才会生效。

### 路径处理

```bash
# 获取脚本所在目录（不管从哪里调用）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 安全地处理文件名（处理特殊字符）
filename="file with spaces.txt"
cp "$filename" /tmp/    # 必须用引号

# 路径操作
dirname "/home/user/file.txt"    # /home/user
basename "/home/user/file.txt"   # file.txt
basename "/home/user/file.txt" .txt   # file

# 去除路径最后的斜杠
path="/home/user/"
echo "${path%/}"    # /home/user

# 默认值
output_dir="${OUTPUT_DIR:-/tmp/default}"
```

### 一个完整的实用脚本模板

```bash
#!/bin/bash
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
用法: $SCRIPT_NAME [选项] <参数>

选项:
    -h, --help      显示帮助信息
    -v, --verbose   详细输出
    -o, --output    输出文件
    -n, --dry-run   模拟运行，不实际执行

示例:
    $SCRIPT_NAME -v input.txt
    $SCRIPT_NAME -o result.json input.txt
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

warn() {
    echo "[WARN] $*" >&2
}

main() {
    local verbose=false
    local output=""
    local dry_run=false
    local input=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -*)
                error "未知选项: $1"
                ;;
            *)
                input="$1"
                shift
                ;;
        esac
    done

    [[ -z "$input" ]] && error "缺少输入文件"
    [[ -f "$input" ]] || error "文件不存在: $input"

    $verbose && log "处理文件: $input"
    $verbose && log "脚本目录: $SCRIPT_DIR"

    if $dry_run; then
        log "[DRY-RUN] 将输出到: ${output:-stdout}"
        exit 0
    fi

    # 实际处理逻辑...
    log "处理完成"
}

main "$@"
```

## 总结

Bash 脚本是一门"够用就行"的语言。它不是为了写大型应用而生的，它的主战场是自动化、部署、系统管理和胶水代码。当你需要用 5 行代码完成一个文件批处理任务时，Bash 是最佳选择。当你需要写超过 500 行的复杂逻辑时，考虑用 Python 或 Go 重写。

### 什么时候用 Bash，什么时候不用

用 Bash 的场景：
- 文件和目录操作
- 调用系统命令并组合它们的输出
- 简单的文本处理
- 启动/停止服务
- 构建和部署脚本

不要用 Bash 的场景：
- 复杂的数学计算
- 网络请求和 API 调用（用 Python/curl）
- 需要解析复杂数据格式（JSON/XML/YAML）
- 多线程/多进程并发
- 需要跨平台兼容（用 Python）

### 常见陷阱速查

| 问题 | 错误写法 | 正确写法 |
|------|---------|---------|
| 变量含空格 | `rm $file` | `rm "$file"` |
| 赋值加空格 | `name = "value"` | `name="value"` |
| 数值比较 | `[ $n > 5 ]` | `(( n > 5 ))` |
| 字符串比较 | `[[ $s > "abc" ]]` | `[[ $s > "abc" ]]` 是对的，但容易混淆 |
| 数组索引 | `${arr[0]}` | `${arr[0]}` 是对的，但注意 `@` 和 `*` |
| 命令替换丢失 | `var=$(cmd)` | `var=$(cmd)` 是对的，但注意引号 |
| 管道错误被吞 | `cmd1 | cmd2` | `set -o pipefail` |
| 函数变量污染 | `x=10` | `local x=10` |

| 主题 | 关键要点 |
|------|---------|
| 变量 | 赋值不加空格，引用用 `"${var}"` |
| 引号 | 双引号扩展，单引号不扩展，用 `[[ ]]` 代替 `[ ]` |
| 条件 | `[[ ]]` 更安全，`-eq` 用于数字，`=` 用于字符串 |
| 循环 | `"${array[@]}"` 遍历数组，用 `while read` 读文件 |
| 函数 | 总是用 `local`，用 `echo` 或全局变量返回结果 |
| 数组 | `declare -A` 声明关联数组 |
| 进程替换 | `<(cmd)` 创建可读文件描述符 |
| Here Doc | `<< 'EOF'` 禁止变量扩展 |
| trap | `EXIT` 信号保证清理代码执行 |
| 严格模式 | `set -euo pipefail` 是最佳实践 |

Shell 脚本写多了，你会发现自己在一堆引号和转义符号里迷失。这时候记住两条原则：一是**所有变量都用双引号包围**，二是**启用严格模式**。这两条能帮你避开 90% 的坑。剩下的 10%，靠的是经验和对 edge case 的敬畏。

> "Bash 是一门让你先用起来再慢慢后悔的语言。" —— 某不知名运维工程师

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '25 days',
    NOW() - INTERVAL '25 days',
    NOW() - INTERVAL '25 days'
),
(
    1,
    'OCaml：强类型函数式编程',
    'ocaml-strongly-typed',
    'OCaml 是一门被低估的语言。它的类型推导系统让编译器像你的搭档一样，帮你发现代码里的 bug。本文深入探索 OCaml 的类型系统、模块系统和尾递归优化。',
    $doc$
# OCaml：强类型函数式编程

OCaml 是一门冷门的语言。放在 TIOBE 排行榜上，它可能都进不了前 50。但如果你去问 Jane Street（华尔街最神秘的交易公司之一）他们用啥写高频交易系统，答案是：OCaml。每年几十亿美元的交易量，全靠这门"小众"语言撑着。

我第一次接触 OCaml 是在大学的一门编程语言课上。老师让我们用 OCaml 写一个表达式求值器，我写完后运行，发现居然一次就通过了所有测试用例。这在 C 或 Java 里是不可想象的——通常要调半天指针或类型转换。OCaml 的编译器就像个唠叨但靠谱的搭档，在我写代码的时候就把大部分错误揪了出来。

后来在工作中偶尔用 OCaml 写一些数据处理和编译器相关的工具，每次都被它的类型系统惊艳到。你改了一个函数的签名，编译器会告诉你所有受影响的地方。这种安全感是动态语言给不了的。

## 类型推导：编译器比你更懂你的代码

OCaml 最迷人的特性是**类型推导**（Type Inference）。你不需要写类型注解，编译器能从代码的结构里自动推断出每个表达式和函数的类型。

```ocaml
(* 不需要写类型，编译器自动推断 *)
let add x y = x + y
(* 推断类型：add : int -> int -> int *)

let greet name = "Hello, " ^ name
(* 推断类型：greet : string -> string *)

(* 列表 *)
let numbers = [1; 2; 3; 4; 5]
(* 推断类型：numbers : int list *)

(* 元组 *)
let point = (3.0, 4.0)
(* 推断类型：point : float * float *)

(* 更复杂的例子 *)
let average a b = (a +. b) /. 2.0
(* 推断类型：average : float -> float -> float *)
```

`^` 是字符串连接运算符，不是乘方。OCaml 用 `+` 做整数加法，`+.` 做浮点加法，`*` 做整数乘法，`*. `做浮点乘法。这看起来啰嗦，但实际上消除了 C 语言里大量隐式类型转换带来的 bug。你不会不小心把浮点数加到整数上，因为编译器会直接报错。

类型推导不是动态类型，它依然是静态强类型。区别在于编译器替你写了类型标注：

```ocaml
(* 上面的 add 函数，显式写出来是这样的 *)
let add (x : int) (y : int) : int = x + y

(* 但我们完全可以省略 *)
let add x y = x + y
```

类型推导基于 **Hindley-Milner 算法**，这是一个 70 年代发明的类型系统。它的核心思想是：给每个表达式一个类型变量，然后根据表达式的使用方式建立约束方程，最后解这个方程组。听起来很数学，但 OCaml 的编译器能在毫秒级完成推导。

```ocaml
(* 复杂一点的例子 *)
let rec map f = function
  | [] -> []
  | x :: xs -> f x :: map f xs

(* 编译器推导出的类型：
   map : ('a -> 'b) -> 'a list -> 'b list
   
   'a 和 'b 是类型变量，表示 "任意类型"
   这跟我们手写的一模一样
*)
```

`map` 的类型签名读作：接收一个函数 `('a -> 'b)`，接收一个 `'a list`，返回一个 `'b list`。`'` 开头的标识符是类型变量，类似于 Java 的泛型参数 `T` 或 Rust 的 `T`。OCaml 的类型推导自动给出了最通用的类型签名，不需要我们显式声明泛型。这是 Hindley-Milner 系统的核心优势：类型多态是自动的、无处不在的。

## 代数数据类型：用类型描述世界

**代数数据类型**（Algebraic Data Types，ADT）是函数式编程的核心工具。OCaml 用 `type` 关键字定义 ADT，支持两种基本构造：乘积类型（元组/记录）和和类型（变体）。

```ocaml
(* 乘积类型：记录（record） *)
type person = {
  name : string;
  age : int;
  email : string option;
}

let alice = { name = "Alice"; age = 30; email = Some "alice@example.com" }

(* 访问字段 *)
let () = Printf.printf "%s is %d years old
" alice.name alice.age

(* 模式匹配解构记录 *)
let greet { name; age } =
  Printf.printf "Hello, %s! You are %d.
" name age

(* 更新记录（创建新记录） *)
let older_alice = { alice with age = 31 }
```

`{ alice with age = 31 }` 是记录更新的语法糖，它创建一个新记录，只修改 `age` 字段，其他字段保持不变。这是不可变更新的标准做法。

和类型（变体）是 ADT 的另一半：

```ocaml
(* 和类型：变体（variant） *)
type shape =
  | Circle of float                    (* 半径 *)
  | Rectangle of float * float         (* 宽 * 高 *)
  | Triangle of float * float * float  (* 三边 *)

(* 模式匹配处理每种情况 *)
let area = function
  | Circle r -> Float.pi *. r *. r
  | Rectangle (w, h) -> w *. h
  | Triangle (a, b, c) ->
      let s = (a +. b +. c) /. 2.0 in
      Float.sqrt (s *. (s -. a) *. (s -. b) *. (s -. c))

let () =
  let c = Circle 5.0 in
  Printf.printf "Area = %.2f
" (area c)  (* Area = 78.54 *)
```

`option` 类型是 OCaml 里处理可能缺失的值的标准方式，相当于其他语言里的 nullable：

```ocaml
type 'a option = None | Some of 'a

(* 安全地查找列表中的元素 *)
let rec find_opt p = function
  | [] -> None
  | x :: _ when p x -> Some x
  | _ :: xs -> find_opt p xs

let result = find_opt (fun x -> x > 10) [1; 5; 15; 20]
(* result = Some 15 *)

match result with
| Some x -> Printf.printf "Found: %d
" x
| None -> print_endline "Not found"
```

ADT 的强大之处在于：**不可能的状态在编译期就被排除**。如果你定义了一个表达式类型：

```ocaml
type expr =
  | Num of int
  | Add of expr * expr
  | Mul of expr * expr
  | Div of expr * expr
  | Var of string

(* 求值器 *)
let rec eval env = function
  | Num n -> n
  | Add (e1, e2) -> eval env e1 + eval env e2
  | Mul (e1, e2) -> eval env e1 * eval env e2
  | Div (e1, e2) -> eval env e1 / eval env e2
  | Var x -> List.assoc x env
```

编译器会检查 `eval` 函数是否处理了 `expr` 的所有变体。如果我后来给 `expr` 加了一个 `Sub` 分支但忘了更新 `eval`，编译器会报错。这种**穷尽性检查**（exhaustiveness checking）让重构变得安全。我有一次给 AST 加了新的节点类型，编译器列出了所有需要更新的函数，省了至少一个小时的调试时间。

## 模式匹配：比 switch 强大十倍

模式匹配是 OCaml 里使用频率最高的语法特性之一。它不仅仅是 switch 语句的增强版，而是一种强大的解构和分支机制。

```ocaml
(* 基础模式匹配 *)
let describe = function
  | 0 -> "zero"
  | 1 -> "one"
  | 2 -> "two"
  | n when n < 0 -> "negative"
  | n when n > 100 -> "big"
  | _ -> "other"

(* 列表模式匹配 *)
let rec length = function
  | [] -> 0
  | _ :: tail -> 1 + length tail

(* 深度模式匹配 *)
type binary_tree =
  | Leaf
  | Node of int * binary_tree * binary_tree

let rec sum_tree = function
  | Leaf -> 0
  | Node (value, left, right) ->
      value + sum_tree left + sum_tree right

(* 嵌套模式 *)
let is_single_node = function
  | Node (_, Leaf, Leaf) -> true
  | _ -> false

(* as 模式：绑定子模式 *)
let get_left = function
  | Node (_, (Leaf as l), _) -> Some l
  | Node (_, (Node _ as l), _) -> Some l
  | Leaf -> None

(* 列表操作的模式匹配 *)
let rec reverse lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] lst

let rec take n = function
  | [] -> []
  | _ when n <= 0 -> []
  | x :: xs -> x :: take (n - 1) xs
```

`::` 是列表的构造运算符，`[1; 2; 3]` 等价于 `1 :: 2 :: 3 :: []`。模式匹配时，`x :: xs` 匹配非空列表，把第一个元素绑定到 `x`，剩余部分绑定到 `xs`。

模式匹配的一个高级特性是**守卫**（guard）：

```ocaml
let classify_number n =
  match n with
  | 0 -> "zero"
  | 1 | 2 | 3 -> "small"           (* 多个模式用 | 连接 *)
  | n when n mod 2 = 0 -> "even"   (* 守卫条件 *)
  | _ -> "odd"
```

编译器会检查模式匹配是否穷尽。如果漏掉了一个分支，它会给出警告甚至错误：

```ocaml
(* 编译器警告：This pattern-matching is not exhaustive. *)
let risky = function
  | Some x -> x
  (* 漏掉了 None！ *)
```

这种静态保证在处理复杂数据结构时价值巨大。你在写代码的时候就知道有没有漏掉情况，而不是等到运行时崩溃。这对于大规模代码库尤其重要。

## 错误处理：Option、Result 与异常

OCaml 提供了多种错误处理机制，从简单的 `option` 到功能完备的 `result` 类型。

`option` 用于表示值可能存在也可能不存在：

```ocaml
type 'a option = None | Some of 'a

let safe_div a b =
  if b = 0 then None
  else Some (a / b)

match safe_div 10 2 with
| Some result -> Printf.printf "结果: %d\n" result
| None -> print_endline "除零错误"
```

`result` 类型在 OCaml 4.03+ 中成为标准库的一部分，它可以携带错误信息：

```ocaml
type ('a, 'b) result = Ok of 'a | Error of 'b

let parse_int s =
  try Ok (int_of_string s)
  with Failure _ -> Error (Printf.sprintf "无法解析整数: %s" s)

let compute s1 s2 =
  match parse_int s1 with
  | Error e -> Error e
  | Ok a ->
      match parse_int s2 with
      | Error e -> Error e
      | Ok b ->
          if b = 0 then Error "除数不能为零"
          else Ok (a / b)

(* 使用 >>= 操作符简化嵌套 *)
let (>>=) r f =
  match r with
  | Ok x -> f x
  | Error e -> Error e

let compute2 s1 s2 =
  parse_int s1 >>= fun a ->
  parse_int s2 >>= fun b ->
  if b = 0 then Error "除数不能为零"
  else Ok (a / b)
```

这种链式调用让错误处理变得清晰。每个步骤失败后，后续步骤不会执行，错误信息会自动传播。这比异常机制更明确，因为错误处理就在类型签名里，不会藏在某个 catch 块里。

异常在 OCaml 中也有用途，主要用于真正的异常情况——程序不应该恢复的错误：

```ocaml
exception Division_by_zero
exception File_not_found of string

let read_file filename =
  if not (Sys.file_exists filename) then
    raise (File_not_found filename);
  let ic = open_in filename in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  content
```

不过现代 OCaml 代码倾向于用 `result` 而不是异常，因为 `result` 让错误处理显式化，编译器能帮你检查是否处理了所有错误路径。

## 模块系统：比类更强大的抽象工具

OCaml 的模块系统是它最独特也最强大的特性之一。模块不是类，不是命名空间，而是一种独立的抽象机制。

```ocaml
(* 定义一个模块 *)
module Stack = struct
  type 'a t = 'a list

  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Empty stack"
    | x :: xs -> (x, xs)
  let peek = function
    | [] -> failwith "Empty stack"
    | x :: _ -> x
  let is_empty s = s = []
  let size s = List.length s
end

(* 使用模块 *)
let s = Stack.empty
let s = Stack.push 1 s
let s = Stack.push 2 s
let top, s = Stack.pop s
(* top = 2, s = [1] *)
```

模块可以封装实现细节。外部代码只知道 `Stack` 模块的接口，不知道底层用的是列表。这意味着以后可以把实现换成数组或自定义数据结构，而不影响外部代码。

### 签名（接口）

```ocaml
(* 定义接口 *)
module type STACK = sig
  type 'a t
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a * 'a t
  val peek : 'a t -> 'a
  val is_empty : 'a t -> bool
  val size : 'a t -> int
end

(* 实现接口 *)
module ListStack : STACK = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Empty stack"
    | x :: xs -> (x, xs)
  let peek = function
    | [] -> failwith "Empty stack"
    | x :: _ -> x
  let is_empty s = s = []
  let size = List.length
end
```

签名隐藏了实现细节。`ListStack` 的类型 `'a ListStack.t` 是抽象的，外部无法知道它内部是列表。这提供了真正的信息隐藏，不是 Java 里那种靠命名约定的伪隐藏。

### Functor：模块的函数

**Functor** 是接收模块作为参数并返回新模块的函数。这是 OCaml 模块系统的巅峰。

```ocaml
(* 定义一个可比较类型的接口 *)
module type COMPARABLE = sig
  type t
  val compare : t -> t -> int
end

(* 定义集合的接口 *)
module type SET = sig
  type elt
  type t
  val empty : t
  val add : elt -> t -> t
  val mem : elt -> t -> bool
  val remove : elt -> t -> t
  val size : t -> int
end

(* Functor：给定一个 COMPARABLE，生成一个 SET *)
module MakeSet (Elt : COMPARABLE) : SET with type elt = Elt.t = struct
  type elt = Elt.t
  type t = elt list

  let empty = []
  let add x s = if List.mem x s then s else x :: s
  let mem = List.mem
  let remove x s = List.filter (fun y -> y <> x) s
  let size = List.length
end

(* 使用 Functor *)
module IntCompare = struct
  type t = int
  let compare = Int.compare
end

module IntSet = MakeSet (IntCompare)

let s = IntSet.empty
let s = IntSet.add 42 s
let s = IntSet.add 10 s
let has_42 = IntSet.mem 42 s  (* true *)
```

Functor 是参数化模块。`MakeSet` 是一个模板，给它不同的比较模块，就能生成不同元素类型的集合。这类似于 C++ 的模板，但类型安全、错误信息友好。

Jane Street 的核心库大量使用 Functor 来构建灵活的数据结构。他们的 `Map` 和 `Set` 实现都是用 Functor 参数化的，可以处理任何可比较的类型。这种模块化的设计让他们能在不修改核心代码的情况下，为不同的数据类型生成优化的集合实现。

## 尾递归优化：递归也能高效

递归在函数式语言里是不可避免的。但朴素的递归会导致栈溢出：

```ocaml
(* 朴素递归：会栈溢出 *)
let rec sum_bad = function
  | [] -> 0
  | x :: xs -> x + sum_bad xs

(* sum_bad [1; 2; ...; 1000000] -> Stack overflow! *)
```

OCaml 支持**尾递归优化**（Tail Call Optimization，TCO）。如果一个递归调用是函数的最后一个操作，编译器会把它优化成循环，复用当前栈帧。

```ocaml
(* 尾递归版本：不会栈溢出 *)
let sum lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (acc + x) xs  (* 尾调用 *)
  in
  aux 0 lst

(* sum [1; 2; ...; 1000000] -> 正常工作！ *)
```

`aux` 函数里的递归调用 `aux (acc + x) xs` 是最后一个操作，没有任何后续计算。编译器识别出这是尾调用，直接复用当前栈帧。这种优化让递归在实际使用中跟循环一样安全。

 accumulator（累加器）模式是写尾递归的标准技巧：把中间结果通过一个额外参数传递，而不是在返回时做计算。

```ocaml
(* 尾递归的阶乘 *)
let factorial n =
  let rec aux acc n =
    if n <= 1 then acc
    else aux (acc * n) (n - 1)
  in
  aux 1 n

(* 尾递归的列表反转 *)
let rev lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] lst

(* 尾递归的列表映射 *)
let map f lst =
  let rec aux acc = function
    | [] -> List.rev acc
    | x :: xs -> aux (f x :: acc) xs
  in
  aux [] lst
```

写尾递归有个简单的判断方法：递归调用后有没有其他运算。`f (x) + 1` 不是尾递归，因为返回后还要加 1；`f (x + 1)` 是尾递归，因为递归调用就是最后一步。这个判断方法在写递归函数时很有用。

OCaml 的标准库函数大多是尾递归的。`List.map`、`List.fold_left` 都是安全的，可以放心处理大列表。但要注意 `List.fold_right` 不是尾递归的，因为 `f x (fold_right f xs init)` 里 `fold_right` 的结果还要传给 `f`。大列表应该用 `fold_left` 或者先把列表反转。

## 与 C 的互操作

OCaml 可以调用 C 函数，这对需要高性能计算或与系统库交互的场景很重要。

```c
/* hello.c */
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <stdio.h>

CAMLprim value caml_hello(value name) {
    CAMLparam1(name);
    printf("Hello from C, %s!
", String_val(name));
    CAMLreturn(Val_unit);
}

CAMLprim value caml_add(value a, value b) {
    CAMLparam2(a, b);
    int result = Int_val(a) + Int_val(b);
    CAMLreturn(Val_int(result));
}
```

```ocaml
(* hello.ml *)
external hello : string -> unit = "caml_hello"
external add : int -> int -> int = "caml_add"

let () = hello "OCaml"
let () = Printf.printf "10 + 20 = %d
" (add 10 20)
```

编译时需要把 C 代码和 OCaml 代码一起编译：

```bash
ocamlc -c hello.c
ocamlc -o hello hello.cmo hello.ml
```

C 互操作的接口需要遵循 OCaml 的 C API 规范，使用 `CAMLparam`、`CAMLreturn` 等宏来管理垃圾回收的根集合。这比 Lua 的栈式 API 复杂一些，但提供了更细粒度的控制。

## Dune：现代化的构建系统

OCaml 的构建系统经历过几次演进。早期的 `ocamlbuild` 已经被 **Dune** 取代。Dune 是一个声明式的构建系统，配置文件简单直观。

```scheme
; dune-project
(lang dune 3.0)
(name myproject)

; src/dune
(executable
 (public_name myproject)
 (name main)
 (libraries core async))

; lib/dune
(library
 (name mylib)
 (libraries base))

; test/dune
(test
 (name test_suite)
 (libraries mylib ounit2))
```

Dune 会自动处理模块依赖、编译顺序、接口文件（`.mli`）和实现文件（`.ml`）的配对。你只需写 `dune build`，它就能搞定一切。

```bash
# 创建新项目
dune init project myproject
cd myproject

# 构建
dune build

# 运行
dune exec myproject

# 测试
dune test

# 生成文档
dune build @doc

# 清理
dune clean

# 带覆盖率测试
dune runtest --instrument-with bisect_ppx
```

Dune 还支持增量编译、并行编译和缓存，大型项目的构建速度很快。Jane Street 的几十万个 OCaml 文件，用 Dune 构建也只需要几分钟。相比之下，C++ 项目同样的代码量可能要构建几小时。

## ReasonML：给 OCaml 穿一件 JavaScript 的外套

**ReasonML** 是 OCaml 的一个语法变体，用更 JavaScript/C 风格的语法写 OCaml。它是 Facebook 发起的项目，旨在降低 OCaml 的学习曲线。

```reason
/* ReasonML 语法 */
let add = (x, y) => x + y;

let rec factorial = n =>
  if (n <= 1) {
    1;
  } else {
    n * factorial(n - 1);
  };

type shape =
  | Circle(float)
  | Rectangle(float, float);

let area = shape =>
  switch (shape) {
  | Circle(r) => 3.14159 *. r *. r
  | Rectangle(w, h) => w *. h
  };

/* 列表操作 */
let numbers = [1, 2, 3, 4, 5];
let doubled = List.map(x => x * 2, numbers);
```

ReasonML 编译成 JavaScript（通过 BuckleScript/ReScript），也可以编译成原生代码。它让前端开发者能用类型安全的语言写 Web 应用，同时复用 OCaml 的整个生态系统。

不过 ReasonML 的发展有些曲折。原团队后来把重点转向了 ReScript（专注于编译到 JavaScript），ReasonML 本身的活跃度有所下降。但对于想尝试 OCaml 类型系统又不喜欢 OCaml 语法的人来说，它依然是个不错的入口。

## 总结

OCaml 是一门被严重低估的语言。它的类型系统既能保证安全性，又不会让你写一大堆类型标注。模块系统提供了比类更强大的抽象能力。尾递归优化让函数式风格的代码也能高效运行。

| 特性 | 说明 | 应用场景 |
|------|------|---------|
| 类型推导 | 自动推断类型，少写标注 | 快速开发、原型 |
| ADT | 代数数据类型描述状态 | 领域建模、编译器、协议解析 |
| 模式匹配 | 安全穷尽的分支处理 | 数据解构、状态机、编译器 |
| 模块系统 | 强大的封装和抽象 | 大型项目架构、库设计 |
| Functor | 参数化模块 | 泛型数据结构、框架 |
| 尾递归 | 递归不栈溢出 | 列表处理、迭代、树遍历 |
| Dune | 现代构建系统 | 项目管理、CI/CD |

OCaml 的编译器是我用过的最友好的编译器之一。错误信息清晰、定位准确，而且类型推导的约束检查能帮你发现大量潜在 bug。如果你厌倦了动态语言的运行时错误，又觉得 Java/C++ 的类型系统太啰嗦，OCaml 值得试一试。它的学习曲线比 Haskell 平缓，却比 Rust 更早成熟。在函数式语言的谱系中，OCaml 是一个被忽视的宝藏。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '26 days',
    NOW() - INTERVAL '26 days',
    NOW() - INTERVAL '26 days'
),
(
    1,
    'Assembly 语言入门：从机器码到寄存器',
    'assembly-language-intro',
    'assembly 不是已经死了吗？不，它活得很好。操作系统内核、密码学库、游戏引擎里的 hot path，都还在用 assembly。本文从 x86-64 架构讲起，带你理解 CPU 是怎么执行代码的。',
    $doc$
# Assembly 语言入门：从机器码到寄存器

Assembly 不是已经死了吗？

每次我说我在学汇编，都有人这么问我。事实是，assembly 活得很好。操作系统内核里到处是它，OpenSSL 的加密核心有它，Linux 的 `memcpy` 实现有它，连 Chrome 的 V8 引擎在 JIT 编译后输出的是它。只不过现在写 assembly 的人少了，它需要你的场景更具体。

我学 assembly 是因为一个调试问题。一个 C 程序在 release 模式下崩溃了，gdb 里的栈 trace 完全不对。最后发现是某个内联汇编的约束写错了，编译器把寄存器分配搞乱了。那次之后我意识到：不懂 assembly，你连自己的程序在干什么都不知道。你写的高级语言代码，最终都变成了 CPU 执行的机器指令。不理解这一层，debug 时就只能盲人摸象。

本文面向有一定 C/C++ 基础的读者，从 x86-64 架构讲起，覆盖寄存器、栈帧、系统调用、内存模型、调用约定、内联汇编和调试技巧。读完之后，你应该能读懂编译器生成的汇编代码，能在 gdb 里做基本的汇编级调试。

## x86-64 架构概览

x86-64（也叫 AMD64）是目前桌面和服务器 CPU 的主流架构。它向后兼容 32 位的 x86，但扩展到了 64 位。Intel 和 AMD 都有实现，指令集基本一致（除了一些扩展指令集如 AVX-512 有差异）。

### 通用寄存器

x86-64 有 16 个 64 位通用寄存器：

| 64 位 | 32 位 | 16 位 | 8 位 | 用途 |
|-------|-------|-------|------|------|
| `rax` | `eax` | `ax` | `al` | 累加器，返回值 |
| `rbx` | `ebx` | `bx` | `bl` | 基址寄存器 |
| `rcx` | `ecx` | `cx` | `cl` | 计数器（循环） |
| `rdx` | `edx` | `dx` | `dl` | 数据寄存器 |
| `rsi` | `esi` | `si` | `sil` | 源索引（字符串操作） |
| `rdi` | `edi` | `di` | `dil` | 目的索引（字符串操作） |
| `rbp` | `ebp` | `bp` | `bpl` | 栈帧基址 |
| `rsp` | `esp` | `sp` | `spl` | 栈指针 |
| `r8`-`r15` | `r8d`-`r15d` | `r8w`-`r15w` | `r8b`-`r15b` | 扩展寄存器 |

寄存器的命名规则是这样的：`r` 前缀表示 64 位，`e` 前缀表示 32 位（继承自 32 位时代），没有前缀的 `ax`/`bx` 是 16 位，后缀 `l` 表示低 8 位，后缀 `h` 表示高 8 位（仅 `ah`/`bh`/`ch`/`dh`）。

```asm
; 寄存器使用示例
mov rax, 0x123456789ABCDEF0    ; rax = 0x123456789ABCDEF0
mov eax, 0x12345678            ; eax = 0x12345678，rax 的高 32 位自动清零
mov ax, 0x1234                 ; ax = 0x1234
mov al, 0x12                   ; al = 0x12
```

`mov eax, value` 会把 `rax` 的高 32 位清零，这是 x86-64 的设计：写入 32 位寄存器会自动将对应的 64 位寄存器的高位置 0。这个细节在优化代码时很重要。如果你依赖 `rax` 的高 32 位保留旧值，用 `mov eax` 就会把它们清零。

### 指令格式

x86-64 的指令格式是变长的，从 1 字节到 15 字节不等：

```
[前缀] [REX前缀] [操作码] [ModR/M] [SIB] [位移] [立即数]
```

大多数指令的格式是：`操作码 目的操作数, 源操作数`

```asm
; 基本指令
mov rax, rbx        ; rax = rbx
add rax, 10         ; rax += 10
sub rax, rbx        ; rax -= rbx
inc rax             ; rax++
dec rax             ; rax--
neg rax             ; rax = -rax
not rax             ; rax = ~rax
and rax, rbx        ; rax &= rbx
or rax, rbx         ; rax |= rbx
xor rax, rax        ; rax = 0（清零寄存器的惯用写法）
cmp rax, rbx        ; 比较 rax 和 rbx（设置标志位）
test rax, rax       ; 测试 rax 是否为 0（设置标志位）
```

`xor rax, rax` 是清零寄存器的最佳方式。比 `mov rax, 0` 更短（2 字节 vs 7 字节），而且不需要立即数。现代 CPU 还会对 `xor reg, reg` 做特殊优化，避免伪依赖。

## 栈帧与函数调用

栈是从高地址向低地址增长的。`rsp` 始终指向栈顶。每次 `push` 操作把数据压入栈顶（`rsp` 减小），`pop` 操作从栈顶弹出数据（`rsp` 增大）。

```asm
; 典型的函数 prologue
push rbp            ; 保存旧的栈帧基址
mov rbp, rsp        ; 建立新的栈帧
sub rsp, 32         ; 分配 32 字节局部变量空间

; ... 函数体 ...

; 典型的函数 epilogue
mov rsp, rbp        ; 恢复栈指针
pop rbp             ; 恢复栈帧基址
ret                 ; 返回调用者
```

这是经典的 x86 函数调用约定。进入函数时，`rbp` 被保存，新的栈帧建立；退出时，栈帧恢复。不过现代编译器（gcc -O2 以上）通常不用 `rbp` 做栈帧指针，而是把它当作普通寄存器用，这样可以多一个可用寄存器。这叫 "omit frame pointer" 优化。

x86-64 的函数参数通过寄存器传递：

| 参数位置 | 整数/指针 | 浮点数 |
|---------|----------|--------|
| 第 1 个 | `rdi` | `xmm0` |
| 第 2 个 | `rsi` | `xmm1` |
| 第 3 个 | `rdx` | `xmm2` |
| 第 4 个 | `rcx` | `xmm3` |
| 第 5 个 | `r8` | `xmm4` |
| 第 6 个 | `r9` | `xmm5` |
| 第 7+ 个 | 栈 | 栈 |

返回值放在 `rax`（整数）或 `xmm0`（浮点数）。

```asm
; C 函数: int add(int a, int b)
; a 在 rdi, b 在 rsi
; 返回值在 rax

.global add
add:
    mov eax, edi        ; eax = a
    add eax, esi        ; eax += b
    ret                 ; 返回，结果在 rax
```

用 `eax` 而不是 `rax` 是因为 C 的 `int` 是 32 位。`mov eax, edi` 会自动清零 `rax` 的高 32 位，符合 System V AMD64 ABI 的要求。如果要返回 64 位值，就用 `rax`。

函数调用的完整过程：

```asm
; 调用者
main:
    push rbp
    mov rbp, rsp
    
    mov edi, 10         ; 第 1 个参数
    mov esi, 20         ; 第 2 个参数
    call add            ; 调用 add
    ; 返回值在 eax
    
    mov esi, eax        ; 准备第 2 个参数
    mov edi, 5          ; 第 1 个参数
    call add            ; 再调用一次
    
    pop rbp
    ret
```

## 系统调用：跟内核打交道

系统调用是用户态程序进入内核的唯一途径。x86-64 用 `syscall` 指令发起系统调用。

```asm
; Linux x86-64 系统调用: write(fd, buf, count)
; 系统调用号: 1 (sys_write)
; 参数: rdi=fd, rsi=buf, rdx=count

section .data
    msg db "Hello, Assembly!", 10   ; 10 是换行符
    len equ $ - msg                  ; 计算字符串长度

section .text
    global _start

_start:
    ; write(1, msg, len)
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg        ; 缓冲区地址
    mov rdx, len        ; 长度
    syscall             ; 发起系统调用

    ; exit(0)
    mov rax, 60         ; sys_exit
    mov rdi, 0          ; 退出码
    syscall
```

编译和运行：

```bash
nasm -f elf64 hello.asm -o hello.o
ld hello.o -o hello
./hello
```

x86-64 Linux 的系统调用约定：
- `rax` = 系统调用号
- `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9` = 参数 1-6
- `rcx` 和 `r11` 被 `syscall` 指令破坏
- 返回值在 `rax`，负值表示错误（-errno）

常用系统调用号：

| 系统调用 | 号 | 说明 |
|---------|---|------|
| read | 0 | 从文件描述符读 |
| write | 1 | 向文件描述符写 |
| open | 2 | 打开文件 |
| close | 3 | 关闭文件描述符 |
| mmap | 9 | 内存映射 |
| brk | 12 | 调整堆大小 |
| exit | 60 | 进程退出 |
| getpid | 39 | 获取进程 ID |
| clone | 56 | 创建线程/进程 |

系统调用的开销比函数调用大得多，因为它涉及从用户态切换到内核态。频繁的系统调用是性能瓶颈的常见来源。

## 内存模型与寻址模式

x86-64 支持多种寻址模式：

```asm
; 直接寻址
mov rax, [0x1000]       ; 从地址 0x1000 读取 8 字节

; 寄存器间接寻址
mov rax, [rbx]          ; 从 rbx 指向的地址读取

; 基址 + 位移
mov rax, [rbx + 8]      ; 从 rbx + 8 处读取
mov rax, [rbx - 16]     ; 从 rbx - 16 处读取

; 基址 + 索引 * 比例
mov rax, [rbx + rdi * 4]    ; 从 rbx + rdi*4 处读取
; 比例可以是 1, 2, 4, 8

; 完整的寻址
mov rax, [rbx + rdi * 8 + 16]   ; 从 rbx + rdi*8 + 16 处读取
```

这种灵活的寻址模式是 x86 CISC 设计的遗产。数组访问 `arr[i]` 可以一条指令完成：`mov rax, [arr + rdi * 8]`。对于 `int64_t arr[]`，比例因子是 8；对于 `int32_t arr[]`，比例因子是 4。编译器会自动选择合适的比例因子。

### 内存段

x86-64 的内存分段模型被大大简化了。Linux 下基本只有三个段：代码段、数据段、栈段。64 位模式下，段寄存器（`cs`、`ds`、`ss`）的作用被弱化，主要用于权限检查。

真正重要的是**页表**。x86-64 用 4 级页表把虚拟地址映射到物理地址。每个进程有独立的页表，由操作系统管理。

```
虚拟地址:
[CR3 -> PML4 -> PDPT -> PD -> PT -> 物理页偏移]
```

页大小通常是 4KB，但也可以配置 2MB 的大页（huge page）用于高性能场景。数据库系统和大内存应用经常用 huge page 减少 TLB miss。

## 调用约定：ABI 的细节

**调用约定**（Calling Convention）规定了函数调用时参数怎么传、寄存器谁负责保存。x86-64 主要有两种：System V AMD64 ABI（Linux/macOS）和 Microsoft x64 ABI（Windows）。

### System V AMD64 ABI（Linux/macOS）

```asm
; 调用者保存的寄存器：rax, rcx, rdx, rsi, rdi, r8-r11
; 被调用者保存的寄存器：rbx, rbp, r12-r15
; 栈必须 16 字节对齐

; 调用一个函数
my_function:
    push rbx            ; 保存被调用者保存的寄存器
    
    mov rdi, 42         ; 第 1 个参数
    mov rsi, 100        ; 第 2 个参数
    call some_function  ; 调用函数
    ; 返回值在 rax
    
    pop rbx             ; 恢复寄存器
    ret
```

栈对齐是个容易忽视的细节。`call` 指令会把返回地址压栈（8 字节），所以进入函数时 `rsp` 是 8 mod 16。如果函数要调用其他函数（尤其是用 SSE/AVX 指令的），必须先把 `rsp` 再压 8 字节，让栈保持 16 字节对齐。SSE 指令要求内存操作数 16 字节对齐，未对齐访问会导致段错误。

```asm
; 保持栈对齐
aligned_call:
    push rbp            ; +8 字节，现在 rsp 是 16 字节对齐了
    mov rbp, rsp
    
    sub rsp, 32         ; 分配 shadow space（Windows）或局部变量
    
    ; 现在可以安全调用其他函数了
    call some_sse_function
    
    mov rsp, rbp
    pop rbp
    ret
```

### Microsoft x64 ABI（Windows）

Windows 的调用约定有几个不同点：
- 调用者必须分配 32 字节的 **shadow space**（也叫 home space）
- 只有 4 个寄存器用于传参（`rcx`、`rdx`、`r8`、`r9`）
- 栈必须 16 字节对齐

```asm
; Windows x64 函数调用
windows_call:
    sub rsp, 40         ; 32 字节 shadow space + 8 字节对齐
    
    mov rcx, 42         ; 第 1 个参数
    mov rdx, 100        ; 第 2 个参数
    xor r8d, r8d        ; 第 3 个参数 = 0
    call some_function
    
    add rsp, 40         ; 恢复栈
    ret
```

写跨平台 assembly 时必须注意这些差异。这也是为什么大多数项目只在特定平台上用内联汇编，或者干脆用编译器 intrinsics。

## 内联汇编：在 C 里嵌入汇编

GCC 和 Clang 支持在 C 代码里嵌入 assembly，这叫**内联汇编**（Inline Assembly）。

```c
#include <stdint.h>

// 用汇编实现 64 位乘法，返回 128 位结果
void mul64(uint64_t a, uint64_t b, uint64_t *hi, uint64_t *lo) {
    __asm__ volatile (
        "mulq %3
	"           // rdx:rax = rax * %3
        "movq %%rdx, %0
	"    // *hi = rdx
        "movq %%rax, %1
	"    // *lo = rax
        : "=m" (*hi), "=m" (*lo)    // 输出
        : "a" (a), "r" (b)          // 输入: a 放 rax, b 放任意寄存器
        : "rdx", "cc"               // 被破坏的寄存器和标志位
    );
}
```

内联汇编的语法是：

```
asm [volatile] (汇编模板
    : 输出操作数
    : 输入操作数
    : 被破坏的寄存器
);
```

约束符（constraint）告诉编译器把 C 变量放在哪里：

| 约束 | 含义 |
|------|------|
| `r` | 通用寄存器 |
| `m` | 内存 |
| `i` | 立即数 |
| `a` | `rax`/`eax`/`ax`/`al` |
| `b` | `rbx` |
| `c` | `rcx` |
| `d` | `rdx` |
| `S` | `rsi` |
| `D` | `rdi` |
| `=` | 只写 |
| `+` | 读写 |
| `&` | 早期修改（不能与输入共享寄存器）|

内联汇编最大的坑是**约束写错**。如果告诉编译器某个寄存器被修改了但实际上没有，或者反过来，都会导致诡异的 bug。这也是为什么现代 C 代码越来越少用内联汇编，而是用 compiler intrinsics 代替。

```c
// 用 intrinsics 代替内联汇编
#include <immintrin.h>

// SIMD 加法：一次加 4 个 float
void add_floats(const float *a, const float *b, float *c) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vc = _mm_add_ps(va, vb);
    _mm_storeu_ps(c, vc);
}

// SIMD 点积
float dot_product(const float *a, const float *b) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 prod = _mm_mul_ps(va, vb);
    
    // 水平相加
    __m128 shuf = _mm_shuffle_ps(prod, prod, _MM_SHUFFLE(2, 3, 0, 1));
    __m128 sums = _mm_add_ps(prod, shuf);
    shuf = _mm_movehl_ps(shuf, sums);
    sums = _mm_add_ss(sums, shuf);
    
    return _mm_cvtss_f32(sums);
}
```

Intrinsics 是编译器内置的函数，它们直接映射到汇编指令，但让编译器负责寄存器分配和优化。这是目前推荐的做法。编译器在优化方面通常比人做得更好，尤其是在指令调度和寄存器分配上。

## 调试技巧：用 gdb 看汇编

gdb 是调试汇编代码的利器。

```bash
# 编译时保留调试信息
gcc -g -O0 program.c -o program

# 启动 gdb
gdb ./program

# 反汇编当前函数
(gdb) disassemble main

# 单步执行汇编指令
(gdb) stepi           # 执行一条指令
(gdb) nexti           # 执行一条指令，跳过函数调用

# 查看寄存器
(gdb) info registers
(gdb) print $rax
(gdb) x/10xg $rsp     # 查看栈顶 10 个 64 位值

# 在特定地址设断点
(gdb) break *0x401000

# 反汇编时显示源代码
(gdb) disassemble /s main

# 查看标志寄存器
(gdb) info registers eflags

# 以 intel 语法显示汇编
(gdb) set disassembly-flavor intel
```

objdump 也是一个有用的工具：

```bash
# 反汇编可执行文件
objdump -d ./program

# 反汇编并显示源代码
objdump -d -l ./program

# 查看符号表
objdump -t ./program

# 查看段信息
objdump -h ./program

# 只反汇编特定函数
objdump -d --disassemble=main ./program
```

### 一个调试实战

假设你遇到了一个段错误，但 gdb 的栈 trace 看起来不对。这时候应该：

```bash
(gdb) run
Program received signal SIGSEGV, Segmentation fault.

(gdb) info registers      # 看崩溃时的寄存器状态
(gdb) disassemble $pc-32,+64   # 反汇编崩溃点附近的代码
(gdb) x/10i $pc           # 看接下来要执行的 10 条指令
(gdb) x/20xg $rsp         # 看栈的内容
(gdb) info frame          # 看当前栈帧信息
(gdb) bt                  # 回溯调用栈
```

`$pc` 是程序计数器（rip 寄存器），指向当前指令。通过查看 `rip` 附近的代码和栈的内容，通常能定位到问题的根源。如果栈被破坏了，`bt` 可能显示不对，这时候需要手动跟踪 `rbp` 链或者看 `$rsp` 的内容。

## 编译器优化与汇编

看编译器生成的汇编代码，是理解优化效果的最好方法。

```bash
# 生成汇编代码
gcc -S -O0 program.c        # 无优化
gcc -S -O2 program.c        # 标准优化
gcc -S -O3 program.c        # 激进优化
gcc -S -Ofast program.c     # 更快的优化（可能不符合标准）

# 查看带注释的汇编
gcc -S -fverbose-asm -O2 program.c
```

```c
// 测试编译器优化
int square(int x) {
    return x * x;
}
```

-O0 生成的汇编：

```asm
square:
    push rbp
    mov rbp, rsp
    mov DWORD PTR [rbp-4], edi
    mov eax, DWORD PTR [rbp-4]
    imul eax, DWORD PTR [rbp-4]
    pop rbp
    ret
```

-O2 生成的汇编：

```asm
square:
    mov eax, edi
    imul eax, edi
    ret
```

编译器把多余的栈操作全部去掉了。`-O2` 下 `square` 函数只有两条指令：把参数从 `edi` 复制到 `eax`（因为返回值必须在 `eax`），然后 `imul`。这就是编译器优化的力量。

### 内联

```c
static inline int max(int a, int b) {
    return a > b ? a : b;
}

int foo(int x, int y) {
    return max(x, y) + max(x + 1, y + 1);
}
```

-O2 下，编译器会把 `max` 内联到 `foo` 里，生成类似这样的汇编：

```asm
foo:
    mov eax, edi        ; eax = x
    cmp edi, esi
    cmovge eax, edi     ; 如果 x >= y，eax = x，否则 eax 已经是 x
    ; ... 第二个 max 的内联
    lea eax, [rax + rdx]
    ret
```

`cmov` 是条件移动指令，避免了分支预测失败的代价。这在 hot path 上能带来显著的性能提升。

### 分支预测与缓存优化

现代 CPU 使用**分支预测**来推测条件跳转的方向。如果预测错误，流水线会被清空，损失十几个时钟周期。

```c
// 难以预测的分支（数据随机分布）
for (int i = 0; i < n; i++) {
    if (data[i] > threshold) {   // 分支预测容易失败
        sum += data[i];
    }
}

// 优化：排序后数据更有规律，分支预测更准
// 或者：用条件移动消除分支
for (int i = 0; i < n; i++) {
    sum += (data[i] > threshold) ? data[i] : 0;  // 编译器可能用 cmov
}
```

**缓存友好性**是另一个关键。CPU 访问内存的延迟从 L1 缓存的 4 个周期到主内存的 200+ 个周期不等。

```c
// 缓存不友好：按列访问
for (int j = 0; j < cols; j++) {
    for (int i = 0; i < rows; i++) {
        sum += matrix[i][j];  // 每次跳跃一行，cache miss
    }
}

// 缓存友好：按行访问
for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
        sum += matrix[i][j];  // 连续访问，cache hit
    }
}
```

## SIMD：一条指令处理多个数据

**SIMD**（Single Instruction Multiple Data）是现代 CPU 的标配。x86-64 的 SIMD 指令集有 SSE、AVX、AVX-512 等。

```asm
; SSE: 128 位寄存器 xmm0-xmm15
; AVX: 256 位寄存器 ymm0-ymm15
; AVX-512: 512 位寄存器 zmm0-zmm31

; SSE 浮点加法（一次加 4 个 float）
movaps xmm0, [rdi]      ; 加载 4 个 float
addps xmm0, [rsi]       ; 加 4 个 float
movaps [rdx], xmm0      ; 存储结果

; AVX 浮点加法（一次加 8 个 float）
vmovaps ymm0, [rdi]
vaddps ymm0, ymm0, [rsi]
vmovaps [rdx], ymm0

; AVX-512 浮点加法（一次加 16 个 float）
vmovaps zmm0, [rdi]
vaddps zmm0, zmm0, [rsi]
vmovaps [rdx], zmm0
```

SIMD 是 assembly 在现代 CPU 上最有价值的应用场景之一。编译器的 auto-vectorization 虽然越来越好，但在特定场景下，手写 SIMD 仍然能带来显著的性能提升。尤其是图像处理、音频处理、密码学、数值计算这些领域。

不过手写 SIMD 的维护成本很高。代码一旦写好，要移植到不支持某些指令集的 CPU 上就很麻烦。通常的做法是用编译器 intrinsics，让编译器根据目标 CPU 选择合适的指令。

## 总结

Assembly 不是要你天天写的语言，但它是理解计算机如何工作的窗口。当你知道每条 C 语句背后发生了什么，当你能在 gdb 里读懂反汇编的输出，当你能判断编译器的优化是否合理——这时候你就真正掌控了你的程序。

| 主题 | 关键概念 |
|------|---------|
| 寄存器 | rax-r15，32/64 位别名，调用约定 |
| 栈帧 | rbp/rsp，prologue/epilogue |
| 系统调用 | syscall 指令，参数寄存器，调用号 |
| 寻址 | 基址+索引*比例+位移 |
| 调用约定 | 参数寄存器，调用者/被调用者保存寄存器 |
| 内联汇编 | 约束，输入/输出，被破坏寄存器 |
| 调试 | gdb disassemble，info registers |
| SIMD | SSE/AVX，向量化计算 |

学习 assembly 最好的方式是：写一段 C 代码，编译成汇编，读它，改它，再编译。反复几次，CPU 的执行模型就会印在你的脑子里。你可以从简单的函数开始，比如阶乘、字符串复制、数组求和，然后逐步深入到更复杂的算法。

现代软件开发中，assembly 的应用场景越来越窄，但它在特定领域依然不可替代：操作系统内核、驱动程序、密码学、实时系统、游戏引擎的渲染管线。掌握 assembly 不是为了用它写整个项目，而是为了在需要的时候能读懂它、能调试它、能在关键路径上优化它。

> "如果你不知道 assembly，那你就不懂计算机。" —— 这话有点极端，但方向是对的。至少，不懂 assembly 的话，你不懂你的程序到底在干什么。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '27 days',
    NOW() - INTERVAL '27 days',
    NOW() - INTERVAL '27 days'
),
-- ============================================================
-- 新增文章（2026 年补充）
-- ============================================================
(
    1,
    'Docker 容器化技术完全指南：从入门到生产部署',
    'docker-deep-dive',
    '本文从架构设计、镜像构建、容器编排到生产部署，全面讲解 Docker 技术栈。涵盖命名空间、cgroups、UnionFS 等内核级原理，以及 compose、多阶段构建和安全加固实践。',
    $doc$
# Docker 容器化技术完全指南：从入门到生产部署

## 前言

我第一次接触 Docker 是在 2016 年。当时团队在用虚拟机部署微服务，每个服务需要单独的 CentOS 镜像，配环境就得花半小时。有一次我本地跑得好好的 Python 脚本，部署到服务器上死活报错，折腾了一下午才发现是 OpenSSL 版本不一致。这种"在我机器上能跑"的问题，在容器化出现之前几乎是每个后端工程师的噩梦。

Docker 改变了这个局面。它用一种轻量级的方式把应用和它的运行环境打包在一起，确保在任何地方都能一致地运行。但 Docker 不仅仅是一个部署工具，它的内核原理、网络模型和存储机制都值得深入理解。这篇文章会从底层原理讲起，覆盖从开发到生产的完整流程。

---

## 一、Docker 架构与核心概念

### 1.1 整体架构

Docker 采用客户端-服务端（C/S）架构。用户通过 Docker CLI 发送命令，Docker 守护进程（dockerd）负责实际的容器管理。

```
┌─────────────────────────────────────────────────────┐
│                    Docker Client                     │
│                  (docker CLI)                        │
└───────────────────────┬─────────────────────────────┘
                        │ REST API
┌───────────────────────▼─────────────────────────────┐
│                   Docker Daemon                      │
│                 (dockerd)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  镜像管理    │  │  容器管理    │  │  网络管理    │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└───────────────────────┬─────────────────────────────┘
                        │ containerd
┌───────────────────────▼─────────────────────────────┐
│              containerd-shim                          │
│              runc (OCI runtime)                       │
└─────────────────────────────────────────────────────┘
```

dockerd 不直接管理容器，它把任务交给 containerd，containerd 再通过 containerd-shim 启动 runc。runc 是符合 OCI（Open Container Initiative）标准的运行时，负责创建和运行容器。这个分层设计的好处是：即使 dockerd 崩溃，已经在运行的容器不会受到影响。

### 1.2 镜像 vs 容器

新手最容易混淆的概念。镜像是只读的模板，容器是镜像的运行实例。类比一下：镜像相当于一个 Class，容器就是这个 Class 的 Instance。

镜像由多层只读文件系统叠加而成。你拉取一个 nginx:latest 镜像，Docker 会下载多个层——基础系统层、nginx 安装层、配置层。容器在镜像之上加了一个可写层，所有的文件修改都发生在这个可写层里。

```bash
# 查看镜像的分层结构
docker history nginx:latest

# 查看容器的可写层
docker inspect <container_id> | grep -A 5 "GraphDriver"
```

### 1.3 Registry 与仓库

Registry 是存放镜像的服务。Docker Hub 是最大的公共 Registry，企业通常搭建私有 Registry。仓库（Repository）是同一镜像不同版本的集合，比如 nginx:1.24、nginx:1.25 属于同一个仓库。

```bash
# 拉取镜像（默认从 Docker Hub）
docker pull nginx:1.25

# 推送镜像到私有 Registry
docker tag myapp:latest registry.example.com/myapp:v1
docker push registry.example.com/myapp:v1
```

---

## 二、Docker 镜像深入解析

### 2.1 镜像分层原理

Docker 镜像的核心是 UnionFS（联合文件系统）。每一层都是只读的，当需要修改文件时，Docker 会在最上层创建一个副本进行修改。这个过程叫 Copy-on-Write（写时复制）。

```dockerfile
# 一个典型的 Dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3 python3-pip
COPY requirements.txt /app/
RUN pip3 install -r /app/requirements.txt
COPY . /app/
WORKDIR /app
CMD ["python3", "app.py"]
```

这个 Dockerfile 会生成 5 层：ubuntu:22.04 基础层、apt-get 安装层、COPY requirements.txt 层、pip install 层、COPY 源码层。每层都有唯一的 SHA256 摘要。如果两个镜像有相同的层，Docker 会复用，不重复存储。这就是为什么拉取镜像比复制整个虚拟机快得多。

### 2.2 构建缓存机制

Docker 构建时会逐层检查缓存。如果某一层没有变化，就直接复用缓存。一旦某一层发生变化，它之后的所有层都需要重新构建。

```dockerfile
# 不好的写法：缓存容易失效
COPY . /app/
RUN pip3 install -r /app/requirements.txt

# 好的写法：先复制依赖文件，再复制源码
COPY requirements.txt /app/
RUN pip3 install -r /app/requirements.txt
COPY . /app/
```

Docker 20.10 以后支持 BuildKit，它提供了更精细的缓存控制。

### 2.3 多阶段构建

多阶段构建解决了一个长期问题：构建环境和运行环境分离。很多编译型语言（Go、Rust、Java）在构建时需要完整的工具链，但运行时只需要二进制文件。

```dockerfile
# 构建阶段
FROM golang:1.21-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server .

# 运行阶段
FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

最终镜像只包含一个静态编译的二进制文件和 SSL 证书，大小可能只有几十 MB，而构建阶段的 Alpine 镜像有几百 MB。

### 2.4 镜像优化技巧

几个要点：用 alpine 或 distroless 基础镜像，不要用 ubuntu；`--only=production` 跳过 devDependencies；最后用 USER 指令切换到非 root 用户；合并 RUN 指令减少层数。

---

## 三、容器网络

### 3.1 网络驱动

Docker 提供了多种网络驱动：bridge（单机多容器）、host（高性能网络）、overlay（跨主机通信）、macvlan（需要独立 MAC 地址）、none（完全隔离）。默认的 bridge 网络有个限制：容器之间只能通过 IP 通信，不能通过容器名。自定义 bridge 网络支持 DNS 解析。

### 3.2 容器间通信原理

在 bridge 网络中，每个容器都有自己的网络命名空间。Docker 通过 veth pair（虚拟以太网设备对）连接容器和宿主机的 docker0 网桥。iptables 规则负责 NAT 和端口映射。

### 3.3 自定义网络配置

生产环境中，默认的网络配置通常不够用。你需要调整 MTU、定义子网、配置 DNS。禁用 IP masquerade 可以避免 Docker 的 NAT 干扰容器获取真实客户端 IP。

---

## 四、数据持久化：Volume 与 Bind Mount

### 4.1 三种存储类型

Docker 有三种主要的持久化方式：Volume（Docker 管理的存储区域）、Bind Mount（直接挂载宿主机目录到容器）、tmpfs（挂载到内存）。Volume 推荐用于数据库等有状态服务，Bind Mount 推荐用于开发时的代码同步。

### 4.2 Volume vs Bind Mount 对比

Volume 由 Docker 管理，跨平台兼容，但备份需要额外操作。Bind Mount 直接复制目录即可备份，但路径依赖宿主机。开发环境倾向用 Bind Mount，生产环境用 Volume。

---

## 五、Docker Compose

### 5.1 基础配置

docker-compose.yml 是定义多容器应用的标准方式。一个典型的 Web 应用可能包含 Web 服务器、应用服务器和数据库。depends_on 控制启动顺序，但有坑：它只等待容器启动，不等待服务就绪。用 healthcheck + condition 才能确保真正的就绪。

### 5.2 环境变量与 Secrets

`.env` 文件存放默认值，`.env.production` 存放生产配置。注意不要把 `.env` 提交到 Git。Docker BuildKit Secrets 可以在构建时使用密码但不留在镜像层。

### 5.3 Profiles 与选择性启动

Profiles 可以按场景分组服务，用 `docker compose --profile production up` 只启动特定 profile 下的服务。

---

## 六、Dockerfile 最佳实践

### 6.1 指令优化顺序

Dockerfile 的指令顺序影响构建缓存效率。把变化频率低的指令放前面，变化频率高的放后面。基础镜像放最前面，应用代码放最后面。

### 6.2 安全相关实践

使用 `COPY --chown` 避免后续 chown 操作；用 `npm cache clean --force` 清理缓存减小镜像体积；不要在镜像里硬编码密码或密钥；用 `.dockerignore` 排除敏感文件。

### 6.3 健康检查

健康检查配合 `restart: unless-stopped` 可以实现自动重启。

---

## 七、Docker 安全加固

### 7.1 Linux 内核隔离机制

Docker 的安全模型建立在 Linux 内核的几个关键特性上：Namespace 提供进程隔离，cgroups 限制容器的资源使用，UnionFS 提供文件系统隔离。

### 7.2 容器逃逸防护

不要用 `--privileged` 模式运行容器；只授予必要的能力；禁止容器获取新权限；使用只读文件系统。

### 7.3 镜像安全扫描

使用 Trivy 或 Docker Scout 扫描镜像漏洞。

---

## 八、生产环境部署

### 8.1 日志管理

Docker 默认的日志驱动是 json-file，生产环境需要配置日志轮转。对于集中式日志收集，推荐用 syslog 或 journald 驱动。

### 8.2 资源限制

生产环境必须设置资源限制，防止某个容器拖垮整个宿主机。limits 是上限，reservations 是保证的最低资源。

### 8.3 重启策略

生产环境用 `unless-stopped` 最合适。

### 8.4 滚动更新

`order: start-first` 先启动新容器，再停止旧容器，确保零停机时间。`failure_action: rollback` 在更新失败时自动回滚。

---

## 九、Docker 底层原理

### 9.1 Namespace 详解

Linux Namespace 是容器隔离的基础。Docker 使用了 7 种 Namespace：PID、NET、MNT、UTS、IPC、USER、CGROUP。

### 9.2 Cgroups v2

现代 Linux 发行版默认使用 cgroups v2，它提供了更精细的资源控制：memory.swap.max、io.latency、cpu.weight。

### 9.3 OverlayFS

Docker 默认使用 OverlayFS（overlay2 存储驱动）来实现分层文件系统。当容器删除时，可写层的数据也会丢失。

---

## 十、实战案例

文中覆盖了 Python Django、Go 微服务、Java Spring Boot 三种典型项目的 Docker 化部署方案，包括 Dockerfile 编写和 docker-compose 配置。

---

## 十一、常见问题与排查

容器无法启动时查看日志和退出码；网络问题测试连通性和 DNS 解析；磁盘空间不足用 `docker system df` 和 `docker system prune` 清理；性能问题用 `docker stats` 监控。

---

## 结尾

这篇文章覆盖了 Docker 从基础概念到生产部署的主要知识点。Docker 是整个容器化生态的基础，理解它的内核原理和最佳实践，才能更好地使用上层工具。

建议从搭建一个完整的本地开发环境开始，用 docker-compose 把你常用的数据库、缓存、消息队列都跑起来，写一个简单的 Web 应用部署到上面。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '15 days'
),
(
    1,
    'Kubernetes 集群管理与编排实战',
    'kubernetes-guide',
    '从 Pod 调度到 Service 网络，从 Helm Charts 到 GitOps 工作流，全面讲解 Kubernetes 集群管理与生产部署实践。',
    $doc$
# Kubernetes 集群管理与编排实战

## 前言

Kubernetes（简称 K8s）已经成为容器编排的事实标准。如果你在用 Docker Compose 管理生产环境，迟早会遇到它的天花板：单机部署、没有自动故障转移、没有滚动更新、没有服务发现。当你开始面对这些问题的时候，就是该上 Kubernetes 的时候了。

这篇文章不是 K8s 的入门教程，官方文档和教程已经写得很好了。我想分享的是在实际生产环境中积累的经验——那些文档里不会告诉你、但你迟早会踩的坑。

---

## 一、核心架构

### 1.1 控制平面

Kubernetes 的控制平面（Control Plane）由几个核心组件组成：

- **kube-apiserver**：所有操作的入口，REST API 服务器
- **etcd**：分布式键值存储，保存集群的所有状态
- **kube-scheduler**：决定 Pod 运行在哪个节点
- **kube-controller-manager**：运行各种控制器，确保集群状态符合期望

控制平面的高可用很重要。生产环境至少要有 3 个 master 节点，etcd 也要做集群。我见过单 master 的集群在生产环境挂掉之后，整个集群不可用长达半小时的情况。

### 1.2 工作节点

每个工作节点（Worker Node）运行几个关键组件：

- **kubelet**：节点上的代理，负责管理 Pod 的生命周期
- **kube-proxy**：维护节点上的网络规则，实现 Service 的负载均衡
- **容器运行时**：containerd 或 CRI-O

节点的资源管理很关键。每个节点都有资源配额，调度器根据这些配额来决定 Pod 放在哪里。用 `kubectl describe node <node-name>` 可以查看节点的资源使用情况。

---

## 二、Pod 与调度

### 2.1 Pod 设计原则

Pod 是 K8s 中最小的调度单元。一个 Pod 可以包含一个或多个容器，它们共享网络命名空间和存储卷。

什么时候该用多容器 Pod？最常见的模式是 sidecar。比如在应用 Pod 旁边放一个日志收集容器，或者放一个 envoy 代理做服务网格。但不要把不相关的服务塞到同一个 Pod 里——它们应该独立扩缩容。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  containers:
  - name: app
    image: my-app:1.0
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
  - name: sidecar-log-agent
    image: log-agent:1.0
```

### 2.2 资源请求与限制

resources.requests 告诉调度器这个 Pod 需要多少资源，resources.limits 告诉 K8s 这个 Pod 最多能用多少资源。requests 影响调度决策，limits 影响运行时行为。

CPU 超限不会被杀掉，只会被限流。内存超限会触发 OOMKilled。这个区别很重要——很多"我的 Pod 怎么被杀了"的问题都是因为内存 limits 设太低。

### 2.3 调度策略

Kubernetes 的调度器根据多种因素来决定 Pod 运行在哪个节点：资源可用性、亲和性/反亲和性、污点和容忍、拓扑约束。

```yaml
# 节点亲和性：只调度到有 SSD 的节点
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disk-type
          operator: In
          values:
          - ssd

# Pod 反亲和性：同一 Deployment 的 Pod 分散到不同节点
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - my-app
      topologyKey: kubernetes.io/hostname
```

### 2.4 污点与容忍

Taint 和 Toleration 配合使用。Taint 加在节点上，表示"不容忍这个 taint 的 Pod 不能调度到这个节点"。Toleration 加在 Pod 上，表示"我可以容忍这个 taint"。

```bash
# 给节点加 taint
kubectl taint nodes node1 dedicated=gpu:NoSchedule

# Pod 需要 toleration 才能调度到这个节点
```

---

## 三、工作负载

### 3.1 Deployment

Deployment 管理无状态应用的副本集。它支持滚动更新和回滚。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: my-app:2.0
        ports:
        - containerPort: 8080
```

maxSurge 和 maxUnavailable 的设置很关键。maxUnavailable 设为 0 确保更新过程中始终有足够的 Pod 在服务请求。

### 3.2 StatefulSet

StatefulSet 管理有状态应用。每个 Pod 有稳定的网络标识（pod-0, pod-1, ...）和持久的存储。数据库、消息队列、ZooKeeper 这类需要稳定标识的服务应该用 StatefulSet。

### 3.3 DaemonSet

DaemonSet 确保每个节点（或指定节点）运行一个 Pod。日志收集、监控代理、网络插件这些基础设施组件适合用 DaemonSet。

### 3.4 Job 和 CronJob

Job 运行一次性任务，CronJob 按计划运行任务。批处理任务、数据迁移、定时备份适合用这些资源。

---

## 四、服务发现与网络

### 4.1 Service 类型

- **ClusterIP**（默认）：只在集群内部可达
- **NodePort**：在每个节点上开放一个端口
- **LoadBalancer**：创建云厂商的负载均衡器
- **ExternalName**：映射到外部 DNS 名称

大多数微服务之间的通信用 ClusterIP 就够了。只有需要外部访问的服务才用 LoadBalancer 或 NodePort。

### 4.2 Ingress

Ingress 是 HTTP 层的路由规则，把外部流量转发到集群内的 Service。Nginx Ingress Controller、Traefik、HAProxy 是常用的 Ingress Controller。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: api-v2
            port:
              number: 80
```

### 4.3 Network Policy

NetworkPolicy 是集群内部的防火墙规则，控制 Pod 之间的通信。默认情况下所有 Pod 之间都能互相通信，这在生产环境是不安全的。

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## 五、配置管理与 Secrets

### 5.1 ConfigMap

ConfigMap 存储非敏感的配置数据。可以通过环境变量或挂载文件的方式注入到 Pod 中。

### 5.2 Secrets

Secrets 存储敏感数据（密码、密钥、证书）。注意：Secrets 默认只是 base64 编码，不是加密。生产环境应该启用 etcd 加密或使用外部密钥管理（如 Vault）。

---

## 六、存储

### 6.1 Persistent Volume

PV（Persistent Volume）是集群级别的存储资源，PVC（Persistent Volume Claim）是 Pod 对存储的申请。StorageClass 定义了存储的类型和供应方式。

有状态应用（数据库、消息队列）必须使用持久化存储。无状态应用如果需要缓存或临时数据，可以用 emptyDir。

---

## 七、Helm

### 7.1 为什么用 Helm

Helm 是 K8s 的包管理器。它把相关的 K8s 资源打包成 Chart，支持模板化、版本管理和一键部署。没有 Helm 的话，管理几十个微服务的 K8s 清单文件是噩梦。

### 7.2 Chart 结构

```yaml
my-chart/
  Chart.yaml
  values.yaml
  templates/
    deployment.yaml
    service.yaml
    ingress.yaml
    configmap.yaml
```

values.yaml 定义默认配置，templates 下的文件用 Go 模板语法渲染。

### 7.3 Helm 最佳实践

把 Chart 发布到私有仓库（如 Harbor），每次部署使用特定版本号。不要在生产环境用 `latest` tag。用 `helm diff` 查看变更再部署。

---

## 八、监控与日志

### 8.1 Prometheus + Grafana

Prometheus 是 K8s 生态中最常用的监控方案。它通过 Service Discovery 自动发现集群中的 Pod 和 Service，抓取指标数据。Grafana 提供可视化面板。

### 8.2 日志收集

EFK（Elasticsearch + Fluentd + Kibana）或 PLG（Promtail + Loki + Grafana）是两种主流的日志方案。Fluentd/Promtail 作为 DaemonSet 运行在每个节点上，收集容器日志。

---

## 九、安全

### 9.1 RBAC

Role-Based Access Control 控制谁可以对哪些资源执行哪些操作。最小权限原则：只给用户和程序需要的最小权限。

### 9.2 Pod Security Standards

Kubernetes 1.25+ 移除了 PodSecurityPolicy，用 Pod Security Admission 替代。它定义了三个级别：privileged、baseline、restricted。

### 9.3 镜像安全

使用 Trivy 扫描镜像漏洞；只从可信的 Registry 拉取镜像；使用 ImagePolicyWebhook 禁止使用 latest tag。

---

## 十、GitOps

### 10.1 ArgoCD

ArgoCD 是 K8s 原生的 GitOps 工具。它监听 Git 仓库的变化，自动同步集群状态到 Git 中定义的期望状态。

### 10.2 Flux

Flux 是另一个流行的 GitOps 工具，由 Weaveworks 开发。它的架构更模块化，支持多种来源（Git、Helm、OCI）。

---

## 结尾

Kubernetes 的学习曲线很陡，但一旦你的集群稳定运行起来，它带来的效率提升是显著的。从一个小集群开始，先把无状态服务迁移上去，积累经验后再处理有状态服务。不要试图一步到位——K8s 生态太庞大了，一步一步来。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '14 days',
    NOW() - INTERVAL '14 days',
    NOW() - INTERVAL '14 days'
),
(
    1,
    'Redis 数据结构与实战应用完全指南',
    'redis-complete-guide',
    '从底层数据结构到分布式集群，覆盖 Redis 五种基础数据结构、发布订阅、Lua 脚本、持久化机制、集群方案和性能优化实践。',
    $doc$
# Redis 数据结构与实战应用完全指南

## 前言

我第一次用 Redis 是因为一个简单的需求：给接口加个计数器，限制用户每分钟最多请求 60 次。用数据库做计数器，每次请求都要 UPDATE 一行记录，在高并发下数据库很快就扛不住了。换成 Redis 的 INCR 命令，问题瞬间解决。

后来我发现 Redis 能做的事情远不止计数器。缓存、会话存储、消息队列、分布式锁、排行榜、地理位置——几乎每个 Web 应用都能从 Redis 中受益。但要用好 Redis，你需要理解它的数据结构和内部实现。

---

## 一、Redis 基础

### 1.1 为什么 Redis 这么快

几个原因：纯内存操作、单线程模型（避免了锁竞争）、IO 多路复用（epoll）、高效的数据结构（SDS、ziplist、quicklist、skiplist、intset、hashtable）。

Redis 6.0 引入了多线程 IO，但核心的命令执行仍然是单线程。这保证了原子性，不需要加锁。

### 1.2 安装与配置

```bash
# macOS
brew install redis

# 启动
redis-server

# 连接
redis-cli
```

关键配置项：

```conf
# 绑定地址
bind 127.0.0.1

# 保护模式
protected-mode yes

# 端口
port 6379

# 数据库数量
databases 16

# 密码
requirepass your-password

# 最大内存
maxmemory 1gb

# 内存淘汰策略
maxmemory-policy allkeys-lru
```

---

## 二、五种基础数据结构

### 2.1 String

String 是最基础的数据类型。可以存储字符串、整数、浮点数，以及二进制数据（最大 512MB）。

```bash
# 基本操作
SET key value
GET key
MSET key1 value1 key2 value2
MGET key1 key2

# 原子操作
INCR counter          # +1
INCRBY counter 10     # +10
DECR counter          # -1
APPEND key "world"    # 追加

# 设置过期时间
SET token abc123 EX 3600    # 1小时过期
SETNX key value             # 不存在时设置（分布式锁基础）
```

String 的应用场景：缓存、会话存储、分布式锁、计数器、限流。

### 2.2 Hash

Hash 是键值对的集合，适合存储对象。

```bash
# 存储用户信息
HSET user:1001 name "Alice" email "alice@example.com" age 30

# 获取字段值
HGET user:1001 name

# 获取所有字段
HGETALL user:1001

# 检查字段是否存在
HEXISTS user:1001 email

# 增加数字字段
HINCRBY user:1001 age 1
```

Hash 相比 String 存储对象的优势：可以只读写部分字段，不需要序列化整个对象。当字段少的时候，Redis 用 ziplist 存储，内存效率很高。

### 2.4 List

List 是有序的字符串列表，支持从两端插入和弹出。

```bash
# 从右端推入
RPUSH queue task1 task2 task3

# 从左端弹出
LPOP queue

# 阻塞弹出（队列为空时等待）
BLPOP queue 30    # 最多等待30秒

# 获取范围
LRANGE queue 0 -1    # 获取所有元素
LRANGE queue 0 9     # 获取前10个元素

# 修剪列表
LTRIM queue 0 99    # 只保留前100个元素
```

List 的应用场景：消息队列、任务队列、最新动态列表。BLPOP 可以实现简单的阻塞队列。

### 2.5 Set

Set 是无序的字符串集合，支持交集、并集、差集运算。

```bash
# 添加元素
SADD tags:post:1 "redis" "database" "cache"

# 检查元素是否存在
SISMEMBER tags:post:1 "redis"

# 获取所有元素
SMEMBERS tags:post:1

# 交集（共同标签）
SINTER tags:post:1 tags:post:2

# 并集
SUNION tags:post:1 tags:post:2

# 差集
SDIFF tags:post:1 tags:post:2
```

Set 的应用场景：标签系统、好友关系、去重、抽奖。

### 2.6 Sorted Set（ZSet）

ZSet 是有序的字符串集合，每个元素关联一个分数（score），按分数排序。

```bash
# 添加元素
ZADD leaderboard 100 "player:1" 200 "player:2" 150 "player:3"

# 获取排名（分数从高到低）
ZREVRANGE leaderboard 0 9 WITHSCORES

# 获取某人的排名
ZREVRANK leaderboard "player:1"

# 增加分数
ZINCRBY leaderboard 50 "player:1"

# 按分数范围查询
ZRANGEBYSCORE leaderboard 100 200
```

ZSet 的应用场景：排行榜、延迟队列（score 存时间戳）、范围查询。

---

## 三、高级数据结构

### 3.1 HyperLogLog

HyperLogLog 用于基数统计（统计集合中不同元素的数量）。它的优势是无论集合有多少元素，始终只占用 12KB 内存。

```bash
# 统计 UV（独立访客）
PFADD uv:20240101 "user1" "user2" "user3"
PFADD uv:20240101 "user1" "user4"    # user1 重复，不计数

# 获取 UV 数
PFCOUNT uv:20240101    # 返回 4
```

### 3.2 Bitmap

Bitmap 是位数组，可以对位进行操作。

```bash
# 签到打卡
SETBIT sign:user:1001:202401 0 1    # 第1天打卡
SETBIT sign:user:1001:202401 1 1    # 第2天打卡

# 统计打卡天数
BITCOUNT sign:user:1001:202401

# 判断某天是否打卡
GETBIT sign:user:1001:202401 0
```

### 3.3 Stream

Stream 是 Redis 5.0 引入的消息队列数据结构，支持消费者组、消息确认、消息持久化。

```bash
# 发送消息
XADD mystream * name "Alice" action "login"

# 读取消息
XREAD COUNT 10 STREAMS mystream 0

# 创建消费者组
XGROUP CREATE mystream mygroup $ MKSTREAM

# 消费者读取
XREADGROUP GROUP mygroup consumer1 COUNT 1 STREAMS mystream >

# 确认消息
XACK mystream mygroup 1234567890-0
```

Stream 相比 List 实现的消息队列的优势：支持消费者组、消息确认、消息持久化、回溯消费。

---

## 四、过期与淘汰策略

### 4.1 设置过期时间

```bash
# 设置过期时间
EXPIRE key 3600        # 1小时
PEXPIRE key 3600000    # 1小时（毫秒）

# 设置带过期时间的值
SETEX key 3600 value

# 查看剩余过期时间
TTL key

# 取消过期时间
PERSIST key
```

### 4.2 内存淘汰策略

当 Redis 内存达到 maxmemory 时，根据策略淘汰键：

- **noeviction**：不淘汰，写入操作报错
- **allkeys-lru**：淘汰所有键中最久未使用的
- **volatile-lru**：淘汰设有过期时间的键中最久未使用的
- **allkeys-random**：随机淘汰
- **volatile-random**：随机淘汰设有过期时间的键
- **volatile-ttl**：淘汰设有过期时间且 TTL 最小的键
- **allkeys-lfu**：淘汰所有键中最不经常使用的
- **volatile-lfu**：淘汰设有过期时间的键中最不经常使用的

大多数场景用 allkeys-lru 或 allkeys-lfu。

---

## 五、持久化机制

### 5.1 RDB

RDB 是快照持久化，在指定时间间隔内把内存数据写入磁盘。

```conf
# redis.conf
save 900 1      # 900秒内有1次写入就触发快照
save 300 10     # 300秒内有10次写入就触发快照
save 60 10000   # 60秒内有10000次写入就触发快照
```

RDB 的优点是恢复速度快，缺点是有数据丢失风险（最后一次快照到宕机之间的数据）。

### 5.2 AOF

AOF 记录每个写操作命令，Redis 重启时重放命令恢复数据。

```conf
# redis.conf
appendonly yes
appendfsync everysec    # 每秒同步一次
```

AOF 的优点是数据丢失少（最多丢1秒数据），缺点是文件体积大、恢复速度慢。

### 5.3 混合持久化

Redis 4.0+ 支持混合持久化：AOF 重写时，先写入 RDB 格式的全量数据，再追加增量 AOF 命令。

---

## 六、发布订阅

```bash
# 订阅频道
SUBSCRIBE news

# 发布消息
PUBLISH news "Breaking news: ..."

# 模式订阅
PSUBSCRIBE news.*
```

Pub/Sub 的问题是消息不持久化，订阅者离线期间的消息会丢失。如果需要可靠的消息传递，用 Stream。

---

## 七、Lua 脚本

Redis 支持在服务端执行 Lua 脚本，可以实现原子操作。

```bash
# 原子操作：检查并设置
EVAL "
  if redis.call('GET', KEYS[1]) == ARGV[1] then
    return redis.call('SET', KEYS[2], ARGV[2])
  else
    return 0
  end
" 2 key1 key2 old_value new_value
```

Lua 脚本在 Redis 中是原子执行的，不需要加锁。分布式锁的实现常用 Lua 脚本来保证检查和设置的原子性。

---

## 八、分布式锁

### 8.1 基本实现

```bash
# 加锁（原子操作）
SET lock:order:123 owner-uuid NX EX 30

# 解锁（需要原子检查）
EVAL "
  if redis.call('GET', KEYS[1]) == ARGV[1] then
    return redis.call('DEL', KEYS[1])
  else
    return 0
  end
" 1 lock:order:123 owner-uuid
```

### 8.2 Redlock 算法

单个 Redis 实例的分布式锁在主从切换时可能丢失锁。Redlock 算法通过在多个独立的 Redis 实例上加锁来提高可靠性。

但 Redlock 也有争议。Martin Kleppmann 在他的文章中指出了 Redlock 的几个潜在问题，包括时钟漂移和 GC 暂停。实际使用中，大多数场景单实例 Redis 锁加上合理的过期时间就够了。

---

## 九、集群方案

### 9.1 Redis Sentinel

Sentinel 是 Redis 的高可用方案。它监控主从节点的状态，主节点挂掉时自动故障转移。

Sentinel 的优点是部署简单，缺点是不能水平扩展（数据量受限于单机内存）。

### 9.2 Redis Cluster

Cluster 是 Redis 的分布式方案，数据分片存储在多个节点上。16384 个哈希槽分布在多个节点上。

Cluster 的优点是支持水平扩展，缺点是有些命令受限（如多 key 操作需要使用 hash tag）。

---

## 十、性能优化

### 10.1 Pipeline

Pipeline 把多个命令打包发送，减少网络往返。

```python
import redis

r = redis.Redis()
pipe = r.pipeline()
for i in range(10000):
    pipe.set(f'key:{i}', f'value:{i}')
pipe.execute()
```

### 10.2 大 Key 问题

大 Key 会导致阻塞、内存不均衡、网络拥塞。用 `redis-cli --bigkeys` 扫描大 Key。

### 10.3 热 Key 问题

热 Key 是访问频率特别高的 Key，会导致单节点过载。解决方案：本地缓存、Key 分散（加后缀）、读写分离。

---

## 结尾

Redis 的强大在于它的灵活性。理解了五种基础数据结构和它们的内部实现，你就能用 Redis 解决各种各样的问题。不要把 Redis 当成万能的——它最适合的场景是读多写少、数据量不太大、对延迟敏感的场景。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '13 days',
    NOW() - INTERVAL '13 days',
    NOW() - INTERVAL '13 days'
),
(
    1,
    'PostgreSQL 高级特性与性能优化实战',
    'postgresql-advanced',
    '从索引原理到查询优化，从 JSONB 到全文搜索，从分区表到复制高可用，深入讲解 PostgreSQL 高级特性和生产环境调优。',
    $doc$
# PostgreSQL 高级特性与性能优化实战

## 前言

我从 MySQL 转到 PostgreSQL 是因为一个需求：需要在数据库层面做全文搜索，同时还要支持 JSON 数据的灵活查询。MySQL 能做，但 PostgreSQL 做得更好。用了几年之后，我发现 PostgreSQL 的能力远不止这些——窗口函数、CTE、JSONB、分区表、物化视图、逻辑复制，每一个特性在特定场景下都能带来巨大的价值。

这篇文章是我使用 PostgreSQL 的经验总结，重点放在那些在实际项目中经常用到的高级特性和性能优化技巧。

---

## 一、索引深入理解

### 1.1 B-Tree 索引

B-Tree 是 PostgreSQL 最常用的索引类型。它适合等值查询和范围查询。

```sql
-- 创建索引
CREATE INDEX idx_users_email ON users (email);

-- 复合索引
CREATE INDEX idx_orders_user_status ON orders (user_id, status);

-- 部分索引（只索引满足条件的行）
CREATE INDEX idx_orders_pending ON orders (created_at) WHERE status = 'pending';
```

部分索引的好处：只索引需要的部分，减少索引大小，提高写入性能。

### 1.2 GIN 索引

GIN（Generalized Inverted Index）是倒排索引，适合全文搜索和 JSONB 查询。

```sql
-- 全文搜索索引
CREATE INDEX idx_posts_search ON posts USING GIN (
  to_tsvector('english', title || ' ' || content)
);

-- JSONB 索引
CREATE INDEX idx_events_data ON events USING GIN (data);

-- JSONB 路径索引
CREATE INDEX idx_events_type ON events USING BTREE ((data ->> 'type'));
```

### 1.3 GiST 索引

GiST（Generalized Search Tree）适合几何数据、范围类型和全文搜索。

```sql
-- 地理位置索引
CREATE INDEX idx_locations_coords ON locations USING GiST (coords);

-- 范围类型索引
CREATE INDEX idx_events_period ON events USING GiST (period);
```

### 1.4 BRIN 索引

BRIN（Block Range Index）适合物理顺序和逻辑顺序一致的大表。比如按时间插入的日志表。

```sql
-- BRIN 索引，体积小但对有序数据效果好
CREATE INDEX idx_logs_created ON logs USING BRIN (created_at);
```

BRIN 索引的优势是体积小（通常是 B-Tree 的几分之一），创建速度快。对于 TB 级的日志表，BRIN 索引比 B-Tree 索引更合适。

---

## 二、查询优化

### 2.1 EXPLAIN ANALYZE

EXPLAIN ANALYZE 是优化查询最重要的工具。它会实际执行查询并显示执行计划。

```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';
```

关键指标：
- **Seq Scan**：全表扫描，大表上要避免
- **Index Scan**：使用索引扫描
- **Bitmap Index Scan**：位图索引扫描，介于两者之间
- **Rows**：估算的行数 vs 实际行数，差距大说明统计信息不准
- **actual time**：实际执行时间

### 2.2 统计信息

PostgreSQL 的查询优化器依赖统计信息来生成执行计划。如果统计信息不准确，优化器可能选择错误的执行计划。

```sql
-- 更新统计信息
ANALYZE users;

-- 查看统计信息
SELECT * FROM pg_stats WHERE tablename = 'users';

-- 增加统计采样精度
ALTER TABLE users ALTER COLUMN email SET STATICS 1000;
```

### 2.3 查询调优参数

```sql
-- 工作内存（排序和哈希操作使用）
SET work_mem = '256MB';

-- 有效缓存大小（告诉优化器系统可用的缓存大小）
SET effective_cache_size = '8GB';

-- 并行查询
SET max_parallel_workers_per_gather = 4;
```

---

## 三、高级 SQL 特性

### 3.1 窗口函数

窗口函数在不减少结果行数的情况下进行聚合计算。

```sql
-- 排名
SELECT name, score,
  RANK() OVER (ORDER BY score DESC) as rank,
  DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank,
  ROW_NUMBER() OVER (ORDER BY score DESC) as row_num
FROM students;

-- 分组排名
SELECT name, department, salary,
  RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank
FROM employees;

-- 移动平均
SELECT date, revenue,
  AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as moving_avg_7d
FROM daily_revenue;
```

### 3.2 CTE（Common Table Expression）

CTE 让复杂查询更易读，支持递归查询。

```sql
-- 普通 CTE
WITH active_users AS (
  SELECT id, name FROM users WHERE last_login > NOW() - INTERVAL '30 days'
)
SELECT * FROM active_users WHERE name LIKE 'A%';

-- 递归 CTE（组织架构树）
WITH RECURSIVE org_tree AS (
  SELECT id, name, manager_id, 1 as level
  FROM employees WHERE manager_id IS NULL
  
  UNION ALL
  
  SELECT e.id, e.name, e.manager_id, t.level + 1
  FROM employees e
  JOIN org_tree t ON e.manager_id = t.id
)
SELECT * FROM org_tree ORDER BY level, name;
```

### 3.3 LATERAL JOIN

LATERAL JOIN 让右边的子查询可以引用左边的结果。

```sql
-- 获取每个用户最近的3个订单
SELECT u.name, recent.*
FROM users u
CROSS JOIN LATERAL (
  SELECT * FROM orders o
  WHERE o.user_id = u.id
  ORDER BY o.created_at DESC
  LIMIT 3
) recent;
```

### 3.4 UPSERT

```sql
-- INSERT 或 UPDATE（如果冲突）
INSERT INTO page_views (page_id, views)
VALUES ('/home', 1)
ON CONFLICT (page_id) DO UPDATE
SET views = page_views.views + 1;
```

---

## 四、JSONB 操作

### 4.1 JSONB 存储与查询

```sql
-- 插入 JSONB
INSERT INTO events (data)
VALUES ('{"type": "click", "target": "button", "metadata": {"browser": "chrome"}}');

-- 查询 JSONB 字段
SELECT data ->> 'type' as event_type FROM events;
SELECT data -> 'metadata' ->> 'browser' as browser FROM events;

-- 条件过滤
SELECT * FROM events WHERE data ->> 'type' = 'click';

-- JSONB 包含查询
SELECT * FROM events WHERE data @> '{"type": "click"}';

-- JSONB 数组查询
SELECT * FROM events WHERE data -> 'tags' ? 'important';
```

### 4.2 JSONB 索引

```bash
# GIN 索引支持 @>, ?, ?|, ?& 操作符
CREATE INDEX idx_events_data ON events USING GIN (data);

# BTREE 索引支持 ->>, -> 操作符
CREATE INDEX idx_events_type ON events USING BTREE ((data ->> 'type'));
```

### 4.3 JSONB 聚合

```sql
-- JSONB 聚合
SELECT jsonb_agg(jsonb_build_object('name', name, 'score', score))
FROM students;

-- JSONB 对象聚合
SELECT jsonb_object_agg(id, name) FROM users;
```

---

## 五、全文搜索

### 5.1 基本用法

```sql
-- 创建 tsvector 列
ALTER TABLE posts ADD COLUMN search_vector tsvector;

-- 填充搜索向量
UPDATE posts SET search_vector =
  to_tsvector('english', coalesce(title, '') || ' ' || coalesce(content, ''));

-- 创建 GIN 索引
CREATE INDEX idx_posts_search ON posts USING GIN (search_vector);

-- 搜索
SELECT * FROM posts WHERE search_vector @@ to_tsquery('english', 'database & performance');
```

### 5.2 中文全文搜索

PostgreSQL 原生不支持中文分词，需要安装 zhparser 或 pg_jieba 扩展。

---

## 六、分区表

### 6.1 声明式分区

```sql
-- 按范围分区
CREATE TABLE logs (
  id BIGSERIAL,
  created_at TIMESTAMPTZ NOT NULL,
  level TEXT,
  message TEXT
) PARTITION BY RANGE (created_at);

-- 创建分区
CREATE TABLE logs_2024_01 PARTITION OF logs
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE logs_2024_02 PARTITION OF logs
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- 自动创建分区（使用 pg_partman 扩展）
```

### 6.2 分区裁剪

PostgreSQL 的查询优化器会自动进行分区裁剪——只扫描相关的分区。但如果查询条件中没有分区键，会扫描所有分区。

---

## 七、复制与高可用

### 7.1 流复制

流复制（Streaming Replication）是 PostgreSQL 内置的物理复制方案。主库把 WAL 日志流式发送给从库，从库重放日志保持数据一致。

### 7.2 逻辑复制

逻辑复制（Logical Replication）可以复制特定的表，支持不同大版本之间的复制。

```sql
-- 发布端
CREATE PUBLICATION my_pub FOR TABLE orders, users;

-- 订阅端
CREATE SUBSCRIPTION my_sub
  CONNECTION 'host=primary-db dbname=mydb'
  PUBLICATION my_pub;
```

### 7.3 Patroni 高可用

Patroni 是目前最流行的 PostgreSQL 高可用方案，基于 DCS（如 etcd、Consul）实现自动故障转移。

---

## 八、扩展

### 8.1 常用扩展

- **pg_stat_statements**：查询性能分析
- **pg_trgm**：模糊搜索加速
- **PostGIS**：地理空间数据
- **TimescaleDB**：时序数据库
- **Citus**：分布式 PostgreSQL
- **pgvector**：向量搜索（AI 相似度搜索）

### 8.2 pg_stat_statements

```sql
-- 启用
CREATE EXTENSION pg_stat_statements;

-- 查看最慢的查询
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

---

## 九、性能优化清单

1. 使用 EXPLAIN ANALYZE 分析慢查询
2. 创建合适的索引（部分索引、复合索引）
3. 定期 VACUUM 和 ANALYZE
4. 调整 work_mem 和 effective_cache_size
5. 避免 SELECT *
6. 使用连接池（PgBouncer）
7. 监控 pg_stat_activity 发现慢查询
8. 定期检查索引使用率，删除无用索引

---

## 结尾

PostgreSQL 是一个功能极其丰富的数据库。掌握这些高级特性能让你在面对复杂需求时游刃有余。但记住，最好的优化是选择合适的架构——不要用数据库做它不擅长的事情。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '12 days',
    NOW() - INTERVAL '12 days',
    NOW() - INTERVAL '12 days'
),
(
    1,
    'React 18 新特性与现代前端架构实战',
    'react18-guide',
    '从 Concurrent Rendering 到 Server Components，覆盖 React 18 核心 API 与大型项目架构实践',
    $doc$
# React 18 新特性与现代前端架构实战

## 写在前面

去年我们团队把一个日活过百万的 C 端产品从 React 16 迁移到 React 18，前后花了将近四个月。过程中踩了不少坑，也积累了一些经验。这篇文章不是官方文档的复述，而是基于真实项目经验，把 React 18 中我认为最关键的改动梳理出来。

React 18 发布于 2022 年 3 月，这是 React 自 2017 年 16.0 以来最大的一次架构变革。核心变化集中在三个方面：并发渲染、自动批处理、以及流式 SSR。

## 并发渲染：React 调度机制的根本变化

### 什么是 Concurrent Mode

React 16 的渲染是同步的——一旦开始渲染，就会一直执行到完成，期间主线程被占用。如果组件树很大，用户交互就会卡顿。

React 18 引入了并发渲染（Concurrent Rendering），本质上是给 React 的 reconciler 加了一个优先级调度器。不同类型的更新可以被打断、暂停、恢复，高优先级的更新（比如用户点击）可以插队到低优先级更新（比如数据预取）前面。

```tsx
// React 17
import ReactDOM from 'react-dom';
ReactDOM.render(<App />, document.getElementById('root'));

// React 18
import { createRoot } from 'react-dom/client';
const root = createRoot(document.getElementById('root'));
root.render(<App />);
```

切换到 `createRoot` 之后，React 18 默认开启所有并发特性。

### Rendering 与 Committing 的分离

要理解并发渲染，需要分清两个阶段：Render 阶段调用组件函数计算虚拟 DOM 树的 diff，可以被打断和重试；Commit 阶段把计算结果批量应用到真实 DOM，是同步不可中断的。

## Transitions：控制更新优先级的 API

### useTransition

`useTransition` 让你把一个状态更新标记为"过渡"，告诉 React 这个更新可以被中断，优先处理更紧急的更新。

```tsx
import { useState, useTransition } from 'react';

function SearchPage() {
  const [query, setQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  function handleChange(e) {
    setQuery(e.target.value);
    startTransition(() => {
      setSearchResults(filterData(e.target.value));
    });
  }

  return (
    <div>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <Results data={searchResults} />
    </div>
  );
}
```

没有 `useTransition` 的时候，每次输入都会触发一次完整的 re-render。用了 `useTransition` 之后，输入框的响应是即时的，搜索结果的更新可以在空闲时处理。

### useDeferredValue

`useDeferredValue` 和 `useTransition` 做的事情类似，但用法不同。它接受一个值，返回一个延迟版本的值。当你无法控制上游传入的值时，它特别有用。

## Suspense：声明式的加载状态管理

### Suspense 的工作原理

Suspense 本质上是一个边界声明。当子树中有组件还在等待异步操作时，React 会渲染 fallback；异步操作完成后，React 用实际内容替换 fallback。

React 18 扩展了 Suspense 的能力，让它支持数据加载场景。原理是当组件在 render 过程中抛出一个 Promise 时，React 会捕获它，暂停渲染，等 Promise resolve 后再恢复。

### Suspense 边界的设计

在大型应用中，Suspense 边界放哪里直接影响用户体验。放得太外层，整个页面都会显示 loading；放得太里层，fallback 切换会很频繁，造成视觉闪烁。

我的经验是在路由级别放一个 Suspense 边界，然后在页面内部按模块粒度放二级边界。

## 流式 SSR 与 Hydration

React 18 的流式 SSR 基于 `renderToPipeableStream`。配合 Suspense，服务端可以在组件数据还没准备好时先发送 HTML shell 和 loading 状态，数据就绪后再通过内联 `<script>` 标签追加内容。

## 自动批处理：减少不必要的 re-render

React 18 把批处理扩展到了所有场景——事件处理、Promise、setTimeout、原生事件，一律合并为一次 re-render。

```tsx
// React 18
async function fetchData() {
  const result = await fetch('/api/data');
  // 只有一次 re-render
  setData(result);
  setLoading(false);
}
```

## 新 Hooks 详解

### useId

`useId` 生成一个在服务端和客户端之间保持一致的唯一 ID，解决了 SSR 中 ID 不匹配的问题。

### useSyncExternalStore

`useSyncExternalStore` 订阅外部数据源，保证在并发模式下不会出现撕裂。Redux、Zustand、Jotai 都用它来集成 React 18 的并发特性。

### useInsertionEffect

`useInsertionEffect` 在 DOM 变更前同步执行，用于注入 CSS-in-JS 的样式。绝大多数应用不需要直接使用，它是给 CSS-in-JS 库作者用的。

## 状态管理：Zustand、Jotai 与 Recoil

React 18 的并发特性对状态管理库提出了新要求。Zustand 是目前最轻量的方案，天然兼容 React 18 的并发特性。Jotai 是原子化状态管理方案，适合状态之间有大量派生关系的场景。

## 性能优化

React.memo 对 props 做浅比较，props 没变时跳过 re-render。useMemo 和 useCallback 分别缓存计算结果和函数引用。虚拟化（react-window、@tanstack/react-virtual）只渲染可视区域内的元素。

## Server Components

Server Components 允许组件只在服务端渲染，不发送 JavaScript 到客户端。目前主要通过 Next.js App Router 使用。

## 迁移实战

从 React 16/17 迁移到 React 18，核心步骤是：升级 react 和 react-dom 到 18.x；把 ReactDOM.render 改成 createRoot；检查所有异步上下文中的状态更新；测试第三方库兼容性。

## 总结

React 18 不是一次 API 层面的大改，而是一次架构层面的升级。迁移成本不高，但需要仔细测试。建议先升级到 React 18，然后逐步引入并发特性。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days'
),
(
    1,
    'Vue 3 Composition API 与响应式系统深入',
    'vue3-composition-api',
    '从 Reactivity 原理到组件设计模式，深入讲解 Vue 3 Composition API、ref vs reactive、composables 设计和大型项目架构。',
    $doc$
# Vue 3 Composition API 与响应式系统深入

## 前言

Vue 3 最重大的变化不是性能提升，而是 Composition API。它改变了我们组织组件逻辑的方式。Options API 在小组件里很清晰，但当一个组件有几百行代码、需要复用多块逻辑时，代码会变得支离破碎——数据在这里，方法在那里，watch 在另一个地方。Composition API 让你可以把相关的逻辑组织在一起，代码的内聚性好得多。

这篇文章不是 API 文档的翻译，我想从实际开发的角度聊一聊 Vue 3 的核心机制和最佳实践。

---

## 一、响应式系统

### 1.1 Proxy vs defineProperty

Vue 2 用 `Object.defineProperty` 实现响应式。它有一个根本限制：只能监听已有属性的读写，不能监听新增/删除属性，也不能监听数组索引和长度。

Vue 3 改用 `Proxy`。Proxy 拦截的是整个对象的操作，包括属性访问、赋值、删除、in 操作符等。

```javascript
// Vue 2 的限制
const vm = new Vue({
  data: { name: 'Alice' }
});
vm.age = 25;  // 这个属性不是响应式的

// Vue 3 没有这个限制
const state = reactive({ name: 'Alice' });
state.age = 25;  // 完全响应式
```

### 1.2 ref vs reactive

Vue 3 提供了两种创建响应式状态的方式：`ref` 和 `reactive`。

```javascript
import { ref, reactive } from 'vue';

// ref：基本类型
const count = ref(0);
console.log(count.value);  // 0
count.value++;             // 修改需要 .value

// reactive：对象类型
const state = reactive({
  name: 'Alice',
  items: [1, 2, 3]
});
console.log(state.name);   // 不需要 .value
state.name = 'Bob';        // 直接修改
```

一个常见的困惑：什么时候用 ref，什么时候用 reactive？

我的原则：**优先用 ref**。理由：
- ref 可以包装任何类型，包括基本类型
- ref 解构后不会丢失响应性（通过 .value 访问）
- reactive 解构会丢失响应性

```javascript
// reactive 解构会丢失响应性
const state = reactive({ count: 0 });
const { count } = state;  // count 不再是响应式的

// ref 解构不会丢失
const count = ref(0);
const myCount = count;  // myCount.value 仍然是响应式的
```

### 1.3 computed

computed 是派生状态，依赖其他响应式状态自动更新。

```javascript
import { ref, computed } from 'vue';

const firstName = ref('John');
const lastName = ref('Doe');

const fullName = computed(() => {
  return `${firstName.value} ${lastName.value}`;
});

// computed 也是 ref
console.log(fullName.value);  // 'John Doe'
```

computed 有缓存：只有依赖变化时才重新计算。这在处理昂贵计算（如排序、过滤大数组）时很有用。

### 1.4 watch 和 watchEffect

```javascript
import { ref, watch, watchEffect } from 'vue';

const query = ref('');

// watch：明确指定要监听的源
watch(query, (newVal, oldVal) => {
  console.log(`搜索词从 "${oldVal}" 变为 "${newVal}"`);
  fetchResults(newVal);
});

// watchEffect：自动追踪依赖
watchEffect(() => {
  console.log(`当前搜索词: ${query.value}`);
  // query.value 变化时自动重新执行
});
```

watch 和 watchEffect 的区别：watch 需要明确指定源，可以获取新旧值；watchEffect 自动追踪依赖，更简洁但不能获取旧值。

### 1.5 toRef 和 toRefs

```javascript
const state = reactive({ name: 'Alice', age: 25 });

// toRef：创建单个属性的 ref
const nameRef = toRef(state, 'name');

// toRefs：解构所有属性为 ref
const { name, age } = toRefs(state);
```

toRefs 在 composable 中特别有用，让你可以从 reactive 对象中解构属性而不丢失响应性。

---

## 二、生命周期

### 2.1 组合式 API 生命周期

```javascript
import { onMounted, onUpdated, onUnmounted } from 'vue';

// 组件挂载后
onMounted(() => {
  console.log('组件已挂载');
});

// 组件更新后
onUpdated(() => {
  console.log('组件已更新');
});

// 组件卸载前
onUnmounted(() => {
  console.log('组件即将卸载');
});
```

### 2.2 生命周期钩子对照

- `beforeCreate` → 不需要（setup 本身就是）
- `created` → 不需要（setup 本身就是）
- `beforeMount` → `onBeforeMount`
- `mounted` → `onMounted`
- `beforeUpdate` → `onBeforeUpdate`
- `updated` → `onUpdated`
- `beforeUnmount` → `onBeforeUnmount`
- `unmounted` → `onUnmounted`

---

## 三、Composables

### 3.1 什么是 Composable

Composable 是利用 Composition API 封装可复用逻辑的函数。它类似于 React Hooks，但有一些关键区别：没有依赖数组，不需要担心闭包陷阱，可以自由使用 reactive 和 ref。

```javascript
// composables/useCounter.js
import { ref } from 'vue';

export function useCounter(initialValue = 0) {
  const count = ref(initialValue);
  
  function increment() {
    count.value++;
  }
  
  function decrement() {
    count.value--;
  }
  
  function reset() {
    count.value = initialValue;
  }
  
  return {
    count,
    increment,
    decrement,
    reset
  };
}

// 使用
const { count, increment, decrement } = useCounter(10);
```

### 3.2 常用 Composable 模式

**useFetch**：

```javascript
export function useFetch(url) {
  const data = ref(null);
  const error = ref(null);
  const loading = ref(true);

  fetch(url)
    .then(res => res.json())
    .then(json => { data.value = json; })
    .catch(err => { error.value = err; })
    .finally(() => { loading.value = false; });

  return { data, error, loading };
}
```

**useLocalStorage**：

```javascript
export function useLocalStorage(key, defaultValue) {
  const stored = localStorage.getItem(key);
  const data = ref(stored ? JSON.parse(stored) : defaultValue);

  watch(data, (newVal) => {
    localStorage.setItem(key, JSON.stringify(newVal));
  }, { deep: true });

  return data;
}
```

### 3.3 Composables vs Mixins

Composables 相比 Vue 2 的 Mixins 的优势：命名清晰（不会出现属性来源不明的问题）、类型推断更好、不会产生命名冲突、可以返回任意类型。

---

## 四、provide / inject

### 4.1 基本用法

```javascript
// 父组件
import { provide } from 'vue';

provide('theme', 'dark');
provide('user', currentUser);

// 子组件
import { inject } from 'vue';

const theme = inject('theme', 'light');  // 第二个参数是默认值
const user = inject('user');
```

### 4.2 响应式 provide

```javascript
// 父组件
const theme = ref('dark');
provide('theme', theme);

// 子组件
const theme = inject('theme');
// theme.value 是响应式的
```

### 4.3 应用全局配置

```javascript
// app.config.globalProperties
app.config.globalProperties.$theme = 'dark';

// 在组件中
const theme = getCurrentInstance().proxy.$theme;
```

---

## 五、Teleport

Teleport 把组件的 DOM 渲染到指定的目标节点，不受父组件 CSS 的影响。

```vue
<template>
  <button @click="showModal = true">打开弹窗</button>
  
  <Teleport to="body">
    <div v-if="showModal" class="modal-overlay">
      <div class="modal">
        <p>这是一个弹窗</p>
        <button @click="showModal = false">关闭</button>
      </div>
    </div>
  </Teleport>
</template>
```

弹窗、通知、工具提示这些需要突破父组件 overflow:hidden 限制的场景，Teleport 是最佳解决方案。

---

## 六、Suspense

```vue
<template>
  <Suspense>
    <template #default>
      <AsyncComponent />
    </template>
    <template #fallback>
      <Loading />
    </template>
  </Suspense>
</template>
```

Suspense 用于处理异步组件的加载状态。配合 `<script setup>` 中的 async 组件使用。

---

## 七、大型项目架构

### 7.1 目录结构

```
src/
  components/       # 通用组件
  composables/      # 可复用逻辑
  views/            # 页面组件
  router/           # 路由配置
  stores/           # Pinia 状态管理
  utils/            # 工具函数
  types/            # TypeScript 类型
  assets/           # 静态资源
```

### 7.2 组件设计原则

- 单一职责：每个组件只做一件事
- Props 向下，Events 向上
- 用 slots 实现组件内容的灵活定制
- 用 provide/inject 实现深层组件通信
- 用 composable 替代 mixin 做逻辑复用

---

## 八、与 TypeScript 的配合

Vue 3 的 TypeScript 支持比 Vue 2 好得多。`<script setup>` + TypeScript 是推荐的开发方式。

```vue
<script setup lang="ts">
interface Props {
  title: string;
  count?: number;
}

const props = withDefaults(defineProps<Props>(), {
  count: 0
});

const emit = defineEmits<{
  change: [value: number];
}>();
</script>
```

---

## 总结

Vue 3 的 Composition API 不仅仅是语法变化，它带来了更好的逻辑复用、更清晰的代码组织、更好的 TypeScript 支持。掌握 ref vs reactive 的选择、composables 的设计模式、provide/inject 的正确用法，你的 Vue 3 代码质量会有质的提升。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '11 days',
    NOW() - INTERVAL '11 days',
    NOW() - INTERVAL '11 days'
),
(
    1,
    'Git 内部原理与高级工作流实战',
    'git-advanced-guide',
    '从 Git 对象模型到分支策略，从 interactive rebase 到 bisect 调试，深入讲解 Git 内部原理和高效协作工作流。',
    $doc$
# Git 内部原理与高级工作流实战

## 前言

大部分开发者用 Git 只会 `add`、`commit`、`push`、`pull`。出了问题就 Google，找到答案照着做，也不理解为什么要这样做。这篇文章想从 Git 的内部原理讲起，帮你理解每个命令背后发生了什么。理解了原理，很多高级操作就自然会用了。

---

## 一、Git 对象模型

### 1.1 三种对象

Git 的核心是三个对象类型：blob（文件内容）、tree（目录结构）、commit（提交信息）。

```bash
# 查看 Git 对象
git cat-file -t HEAD    # 查看对象类型
git cat-file -p HEAD    # 查看对象内容
```

每个 commit 指向一个 tree，tree 指向 blob 和子 tree。commit 的 parent 指针形成提交历史。

### 1.2 SHA-1 哈希

Git 用 SHA-1 哈希作为对象的唯一标识。相同的文件内容会产生相同的 blob 对象，这就是为什么 Git 能高效地检测重复文件。

```bash
# 计算文件的 SHA-1
git hash-object file.txt
```

### 1.3 引用（Refs）

分支和标签本质上都是引用——一个指向 commit 的文件。

```bash
# 分支引用
cat .git/refs/heads/main

# 标签引用
cat .git/refs/tags/v1.0.0
```

---

## 二、Git 工作流

### 2.1 暂存区

暂存区（staging area）是 Git 独特的设计。它让你可以精确控制每次提交包含哪些改动。

```bash
# 部分暂存
git add -p          # 交互式选择要暂存的代码块

# 暂存删除
git rm file.txt     # 从暂存区和工作区删除
git rm --cached file.txt  # 只从暂存区删除
```

### 2.2 HEAD 指针

HEAD 指向当前分支的最新 commit。`git checkout` 本质上是移动 HEAD 指针。

```bash
# 查看 HEAD 指向
cat .git/HEAD

# detached HEAD 状态
git checkout <commit-hash>
```

---

## 三、分支策略

### 3.1 Git Flow

Git Flow 适合有明确发布周期的项目：main（生产分支）、develop（开发分支）、feature/*（功能分支）、release/*（发布分支）、hotfix/*（紧急修复）。

### 3.2 GitHub Flow

GitHub Flow 更简洁：main 分支始终可部署，功能分支通过 Pull Request 合并到 main。

### 3.3 Trunk-Based Development

Trunk-Based Development 更激进：所有开发者直接往 main 分支提交（或用非常短命的分支），配合特性开关控制功能发布。

选哪个策略？看你的发布频率。如果是 SaaS 产品每天发布多次，Trunk-Based Development 最合适。如果是传统软件按月发布，Git Flow 更合适。

---

## 四、高级操作

### 4.1 Interactive Rebase

Interactive rebase 可以修改提交历史，整理 commit。

```bash
# 修改最近 3 次提交
git rebase -i HEAD~3
```

编辑器会显示：

```
pick abc1234 Add login feature
pick def5678 Fix typo in login
pick ghi9012 Add password validation
```

可以改成：

```
pick abc1234 Add login feature
squash def5678 Fix typo in login
pick ghi9012 Add password validation
```

squash 会把两个 commit 合并成一个。

### 4.2 Cherry-Pick

Cherry-pick 把某个 commit 的改动应用到当前分支。

```bash
# 把特定 commit 应用到当前分支
git cherry-pick abc1234

# 把多个 commit 应用
git cherry-pick abc1234 def5678
```

### 4.3 Bisect

Bisect 用二分查找定位引入 bug 的 commit。

```bash
# 开始 bisect
git bisect start

# 标记当前版本有问题
git bisect bad

# 标记已知的好版本
git bisect good v1.0.0

# Git 会自动 checkout 中间的 commit
# 测试后标记
git bisect good    # 或 git bisect bad

# 重复直到找到引入 bug 的 commit
```

### 4.4 Reflog

Reflog 记录了 HEAD 的所有移动历史。即使 `git reset --hard` 丢失了 commit，也可以通过 reflog 找回。

```bash
# 查看 reflog
git reflog

# 恢复丢失的 commit
git checkout <commit-hash>
git branch recover-branch
```

---

## 五、远程协作

### 5.1 Fetch vs Pull

`git fetch` 只下载远程数据，不合并。`git pull` = `git fetch` + `git merge`。

建议用 `git fetch` + `git rebase` 代替 `git pull`，保持提交历史更整洁。

### 5.2 Push Options

```bash
# 推送并创建 Pull Request
git push origin feature-branch -o pull-request

# 推送并自动合并
git push origin main -o merge
```

### 5.3 Git LFS

Git LFS（Large File Storage）用于存储大文件（视频、数据集、二进制文件）。

```bash
# 安装 Git LFS
git lfs install

# 跟踪大文件
git lfs track "*.psd"
git lfs track "*.zip"
```

---

## 六、配置与别名

### 6.1 实用别名

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --oneline --graph --all"
git config --global alias.last "log -1 HEAD"
git config --global alias.unstage "reset HEAD --"
```

### 6.2 .gitattributes

```gitattributes
# 指定换行符
*.sh text eol=lf
*.bat text eol=crlf

# 标记二进制文件
*.png binary
*.jpg binary

# 合并策略
package-lock.json merge=ours
```

---

## 七、常见问题解决

### 7.1 撤销操作

```bash
# 撤销工作区修改
git checkout -- file.txt

# 撤销暂存
git reset HEAD file.txt

# 修改上一次提交
git commit --amend

# 回退到某个 commit
git reset --hard <commit-hash>
```

### 7.2 冲突解决

```bash
# 查看冲突文件
git status

# 解决冲突后
git add <file>
git commit    # 不需要 -m，Git 会自动生成合并提交信息
```

### 7.3 清理

```bash
# 删除已合并的分支
git branch --merged main | grep -v main | xargs git branch -d

# 清理未跟踪的文件
git clean -fd
```

---

## 八、Git Hooks

Git Hooks 是在特定事件发生时自动执行的脚本。

```bash
# .git/hooks/pre-commit
#!/bin/sh
# 在提交前运行 lint
npm run lint
if [ $? -ne 0 ]; then
  echo "Lint 失败，提交被阻止"
  exit 1
fi
```

推荐使用 husky 来管理 Git Hooks：

```bash
npx husky install
npx husky add .husky/pre-commit "npm run lint"
```

---

## 总结

理解 Git 的内部原理（对象模型、引用、暂存区）能让你更自信地使用高级操作。interactive rebase、cherry-pick、bisect 这些工具在日常开发中非常实用。选一个适合你团队的分支策略，配合 Git Hooks 保证代码质量。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '10 days'
),
(
    1,
    'Nginx 高性能 Web 服务器配置与优化实战',
    'nginx-performance-guide',
    '从架构原理到生产环境调优，覆盖 Nginx master-worker 模型、事件驱动、虚拟主机、location 匹配、upstream 负载均衡、SSL/TLS、HTTP/2、缓存、限流、安全加固、OpenResty Lua 扩展、WebSocket 代理、性能调优与监控',
    $doc$
# Nginx 高性能 Web 服务器配置与优化实战

我第一次真正理解 Nginx 是在 2016 年，当时公司的一台 Apache 服务器在促销活动期间扛不住流量挂了。迁移到 Nginx 之后，同样的硬件跑了原来三倍的请求量。这件事让我意识到，选对工具比堆硬件重要得多。

这篇文章是我这些年折腾 Nginx 的经验总结，从架构原理到生产配置，尽量写得实用。

## 1. Nginx 的架构：master-worker 模型

Nginx 用一个 master 进程管理多个 worker 进程。master 负责读取配置、绑定端口、管理 worker；worker 负责实际处理请求。每个 worker 是一个独立进程，互相之间不共享内存。

worker 数量通常设成 CPU 核心数。太多会增加进程切换开销，太少会浪费 CPU。

每个 worker 内部是事件驱动模型（epoll on Linux，kqueue on macOS）。单个 worker 就能处理成千上万的并发连接，不需要为每个请求开新线程。

## 2. 虚拟主机与 server_name 匹配

Nginx 收到请求后，按优先级匹配 server 块：精确匹配 > 前缀通配符 > 后缀通配符 > 正则表达式 > 默认 server。HTTPS 的虚拟主机匹配有个坑：因为 SSL 握手发生在 HTTP 层之前，Nginx 只能靠 SNI 里的域名来选证书。

## 3. location 匹配规则

匹配优先级从高到低：`=` 精确匹配 > `^~` 前缀匹配（找到后停止搜索正则）> `~` 或 `~*` 正则匹配 > 普通前缀匹配。静态资源用 `^~` 或 `=` 可以跳过正则匹配，提升性能。

## 4. upstream 代理与负载均衡

负载均衡算法：轮询（默认）、加权轮询、IP Hash（会话保持）、Least Connections、一致性哈希。无状态服务用 least_conn 或加权轮询，需要会话保持用 ip_hash，缓存场景用一致性哈希。

健康检查通过 `max_fails` 和 `fail_timeout` 做被动检测。

## 5. SSL/TLS 配置

只开 TLSv1.2 和 TLSv1.3，关掉老版本。HSTS 头让浏览器以后只走 HTTPS。OCSP Stapling 减少客户端验证证书的延迟。`ssl_session_cache` 复用 SSL 会话，减少握手开销。

## 6. 缓存配置

代理缓存减少回源请求。静态资源设置长期缓存。Microcaching 在高并发场景下缓存 1-5 秒，大幅降低后端压力。`proxy_cache_lock on` 确保同一时间只有一个请求去回源。

## 7. 限流与访问控制

请求限速通过 `limit_req_zone` 和 `limit_req` 实现。连接数限制通过 `limit_conn_zone` 和 `limit_conn` 实现。IP 黑白名单通过 `allow`/`deny` 或 `geo` 模块实现。

## 8. 安全加固

隐藏版本信息（server_tokens off）、安全响应头（X-Frame-Options、X-Content-Type-Options、CSP）、限制请求方法、防止路径穿越、限制请求体大小。

## 9. 性能调优

连接处理（worker_connections、multi_accept、epoll）、缓冲区配置（sendfile、tcp_nopush、tcp_nodelay）、超时设置（keepalive_timeout、keepalive_requests）、Gzip 压缩。

## 10. Lua 集成与 OpenResty

OpenResty 把 LuaJIT 嵌入 Nginx，让你在 Nginx 配置里直接写 Lua 代码。可以实现请求限流（令牌桶）、动态路由、JWT 验证等高级功能。

## 11. WebSocket 代理

关键是处理好协议升级。`proxy_read_timeout` 默认是 60 秒，WebSocket 空闲超过这个时间会被断开，所以要调大。

## 12. 监控

stub_status 提供基本的连接统计。配合 nginx-vts-exporter 可以把指标接入 Prometheus + Grafana。

## 13. 常见问题排查

502 Bad Gateway 检查后端服务状态；504 Gateway Timeout 调大超时时间但根本原因是后端性能；413 Request Entity Too Large 增大 client_max_body_size；配置不生效用 nginx -T 查看完整配置。

## 结尾

Nginx 入门不难但精通需要时间。每次线上出问题回头看，往往都是配置里某个参数没调对。建议把线上验证过的配置模板化，新项目直接用。配置改之前一定跑 `nginx -t`。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
),
(
    1,
    '常用数据结构与算法实战',
    'algorithms-practice-guide',
    '从排序到图论，从动态规划到回溯，覆盖 20+ 种常用算法的原理、实现、复杂度分析和 LeetCode 经典题解。',
    $doc$
# 常用数据结构与算法实战

## 前言

学算法不是为了刷题，是为了在面对问题时能想到高效的解决方案。我见过太多项目因为用了 O(n²) 的算法导致性能瓶颈，最后花几天时间重写成 O(n log n) 的版本。如果开发者脑子里没有算法这根弦，遇到性能问题根本不会往这个方向想。

这篇文章不追求算法的数学证明，重点放在每种算法的核心思想、适用场景和实际实现。

---

## 一、排序算法

### 1.1 快速排序

快速排序是实际应用中最常用的排序算法。核心思想：选一个基准值，把数组分成小于和大于基准值的两部分，递归排序。

```python
def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)
```

平均时间复杂度 O(n log n)，最坏 O(n²)。随机选择基准值可以避免最坏情况。

### 1.2 归并排序

归并排序是稳定的排序算法。核心思想：把数组分成两半，递归排序，然后合并。

```python
def mergesort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = mergesort(arr[:mid])
    right = mergesort(arr[mid:])
    return merge(left, right)

def merge(left, right):
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result
```

时间复杂度稳定 O(n log n)，但需要 O(n) 额外空间。

### 1.3 堆排序

堆排序利用堆数据结构实现排序。适合需要原地排序且空间受限的场景。

### 1.4 排序算法对比

| 算法 | 平均时间 | 最坏时间 | 空间 | 稳定性 |
|------|---------|---------|------|--------|
| 快速排序 | O(n log n) | O(n²) | O(log n) | 不稳定 |
| 归并排序 | O(n log n) | O(n log n) | O(n) | 稳定 |
| 堆排序 | O(n log n) | O(n log n) | O(1) | 不稳定 |
| 插入排序 | O(n²) | O(n²) | O(1) | 稳定 |

---

## 二、查找算法

### 2.1 二分查找

二分查找的前提是数组有序。每次比较中间元素，将搜索范围缩小一半。

```python
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1
```

时间复杂度 O(log n)。变体：查找第一个/最后一个等于目标值的位置、查找第一个大于等于目标值的位置。

### 2.2 哈希表

哈希表提供 O(1) 的平均查找时间。核心是哈希函数和冲突解决。

冲突解决方法：链地址法（Java HashMap）、开放寻址法（Python dict）。

---

## 三、数据结构

### 3.1 栈

栈是后进先出（LIFO）的数据结构。

应用场景：函数调用栈、表达式求值、括号匹配、浏览器前进/后退。

### 3.2 队列

队列是先进先出（FIFO）的数据结构。

变体：双端队列（deque）、优先队列（priority queue，基于堆实现）。

### 3.3 链表

链表是动态数据结构，插入和删除操作的时间复杂度是 O(1)。

```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next
```

链表的经典问题：反转链表、检测环、合并两个有序链表、找中间节点。

### 3.4 树

二叉搜索树（BST）：左子树所有节点值小于根节点，右子树所有节点值大于根节点。查找、插入、删除的平均时间复杂度是 O(log n)。

平衡二叉树（AVL、红黑树）：保证树的高度是 O(log n)，避免退化成链表。

### 3.5 图

图的表示方式：邻接矩阵、邻接表。

图的遍历：BFS（广度优先搜索，按层遍历）、DFS（深度优先搜索，沿一条路径走到底再回溯）。

---

## 四、经典算法

### 4.1 动态规划

动态规划的核心：把大问题分解成子问题，存储子问题的结果避免重复计算。

适用条件：最优子结构、重叠子问题。

经典问题：爬楼梯、最大子数组和、编辑距离、背包问题、最长公共子序列。

### 4.2 贪心算法

贪心算法每一步都选择当前看起来最优的选项。不一定能得到全局最优解，但在某些问题上能保证最优。

经典问题：活动选择、霍夫曼编码、Dijkstra 最短路径。

### 4.3 回溯

回溯是一种系统地搜索解空间的方法。在每一步做出选择，如果不满足条件就撤销选择。

经典问题：N 皇后、数独求解、全排列、组合总和。

### 4.4 分治

分治把问题分成若干个规模较小的子问题，递归求解，然后合并结果。归并排序和快速排序都是分治的典型应用。

---

## 五、复杂度分析

### 5.1 时间复杂度

常见的时间复杂度从低到高：O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)。

### 5.2 空间复杂度

除了算法本身需要的额外空间，还要考虑递归调用的栈空间。快速排序的空间复杂度是 O(log n)（递归栈），归并排序是 O(n)（合并用的临时数组）。

---

## 六、LeetCode 经典题

### 6.1 两数之和（HashMap）

```python
def twoSum(nums, target):
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
```

### 6.2 最大子数组和（动态规划）

```python
def maxSubArray(nums):
    max_sum = current_sum = nums[0]
    for num in nums[1:]:
        current_sum = max(num, current_sum + num)
        max_sum = max(max_sum, current_sum)
    return max_sum
```

### 6.3 反转链表（迭代）

```python
def reverseList(head):
    prev = None
    current = head
    while current:
        next_temp = current.next
        current.next = prev
        prev = current
        current = next_temp
    return prev
```

---

## 总结

算法学习是一个持续的过程。不需要背诵所有算法的模板，但要理解每种算法的核心思想和适用场景。遇到问题时，先分析时间复杂度需求，再选择合适的算法。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '9 days',
    NOW() - INTERVAL '9 days',
    NOW() - INTERVAL '9 days'
),
(
    1,
    'WebSocket 实时通信与 Server-Sent Events',
    'websocket-realtime-guide',
    '从协议原理到生产实践，覆盖 WebSocket 握手、心跳机制、Socket.IO、Redis Pub/Sub 多实例广播、SSE 长连接和实时应用架构设计。',
    $doc$
# WebSocket 实时通信与 Server-Sent Events

## 前言

传统的 HTTP 请求-响应模型在实时场景下力不从心。想象一个在线聊天应用：用户发了一条消息，其他用户要看到这条消息，要么不停轮询（浪费资源），要么用长轮询（体验差）。WebSocket 解决了这个问题——它建立了一个全双工的持久连接，服务端可以主动推送数据给客户端。

这篇文章会从协议原理讲起，覆盖 WebSocket 的完整技术栈和生产实践。

---

## 一、WebSocket 基础

### 1.1 协议原理

WebSocket 是一个独立的协议，基于 TCP。它通过 HTTP 升级握手建立连接，之后的数据传输不经过 HTTP。

握手过程：
1. 客户端发送 HTTP 请求，带上 `Upgrade: websocket` 头
2. 服务端返回 101 Switching Protocols
3. 连接升级为 WebSocket 全双工通信

### 1.2 与 HTTP 的区别

| 特性 | HTTP | WebSocket |
|------|------|-----------|
| 连接方式 | 请求-响应 | 全双工 |
| 连接持续 | 短连接（或 Keep-Alive） | 长连接 |
| 数据格式 | 文本 | 文本或二进制 |
| 服务端推送 | 不支持（轮询） | 原生支持 |
| 协议头开销 | 大 | 小（2-14 字节） |

### 1.3 适用场景

适合 WebSocket 的场景：在线聊天、实时协作编辑、多人游戏、实时数据看板、股票行情推送。

不适合的场景：低频数据更新（每分钟一次用轮询就够了）、简单的请求-响应（HTTP 更合适）。

---

## 二、前端实现

### 2.1 原生 WebSocket API

```javascript
const ws = new WebSocket('ws://localhost:3000');

ws.onopen = () => {
  console.log('连接已建立');
  ws.send(JSON.stringify({ type: 'join', room: 'general' }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('收到消息:', data);
};

ws.onclose = (event) => {
  console.log('连接已关闭:', event.code, event.reason);
};

ws.onerror = (error) => {
  console.error('连接错误:', error);
};
```

### 2.2 Socket.IO

Socket.IO 是基于 WebSocket 的封装库，提供了自动重连、房间、命名空间、回退机制（WebSocket 不可用时自动降级到轮询）。

```javascript
// 客户端
import { io } from 'socket.io-client';

const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('已连接:', socket.id);
});

socket.on('message', (data) => {
  console.log('收到消息:', data);
});

socket.emit('send-message', { text: 'Hello', room: 'general' });

// 服务端
import { Server } from 'socket.io';

const io = new Server(3000);

io.on('connection', (socket) => {
  console.log('用户已连接:', socket.id);
  
  socket.on('send-message', (data) => {
    io.to(data.room).emit('message', data);
  });
  
  socket.join('general');
});
```

---

## 三、后端实现

### 3.1 Node.js WebSocket 服务端

```javascript
import { WebSocketServer } from 'ws';

const wss = new WebSocketServer({ port: 3000 });

const clients = new Set();

wss.on('connection', (ws) => {
  clients.add(ws);
  
  ws.on('message', (message) => {
    const data = JSON.parse(message);
    
    // 广播给所有客户端
    for (const client of clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(data));
      }
    }
  });
  
  ws.on('close', () => {
    clients.delete(ws);
  });
});
```

### 3.2 心跳机制

心跳检测连接是否存活。客户端定期发送 ping，服务端返回 pong。如果超时没有收到 pong，就断开连接。

```javascript
// 服务端
const HEARTBEAT_INTERVAL = 30000;

setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) {
      return ws.terminate();
    }
    ws.isAlive = false;
    ws.ping();
  });
}, HEARTBEAT_INTERVAL);

wss.on('connection', (ws) => {
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });
});
```

### 3.3 优雅关闭

```javascript
process.on('SIGTERM', () => {
  console.log('收到 SIGTERM 信号，准备关闭');
  
  // 停止接受新连接
  wss.close(() => {
    console.log('WebSocket 服务已关闭');
    process.exit(0);
  });
  
  // 通知所有客户端即将断开
  for (const client of wss.clients) {
    client.close(1001, 'Server shutting down');
  }
});
```

---

## 四、多实例部署

### 4.1 问题

WebSocket 是有状态的——连接建立后，后续的消息必须发到同一个服务器实例。如果用负载均衡器把请求分发到不同的实例，消息就丢失了。

### 4.2 Redis Pub/Sub

用 Redis 的发布/订阅功能在多个实例之间广播消息。

```javascript
import Redis from 'ioredis';

const pub = new Redis();
const sub = new Redis();

// 订阅频道
sub.subscribe('chat:general');

// 收到消息后广播给本地客户端
sub.on('message', (channel, message) => {
  for (const client of clients) {
    client.send(message);
  }
});

// 发布消息
ws.on('message', (data) => {
  pub.publish('chat:general', JSON.stringify(data));
});
```

### 4.3 Sticky Session

负载均衡器配置 sticky session，确保同一客户端的请求总是路由到同一个后端实例。

---

## 五、Server-Sent Events（SSE）

### 5.1 SSE vs WebSocket

SSE 是基于 HTTP 的单向推送（服务端到客户端）。WebSocket 是全双工的。

| 特性 | SSE | WebSocket |
|------|-----|-----------|
| 方向 | 服务端→客户端 | 双向 |
| 协议 | HTTP | WebSocket |
| 数据格式 | 文本 | 文本或二进制 |
| 自动重连 | 浏览器内置 | 需要自己实现 |
| 代理兼容 | 好（标准 HTTP） | 可能有问题 |

适合 SSE 的场景：通知推送、实时数据更新（只从服务端到客户端）、服务器事件日志。

### 5.2 前端实现

```javascript
const eventSource = new EventSource('/api/events');

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('收到事件:', data);
};

eventSource.onerror = () => {
  console.log('连接断开，浏览器会自动重连');
};
```

### 5.3 Node.js 实现

```javascript
app.get('/api/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  
  const sendEvent = (data) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };
  
  // 监听数据变化并推送
  eventEmitter.on('update', sendEvent);
  
  req.on('close', () => {
    eventEmitter.removeListener('update', sendEvent);
  });
});
```

---

## 六、安全考虑

### 6.1 认证

WebSocket 连接建立时无法直接设置自定义头。几种认证方式：
- 通过 URL 参数传递 token（不推荐，日志会泄露）
- 连接建立后发送第一条消息携带 token
- 先通过 HTTP 请求获取 token，再建立 WebSocket 连接

### 6.2 防止 DDoS

- 限制单 IP 的连接数
- 设置消息大小限制
- 使用速率限制
- 验证 Origin 头

### 6.3 数据验证

所有收到的消息都必须验证格式和内容，不要信任客户端数据。

---

## 七、性能优化

### 7.1 消息压缩

WebSocket 支持 permessage-deflate 扩展，可以压缩消息。

### 7.2 连接池

对于需要连接多个 WebSocket 服务的应用，使用连接池管理连接。

### 7.3 水平扩展

通过 Redis Pub/Sub 或 Kafka 实现多实例之间的消息广播。

---

## 八、实战：聊天室

一个完整的聊天室需要：用户认证、房间管理、消息广播、消息持久化、在线用户列表、输入状态提示。

推荐的技术栈：前端用 Socket.IO，后端用 Node.js + Socket.IO，消息存储用 Redis + PostgreSQL，多实例广播用 Redis Pub/Sub。

---

## 总结

WebSocket 是实时应用的核心技术。选择 WebSocket 还是 SSE 取决于你的场景是否需要双向通信。如果只需要服务端推送，SSE 更简单。如果需要双向实时通信，WebSocket 是唯一选择。生产环境别忘了心跳机制、认证、多实例部署这些关键问题。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '8 days',
    NOW() - INTERVAL '8 days',
    NOW() - INTERVAL '8 days'
),
(
    1,
    'gRPC 与 Protocol Buffers 微服务通信实战',
    'grpc-microservices-guide',
    '从 proto 文件定义到流式 RPC，从负载均衡到拦截器，覆盖 gRPC 在微服务架构中的完整应用实践。',
    $doc$
# gRPC 与 Protocol Buffers 微服务通信实战

## 前言

REST API 在微服务通信中有几个痛点：JSON 序列化体积大、传输效率低、没有严格的接口契约、不支持流式通信。gRPC 解决了这些问题——它用 Protocol Buffers 做序列化（体积小、速度快），HTTP/2 做传输（多路复用、头部压缩），IDL（接口定义语言）做契约（强类型、代码生成）。

这篇文章会从 proto 文件定义讲起，覆盖 gRPC 在微服务架构中的完整应用。

---

## 一、Protocol Buffers

### 1.1 基本语法

```protobuf
syntax = "proto3";

package user;

message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  repeated string tags = 4;
  map<string, string> metadata = 5;
}
```

proto3 相比 proto2 的主要变化：所有字段都是 optional，移除了 required 关键字，支持 map 类型。

### 1.2 字段编号

字段编号（1, 2, 3...）是 Protocol Buffers 的核心概念。它用于在二进制编码中标识字段。一旦使用了某个编号，就不能再改。

字段编号 1-15 只用 1 字节编码，16-2047 用 2 字节。常用的字段应该用小编号。

### 1.3 枚举和 Oneof

```protobuf
enum Status {
  UNKNOWN = 0;
  ACTIVE = 1;
  INACTIVE = 2;
}

message Event {
  oneof payload {
    TextMessage text = 1;
    ImageMessage image = 2;
    VideoMessage video = 3;
  }
}
```

Oneof 表示互斥的字段——同一时间只能有一个被设置。

---

## 二、gRPC 四种通信模式

### 2.1 一元 RPC（Unary）

最简单的模式：客户端发一个请求，服务端返回一个响应。

```protobuf
service UserService {
  rpc GetUser (GetUserRequest) returns (User);
}
```

### 2.2 服务端流式 RPC

客户端发一个请求，服务端返回一个流，可以发送多个响应。

```protobuf
service UserService {
  rpc ListUsers (ListUsersRequest) returns (stream User);
}
```

适用场景：大数据量分页返回、实时数据推送。

### 2.3 客户端流式 RPC

客户端发送一个流，服务端返回一个响应。

```protobuf
service UserService {
  rpc UploadUsers (stream User) returns (UploadResult);
}
```

适用场景：批量上传、日志收集。

### 2.4 双向流式 RPC

客户端和服务端都可以随时发送数据。

```protobuf
service ChatService {
  rpc Chat (stream ChatMessage) returns (stream ChatMessage);
}
```

适用场景：实时聊天、双向数据同步。

---

## 三、Go 实现 gRPC 服务

### 3.1 定义 proto 文件

```protobuf
syntax = "proto3";
package order;

service OrderService {
  rpc CreateOrder (CreateOrderRequest) returns (Order);
  rpc GetOrder (GetOrderRequest) returns (Order);
  rpc ListOrders (ListOrdersRequest) returns (stream Order);
}

message CreateOrderRequest {
  int32 user_id = 1;
  repeated OrderItem items = 2;
}

message Order {
  int32 id = 1;
  int32 user_id = 2;
  repeated OrderItem items = 3;
  string status = 4;
  float total = 5;
}
```

### 3.2 生成代码

```bash
protoc --go_out=. --go-grpc_out=. proto/order.proto
```

### 3.3 实现服务

```go
type OrderServer struct {
    pb.UnimplementedOrderServiceServer
}

func (s *OrderServer) CreateOrder(ctx context.Context, req *pb.CreateOrderRequest) (*pb.Order, error) {
    order := &pb.Order{
        Id:     generateID(),
        UserId: req.UserId,
        Items:  req.Items,
        Status: "created",
        Total:  calculateTotal(req.Items),
    }
    return order, nil
}
```

---

## 四、Java 实现 gRPC 服务

```java
public class OrderServiceImpl extends OrderServiceGrpc.OrderServiceImplBase {
    @Override
    public void createOrder(CreateOrderRequest request, StreamObserver<Order> responseObserver) {
        Order order = Order.newBuilder()
            .setId(generateId())
            .setUserId(request.getUserId())
            .addAllItems(request.getItemsList())
            .setStatus("created")
            .build();
        
        responseObserver.onNext(order);
        responseObserver.onCompleted();
    }
}
```

---

## 五、负载均衡

### 5.1 客户端负载均衡

gRPC 内置了客户端负载均衡。客户端从服务发现获取所有实例，自己做负载均衡。

```go
conn, err := grpc.Dial(
    "dns:///order-service:50051",
    grpc.WithDefaultServiceConfig(`{"loadBalancingConfig": [{"round_robin":{}}]}`),
)
```

### 5.2 服务端负载均衡

用 Nginx 或 Envoy 做服务端负载均衡。Nginx 1.13.10+ 支持 gRPC 代理。

---

## 六、拦截器（Interceptors）

拦截器类似于中间件，在 RPC 调用前后执行逻辑。

### 6.1 一元拦截器

```go
func loggingInterceptor(
    ctx context.Context,
    req interface{},
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (interface{}, error) {
    start := time.Now()
    resp, err := handler(ctx, req)
    log.Printf("Method: %s, Duration: %v, Error: %v",
        info.FullMethod, time.Since(start), err)
    return resp, err
}
```

### 6.2 链式拦截器

```go
server := grpc.NewServer(
    grpc.ChainUnaryInterceptor(
        recoveryInterceptor,
        loggingInterceptor,
        authInterceptor,
    ),
)
```

---

## 七、错误处理

gRPC 定义了标准的状态码：

| 状态码 | 含义 |
|--------|------|
| OK | 成功 |
| INVALID_ARGUMENT | 参数无效 |
| NOT_FOUND | 资源不存在 |
| ALREADY_EXISTS | 资源已存在 |
| PERMISSION_DENIED | 权限不足 |
| UNAUTHENTICATED | 未认证 |
| INTERNAL | 内部错误 |
| UNAVAILABLE | 服务不可用 |

不要把所有错误都返回 INTERNAL——使用正确的状态码让客户端能做出适当的处理。

---

## 八、认证

### 8.1 Token 认证

```go
// 客户端
token := &oauth2.Token{AccessToken: "my-token"}
conn, err := grpc.Dial(addr,
    grpc.WithTransportCredentials(insecure.NewCredentials()),
    grpc.WithPerRPCCredentials(&tokenAuth{token: token}),
)
```

### 8.2 TLS

```go
creds, err := credentials.NewServerTLSFromFile("server.crt", "server.key")
server := grpc.NewServer(grpc.Creds(creds))
```

---

## 九、健康检查

gRPC 定义了标准的健康检查协议：

```protobuf
service Health {
  rpc Check (HealthCheckRequest) returns (HealthCheckResponse);
}
```

Kubernetes 可以用这个协议做存活探针和就绪探针。

---

## 十、gRPC-Web

gRPC-Web 让浏览器可以直接调用 gRPC 服务。通过 Envoy 代理将 gRPC-Web 协议转换为标准 gRPC 协议。

---

## 十一、与 REST 共存

### 11.1 gRPC-Gateway

gRPC-Gateway 把 gRPC 服务映射为 REST API。通过 proto 文件中的注释定义 HTTP 映射。

### 11.2 同时暴露两种协议

一个服务同时监听 gRPC 端口和 HTTP 端口，满足不同客户端的需求。

---

## 十二、性能优化

### 12.1 连接管理

gRPC 基于 HTTP/2，支持多路复用。一个 TCP 连接可以并发多个 RPC 调用。客户端应该复用连接，不要为每次调用创建新连接。

### 12.2 消息大小

默认的 gRPC 消息大小限制是 4MB。对于大消息，需要调整 `maxSendMsgSize` 和 `maxRecvMsgSize`。

### 12.3 超时和截止时间

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
resp, err := client.GetOrder(ctx, &pb.GetOrderRequest{Id: orderId})
```

---

## 十三、测试

### 13.1 单元测试

gRPC 服务的单元测试可以用 bufconn 建立内存连接，不需要启动真实的服务器。

### 13.2 集成测试

用测试容器（testcontainers）启动真实的依赖服务，验证端到端的流程。

---

## 总结

gRPC 在微服务通信中比 REST 更高效、更可靠。Protocol Buffers 的强类型保证了接口契约，HTTP/2 提供了高效的传输，流式 RPC 支持了实时场景。但 gRPC 不是万能的——浏览器支持有限、调试不如 REST 直观、学习曲线较陡。选择 REST 还是 gRPC，取决于你的具体场景。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days'
),
(
    1,
    'CI/CD 流水线设计与 DevOps 实践',
    'cicd-devops-guide',
    '从构建自动化到部署策略，覆盖 Jenkins、GitHub Actions、GitLab CI、ArgoCD 工具链，讲解流水线设计、环境管理、质量门禁和发布策略。',
    $doc$
# CI/CD 流水线设计与 DevOps 实践

## 前言

CI/CD 不是工具问题，是文化问题。我见过太多团队买了昂贵的 CI/CD 平台，但开发流程还是老样子——手动测试、手动部署、出了问题再修。工具只是手段，目的是让代码从提交到上线这个过程更快、更可靠、更自动化。

这篇文章从实践角度出发，讲一讲 CI/CD 流水线的设计原则和常见方案。

---

## 一、持续集成（CI）

### 1.1 什么是持续集成

持续集成的核心实践：开发者频繁地把代码合并到主分支，每次合并都触发自动化构建和测试。

### 1.2 CI 流水线设计

一个典型的 CI 流水线包括：

1. **代码检出**：从 Git 仓库拉取代码
2. **依赖安装**：安装项目依赖
3. **代码检查**：lint、格式化检查
4. **单元测试**：运行单元测试
5. **集成测试**：运行集成测试
6. **代码覆盖率**：生成覆盖率报告
7. **安全扫描**：依赖漏洞扫描、SAST
8. **构建**：编译打包

### 1.3 质量门禁

质量门禁是 CI 的核心——不合格的代码不允许合并。

```yaml
# GitHub Actions 示例
- name: Quality Gate
  run: |
    # 测试通过率必须 100%
    # 代码覆盖率必须 > 80%
    # 没有 P0/P1 级别的安全漏洞
    # 代码 lint 没有 error
```

---

## 二、持续部署（CD）

### 2.1 部署策略

**蓝绿部署**：维护两套完全相同的环境，切换流量实现零停机。

**金丝雀发布**：先给一小部分用户使用新版本，观察没有问题后再全量发布。

**滚动更新**：逐步替换旧版本的实例。Kubernetes 的默认策略。

### 2.2 环境管理

开发环境 → 测试环境 → 预发布环境 → 生产环境。每个环境的配置通过环境变量或配置中心管理，不要硬编码在代码里。

### 2.3 回滚策略

任何部署都必须有回滚方案。最简单的回滚：回退到上一个版本的镜像重新部署。

---

## 三、CI/CD 工具

### 3.1 GitHub Actions

```yaml
name: CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm test
      - run: npm run lint

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        run: ./deploy.sh
```

### 3.2 GitLab CI

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  script:
    - npm ci
    - npm test

build:
  stage: build
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - docker push registry.example.com/myapp:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/myapp myapp=registry.example.com/myapp:$CI_COMMIT_SHA
  only:
    - main
```

### 3.3 Jenkins

Jenkins 是老牌的 CI/CD 工具，生态丰富但配置复杂。推荐用 Jenkins Pipeline 即代码的方式管理流水线。

---

## 四、GitOps

### 4.1 GitOps 原则

- 所有声明式配置存储在 Git 仓库中
- Git 仓库是系统的唯一事实来源
- 自动化工具将实际状态同步到 Git 中定义的期望状态
- 变更通过 Pull Request 流程审核

### 4.2 ArgoCD

ArgoCD 是 Kubernetes 原生的 GitOps 工具：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    path: apps/my-app
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 4.3 Flux

Flux 是另一个流行的 GitOps 工具，架构更模块化。

---

## 五、基础设施即代码（IaC）

### 5.1 Terraform

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

Terraform 的工作流：plan（预览变更）→ apply（执行变更）→ destroy（销毁资源）。

### 5.2 Ansible

Ansible 是配置管理工具，用 YAML 定义主机配置。

```yaml
- hosts: webservers
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Start nginx
      service:
        name: nginx
        state: started
```

---

## 六、容器化与 Kubernetes

### 6.1 Docker 构建优化

- 多阶段构建减小镜像体积
- 利用构建缓存加速
- 使用 .dockerignore 排除不需要的文件
- 固定依赖版本

### 6.2 Kubernetes 部署

- 使用 Deployment 管理无状态应用
- 配置健康检查和就绪探针
- 设置资源限制和请求
- 使用 ConfigMap 和 Secrets 管理配置
- 配置 HPA（Horizontal Pod Autoscaler）自动扩缩容

---

## 七、监控与可观测性

### 7.1 三大支柱

- **Metrics**：Prometheus + Grafana
- **Logging**：EFK 或 PLG
- **Tracing**：Jaeger 或 Zipkin

### 7.2 告警

```yaml
# Prometheus 告警规则
groups:
- name: app-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "高错误率告警"
```

---

## 八、安全

### 8.1 DevSecOps

安全左移——在 CI 阶段就集成安全扫描：

- SAST（静态应用安全测试）：Semgrep、SonarQube
- DAST（动态应用安全测试）：OWASP ZAP
- SCA（软件成分分析）：Snyk、Dependabot
- 容器镜像扫描：Trivy

### 8.2 Secrets 管理

不要在代码或配置文件中硬编码密钥。使用 Vault、AWS Secrets Manager、或 Kubernetes Secrets。

---

## 九、度量与改进

### 9.1 DORA 指标

- **部署频率**：多久部署一次
- **变更前置时间**：从提交到上线需要多长时间
- **变更失败率**：部署导致故障的比例
- **服务恢复时间**：从故障中恢复需要多长时间

### 9.2 持续改进

定期回顾 CI/CD 流水线的效率，识别瓶颈，持续优化。

---

## 总结

CI/CD 不是一次性搭建完成的，它需要根据团队的实际情况持续调整。从最简单的流水线开始，逐步添加质量门禁、安全扫描、自动化部署。记住，工具是手段，目标是更快、更可靠地交付价值。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days'
),
(
    1,
    'Web 应用安全攻防实战指南',
    'web-security-guide',
    '从渗透测试工程师视角出发，系统讲解 OWASP Top 10 漏洞原理与防御手段，覆盖 XSS、SQL 注入、CSRF、认证鉴权、HTTPS/TLS、CORS、CSP 等核心安全知识点，附带真实攻击场景和安全代码示例。',
    $doc$
# Web 应用安全攻防实战指南

做渗透测试这些年，我发现大多数 Web 应用被攻破的原因都差不多。开发者不是不懂安全，而是不知道攻击者会怎么想。这篇文章我想从攻击者的角度出发，把最常见的 Web 安全漏洞讲清楚——不是那种"你应该注意安全"的空话，而是具体到每一行代码该怎么写。

## OWASP Top 10 概览

OWASP（Open Web Application Security Project）每几年会更新一次 Top 10 列表。2021 版的列表包括：Broken Access Control、Cryptographic Failures、Injection、Insecure Design、Security Misconfiguration、Vulnerable and Outdated Components、Identification and Authentication Failures、Software and Data Integrity Failures、Security Logging and Monitoring Failures、Server-Side Request Forgery。

## XSS：跨站脚本攻击

XSS 分三种类型：存储型（恶意脚本永久存储在服务器上）、反射型（通过 URL 参数传递）、DOM 型（漏洞完全在客户端）。

防御方式：HTML 转义、CSP（Content Security Policy）、HttpOnly Cookie、DOM API 安全使用（优先用 textContent 避免 innerHTML）。

## SQL 注入

防御 SQL 注入的唯一可靠方式是使用参数化查询。ORM 的标准查询是安全的，但如果用了原生查询或者拼接字符串，一样会出问题。二次注入更隐蔽——恶意数据在第一次被存储时被转义，但在第二次被使用时导致注入。

## CSRF：跨站请求伪造

防御方式：CSRF Token（服务端生成随机 token 嵌入表单）+ SameSite Cookie（限制第三方请求是否携带 cookie）。SameSite=Lax 是大多数 Web 应用的推荐选择。

## 认证与鉴权

JWT 的常见问题：使用弱密钥、不验证签名算法、把 JWT 放在 localStorage。修复：使用强随机密钥、始终验证签名、放在 HttpOnly cookie。

密码存储：永远不要用 MD5 或 SHA-256。使用 bcrypt 或 argon2id。

## HTTPS 与 TLS

只开 TLSv1.2 和 TLSv1.3，关掉老版本。启用 HSTS。使用 SSL Labs 测试配置，目标 A+ 评级。

## CORS

不要反射 Origin 头，不要允许所有来源。只允许特定来源，配置 methods 和 allowedHeaders。

## CSP

使用 nonce 允许特定脚本执行。避免 `unsafe-inline` 和 `unsafe-eval`。配置 `frame-ancestors 'none'` 防止点击劫持。

## 速率限制

登录接口、密码重置接口必须做速率限制。实现账户锁定策略——5 次失败后锁定 30 分钟。

## 输入验证

白名单优于黑名单。所有字符串输入都要限制最大长度。数字类型要验证是否真的是数字。

## 安全响应头

X-Frame-Options（防止点击劫持）、X-Content-Type-Options（防止 MIME 嗅探）、Referrer-Policy（控制 Referrer 信息泄露）、Permissions-Policy（限制权限 API）。

## API 安全

API Key 认证、基于角色的访问控制（RBAC）、输入验证、输出编码、敏感数据过滤。

## 容器与部署安全

Docker 使用非 root 用户、依赖安全扫描（npm audit、Snyk）、SAST（Semgrep、SonarQube）、DAST（OWASP ZAP）。

## 安全日志与监控

记录所有认证事件、权限变更、数据修改操作、异常请求。日志中不要记录密码、信用卡号、Session Token。

## 总结

安全不是一次性的任务，而是持续的过程。把安全测试加入 CI/CD，定期更新依赖，对开发团队做安全培训，建立漏洞响应流程。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
)
;

-- 重置序列
SELECT setval('posts_id_seq', COALESCE((SELECT MAX(id) FROM posts), 1), false);
