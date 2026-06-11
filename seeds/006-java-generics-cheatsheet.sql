INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Java 泛型深度解析：从基础到通配符的PECS原则',
    'java-generics-cheatsheet',
    'Java 泛型是类型安全的基石，本文深入讲解泛型类、泛型方法、通配符及其上界下界，以及PECS原则在实际编程中的应用。',
    $doc$
# Java 泛型深度解析：从基础到通配符的 PECS 原则

Java 泛型（Generics）是自 JDK 5 引入的一项重要特性，它为 Java 语言带来了**编译期类型检查**和**类型安全**的能力。在没有泛型之前，Java 集合只能存储 `Object` 类型，取出数据时需要进行强制类型转换，这不仅繁琐，而且容易在运行时抛出 `ClassCastException`。

本文将从基础概念出发，深入探讨 Java 泛型的核心机制，包括泛型类、泛型方法、通配符、类型擦除，以及实际开发中最常用的 PECS 原则。

## 泛型的基础概念

### 泛型类

泛型类允许你在定义类时使用类型参数，这些类型参数在创建实例时被具体化：

```java
// 定义泛型类
public class Box<T> {
    private T value;
    
    public void set(T value) {
        this.value = value;
    }
    
    public T get() {
        return value;
    }
    
    public static void main(String[] args) {
        // 创建 String 类型的 Box
        Box<String> stringBox = new Box<>();
        stringBox.set("Hello Generics");
        String str = stringBox.get(); // 无需类型转换
        
        // 创建 Integer 类型的 Box
        Box<Integer> intBox = new Box<>();
        intBox.set(42);
        Integer num = intBox.get();
    }
}
```

### 泛型方法

泛型方法允许你在普通类或泛型类中定义带有类型参数的方法：

```java
public class GenericMethodExample {
    
    // 泛型方法
    public <T> void printArray(T[] array) {
        for (T element : array) {
            System.out.println(element);
        }
    }
    
    // 泛型方法 with 返回值
    public <T> T getFirst(T[] array) {
        return array.length > 0 ? array[0] : null;
    }
    
    // 泛型方法 with 多个类型参数
    public <K, V> void printPair(K key, V value) {
        System.out.println("Key: " + key + ", Value: " + value);
    }
    
    public static void main(String[] args) {
        GenericMethodExample example = new GenericMethodExample();
        
        String[] names = {"Alice", "Bob", "Charlie"};
        example.printArray(names);
        
        Integer first = example.getFirst(new Integer[]{1, 2, 3});
        example.printPair("ID", 1001);
    }
}
```

### 类型参数的约束

你可以使用 `extends` 关键字对类型参数进行约束：

```java
// T 必须是 Number 的子类
public class NumberBox<T extends Number> {
    private T value;
    
    public double getDoubleValue() {
        return value.doubleValue();
    }
}

// 使用
NumberBox<Integer> intBox = new NumberBox<>(); // ✅
NumberBox<Double> doubleBox = new NumberBox<>(); // ✅
// NumberBox<String> stringBox = new NumberBox<>(); // ❌ 编译错误
```

## 通配符（Wildcards）

泛型中的通配符 `?` 表示**未知类型**，它提供了更灵活的类型兼容性。

### 无界通配符 `?`

```java
public void printList(List<?> list) {
    for (Object obj : list) {
        System.out.println(obj);
    }
}

// 可以接受任何类型的 List
printList(new ArrayList<String>());
printList(new ArrayList<Integer>());
```

### 上界通配符 `? extends T`

`? extends T` 表示**T 的子类型**，适用于读取数据的场景：

```java
// 可以接受 Number 及其子类型的 List
public double sumNumbers(List<? extends Number> numbers) {
    double sum = 0;
    for (Number num : numbers) {
        sum += num.doubleValue();
    }
    return sum;
}

// 使用
List<Integer> ints = Arrays.asList(1, 2, 3);
List<Double> doubles = Arrays.asList(1.1, 2.2, 3.3);

sumNumbers(ints);    // ✅ Integer 是 Number 的子类
sumNumbers(doubles); // ✅ Double 是 Number 的子类
```

