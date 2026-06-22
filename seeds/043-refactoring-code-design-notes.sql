INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    '重构十年：一个老程序员的代码设计笔记',
    'refactoring-code-design-notes',
    '十年间重构过几十个项目，踩过无数的坑。从单体应用拆到微服务又从微服务拆回来，从 PHP 写到 Go 又写到 Rust。这篇文章不讲大道理，只聊实实在在的代码设计经验和重构心得。',
    $doc$
# 重构十年：一个老程序员的代码设计笔记

2014 年我接手了第一个需要大规模重构的项目。一个电商后台，二十万行 PHP，没有测试，没有文档，连数据库表结构都没有注释。那个项目让我学会了三件事：第一，不要在没有测试的情况下重构；第二，重构的第一步永远是搞清楚代码到底在干什么；第三，大多数坏代码不是人蠢写的，而是被 deadline 逼出来的。

十年过去，重构过的项目大概有几十个。有些成功了，有些搞砸了，还有些重构到一半项目直接黄了。说说我学到的东西。

这篇文章不教你怎么用 IntelliJ 的重构快捷键，也不讨论领域驱动设计的原则该怎么背。只说我在真实项目里踩过的坑和试出来的方法。如果你也在面对一堆烂代码不知道从哪下手，或许有些能帮上忙。

## 什么样的代码需要重构

我见过最糟糕的代码不是面条式代码。面条式代码至少能顺着执行路径读下去。真正的噩梦是那些"看起来还行"的代码——每个方法都不长，命名也还规范，但就是改不动。改一行代码，三个地方出问题。这种事出现三次，你就该认真考虑重构了。

### 过长函数

这个太常见了。一个函数两三百行，缩进七八层。你别说新人，写这段代码的人自己过两周回来也看不懂。

```python
# 这种函数我每个月都能见到
def process_order(order_data):
    # 两百行代码
    # 验证、计算、写库、发邮件、更新库存全在一起
    # try 套 try，if 套 if
    pass
```

拆函数的判断标准不是行数。拆函数的判断标准是：你能不能给这段代码取一个好名字。如果一段代码需要看你读三遍才知道它在干什么，那就抽出去。

### 条件逻辑太复杂

嵌套的 if-else 是代码里最常见的坏味道。我见过最夸张的一个函数，八层 if 嵌套，每层还有两三个 else if。后来发现这段逻辑其实可以拆成策略模式，写完只剩二十行。

```python
# 这种代码看着就头疼
def calculate_price(user, product, coupon, address):
    # 各种 if 嵌套
    # if user.is_vip and coupon and ...
    # else if user.is_new and not coupon and ...
    # else if ...
    pass
```

三层以上的 if 嵌套，就应该停下来想想了。

### 重复代码

复制粘贴是代码退化的第一推动力。改需求的时候改了一个地方忘了另一个地方——这种事我干过太多次了。

#### 重复的类型

最常见的重复分两种：一种是显式的——你看到一模一样的代码块在不同文件里出现。这种还好，抽个函数就完事。

另一种是隐式的——逻辑相似但细节不同。比如两个函数都做校验，一个检查邮箱格式，一个检查手机号格式。表面上看代码不一样，但校验流程是一致的。这种需要抽象出更通用的模式。

#### 什么时候不该消除重复

也有例外。如果两段代码只是恰好长得像，但业务含义完全不同，硬要合并反而坏事。我见过有人把用户注册和商品入库的比较逻辑硬抽到一个函数里，因为"它们都校验长度"。结果后来需求分化，那个函数加了三个参数来控制分支，比原来更乱。

### 类变得太大

一个类五百行、一千行、两千行。到最后没人敢碰。不是不想拆，是不知道从哪下手。

我有个经验：如果这个类的职责需要三个以上的词才能描述清楚，就该拆了。比如"OrderManager"——什么意思？订单管理？具体管什么？创建？更新？退款？物流追踪？五个词都打不住。

