INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Swift 现代语法速览',
    'swift-modern-syntax',
    '全面梳理 Swift 现代语法特性，从可选类型到属性包装器，深入理解值类型与引用类型、协议扩展、泛型和错误处理，掌握 Swift 编程的核心概念和最佳实践。',
    $doc$
# Swift 现代语法速览

Swift 是 Apple 推出的现代编程语言，结合了 C 和 Objective-C 的优点，同时引入了函数式编程和类型安全的特性。本文将全面梳理 Swift 的核心语法，帮助你快速掌握这门语言。

## 为什么选择 Swift？

Swift 的设计目标是安全、快速、表达力强。它消除了 C 语言家族中许多不安全的特性，同时提供了现代化的语法和强大的类型系统。

> Swift 结合了编译型语言的性能和脚本语言的交互性，是现代 Apple 平台开发的首选语言。

## 基础语法

### 常量与变量

```swift
// 常量 - 不可变
let pi = 3.14159
let greeting = "Hello, Swift!"

// 变量 - 可变
var counter = 0
counter += 1

// 类型注解（通常可以省略，编译器会自动推断）
let explicitDouble: Double = 70.0
let implicitDouble = 70.0 // 同样是 Double

// 多行字符串
let multiline = """
    Swift is a powerful and intuitive
    programming language for iOS, iPadOS,
    macOS, watchOS, and tvOS.
    """
```

### 基本数据类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `Int` | 整数 | `let age: Int = 25` |
| `Double` | 双精度浮点 | `let price: Double = 19.99` |
| `String` | 字符串 | `let name = "Swift"` |
| `Bool` | 布尔 | `let isActive = true` |
| `Array` | 数组 | `let numbers = [1, 2, 3]` |
| `Dictionary` | 字典 | `let scores = ["A": 90]` |

### 字符串插值和运算

```swift
let name = "World"
let message = "Hello, \(name)!"

// 字符串操作
var str = "Swift"
str.append("!")
str += " Programming"

// 多行字符串保留格式
let poem = """
    Swift as the wind,
    Strong as a mountain,
    Elegant as poetry.
    """
```

## 可选类型（Optionals）

### 什么是可选类型

可选类型表示一个值可能存在，也可能不存在（nil）：

```swift
// 可选整数
var optionalNumber: Int? = 42
optionalNumber = nil

// 强制解包（危险！如果为 nil 会崩溃）
let forced = optionalNumber!

// 安全解包方式
if let number = optionalNumber {
    print("The number is \(number)")
} else {
    print("No number")
}

// Nil 合并运算符
let defaultNumber = optionalNumber ?? 0

// 可选链
let uppercased = optionalNumber?.description.uppercased()
```

### guard 语句

`guard` 语句用于提前退出，提高代码可读性：

```swift
func processUser(age: Int?, name: String?) {
    guard let validAge = age, validAge >= 0 else {
        print("Invalid age")
        return
    }

    guard let validName = name, !validName.isEmpty else {
        print("Invalid name")
        return
    }

    print("User: \(validName), Age: \(validAge)")
}

// 使用
processUser(age: 25, name: "Alice")  // 成功
processUser(age: -5, name: "Bob")    // Invalid age
processUser(age: 30, name: nil)      // Invalid name
```

### if let 和 guard let 对比

| 特性 | `if let` | `guard let` |
|------|----------|-------------|
| 作用域 | 仅在 if 块内 | 在 guard 之后的代码 |
| 使用场景 | 条件分支处理 | 前置条件检查 |
| 代码风格 | 嵌套可能较深 | 减少嵌套，提前退出 |

## 集合类型

### 数组和字典

```swift
// 数组
var fruits = ["Apple", "Banana", "Orange"]
fruits.append("Mango")
fruits.insert("Grape", at: 1)
let firstFruit = fruits[0]

// 字典
var scores: [String: Int] = [
    "Alice": 95,
    "Bob": 87,
    "Charlie": 92
]

scores["David"] = 88
if let aliceScore = scores["Alice"] {
    print("Alice scored \(aliceScore)")
}

// 遍历字典
for (name, score) in scores {
    print("\(name): \(score)")
}
```