### 下界通配符 `? super T`

`? super T` 表示**T 的父类型**，适用于写入数据的场景：

```java
// 可以接受 Integer 及其父类型的 List
public void addIntegers(List<? super Integer> list) {
    list.add(1);
    list.add(2);
    list.add(3);
}

// 使用
List<Number> numbers = new ArrayList<>();
List<Object> objects = new ArrayList<>();

addIntegers(numbers); // ✅ Number 是 Integer 的父类
addIntegers(objects); // ✅ Object 是 Integer 的父类
// addIntegers(new ArrayList<String>()); // ❌ 编译错误
```

## PECS 原则

PECS 是 Java 泛型中最重要也最实用的原则，它是 **Producer-Extends, Consumer-Super** 的缩写：

| 原则 | 含义 | 使用场景 |
|------|------|---------|
| **Producer-Extends** | 如果数据从集合中产出（读取），使用 `? extends T` | 方法参数用于读取 |
| **Consumer-Super** | 如果数据被消费（写入），使用 `? super T` | 方法参数用于写入 |

### 实际案例：Collections.copy

Java 标准库中的 `Collections.copy` 方法完美诠释了 PECS 原则：

```java
public static <T> void copy(List<? super T> dest, List<? extends T> src) {
    for (int i = 0; i < src.size(); i++) {
        dest.set(i, src.get(i));
    }
}
```

分析：
- `src`（源列表）是**生产者**，从中读取数据，所以用 `? extends T`
- `dest`（目标列表）是**消费者**，向其中写入数据，所以用 `? super T`

### 实战示例

```java
public class PECSExample {
    
    // Producer: 从列表中读取数据
    public static double sumOfList(List<? extends Number> list) {
        double sum = 0.0;
        for (Number n : list) {
            sum += n.doubleValue();
        }
        return sum;
    }
    
    // Consumer: 向列表中写入数据
    public static void addNumbers(List<? super Integer> list) {
        for (int i = 1; i <= 5; i++) {
            list.add(i);
        }
    }
    
    public static void main(String[] args) {
        // Producer 示例
        List<Integer> ints = Arrays.asList(1, 2, 3);
        List<Double> doubles = Arrays.asList(1.1, 2.2, 3.3);
        
        System.out.println(sumOfList(ints));    // 6.0
        System.out.println(sumOfList(doubles)); // 6.6
        
        // Consumer 示例
        List<Number> numbers = new ArrayList<>();
        addNumbers(numbers);
        System.out.println(numbers); // [1, 2, 3, 4, 5]
        
        List<Object> objects = new ArrayList<>();
        addNumbers(objects);
        System.out.println(objects); // [1, 2, 3, 4, 5]
    }
}
```

## 类型擦除（Type Erasure）

Java 泛型采用了**类型擦除**机制来实现向后兼容。在编译期，所有泛型信息都会被擦除，替换为它们的上界（通常是 `Object`）：

```java
// 编译前
List<String> strings = new ArrayList<>();
String s = strings.get(0);

// 编译后（类型擦除）
List strings = new ArrayList();
String s = (String) strings.get(0); // 自动插入类型转换
```

### 类型擦除的影响

1. **不能使用基本类型**：`List<int>` 是错误的，必须使用 `List<Integer>`
2. **运行时类型检查受限**：`instanceof List<String>` 是非法的
3. **不能创建泛型数组**：`new T[10]` 是非法的
4. **可以通过反射绕过泛型检查**：

```java
List<String> strings = new ArrayList<>();
// strings.add(42); // 编译错误

// 但可以通过反射绕过
Method m = strings.getClass().getMethod("add", Object.class);
m.invoke(strings, 42); // 运行时成功添加 Integer！
```

## 泛型与继承

泛型类型之间**不协变**（not covariant）：

