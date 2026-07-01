INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Bash 脚本编程完全指南',
    'bash-scripting-guide',
    'Shell 脚本写多了，你会发现自己在一堆引号和转义符号里迷失。本文从变量、引号、条件测试到进程替换、trap 信号处理，系统梳理 Bash 脚本的方方面面。',
    $doc$
# Bash 脚本编程完全指南

写 Bash 脚本是一件让人既爱又恨的事情。爱的是它随手就能写，打开终端三行代码解决一个问题；恨的是一旦脚本超过 50 行，各种引号、转义、空格问题就开始折磨你。我见过有人因为一行没加引号的 `rm -rf $dir` 把整个 `/home` 目录删掉的。我也见过有人用 `if [ $var == "something" ]` 判断，结果变量为空的时候语法错误。

我写过一条 200 行的 Bash 部署脚本，上线第一天就因为一个未加引号的变量导致把整个生产目录给删了。那次之后，我花了两周时间系统学习了 Bash 的每一个角落。这篇文章就是那些血泪教训的总结。

Bash 是 Linux 世界的通用语言。每个服务器上都有它，每个 DevOps 工程师都用它。掌握 Bash 不是可选技能，是基础设施。本文覆盖变量与引号、条件测试、循环结构、函数定义、数组与关联数组、进程替换、here document、trap 信号处理和实用技巧。

## 变量与引号：Bash 的第一道坎

Bash 的变量赋值看起来简单，实则暗藏杀机。

```bash
# 正确赋值：等号两边不能有空格！
name="Alice"

# 错误：会被解析成命令 name，参数是 "=Alice"
name = "Alice"  # bash: name: command not found

# 错误：会被解析成命令 name，参数是 "Alice"
name= "Alice"   # bash: Alice: command not found
```

这个反直觉的设计源于 Bash 的语法继承。在 shell 里，`name=value command` 是一种环境变量传参的语法，所以等号两侧的空格会让解析器误判。`name` 被当作命令，`=` 和 `"Alice"` 被当作参数。

变量引用有两种方式：

```bash
name="Alice"
echo $name       # Alice

# 推荐用花括号，避免歧义
filename="data"
echo "$filename.txt"      # data.txt

# 不加花括号会怎样？
echo "$filenametxt"       # 空值，因为变量名被解析为 filenametxt
```

花括号 `{}` 的作用很明确：界定变量名的边界。这在字符串插值时尤其重要。比如 `"${prefix}_${suffix}"` 这种写法，没有花括号就乱了。

### 引号的三重境界

Bash 有三种引用方式，它们的区别是很多人搞不清的：

| 引号类型 | 变量扩展 | 命令替换 | 转义 |
|---------|---------|---------|------|
| 双引号 `"` | 扩展 | 扩展 | `\` 有效 |
| 单引号 `'` | 不扩展 | 不扩展 | `\` 不识别 |
| 反引号 `` ` `` | 已废弃 | 执行命令 | 特殊处理 |

```bash
name="Alice"

# 双引号：变量会被扩展
echo "Hello, $name"        # Hello, Alice

# 单引号：原样输出
echo 'Hello, $name'        # Hello, $name

# 混合使用：外层单引号，内层双引号
echo 'Hello, '"$name"'!'   # Hello, Alice!

# 更优雅的做法：在双引号里用转义
echo "The price is \$5"    # The price is $5
```

单引号里的内容没有任何特殊含义，连反斜杠也只是普通字符。这有时候会很烦人：

```bash
# 想要输出一个带单引号的字符串？
echo 'It'''s a trap!'     # It's a trap!
# 技巧：用 ''' 来跳出单引号环境

# 或者干脆用双引号
echo "It's a trap!"        # 简单多了
```

还有一个坑：双引号里的命令替换 `` `cmd` `` 或 `$(cmd)` 会执行：

```bash
date_str="Today is $(date +%Y-%m-%d)"
echo "$date_str"  # Today is 2024-01-15
```

### 特殊变量

Bash 内置了一大堆特殊变量，记不住没关系，常用的就这几个：

```bash
#!/bin/bash

