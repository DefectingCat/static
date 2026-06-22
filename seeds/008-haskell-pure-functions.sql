INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Haskell 纯函数、惰性求值与 Monad：函数式编程的精髓',
    'haskell-pure-functions',
    '深入理解 Haskell 的纯函数、惰性求值、高阶函数和 Monad，探索函数式编程的核心思想。',
    $doc$
# Haskell 纯函数、惰性求值与 Monad：函数式编程的精髓

Haskell 是一门**纯函数式编程语言**，以严格的数学基础和优雅的设计著称。与命令式语言不同，Haskell 强调函数的数学本质：**函数只是从输入到输出的映射**，没有副作用、没有状态变化、没有隐式的执行顺序。这种纯粹性带来了前所未有的代码可预测性和可组合性。

本文将深入探讨 Haskell 的三大核心特性：纯函数、惰性求值和 Monad，帮助你理解函数式编程的精髓。

## 纯函数（Pure Functions）

纯函数是函数式编程的基石。一个函数是纯函数，当且仅当满足两个条件：

1. **引用透明**（Referential Transparency）：对于相同的输入，永远返回相同的输出
2. **无副作用**（No Side Effects）：不修改外部状态，不执行 I/O 操作

### 纯函数示例

```haskell
-- 纯函数：给定输入，总有确定的输出
factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)

-- 另一个纯函数
square :: Num a => a -> a
square x = x * x

-- 纯函数可以安全地被替换为其结果（引用透明）
-- square 5 总是可以被替换为 25
```

### 纯函数的优势

| 特性 | 说明 |
|------|------|
| 可测试性 | 无需模拟外部状态，输入确定即可测试 |
| 可缓存性 | 结果可以被记忆化（memoization） |
| 可并行性 | 无共享状态，天然适合并行计算 |
| 可组合性 | 函数可以像乐高积木一样组合 |

## 高阶函数（Higher-Order Functions）

Haskell 中的函数是一等公民，可以作为参数传递，也可以作为返回值：

```haskell
-- map：对列表每个元素应用函数
map :: (a -> b) -> [a] -> [b]
doubleAll = map (* 2)
-- doubleAll [1, 2, 3] => [2, 4, 6]

-- filter：根据条件过滤列表
filter :: (a -> Bool) -> [a] -> [a]
evens = filter even
-- evens [1..10] => [2, 4, 6, 8, 10]

-- foldl / foldr：列表归约
sumList = foldl (+) 0
-- sumList [1, 2, 3, 4] => 10

-- 函数组合
(.) :: (b -> c) -> (a -> b) -> a -> c
f . g = \\x -> f (g x)

-- 使用函数组合
process = sum . map square . filter even
-- process [1..10] = sum (map square (filter even [1..10]))
```

### 自定义高阶函数

```haskell
-- 将函数应用两次
applyTwice :: (a -> a) -> a -> a
applyTwice f x = f (f x)

-- 使用
applyTwice (+ 3) 10  -- 16
applyTwice reverse [1, 2, 3]  -- [1, 2, 3]

-- 柯里化（Currying）
add :: Int -> Int -> Int
add x y = x + y

-- add 5 是一个接收 Int 返回 Int 的函数
addFive = add 5
addFive 3  -- 8
```

## 惰性求值（Lazy Evaluation）

Haskell 默认采用**惰性求值**（Lazy Evaluation），也称为**按需调用**（Call by Need）。这意味着表达式在真正需要其值时才会被计算。

### 无限列表

惰性求值最惊人的特性之一，就是可以定义**无限数据结构**：

```haskell
-- 无限自然数列表
nats :: [Integer]
nats = [0..]

-- 无限偶数列表
evens :: [Integer]
evens = [0, 2..]

-- 无限斐波那契数列
fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

-- 使用 take 只取有限部分
main = do
    print $ take 10 nats       -- [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    print $ take 10 evens      -- [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
    print $ take 15 fibs       -- [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377]
```

