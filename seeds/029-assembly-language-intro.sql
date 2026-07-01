INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Assembly 语言入门：从机器码到寄存器',
    'assembly-language-intro',
    'assembly 不是已经死了吗？不，它活得很好。操作系统内核、密码学库、游戏引擎里的 hot path，都还在用 assembly。本文从 x86-64 架构讲起，带你理解 CPU 是怎么执行代码的。',
    $doc$
# Assembly 语言入门：从机器码到寄存器

Assembly 不是已经死了吗？

每次我说我在学汇编，都有人这么问我。事实是，assembly 活得很好。操作系统内核里到处是它，OpenSSL 的加密核心有它，Linux 的 `memcpy` 实现有它，连 Chrome 的 V8 引擎在 JIT 编译后输出的是它。只不过现在写 assembly 的人少了，它需要你的场景更具体。

我学 assembly 是因为一个调试问题。一个 C 程序在 release 模式下崩溃了，gdb 里的栈 trace 完全不对。最后发现是某个内联汇编的约束写错了，编译器把寄存器分配搞乱了。那次之后我意识到：不懂 assembly，你连自己的程序在干什么都不知道。你写的高级语言代码，最终都变成了 CPU 执行的机器指令。不理解这一层，debug 时就只能盲人摸象。

本文面向有一定 C/C++ 基础的读者，从 x86-64 架构讲起，覆盖寄存器、栈帧、系统调用、内存模型、调用约定、内联汇编和调试技巧。读完之后，你应该能读懂编译器生成的汇编代码，能在 gdb 里做基本的汇编级调试。

## x86-64 架构概览

x86-64（也叫 AMD64）是目前桌面和服务器 CPU 的主流架构。它向后兼容 32 位的 x86，但扩展到了 64 位。Intel 和 AMD 都有实现，指令集基本一致（除了一些扩展指令集如 AVX-512 有差异）。

### 通用寄存器

x86-64 有 16 个 64 位通用寄存器：

| 64 位 | 32 位 | 16 位 | 8 位 | 用途 |
|-------|-------|-------|------|------|
| `rax` | `eax` | `ax` | `al` | 累加器，返回值 |
| `rbx` | `ebx` | `bx` | `bl` | 基址寄存器 |
| `rcx` | `ecx` | `cx` | `cl` | 计数器（循环） |
| `rdx` | `edx` | `dx` | `dl` | 数据寄存器 |
| `rsi` | `esi` | `si` | `sil` | 源索引（字符串操作） |
| `rdi` | `edi` | `di` | `dil` | 目的索引（字符串操作） |
| `rbp` | `ebp` | `bp` | `bpl` | 栈帧基址 |
| `rsp` | `esp` | `sp` | `spl` | 栈指针 |
| `r8`-`r15` | `r8d`-`r15d` | `r8w`-`r15w` | `r8b`-`r15b` | 扩展寄存器 |

寄存器的命名规则是这样的：`r` 前缀表示 64 位，`e` 前缀表示 32 位（继承自 32 位时代），没有前缀的 `ax`/`bx` 是 16 位，后缀 `l` 表示低 8 位，后缀 `h` 表示高 8 位（仅 `ah`/`bh`/`ch`/`dh`）。

```asm
; 寄存器使用示例
mov rax, 0x123456789ABCDEF0    ; rax = 0x123456789ABCDEF0
mov eax, 0x12345678            ; eax = 0x12345678，rax 的高 32 位自动清零
mov ax, 0x1234                 ; ax = 0x1234
mov al, 0x12                   ; al = 0x12
```

`mov eax, value` 会把 `rax` 的高 32 位清零，这是 x86-64 的设计：写入 32 位寄存器会自动将对应的 64 位寄存器的高位置 0。这个细节在优化代码时很重要。如果你依赖 `rax` 的高 32 位保留旧值，用 `mov eax` 就会把它们清零。

### 指令格式

x86-64 的指令格式是变长的，从 1 字节到 15 字节不等：

```
[前缀] [REX前缀] [操作码] [ModR/M] [SIB] [位移] [立即数]
```

大多数指令的格式是：`操作码 目的操作数, 源操作数`

