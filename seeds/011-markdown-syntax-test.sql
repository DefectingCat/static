INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
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
) ON CONFLICT DO NOTHING;
