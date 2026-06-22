INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
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
    '/images/covers/redis-complete-guide.jpg',
    '<ul>
<li><a href="#前言">前言</a></li>
<li><a href="#一-redis-基础">一、Redis 基础</a></li>
<ul>
<li><a href="#1-1-为什么-redis-这么快">1.1 为什么 Redis 这么快</a></li>
<li><a href="#1-2-安装与配置">1.2 安装与配置</a></li>
</ul>
<li><a href="#二-五种基础数据结构">二、五种基础数据结构</a></li>
<ul>
<li><a href="#2-1-string">2.1 String</a></li>
<li><a href="#2-2-hash">2.2 Hash</a></li>
<li><a href="#2-4-list">2.4 List</a></li>
<li><a href="#2-5-set">2.5 Set</a></li>
<li><a href="#2-6-sorted-set-zset">2.6 Sorted Set（ZSet）</a></li>
</ul>
<li><a href="#三-高级数据结构">三、高级数据结构</a></li>
<ul>
<li><a href="#3-1-hyperloglog">3.1 HyperLogLog</a></li>
<li><a href="#3-2-bitmap">3.2 Bitmap</a></li>
<li><a href="#3-3-stream">3.3 Stream</a></li>
</ul>
<li><a href="#四-过期与淘汰策略">四、过期与淘汰策略</a></li>
<ul>
<li><a href="#4-1-设置过期时间">4.1 设置过期时间</a></li>
<li><a href="#4-2-内存淘汰策略">4.2 内存淘汰策略</a></li>
</ul>
<li><a href="#五-持久化机制">五、持久化机制</a></li>
<ul>
<li><a href="#5-1-rdb">5.1 RDB</a></li>
<li><a href="#5-2-aof">5.2 AOF</a></li>
<li><a href="#5-3-混合持久化">5.3 混合持久化</a></li>
</ul>
<li><a href="#六-发布订阅">六、发布订阅</a></li>
<li><a href="#七-lua-脚本">七、Lua 脚本</a></li>
<li><a href="#八-分布式锁">八、分布式锁</a></li>
<ul>
<li><a href="#8-1-基本实现">8.1 基本实现</a></li>
<li><a href="#8-2-redlock-算法">8.2 Redlock 算法</a></li>
</ul>
<li><a href="#九-集群方案">九、集群方案</a></li>
<ul>
<li><a href="#9-1-redis-sentinel">9.1 Redis Sentinel</a></li>
<li><a href="#9-2-redis-cluster">9.2 Redis Cluster</a></li>
</ul>
<li><a href="#十-性能优化">十、性能优化</a></li>
<ul>
<li><a href="#10-1-pipeline">10.1 Pipeline</a></li>
<li><a href="#10-2-大-key-问题">10.2 大 Key 问题</a></li>
<li><a href="#10-3-热-key-问题">10.3 热 Key 问题</a></li>
</ul>
<li><a href="#结尾">结尾</a></li>
</ul>',
    760,
    4,
    'published',
    NOW() - INTERVAL '13 days',
    NOW() - INTERVAL '13 days',
    NOW() - INTERVAL '13 days'
) ON CONFLICT DO NOTHING;