```asm
; 基本指令
mov rax, rbx        ; rax = rbx
add rax, 10         ; rax += 10
sub rax, rbx        ; rax -= rbx
inc rax             ; rax++
dec rax             ; rax--
neg rax             ; rax = -rax
not rax             ; rax = ~rax
and rax, rbx        ; rax &= rbx
or rax, rbx         ; rax |= rbx
xor rax, rax        ; rax = 0（清零寄存器的惯用写法）
cmp rax, rbx        ; 比较 rax 和 rbx（设置标志位）
test rax, rax       ; 测试 rax 是否为 0（设置标志位）
```

`xor rax, rax` 是清零寄存器的最佳方式。比 `mov rax, 0` 更短（2 字节 vs 7 字节），而且不需要立即数。现代 CPU 还会对 `xor reg, reg` 做特殊优化，避免伪依赖。

## 栈帧与函数调用

栈是从高地址向低地址增长的。`rsp` 始终指向栈顶。每次 `push` 操作把数据压入栈顶（`rsp` 减小），`pop` 操作从栈顶弹出数据（`rsp` 增大）。

```asm
; 典型的函数 prologue
push rbp            ; 保存旧的栈帧基址
mov rbp, rsp        ; 建立新的栈帧
sub rsp, 32         ; 分配 32 字节局部变量空间

; ... 函数体 ...

; 典型的函数 epilogue
mov rsp, rbp        ; 恢复栈指针
pop rbp             ; 恢复栈帧基址
ret                 ; 返回调用者
```

这是经典的 x86 函数调用约定。进入函数时，`rbp` 被保存，新的栈帧建立；退出时，栈帧恢复。不过现代编译器（gcc -O2 以上）通常不用 `rbp` 做栈帧指针，而是把它当作普通寄存器用，这样可以多一个可用寄存器。这叫 "omit frame pointer" 优化。

x86-64 的函数参数通过寄存器传递：

| 参数位置 | 整数/指针 | 浮点数 |
|---------|----------|--------|
| 第 1 个 | `rdi` | `xmm0` |
| 第 2 个 | `rsi` | `xmm1` |
| 第 3 个 | `rdx` | `xmm2` |
| 第 4 个 | `rcx` | `xmm3` |
| 第 5 个 | `r8` | `xmm4` |
| 第 6 个 | `r9` | `xmm5` |
| 第 7+ 个 | 栈 | 栈 |

返回值放在 `rax`（整数）或 `xmm0`（浮点数）。

```asm
; C 函数: int add(int a, int b)
; a 在 rdi, b 在 rsi
; 返回值在 rax

.global add
add:
    mov eax, edi        ; eax = a
    add eax, esi        ; eax += b
    ret                 ; 返回，结果在 rax
```

用 `eax` 而不是 `rax` 是因为 C 的 `int` 是 32 位。`mov eax, edi` 会自动清零 `rax` 的高 32 位，符合 System V AMD64 ABI 的要求。如果要返回 64 位值，就用 `rax`。

函数调用的完整过程：

```asm
; 调用者
main:
    push rbp
    mov rbp, rsp
    
    mov edi, 10         ; 第 1 个参数
    mov esi, 20         ; 第 2 个参数
    call add            ; 调用 add
    ; 返回值在 eax
    
    mov esi, eax        ; 准备第 2 个参数
    mov edi, 5          ; 第 1 个参数
    call add            ; 再调用一次
    
    pop rbp
    ret
```

## 系统调用：跟内核打交道

系统调用是用户态程序进入内核的唯一途径。x86-64 用 `syscall` 指令发起系统调用。

```asm
; Linux x86-64 系统调用: write(fd, buf, count)
; 系统调用号: 1 (sys_write)
; 参数: rdi=fd, rsi=buf, rdx=count

section .data
    msg db "Hello, Assembly!", 10   ; 10 是换行符
    len equ $ - msg                  ; 计算字符串长度

section .text
    global _start

_start:
    ; write(1, msg, len)
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg        ; 缓冲区地址
    mov rdx, len        ; 长度
    syscall             ; 发起系统调用

    ; exit(0)
    mov rax, 60         ; sys_exit
    mov rdi, 0          ; 退出码
    syscall
```

编译和运行：

```bash
nasm -f elf64 hello.asm -o hello.o
ld hello.o -o hello
./hello
```

x86-64 Linux 的系统调用约定：
- `rax` = 系统调用号
- `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9` = 参数 1-6
- `rcx` 和 `r11` 被 `syscall` 指令破坏
- 返回值在 `rax`，负值表示错误（-errno）

常用系统调用号：