```java
// 这种类名就是个危险信号
public class OrderService {
    // 创建订单
    // 更新订单
    // 退款
    // 物流查询
    // 发票管理
    // 优惠券校验
    // 库存扣减
    // ...
}
```

一个类应该只有一个让它可以变化的理由。这是单一职责原则最朴素的表述方式。

### 全局状态与隐式依赖

全局变量、单例模式、静态方法——这些东西用起来很爽，调试起来想死。一个函数读一个全局变量，你永远不知道这个变量在哪个时间点被谁改过。

```python
# 这种代码怎么调试？
def process():
    global config
    if config.debug:
        log("debug mode")
    db = get_db()  # 全局连接
    cache = get_cache()  # 另一个全局连接
```

重构这类代码的关键是把隐式依赖改成显式参数。不要求一步到位，但每次改代码时把能传的参数传进去，而不是从全局拿。三周后你会感谢自己。

### 数据与行为分离

这是最隐蔽的问题。数据在一个地方定义，操作数据的逻辑在另一个地方，中间隔了三层抽象。改一个字段格式，你要找六个文件。

我更倾向于让数据和行为待在一起。不是非要面向对象，用函数式也一样——把相关的类型和操作它们的方法放在同一个模块里。别人找起来方便，改起来也放心。

### 散弹式修改

一个需求改动要改七八个文件。看起来每个改动都很小，但你就是记不全还有哪里没改。这就是散弹式修改（Shotgun Surgery）。

```python
# 要加一个字段，你要改：
# 1. models.py - 加数据库字段
# 2. serializer.py - 加序列化
# 3. validator.py - 加校验
# 4. views.py - 加接口
# 5. template.html - 加展示
# 6. test_*.py - 加测试（如果有的话）
```

如果改一个需求要碰超过三个文件，说明职责没有内聚。解决方案是把相关的变动集中到一起。比如用 ViewModel 或 DTO 把展示和校验逻辑封装起来，而不是散落在各层。

### 基本类型偏执

用字符串表示状态、用整数表示类型、用字典表示一切。基本类型偏执（Primitive Obsession）在 Python 和 Go 项目里特别常见。

```python
# 到处都是魔法值
status = "paid"  # 还是 "completed"？"finished"？
order_type = 2   # 2 是什么类型？为什么不是 3？

# 好一点的做法
class OrderStatus:
    PAID = "paid"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class OrderType(Enum):
    NORMAL = 1
    PREMIUM = 2
    SUBSCRIPTION = 3
```

不用到处建类，但至少把经常一起出现的值定义成常量或枚举。三个月后回头看代码，你会感谢现在的自己。

## 重构的节奏

重构这事最大的误区是一口气做完。尤其是大重构。

### 先搞清现状

第一次重构电商项目的时候，我花了整整两周什么都没改，就是在读代码。把每一个分支、每一种状态转换、每一处数据流向都画出来。不是所有代码都有文档，但你可以自己画。

当时我用了思维导图来整理调用关系。从 HTTP 入口开始，一层层追踪下去，直到数据库。画完发现有一半的代码其实根本没人调用——死代码。删掉它们，代码量直接从二十万降到十几万。

### 写测试

没有测试的重构叫瞎改。这个道理我付出了惨痛代价才学会。

先写测试不是为了验证功能正确，而是为了让你在重构后有信心说"我没改坏东西"。写多少测试够？

- 核心业务逻辑必须覆盖
- 边界条件写几个
- 出过 bug 的地方重点写

不是一定要 100% 覆盖，但你改了哪部分，至少那部分要有测试。

#### 测试的策略

我试过各种测试方法。单元测试是最容易写的，但换了语言或框架后价值大打折扣。集成测试和端到端测试更容易发现真正的破坏，但跑一次要十几分钟。

现在的做法是：业务核心逻辑用单元测试重点覆盖，流程类的东西交给集成测试。不追求比例，追求效果。如果每次发版都需要手工回归两小时，说明测试覆盖不行。

