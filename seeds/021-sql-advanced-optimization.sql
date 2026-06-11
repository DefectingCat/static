INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
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
) ON CONFLICT DO NOTHING;
