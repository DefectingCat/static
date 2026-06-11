INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
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
) ON CONFLICT DO NOTHING;
