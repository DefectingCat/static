INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'OCaml：强类型函数式编程',
    'ocaml-strongly-typed',
    'OCaml 是一门被低估的语言。它的类型推导系统让编译器像你的搭档一样，帮你发现代码里的 bug。本文深入探索 OCaml 的类型系统、模块系统和尾递归优化。',
    $doc$
# OCaml：强类型函数式编程

OCaml 是一门冷门的语言。放在 TIOBE 排行榜上，它可能都进不了前 50。但如果你去问 Jane Street（华尔街最神秘的交易公司之一）他们用啥写高频交易系统，答案是：OCaml。每年几十亿美元的交易量，全靠这门"小众"语言撑着。

我第一次接触 OCaml 是在大学的一门编程语言课上。老师让我们用 OCaml 写一个表达式求值器，我写完后运行，发现居然一次就通过了所有测试用例。这在 C 或 Java 里是不可想象的——通常要调半天指针或类型转换。OCaml 的编译器就像个唠叨但靠谱的搭档，在我写代码的时候就把大部分错误揪了出来。

后来在工作中偶尔用 OCaml 写一些数据处理和编译器相关的工具，每次都被它的类型系统惊艳到。你改了一个函数的签名，编译器会告诉你所有受影响的地方。这种安全感是动态语言给不了的。

## 类型推导：编译器比你更懂你的代码

OCaml 最迷人的特性是**类型推导**（Type Inference）。你不需要写类型注解，编译器能从代码的结构里自动推断出每个表达式和函数的类型。

```ocaml
(* 不需要写类型，编译器自动推断 *)
let add x y = x + y
(* 推断类型：add : int -> int -> int *)

let greet name = "Hello, " ^ name
(* 推断类型：greet : string -> string *)

(* 列表 *)
let numbers = [1; 2; 3; 4; 5]
(* 推断类型：numbers : int list *)

(* 元组 *)
let point = (3.0, 4.0)
(* 推断类型：point : float * float *)

(* 更复杂的例子 *)
let average a b = (a +. b) /. 2.0
(* 推断类型：average : float -> float -> float *)
```

`^` 是字符串连接运算符，不是乘方。OCaml 用 `+` 做整数加法，`+.` 做浮点加法，`*` 做整数乘法，`*. `做浮点乘法。这看起来啰嗦，但实际上消除了 C 语言里大量隐式类型转换带来的 bug。你不会不小心把浮点数加到整数上，因为编译器会直接报错。

类型推导不是动态类型，它依然是静态强类型。区别在于编译器替你写了类型标注：

```ocaml
(* 上面的 add 函数，显式写出来是这样的 *)
let add (x : int) (y : int) : int = x + y

(* 但我们完全可以省略 *)
let add x y = x + y
```

类型推导基于 **Hindley-Milner 算法**，这是一个 70 年代发明的类型系统。它的核心思想是：给每个表达式一个类型变量，然后根据表达式的使用方式建立约束方程，最后解这个方程组。听起来很数学，但 OCaml 的编译器能在毫秒级完成推导。

```ocaml
(* 复杂一点的例子 *)
let rec map f = function
  | [] -> []
  | x :: xs -> f x :: map f xs

(* 编译器推导出的类型：
   map : ('a -> 'b) -> 'a list -> 'b list
   
   'a 和 'b 是类型变量，表示 "任意类型"
   这跟我们手写的一模一样
*)
```

`map` 的类型签名读作：接收一个函数 `('a -> 'b)`，接收一个 `'a list`，返回一个 `'b list`。`'` 开头的标识符是类型变量，类似于 Java 的泛型参数 `T` 或 Rust 的 `T`。OCaml 的类型推导自动给出了最通用的类型签名，不需要我们显式声明泛型。这是 Hindley-Milner 系统的核心优势：类型多态是自动的、无处不在的。

## 代数数据类型：用类型描述世界