### Set 集合

```swift
let favoriteGenres: Set<String> = ["Rock", "Classical", "Hip hop"]
let otherGenres: Set<String> = ["Jazz", "Rock", "Electronic"]

// 集合运算
let intersection = favoriteGenres.intersection(otherGenres)
let union = favoriteGenres.union(otherGenres)
let difference = favoriteGenres.symmetricDifference(otherGenres)

print("Both like: \(intersection)")
print("All genres: \(union)")
```

## 控制流

### 高级 switch

```swift
let character: Character = "a"

switch character {
case "a", "e", "i", "o", "u":
    print("\(character) is a vowel")
case "b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
     "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z":
    print("\(character) is a consonant")
default:
    print("\(character) is not a letter")
}

// 区间匹配
let count = 62
switch count {
case 0:
    print("none")
case 1..<5:
    print("a few")
case 5..<12:
    print("several")
case 12..<100:
    print("dozens")
case 100..<1000:
    print("hundreds")
default:
    print("many")
}

// 元组匹配
let point = (1, 1)
switch point {
case (0, 0):
    print("origin")
case (_, 0):
    print("on x-axis")
case (0, _):
    print("on y-axis")
case (-2...2, -2...2):
    print("inside the box")
default:
    print("outside")
}
```

### for-in 循环

```swift
// 遍历范围
for index in 1...5 {
    print("\(index) times 5 is \(index * 5)")
}

// 遍历数组
let names = ["Anna", "Alex", "Brian", "Jack"]
for name in names {
    print("Hello, \(name)!")
}

// 遍历字典
let numberOfLegs = ["spider": 8, "ant": 6, "cat": 4]
for (animalName, legCount) in numberOfLegs {
    print("\(animalName)s have \(legCount) legs")
}

// 带索引的遍历
for (index, name) in names.enumerated() {
    print("\(index + 1). \(name)")
}

// stride 函数
let minutes = 60
let minuteInterval = 5
for tickMark in stride(from: 0, to: minutes, by: minuteInterval) {
    print("Tick mark at \(tickMark) minutes")
}
```

## 函数和闭包

### 函数定义

```swift
// 基本函数
func greet(person: String) -> String {
    return "Hello, \(person)!"
}

// 参数标签和参数名
func greet(person: String, from hometown: String) -> String {
    return "Hello \(person)! Glad you could visit from \(hometown)."
}

let greeting = greet(person: "Bill", from: "Cupertino")

// 默认参数
func greet(person: String, nicely: Bool = true) -> String {
    if nicely {
        return "Hello, \(person)!"
    } else {
        return "Oh no, it's \(person) again..."
    }
}

print(greet(person: "Tim"))           // Hello, Tim!
print(greet(person: "Tim", nicely: false))  // Oh no, it's Tim again...

// 可变参数
func arithmeticMean(_ numbers: Double...) -> Double {
    var total: Double = 0
    for number in numbers {
        total += number
    }
    return total / Double(numbers.count)
}

print(arithmeticMean(1, 2, 3, 4, 5))
```

### 闭包（Closures）

```swift
// 基本闭包
let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]

// 完整写法
let reversedNames = names.sorted(by: { (s1: String, s2: String) -> Bool in
    return s1 > s2
})

// 类型推断简化
let reversedNames2 = names.sorted(by: { s1, s2 in return s1 > s2 })

// 隐式返回
let reversedNames3 = names.sorted(by: { s1, s2 in s1 > s2 })

// 简写参数名
let reversedNames4 = names.sorted(by: { \$0 > \$1 })

// 尾随闭包
let reversedNames5 = names.sorted { \$0 > \$1 }

// 捕获值
func makeIncrementer(forIncrement amount: Int) -> () -> Int {
    var runningTotal = 0
    func incrementer() -> Int {
        runningTotal += amount
        return runningTotal
    }
    return incrementer
}

let incrementByTen = makeIncrementer(forIncrement: 10)
print(incrementByTen()) // 10
print(incrementByTen()) // 20
```

