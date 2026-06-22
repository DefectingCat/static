INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Scala：融合面向对象与函数式编程',
    'scala-fp-oop',
    'Scala 是一门将面向对象与函数式编程完美融合的语言。本文深入探讨 case class、模式匹配、隐式转换、高阶函数、特质、for-comprehension、Option/Either 以及 Akka Actor 等核心特性。',
    $doc$
# Scala：融合面向对象与函数式编程

我第一次接触 Scala 是在 2012 年，那时候 Twitter 刚刚从 Ruby 迁移到 Scala，整个社区都在讨论这门"更好的 Java"。十年过去了，Scala 的江湖地位起起伏伏，但它在某些领域依然是不可替代的存在。Spark、Kafka、Play Framework 这些重量级项目都是 Scala 写的。如果你做大数据或者分布式系统，绕不开它。

Scala 的野心很大：它想同时讨好面向对象阵营和函数式编程阵营。Martin Odersky 的设计思路很明确——不强迫你选择阵营，而是把两种范式揉在一起，让你按需取用。这种设计带来了极大的灵活性，也让学习曲线变得异常陡峭。我在面试中见过太多自称"精通 Scala"的候选人，连 `implicit` 的解析规则都说不清楚。

说个实话，Scala 的生态最近几年确实在走下坡路。Typesafe 改名 Lightbend 之后商业重心转移，社区里吵吵闹闹，Scala 3 的推出也没能挽回颓势。但瘦死的骆驼比马大，Spark 一天不死，Scala 就一天不会消亡。况且，学会 Scala 之后再看其他 JVM 语言，都会有一种"降维打击"的感觉。

## case class：不可变数据的优雅表达

case class 是我最喜欢的 Scala 特性之一。它比 Java 的 record 早出现很多年，功能也更强大。

```scala
// 定义一个 case class
case class User(name: String, email: String, age: Int)

// 创建实例——不需要 new 关键字
val alice = User("Alice", "alice@example.com", 28)

// 自动生成的 equals 和 hashCode
val alice2 = User("Alice", "alice@example.com", 28)
alice == alice2  // true

// 模式匹配解构
val User(n, e, a) = alice
// n = "Alice", e = "alice@example.com", a = 28

// copy 方法创建修改后的副本
val olderAlice = alice.copy(age = 29)
```

case class 会自动生成一堆有用的方法：`apply`、`unapply`、`copy`、`equals`、`hashCode`、`toString`。在模式匹配中，`unapply` 方法让解构变得异常自然。我在生产环境里大量用 case class 来建模领域对象，配合不可变性，消除了很多由状态突变引发的 bug。

有个细节很多人没注意到：case class 默认是 `Serializable` 的。这在分布式系统里非常重要——Spark 的 RDD 操作要求数据必须可序列化，用 case class 就省了很多事。Java 的 record 直到 Java 14 才出现，而且功能远没有 case class 丰富。

```scala
// case class 支持嵌套和递归
case class Address(city: String, zip: String)
case class Person(name: String, address: Address)

val person = Person("Bob", Address("NYC", "10001"))

// 深层 copy
val moved = person.copy(
  address = person.address.copy(city = "Boston")
)

// case object——单例的 case class
sealed trait Status
case object Pending extends Status
case object Approved extends Status
case object Rejected extends Status
```

## 模式匹配：不只是 switch 的高级版

很多从 Java 转过来的程序员把 Scala 的模式匹配当成"更好的 switch"。这完全是低估了它。模式匹配是 Scala 最核心的表达式之一，它能解构任意复杂的数据结构。

```scala
sealed trait Expr
case class Num(value: Int) extends Expr
case class Add(left: Expr, right: Expr) extends Expr
case class Mul(left: Expr, right: Expr) extends Expr

// 求值一个表达式树
def eval(expr: Expr): Int = expr match {
  case Num(value) => value
  case Add(l, r)  => eval(l) + eval(r)
  case Mul(l, r)  => eval(l) * eval(r)
}

val expr = Add(Mul(Num(2), Num(3)), Num(4))  // 2 * 3 + 4
eval(expr)  // 10
```

`sealed trait` 配合模式匹配是 Scala 中实现代数数据类型（ADT）的标准做法。编译器能检查模式匹配是否穷尽，如果你漏了某个 case，编译器会警告你。这种在编译期就捕获错误的能力，是我坚持用 Scala 做核心业务逻辑的主要原因。

我在一个支付系统里用 ADT 建模了所有交易状态。`sealed trait TransactionStatus` 下面有 `Pending`、`Completed`、`Failed`、`Refunded` 等 case class。状态转换逻辑用模式匹配实现，编译器确保我不会漏掉任何状态。结果三年下来，状态机相关的 bug 为零。

