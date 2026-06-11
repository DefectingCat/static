INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'TypeScript 高级类型体操：从条件类型到模板字面量',
    'typescript-type-gymnastics',
    '探索 TypeScript 类型系统的极限，从条件类型到映射类型，再到模板字面量类型和类型推断，让你的代码在编译期就获得强大的类型保障。',
    $doc$
# TypeScript 高级类型体操：从条件类型到模板字面量

TypeScript 的类型系统是一门**图灵完备**的语言。这意味着，在理论上，你可以使用 TypeScript 的类型系统来实现任何可计算的程序。虽然我们不建议在真实项目中过度使用复杂的类型体操，但掌握这些高级类型技巧，可以帮助你构建更加健壮、可维护的类型定义，特别是在开发库和框架时。

本文将从基础到高级，系统介绍 TypeScript 的类型系统特性，包括条件类型、映射类型、模板字面量类型、递归类型和类型推断等。

## 为什么需要高级类型？

在日常开发中，基础类型（`string`、`number`、`boolean`）和简单的接口往往已经足够。但在以下场景中，高级类型变得至关重要：

- **开发类型安全的库**：如 Vue、React、Redux 等框架的类型定义
- **编写通用工具函数**：如 lodash 的类型定义
- **实现类型转换**：如将对象的所有属性变为可选或只读
- **约束 API 接口**：确保编译器能够推断出正确的响应类型

## 条件类型（Conditional Types）

条件类型是 TypeScript 2.8 引入的特性，它允许你根据类型关系选择不同的类型：

```typescript
type IsString<T> = T extends string ? true : false;

// 使用示例
type A = IsString<string>;  // true
type B = IsString<number>;  // false
type C = IsString<"hello">; // true（字面量类型也是 string 的子类型）
```

### extends 关键字

在条件类型中，`extends` 表示"是否是...的子类型"：

```typescript
type IsArray<T> = T extends any[] ? true : false;

type D = IsArray<number[]>; // true
type E = IsArray<string>;   // false
```

### infer 关键字：类型推断

`infer` 是 TypeScript 中最强大的关键字之一，它允许你在条件类型中"提取"类型：

```typescript
// 提取数组元素类型
type ElementType<T> = T extends (infer U)[] ? U : never;

type F = ElementType<string[]>; // string
type G = ElementType<number[]>; // number

// 提取函数返回值类型
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

function getUser() {
    return { id: 1, name: "Alice" };
}

type User = ReturnType<typeof getUser>; // { id: number; name: string; }

// 提取 Promise 的解析类型
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

type H = UnwrapPromise<Promise<string>>; // string
```

### 内置条件类型

TypeScript 标准库已经提供了许多基于条件类型的工具类型：

| 类型 | 作用 | 示例 |
|------|------|------|
| `Exclude<T, U>` | 从 T 中排除 U | `Exclude<'a' \| 'b', 'a'>` → `'b'` |
| `Extract<T, U>` | 从 T 中提取 U | `Extract<'a' \| 'b', 'a' \| 'c'>` → `'a'` |
| `NonNullable<T>` | 排除 null 和 undefined | `NonNullable<string \| null>` → `string` |
| `ReturnType<T>` | 获取函数返回类型 | `ReturnType<() => number>` → `number` |
| `Parameters<T>` | 获取函数参数类型 | `Parameters<(a: string) => void>` → `[string]` |
| `InstanceType<T>` | 获取构造函数实例类型 | `InstanceType<typeof Date>` → `Date` |

## 映射类型（Mapped Types）

映射类型允许你基于已有类型创建新类型，通过遍历属性键来转换每个属性：

### 基础映射类型

```typescript
type Readonly<T> = {
    readonly [P in keyof T]: T[P];
};

type Partial<T> = {
    [P in keyof T]?: T[P];
};

type Required<T> = {
    [P in keyof T]-?: T[P]; // -? 移除可选性
};

// 使用示例
interface User {
    name: string;
    age: number;
}

type ReadonlyUser = Readonly<User>;
// { readonly name: string; readonly age: number; }

type PartialUser = Partial<User>;
// { name?: string; age?: number; }
```