## 结构体与类

### 值类型 vs 引用类型

```swift
// 结构体 - 值类型
struct Resolution {
    var width = 0
    var height = 0
}

// 类 - 引用类型
class VideoMode {
    var resolution = Resolution()
    var interlaced = false
    var frameRate = 0.0
    var name: String?
}

let hd = Resolution(width: 1920, height: 1080)
var cinema = hd // 值拷贝
cinema.width = 2048

print("hd width: \(hd.width)")         // 1920
print("cinema width: \(cinema.width)")  // 2048

let tenEighty = VideoMode()
tenEighty.resolution = hd
tenEighty.interlaced = true
tenEighty.name = "1080i"
tenEighty.frameRate = 25.0

let alsoTenEighty = tenEighty // 引用拷贝
alsoTenEighty.frameRate = 30.0

print("tenEighty frameRate: \(tenEighty.frameRate)")  // 30.0
```

### 属性观察器

```swift
class StepCounter {
    var totalSteps: Int = 0 {
        willSet(newTotalSteps) {
            print("About to set totalSteps to \(newTotalSteps)")
        }
        didSet {
            if totalSteps > oldValue  {
                print("Added \(totalSteps - oldValue) steps")
            }
        }
    }
}

let stepCounter = StepCounter()
stepCounter.totalSteps = 200
// About to set totalSteps to 200
// Added 200 steps
stepCounter.totalSteps = 360
// About to set totalSteps to 360
// Added 160 steps
```

## 协议与扩展

### 协议定义

```swift
protocol FullyNamed {
    var fullName: String { get }
}

protocol RandomNumberGenerator {
    func random() -> Double
}

// 协议继承
protocol NamedAndAged: FullyNamed {
    var age: Int { get }
}

// 遵循协议
struct Person: FullyNamed {
    var firstName: String
    var lastName: String

    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

let john = Person(firstName: "John", lastName: "Appleseed")
print(john.fullName)
```

### 扩展

```swift
// 扩展现有类型
extension Int {
    func repetitions(task: () -> Void) {
        for _ in 0..<self {
            task()
        }
    }

    var squared: Int {
        return self * self
    }
}

3.repetitions {
    print("Hello!")
}

print(5.squared) // 25

// 协议扩展提供默认实现
extension RandomNumberGenerator {
    func randomBool() -> Bool {
        return random() > 0.5
    }
}
```

## 泛型

### 泛型函数和类型

```swift
// 泛型函数
func swapTwoValues<T>(_ a: inout T, _ b: inout T) {
    let temporaryA = a
    a = b
    b = temporaryA
}

var someInt = 3
var anotherInt = 107
swapTwoValues(&someInt, &anotherInt)

var someString = "hello"
var anotherString = "world"
swapTwoValues(&someString, &anotherString)

// 泛型类型
struct Stack<Element> {
    private var items: [Element] = []

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element {
        return items.removeLast()
    }

    var topItem: Element? {
        return items.isEmpty ? nil : items[items.count - 1]
    }

    var isEmpty: Bool {
        return items.isEmpty
    }
}

var stackOfStrings = Stack<String>()
stackOfStrings.push("uno")
stackOfStrings.push("dos")
stackOfStrings.push("tres")
print(stackOfStrings.pop()) // tres

// 泛型约束
func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
    for (index, value) in array.enumerated() {
        if value == valueToFind {
            return index
        }
    }
    return nil
}
```

## 错误处理

### 定义和抛出错误