```go
// 有价值的测试长这样
func TestPaymentRefund_RefundExceedsAmount(t *testing.T) {
    tx := createTestTransaction(t, 100.00)
    err := refund(tx, 200.00)
    assert.Error(t, err)
    assert.Equal(t, "refund amount exceeds original", err.Error())
}
```

### 小步前进

重构的大忌是一次改太多。每次重构只改一件事。拆一个函数，提取一个类，改一个变量名。改完跑测试。绿了再下一步。

这个方法看起来慢，实际最快。因为出了问题你马上知道是哪一步导致的。我见过最惨的一次，同事一口气改了一整个模块，花了三天，结果测试全红，回退都不知道回退到哪一步。

## 一个重构实战案例

说个具体的例子。去年我接手了一个订单导出功能，需求很简单——把订单数据导出成 CSV。原来的代码大概两百行，一个函数搞定。但它的问题是：每次加一个新字段都要改这个函数，加一个过滤条件也要改。改了十几次后，没有人敢碰了。

### 原来的代码

```python
def export_orders(params):
    # 两百行
    # 1. 查数据库
    # 2. 组装数据
    # 3. 格式化 CSV
    # 4. 写文件
    # 全部混在一起
```

### 第一步：拆流程

我把流程拆成三步：查询、转换、输出。每步一个函数，参数显式传递。

```python
def export_orders(params):
    orders = query_orders(params)
    rows = transform_orders(orders)
    write_csv(rows, params.get('filename', 'export.csv'))
```

### 第二步：用策略替换条件判断

原来的代码里，字段映射用了一个巨大的 if-else。我把它改成了字典查找。

```python
FIELD_MAP = {
    'order_id': lambda o: o.id,
    'customer_name': lambda o: o.user.name,
    'amount': lambda o: f"{o.total:.2f}",
    'status': lambda o: STATUS_LABEL.get(o.status, 'unknown'),
    'created_at': lambda o: o.created_at.strftime('%Y-%m-%d %H:%M'),
}

def transform_orders(orders):
    return [
        [field_fn(order) for field_fn in FIELD_MAP.values()]
        for order in orders
    ]
```

### 第三步：添加扩展点

现在要加字段只需向 FIELD_MAP 加一项。要加过滤条件只需改 query_orders 的参数。谁都不需要碰 export_orders 本身。后来产品加了六个新字段，每次改动不超过两行代码。

这个案例没什么高深的设计模式，就是三个简单的原则：单一职责、依赖注入、策略模式。但比任何理论都管用。

## 几种常用的重构手法

重构不是乱改。有套路可循。说说我最常用的几种。

### 提取方法（Extract Method）

看到一段代码能用一个名字概括，就把它抽成函数。这是最基础也是最有用的重构手法。

```python
# 重构前
def send_invoice(user, orders):
    total = sum(o.amount for o in orders)
    tax = total * 0.08
    discount = 0
    if user.is_vip:
        discount = total * 0.1
    if user.coupon:
        discount = max(discount, user.coupon.value)
    final = total + tax - discount
    body = f"总计：{total}，税费：{tax}，折扣：{discount}，应付：{final}"
    email.send(user.email, "账单", body)

# 重构后
def send_invoice(user, orders):
    total = sum(o.amount for o in orders)
    tax = calc_tax(total)
    discount = calc_discount(user, total)
    final = total + tax - discount
    body = format_invoice_body(total, tax, discount, final)
    email.send(user.email, "账单", body)
```

提取的粒度不是越细越好。如果你发现一个函数内部调用了十几个小函数，每个函数只有两三行，那就是拆过头了。

### 以多态取代条件（Replace Conditional with Polymorphism）

当你有大量 if-else 判断类型，然后做不同操作时，可以考虑用多态。