```java
List<Object> objects = new ArrayList<String>(); // ❌ 编译错误
```

虽然 `String` 是 `Object` 的子类，但 `List<String>` 并不是 `List<Object>` 的子类。这是为了防止以下运行时错误：

```java
// 假设允许协变
List<String> strings = new ArrayList<>();
List<Object> objects = strings; // 假设可以
objects.add(42); // 向字符串列表中添加整数！
String s = strings.get(0); // ClassCastException！
```

## 总结

Java 泛型是类型安全的基石，掌握它需要理解以下核心概念：

| 概念 | 说明 | 示例 |
|------|------|------|
| 泛型类 | 类级别的类型参数 | `class Box<T>` |
| 泛型方法 | 方法级别的类型参数 | `<T> T method(T arg)` |
| `? extends T` | 上界通配符，用于读取 | `List<? extends Number>` |
| `? super T` | 下界通配符，用于写入 | `List<? super Integer>` |
| PECS | Producer-Extends, Consumer-Super | `copy(dest, src)` |
| 类型擦除 | 编译期擦除泛型信息 | `List<String>` → `List` |

> **最佳实践**：始终遵循 PECS 原则设计 API，使用通配符增加 API 的灵活性，但不要过度使用复杂的泛型嵌套，保持代码的可读性。

## 泛型在集合框架中的深度应用

Java 集合框架是泛型最广泛的应用场景。深入理解集合的泛型设计，有助于你更好地使用和设计泛型 API。

### 集合的泛型层次结构

```java
// 集合框架的核心接口泛型定义
// Collection<E> → List<E> → ArrayList<E>
// Collection<E> → Set<E> → HashSet<E>
// Map<K, V> → HashMap<K, V>

// 示例：泛型集合的正确使用
List<String> names = new ArrayList<>();        // E = String
Set<Integer> uniqueNumbers = new HashSet<>();  // E = Integer
Map<String, Integer> scores = new HashMap<>(); // K = String, V = Integer

// 注意：数组与泛型的区别
List<String>[] arrayOfLists = new List[10]; // 警告：泛型数组创建
arrayOfLists[0] = new ArrayList<String>();
// arrayOfLists[0].add("Hello"); // 可能需要类型转换
```

### 自定义泛型集合

让我们实现一个类型安全的优先队列（最小堆）：

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Comparator;

public class GenericMinHeap<T> {
    private List<T> heap;
    private Comparator<? super T> comparator;
    
    public GenericMinHeap() {
        this.heap = new ArrayList<>();
        this.comparator = null; // 要求 T 实现 Comparable
    }
    
    public GenericMinHeap(Comparator<? super T> comparator) {
        this.heap = new ArrayList<>();
        this.comparator = comparator;
    }
    
    @SuppressWarnings("unchecked")
    private int compare(T a, T b) {
        if (comparator != null) {
            return comparator.compare(a, b);
        }
        return ((Comparable<? super T>) a).compareTo(b);
    }
    
    public void add(T element) {
        heap.add(element);
        siftUp(heap.size() - 1);
    }
    
    public T poll() {
        if (heap.isEmpty()) return null;
        T result = heap.get(0);
        T last = heap.remove(heap.size() - 1);
        if (!heap.isEmpty()) {
            heap.set(0, last);
            siftDown(0);
        }
        return result;
    }
    
    public T peek() {
        return heap.isEmpty() ? null : heap.get(0);
    }
    
    private void siftUp(int index) {
        while (index > 0) {
            int parent = (index - 1) / 2;
            if (compare(heap.get(index), heap.get(parent)) >= 0) break;
            swap(index, parent);
            index = parent;
        }
    }
    
    private void siftDown(int index) {
        int size = heap.size();
        while (true) {
            int left = 2 * index + 1;
            int right = 2 * index + 2;
            int smallest = index;
            
            if (left < size && compare(heap.get(left), heap.get(smallest)) < 0)
                smallest = left;
            if (right < size && compare(heap.get(right), heap.get(smallest)) < 0)
                smallest = right;
            
            if (smallest == index) break;
            swap(index, smallest);
            index = smallest;
        }
    }
    
