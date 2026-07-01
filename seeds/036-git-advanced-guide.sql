INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Git 内部原理与高级工作流实战',
    'git-advanced-guide',
    '从 Git 对象模型到分支策略，从 interactive rebase 到 bisect 调试，深入讲解 Git 内部原理和高效协作工作流。',
    $doc$
# Git 内部原理与高级工作流实战

## 前言

大部分开发者用 Git 只会 `add`、`commit`、`push`、`pull`。出了问题就 Google，找到答案照着做，也不理解为什么要这样做。这篇文章想从 Git 的内部原理讲起，帮你理解每个命令背后发生了什么。理解了原理，很多高级操作就自然会用了。

---

## 一、Git 对象模型

### 1.1 三种对象

Git 的核心是三个对象类型：blob（文件内容）、tree（目录结构）、commit（提交信息）。

```bash
# 查看 Git 对象
git cat-file -t HEAD    # 查看对象类型
git cat-file -p HEAD    # 查看对象内容
```

每个 commit 指向一个 tree，tree 指向 blob 和子 tree。commit 的 parent 指针形成提交历史。

### 1.2 SHA-1 哈希

Git 用 SHA-1 哈希作为对象的唯一标识。相同的文件内容会产生相同的 blob 对象，这就是为什么 Git 能高效地检测重复文件。

```bash
# 计算文件的 SHA-1
git hash-object file.txt
```

### 1.3 引用（Refs）

分支和标签本质上都是引用——一个指向 commit 的文件。

```bash
# 分支引用
cat .git/refs/heads/main

# 标签引用
cat .git/refs/tags/v1.0.0
```

---

## 二、Git 工作流

### 2.1 暂存区

暂存区（staging area）是 Git 独特的设计。它让你可以精确控制每次提交包含哪些改动。

```bash
# 部分暂存
git add -p          # 交互式选择要暂存的代码块

# 暂存删除
git rm file.txt     # 从暂存区和工作区删除
git rm --cached file.txt  # 只从暂存区删除
```

### 2.2 HEAD 指针

HEAD 指向当前分支的最新 commit。`git checkout` 本质上是移动 HEAD 指针。

```bash
# 查看 HEAD 指向
cat .git/HEAD

# detached HEAD 状态
git checkout <commit-hash>
```

---

## 三、分支策略

### 3.1 Git Flow