```python
# 重构前
def calculate_shipping(order, method):
    if method == "standard":
        return order.weight * 1.5 + 5
    elif method == "express":
        return order.weight * 3 + 10
    elif method == "overnight":
        return order.weight * 5 + 20
    elif method == "pickup":
        return 0

# 重构后
class StandardShipping:
    def calculate(self, order):
        return order.weight * 1.5 + 5

class ExpressShipping:
    def calculate(self, order):
        return order.weight * 3 + 10

class OvernightShipping:
    def calculate(self, order):
        return order.weight * 5 + 20

STRATEGIES = {
    "standard": StandardShipping(),
    "express": ExpressShipping(),
    "overnight": OvernightShipping(),
    "pickup": lambda o: 0,
}

def calculate_shipping(order, method):
    return STRATEGIES[method].calculate(order)
```

注意，不是所有条件判断都要改成多态。如果只有两三个分支且不太可能新增，if-else 就够了。

### 搬移字段（Move Field）

一个字段大部分时间都在另一个类中使用，那就把它搬过去。

这个手法简单，但做对的人不多。我见过一个 User 类里存了十几个业务字段——其中一半只有 Order 模块在用，另一半只有 Payment 模块在用。但没人敢动，因为怕出事。

判断标准很简单：如果这个字段在 getter/setter 之外的调用都来自另一个类，就该搬了。

### 拆分循环（Split Loop）

一个循环里干三件事。看起来高效，但改起来痛苦。

```python
# 重构前
for order in orders:
    total += order.amount
    if order.status == "overdue":
        overdue_count += 1
    if order.is_vip:
        vip_orders.append(order)
        vip_total += order.amount

# 重构后
total = sum(o.amount for o in orders)
overdue_count = sum(1 for o in orders if o.status == "overdue")
vip_orders = [o for o in orders if o.is_vip]
vip_total = sum(o.amount for o in vip_orders)
```

性能差别可以忽略不计，但可读性提升很明显。除非你的循环在热点路径上且每秒调用上万次，否则优先考虑可读性。

## 设计原则：简单比完美重要

聊设计原则很容易变得很虚。我自己也经历过那个阶段——学了一堆设计模式，到处用，结果把代码搞得更复杂了。

### 分层要松但不能多

好的设计是分层的，但三层就够了。再多一层，每层就只是在透传。我见过六层架构的项目，改一个字段要改六个文件。没人记得住这些层的边界，最后所有人都直接跳过中间层。

```java
// 透传是分层最无聊的表现
public class OrderController {
    private OrderService service;
    public OrderDTO get(Long id) {
        return service.get(id);  // 一行代码，毫无价值
    }
}
```

接口是为调用方设计的，不是为你自己设计的。写接口之前先想清楚谁会调用它，他们需要什么。不是所有方法都需要接口，也不是所有实现都需要替换。

### 异常处理：什么时候吞，什么时候抛

异常处理可能是代码里水最深的地方。我见过两种极端：

```python
# 极端一：吞掉所有异常
try:
    process()
except Exception:
    pass

# 极端二：到处抛异常
def get_user(id):
    if id is None:
        raise ValidationError("id is required")
    if id <= 0:
        raise ValidationError("id must be positive")
    user = db.query(User).filter_by(id=id).first()
    if user is None:
        raise NotFoundError("user not found")
    return user
```

第一种让你在线上出了 bug 完全不知道。第二种让调用方苦不堪言——调一个函数要 catch 四个异常。

我的做法：只在你能真正恢复的地方处理异常。不能恢复的就让它往上抛。中间层根本不应该知道异常的存在。

## 这些年踩过的坑

### 过度设计

有一阵我痴迷于设计模式。一个简单的配置读取功能，我用了工厂模式加策略模式加单例模式。写的时候感觉自己在写框架。半年后自己回来看，根本看不懂。最后全部删掉，换成三十行 if-else。

设计模式是用来解决特定问题的，不是用来展示你读过《设计模式》这本书的。

```python
# 被过度设计的配置读取
class ConfigFactory:
    @staticmethod
    def create(source_type):
        if source_type == 'file':
            return FileConfigReader()
        elif source_type == 'env':
            return EnvConfigReader()
        elif ...

# 三行代码就能解决的问题
config = {}
if os.path.exists('config.yaml'):
    config.update(parse_yaml('config.yaml'))
config.update(os.environ)
```