### 键重映射（Key Remapping）

TypeScript 4.1 引入了 `as` 关键字，允许在映射类型中重命名键：

```typescript
// 将每个属性名添加 "get" 前缀，类型变为函数
type Getters<T> = {
    [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface Person {
    name: string;
    age: number;
}

type PersonGetters = Getters<Person>;
// { getName: () => string; getAge: () => number; }
```

### 过滤属性

```typescript
// 只保留 string 类型的属性
type StringProperties<T> = {
    [K in keyof T as T[K] extends string ? K : never]: T[K];
};

interface User {
    name: string;
    age: number;
    email: string;
}

type StringUserProps = StringProperties<User>;
// { name: string; email: string; }
```

## 模板字面量类型（Template Literal Types）

TypeScript 4.1 引入了模板字面量类型，它允许你通过字符串字面量类型来构造新类型：

### 基础用法

```typescript
type EventName<T extends string> = `on${Capitalize<T>}`;

type ClickEvent = EventName<"click">;      // "onClick"
type HoverEvent = EventName<"mouseOver">;  // "onMouseOver"
```

### 联合类型的组合

当模板字面量类型与联合类型结合使用时，会产生**笛卡尔积**效果：

```typescript
type Horizontal = "left" | "center" | "right";
type Vertical = "top" | "center" | "bottom";

type Alignment = `${Horizontal}-${Vertical}`;
// "left-top" | "left-center" | "left-bottom" |
// "center-top" | "center-center" | "center-bottom" |
// "right-top" | "right-center" | "right-bottom"
```

### 实际应用：CSS 属性类型

```typescript
type CSSProperty = "margin" | "padding";
type CSSDirection = "top" | "right" | "bottom" | "left";

type CSSKey = `${CSSProperty}${Capitalize<CSSDirection>}` | CSSProperty;
// "margin" | "padding" | "marginTop" | "marginRight" | ...
```

## 递归类型

TypeScript 支持递归类型定义，这在处理嵌套数据结构时非常有用：

```typescript
// 深度只读类型
type DeepReadonly<T> = {
    readonly [P in keyof T]: T[P] extends object
        ? DeepReadonly<T[P]>
        : T[P];
};

interface NestedUser {
    name: string;
    address: {
        city: string;
        coordinates: {
            lat: number;
            lng: number;
        };
    };
}

type DeepReadonlyUser = DeepReadonly<NestedUser>;
// 所有嵌套属性都变为 readonly

// 深度 Partial 类型
type DeepPartial<T> = {
    [P in keyof T]?: T[P] extends object
        ? DeepPartial<T[P]>
        : T[P];
};

// 扁平化对象类型（将嵌套属性用点号连接）
type Flatten<T, Prefix = ""> = {
    [K in keyof T as K extends string
        ? Prefix extends ""
            ? K
            : `${Prefix & string}.${K}`
        : never
    ]: T[K] extends object ? Flatten<T[K], `${Prefix & string}.${K & string}`> : T[K];
};
```

## 类型守卫与类型收窄

TypeScript 的类型系统不仅在编译期工作，还能通过类型守卫在运行时收窄类型：

```typescript
// typeof 类型守卫
function processValue(value: string | number) {
    if (typeof value === "string") {
        // 此分支中 value 的类型为 string
        return value.toUpperCase();
    } else {
        // 此分支中 value 的类型为 number
        return value.toFixed(2);
    }
}

// 自定义类型守卫
type Cat = { kind: "cat"; meow: () => void };
type Dog = { kind: "dog"; bark: () => void };
type Animal = Cat | Dog;

function isCat(animal: Animal): animal is Cat {
    return animal.kind === "cat";
}

function makeSound(animal: Animal) {
    if (isCat(animal)) {
        animal.meow();
    } else {
        animal.bark();
    }
}
```

