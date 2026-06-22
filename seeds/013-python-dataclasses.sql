INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
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
    '/images/covers/python-dataclasses.jpg',
    '<ul>
<li><a href="#dataclass-标准库">dataclass（标准库）</a></li>
<ul>
<li><a href="#基础用法">基础用法</a></li>
<li><a href="#dataclass-参数">dataclass 参数</a></li>
<li><a href="#field-函数">field() 函数</a></li>
<li><a href="#frozen-dataclass-不可变数据类">frozen dataclass（不可变数据类）</a></li>
<li><a href="#继承">继承</a></li>
</ul>
<li><a href="#attrs-第三方库">attrs（第三方库）</a></li>
<ul>
<li><a href="#attrs-的优势">attrs 的优势</a></li>
<li><a href="#attrs-验证器示例">attrs 验证器示例</a></li>
</ul>
<li><a href="#pydantic-数据验证与序列化">Pydantic：数据验证与序列化</a></li>
<ul>
<li><a href="#基础用法">基础用法</a></li>
<li><a href="#pydantic-配置">Pydantic 配置</a></li>
</ul>
<li><a href="#三者对比">三者对比</a></li>
<li><a href="#如何选择">如何选择？</a></li>
<li><a href="#总结">总结</a></li>
<li><a href="#高级数据类特性">高级数据类特性</a></li>
<ul>
<li><a href="#使用-__slots__-优化内存">使用 __slots__ 优化内存</a></li>
<li><a href="#自定义序列化与反序列化">自定义序列化与反序列化</a></li>
<li><a href="#数据类与描述符结合">数据类与描述符结合</a></li>
</ul>
<li><a href="#数据类性能对比与选择指南">数据类性能对比与选择指南</a></li>
<ul>
<li><a href="#性能测试示例">性能测试示例</a></li>
</ul>
</ul>',
    1747,
    9,
    'published',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days'
) ON CONFLICT DO NOTHING;
