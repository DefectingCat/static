INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Nginx 高性能 Web 服务器配置与优化实战',
    'nginx-performance-guide',
    '从架构原理到生产环境调优，覆盖 Nginx master-worker 模型、事件驱动、虚拟主机、location 匹配、upstream 负载均衡、SSL/TLS、HTTP/2、缓存、限流、安全加固、OpenResty Lua 扩展、WebSocket 代理、性能调优与监控',
    $doc$
# Nginx 高性能 Web 服务器配置与优化实战

我第一次真正理解 Nginx 是在 2016 年，当时公司的一台 Apache 服务器在促销活动期间扛不住流量挂了。迁移到 Nginx 之后，同样的硬件跑了原来三倍的请求量。这件事让我意识到，选对工具比堆硬件重要得多。

这篇文章是我这些年折腾 Nginx 的经验总结，从架构原理到生产配置，尽量写得实用。

## 1. Nginx 的架构：master-worker 模型

Nginx 用一个 master 进程管理多个 worker 进程。master 负责读取配置、绑定端口、管理 worker；worker 负责实际处理请求。每个 worker 是一个独立进程，互相之间不共享内存。

worker 数量通常设成 CPU 核心数。太多会增加进程切换开销，太少会浪费 CPU。

每个 worker 内部是事件驱动模型（epoll on Linux，kqueue on macOS）。单个 worker 就能处理成千上万的并发连接，不需要为每个请求开新线程。

## 2. 虚拟主机与 server_name 匹配

Nginx 收到请求后，按优先级匹配 server 块：精确匹配 > 前缀通配符 > 后缀通配符 > 正则表达式 > 默认 server。HTTPS 的虚拟主机匹配有个坑：因为 SSL 握手发生在 HTTP 层之前，Nginx 只能靠 SNI 里的域名来选证书。

## 3. location 匹配规则

匹配优先级从高到低：`=` 精确匹配 > `^~` 前缀匹配（找到后停止搜索正则）> `~` 或 `~*` 正则匹配 > 普通前缀匹配。静态资源用 `^~` 或 `=` 可以跳过正则匹配，提升性能。

## 4. upstream 代理与负载均衡

负载均衡算法：轮询（默认）、加权轮询、IP Hash（会话保持）、Least Connections、一致性哈希。无状态服务用 least_conn 或加权轮询，需要会话保持用 ip_hash，缓存场景用一致性哈希。

健康检查通过 `max_fails` 和 `fail_timeout` 做被动检测。

## 5. SSL/TLS 配置

只开 TLSv1.2 和 TLSv1.3，关掉老版本。HSTS 头让浏览器以后只走 HTTPS。OCSP Stapling 减少客户端验证证书的延迟。`ssl_session_cache` 复用 SSL 会话，减少握手开销。

## 6. 缓存配置

代理缓存减少回源请求。静态资源设置长期缓存。Microcaching 在高并发场景下缓存 1-5 秒，大幅降低后端压力。`proxy_cache_lock on` 确保同一时间只有一个请求去回源。

## 7. 限流与访问控制

请求限速通过 `limit_req_zone` 和 `limit_req` 实现。连接数限制通过 `limit_conn_zone` 和 `limit_conn` 实现。IP 黑白名单通过 `allow`/`deny` 或 `geo` 模块实现。

## 8. 安全加固

隐藏版本信息（server_tokens off）、安全响应头（X-Frame-Options、X-Content-Type-Options、CSP）、限制请求方法、防止路径穿越、限制请求体大小。

## 9. 性能调优

连接处理（worker_connections、multi_accept、epoll）、缓冲区配置（sendfile、tcp_nopush、tcp_nodelay）、超时设置（keepalive_timeout、keepalive_requests）、Gzip 压缩。

## 10. Lua 集成与 OpenResty

OpenResty 把 LuaJIT 嵌入 Nginx，让你在 Nginx 配置里直接写 Lua 代码。可以实现请求限流（令牌桶）、动态路由、JWT 验证等高级功能。

## 11. WebSocket 代理

关键是处理好协议升级。`proxy_read_timeout` 默认是 60 秒，WebSocket 空闲超过这个时间会被断开，所以要调大。

## 12. 监控

stub_status 提供基本的连接统计。配合 nginx-vts-exporter 可以把指标接入 Prometheus + Grafana。

## 13. 常见问题排查

502 Bad Gateway 检查后端服务状态；504 Gateway Timeout 调大超时时间但根本原因是后端性能；413 Request Entity Too Large 增大 client_max_body_size；配置不生效用 nginx -T 查看完整配置。

## 结尾

Nginx 入门不难但精通需要时间。每次线上出问题回头看，往往都是配置里某个参数没调对。建议把线上验证过的配置模板化，新项目直接用。配置改之前一定跑 `nginx -t`。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
) ON CONFLICT DO NOTHING;