## 实用类型工具库

基于上述类型特性，你可以构建强大的类型工具库：

```typescript
// 将对象的所有嵌套属性路径提取为联合类型
type Path<T, K extends keyof T = keyof T> = K extends string
    ? T[K] extends object
        ? `${K}` | `${K}.${Path<T[K]>}`
        : `${K}`
    : never;

// 安全的深度属性访问类型
type DeepPick<T, P extends string> = P extends `${infer K}.${infer Rest}`
    ? K extends keyof T
        ? { [key in K]: DeepPick<T[K], Rest> }
        : never
    : P extends keyof T
    ? { [key in P]: T[P] }
    : never;
```

## 总结

TypeScript 的类型系统提供了丰富的工具来构建类型安全的应用程序：

| 特性 | 版本 | 作用 |
|------|------|------|
| 条件类型 | 2.8 | 基于类型关系选择类型 |
| infer | 2.8 | 在条件类型中提取类型 |
| 映射类型 | 2.1 | 遍历属性键转换类型 |
| 模板字面量 | 4.1 | 构造字符串字面量类型 |
| 键重映射 | 4.1 | 在映射中重命名属性键 |
| 递归类型 | 3.7+ | 处理嵌套数据结构 |

> ⚠️ **温馨提示**：类型体操虽有趣，但过度使用会降低代码可读性和编译性能。遵循"简单优于复杂"的原则，在合适的场景使用高级类型。对于大多数业务代码，基础类型和简单的接口已经足够。

## 类型挑战与实战

学习类型体操的最佳方式是通过实战挑战。以下是几个常见的类型编程问题及其解决方案：

### 挑战 1：实现 DeepPick

实现一个深度选择类型，可以从嵌套对象中按路径提取子集：

```typescript
type DeepPick<T, K extends string> = K extends `${infer First}.${infer Rest}`
    ? First extends keyof T
        ? { [P in First]: DeepPick<T[First], Rest> }
        : never
    : K extends keyof T
    ? { [P in K]: T[P] }
    : never;

// 使用示例
interface Company {
    name: string;
    address: {
        city: string;
        country: {
            code: string;
            name: string;
        };
    };
}

type CompanyNameAndCity = DeepPick<Company, "name" | "address.city">;
// { name: string; address: { city: string; } }
```

### 挑战 2：实现 UnionToTuple

将联合类型转换为元组类型（保留顺序）：

```typescript
type UnionToIntersection<U> = (U extends any ? (x: U) => void : never) extends (x: infer I) => void ? I : never;

type LastInUnion<U> = UnionToIntersection<U extends any ? (x: U) => void : never> extends (x: infer L) => void ? L : never;

type UnionToTuple<U, Last = LastInUnion<U>> = [U] extends [never] ? [] : [...UnionToTuple<Exclude<U, Last>>, Last];

// 使用示例
type Result = UnionToTuple<'a' | 'b' | 'c'>;
// ['a', 'b', 'c']（顺序可能因实现而异）
```

### 挑战 3：实现 AllKeys

获取对象所有层级的键的联合类型：

```typescript
type AllKeys<T> = T extends object
    ? keyof T extends infer K
        ? K extends string
            ? K | AllKeys<T[K]>
            : never
        : never
    : never;

interface Nested {
    a: { b: { c: string } };
    d: number;
}

type Keys = AllKeys<Nested>; // "a" | "b" | "c" | "d"
```

| 挑战 | 核心概念 | 难度 |
|------|---------|------|
| DeepPick | 条件类型 + 递归 + 模板字面量 | ⭐⭐⭐ |
| UnionToTuple | 逆变 + 交叉类型 + 递归 | ⭐⭐⭐⭐ |
| AllKeys | 递归 + keyof + 联合类型分发 | ⭐⭐⭐ |

## 类型安全的路由与 API