### 过早优化

"这段代码以后可能慢"——先别管。等它真的慢了你再去优化。很多"优化"实际上是变得更复杂、更难维护，但实际性能提升微乎其微。

```python
# "优化"前：15行，好读
def get_active_users():
    users = db.query(User).all()
    result = []
    for user in users:
        if user.is_active and user.last_login:
            result.append(user)
    return result

# "优化"后：单行，性能一样，没人读得懂
def get_active_users():
    return [u for u in db.query(User).all() if u.is_active and u.last_login and ...]
```

### 重构到一半项目没了

这种事我经历过两次。第一次重构一个支付模块，刚拆了一半，公司战略调整，整个项目组被调到新业务线。重构的代码没人接着做，变成了一堆半成品留在代码库里。后来的同事接手的时候，看着一半重构一半没改的代码，比不改还难受。

从那以后，我学会了两个道理。第一，大重构必须有业务上的 urgency，不然优先级永远排不过新需求。第二，如果重构的时间跨度超过一个月，中间一定要有可交付的阶段性成果。哪怕就是说"这个模块现在可维护性提高了"，也比三个月后交付一个完整的代码库靠谱。

### 不兼容的改动

还有一次，重构的时候改了数据库字段类型，以为所有调用方都排查过了。结果有个定时任务跑了两年没人维护，直接挂了。第二天早上被电话吵醒，老板问为什么报表没出来。

那次之后，我对不兼容改动多了一个步骤：先废弃（deprecate），再删除。给调用方留出迁移的时间窗口。哪怕调用方就在同一个代码库里。

```python
# 先废弃旧接口
def get_user_name(user_id):
    warnings.warn("use get_user_display_name instead", DeprecationWarning)
    return get_user_display_name(user_id)

# 等所有人都切过去了再删
```

这个习惯让我少挨了很多骂。

## 处理遗留系统的经验

你可能要问：你说的这些道理我都懂，但面对一个几百万行的遗留系统，从哪里下手？

我处理过最老的一个项目是 2008 年上线的，用的框架连官方都不维护了。我的做法是：

### 建立防护层

不要一开始就想着重写。先在外围加测试，把核心接口的契约固定下来。这叫"扼杀者模式"（Strangler Fig Pattern）。新的功能用新代码写，老的功能逐步替换。

```python
# 在旧系统外面包一层
class LegacyOrderAPI:
    def get_order(self, order_id):
        # 旧实现，不碰它
        return legacy_call(order_id)

class NewOrderAPI:
    def get_order(self, order_id):
        # 新实现，逐步替换
        return new_call(order_id)

# 通过开关控制流量
if feature_flag.enabled('new_order_api'):
    return NewOrderAPI().get_order(order_id)
else:
    return LegacyOrderAPI().get_order(order_id)
```

### 识别核心路径

大部分系统中，真正关键的代码只占一小部分。支付、登录、权限校验——这些是核心路径。核心路径需要最高质量。其他的？日志、报表、后台管理页面——可以容忍暂时的混乱。

先把核心路径理清楚，剩下的慢慢来。

### 做好回滚准备

任何重构都要有回滚方案。加一个功能开关（feature flag），出问题能立刻切回旧实现。没有开关的重构就像没有安全绳的攀岩——看着刺激，摔了也疼。

开关不止一种。简单的 if-else 开关适合短期切换。用了就删，别留着。对于更复杂的场景，可以用流量灰度——先切 1% 的流量到新实现，观察几天没问题再逐步放开。

```python
# 功能开关示例
if settings.USE_NEW_PAYMENT_FLOW:
    process_payment_v2(order)
else:
    process_payment_v1(order)

# 灰度发布
if random.random() < settings.NEW_PAYMENT_TRAFFIC_RATIO:
    process_payment_v2(order)
else:
    process_payment_v1(order)
```