### 列表推导式

Haskell 的列表推导式（List Comprehension）是处理集合的强大工具：

```haskell
-- 基本列表推导式
squares = [x^2 | x <- [1..10]]
-- [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

-- 带过滤条件
evenSquares = [x^2 | x <- [1..20], even x]
-- [4, 16, 36, 64, 100, 144, 196, 256, 324, 400]

-- 多生成器
pairs = [(x, y) | x <- [1..3], y <- ['a', 'b']]
-- [(1,'a'), (1,'b'), (2,'a'), (2,'b'), (3,'a'), (3,'b')]

-- 使用 let 绑定
result = [let y = x * 2 in (x, y) | x <- [1..5]]
-- [(1,2), (2,4), (3,6), (4,8), (5,10)]
```

### 惰性求值的实际应用

```haskell
-- 只计算需要的部分
firstEvenSquareOver100 = head [x^2 | x <- [1..], even x, x^2 > 100]
-- 结果为 144（12^2），不需要计算 [1..] 的所有元素

-- 短路求值
and' :: [Bool] -> Bool
and' = foldr (&&) True
-- and' (False : undefined) => False
-- 不需要计算 undefined，因为第一个 False 已经决定了结果
```

## 类型系统与类型类

Haskell 拥有强大的静态类型系统和类型推断能力：

```haskell
-- 代数数据类型（Algebraic Data Types）
data Shape = Circle Float
           | Rectangle Float Float
           | Triangle Float Float Float
           deriving (Show, Eq)

area :: Shape -> Float
area (Circle r) = pi * r * r
area (Rectangle w h) = w * h
area (Triangle a b c) = 
    let s = (a + b + c) / 2
    in sqrt (s * (s - a) * (s - b) * (s - c))

-- 类型类（Type Classes）
class Describable a where
    describe :: a -> String

instance Describable Shape where
    describe (Circle r) = "半径为 " ++ show r ++ " 的圆"
    describe (Rectangle w h) = show w ++ " x " ++ show h ++ " 的矩形"
```

## Monad：处理副作用的优雅方式

纯函数不能执行 I/O 操作，但程序总要与外界交互。Haskell 使用 **Monad** 来在纯函数式框架内处理副作用。

### Maybe Monad：处理可能失败的计算

```haskell
-- 安全除法
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv a b = Just (a `div` b)

-- 使用 do 语法串联 Maybe 计算
calculate :: Int -> Int -> Int -> Maybe Int
calculate x y z = do
    a <- safeDiv x y    -- 如果失败，整个计算返回 Nothing
    b <- safeDiv a z
    return (b + 1)

-- 示例
calculate 10 2 3  -- Just 2
calculate 10 0 3  -- Nothing
calculate 10 2 0  -- Nothing
```

### IO Monad：处理输入输出

```haskell
-- IO 是一个 Monad，将副作用操作封装起来
greet :: IO ()
greet = do
    putStrLn "请输入你的名字:"
    name <- getLine
    putStrLn $ "你好, " ++ name ++ "!"

-- 使用 >>=（bind）操作符
main :: IO ()
main = putStrLn "Hello" >>= \_ -> putStrLn "World"
```

### 常用 Monad

| Monad | 用途 | 示例 |
|-------|------|------|
| `Maybe` | 可能失败的计算 | `safeDiv`、`lookup` |
| `Either` | 带错误信息的计算 | `parseNumber` |
| `IO` | 输入输出操作 | `readFile`、`putStrLn` |
| `List` | 非确定性计算 | 多个结果 |
| `State` | 状态传递 | 计数器、随机数生成 |
| `Reader` | 环境读取 | 配置读取 |
| `Writer` | 日志记录 | 追踪计算过程 |

## 总结

Haskell 的函数式编程范式带来了全新的编程思维方式：

