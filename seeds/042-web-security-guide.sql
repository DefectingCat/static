INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Web 应用安全攻防实战指南',
    'web-security-guide',
    '从渗透测试工程师视角出发，系统讲解 OWASP Top 10 漏洞原理与防御手段，覆盖 XSS、SQL 注入、CSRF、认证鉴权、HTTPS/TLS、CORS、CSP 等核心安全知识点，附带真实攻击场景和安全代码示例。',
    $doc$
# Web 应用安全攻防实战指南

做渗透测试这些年，我发现大多数 Web 应用被攻破的原因都差不多。开发者不是不懂安全，而是不知道攻击者会怎么想。这篇文章我想从攻击者的角度出发，把最常见的 Web 安全漏洞讲清楚——不是那种"你应该注意安全"的空话，而是具体到每一行代码该怎么写。

## OWASP Top 10 概览

OWASP（Open Web Application Security Project）每几年会更新一次 Top 10 列表。2021 版的列表包括：Broken Access Control、Cryptographic Failures、Injection、Insecure Design、Security Misconfiguration、Vulnerable and Outdated Components、Identification and Authentication Failures、Software and Data Integrity Failures、Security Logging and Monitoring Failures、Server-Side Request Forgery。

## XSS：跨站脚本攻击

XSS 分三种类型：存储型（恶意脚本永久存储在服务器上）、反射型（通过 URL 参数传递）、DOM 型（漏洞完全在客户端）。

防御方式：HTML 转义、CSP（Content Security Policy）、HttpOnly Cookie、DOM API 安全使用（优先用 textContent 避免 innerHTML）。

## SQL 注入

防御 SQL 注入的唯一可靠方式是使用参数化查询。ORM 的标准查询是安全的，但如果用了原生查询或者拼接字符串，一样会出问题。二次注入更隐蔽——恶意数据在第一次被存储时被转义，但在第二次被使用时导致注入。

## CSRF：跨站请求伪造

防御方式：CSRF Token（服务端生成随机 token 嵌入表单）+ SameSite Cookie（限制第三方请求是否携带 cookie）。SameSite=Lax 是大多数 Web 应用的推荐选择。

## 认证与鉴权

JWT 的常见问题：使用弱密钥、不验证签名算法、把 JWT 放在 localStorage。修复：使用强随机密钥、始终验证签名、放在 HttpOnly cookie。

密码存储：永远不要用 MD5 或 SHA-256。使用 bcrypt 或 argon2id。

## HTTPS 与 TLS

只开 TLSv1.2 和 TLSv1.3，关掉老版本。启用 HSTS。使用 SSL Labs 测试配置，目标 A+ 评级。

## CORS

不要反射 Origin 头，不要允许所有来源。只允许特定来源，配置 methods 和 allowedHeaders。

## CSP

使用 nonce 允许特定脚本执行。避免 `unsafe-inline` 和 `unsafe-eval`。配置 `frame-ancestors 'none'` 防止点击劫持。

## 速率限制

登录接口、密码重置接口必须做速率限制。实现账户锁定策略——5 次失败后锁定 30 分钟。

## 输入验证

白名单优于黑名单。所有字符串输入都要限制最大长度。数字类型要验证是否真的是数字。

## 安全响应头

X-Frame-Options（防止点击劫持）、X-Content-Type-Options（防止 MIME 嗅探）、Referrer-Policy（控制 Referrer 信息泄露）、Permissions-Policy（限制权限 API）。

## API 安全

API Key 认证、基于角色的访问控制（RBAC）、输入验证、输出编码、敏感数据过滤。

## 容器与部署安全

Docker 使用非 root 用户、依赖安全扫描（npm audit、Snyk）、SAST（Semgrep、SonarQube）、DAST（OWASP ZAP）。

## 安全日志与监控

记录所有认证事件、权限变更、数据修改操作、异常请求。日志中不要记录密码、信用卡号、Session Token。

## 总结

安全不是一次性的任务，而是持续的过程。把安全测试加入 CI/CD，定期更新依赖，对开发团队做安全培训，建立漏洞响应流程。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
) ON CONFLICT DO NOTHING;