| 系统调用 | 号 | 说明 |
|---------|---|------|
| read | 0 | 从文件描述符读 |
| write | 1 | 向文件描述符写 |
| open | 2 | 打开文件 |
| close | 3 | 关闭文件描述符 |
| mmap | 9 | 内存映射 |
| brk | 12 | 调整堆大小 |
| exit | 60 | 进程退出 |
| getpid | 39 | 获取进程 ID |
| clone | 56 | 创建线程/进程 |

系统调用的开销比函数调用大得多，因为它涉及从用户态切换到内核态。频繁的系统调用是性能瓶颈的常见来源。

## 内存模型与寻址模式

x86-64 支持多种寻址模式：

```asm
; 直接寻址
mov rax, [0x1000]       ; 从地址 0x1000 读取 8 字节

; 寄存器间接寻址
mov rax, [rbx]          ; 从 rbx 指向的地址读取

; 基址 + 位移
mov rax, [rbx + 8]      ; 从 rbx + 8 处读取
mov rax, [rbx - 16]     ; 从 rbx - 16 处读取

; 基址 + 索引 * 比例
mov rax, [rbx + rdi * 4]    ; 从 rbx + rdi*4 处读取
; 比例可以是 1, 2, 4, 8

; 完整的寻址
mov rax, [rbx + rdi * 8 + 16]   ; 从 rbx + rdi*8 + 16 处读取
```

这种灵活的寻址模式是 x86 CISC 设计的遗产。数组访问 `arr[i]` 可以一条指令完成：`mov rax, [arr + rdi * 8]`。对于 `int64_t arr[]`，比例因子是 8；对于 `int32_t arr[]`，比例因子是 4。编译器会自动选择合适的比例因子。

### 内存段

x86-64 的内存分段模型被大大简化了。Linux 下基本只有三个段：代码段、数据段、栈段。64 位模式下，段寄存器（`cs`、`ds`、`ss`）的作用被弱化，主要用于权限检查。

真正重要的是**页表**。x86-64 用 4 级页表把虚拟地址映射到物理地址。每个进程有独立的页表，由操作系统管理。

```
虚拟地址:
[CR3 -> PML4 -> PDPT -> PD -> PT -> 物理页偏移]
```

页大小通常是 4KB，但也可以配置 2MB 的大页（huge page）用于高性能场景。数据库系统和大内存应用经常用 huge page 减少 TLB miss。

## 调用约定：ABI 的细节

**调用约定**（Calling Convention）规定了函数调用时参数怎么传、寄存器谁负责保存。x86-64 主要有两种：System V AMD64 ABI（Linux/macOS）和 Microsoft x64 ABI（Windows）。

### System V AMD64 ABI（Linux/macOS）

```asm
; 调用者保存的寄存器：rax, rcx, rdx, rsi, rdi, r8-r11
; 被调用者保存的寄存器：rbx, rbp, r12-r15
; 栈必须 16 字节对齐

; 调用一个函数
my_function:
    push rbx            ; 保存被调用者保存的寄存器
    
    mov rdi, 42         ; 第 1 个参数
    mov rsi, 100        ; 第 2 个参数
    call some_function  ; 调用函数
    ; 返回值在 rax
    
    pop rbx             ; 恢复寄存器
    ret
```

栈对齐是个容易忽视的细节。`call` 指令会把返回地址压栈（8 字节），所以进入函数时 `rsp` 是 8 mod 16。如果函数要调用其他函数（尤其是用 SSE/AVX 指令的），必须先把 `rsp` 再压 8 字节，让栈保持 16 字节对齐。SSE 指令要求内存操作数 16 字节对齐，未对齐访问会导致段错误。

```asm
; 保持栈对齐
aligned_call:
    push rbp            ; +8 字节，现在 rsp 是 16 字节对齐了
    mov rbp, rsp
    
    sub rsp, 32         ; 分配 shadow space（Windows）或局部变量
    
    ; 现在可以安全调用其他函数了
    call some_sse_function
    
    mov rsp, rbp
    pop rbp
    ret
```

### Microsoft x64 ABI（Windows）

Windows 的调用约定有几个不同点：
- 调用者必须分配 32 字节的 **shadow space**（也叫 home space）
- 只有 4 个寄存器用于传参（`rcx`、`rdx`、`r8`、`r9`）
- 栈必须 16 字节对齐