| 概念 | 核心思想 | 优势 |
|------|---------|------|
| 纯函数 | 无副作用、引用透明 | 可预测、可测试、可并行 |
| 惰性求值 | 按需计算 | 无限数据结构、短路求值 |
| 高阶函数 | 函数作为一等公民 | 强大的组合能力 |
| 类型系统 | 强类型、类型推断 | 编译期捕获错误 |
| Monad | 在纯函数框架内处理副作用 | 优雅的副作用管理 |

> "学习 Haskell 不是为了在工作中使用它，而是为了以全新的方式思考编程。" —— 匿名

## Functor、Applicative 与 Monad 进阶

在理解 Monad 之前，我们需要先了解它的两个重要前身：Functor 和 Applicative。它们共同构成了 Haskell 中处理"上下文中的值"的抽象层次。

### Functor

Functor 表示可以被映射（map）的结构：

```haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b

-- Maybe 是 Functor 的实例
fmap (+1) (Just 5)        -- Just 6
fmap (+1) Nothing         -- Nothing

-- 列表也是 Functor
fmap (*2) [1, 2, 3]       -- [2, 4, 6]
```

### Applicative Functor

Applicative 允许我们将函数也包裹在上下文中：

```haskell
class Functor f => Applicative f where
    pure  :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b

-- 使用 Applicative 组合多个 Maybe 值
addMaybes :: Maybe Int -> Maybe Int -> Maybe Int
addMaybes mx my = (+) <$> mx <*> my

-- 示例
addMaybes (Just 3) (Just 4)   -- Just 7
addMaybes (Just 3) Nothing    -- Nothing

-- 列表作为 Applicative：笛卡尔积
pure (+) <*> [1, 2] <*> [10, 20]
-- [11, 21, 12, 22]
```

### Monad 与 Applicative 的关系

| 抽象 | 能力 | 核心操作 | 典型应用 |
|------|------|----------|----------|
| `Functor` | 应用普通函数到上下文值 | `fmap` | 转换容器内值 |
| `Applicative` | 应用上下文函数到上下文值 | `<*>`, `pure` | 独立计算组合 |
| `Monad` | 后续计算依赖前面结果 | `>>=`, `return` | 链式依赖计算 |

```haskell
-- 使用 liftA2（Applicative）组合独立计算
import Control.Applicative

liftA2 (+) (Just 1) (Just 2)     -- Just 3

-- 使用 >>=（Monad）组合依赖计算
half :: Int -> Maybe Int
half x = if even x then Just (x `div` 2) else Nothing

Just 20 >>= half >>= half   -- Just 5
Just 20 >>= half >>= half >>= half  -- Nothing
```

## Monad 转换器实战

实际项目中 rarely 只使用单一 Monad。Haskell 通过 Monad 转换器（Monad Transformers）来组合多个 Monad 的能力。

### 常见 Monad 转换器

```haskell
import Control.Monad.Trans.Reader
import Control.Monad.Trans.State
import Control.Monad.Trans.Writer
import Control.Monad.Trans.Except
import Control.Monad.Trans.Class (lift)

type App a = ExceptT String (ReaderT Config (StateT AppState IO)) a

-- 简化的组合示例
logAndCount :: WriterT [String] (State Int) ()
logAndCount = do
    lift $ modify (+1)
    n <- lift get
    tell ["Count incremented to: " ++ show n]
    lift $ modify (+1)
    n' <- lift get
    tell ["Count incremented to: " ++ show n']

-- 运行
runState (runWriterT logAndCount) 0
-- 返回 ((), ["Count incremented to: 1", "Count incremented to: 2"], 2)
```

### 构建 Web 应用风格的 Monad 栈

