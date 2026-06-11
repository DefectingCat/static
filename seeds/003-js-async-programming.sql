INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
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
) ON CONFLICT DO NOTHING;