在实际项目中，类型体操最常见的应用场景之一是构建类型安全的路由系统和 API 客户端。

### 类型安全的路由参数

```typescript
// 定义路由参数映射
type RouteParams = {
    '/users/:id': { id: string };
    '/users/:id/posts/:postId': { id: string; postId: string };
    '/products/:category/:id': { category: string; id: string };
};

// 提取路径参数类型
type ExtractParams<T extends string> = 
    T extends `${infer _}/:${infer Param}/${infer Rest}`
        ? { [K in Param | keyof ExtractParams<`/${Rest}`>]: string }
        : T extends `${infer _}/:${infer Param}`
        ? { [K in Param]: string }
        : {};

// 使用
function navigate<T extends keyof RouteParams>(
    path: T,
    params: RouteParams[T]
): void {
    console.log(`Navigating to ${path} with ${JSON.stringify(params)}`);
}

navigate('/users/:id', { id: '123' }); // ✅
// navigate('/users/:id', { id: 123 }); // ❌ 类型错误
// navigate('/users/:id', { postId: '123' }); // ❌ 类型错误
```

### 类型安全的 API 客户端

```typescript
interface APIEndpoints {
    'GET /users': { response: User[] };
    'GET /users/:id': { params: { id: string }; response: User };
    'POST /users': { body: CreateUserRequest; response: User };
    'DELETE /users/:id': { params: { id: string }; response: void };
}

type Method = 'GET' | 'POST' | 'PUT' | 'DELETE';

type ExtractEndpoint<T> = T extends `${Method} ${infer Path}` ? Path : never;

type APIResponse<T extends keyof APIEndpoints> = APIEndpoints[T]['response'];

async function apiCall<T extends keyof APIEndpoints>(
    endpoint: T,
    ...args: APIEndpoints[T] extends { params: infer P }
        ? [P]
        : APIEndpoints[T] extends { body: infer B }
        ? [B]
        : []
): Promise<APIResponse<T>> {
    // 实现...
    return fetch(endpoint).then(r => r.json());
}

// 使用
const users = await apiCall('GET /users'); // User[]
const user = await apiCall('GET /users/:id', { id: '123' }); // User
```

## 编译性能优化

复杂的类型体操虽然强大，但可能导致编译时间显著增加。以下是一些优化建议：

### 1. 避免深层嵌套

```typescript
// ❌ 编译器需要递归多层
type BadExample<T> = T extends object
    ? { [K in keyof T]: BadExample<T[K]> extends object ? BadExample<BadExample<T[K]>> : T[K] }
    : T;

// ✅ 限制递归深度
type GoodExample<T, Depth extends number = 5> = 
    Depth extends 0
        ? T
        : T extends object
        ? { [K in keyof T]: GoodExample<T[K], Prev<Depth>> }
        : T;

type Prev<N extends number> = [never, 0, 1, 2, 3, 4, 5][N];
```

### 2. 使用接口而非类型别名

```typescript
// ✅ 接口支持声明合并，编译器优化更好
interface User {
    name: string;
    age: number;
}

// ❌ 复杂的类型别名会增加编译负担
type ComplexUser = {
    [K in 'name' | 'age' | 'email']: K extends 'name' ? string : K extends 'age' ? number : string;
};
```

### 3. 延迟类型计算

```typescript
// ✅ 使用接口延迟类型计算
type Lazy<T> = T extends infer U ? { [K in keyof U]: U[K] } : never;

// 只有在实际使用时才展开类型
type ComplexType = Lazy<SomeDeepNesting>;
```

| 优化策略 | 效果 | 适用场景 |
|---------|------|---------|
| 限制递归深度 | 显著减少编译时间 | 递归类型定义 |
| 使用接口 | 更好的类型缓存 | 对象类型定义 |
| 延迟计算 | 按需展开类型 | 复杂工具类型库 |

---

*本文首发于 Yggdrasil 博客*
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
) ON CONFLICT DO NOTHING;