Git Flow 适合有明确发布周期的项目：main（生产分支）、develop（开发分支）、feature/*（功能分支）、release/*（发布分支）、hotfix/*（紧急修复）。

### 3.2 GitHub Flow

GitHub Flow 更简洁：main 分支始终可部署，功能分支通过 Pull Request 合并到 main。

### 3.3 Trunk-Based Development

Trunk-Based Development 更激进：所有开发者直接往 main 分支提交（或用非常短命的分支），配合特性开关控制功能发布。

选哪个策略？看你的发布频率。如果是 SaaS 产品每天发布多次，Trunk-Based Development 最合适。如果是传统软件按月发布，Git Flow 更合适。

---

## 四、高级操作

### 4.1 Interactive Rebase

Interactive rebase 可以修改提交历史，整理 commit。

```bash
# 修改最近 3 次提交
git rebase -i HEAD~3
```

编辑器会显示：

```
pick abc1234 Add login feature
pick def5678 Fix typo in login
pick ghi9012 Add password validation
```

可以改成：

```
pick abc1234 Add login feature
squash def5678 Fix typo in login
pick ghi9012 Add password validation
```

squash 会把两个 commit 合并成一个。

### 4.2 Cherry-Pick

Cherry-pick 把某个 commit 的改动应用到当前分支。

```bash
# 把特定 commit 应用到当前分支
git cherry-pick abc1234

# 把多个 commit 应用
git cherry-pick abc1234 def5678
```

### 4.3 Bisect

Bisect 用二分查找定位引入 bug 的 commit。

```bash
# 开始 bisect
git bisect start

# 标记当前版本有问题
git bisect bad

# 标记已知的好版本
git bisect good v1.0.0

# Git 会自动 checkout 中间的 commit
# 测试后标记
git bisect good    # 或 git bisect bad

# 重复直到找到引入 bug 的 commit
```

### 4.4 Reflog

Reflog 记录了 HEAD 的所有移动历史。即使 `git reset --hard` 丢失了 commit，也可以通过 reflog 找回。

```bash
# 查看 reflog
git reflog

# 恢复丢失的 commit
git checkout <commit-hash>
git branch recover-branch
```

---

## 五、远程协作

### 5.1 Fetch vs Pull

`git fetch` 只下载远程数据，不合并。`git pull` = `git fetch` + `git merge`。

建议用 `git fetch` + `git rebase` 代替 `git pull`，保持提交历史更整洁。

### 5.2 Push Options

```bash
# 推送并创建 Pull Request
git push origin feature-branch -o pull-request

# 推送并自动合并
git push origin main -o merge
```

### 5.3 Git LFS

Git LFS（Large File Storage）用于存储大文件（视频、数据集、二进制文件）。

```bash
# 安装 Git LFS
git lfs install

# 跟踪大文件
git lfs track "*.psd"
git lfs track "*.zip"
```

---

## 六、配置与别名

### 6.1 实用别名

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --oneline --graph --all"
git config --global alias.last "log -1 HEAD"
git config --global alias.unstage "reset HEAD --"
```

### 6.2 .gitattributes

```gitattributes
# 指定换行符
*.sh text eol=lf
*.bat text eol=crlf

# 标记二进制文件
*.png binary
*.jpg binary

# 合并策略
package-lock.json merge=ours
```

---

## 七、常见问题解决

### 7.1 撤销操作

```bash
# 撤销工作区修改
git checkout -- file.txt

# 撤销暂存
git reset HEAD file.txt

# 修改上一次提交
git commit --amend

# 回退到某个 commit
git reset --hard <commit-hash>
```

### 7.2 冲突解决

```bash
# 查看冲突文件
git status

# 解决冲突后
git add <file>
git commit    # 不需要 -m，Git 会自动生成合并提交信息
```

### 7.3 清理

```bash
# 删除已合并的分支
git branch --merged main | grep -v main | xargs git branch -d

# 清理未跟踪的文件
git clean -fd
```

---

## 八、Git Hooks

Git Hooks 是在特定事件发生时自动执行的脚本。

```bash
# .git/hooks/pre-commit
#!/bin/sh
# 在提交前运行 lint
npm run lint
if [ $? -ne 0 ]; then
  echo "Lint 失败，提交被阻止"
  exit 1
fi
```

推荐使用 husky 来管理 Git Hooks：

```bash
npx husky install
npx husky add .husky/pre-commit "npm run lint"
```

---

## 总结

理解 Git 的内部原理（对象模型、引用、暂存区）能让你更自信地使用高级操作。interactive rebase、cherry-pick、bisect 这些工具在日常开发中非常实用。选一个适合你团队的分支策略，配合 Git Hooks 保证代码质量。
$doc$,
    NULL,
    NULL,
    '<ul>
<li><a href="#前言">前言</a></li>
<li><a href="#一-git-对象模型">一、Git 对象模型</a></li>
<ul>
<li><a href="#1-1-三种对象">1.1 三种对象</a></li>
<li><a href="#1-2-sha-1-哈希">1.2 SHA-1 哈希</a></li>
<li><a href="#1-3-引用-refs">1.3 引用（Refs）</a></li>
</ul>
<li><a href="#二-git-工作流">二、Git 工作流</a></li>
<ul>
<li><a href="#2-1-暂存区">2.1 暂存区</a></li>
<li><a href="#2-2-head-指针">2.2 HEAD 指针</a></li>
</ul>
<li><a href="#三-分支策略">三、分支策略</a></li>
<ul>
<li><a href="#3-1-git-flow">3.1 Git Flow</a></li>
<li><a href="#3-2-github-flow">3.2 GitHub Flow</a></li>
<li><a href="#3-3-trunk-based-development">3.3 Trunk-Based Development</a></li>
</ul>
<li><a href="#四-高级操作">四、高级操作</a></li>
<ul>
<li><a href="#4-1-interactive-rebase">4.1 Interactive Rebase</a></li>
<li><a href="#4-2-cherry-pick">4.2 Cherry-Pick</a></li>
<li><a href="#4-3-bisect">4.3 Bisect</a></li>
<li><a href="#4-4-reflog">4.4 Reflog</a></li>
</ul>
<li><a href="#五-远程协作">五、远程协作</a></li>
<ul>
<li><a href="#5-1-fetch-vs-pull">5.1 Fetch vs Pull</a></li>
<li><a href="#5-2-push-options">5.2 Push Options</a></li>
<li><a href="#5-3-git-lfs">5.3 Git LFS</a></li>
</ul>
<li><a href="#六-配置与别名">六、配置与别名</a></li>
<ul>
<li><a href="#6-1-实用别名">6.1 实用别名</a></li>
<li><a href="#6-2-gitattributes">6.2 .gitattributes</a></li>
</ul>
<li><a href="#七-常见问题解决">七、常见问题解决</a></li>
<ul>
<li><a href="#7-1-撤销操作">7.1 撤销操作</a></li>
<li><a href="#7-2-冲突解决">7.2 冲突解决</a></li>
<li><a href="#7-3-清理">7.3 清理</a></li>
</ul>
<li><a href="#八-git-hooks">八、Git Hooks</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
    619,
    4,
    'published',
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '10 days'
) ON CONFLICT DO NOTHING;