```swift
enum PrinterError: Error {
    case outOfPaper
    case noToner
    case onFire
}

func send(job: Int, toPrinter printerName: String) throws -> String {
    if printerName == "Never Has Toner" {
        throw PrinterError.noToner
    }
    return "Job sent"
}

// 使用 do-catch
func processPrintJob() {
    do {
        let printerResponse = try send(job: 1040, toPrinter: "Bi Sheng")
        print(printerResponse)
    } catch PrinterError.onFire {
        print("I'll just put this over here, with the rest of the fire.")
    } catch let printerError as PrinterError {
        print("Printer error: \(printerError).")
    } catch {
        print(error)
    }
}

// try? 转换为可选
let printerSuccess = try? send(job: 1884, toPrinter: "Mergenthaler")
let printerFailure = try? send(job: 1885, toPrinter: "Never Has Toner")

// defer
func processFile(filename: String) throws {
    let file = open(filename)
    defer {
        close(file)
    }
    // 处理文件...
    // 无论是否抛出错误，defer 都会执行
}
```

## 属性包装器

```swift
@propertyWrapper
struct TwelveOrLess {
    private var number = 0
    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, 12) }
    }
}

struct SmallRectangle {
    @TwelveOrLess var height: Int
    @TwelveOrLess var width: Int
}

var rectangle = SmallRectangle()
print(rectangle.height) // 0

rectangle.height = 10
print(rectangle.height) // 10

rectangle.height = 24
print(rectangle.height) // 12
```

## 总结

Swift 是一门现代化的编程语言，提供了丰富的特性：

1. **类型安全**：可选类型消除空指针异常
2. **值类型优先**：结构体和枚举都是值类型，减少副作用
3. **协议导向**：通过协议和扩展实现多态
4. **函数式特性**：闭包、高阶函数、不可变性
5. **现代语法**：类型推断、字符串插值、模式匹配

> Swift 的设计哲学是安全、快速、表达力强。它不仅仅是一门 iOS 开发语言，也是一门通用的现代编程语言。

通过本文的学习，你应该已经掌握了 Swift 的核心语法特性，可以开始构建 iOS、macOS 或其他平台的应用程序了。

## 结果类型与错误传播

Swift 5.0 引入了 `Result` 类型，为异步操作和可能失败的计算提供了类型安全的错误处理方式。

### Result 类型基础

```swift
enum NetworkError: Error {
    case badURL
    case noData
    case decodingError
}

func fetchUserData(userID: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
    guard let url = URL(string: "https://api.example.com/users/\(userID)") else {
        completion(.failure(.badURL))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            completion(.success(user))
        } catch {
            completion(.failure(.decodingError))
        }
    }.resume()
}

// 使用
fetchUserData(userID: "123") { result in
    switch result {
    case .success(let user):
        print("获取用户成功: \(user.name)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

### Result 的链式操作

```swift
// map：转换成功值
let result: Result<Int, NetworkError> = .success(10)
let doubled = result.map { $0 * 2 } // .success(20)

// flatMap：链式可能失败的操作
let stringResult = doubled.flatMap { value -> Result<String, NetworkError> in
    if value > 0 {
        return .success(String(value))
    }
    return .failure(.noData)
}

// 获取值或默认值
let value = result.mapError { _ in NetworkError.noData }.getOrElse(0)
```

| Result 方法 | 作用 | 返回值 |
|------------|------|--------|
| `map` | 转换成功值 | `Result<U, E>` |
| `mapError` | 转换错误 | `Result<T, F>` |
| `flatMap` | 链式操作 | `Result<U, E>` |
| `get` | 获取成功值（可能抛出） | `T` |
| `getOrElse` | 获取值或默认值 | `T` |

## 异步/等待（Async/Await）

Swift 5.5 引入了 async/await 语法，彻底改变了 Swift 的并发编程方式。

### 基本用法

```swift
// 定义异步函数
func fetchUser async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: userURL)
    let user = try JSONDecoder().decode(User.self, from: data)
    return user
}

// 调用异步函数
func updateUI() async {
    do {
        let user = try await fetchUser()
        print("欢迎, \(user.name)!")
    } catch {
        print("获取用户失败: \(error)")
    }
}