### 不要重写，要替换

重写（rewrite）和替换（replace）是两回事。重写是把整个系统从头做一遍，替换是一次只换一块。

我见过三个重写项目，全部失败了。原因都一样：重写花了太长时间，业务已经变了。等新系统上线时，它解决的是两年前的问题。

替换的策略是：每次重构一个模块或一个功能，改完就上线。不影响其他部分。这样每两周都有产出，项目经理看得到进度，团队也有成就感。

## 重构与文化

重构不只是技术问题。很多时候是组织问题。你的经理不会因为代码整洁给你升职，但会因为按时上线给你绩效。这个矛盾无解，但有一些技巧可以缓解。

### 给重构找业务理由

"这个模块太乱了需要重构"——听起来就像程序员在偷懒。换种说法："这个模块改一个需求需要三天，重构后一天搞定，而且 bug 会更少。"

项目经理关心的是时间和质量，不是代码好不好看。

```python
# 用数据说话
# 重构前：改一个支付流程平均需要 3 天，线上故障率 2%
# 重构后：改一个支付流程需要 1 天，线上故障率 0.3%
```

### 用小步而不是大跃进

大重构往往死在中途。不是技术原因，是组织原因。项目排期变了，产品方向变了，核心成员走了——原因太多了。小重构不可能失败，因为每一步的投入都很小。

### 每次改代码都比之前好一点

这可能是最重要的一条。不用专门安排重构的时间。改 bug 的时候顺便把那个混乱的方法拆一下，加需求的时候顺手把附近的变量名改得更清晰。日积月累，代码自然就好了。

```python
# 改 bug 之前
def save(data):
    # 五十行，没人看得懂
    pass

# 改完 bug 顺便重构
def save(data):
    validated = validate(data)
    transformed = transform(validated)
    persisted = persist(transformed)
    notify(persisted)
    return persisted
```

## 说到最后

写了十年代码，我最大的体会是：好的代码不是一次写出来的，是不断改出来的。那个四年没动过的项目不会自己变好，也不会自己变坏。代码和代码之间唯一的区别是有没有人在乎它的质量。

重构不是件浪漫的事。它很琐碎，很多时候看不到直接的回报。但回头看看十年前写的那些代码——还在跑的剩下的不多了，但留下的那些，都是我花时间认真改过的。

有一个事实我至今仍觉得有趣：我做过的项目里，那些代码质量最高的，催得最紧。那些"慢慢来，做精细一点"的项目，反而代码最烂。代码质量和时间没有直接关系，和有经验的工程师有没有决策权有关系。你不给好工程师改代码的权力，给再多时间也写不出好东西。

如果你刚入行，不知道怎么开始，建议从一个小模块开始。花一个下午读通它，把变量名改清楚，把长函数拆短，把注释改成代码。做完这些，你就知道自己在干什么了。然后用同样的方法做下一个。一年后再回头看，你会发现自己已经不认识那些代码了——而这是件好事。

重构没有终点。代码写完了才叫遗产，写的时候是活的东西。

还有，对代码别太较真。它只是工具，不是艺术品。值得重构的代码就认真改，不值得的就扔了。说到底，代码的好坏衡量标准只有一个——它能不能帮人解决问题。如果明天业务不需要了，删得越干净越好。

有个事我一直想说：很多人把重构想得太重了。他们觉得重构就是要重新设计架构、重写所有代码、用最酷的新框架。但实际最有效的重构恰恰是那些小事。今天我改个变量名，明天我拆个长函数，后天我删一百行死代码。这些事情单看很小，但做满一年，你的代码库会完全不一样。

最后推荐几本书。Martin Fowler 的《重构：改善既有代码的设计》是必读的，虽然例子是 Java，但思想通用。《Working Effectively with Legacy Code》教你如何对付老系统，非常实用。还有《代码整洁之道》，这本书有些人觉得太教条，但它说的"童子军规则"——每次离开时让营地比来的时候更干净——是重构最好的行动指南。