**代数数据类型**（Algebraic Data Types，ADT）是函数式编程的核心工具。OCaml 用 `type` 关键字定义 ADT，支持两种基本构造：乘积类型（元组/记录）和和类型（变体）。

```ocaml
(* 乘积类型：记录（record） *)
type person = {
  name : string;
  age : int;
  email : string option;
}

let alice = { name = "Alice"; age = 30; email = Some "alice@example.com" }

(* 访问字段 *)
let () = Printf.printf "%s is %d years old
" alice.name alice.age

(* 模式匹配解构记录 *)
let greet { name; age } =
  Printf.printf "Hello, %s! You are %d.
" name age

(* 更新记录（创建新记录） *)
let older_alice = { alice with age = 31 }
```

`{ alice with age = 31 }` 是记录更新的语法糖，它创建一个新记录，只修改 `age` 字段，其他字段保持不变。这是不可变更新的标准做法。

和类型（变体）是 ADT 的另一半：

```ocaml
(* 和类型：变体（variant） *)
type shape =
  | Circle of float                    (* 半径 *)
  | Rectangle of float * float         (* 宽 * 高 *)
  | Triangle of float * float * float  (* 三边 *)

(* 模式匹配处理每种情况 *)
let area = function
  | Circle r -> Float.pi *. r *. r
  | Rectangle (w, h) -> w *. h
  | Triangle (a, b, c) ->
      let s = (a +. b +. c) /. 2.0 in
      Float.sqrt (s *. (s -. a) *. (s -. b) *. (s -. c))

let () =
  let c = Circle 5.0 in
  Printf.printf "Area = %.2f
" (area c)  (* Area = 78.54 *)
```

`option` 类型是 OCaml 里处理可能缺失的值的标准方式，相当于其他语言里的 nullable：

```ocaml
type 'a option = None | Some of 'a

(* 安全地查找列表中的元素 *)
let rec find_opt p = function
  | [] -> None
  | x :: _ when p x -> Some x
  | _ :: xs -> find_opt p xs

let result = find_opt (fun x -> x > 10) [1; 5; 15; 20]
(* result = Some 15 *)

match result with
| Some x -> Printf.printf "Found: %d
" x
| None -> print_endline "Not found"
```

ADT 的强大之处在于：**不可能的状态在编译期就被排除**。如果你定义了一个表达式类型：

```ocaml
type expr =
  | Num of int
  | Add of expr * expr
  | Mul of expr * expr
  | Div of expr * expr
  | Var of string

(* 求值器 *)
let rec eval env = function
  | Num n -> n
  | Add (e1, e2) -> eval env e1 + eval env e2
  | Mul (e1, e2) -> eval env e1 * eval env e2
  | Div (e1, e2) -> eval env e1 / eval env e2
  | Var x -> List.assoc x env
```

编译器会检查 `eval` 函数是否处理了 `expr` 的所有变体。如果我后来给 `expr` 加了一个 `Sub` 分支但忘了更新 `eval`，编译器会报错。这种**穷尽性检查**（exhaustiveness checking）让重构变得安全。我有一次给 AST 加了新的节点类型，编译器列出了所有需要更新的函数，省了至少一个小时的调试时间。

## 模式匹配：比 switch 强大十倍

模式匹配是 OCaml 里使用频率最高的语法特性之一。它不仅仅是 switch 语句的增强版，而是一种强大的解构和分支机制。

```ocaml
(* 基础模式匹配 *)
let describe = function
  | 0 -> "zero"
  | 1 -> "one"
  | 2 -> "two"
  | n when n < 0 -> "negative"
  | n when n > 100 -> "big"
  | _ -> "other"

(* 列表模式匹配 *)
let rec length = function
  | [] -> 0
  | _ :: tail -> 1 + length tail

(* 深度模式匹配 *)
type binary_tree =
  | Leaf
  | Node of int * binary_tree * binary_tree

let rec sum_tree = function
  | Leaf -> 0
  | Node (value, left, right) ->
      value + sum_tree left + sum_tree right

(* 嵌套模式 *)
let is_single_node = function
  | Node (_, Leaf, Leaf) -> true
  | _ -> false

(* as 模式：绑定子模式 *)
let get_left = function
  | Node (_, (Leaf as l), _) -> Some l
  | Node (_, (Node _ as l), _) -> Some l
  | Leaf -> None

(* 列表操作的模式匹配 *)
let rec reverse lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] lst

let rec take n = function
  | [] -> []
  | _ when n <= 0 -> []
  | x :: xs -> x :: take (n - 1) xs
```

