INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
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
    NULL,
    '<ul>
<li><a href="#前言">前言</a></li>
<li><a href="#一-websocket-基础">一、WebSocket 基础</a></li>
<ul>
<li><a href="#1-1-协议原理">1.1 协议原理</a></li>
<li><a href="#1-2-与-http-的区别">1.2 与 HTTP 的区别</a></li>
<li><a href="#1-3-适用场景">1.3 适用场景</a></li>
</ul>
<li><a href="#二-前端实现">二、前端实现</a></li>
<ul>
<li><a href="#2-1-原生-websocket-api">2.1 原生 WebSocket API</a></li>
<li><a href="#2-2-socket-io">2.2 Socket.IO</a></li>
</ul>
<li><a href="#三-后端实现">三、后端实现</a></li>
<ul>
<li><a href="#3-1-node-js-websocket-服务端">3.1 Node.js WebSocket 服务端</a></li>
<li><a href="#3-2-心跳机制">3.2 心跳机制</a></li>
<li><a href="#3-3-优雅关闭">3.3 优雅关闭</a></li>
</ul>
<li><a href="#四-多实例部署">四、多实例部署</a></li>
<ul>
<li><a href="#4-1-问题">4.1 问题</a></li>
<li><a href="#4-2-redis-pub-sub">4.2 Redis Pub/Sub</a></li>
<li><a href="#4-3-sticky-session">4.3 Sticky Session</a></li>
</ul>
<li><a href="#五-server-sent-events-sse">五、Server-Sent Events（SSE）</a></li>
<ul>
<li><a href="#5-1-sse-vs-websocket">5.1 SSE vs WebSocket</a></li>
<li><a href="#5-2-前端实现">5.2 前端实现</a></li>
<li><a href="#5-3-node-js-实现">5.3 Node.js 实现</a></li>
</ul>
<li><a href="#六-安全考虑">六、安全考虑</a></li>
<ul>
<li><a href="#6-1-认证">6.1 认证</a></li>
<li><a href="#6-2-防止-ddos">6.2 防止 DDoS</a></li>
<li><a href="#6-3-数据验证">6.3 数据验证</a></li>
</ul>
<li><a href="#七-性能优化">七、性能优化</a></li>
<ul>
<li><a href="#7-1-消息压缩">7.1 消息压缩</a></li>
<li><a href="#7-2-连接池">7.2 连接池</a></li>
<li><a href="#7-3-水平扩展">7.3 水平扩展</a></li>
</ul>
<li><a href="#八-实战-聊天室">八、实战：聊天室</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
    656,
    4,
    'published',
    NOW() - INTERVAL '8 days',
    NOW() - INTERVAL '8 days',
    NOW() - INTERVAL '8 days'
) ON CONFLICT DO NOTHING;