// 在 Task 中执行
Task {
    await updateUI()
}
```

### 并发执行多个任务

```swift
// 顺序执行（较慢）
func fetchSequential() async throws -> (User, Order) {
    let user = try await fetchUser()
    let order = try await fetchOrder()
    return (user, order)
}

// 并发执行（更快）
func fetchConcurrent() async throws -> (User, Order) {
    async let userTask = fetchUser()
    async let orderTask = fetchOrder()
    
    let user = try await userTask
    let order = try await orderTask
    return (user, order)
}

// 使用 TaskGroup 处理动态数量的任务
func fetchAllUsers(userIDs: [String]) async -> [User] {
    await withTaskGroup(of: User.self) { group in
        for id in userIDs {
            group.addTask {
                await fetchUser(id: id)
            }
        }
        
        var users: [User] = []
        for await user in group {
            users.append(user)
        }
        return users
    }
}
```

### MainActor 与 UI 更新

```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    
    func loadUser(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            user = try await fetchUser(id: id)
        } catch {
            print("Error: \(error)")
        }
    }
}

// 在视图中使用
struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        VStack {
            if let user = viewModel.user {
                Text(user.name)
            }
        }
        .task {
            await viewModel.loadUser(id: "123")
        }
    }
}
```

| 并发特性 | 用途 | 引入版本 |
|---------|------|---------|
| `async/await` | 异步编程 | Swift 5.5 |
| `Task` | 创建异步任务 | Swift 5.5 |
| `async let` | 并发绑定 | Swift 5.5 |
| `TaskGroup` | 动态任务组 | Swift 5.5 |
| `@MainActor` | 主线程安全 | Swift 5.5 |
| `Continuation` | 桥接回调式 API | Swift 5.5 |

## SwiftUI 与属性包装器实战

SwiftUI 大量使用了属性包装器来管理状态和数据流。

### 核心属性包装器

```swift
import SwiftUI

struct ContentView: View {
    // @State：视图内部的可变状态
    @State private var count = 0
    
    // @Binding：父子视图间的双向绑定
    @Binding var isPresented: Bool
    
    // @ObservedObject：引用外部可观察对象
    @ObservedObject var viewModel: UserViewModel
    
    // @StateObject：视图拥有的可观察对象（生命周期绑定）
    @StateObject private var settings = Settings()
    
    // @Environment：读取环境值
    @Environment(\.colorScheme) var colorScheme
    
    // @AppStorage：自动同步 UserDefaults
    @AppStorage("username") var username = ""
    
    // @SceneStorage：状态恢复
    @SceneStorage("selectedTab") var selectedTab = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            
            Button("Increment") {
                count += 1
            }
            
            Toggle("Presented", isOn: $isPresented)
        }
    }
}
```

### 自定义属性包装器

```swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// 使用
struct Settings {
    @UserDefault(key: "isDarkMode", defaultValue: false)
    var isDarkMode: Bool
    
    @UserDefault(key: "fontSize", defaultValue: 16)
    var fontSize: Int
}

var settings = Settings()
settings.isDarkMode = true // 自动保存到 UserDefaults
print(settings.isDarkMode) // 从 UserDefaults 读取
```

### 状态管理架构对比

| 方案 | 适用场景 | 复杂度 | 数据流 |
|------|---------|--------|--------|
| `@State` | 简单视图状态 | 低 | 单向 |
| `@StateObject` | 视图拥有对象 | 低 | 单向 |
| `MVVM` | 中等复杂度应用 | 中 | 双向绑定 |
| `Redux/Observable` | 复杂全局状态 | 高 | 单向数据流 |
| `@EnvironmentObject` | 跨视图共享状态 | 中 | 依赖注入 |

```swift
// MVVM 示例
class TodoViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var filter: Filter = .all
    
    var filteredTodos: [Todo] {
        switch filter {
        case .all: return todos
        case .active: return todos.filter { !$0.isCompleted }
        case .completed: return todos.filter { \$0.isCompleted }
        }
    }
    
    func addTodo(title: String) {
        todos.append(Todo(id: UUID(), title: title))
    }
    
    func toggleTodo(id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
        }
    }
}