`::` 是列表的构造运算符，`[1; 2; 3]` 等价于 `1 :: 2 :: 3 :: []`。模式匹配时，`x :: xs` 匹配非空列表，把第一个元素绑定到 `x`，剩余部分绑定到 `xs`。

模式匹配的一个高级特性是**守卫**（guard）：

```ocaml
let classify_number n =
  match n with
  | 0 -> "zero"
  | 1 | 2 | 3 -> "small"           (* 多个模式用 | 连接 *)
  | n when n mod 2 = 0 -> "even"   (* 守卫条件 *)
  | _ -> "odd"
```

编译器会检查模式匹配是否穷尽。如果漏掉了一个分支，它会给出警告甚至错误：

```ocaml
(* 编译器警告：This pattern-matching is not exhaustive. *)
let risky = function
  | Some x -> x
  (* 漏掉了 None！ *)
```

这种静态保证在处理复杂数据结构时价值巨大。你在写代码的时候就知道有没有漏掉情况，而不是等到运行时崩溃。这对于大规模代码库尤其重要。

## 错误处理：Option、Result 与异常

OCaml 提供了多种错误处理机制，从简单的 `option` 到功能完备的 `result` 类型。

`option` 用于表示值可能存在也可能不存在：

```ocaml
type 'a option = None | Some of 'a

let safe_div a b =
  if b = 0 then None
  else Some (a / b)

match safe_div 10 2 with
| Some result -> Printf.printf "结果: %d\n" result
| None -> print_endline "除零错误"
```

`result` 类型在 OCaml 4.03+ 中成为标准库的一部分，它可以携带错误信息：

```ocaml
type ('a, 'b) result = Ok of 'a | Error of 'b

let parse_int s =
  try Ok (int_of_string s)
  with Failure _ -> Error (Printf.sprintf "无法解析整数: %s" s)

let compute s1 s2 =
  match parse_int s1 with
  | Error e -> Error e
  | Ok a ->
      match parse_int s2 with
      | Error e -> Error e
      | Ok b ->
          if b = 0 then Error "除数不能为零"
          else Ok (a / b)

(* 使用 >>= 操作符简化嵌套 *)
let (>>=) r f =
  match r with
  | Ok x -> f x
  | Error e -> Error e

let compute2 s1 s2 =
  parse_int s1 >>= fun a ->
  parse_int s2 >>= fun b ->
  if b = 0 then Error "除数不能为零"
  else Ok (a / b)
```

这种链式调用让错误处理变得清晰。每个步骤失败后，后续步骤不会执行，错误信息会自动传播。这比异常机制更明确，因为错误处理就在类型签名里，不会藏在某个 catch 块里。

异常在 OCaml 中也有用途，主要用于真正的异常情况——程序不应该恢复的错误：

```ocaml
exception Division_by_zero
exception File_not_found of string

let read_file filename =
  if not (Sys.file_exists filename) then
    raise (File_not_found filename);
  let ic = open_in filename in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  content
```

不过现代 OCaml 代码倾向于用 `result` 而不是异常，因为 `result` 让错误处理显式化，编译器能帮你检查是否处理了所有错误路径。

## 模块系统：比类更强大的抽象工具

OCaml 的模块系统是它最独特也最强大的特性之一。模块不是类，不是命名空间，而是一种独立的抽象机制。