```haskell
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

import Control.Monad.Reader
import Control.Monad.Except
import Control.Monad.IO.Class

data AppConfig = AppConfig {
    dbConnection :: String,
    apiKey       :: String
}

data AppError = NotFound String | ValidationError String | DatabaseError String
    deriving (Show)

newtype AppM a = AppM {
    runAppM :: ReaderT AppConfig (ExceptT AppError IO) a
} deriving (Functor, Applicative, Monad, MonadReader AppConfig, MonadError AppError, MonadIO)

getUserById :: Int -> AppM String
getUserById userId = do
    config <- ask
    when (null (apiKey config)) $
        throwError $ ValidationError "API key is missing"
    if userId > 0
        then return $ "User " ++ show userId
        else throwError $ NotFound $ "User " ++ show userId

-- 运行
main :: IO ()
main = do
    let config = AppConfig "postgres://localhost" "secret-key"
    result <- runExceptT $ runReaderT (runAppM $ getUserById 42) config
    case result of
        Left err  -> putStrLn $ "Error: " ++ show err
        Right val -> putStrLn $ "Success: " ++ val
```

### Monad 转换器选择指南

| 场景 | 基础 Monad | 转换器 | 用途 |
|------|-----------|--------|------|
| 错误处理 | `Either` | `ExceptT` | 统一错误传播 |
| 环境读取 | `Reader` | `ReaderT` | 共享配置、依赖注入 |
| 状态管理 | `State` | `StateT` | 可变状态模拟 |
| 日志记录 | `Writer` | `WriterT` | 累积日志、审计 |
| IO 操作 | `IO` | 作为栈底 | 与外部世界交互 |

## 函数式编程模式

Haskell 丰富的类型系统催生了许多强大的编程模式。

### 递归模式与 Catamorphism

```haskell
-- fold 是列表的 catamorphism
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f z []     = z
foldr f z (x:xs) = f x (foldr f z xs)

-- 用 foldr 实现各种列表操作
sum'     = foldr (+) 0
product' = foldr (*) 1
length'  = foldr (\_ acc -> acc + 1) 0
map' f   = foldr (\x acc -> f x : acc) []
filter' p = foldr (\x acc -> if p x then x : acc else acc) []

-- unfoldr：从种子生成列表
import Data.List
fibonacci :: [Integer]
fibonacci = unfoldr (\(a, b) -> Just (a, (b, a + b))) (0, 1)
-- take 10 fibonacci => [0,1,1,2,3,5,8,13,21,34]
```

### Lens：函数式数据操作

Lens 提供了优雅的不可变数据更新方式：

```haskell
{-# LANGUAGE TemplateHaskell #-}
import Control.Lens

data Address = Address {
    _street :: String,
    _city   :: String,
    _zip    :: String
} deriving (Show)

data Person = Person {
    _name    :: String,
    _age     :: Int,
    _address :: Address
} deriving (Show)

makeLenses ''Address
makeLenses ''Person

-- 使用 Lens 更新嵌套字段
john :: Person
john = Person "John" 30 (Address "123 Main St" "NYC" "10001")

-- 更新年龄
johnAfterBirthday = age +~ 1 $ john
-- Person "John" 31 ...

-- 更新嵌套地址的城市
johnMoved = address . city .~ "Boston" $ john
-- Person "John" 30 (Address "123 Main St" "Boston" "10001")

-- 组合修改
johnUpdated = john 
    & age +~ 1
    & address . city .~ "Boston"
    & address . zip .~ "02101"
```

### 设计模式对比

| 命令式模式 | Haskell 对应 | 说明 |
|-----------|-------------|------|
| Strategy | 高阶函数 | 将行为作为参数传递 |
| Observer | FRP / STM | 响应式编程或软件事务内存 |
| Iterator | 递归 / fold / unfold | 统一遍历模式 |
| Builder | 记录语法 + Monoid | 累积式构造 |
| Singleton | 纯函数 + 缓存 | 不需要传统单例 |
| Factory | 类型类 + 智能构造函数 | 多态创建 |

## 总结

Haskell 的函数式编程范式带来了全新的编程思维方式：