如果你只记住一件事，我希望是这句：好的代码不是设计出来的，是改出来的。
$doc$,
    NULL,
    '/images/covers/refactoring-code-design-notes.jpg',
    '<ul>
<li><a href="#什么样的代码需要重构">什么样的代码需要重构</a></li>
<ul>
<li><a href="#过长函数">过长函数</a></li>
<li><a href="#条件逻辑太复杂">条件逻辑太复杂</a></li>
<li><a href="#重复代码">重复代码</a></li>
<ul>
<li><a href="#重复的类型">重复的类型</a></li>
<li><a href="#什么时候不该消除重复">什么时候不该消除重复</a></li>
</ul>
<li><a href="#类变得太大">类变得太大</a></li>
<li><a href="#全局状态与隐式依赖">全局状态与隐式依赖</a></li>
<li><a href="#数据与行为分离">数据与行为分离</a></li>
<li><a href="#散弹式修改">散弹式修改</a></li>
<li><a href="#基本类型偏执">基本类型偏执</a></li>
</ul>
<li><a href="#重构的节奏">重构的节奏</a></li>
<ul>
<li><a href="#先搞清现状">先搞清现状</a></li>
<li><a href="#写测试">写测试</a></li>
<ul>
<li><a href="#测试的策略">测试的策略</a></li>
</ul>
<li><a href="#小步前进">小步前进</a></li>
</ul>
<li><a href="#一个重构实战案例">一个重构实战案例</a></li>
<ul>
<li><a href="#原来的代码">原来的代码</a></li>
<li><a href="#第一步-拆流程">第一步：拆流程</a></li>
<li><a href="#第二步-用策略替换条件判断">第二步：用策略替换条件判断</a></li>
<li><a href="#第三步-添加扩展点">第三步：添加扩展点</a></li>
</ul>
<li><a href="#几种常用的重构手法">几种常用的重构手法</a></li>
<ul>
<li><a href="#提取方法-extract-method">提取方法（Extract Method）</a></li>
<li><a href="#以多态取代条件-replace-conditional-with-polymorphism">以多态取代条件（Replace Conditional with Polymorphism）</a></li>
<li><a href="#搬移字段-move-field">搬移字段（Move Field）</a></li>
<li><a href="#拆分循环-split-loop">拆分循环（Split Loop）</a></li>
</ul>
<li><a href="#设计原则-简单比完美重要">设计原则：简单比完美重要</a></li>
<ul>
<li><a href="#分层要松但不能多">分层要松但不能多</a></li>
<li><a href="#异常处理-什么时候吞-什么时候抛">异常处理：什么时候吞，什么时候抛</a></li>
</ul>
<li><a href="#这些年踩过的坑">这些年踩过的坑</a></li>
<ul>
<li><a href="#过度设计">过度设计</a></li>
<li><a href="#过早优化">过早优化</a></li>
<li><a href="#重构到一半项目没了">重构到一半项目没了</a></li>
<li><a href="#不兼容的改动">不兼容的改动</a></li>
</ul>
<li><a href="#处理遗留系统的经验">处理遗留系统的经验</a></li>
<ul>
<li><a href="#建立防护层">建立防护层</a></li>
<li><a href="#识别核心路径">识别核心路径</a></li>
<li><a href="#做好回滚准备">做好回滚准备</a></li>
<li><a href="#不要重写-要替换">不要重写，要替换</a></li>
</ul>
<li><a href="#重构与文化">重构与文化</a></li>
<ul>
<li><a href="#给重构找业务理由">给重构找业务理由</a></li>
<li><a href="#用小步而不是大跃进">用小步而不是大跃进</a></li>
<li><a href="#每次改代码都比之前好一点">每次改代码都比之前好一点</a></li>
</ul>
<li><a href="#说到最后">说到最后</a></li>
</ul>',
    1494,
    8,
    'published',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour'
) ON CONFLICT DO NOTHING;