```asm
; Windows x64 函数调用
windows_call:
    sub rsp, 40         ; 32 字节 shadow space + 8 字节对齐
    
    mov rcx, 42         ; 第 1 个参数
    mov rdx, 100        ; 第 2 个参数
    xor r8d, r8d        ; 第 3 个参数 = 0
    call some_function
    
    add rsp, 40         ; 恢复栈
    ret
```

写跨平台 assembly 时必须注意这些差异。这也是为什么大多数项目只在特定平台上用内联汇编，或者干脆用编译器 intrinsics。

## 内联汇编：在 C 里嵌入汇编

GCC 和 Clang 支持在 C 代码里嵌入 assembly，这叫**内联汇编**（Inline Assembly）。

```c
#include <stdint.h>

// 用汇编实现 64 位乘法，返回 128 位结果
void mul64(uint64_t a, uint64_t b, uint64_t *hi, uint64_t *lo) {
    __asm__ volatile (
        "mulq %3
	"           // rdx:rax = rax * %3
        "movq %%rdx, %0
	"    // *hi = rdx
        "movq %%rax, %1
	"    // *lo = rax
        : "=m" (*hi), "=m" (*lo)    // 输出
        : "a" (a), "r" (b)          // 输入: a 放 rax, b 放任意寄存器
        : "rdx", "cc"               // 被破坏的寄存器和标志位
    );
}
```

内联汇编的语法是：

```
asm [volatile] (汇编模板
    : 输出操作数
    : 输入操作数
    : 被破坏的寄存器
);
```

约束符（constraint）告诉编译器把 C 变量放在哪里：

| 约束 | 含义 |
|------|------|
| `r` | 通用寄存器 |
| `m` | 内存 |
| `i` | 立即数 |
| `a` | `rax`/`eax`/`ax`/`al` |
| `b` | `rbx` |
| `c` | `rcx` |
| `d` | `rdx` |
| `S` | `rsi` |
| `D` | `rdi` |
| `=` | 只写 |
| `+` | 读写 |
| `&` | 早期修改（不能与输入共享寄存器）|

内联汇编最大的坑是**约束写错**。如果告诉编译器某个寄存器被修改了但实际上没有，或者反过来，都会导致诡异的 bug。这也是为什么现代 C 代码越来越少用内联汇编，而是用 compiler intrinsics 代替。

```c
// 用 intrinsics 代替内联汇编
#include <immintrin.h>

// SIMD 加法：一次加 4 个 float
void add_floats(const float *a, const float *b, float *c) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vc = _mm_add_ps(va, vb);
    _mm_storeu_ps(c, vc);
}

// SIMD 点积
float dot_product(const float *a, const float *b) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 prod = _mm_mul_ps(va, vb);
    
    // 水平相加
    __m128 shuf = _mm_shuffle_ps(prod, prod, _MM_SHUFFLE(2, 3, 0, 1));
    __m128 sums = _mm_add_ps(prod, shuf);
    shuf = _mm_movehl_ps(shuf, sums);
    sums = _mm_add_ss(sums, shuf);
    
    return _mm_cvtss_f32(sums);
}
```

Intrinsics 是编译器内置的函数，它们直接映射到汇编指令，但让编译器负责寄存器分配和优化。这是目前推荐的做法。编译器在优化方面通常比人做得更好，尤其是在指令调度和寄存器分配上。

## 调试技巧：用 gdb 看汇编

gdb 是调试汇编代码的利器。

```bash
# 编译时保留调试信息
gcc -g -O0 program.c -o program

# 启动 gdb
gdb ./program

# 反汇编当前函数
(gdb) disassemble main

# 单步执行汇编指令
(gdb) stepi           # 执行一条指令
(gdb) nexti           # 执行一条指令，跳过函数调用

# 查看寄存器
(gdb) info registers
(gdb) print $rax
(gdb) x/10xg $rsp     # 查看栈顶 10 个 64 位值

# 在特定地址设断点
(gdb) break *0x401000

# 反汇编时显示源代码
(gdb) disassemble /s main

# 查看标志寄存器
(gdb) info registers eflags

# 以 intel 语法显示汇编
(gdb) set disassembly-flavor intel
```

objdump 也是一个有用的工具：

```bash
# 反汇编可执行文件
objdump -d ./program

# 反汇编并显示源代码
objdump -d -l ./program

# 查看符号表
objdump -t ./program

# 查看段信息
objdump -h ./program

# 只反汇编特定函数
objdump -d --disassemble=main ./program
```

### 一个调试实战

