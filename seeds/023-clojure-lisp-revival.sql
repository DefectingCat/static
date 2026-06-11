INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Clojure：Lisp 的现代复兴',
    'clojure-lisp-revival',
    'Clojure 是 Lisp 家族在 JVM 上的现代复兴。本文探讨其 S-expression 语法、不可变数据结构、STM 软件事务内存、宏系统、多方法、Java 互操作以及 REPL 驱动开发等核心特性。',
    $doc$
# Clojure：Lisp 的现代复兴

Lisp 诞生于 1958 年，比 C 还早十几年。在编程语言的进化树上，Lisp 是一个异常长寿的分支——Fortran 已经变得面目全非，Cobol 变成了古董，但 Lisp 的精神通过各种方言延续至今。Clojure 就是其中最成功的现代变体之一。

Rich Hickey 在 2007 年创造了 Clojure。他没有选择重新发明虚拟机，而是直接寄生在 JVM 上。这个决策极其聪明：Java 生态里有海量的库和成熟的基础设施，Clojure 程序员可以直接调用。加上不可变数据结构和 STM（软件事务内存），Clojure 成为了一门既有历史底蕴又有现代特性的语言。

我第一次在生产环境用 Clojure 是 2015 年，做一个金融数据处理的 ETL 管道。三年下来，代码量只有 Java 版本的三分之一，bug 数量更是少了一个数量级。那之后我对这门语言彻底改观。说个不怕得罪人的话：Clojure 的代码质量在同等项目里通常是最高的，因为 mutable state 少了，自然就少了很多莫名其妙的问题。

## 括号不是问题：S-expression 的真相

每一个讨论 Lisp 的帖子下面，都会有人抱怨"括号太多了"。这种批评通常是外行的标志。Clojure 的语法实际上极其简洁——整个语言的语法规则用一页纸就能写完。

```clojure
;; 函数调用：(函数名 参数1 参数2 ...)
(+ 1 2 3)           ; => 6
(str "Hello" " " "World")  ; => "Hello World"

;; 定义变量
(def pi 3.14159)

;; 定义函数
(defn greet [name]
  (str "Hello, " name "!"))

(greet "Alice")    ; => "Hello, Alice!"

;; 条件表达式
(if (> 10 5)
  "yes"
  "no")           ; => "yes"
```

前缀表示法（operator 在前，操作数在后）的好处是完全没有优先级歧义。你不需要记 `*` 和 `+` 哪个优先级高，表达式 `(+ (* 2 3) 4)` 的意思一目了然。而且，因为代码和数据使用完全相同的结构（S-expression），宏系统才能成为可能。

```clojure
;; 数据结构——同样是括号，但含义不同
[1 2 3]             ; 向量（Vector）
{:a 1 :b 2}         ; 映射（Map）
#{1 2 3}            ; 集合（Set）
''(1 2 3)            ; 列表（List），不执行

;; 函数也是一等公民
(def operations [+ - * /])
((operations 0) 1 2 3)  ; => 6，等价于 (+ 1 2 3)
```

## 不可变数据结构：持久化数据结构的妙用

Clojure 的所有核心数据结构都是不可变的。但你可能担心：如果每次修改都复制整个结构，性能岂不是要爆炸？

答案在于**持久化数据结构**（Persistent Data Structures）。它们通过结构共享来实现不可变性，时间复杂度接近可变数据结构。

```clojure
(def v1 [1 2 3])
(def v2 (conj v1 4))    ; v2 = [1 2 3 4]，v1 仍然是 [1 2 3]

;; v1 和 v2 共享大部分内部结构，只在新节点分配内存
v1  ; => [1 2 3]
v2  ; => [1 2 3 4]

;; 映射也是不可变的
(def m1 {:name "Alice" :age 28})
(def m2 (assoc m1 :city "NYC"))

m1  ; => {:name "Alice", :age 28}
m2  ; => {:name "Alice", :age 28, :city "NYC"}
```

我在一个实时数据处理系统里用 Clojure 的不可变向量作为滑动窗口的数据结构。窗口每秒滑动一次，每次产生新窗口时只需要创建少数新节点，内存占用和 GC 压力都比 Java 的 ArrayList 方案小得多。这就是持久化数据结构的威力。