```scala
// 列表的模式匹配
def sumList(list: List[Int]): Int = list match {
  case Nil          => 0
  case head :: tail => head + sumList(tail)
}

// 守卫条件
def describe(x: Any): String = x match {
  case i: Int if i > 0 => s"正整数: $i"
  case i: Int if i < 0 => s"负整数: $i"
  case 0               => "零"
  case s: String       => s"字符串: $s"
  case _               => "其他"
}

// 提取器模式
object Email {
  def unapply(str: String): Option[(String, String)] = {
    val parts = str.split("@")
    if (parts.length == 2) Some((parts(0), parts(1))) else None
  }
}

"alice@example.com" match {
  case Email(user, domain) => s"User: $user, Domain: $domain"
  case _                   => "Not an email"
}
```

## 隐式转换：又爱又恨的黑魔法

隐式转换是 Scala 最有争议的 feature。用得好，它能让代码优雅到极致；用不好，它就是调试噩梦。

```scala
// 隐式类：为现有类型添加方法
implicit class RichInt(val n: Int) {
  def times(f: => Unit): Unit = (1 to n).foreach(_ => f)
}

// 现在所有 Int 都有 times 方法了
3.times(println("Hello!"))  // 打印三次
```

我在项目里见过最离谱的隐式转换链条：从一个字符串出发，经过三层隐式转换，最终变成数据库连接池。代码作者是三个月前离职的，现在没人敢碰那段代码。Scala 3 引入了 `given` 和 `using` 来替代老的 `implicit`，很大程度上就是为了解决隐式解析不透明的问题。

其实隐式转换本身不是问题，问题在于滥用。Scala 社区有个不成文的规矩：隐式转换只用于两种场景——类型类（type class）和扩展方法。超出这个范围，就是在给自己挖坑。

```scala
// Scala 3 的 given/using 语法
trait Ord[T] {
  def compare(x: T, y: T): Int
}

given Ord[Int] with {
  def compare(x: Int, y: Int): Int = x - y
}

def sort[T](list: List[T])(using ord: Ord[T]): List[T] =
  list.sorted(Ordering.by[T, Int](x => ord.compare(x, x)))  // 简化示意

// 使用——编译器自动找到 given 实例
sort(List(3, 1, 4, 1, 5))  // List(1, 1, 3, 4, 5)
```

## 高阶函数与函数组合

Scala 把函数提升为一等公民。你可以像传递变量一样传递函数，可以把函数作为返回值，还可以在运行时动态构造函数。

```scala
val numbers = List(1, 2, 3, 4, 5)

// map、filter、reduce——函数式编程三板斧
val doubled = numbers.map(_ * 2)           // List(2, 4, 6, 8, 10)
val evens = numbers.filter(_ % 2 == 0)     // List(2, 4)
val sum = numbers.reduce(_ + _)            // 15

// 函数组合
val addOne = (x: Int) => x + 1
val multiplyByTwo = (x: Int) => x * 2
val addOneThenDouble = addOne andThen multiplyByTwo
addOneThenDouble(3)  // 8

// 偏应用函数
def greet(greeting: String, name: String): String = s"$greeting, $name!"
val sayHello = greet("Hello", _: String)
sayHello("Alice")  // "Hello, Alice!"
```

函数组合是函数式编程的灵魂。在 Scala 里，你可以用 `andThen` 和 `compose` 把多个小函数拼接成复杂的处理管道。我在数据处理流水线里大量使用这种模式——每个阶段都是一个纯函数，组合起来就是完整的数据流。

```scala
// 柯里化
def add(x: Int)(y: Int): Int = x + y
val addFive = add(5)  // Int => Int
addFive(3)  // 8

// 函数作为参数——自定义控制结构
def timed[T](block: => T): T = {
  val start = System.nanoTime()
  val result = block
  val elapsed = (System.nanoTime() - start) / 1e6
  println(s"Elapsed: $elapsed ms")
  result
}

timed {
  Thread.sleep(100)
  42
}
```

## 特质（trait）：比接口更灵活

Scala 的 trait 是 Java 接口的超集。它可以有方法实现，可以持有抽象成员，还可以混入（mixin）到类中。Scala 通过 trait 实现了多重继承的能力，但避免了菱形继承问题。

```scala
trait Logger {
  def log(message: String): Unit = println(s"[LOG] $message")
}

trait TimestampLogger extends Logger {
  abstract override def log(message: String): Unit =
    super.log(s"${java.time.Instant.now()} $message")
}

trait FilterLogger extends Logger {
  val filterLevel: String
  abstract override def log(message: String): Unit =
    if (message.contains(filterLevel)) super.log(message)
}

// 通过 with 混入多个特质
class Service extends Logger with TimestampLogger with FilterLogger {
  val filterLevel = "ERROR"
}

val svc = new Service
svc.log("ERROR: Database connection failed")  // 会打印，带时间戳
svc.log("INFO: Request processed")             // 不会打印，被过滤了
```