| 概念 | 核心思想 | 优势 |
|------|---------|------|
| 纯函数 | 无副作用、引用透明 | 可预测、可测试、可并行 |
| 惰性求值 | 按需计算 | 无限数据结构、短路求值 |
| 高阶函数 | 函数作为一等公民 | 强大的组合能力 |
| 类型系统 | 强类型、类型推断 | 编译期捕获错误 |
| Monad | 在纯函数框架内处理副作用 | 优雅的副作用管理 |
| Monad 转换器 | 组合多种上下文 | 构建复杂应用架构 |
| Lens | 声明式不可变更新 | 优雅的嵌套数据操作 |

> "学习 Haskell 不是为了在工作中使用它，而是为了以全新的方式思考编程。" —— 匿名

Haskell 可能不是最适合所有场景的语言，但它所倡导的函数式编程思想——不可变性、纯函数、组合——已经深刻影响了现代编程语言的设计。从 JavaScript 的 `map`/`filter`/`reduce`，到 Java 的 Stream API，再到 Rust 的迭代器，函数式编程的思想无处不在。

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    '/images/covers/haskell-pure-functions.jpg',
    '<ul>
<li><a href="#纯函数-pure-functions">纯函数（Pure Functions）</a></li>
<ul>
<li><a href="#纯函数示例">纯函数示例</a></li>
<li><a href="#纯函数的优势">纯函数的优势</a></li>
</ul>
<li><a href="#高阶函数-higher-order-functions">高阶函数（Higher-Order Functions）</a></li>
<ul>
<li><a href="#自定义高阶函数">自定义高阶函数</a></li>
</ul>
<li><a href="#惰性求值-lazy-evaluation">惰性求值（Lazy Evaluation）</a></li>
<ul>
<li><a href="#无限列表">无限列表</a></li>
<li><a href="#列表推导式">列表推导式</a></li>
<li><a href="#惰性求值的实际应用">惰性求值的实际应用</a></li>
</ul>
<li><a href="#类型系统与类型类">类型系统与类型类</a></li>
<li><a href="#monad-处理副作用的优雅方式">Monad：处理副作用的优雅方式</a></li>
<ul>
<li><a href="#maybe-monad-处理可能失败的计算">Maybe Monad：处理可能失败的计算</a></li>
<li><a href="#io-monad-处理输入输出">IO Monad：处理输入输出</a></li>
<li><a href="#常用-monad">常用 Monad</a></li>
</ul>
<li><a href="#总结">总结</a></li>
<li><a href="#functor-applicative-与-monad-进阶">Functor、Applicative 与 Monad 进阶</a></li>
<ul>
<li><a href="#functor">Functor</a></li>
<li><a href="#applicative-functor">Applicative Functor</a></li>
<li><a href="#monad-与-applicative-的关系">Monad 与 Applicative 的关系</a></li>
</ul>
<li><a href="#monad-转换器实战">Monad 转换器实战</a></li>
<ul>
<li><a href="#常见-monad-转换器">常见 Monad 转换器</a></li>
<li><a href="#构建-web-应用风格的-monad-栈">构建 Web 应用风格的 Monad 栈</a></li>
<li><a href="#monad-转换器选择指南">Monad 转换器选择指南</a></li>
</ul>
<li><a href="#函数式编程模式">函数式编程模式</a></li>
<ul>
<li><a href="#递归模式与-catamorphism">递归模式与 Catamorphism</a></li>
<li><a href="#lens-函数式数据操作">Lens：函数式数据操作</a></li>
<li><a href="#设计模式对比">设计模式对比</a></li>
</ul>
<li><a href="#总结">总结</a></li>
</ul>',
    1203,
    7,
    'published',
    NOW() - INTERVAL '12 hours',
    NOW() - INTERVAL '12 hours',
    NOW() - INTERVAL '12 hours'
) ON CONFLICT DO NOTHING;