```clojure
;; 嵌套数据结构的更新——用 -> 宏串联操作
(def user
  {:name "Alice"
   :address {:city "NYC"
             :zip "10001"}})

(def updated-user
  (-> user
      (assoc :age 29)
      (assoc-in [:address :city] "Boston")
      (update-in [:address :zip] str "-new")))

;; updated-user =>
;; {:name "Alice", :age 29,
;;  :address {:city "Boston", :zip "10001-new"}}
;; user 本身完全没有变化

;; 集合操作——不可变但高效
(def s1 #{1 2 3})
(def s2 (conj s1 4))     ; #{1 2 3 4}
(def s3 (disj s2 2))     ; #{1 3 4}

;; 映射的合并
(def defaults {:timeout 30 :retries 3})
(def config (merge defaults {:timeout 60}))
;; config => {:timeout 60, :retries 3}
```

## STM：软件事务内存的优雅

并发编程的两大噩梦是死锁和竞态条件。Clojure 的 STM（Software Transaction Memory）提供了一种优雅的解决方案：把共享状态的修改当成数据库事务来处理。

```clojure
(def account-a (ref 1000))
(def account-b (ref 2000))

;; 转账操作——原子性、一致性、隔离性
(defn transfer [from to amount]
  (dosync
    (let [from-balance @from]
      (when (< from-balance amount)
        (throw (Exception. "Insufficient funds"))))
    (alter from - amount)
    (alter to + amount)))

(transfer account-a account-b 300)
@account-a  ; => 700
@account-b  ; => 2300
```

`dosync` 块里的所有操作要么全部成功，要么全部回滚。如果有两个事务同时修改同一个 ref，STM 会自动重试其中一个。你不需要显式加锁，不需要担心锁的顺序，也不需要写任何同步代码。

我在一个交易系统里用过 STM 来处理订单状态机。每天处理几百万笔订单，零死锁，零竞态条件。当然，STM 也有局限：如果事务太大或者冲突太频繁，重试开销会急剧上升。这时候你就需要考虑把大事务拆小，或者改用 Agent/Atom。

```clojure
;; Agent：异步、串行的状态更新
(def counter (agent 0))

(send counter + 1)    ; 异步发送增量操作
(send counter + 5)

(await counter)       ; 等待所有操作完成
@counter              ; => 6

;; Agent 的错误处理
(def safe-counter (agent 0
                    :error-handler (fn [agent err]
                                     (println "Error:" err))
                    :error-mode :continue))

;; Atom：同步、无协调的 CAS 更新
(def visits (atom 0))
(swap! visits inc)    ; 原子地增加
@visits               ; => 1

;; Atom 支持验证函数
(def valid-counter (atom 0 :validator #(>= % 0)))
;; (reset! valid-counter -1)  ; 抛出 IllegalStateException
```

## 宏系统：代码即数据，数据即代码

宏是 Lisp 的灵魂。因为 Clojure 代码本身就是数据结构（S-expression），你可以在编译期随意构造、分析和修改代码。这比 C 的文本替换宏强大太多了。

```clojure
;; 自定义 when 宏
(defmacro my-when [condition & body]
  `(if ~condition
     (do ~@body)
     nil))

;; 使用
(my-when (> 5 3)
  (println "Condition is true")
  (+ 1 2 3))
;; 展开后等价于：
;; (if (> 5 3)
;;   (do (println "Condition is true") (+ 1 2 3))
;;   nil)
```

我在项目里写过一个 `defapi` 宏，用来简化 REST API 端点的定义。原本需要写二十几行样板代码，用宏之后只要三行。宏的力量在于它能消除所有机械重复的代码，让你的 DSL 看起来像语言原生的一部分。

```clojure
;; 带计时的宏
(defmacro timed [expr]
  `(let [start# (System/nanoTime)
         result# ~expr
         elapsed# (/ (- (System/nanoTime) start#) 1e6)]
     (println (str "Elapsed: " elapsed# " ms"))
     result#))

(timed (reduce + (range 1000000)))
;; Elapsed: 45.231 ms
;; => 499999500000

;; 自定义的线程安全宏
(defmacro synchronized [lock & body]
  `(locking ~lock
     ~@body))
```

但要注意，宏是编译期的魔法。滥用宏会让代码难以理解和调试。我的原则是：只有出现明显的重复模式时，才考虑写宏。不要为了炫技而写宏。

## 多方法：超越传统多态

Clojure 的 multimethod 是一种基于任意 dispatch 函数的多态机制。它不限于类型 dispatch，可以根据任何逻辑来决定调用哪个方法。

```clojure
;; 基于类型的 dispatch
(defmulti encounter (fn [x y] [(:species x) (:species y)]))

(defmethod encounter [:bunny :lion] [b l]
  :run-away)

(defmethod encounter [:lion :bunny] [l b]
  :eat)

(defmethod encounter [:lion :lion] [l1 l2]
  :fight)

(defmethod encounter :default [x y]
  :ignore)