`abstract override` 是 Scala 的一个独特概念，它允许你在特质中调用 `super` 的方法，即使这个方法在当前特质中还没有实现。这种线性化的混入机制，让 Scala 的 trait 比 Java 8 的默认方法灵活得多。

我在一个项目里用 trait 实现了审计日志的横切关注点。业务类只需要 `extends Auditable`，所有的数据库操作就会自动记录到审计表。这比 Spring AOP 的实现方式更轻量，也不需要任何运行时代理。

## for-comprehension：语法糖背后的 monad

Scala 的 for-comprehension 是对 monadic 操作的语法糖。它让嵌套的 `flatMap` 和 `map` 调用看起来像命令式代码。

```scala
val result = for {
  user    <- fetchUser(id)      // Option[User]
  profile <- user.profile       // Option[Profile]
  address <- profile.address    // Option[Address]
} yield address.city

// 上面的代码等价于：
// fetchUser(id).flatMap(_.profile).flatMap(_.profile.address).map(_.city)
```

我在团队里推广过 for-comprehension，发现大部分 Scala 开发者都停留在"用 for 替代嵌套 flatMap"的层面，很少有人真正理解它背后的 monad Laws。这没关系，能写出可读的代码就够了。但如果你要设计自己的 monad，那些定律是逃不掉的。

```scala
// 多个列表的笛卡尔积
val pairs = for {
  x <- List(1, 2)
  y <- List(''a'', ''b'')
} yield (x, y)
// List((1,''a''), (1,''b''), (2,''a''), (2,''b''))

// 带条件的 for-comprehension
val result = for {
  x <- List(1, 2, 3, 4, 5)
  if x > 2
  y = x * x
} yield y
// List(9, 16, 25)

// Future 的 for-comprehension
import scala.concurrent.{Future, ExecutionContext}
import scala.concurrent.duration._

implicit val ec: ExecutionContext = ExecutionContext.global

val result: Future[String] = for {
  user     <- fetchUserAsync(id)
  orders   <- fetchOrdersAsync(user.id)
  summary  <- generateSummaryAsync(orders)
} yield summary
```

## Option 与 Either：消灭 NullPointerException

Tony Hoare 称 null 引用是他"十亿美元的错误"。Scala 用 `Option` 和 `Either` 来从根本上解决这个问题。

```scala
// Option: 表示可能有值，也可能没有
val maybeValue: Option[Int] = Some(42)
val noValue: Option[Int] = None

// 安全地获取值
val result = maybeValue.getOrElse(0)  // 42
val fallback = noValue.getOrElse(0)   // 0

// 链式操作
val processed = maybeValue
  .map(_ * 2)
  .filter(_ > 50)
  .getOrElse(0)

// Either: 表示两种可能的结果类型
val success: Either[String, Int] = Right(42)
val failure: Either[String, Int] = Left("Invalid input")

// 处理错误
val finalResult = success match {
  case Right(value) => s"Success: $value"
  case Left(error)  => s"Error: $error"
}
```

在 Scala 代码里，null 应该像瘟疫一样被消灭。如果一个值可能不存在，用 `Option`；如果一个操作可能失败，用 `Either`。刚开始团队里会有人抱怨"总是需要 unwrap 太麻烦"，但三个月后，生产环境里的 NPE 基本绝迹，那些抱怨的人就闭嘴了。

```scala
// 从可能返回 null 的 Java API 安全转换
import scala.util.Try

def parseInt(str: String): Option[Int] = Try(str.toInt).toOption

// 累积错误——Either 的链式处理
import cats.implicits._

def validateName(name: String): Either[String, String] =
  if (name.nonEmpty) Right(name) else Left("Name cannot be empty")

def validateAge(age: Int): Either[String, Int] =
  if (age >= 0) Right(age) else Left("Age must be non-negative")

val validated = for {
  n <- validateName("Alice")
  a <- validateAge(25)
} yield (n, a)
// Right(("Alice", 25))
```

## Akka Actor：并发编程的另一种思路

Akka 的 Actor 模型是我在 Scala 生态里用过最久的并发框架。它的核心思想很简单：不要共享状态，通过消息传递来通信。

```scala
import akka.actor.{Actor, ActorRef, ActorSystem, Props}

// 定义一个 Actor
class Counter extends Actor {
  var count = 0

  def receive = {
    case "increment" => count += 1
    case "get"       => sender() ! count
    case "reset"     => count = 0
  }
}

// 创建 Actor 系统
val system = ActorSystem("MySystem")
val counter = system.actorOf(Props[Counter], "counter")

// 发送消息（异步、无阻塞）
counter ! "increment"
counter ! "increment"
counter ! "get"  // 收到 2
```