echo "脚本名: $0"
echo "第一个参数: $1"
echo "第二个参数: $2"
echo "参数总数: $#"
echo "所有参数(分开): $@"
echo "所有参数(作为一个字符串): $*"
echo "上一个命令的退出码: $?"
echo "当前进程 PID: $$"
echo "最后一个后台进程 PID: $!"

# 实际用法
if [ $# -lt 2 ]; then
    echo "用法: $0 <源文件> <目标文件>"
    exit 1
fi
```

`$@` 和 `$*` 的区别很多人说不清。用双引号包围时，`"$@"` 把每个参数当作独立的单词（推荐），`"$*"` 把所有参数合并成一个字符串。绝大多数情况下你应该用 `"$@"`。比如 `"$@"` 能正确处理带空格的文件名，而 `"$*"` 会把所有参数粘在一起。

## 条件测试：方括号里的学问

Bash 的条件测试有三种写法：`test`、`[ ]`、`[[ ]]`。新手一般用 `[ ]`，老手都用 `[[ ]]`。

```bash
name="Alice"

# 旧式写法：[ ] 是一个命令，参数之间必须有空格
if [ "$name" = "Alice" ]; then
    echo "Hello, Alice"
fi

# 新式写法：[[ ]] 是关键字，更强大、更安全
if [[ $name == "Alice" ]]; then
    echo "Hello, Alice"
fi
```

`[[ ]]` 相比 `[ ]` 的优势：

1. **不需要对变量加引号**：`[[ $name == "Alice" ]]` 即使 `name` 为空也不会报错。用 `[ ]` 时如果变量为空，会变成 `[ == "Alice" ]`，语法错误。
2. **支持模式匹配**：`[[ $name == A* ]]` 匹配以 A 开头的字符串。
3. **支持正则表达式**：`[[ $name =~ ^[A-Z][a-z]+$ ]]` 可以用正则匹配。
4. **`&&` 和 `||` 直接在内部使用**：`[[ $a == 1 && $b == 2 ]]`，而 `[ ]` 需要用 `-a` 和 `-o`，容易跟文件名冲突。

```bash
# 文件测试
file="/etc/passwd"

if [[ -e $file ]]; then           # 文件存在？
    echo "$file 存在"
fi

if [[ -f $file ]]; then           # 是普通文件？
    echo "$file 是普通文件"
fi

if [[ -d /tmp ]]; then            # 是目录？
    echo "/tmp 是目录"
fi

if [[ -r $file && -w $file ]]; then
    echo "$file 可读且可写"
fi

if [[ -x /bin/ls ]]; then         # 可执行？
    echo "/bin/ls 可执行"
fi

if [[ -s $file ]]; then           # 非空文件？
    echo "$file 非空"
fi

if [[ -L /bin/sh ]]; then         # 是符号链接？
    echo "/bin/sh 是符号链接"
fi

# 字符串测试
str=""

if [[ -z $str ]]; then            # 字符串为空？
    echo "字符串为空"
fi

if [[ -n "hello" ]]; then         # 字符串非空？
    echo "字符串非空"
fi

if [[ "$str" == "" ]]; then      # 另一种空字符串判断
    echo "确实是空"
fi

# 数值比较（注意：必须用 -eq, -ne, -lt, -le, -gt, -ge）
num=42
if [[ $num -eq 42 ]]; then
    echo "等于 42"
fi

if [[ $num -ne 0 ]]; then
    echo "不等于 0"
fi

if [[ $num -gt 40 ]]; then
    echo "大于 40"
fi

# 或者用 (( )) 做算术比较（更推荐）
if (( num > 40 && num < 50 )); then
    echo "在 40 和 50 之间"
fi

if (( num % 2 == 0 )); then
    echo "偶数"
fi
```

有一个坑必须提醒：`=` 和 `==` 在 `[[ ]]` 里效果一样，但在 `[ ]` 里只能用 `=`。数值比较如果用 `=` 会按字符串比较，`[[ 10 -gt 2 ]]` 是对的，`[[ 10 > 2 ]]` 会按字符串比较得出错误结果。另一个坑是 `==` 在 `[[ ]]` 里是模式匹配，不是精确字符串匹配。如果要精确匹配字符串，用 `=` 更安全。

## 循环结构：for、while 与 until

### for 循环

```bash
# 遍历列表
for name in Alice Bob Charlie; do
    echo "Hello, $name"
done

# 遍历文件
for file in *.txt; do
    echo "处理: $file"
done

# 处理带空格的文件名
for file in *.txt; do
    if [[ -f "$file" ]]; then
        echo "处理: '$file'"
    fi
done

# C 风格（需要 Bash）
for ((i = 0; i < 5; i++)); do
    echo "i = $i"
done

# 递减
for ((i = 10; i > 0; i--)); do
    echo "倒计时: $i"
done

# 遍历命令输出
for user in $(cut -d: -f1 /etc/passwd); do
    echo "用户: $user"
done

# 更安全的做法（处理带空格的文件名）
while IFS= read -r line; do
    echo "行: $line"
done < file.txt
```

遍历命令输出时用 `$(...)` 比用反引号 `` `...` `` 好，因为可以嵌套，而且转义规则更直观。比如 `$(basename $(dirname $path))` 这种嵌套用反引号就很难写。

### while 与 until

```bash
# while 循环
count=0
while (( count < 5 )); do
    echo "count = $count"
    ((count++))
done

# 读取文件行 by 行
while IFS= read -r line; do
    echo "读取: $line"
done < input.txt

# 读取命令输出
while IFS= read -r line; do
    echo "输出: $line"
done < <(ls -la)

# until 循环（条件为假时执行）
num=0
until (( num >= 5 )); do
    echo "num = $num"
    ((num++))
done

# 无限循环
while true; do
    echo "按 Ctrl+C 退出"
    sleep 1
done

# 带 break 和 continue
for i in {1..10}; do
    if (( i == 3 )); then
        continue  # 跳过 3
    fi
    if (( i == 7 )); then
        break     # 到 7 停止
    fi
    echo "i = $i"
done
```

`IFS=` 和 `read -r` 是读取文件时的最佳实践。`IFS=` 防止行首行尾的空格被截断，`read -r` 防止反斜杠被当作转义字符处理。如果不用 `-r`，`read` 会把行尾的 `\` 当作续行符处理，这在处理 Windows 路径时尤其危险。

## 函数定义：作用域是个坑

```bash
#!/bin/bash

# 定义函数
greet() {
    local name=$1     # local 关键字限定作用域
    echo "Hello, $name"
}

# 带返回值的函数（只能返回 0-255 的整数）
add() {
    local a=$1
    local b=$2
    echo $((a + b))   # 用 stdout 返回结果
}

# 调用
result=$(add 10 20)
echo "10 + 20 = $result"

# 获取函数返回值（exit status）
check_file() {
    [[ -f $1 ]]
}

if check_file "/etc/passwd"; then
    echo "文件存在"
fi
```

Bash 函数的"返回值"非常受限，只能返回 0 到 255 的整数。如果需要返回复杂数据，通常用 `echo` 输出到 stdout，然后用命令替换捕获。另一种方式是设置全局变量，但这在并发场景下会有问题。

**函数作用域是新手最容易踩的坑**。默认情况下，函数里定义的变量是全局的！

```bash
x=10

bad_function() {
    x=20    # 修改了全局变量！
}

good_function() {
    local x=30    # 只在这个函数里有效
    local y=50    # 局部变量
}

bad_function
echo "x = $x"    # x = 20（被修改了！）

good_function
echo "x = $x"    # x = 20（good_function 没影响）
echo "y = $y"    # y = （空，因为 y 是局部的）
```

养成在函数里对所有变量使用 `local` 的习惯。这是写好 Bash 脚本的第一条军规。我见过太多 bug 是因为函数里忘了加 `local`，把全局变量给覆盖了。

## 字符串操作：Bash 的瑞士军刀

Bash 内置了强大的字符串操作能力，不需要调用 `sed` 或 `awk` 就能完成很多常见的文本处理任务。

```bash
str="Hello, World!"

# 获取长度
len=${#str}
echo "长度: $len"    # 13

# 截取子串（从索引 0 开始）
echo "${str:0:5}"    # Hello
echo "${str:7}"      # World!
echo "${str: -6}"    # World!（注意空格，从末尾数）

# 删除前缀
echo "${str#Hello, }"     # World!
echo "${str#*, }"         # World!（最短匹配）
echo "${str##*, }"        # World!（最长匹配）

# 删除后缀
filename="document.txt.tar.gz"
echo "${filename%.txt*}"     # document
echo "${filename%%.*}"       # document（最长匹配）

# 查找替换
echo "${str/World/Bash}"      # Hello, Bash!
echo "${str//l/L}"            # HeLLo, WorLd!（全局替换）
echo "${str/l}"               # Helo, World!（删除第一个匹配）

# 大小写转换
echo "${str^^}"        # HELLO, WORLD!（全大写）
echo "${str,,}"        # hello, world!（全小写）
echo "${str^}"         # Hello, World!（首字母大写）

# 默认值
unset var
echo "${var:-default}"      # default（var 为空或未定义时返回 default）
echo "${var:=default}"      # default（同时设置 var = default）
echo "${var:?error}"        # 报错：var: error
var="hello"
echo "${var:+set}"          # set（var 非空时返回 set）
```

这些参数扩展在处理文件名、路径和配置时非常有用。比如批量重命名文件：

```bash
for file in *.txt; do
    # 去掉 .txt 后缀，加上 .bak
    newname="${file%.txt}.bak"
    mv "$file" "$newname"
done
```

## 数组与关联数组

Bash 4.0 引入了关联数组（哈希表），让 Bash 终于有点现代语言的样子了。

```bash
#!/bin/bash

# 索引数组
colors=("red" "green" "blue")
echo "第一种颜色: ${colors[0]}"
echo "所有颜色: ${colors[@]}"
echo "数组长度: ${#colors[@]}"

# 遍历数组
for color in "${colors[@]}"; do
    echo "颜色: $color"
done

# 遍历索引
for i in "${!colors[@]}"; do
    echo "索引 $i: ${colors[$i]}"
done

# 追加元素
colors+=("yellow")
colors+=("purple" "orange")

# 删除元素
unset 'colors[2]'    # 删除索引 2 的元素

# 切片
echo "前两个: ${colors[@]:0:2}"
echo "从索引1开始: ${colors[@]:1}"

# 关联数组（Bash 4.0+）
declare -A user
user[name]="Alice"
user[age]=30
user[city]="Beijing"
user[role]="admin"

echo "姓名: ${user[name]}"
echo "所有键: ${!user[@]}"
echo "所有值: ${user[@]}"

# 遍历关联数组
for key in "${!user[@]}"; do
    echo "$key = ${user[$key]}"
done

# 检查键是否存在
if [[ -n "${user[email]}" ]]; then
    echo "有邮箱"
else
    echo "没邮箱"
fi
```

关联数组在 Bash 4 之前是不存在的，这也是为什么很多老脚本用 `eval` 搞出各种黑科技来模拟哈希表。如果你还在用 Bash 3（macOS 默认就是），考虑升级到 Bash 5 或者用 zsh。macOS 用户可以用 `brew install bash` 安装新版 Bash。

## 进程替换：Bash 的黑魔法

进程替换（Process Substitution）是 Bash 的一个高级特性，很多人听说过但不知道怎么用。

```bash
# 语法：<(command) 生成一个可读的文件描述符
#        >(command) 生成一个可写的文件描述符

# 例子：比较两个命令的输出
diff <(ls dir1) <(ls dir2)

# 例子：把多个命令的输出合并处理
cat <(echo "Header") <(cat data.txt) <(echo "Footer")

# 例子：把输出重定向到另一个命令（少见）
cat file.txt > >(grep "error" > errors.log)

# 用进程替换读取命令输出到 while 循环
while IFS= read -r line; do
    echo "处理: $line"
done < <(find . -name "*.txt")
```

进程替换的本质是创建了一个命名管道（named pipe），让命令的输出可以像文件一样被其他命令读取。这对于不接受标准输入的命令特别有用。比如 `diff` 需要两个文件参数，用进程替换可以直接比较两个命令的输出。

```bash
# 不用进程替换的丑陋写法
cat file1 file2 > /tmp/combined.txt
grep "pattern" /tmp/combined.txt
rm /tmp/combined.txt

# 用进程替换
grep "pattern" <(cat file1 file2)
```

进程替换在写复杂管道时简直是救命稻草。不过要注意，它创建的 "文件" 实际上是一个 `/dev/fd/xx` 特殊文件，某些不支持这种文件类型的程序可能会报错。另外，进程替换创建的子进程是异步运行的，如果处理不当可能导致竞争条件。

### xargs：管道的好搭档

`xargs` 把标准输入转换成命令行参数，是管道处理中不可或缺的工具。

```bash
# 基本用法：把 find 的结果传给 rm
find . -name "*.tmp" | xargs rm

# 处理带空格的文件名
find . -name "*.txt" -print0 | xargs -0 rm

# 限制每次传递的参数数量
find . -name "*.log" | xargs -n 100 rm

# 并行执行（-P 指定并发数）
find . -name "*.jpg" | xargs -P 4 -I {} convert {} {}.png

# 从文件读取参数
cat urls.txt | xargs -n 1 curl -O

# 配合 -I 做替换
ls *.txt | xargs -I {} cp {} {}.bak
```

`xargs -0` 是处理带空格文件名的标准做法。`-print0` 让 `find` 用 NUL 字符分隔文件名，`xargs -0` 用 NUL 字符解析，这样文件名里的空格、换行都不会造成问题。

## Here Document 与 Here String

Here Document 让你可以在脚本里嵌入多行文本：

```bash
# Here Document
cat << EOF
这是一个多行文本。
当前用户: $USER
当前目录: $PWD
当前时间: $(date)
EOF

# 禁止变量扩展（在定界符加引号）
cat << 'EOF'
这是纯文本，$USER 不会被扩展。
$(date) 也不会执行。
EOF

# 忽略前导制表符（在 << 后加减号）
cat <<-EOF
	这一行的制表符会被去掉
		这一行也是
				全部去掉
EOF

# Here String（单行）
grep "pattern" <<< "this is a test string"

# 等价于
echo "this is a test string" | grep "pattern"
```

Here Document 在生成配置文件或 SQL 语句时特别方便：

```bash
# 生成配置文件
cat > config.ini << EOF
[database]
host = localhost
port = 5432
name = myapp
user = admin

[server]
port = 8080
workers = 4
max_connections = 100

[logging]
level = info
file = /var/log/app.log
EOF

# 执行 SQL
mysql -u root -p << 'SQL'
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (name, email) VALUES 
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com');
SQL
```

注意上面 SQL heredoc 用了 `'SQL'` 来禁止变量扩展，防止 SQL 里的 `$` 被误解析。如果 SQL 里有 `$` 符号（比如 PostgreSQL 的占位符 `$1`），不加引号的话 Bash 会把它当变量处理。

## 后台作业与并行执行

Bash 支持把任务放到后台执行，配合 `wait` 可以实现简单的并行处理。

```bash
# 后台执行命令
long_task() {
    echo "开始任务 $1"
    sleep "$2"
    echo "任务 $1 完成"
}

# 启动多个后台任务
long_task "A" 3 &
long_task "B" 2 &
long_task "C" 4 &

# 等待所有后台任务完成
echo "等待所有任务完成..."
wait
echo "全部完成"

# 查看后台作业列表
jobs

# 把最近的后台作业调到前台
fg %1

# 暂停当前作业，放到后台
# Ctrl+Z 暂停，然后 bg 放到后台继续执行
```

用 `&` 启动后台任务时，Bash 会输出作业号和进程 ID。`wait` 命令等待所有子进程结束，这在批量处理时非常有用。我曾经用它并行处理几百个日志文件，比串行处理快了将近 10 倍。

但要注意，后台任务的输出会跟前台输出混在一起。如果需要收集每个任务的结果，可以把输出重定向到不同的文件：

```bash
for file in *.log; do
    process_log "$file" > "${file%.log}.out" 2>&1 &
done
wait
```

## Trap：优雅地处理信号

脚本被 `Ctrl+C` 中断时，临时文件没清理，数据库事务没回滚，这种事情你遇到过吗？`trap` 命令就是用来解决这类问题的。

```bash
#!/bin/bash

# 设置临时目录
TMPDIR=$(mktemp -d)
echo "临时目录: $TMPDIR"

# 退出时清理
cleanup() {
    echo "清理临时文件..."
    rm -rf "$TMPDIR"
    echo "完成"
}

# 捕获 EXIT 信号（脚本退出时，无论正常还是异常）
trap cleanup EXIT

# 捕获 SIGINT (Ctrl+C)
trap 'echo "收到中断信号，正在退出..."; exit 1' INT

# 捕获 SIGTERM (kill 默认信号)
trap 'echo "收到终止信号"; exit 1' TERM

# 模拟工作
echo "开始处理..."
sleep 5
echo "处理完成"

# 正常退出时，EXIT trap 会自动执行 cleanup
```

`trap` 的常见用法：

```bash
# 忽略信号
trap '' INT    # 忽略 Ctrl+C
trap '-' INT   # 恢复默认处理

# 捕获多个信号
trap 'echo "收到信号"; cleanup' INT TERM EXIT

# 查看当前设置的 trap
trap -p

# 在函数里局部设置 trap（Bash 4.0+）
process_with_cleanup() {
    local temp=$(mktemp)
    trap "rm -f $temp" RETURN    # 函数返回时执行
    # 处理...
    echo "处理文件: $temp"
}

# 嵌套 trap
set -E  # 继承 ERR trap
set -T  # 继承 DEBUG 和 RETURN trap
```

`trap` 配合临时文件处理是写健壮脚本的必修课。我见过太多脚本在 `/tmp` 里留下成堆的垃圾文件，就是因为没做清理。`mktemp` + `trap cleanup EXIT` 是标准搭配。

## 实用技巧与最佳实践

### 严格模式

在脚本开头加上这几行，能避免 80% 的常见问题：

```bash
#!/bin/bash
set -euo pipefail
IFS=$'
	'
```

- `set -e`：命令失败（返回非 0）时立即退出。但要注意，它在某些情况下不生效（比如管道中间失败、if 条件里的命令）。
- `set -u`：使用未定义变量时报错。防止 `rm -rf $uninitialized/` 这种悲剧。
- `set -o pipefail`：管道中任一命令失败，整个管道返回非 0。防止 `grep | something` 中 grep 没找到但管道返回成功。
- `IFS=$'
	'`：把字段分隔符设为换行和制表符，避免空格引起的拆分问题。

### 调试技巧

```bash
#!/bin/bash
set -x          # 开启调试模式，打印每条执行的命令
# ... 脚本代码 ...
set +x          # 关闭调试模式

# 或者运行脚本时开启调试
bash -x script.sh

# 只在特定部分调试
set -x
critical_function
set +x

# 打印执行的命令但不执行（dry run）
set -n

# 更精细的调试
PS4='+ ${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
```

### 处理命令失败

```bash
# 检查命令是否成功
if ! command -v node &> /dev/null; then
    echo "node 未安装"
    exit 1
fi

# 或者使用 ||
grep "pattern" file.txt || echo "未找到匹配"

# 使用 && 确保前一条成功才执行下一条
mkdir -p "$dir" && cd "$dir" || exit 1

# 管道中的错误处理
set -o pipefail
some_command | grep "filter" | head -n 10
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "some_command 失败了"
fi

# 显式检查退出码
rm "$file"
exit_code=$?
if (( exit_code != 0 )); then
    echo "删除失败，退出码: $exit_code"
fi
```

### 正则表达式与文本处理

Bash 3.2+ 支持正则表达式匹配，配合 `grep`、`sed`、`awk` 可以完成复杂的文本处理。

```bash
# Bash 内置正则匹配
if [[ "hello@example.com" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "邮箱格式正确"
fi

# 提取匹配的组
string="version=1.2.3"
if [[ $string =~ version=([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "主版本: ${BASH_REMATCH[1]}"
    echo "次版本: ${BASH_REMATCH[2]}"
    echo "修订: ${BASH_REMATCH[3]}"
fi

# sed 常用技巧
sed 's/old/new/g' file.txt          # 替换所有 old 为 new
sed '/^#/d' file.txt                # 删除以 # 开头的行
sed -n '10,20p' file.txt            # 打印第 10-20 行
sed 's/  */ /g' file.txt            # 多个空格合并为一个

# awk 常用技巧
awk '{print $1}' file.txt           # 打印第一列
awk -F',' '{print $2}' file.csv     # 以逗号分隔，打印第二列
awk '$3 > 100 {print $0}' data.txt  # 第三列大于 100 的行
awk '{sum+=$1} END {print sum}' nums.txt  # 求和
```

### 环境变量与配置文件

脚本经常需要读取环境变量或配置文件。处理这些时要注意默认值和安全性。

```bash
# 读取环境变量（带默认值）
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export LOG_LEVEL="${LOG_LEVEL:-info}"

# 检查必需的环境变量
: "${API_KEY:?API_KEY 环境变量必须设置}"

# 读取 .env 文件
load_env() {
    local env_file="${1:-.env}"
    if [[ -f "$env_file" ]]; then
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            # 去除首尾空格
            key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            # 去除引号
            value="${value%\"}"
            value="${value#\"}"
            export "$key=$value"
        done < "$env_file"
    fi
}

# 生成配置文件
generate_config() {
    cat > config.ini << EOF
[app]
name = ${APP_NAME:-myapp}
version = ${VERSION:-1.0.0}
environment = ${ENV:-development}

[database]
host = ${DB_HOST:-localhost}
port = ${DB_PORT:-5432}
pool_size = ${DB_POOL:-10}
EOF
}
```

环境变量的处理有一个常见陷阱：在脚本里 `export` 的变量会传递给子进程，但不会影响父 shell。如果你运行 `./script.sh`，脚本里的 `export` 对当前终端无效；要用 `source script.sh` 才会生效。

### 路径处理

```bash
# 获取脚本所在目录（不管从哪里调用）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 安全地处理文件名（处理特殊字符）
filename="file with spaces.txt"
cp "$filename" /tmp/    # 必须用引号

# 路径操作
dirname "/home/user/file.txt"    # /home/user
basename "/home/user/file.txt"   # file.txt
basename "/home/user/file.txt" .txt   # file

# 去除路径最后的斜杠
path="/home/user/"
echo "${path%/}"    # /home/user

# 默认值
output_dir="${OUTPUT_DIR:-/tmp/default}"
```

### 一个完整的实用脚本模板

```bash
#!/bin/bash
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
用法: $SCRIPT_NAME [选项] <参数>

选项:
    -h, --help      显示帮助信息
    -v, --verbose   详细输出
    -o, --output    输出文件
    -n, --dry-run   模拟运行，不实际执行

示例:
    $SCRIPT_NAME -v input.txt
    $SCRIPT_NAME -o result.json input.txt
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

warn() {
    echo "[WARN] $*" >&2
}

main() {
    local verbose=false
    local output=""
    local dry_run=false
    local input=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -*)
                error "未知选项: $1"
                ;;
            *)
                input="$1"
                shift
                ;;
        esac
    done

    [[ -z "$input" ]] && error "缺少输入文件"
    [[ -f "$input" ]] || error "文件不存在: $input"

    $verbose && log "处理文件: $input"
    $verbose && log "脚本目录: $SCRIPT_DIR"

    if $dry_run; then
        log "[DRY-RUN] 将输出到: ${output:-stdout}"
        exit 0
    fi

    # 实际处理逻辑...
    log "处理完成"
}

main "$@"
```

## 总结

Bash 脚本是一门"够用就行"的语言。它不是为了写大型应用而生的，它的主战场是自动化、部署、系统管理和胶水代码。当你需要用 5 行代码完成一个文件批处理任务时，Bash 是最佳选择。当你需要写超过 500 行的复杂逻辑时，考虑用 Python 或 Go 重写。

### 什么时候用 Bash，什么时候不用

用 Bash 的场景：
- 文件和目录操作
- 调用系统命令并组合它们的输出
- 简单的文本处理
- 启动/停止服务
- 构建和部署脚本

不要用 Bash 的场景：
- 复杂的数学计算
- 网络请求和 API 调用（用 Python/curl）
- 需要解析复杂数据格式（JSON/XML/YAML）
- 多线程/多进程并发
- 需要跨平台兼容（用 Python）

### 常见陷阱速查

| 问题 | 错误写法 | 正确写法 |
|------|---------|---------|
| 变量含空格 | `rm $file` | `rm "$file"` |
| 赋值加空格 | `name = "value"` | `name="value"` |
| 数值比较 | `[ $n > 5 ]` | `(( n > 5 ))` |
| 字符串比较 | `[[ $s > "abc" ]]` | `[[ $s > "abc" ]]` 是对的，但容易混淆 |
| 数组索引 | `${arr[0]}` | `${arr[0]}` 是对的，但注意 `@` 和 `*` |
| 命令替换丢失 | `var=$(cmd)` | `var=$(cmd)` 是对的，但注意引号 |
| 管道错误被吞 | `cmd1 | cmd2` | `set -o pipefail` |
| 函数变量污染 | `x=10` | `local x=10` |

| 主题 | 关键要点 |
|------|---------|
| 变量 | 赋值不加空格，引用用 `"${var}"` |
| 引号 | 双引号扩展，单引号不扩展，用 `[[ ]]` 代替 `[ ]` |
| 条件 | `[[ ]]` 更安全，`-eq` 用于数字，`=` 用于字符串 |
| 循环 | `"${array[@]}"` 遍历数组，用 `while read` 读文件 |
| 函数 | 总是用 `local`，用 `echo` 或全局变量返回结果 |
| 数组 | `declare -A` 声明关联数组 |
| 进程替换 | `<(cmd)` 创建可读文件描述符 |
| Here Doc | `<< 'EOF'` 禁止变量扩展 |
| trap | `EXIT` 信号保证清理代码执行 |
| 严格模式 | `set -euo pipefail` 是最佳实践 |

Shell 脚本写多了，你会发现自己在一堆引号和转义符号里迷失。这时候记住两条原则：一是**所有变量都用双引号包围**，二是**启用严格模式**。这两条能帮你避开 90% 的坑。剩下的 10%，靠的是经验和对 edge case 的敬畏。

> "Bash 是一门让你先用起来再慢慢后悔的语言。" —— 某不知名运维工程师

---

*本文首发于 Yggdrasil 博客*
    $doc$,
        NULL,
        NULL,
        '<ul>
<li><a href="#变量与引号-bash-的第一道坎">变量与引号：Bash 的第一道坎</a></li>
<ul>
<li><a href="#引号的三重境界">引号的三重境界</a></li>
<li><a href="#特殊变量">特殊变量</a></li>
</ul>
<li><a href="#条件测试-方括号里的学问">条件测试：方括号里的学问</a></li>
<li><a href="#循环结构-for-while-与-until">循环结构：for、while 与 until</a></li>
<ul>
<li><a href="#for-循环">for 循环</a></li>
<li><a href="#while-与-until">while 与 until</a></li>
</ul>
<li><a href="#函数定义-作用域是个坑">函数定义：作用域是个坑</a></li>
<li><a href="#字符串操作-bash-的瑞士军刀">字符串操作：Bash 的瑞士军刀</a></li>
<li><a href="#数组与关联数组">数组与关联数组</a></li>
<li><a href="#进程替换-bash-的黑魔法">进程替换：Bash 的黑魔法</a></li>
<ul>
<li><a href="#xargs-管道的好搭档">xargs：管道的好搭档</a></li>
</ul>
<li><a href="#here-document-与-here-string">Here Document 与 Here String</a></li>
<li><a href="#后台作业与并行执行">后台作业与并行执行</a></li>
<li><a href="#trap-优雅地处理信号">Trap：优雅地处理信号</a></li>
<li><a href="#实用技巧与最佳实践">实用技巧与最佳实践</a></li>
<ul>
<li><a href="#严格模式">严格模式</a></li>
<li><a href="#调试技巧">调试技巧</a></li>
<li><a href="#处理命令失败">处理命令失败</a></li>
<li><a href="#正则表达式与文本处理">正则表达式与文本处理</a></li>
<li><a href="#环境变量与配置文件">环境变量与配置文件</a></li>
<li><a href="#路径处理">路径处理</a></li>
<li><a href="#一个完整的实用脚本模板">一个完整的实用脚本模板</a></li>
</ul>
<li><a href="#总结">总结</a></li>
<ul>
<li><a href="#什么时候用-bash-什么时候不用">什么时候用 Bash，什么时候不用</a></li>
<li><a href="#常见陷阱速查">常见陷阱速查</a></li>
</ul>
</ul>',
        2450,
        13,
        'published',
    NOW() - INTERVAL '25 days',
    NOW() - INTERVAL '25 days',
    NOW() - INTERVAL '25 days'
) ON CONFLICT DO NOTHING;