(encounter {:species :bunny} {:species :lion})   ; => :run-away
(encounter {:species :lion} {:species :lion})    ; => :fight
```

这比 Java 的面向对象多态灵活得多。你可以根据多个参数的值来 dispatch，可以根据参数的属性来 dispatch，甚至可以根据运行时状态来 dispatch。我在一个规则引擎里用 multimethod 来实现策略分发，代码清晰得不像话。

```clojure
;; 基于计算结果的 dispatch
(defmulti tax-rate :country)

(defmethod tax-rate "US" [_] 0.08)
(defmethod tax-rate "UK" [_] 0.20)
(defmethod tax-rate "JP" [_] 0.10)
(defmethod tax-rate :default [_] 0.0)

(tax-rate {:country "UK"})  ; => 0.20
(tax-rate {:country "FR"})  ; => 0.0

;; 更复杂的 dispatch——基于自定义逻辑
(defmulti process-request
  (fn [request]
    (cond
      (contains? request :file-upload) :file
      (> (:payload-size request 0) 1000000) :large
      :else :normal)))

(defmethod process-request :file [req]
  (str "Processing file upload: " (:filename req)))

(defmethod process-request :large [req]
  "Processing large payload asynchronously")

(defmethod process-request :normal [req]
  "Processing normal request")
```

## 与 Java 互操作：站在巨人肩膀上

Clojure 最大的优势之一就是能无缝调用 Java 代码。JVM 上二十多年的生态积累，你直接拿来用。

```clojure
;; 创建 Java 对象
(import ''[java.util Date ArrayList])
(def now (Date.))
(.getTime now)           ; => 1640000000000

;; 调用 Java 方法
(def list (ArrayList.))
(.add list "Hello")
(.add list "World")
(.size list)             ; => 2

;; 更 Clojure 风格的方式
(doto (ArrayList.)
  (.add "Hello")
  (.add "World"))

;; 使用 Java 8 Stream
(import ''[java.util Arrays])
(-> (Arrays/stream (into-array Integer [1 2 3 4 5]))
    (.filter (reify java.util.function.Predicate
               (test [_ x] (> x 2))))
    (.map (reify java.util.function.Function
            (apply [_ x] (* x x))))
    (.toList))
;; 当然，Clojure 自带的序列操作更简洁...
```

Java 互操作意味着你可以用 Clojure 写业务逻辑，用 Java 写性能敏感的底层代码。我们团队在一个高性能计算项目里就是这么做：核心算法用 Java 写，数据流编排和配置用 Clojure 写，两边配合得天衣无缝。

```clojure
;; 使用 Java 的并发工具
(import ''[java.util.concurrent Executors CountDownLatch])

(def executor (Executors/newFixedThreadPool 4))
(def latch (CountDownLatch. 3))

(dotimes [i 3]
  (.execute executor
    #(do
       (println (str "Task " i " running on " (.getName (Thread/currentThread))))
       (.countDown latch))))

(.await latch)
(.shutdown executor)