每个 Actor 有一个 mailbox，消息按 FIFO 顺序处理。因为 Actor 不共享状态，你不需要锁，不需要 synchronized，也不用担心死锁。Akka 让并发编程的复杂度大幅下降。

不过说实话，Akka 2.6 之后 License 改成了 BSL，商业使用有很多限制。Lightbend 的这个决策在社区里引起很大争议。如果你今天才开始一个新项目，我建议先评估一下 Akka Pekko（Apache fork）或者其他替代方案。

```scala
// 使用 ask 模式获取响应
import akka.pattern.ask
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

implicit val timeout: akka.util.Timeout = 5.seconds

val future = counter ? "get"  // Future[Any]
future.map { count =>
  println(s"当前计数: $count")
}

// Actor 层次结构和监督策略
import akka.actor.SupervisorStrategy._

class ParentActor extends Actor {
  override val supervisorStrategy =
    OneForOneStrategy(maxNrOfRetries = 10, withinTimeRange = 1.minute) {
      case _: ArithmeticException      => Resume
      case _: NullPointerException     => Restart
      case _: IllegalArgumentException => Stop
      case _: Exception                => Escalate
    }

  def receive = {
    case p: Props => sender() ! context.actorOf(p)
  }
}
```

## Future 与异步编程

Scala 标准库提供了 `Future` 来处理异步计算。配合 `flatMap` 和 `for-comprehension`，你可以写出优雅的异步代码。

```scala
import scala.concurrent.{Future, ExecutionContext}
import scala.concurrent.duration._
import scala.util.{Success, Failure}

implicit val ec: ExecutionContext = ExecutionContext.global

// 创建 Future
val f1 = Future { Thread.sleep(100); 42 }
val f2 = Future { Thread.sleep(50); 100 }

// 组合 Future
val combined = for {
  a <- f1
  b <- f2
} yield a + b  // Future(142)

// 处理失败
combined.onComplete {
  case Success(value) => println(s"Result: $value")
  case Failure(ex)    => println(s"Failed: ${ex.getMessage}")
}

// 超时控制
import scala.concurrent.Await
val result = Await.result(combined, 5.seconds)
```

## 总结

Scala 是一门让人又爱又恨的语言。它的类型系统强大到有时候你自己都不知道在写什么，编译器的错误信息长得能当论文读。但一旦跨过那个门槛，你会发现它的表达力和抽象能力几乎没有对手。

| 特性 | 作用 | 适用场景 |
|------|------|---------|
| case class | 不可变数据建模 | 领域对象、DTO |
| 模式匹配 | 数据结构解构 | 表达式求值、状态机 |
| 隐式/given | 类型类、扩展方法 | 库设计、DSL |
| 高阶函数 | 函数组合、抽象 | 数据处理管道 |
| trait | 代码复用、横切关注点 | 日志、缓存、验证 |
| for-comprehension | monadic 操作语法糖 | Option/Either/List 链式操作 |
| Option/Either | 空值与错误处理 | 所有可能失败的场景 |
| Actor | 消息驱动并发 | 分布式系统、高并发服务 |
| Future | 异步计算组合 | 非阻塞 I/O |

Scala 不适合所有人。如果你的团队以 Java 背景为主，强行切 Scala 可能会导致生产力下降和代码质量参差不齐。但如果你有充足的学习时间，并且项目确实需要高抽象层次的表达，Scala 是值得投入的选择。毕竟，Spark 和 Kafka 不会用一门烂语言来构建。

---

*本文首发于 Yggdrasil 博客*
     $doc$,
         NULL,
         '/images/covers/scala-fp-oop.jpg',
         '<ul>
<li><a href="#case-class-不可变数据的优雅表达">case class：不可变数据的优雅表达</a></li>
<li><a href="#模式匹配-不只是-switch-的高级版">模式匹配：不只是 switch 的高级版</a></li>
<li><a href="#隐式转换-又爱又恨的黑魔法">隐式转换：又爱又恨的黑魔法</a></li>
<li><a href="#高阶函数与函数组合">高阶函数与函数组合</a></li>
<li><a href="#特质-trait-比接口更灵活">特质（trait）：比接口更灵活</a></li>
<li><a href="#for-comprehension-语法糖背后的-monad">for-comprehension：语法糖背后的 monad</a></li>
<li><a href="#option-与-either-消灭-nullpointerexception">Option 与 Either：消灭 NullPointerException</a></li>
<li><a href="#akka-actor-并发编程的另一种思路">Akka Actor：并发编程的另一种思路</a></li>
<li><a href="#future-与异步编程">Future 与异步编程</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
         1482,
         8,
         'published',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '20 days'
) ON CONFLICT DO NOTHING;