```ocaml
(* 定义一个模块 *)
module Stack = struct
  type 'a t = 'a list

  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Empty stack"
    | x :: xs -> (x, xs)
  let peek = function
    | [] -> failwith "Empty stack"
    | x :: _ -> x
  let is_empty s = s = []
  let size s = List.length s
end

(* 使用模块 *)
let s = Stack.empty
let s = Stack.push 1 s
let s = Stack.push 2 s
let top, s = Stack.pop s
(* top = 2, s = [1] *)
```

模块可以封装实现细节。外部代码只知道 `Stack` 模块的接口，不知道底层用的是列表。这意味着以后可以把实现换成数组或自定义数据结构，而不影响外部代码。

### 签名（接口）

```ocaml
(* 定义接口 *)
module type STACK = sig
  type 'a t
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a * 'a t
  val peek : 'a t -> 'a
  val is_empty : 'a t -> bool
  val size : 'a t -> int
end

(* 实现接口 *)
module ListStack : STACK = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Empty stack"
    | x :: xs -> (x, xs)
  let peek = function
    | [] -> failwith "Empty stack"
    | x :: _ -> x
  let is_empty s = s = []
  let size = List.length
end
```

签名隐藏了实现细节。`ListStack` 的类型 `'a ListStack.t` 是抽象的，外部无法知道它内部是列表。这提供了真正的信息隐藏，不是 Java 里那种靠命名约定的伪隐藏。

### Functor：模块的函数

**Functor** 是接收模块作为参数并返回新模块的函数。这是 OCaml 模块系统的巅峰。

```ocaml
(* 定义一个可比较类型的接口 *)
module type COMPARABLE = sig
  type t
  val compare : t -> t -> int
end

(* 定义集合的接口 *)
module type SET = sig
  type elt
  type t
  val empty : t
  val add : elt -> t -> t
  val mem : elt -> t -> bool
  val remove : elt -> t -> t
  val size : t -> int
end

(* Functor：给定一个 COMPARABLE，生成一个 SET *)
module MakeSet (Elt : COMPARABLE) : SET with type elt = Elt.t = struct
  type elt = Elt.t
  type t = elt list

  let empty = []
  let add x s = if List.mem x s then s else x :: s
  let mem = List.mem
  let remove x s = List.filter (fun y -> y <> x) s
  let size = List.length
end

(* 使用 Functor *)
module IntCompare = struct
  type t = int
  let compare = Int.compare
end

module IntSet = MakeSet (IntCompare)

let s = IntSet.empty
let s = IntSet.add 42 s
let s = IntSet.add 10 s
let has_42 = IntSet.mem 42 s  (* true *)
```

Functor 是参数化模块。`MakeSet` 是一个模板，给它不同的比较模块，就能生成不同元素类型的集合。这类似于 C++ 的模板，但类型安全、错误信息友好。

Jane Street 的核心库大量使用 Functor 来构建灵活的数据结构。他们的 `Map` 和 `Set` 实现都是用 Functor 参数化的，可以处理任何可比较的类型。这种模块化的设计让他们能在不修改核心代码的情况下，为不同的数据类型生成优化的集合实现。

## 尾递归优化：递归也能高效

递归在函数式语言里是不可避免的。但朴素的递归会导致栈溢出：

```ocaml
(* 朴素递归：会栈溢出 *)
let rec sum_bad = function
  | [] -> 0
  | x :: xs -> x + sum_bad xs

(* sum_bad [1; 2; ...; 1000000] -> Stack overflow! *)
```

OCaml 支持**尾递归优化**（Tail Call Optimization，TCO）。如果一个递归调用是函数的最后一个操作，编译器会把它优化成循环，复用当前栈帧。

```ocaml
(* 尾递归版本：不会栈溢出 *)
let sum lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (acc + x) xs  (* 尾调用 *)
  in
  aux 0 lst

(* sum [1; 2; ...; 1000000] -> 正常工作！ *)
```

