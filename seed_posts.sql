-- 种子数据：高质量测试文章
-- 共 42 篇技术文章，覆盖 20+ 种编程语言
-- 文章内容拆分到 seeds/ 目录，每篇文章一个 SQL 文件

-- 先创建测试用户（如果不存在）
INSERT INTO users (username, email, password_hash, role)
SELECT 'testuser', 'test@example.com', '$argon2id$v=19$m=65536,t=3,p=4$testtesttesttesttesttesttest$testtesttesttesttesttesttesttesttesttest', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE role = 'admin');

-- 插入所有文章（按文件名排序执行）
-- psql 批量执行：
--   for f in seeds/*.sql; do psql -d your_db -f "$f"; done
--
-- 或者用 cat 合并执行：
--   cat seeds/*.sql | psql -d your_db