struct TodoListView: View {
    @StateObject private var viewModel = TodoViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.filteredTodos) { todo in
                TodoRow(todo: todo) {
                    viewModel.toggleTodo(id: todo.id)
                }
            }
        }
    }
}
```

> **SwiftUI 最佳实践**：优先使用值类型（`struct`）和 `@State`，只有在需要共享状态或处理复杂逻辑时才使用 `ObservableObject` 和 `@StateObject`。

通过本文的学习，你应该已经掌握了 Swift 的核心语法特性，可以开始构建 iOS、macOS 或其他平台的应用程序了。
$doc$,
    NULL,
    '/images/covers/swift-modern-syntax.jpg',
    '<ul>
<li><a href="#为什么选择-swift">为什么选择 Swift？</a></li>
<li><a href="#基础语法">基础语法</a></li>
<ul>
<li><a href="#常量与变量">常量与变量</a></li>
<li><a href="#基本数据类型">基本数据类型</a></li>
<li><a href="#字符串插值和运算">字符串插值和运算</a></li>
</ul>
<li><a href="#可选类型-optionals">可选类型（Optionals）</a></li>
<ul>
<li><a href="#什么是可选类型">什么是可选类型</a></li>
<li><a href="#guard-语句">guard 语句</a></li>
<li><a href="#if-let-和-guard-let-对比">if let 和 guard let 对比</a></li>
</ul>
<li><a href="#集合类型">集合类型</a></li>
<ul>
<li><a href="#数组和字典">数组和字典</a></li>
<li><a href="#set-集合">Set 集合</a></li>
</ul>
<li><a href="#控制流">控制流</a></li>
<ul>
<li><a href="#高级-switch">高级 switch</a></li>
<li><a href="#for-in-循环">for-in 循环</a></li>
</ul>
<li><a href="#函数和闭包">函数和闭包</a></li>
<ul>
<li><a href="#函数定义">函数定义</a></li>
<li><a href="#闭包-closures">闭包（Closures）</a></li>
</ul>
<li><a href="#结构体与类">结构体与类</a></li>
<ul>
<li><a href="#值类型-vs-引用类型">值类型 vs 引用类型</a></li>
<li><a href="#属性观察器">属性观察器</a></li>
</ul>
<li><a href="#协议与扩展">协议与扩展</a></li>
<ul>
<li><a href="#协议定义">协议定义</a></li>
<li><a href="#扩展">扩展</a></li>
</ul>
<li><a href="#泛型">泛型</a></li>
<ul>
<li><a href="#泛型函数和类型">泛型函数和类型</a></li>
</ul>
<li><a href="#错误处理">错误处理</a></li>
<ul>
<li><a href="#定义和抛出错误">定义和抛出错误</a></li>
</ul>
<li><a href="#属性包装器">属性包装器</a></li>
<li><a href="#总结">总结</a></li>
<li><a href="#结果类型与错误传播">结果类型与错误传播</a></li>
<ul>
<li><a href="#result-类型基础">Result 类型基础</a></li>
<li><a href="#result-的链式操作">Result 的链式操作</a></li>
</ul>
<li><a href="#异步-等待-async-await">异步/等待（Async/Await）</a></li>
<ul>
<li><a href="#基本用法">基本用法</a></li>
<li><a href="#并发执行多个任务">并发执行多个任务</a></li>
<li><a href="#mainactor-与-ui-更新">MainActor 与 UI 更新</a></li>
</ul>
<li><a href="#swiftui-与属性包装器实战">SwiftUI 与属性包装器实战</a></li>
<ul>
<li><a href="#核心属性包装器">核心属性包装器</a></li>
<li><a href="#自定义属性包装器">自定义属性包装器</a></li>
<li><a href="#状态管理架构对比">状态管理架构对比</a></li>
</ul>
</ul>',
    1913,
    10,
    'published',
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;
