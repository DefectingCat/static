INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
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
    '/images/covers/go-concurrency-patterns.jpg',
    '<ul>
<li><a href="#goroutine-轻量级并发单元">Goroutine：轻量级并发单元</a></li>
<ul>
<li><a href="#使用-waitgroup-等待-goroutine-完成">使用 WaitGroup 等待 goroutine 完成</a></li>
</ul>
<li><a href="#channel-goroutine-之间的通信桥梁">Channel：goroutine 之间的通信桥梁</a></li>
<ul>
<li><a href="#创建-channel">创建 Channel</a></li>
<li><a href="#无缓冲-channel">无缓冲 Channel</a></li>
<li><a href="#有缓冲-channel">有缓冲 Channel</a></li>
<li><a href="#关闭-channel">关闭 Channel</a></li>
<li><a href="#单向-channel">单向 Channel</a></li>
</ul>
<li><a href="#select-多路复用">Select：多路复用</a></li>
<ul>
<li><a href="#超时处理">超时处理</a></li>
<li><a href="#非阻塞操作">非阻塞操作</a></li>
<li><a href="#随机选择">随机选择</a></li>
</ul>
<li><a href="#常见并发模式">常见并发模式</a></li>
<ul>
<li><a href="#1-生产者-消费者模式">1. 生产者-消费者模式</a></li>
<li><a href="#2-worker-pool-工作池">2. Worker Pool（工作池）</a></li>
<li><a href="#3-pipeline-管道">3. Pipeline（管道）</a></li>
<li><a href="#4-fan-out-fan-in-扇出-扇入">4. Fan-out/Fan-in（扇出/扇入）</a></li>
</ul>
<li><a href="#context-请求级控制">Context：请求级控制</a></li>
<ul>
<li><a href="#context-链式传递">Context 链式传递</a></li>
</ul>
<li><a href="#并发模式对比">并发模式对比</a></li>
<li><a href="#总结">总结</a></li>
<li><a href="#sync-包高级原语">Sync 包高级原语</a></li>
<ul>
<li><a href="#mutex-与-rwmutex">Mutex 与 RWMutex</a></li>
<li><a href="#once-pool-与-cond">Once、Pool 与 Cond</a></li>
</ul>
<li><a href="#go-内存模型与-happens-before">Go 内存模型与 Happens-Before</a></li>
<ul>
<li><a href="#channel-的-happens-before-保证">Channel 的 Happens-Before 保证</a></li>
<li><a href="#其他-happens-before-场景">其他 Happens-Before 场景</a></li>
</ul>
<li><a href="#并发调试与性能优化">并发调试与性能优化</a></li>
<ul>
<li><a href="#race-detector">Race Detector</a></li>
<li><a href="#goroutine-leak-检测">Goroutine Leak 检测</a></li>
<li><a href="#性能分析">性能分析</a></li>
</ul>
<li><a href="#总结">总结</a></li>
</ul>',
    1551,
    8,
    'published',
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '4 days'
) ON CONFLICT DO NOTHING;