`aux` 函数里的递归调用 `aux (acc + x) xs` 是最后一个操作，没有任何后续计算。编译器识别出这是尾调用，直接复用当前栈帧。这种优化让递归在实际使用中跟循环一样安全。

 accumulator（累加器）模式是写尾递归的标准技巧：把中间结果通过一个额外参数传递，而不是在返回时做计算。

```ocaml
(* 尾递归的阶乘 *)
let factorial n =
  let rec aux acc n =
    if n <= 1 then acc
    else aux (acc * n) (n - 1)
  in
  aux 1 n

(* 尾递归的列表反转 *)
let rev lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] lst

(* 尾递归的列表映射 *)
let map f lst =
  let rec aux acc = function
    | [] -> List.rev acc
    | x :: xs -> aux (f x :: acc) xs
  in
  aux [] lst
```

写尾递归有个简单的判断方法：递归调用后有没有其他运算。`f (x) + 1` 不是尾递归，因为返回后还要加 1；`f (x + 1)` 是尾递归，因为递归调用就是最后一步。这个判断方法在写递归函数时很有用。

OCaml 的标准库函数大多是尾递归的。`List.map`、`List.fold_left` 都是安全的，可以放心处理大列表。但要注意 `List.fold_right` 不是尾递归的，因为 `f x (fold_right f xs init)` 里 `fold_right` 的结果还要传给 `f`。大列表应该用 `fold_left` 或者先把列表反转。

## 与 C 的互操作

OCaml 可以调用 C 函数，这对需要高性能计算或与系统库交互的场景很重要。

```c
/* hello.c */
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <stdio.h>

CAMLprim value caml_hello(value name) {
    CAMLparam1(name);
    printf("Hello from C, %s!
", String_val(name));
    CAMLreturn(Val_unit);
}

CAMLprim value caml_add(value a, value b) {
    CAMLparam2(a, b);
    int result = Int_val(a) + Int_val(b);
    CAMLreturn(Val_int(result));
}
```

```ocaml
(* hello.ml *)
external hello : string -> unit = "caml_hello"
external add : int -> int -> int = "caml_add"

let () = hello "OCaml"
let () = Printf.printf "10 + 20 = %d
" (add 10 20)
```

编译时需要把 C 代码和 OCaml 代码一起编译：

```bash
ocamlc -c hello.c
ocamlc -o hello hello.cmo hello.ml
```

C 互操作的接口需要遵循 OCaml 的 C API 规范，使用 `CAMLparam`、`CAMLreturn` 等宏来管理垃圾回收的根集合。这比 Lua 的栈式 API 复杂一些，但提供了更细粒度的控制。

## Dune：现代化的构建系统

OCaml 的构建系统经历过几次演进。早期的 `ocamlbuild` 已经被 **Dune** 取代。Dune 是一个声明式的构建系统，配置文件简单直观。

```scheme
; dune-project
(lang dune 3.0)
(name myproject)

; src/dune
(executable
 (public_name myproject)
 (name main)
 (libraries core async))

; lib/dune
(library
 (name mylib)
 (libraries base))

; test/dune
(test
 (name test_suite)
 (libraries mylib ounit2))
```

Dune 会自动处理模块依赖、编译顺序、接口文件（`.mli`）和实现文件（`.ml`）的配对。你只需写 `dune build`，它就能搞定一切。

```bash
# 创建新项目
dune init project myproject
cd myproject

# 构建
dune build

# 运行
dune exec myproject

# 测试
dune test

# 生成文档
dune build @doc

# 清理
dune clean

# 带覆盖率测试
dune runtest --instrument-with bisect_ppx
```

Dune 还支持增量编译、并行编译和缓存，大型项目的构建速度很快。Jane Street 的几十万个 OCaml 文件，用 Dune 构建也只需要几分钟。相比之下，C++ 项目同样的代码量可能要构建几小时。

## ReasonML：给 OCaml 穿一件 JavaScript 的外套

**ReasonML** 是 OCaml 的一个语法变体，用更 JavaScript/C 风格的语法写 OCaml。它是 Facebook 发起的项目，旨在降低 OCaml 的学习曲线。