    private void swap(int i, int j) {
        T temp = heap.get(i);
        heap.set(i, heap.get(j));
        heap.set(j, temp);
    }
    
    public boolean isEmpty() {
        return heap.isEmpty();
    }
    
    public int size() {
        return heap.size();
    }
}

// 使用示例
class Task implements Comparable<Task> {
    String name;
    int priority; // 数字越小优先级越高
    
    Task(String name, int priority) {
        this.name = name;
        this.priority = priority;
    }
    
    @Override
    public int compareTo(Task other) {
        return Integer.compare(this.priority, other.priority);
    }
    
    @Override
    public String toString() {
        return name + "(priority:" + priority + ")";
    }
}

// 使用自定义类型
GenericMinHeap<Task> taskQueue = new GenericMinHeap<>();
taskQueue.add(new Task("紧急修复", 1));
taskQueue.add(new Task("常规更新", 3));
taskQueue.add(new Task("文档编写", 5));

while (!taskQueue.isEmpty()) {
    System.out.println("处理: " + taskQueue.poll());
}
// 输出：紧急修复(priority:1), 常规更新(priority:3), 文档编写(priority:5)
```

## 泛型与函数式编程

Java 8 引入的 Stream API 大量使用了泛型，结合 Lambda 表达式，可以写出非常简洁的代码。

### Stream API 中的泛型

```java
import java.util.*;
import java.util.stream.*;

public class StreamGenerics {
    
    // 泛型方法处理任意类型的 Stream
    public static <T> List<T> filterAndCollect(
            Stream<T> stream, 
            Predicate<? super T> predicate) {
        return stream.filter(predicate)
                     .collect(Collectors.toList());
    }
    
    // 泛型映射
    public static <T, R> List<R> mapToList(
            List<T> list, 
            Function<? super T, ? extends R> mapper) {
        return list.stream()
                   .map(mapper)
                   .collect(Collectors.toList());
    }
    
    // 泛型归约
    public static <T> T reduce(
            List<T> list, 
            T identity, 
            BinaryOperator<T> accumulator) {
        return list.stream().reduce(identity, accumulator);
    }
    
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5);
        
        // 过滤偶数
        List<Integer> evens = filterAndCollect(
            numbers.stream(), 
            n -> n % 2 == 0
        );
        
        // 映射为字符串
        List<String> strings = mapToList(
            numbers, 
            n -> "Number: " + n
        );
        
        // 求和
        Integer sum = reduce(numbers, 0, Integer::sum);
    }
}
```

### 自定义函数式接口

```java
@FunctionalInterface
interface Converter<F, T> {
    T convert(F from);
    
    // 默认方法
    default <V> Converter<F, V> andThen(Converter<? super T, ? extends V> after) {
        return (F f) -> after.convert(convert(f));
    }
}

// 使用
Converter<String, Integer> stringToInt = Integer::parseInt;
Converter<Integer, Double> intToDouble = Integer::doubleValue;
Converter<String, Double> stringToDouble = stringToInt.andThen(intToDouble);

Double result = stringToDouble.convert("42"); // 42.0
```

| 函数式接口 | 泛型签名 | 用途 |
|-----------|---------|------|
| `Function<T, R>` | T → R | 类型转换 |
| `Predicate<T>` | T → boolean | 条件判断 |
| `Consumer<T>` | T → void | 消费数据 |
| `Supplier<T>` | () → T | 提供数据 |
| `BinaryOperator<T>` | (T, T) → T | 二元操作 |

## 实战：类型安全的缓存系统

让我们综合运用泛型知识，实现一个生产级的类型安全缓存系统：

```java
import java.util.*;
import java.util.concurrent.*;
import java.lang.ref.SoftReference;

