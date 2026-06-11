INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
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
) ON CONFLICT DO NOTHING;