```reason
/* ReasonML 语法 */
let add = (x, y) => x + y;

let rec factorial = n =>
  if (n <= 1) {
    1;
  } else {
    n * factorial(n - 1);
  };

type shape =
  | Circle(float)
  | Rectangle(float, float);

let area = shape =>
  switch (shape) {
  | Circle(r) => 3.14159 *. r *. r
  | Rectangle(w, h) => w *. h
  };

/* 列表操作 */
let numbers = [1, 2, 3, 4, 5];
let doubled = List.map(x => x * 2, numbers);
```

ReasonML 编译成 JavaScript（通过 BuckleScript/ReScript），也可以编译成原生代码。它让前端开发者能用类型安全的语言写 Web 应用，同时复用 OCaml 的整个生态系统。

不过 ReasonML 的发展有些曲折。原团队后来把重点转向了 ReScript（专注于编译到 JavaScript），ReasonML 本身的活跃度有所下降。但对于想尝试 OCaml 类型系统又不喜欢 OCaml 语法的人来说，它依然是个不错的入口。

## 总结

OCaml 是一门被严重低估的语言。它的类型系统既能保证安全性，又不会让你写一大堆类型标注。模块系统提供了比类更强大的抽象能力。尾递归优化让函数式风格的代码也能高效运行。

| 特性 | 说明 | 应用场景 |
|------|------|---------|
| 类型推导 | 自动推断类型，少写标注 | 快速开发、原型 |
| ADT | 代数数据类型描述状态 | 领域建模、编译器、协议解析 |
| 模式匹配 | 安全穷尽的分支处理 | 数据解构、状态机、编译器 |
| 模块系统 | 强大的封装和抽象 | 大型项目架构、库设计 |
| Functor | 参数化模块 | 泛型数据结构、框架 |
| 尾递归 | 递归不栈溢出 | 列表处理、迭代、树遍历 |
| Dune | 现代构建系统 | 项目管理、CI/CD |

OCaml 的编译器是我用过的最友好的编译器之一。错误信息清晰、定位准确，而且类型推导的约束检查能帮你发现大量潜在 bug。如果你厌倦了动态语言的运行时错误，又觉得 Java/C++ 的类型系统太啰嗦，OCaml 值得试一试。它的学习曲线比 Haskell 平缓，却比 Rust 更早成熟。在函数式语言的谱系中，OCaml 是一个被忽视的宝藏。

---

*本文首发于 Yggdrasil 博客*
    $doc$,
        NULL,
        '/images/covers/ocaml-strongly-typed.jpg',
        '<ul>
<li><a href="#类型推导-编译器比你更懂你的代码">类型推导：编译器比你更懂你的代码</a></li>
<li><a href="#代数数据类型-用类型描述世界">代数数据类型：用类型描述世界</a></li>
<li><a href="#模式匹配-比-switch-强大十倍">模式匹配：比 switch 强大十倍</a></li>
<li><a href="#错误处理-option-result-与异常">错误处理：Option、Result 与异常</a></li>
<li><a href="#模块系统-比类更强大的抽象工具">模块系统：比类更强大的抽象工具</a></li>
<ul>
<li><a href="#签名-接口">签名（接口）</a></li>
<li><a href="#functor-模块的函数">Functor：模块的函数</a></li>
</ul>
<li><a href="#尾递归优化-递归也能高效">尾递归优化：递归也能高效</a></li>
<li><a href="#与-c-的互操作">与 C 的互操作</a></li>
<li><a href="#dune-现代化的构建系统">Dune：现代化的构建系统</a></li>
<li><a href="#reasonml-给-ocaml-穿一件-javascript-的外套">ReasonML：给 OCaml 穿一件 JavaScript 的外套</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
        1869,
        10,
        'published',
    NOW() - INTERVAL '26 days',
    NOW() - INTERVAL '26 days',
    NOW() - INTERVAL '26 days'
) ON CONFLICT DO NOTHING;