假设你遇到了一个段错误，但 gdb 的栈 trace 看起来不对。这时候应该：

```bash
(gdb) run
Program received signal SIGSEGV, Segmentation fault.

(gdb) info registers      # 看崩溃时的寄存器状态
(gdb) disassemble $pc-32,+64   # 反汇编崩溃点附近的代码
(gdb) x/10i $pc           # 看接下来要执行的 10 条指令
(gdb) x/20xg $rsp         # 看栈的内容
(gdb) info frame          # 看当前栈帧信息
(gdb) bt                  # 回溯调用栈
```

`$pc` 是程序计数器（rip 寄存器），指向当前指令。通过查看 `rip` 附近的代码和栈的内容，通常能定位到问题的根源。如果栈被破坏了，`bt` 可能显示不对，这时候需要手动跟踪 `rbp` 链或者看 `$rsp` 的内容。

## 编译器优化与汇编

看编译器生成的汇编代码，是理解优化效果的最好方法。

```bash
# 生成汇编代码
gcc -S -O0 program.c        # 无优化
gcc -S -O2 program.c        # 标准优化
gcc -S -O3 program.c        # 激进优化
gcc -S -Ofast program.c     # 更快的优化（可能不符合标准）

# 查看带注释的汇编
gcc -S -fverbose-asm -O2 program.c
```

```c
// 测试编译器优化
int square(int x) {
    return x * x;
}
```

-O0 生成的汇编：

```asm
square:
    push rbp
    mov rbp, rsp
    mov DWORD PTR [rbp-4], edi
    mov eax, DWORD PTR [rbp-4]
    imul eax, DWORD PTR [rbp-4]
    pop rbp
    ret
```

-O2 生成的汇编：

```asm
square:
    mov eax, edi
    imul eax, edi
    ret
```

编译器把多余的栈操作全部去掉了。`-O2` 下 `square` 函数只有两条指令：把参数从 `edi` 复制到 `eax`（因为返回值必须在 `eax`），然后 `imul`。这就是编译器优化的力量。

### 内联

```c
static inline int max(int a, int b) {
    return a > b ? a : b;
}

int foo(int x, int y) {
    return max(x, y) + max(x + 1, y + 1);
}
```

-O2 下，编译器会把 `max` 内联到 `foo` 里，生成类似这样的汇编：

```asm
foo:
    mov eax, edi        ; eax = x
    cmp edi, esi
    cmovge eax, edi     ; 如果 x >= y，eax = x，否则 eax 已经是 x
    ; ... 第二个 max 的内联
    lea eax, [rax + rdx]
    ret
```

`cmov` 是条件移动指令，避免了分支预测失败的代价。这在 hot path 上能带来显著的性能提升。

### 分支预测与缓存优化

现代 CPU 使用**分支预测**来推测条件跳转的方向。如果预测错误，流水线会被清空，损失十几个时钟周期。

```c
// 难以预测的分支（数据随机分布）
for (int i = 0; i < n; i++) {
    if (data[i] > threshold) {   // 分支预测容易失败
        sum += data[i];
    }
}

// 优化：排序后数据更有规律，分支预测更准
// 或者：用条件移动消除分支
for (int i = 0; i < n; i++) {
    sum += (data[i] > threshold) ? data[i] : 0;  // 编译器可能用 cmov
}
```

**缓存友好性**是另一个关键。CPU 访问内存的延迟从 L1 缓存的 4 个周期到主内存的 200+ 个周期不等。

```c
// 缓存不友好：按列访问
for (int j = 0; j < cols; j++) {
    for (int i = 0; i < rows; i++) {
        sum += matrix[i][j];  // 每次跳跃一行，cache miss
    }
}

// 缓存友好：按行访问
for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
        sum += matrix[i][j];  // 连续访问，cache hit
    }
}
```

## SIMD：一条指令处理多个数据

**SIMD**（Single Instruction Multiple Data）是现代 CPU 的标配。x86-64 的 SIMD 指令集有 SSE、AVX、AVX-512 等。