;; 调用 Apache Commons 等第三方库
;; [org.apache.commons/commons-lang3 "3.12.0"]
(import ''[org.apache.commons.lang3 StringUtils])
(StringUtils/reverse "hello")  ; => "olleh"
```

## REPL 驱动开发：实时编程

Clojure 的 REPL（Read-Eval-Print Loop）是我用过的最 productive 的开发环境之一。它不是那种 toy REPL——它是真正的开发环境，可以在运行时修改生产代码。

```clojure
;; 在 REPL 中实时开发
user=> (defn process-data [data]
  #_=>   (map inc data))
user=> (process-data [1 2 3 4 5])
(2 3 4 5 6)

;; 发现 bug，立即修复
user=> (defn process-data [data]
  #_=>   (map #(+ % 10) data))
user=> (process-data [1 2 3])
(11 12 13)

;; 检查运行时状态
user=> (def state (atom {:count 0 :items []}))
user=> (swap! state update :count inc)
{:count 1, :items []}
```

Clojure 的 REPL 驱动开发流程是这样的：你在编辑器里写函数，按一个快捷键把代码发送到 REPL 执行，立即看到结果。发现不对就修改再发送。整个过程以秒为单位循环，而不是以分钟为单位编译-运行-调试。

我曾在凌晨两点接到生产环境告警，连上 REPL，定位到问题函数，修改代码发送到运行中的进程，问题当场解决。整个过程没有重启服务，没有部署，没有停机。这种能力在其他语言里几乎不存在。

```clojure
;; 使用 tools.namespace 实现代码热重载
(require ''[clojure.tools.namespace.repl :refer [refresh]])

;; 修改源文件后
(refresh)
;; :reloading (my-project.core my-project.utils)
;; :ok

;; Stuart Sierra 的 Component 库管理应用生命周期
(require ''[com.stuartsierra.component :as component])

(defrecord Database [host port connection]
  component/Lifecycle
  (start [this]
    (println "Starting database connection...")
    (assoc this :connection (connect host port)))
  (stop [this]
    (println "Stopping database connection...")
    (.close connection)
    (assoc this :connection nil)))
```

## Transducers：高阶抽象的极致

Transducer 是 Rich Hickey 在 2014 年引入的一个概念。它把 map、filter、take 等序列操作从数据源（列表、流、channel）中解耦出来，成为一种可复用的转换逻辑。

```clojure
;; 定义一个 transducer
(def xform
  (comp
    (filter odd?)
    (map inc)
    (take 5)))

;; 应用于不同数据源
(into [] xform (range 100))
;; => [2 4 6 8 10]

;; 应用于 channel
(require ''[clojure.core.async :refer [chan pipeline]]))

(def input (chan))
(def output (chan))
(pipeline 4 output xform input)
```

Transducer 的优雅之处在于零开销组合。`(comp (filter f) (map g))` 在遍历序列时只遍历一次，而不是先过滤整个序列再映射整个序列。对于大数据流，这个区别可能是性能上的天壤之别。

```clojure
;; 自定义 transducer
(defn mapping [f]
  (fn [rf]
    (fn
      ([] (rf))
      ([result] (rf result))
      ([result input]
       (rf result (f input))))))

(defn filtering [pred]
  (fn [rf]
    (fn
      ([] (rf))
      ([result] (rf result))
      ([result input]
       (if (pred input)
         (rf result input)
         result)))))

;; 使用自定义 transducer
(into [] (comp (filtering even?) (mapping #(* % %))) (range 10))
;; => [0 4 16 36 64]
```

## Spec：数据规范与验证

Clojure 1.9 引入了 `clojure.spec`，提供了一种声明式的数据规范机制。跟静态类型不同，spec 在运行时验证数据，并且可以用于生成测试数据、文档和错误信息。

```clojure
(require ''[clojure.spec.alpha :as s])

;; 定义规范
(s/def ::name string?)
(s/def ::age (s/and int? #(>= % 0)))
(s/def ::email (s/and string? #(re-matches #".+@.+" %)))
(s/def ::person (s/keys :req [::name ::age] :opt [::email]))

;; 验证数据
(s/valid? ::person {::name "Alice" ::age 28})
;; => true

(s/valid? ::person {::name "Bob" ::age -5})
;; => false

(s/explain ::person {::name "Bob" ::age -5})
;; -5 - failed: (>= % 0)

;; 用 spec 生成测试数据
(require ''[clojure.spec.gen.alpha :as gen])
(gen/sample (s/gen ::person) 3)
;; => ({:user/name "" :user/age 0}
;;     {:user/name "x" :user/age 1 :user/email "a@b"}
;;     {:user/name "yz" :user/age 2})
```

我在 API 接口层大量使用 spec 来做输入验证。它比手写验证逻辑清晰得多，而且 `s/explain` 生成的错误信息可以直接返回给客户端。

## 总结

Clojure 不是一门大众语言，但它的设计哲学深刻影响了很多现代语言。不可变数据结构被 JavaScript（Immutable.js）、Java（Vavr）广泛借鉴；STM 的概念启发了数据库和分布式系统的设计；宏系统虽然难以在其他语言中复制，但其"代码即数据"的思想被各种 AST 转换工具继承。

| 特性 | 作用 | 学习难度 |
|------|------|---------|
| S-expression | 统一的代码/数据表示 | 低（克服括号恐惧后） |
| 不可变数据结构 | 安全、可预测的代码 | 中（改变思维方式） |
| STM | 无锁并发 | 中 |
| 宏 | 编译期元编程 | 高 |
| 多方法 | 灵活的多态 | 低 |
| Java 互操作 | 生态复用 | 低 |
| REPL | 实时开发 | 低 |
| Transducers | 零开销序列转换 | 中 |
| Spec | 数据验证与生成 | 低 |

Clojure 适合什么样的人？如果你喜欢函数式编程，如果你厌倦了 null 和 mutable state 带来的痛苦，如果你想用 Lisp 的智慧来解决实际问题——Clojure 是你的菜。但如果你对括号有生理厌恶，或者你的团队无法接受 Lisp 的思维方式，那还是不要勉强。

---

*本文首发于 Yggdrasil 博客*

    $doc$,
    NULL,
    'published',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '21 days'
) ON CONFLICT DO NOTHING;