public class GenericCache<K, V> {
    private final Map<K, CacheEntry<V>> cache;
    private final long defaultTTL; // 默认过期时间（毫秒）
    private final int maxSize;
    
    private static class CacheEntry<V> {
        V value;
        long expiryTime;
        long accessTime;
        
        CacheEntry(V value, long ttl) {
            this.value = value;
            this.expiryTime = System.currentTimeMillis() + ttl;
            this.accessTime = System.currentTimeMillis();
        }
        
        boolean isExpired() {
            return System.currentTimeMillis() > expiryTime;
        }
    }
    
    public GenericCache(int maxSize, long defaultTTL) {
        this.maxSize = maxSize;
        this.defaultTTL = defaultTTL;
        // 使用 LinkedHashMap 实现 LRU
        this.cache = new LinkedHashMap<K, CacheEntry<V>>(16, 0.75f, true) {
            @Override
            protected boolean removeEldestEntry(Map.Entry<K, CacheEntry<V>> eldest) {
                return size() > maxSize;
            }
        };
    }
    
    public synchronized void put(K key, V value) {
        put(key, value, defaultTTL);
    }
    
    public synchronized void put(K key, V value, long ttl) {
        cache.put(key, new CacheEntry<>(value, ttl));
    }
    
    public synchronized V get(K key) {
        CacheEntry<V> entry = cache.get(key);
        if (entry == null) return null;
        
        if (entry.isExpired()) {
            cache.remove(key);
            return null;
        }
        
        entry.accessTime = System.currentTimeMillis();
        return entry.value;
    }
    
    public synchronized boolean containsKey(K key) {
        return get(key) != null;
    }
    
    public synchronized void invalidate(K key) {
        cache.remove(key);
    }
    
    public synchronized void invalidateAll() {
        cache.clear();
    }
    
    public synchronized int size() {
        // 清理过期条目后返回大小
        cleanUp();
        return cache.size();
    }
    
    private void cleanUp() {
        cache.entrySet().removeIf(entry -> entry.getValue().isExpired());
    }
    
    // 批量操作
    public Map<K, V> getAll(Collection<? extends K> keys) {
        Map<K, V> result = new HashMap<>();
        for (K key : keys) {
            V value = get(key);
            if (value != null) {
                result.put(key, value);
            }
        }
        return result;
    }
    
    // 使用 Supplier 实现缓存加载
    public V getOrLoad(K key, Supplier<? extends V> loader) {
        V value = get(key);
        if (value == null) {
            value = loader.get();
            put(key, value);
        }
        return value;
    }
}

// 使用示例
class UserService {
    private final GenericCache<String, User> userCache;
    
    public UserService() {
        this.userCache = new GenericCache<>(1000, 300_000); // 1000条，5分钟过期
    }
    
    public User getUser(String userId) {
        return userCache.getOrLoad(userId, () -> loadFromDatabase(userId));
    }
    
    private User loadFromDatabase(String userId) {
        // 模拟数据库查询
        System.out.println("Loading user from DB: " + userId);
        return new User(userId, "User " + userId);
    }
}

class User {
    String id;
    String name;
    
    User(String id, String name) {
        this.id = id;
        this.name = name;
    }
}
```

这个缓存系统展示了泛型的多个重要应用：
- **类型参数**：`K` 和 `V` 分别表示键和值的类型
- **泛型方法**：`getOrLoad` 使用 `Supplier<? extends V>` 实现延迟加载
- **通配符**：`getAll` 方法接受 `Collection<? extends K>`
- **内部类**：`CacheEntry<V>` 独立于外部类的类型参数

| 特性 | 实现方式 | 优势 |
|------|---------|------|
| 类型安全 | 泛型参数 K, V | 编译期类型检查 |
| LRU 淘汰 | LinkedHashMap | 自动管理内存 |
| 过期策略 | TTL + 定时清理 | 防止脏数据 |
| 懒加载 | Supplier 函数式接口 | 按需加载，减少数据库压力 |

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days'
) ON CONFLICT DO NOTHING;