```asm
; SSE: 128 位寄存器 xmm0-xmm15
; AVX: 256 位寄存器 ymm0-ymm15
; AVX-512: 512 位寄存器 zmm0-zmm31

; SSE 浮点加法（一次加 4 个 float）
movaps xmm0, [rdi]      ; 加载 4 个 float
addps xmm0, [rsi]       ; 加 4 个 float
movaps [rdx], xmm0      ; 存储结果

; AVX 浮点加法（一次加 8 个 float）
vmovaps ymm0, [rdi]
vaddps ymm0, ymm0, [rsi]
vmovaps [rdx], ymm0

; AVX-512 浮点加法（一次加 16 个 float）
vmovaps zmm0, [rdi]
vaddps zmm0, zmm0, [rsi]
vmovaps [rdx], zmm0
```

SIMD 是 assembly 在现代 CPU 上最有价值的应用场景之一。编译器的 auto-vectorization 虽然越来越好，但在特定场景下，手写 SIMD 仍然能带来显著的性能提升。尤其是图像处理、音频处理、密码学、数值计算这些领域。

不过手写 SIMD 的维护成本很高。代码一旦写好，要移植到不支持某些指令集的 CPU 上就很麻烦。通常的做法是用编译器 intrinsics，让编译器根据目标 CPU 选择合适的指令。

## 总结

Assembly 不是要你天天写的语言，但它是理解计算机如何工作的窗口。当你知道每条 C 语句背后发生了什么，当你能在 gdb 里读懂反汇编的输出，当你能判断编译器的优化是否合理——这时候你就真正掌控了你的程序。

| 主题 | 关键概念 |
|------|---------|
| 寄存器 | rax-r15，32/64 位别名，调用约定 |
| 栈帧 | rbp/rsp，prologue/epilogue |
| 系统调用 | syscall 指令，参数寄存器，调用号 |
| 寻址 | 基址+索引*比例+位移 |
| 调用约定 | 参数寄存器，调用者/被调用者保存寄存器 |
| 内联汇编 | 约束，输入/输出，被破坏寄存器 |
| 调试 | gdb disassemble，info registers |
| SIMD | SSE/AVX，向量化计算 |

学习 assembly 最好的方式是：写一段 C 代码，编译成汇编，读它，改它，再编译。反复几次，CPU 的执行模型就会印在你的脑子里。你可以从简单的函数开始，比如阶乘、字符串复制、数组求和，然后逐步深入到更复杂的算法。

现代软件开发中，assembly 的应用场景越来越窄，但它在特定领域依然不可替代：操作系统内核、驱动程序、密码学、实时系统、游戏引擎的渲染管线。掌握 assembly 不是为了用它写整个项目，而是为了在需要的时候能读懂它、能调试它、能在关键路径上优化它。

> "如果你不知道 assembly，那你就不懂计算机。" —— 这话有点极端，但方向是对的。至少，不懂 assembly 的话，你不懂你的程序到底在干什么。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
        NULL,
        NULL,
        '<ul>
<li><a href="#x86-64-架构概览">x86-64 架构概览</a></li>
<ul>
<li><a href="#通用寄存器">通用寄存器</a></li>
<li><a href="#指令格式">指令格式</a></li>
</ul>
<li><a href="#栈帧与函数调用">栈帧与函数调用</a></li>
<li><a href="#系统调用-跟内核打交道">系统调用：跟内核打交道</a></li>
<li><a href="#内存模型与寻址模式">内存模型与寻址模式</a></li>
<ul>
<li><a href="#内存段">内存段</a></li>
</ul>
<li><a href="#调用约定-abi-的细节">调用约定：ABI 的细节</a></li>
<ul>
<li><a href="#system-v-amd64-abi-linux-macos">System V AMD64 ABI（Linux/macOS）</a></li>
<li><a href="#microsoft-x64-abi-windows">Microsoft x64 ABI（Windows）</a></li>
</ul>
<li><a href="#内联汇编-在-c-里嵌入汇编">内联汇编：在 C 里嵌入汇编</a></li>
<li><a href="#调试技巧-用-gdb-看汇编">调试技巧：用 gdb 看汇编</a></li>
<ul>
<li><a href="#一个调试实战">一个调试实战</a></li>
</ul>
<li><a href="#编译器优化与汇编">编译器优化与汇编</a></li>
<ul>
<li><a href="#内联">内联</a></li>
<li><a href="#分支预测与缓存优化">分支预测与缓存优化</a></li>
</ul>
<li><a href="#simd-一条指令处理多个数据">SIMD：一条指令处理多个数据</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
        1844,
        10,
        'published',
    NOW() - INTERVAL '27 days',
    NOW() - INTERVAL '27 days',
    NOW() - INTERVAL '27 days'
) ON CONFLICT DO NOTHING;
