INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
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
    NULL,
    '<ul>
<li><a href="#什么是装饰器">什么是装饰器？</a></li>
<li><a href="#处理带参数的函数">处理带参数的函数</a></li>
<li><a href="#使用-functools-wraps-保留元数据">使用 functools.wraps 保留元数据</a></li>
<li><a href="#参数化装饰器">参数化装饰器</a></li>
<li><a href="#类装饰器">类装饰器</a></li>
<ul>
<li><a href="#基础类装饰器">基础类装饰器</a></li>
<li><a href="#使用类实现带状态装饰器">使用类实现带状态装饰器</a></li>
</ul>
<li><a href="#内置装饰器实战">内置装饰器实战</a></li>
<ul>
<li><a href="#property-将方法变为属性">@property：将方法变为属性</a></li>
<li><a href="#staticmethod-和-classmethod">@staticmethod 和 @classmethod</a></li>
<li><a href="#functools-lru_cache-自动缓存">@functools.lru_cache：自动缓存</a></li>
<li><a href="#functools-singledispatch-函数重载">@functools.singledispatch：函数重载</a></li>
</ul>
<li><a href="#装饰器组合与顺序">装饰器组合与顺序</a></li>
<li><a href="#实际应用场景">实际应用场景</a></li>
<li><a href="#总结">总结</a></li>
<li><a href="#装饰器模式的高级实战">装饰器模式的高级实战</a></li>
<ul>
<li><a href="#带状态的装饰器">带状态的装饰器</a></li>
<li><a href="#方法装饰器与描述符协议">方法装饰器与描述符协议</a></li>
<li><a href="#装饰器调试与常见问题">装饰器调试与常见问题</a></li>
</ul>
<li><a href="#装饰器设计模式总结">装饰器设计模式总结</a></li>
</ul>',
    1349,
    7,
    'published',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days'
) ON CONFLICT DO NOTHING;
