INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Elixir 并发与容错',
    'elixir-concurrency',
    '深入探索 Elixir 的并发模型和容错机制，从 OTP 进程到 Supervisor 监督树，理解 Actor 模型和 Let it crash 哲学，构建高可用的分布式系统。',
    $doc$
# Elixir 并发与容错：构建高可用系统

Elixir 构建在 Erlang VM（BEAM）之上，继承了 Erlang 强大的并发和容错能力。本文将深入探讨 Elixir 的并发模型、进程隔离、Supervisor 监督机制以及分布式系统的构建方法。

## 为什么选择 Elixir？

Elixir 不是另一种 Web 框架，而是一种全新的编程范式。它基于 **Actor 模型**，提供了轻量级进程和消息传递机制，让并发编程变得简单而安全。

> WhatsApp 使用 Erlang/OTP 处理每天超过 650 亿条消息，每台服务器维护超过 200 万个并发连接。这就是 BEAM 虚拟机的实力。

## Elixir 进程模型

### 轻量级进程

在 Elixir 中，"进程"不是操作系统进程，而是由 BEAM 虚拟机管理的轻量级执行单元：

```elixir
# 创建一个新进程
pid = spawn(fn ->
  IO.puts("Hello from a new process!")
  IO.puts("Process PID: #{inspect(self())}")
end)

IO.puts("Main process PID: #{inspect(self())}")
IO.puts("Spawned process PID: #{inspect(pid)}")
```

特点对比：

| 特性 | OS 进程 | Elixir 进程 |
|------|---------|-------------|
| 内存占用 | MB 级别 | ~300 字节 |
| 创建时间 | 毫秒级 | 微秒级 |
| 最大数量 | 数千 | 数百万 |
| 通信方式 | 共享内存 | 消息传递 |
| 调度 | 抢占式 | 协作式 |

### 进程隔离

每个 Elixir 进程都有自己独立的内存空间，进程之间不共享状态：

```elixir
defmodule Counter do
  def start(initial_value \\ 0) do
    spawn(fn -> loop(initial_value) end)
  end

  defp loop(current_value) do
    receive do
      {:get, caller} ->
        send(caller, {:value, current_value})
        loop(current_value)

      {:increment} ->
        loop(current_value + 1)

      {:decrement} ->
        loop(current_value - 1)

      {:add, amount} ->
        loop(current_value + amount)
    end
  end
end

# 使用示例
counter = Counter.start(10)

send(counter, {:increment})
send(counter, {:add, 5})
send(counter, {:get, self()})

receive do
  {:value, value} -> IO.puts("Current value: #{value}")
after
  1000 -> IO.puts("Timeout!")
end
```

## 消息传递机制

### 异步消息

Elixir 进程通过异步消息传递进行通信：

```elixir
defmodule Messenger do
  def send_message(to_pid, message) do
    send(to_pid, {self(), message})
  end

  def wait_for_reply(timeout \\\\ 5000) do
    receive do
      {_from, reply} -> {:ok, reply}
    after
      timeout -> {:error, :timeout}
    end
  end
end

# 创建接收进程
receiver = spawn(fn ->
  receive do
    {from, msg} ->
      IO.puts("Received: #{msg}")
      send(from, {self(), "Reply: #{msg}"})
  end
end)

Messenger.send_message(receiver, "Hello Elixir!")
case Messenger.wait_for_reply() do
  {:ok, reply} -> IO.puts("Got reply: #{reply}")
  {:error, reason} -> IO.puts("Failed: #{reason}")
end
```

### 消息邮箱

每个进程都有一个消息邮箱，消息按到达顺序排队：

```elixir
defmodule MessageProcessor do
  def process_messages do
    receive do
      message ->
        IO.puts("Processing: #{inspect(message)}")
        process_messages()
    end
  end
end

processor = spawn(&MessageProcessor.process_messages/0)

send(processor, :first)
send(processor, :second)
send(processor, {:complex, [1, 2, 3]})
```

## GenServer：状态机模式

GenServer 是 OTP 行为（Behaviour）之一，提供了一种标准化的方式来构建有状态的服务器进程：

```elixir
defmodule KeyValueStore do
  use GenServer

  # 客户端 API
  def start_link(initial_state \\\\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  # 服务器回调
  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end
end

# 使用示例
{:ok, _pid} = KeyValueStore.start_link()
KeyValueStore.put(:name, "Elixir")
KeyValueStore.put(:version, "1.15")
IO.inspect(KeyValueStore.get(:name))
```

### GenServer 回调详解

| 回调函数 | 用途 | 返回值 |
|----------|------|--------|
| `init/1` | 初始化状态 | `{:ok, state}` |
| `handle_call/3` | 同步请求 | `{:reply, reply, state}` |
| `handle_cast/2` | 异步请求 | `{:noreply, state}` |
| `handle_info/2` | 处理普通消息 | `{:noreply, state}` |
| `terminate/2` | 清理资源 | 任意 |

## Supervisor 监督策略

### 容错哲学：Let it crash

Elixir 的核心哲学是 **Let it crash**。进程崩溃不应该影响整个系统，Supervisor 会负责重启失败的进程。

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # 工作进程
      {KeyValueStore, %{}},
      # 另一个工作进程
      {MyApp.Worker, []},
      # 动态监督者
      {DynamicSupervisor, strategy: :one_for_one, name: MyApp.DynamicSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
```

### 监督策略对比

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| `:one_for_one` | 只重启失败的子进程 | 独立的服务 |
| `:one_for_all` | 重启所有子进程 | 相互依赖的服务 |
| `:rest_for_one` | 重启失败进程及其后续进程 | 有启动顺序依赖 |
| `:simple_one_for_one` | 动态添加子进程 | 需要动态创建进程 |

### 重启策略

```elixir
defmodule MyApp.Worker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    # 如果初始化失败，Supervisor 会根据重启策略处理
    case connect_to_database(args) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> {:stop, reason}
    end
  end

  defp connect_to_database(_args) do
    # 模拟数据库连接
    {:ok, %{} }
  end
end
```

## 容错机制实践

### 链接进程（Linking）

进程可以相互链接，一个进程崩溃会导致链接的进程也崩溃：

```elixir
defmodule LinkExample do
  def run do
    parent = self()

    child = spawn_link(fn ->
      receive do
        :crash -> raise "Simulated error"
        :normal -> IO.puts("Normal exit")
      end
    end)

    Process.flag(:trap_exit, true)

    send(child, :crash)

    receive do
      {:EXIT, ^child, reason} ->
        IO.puts("Child exited with reason: #{inspect(reason)}")
    end
  end
end
```

### 监控进程（Monitoring）

监控是单向的，被监控进程崩溃不会导致监控进程崩溃：

```elixir
defmodule MonitorExample do
  def run do
    target = spawn(fn ->
      Process.sleep(1000)
      exit(:normal)
    end)

    ref = Process.monitor(target)

    receive do
      {:DOWN, ^ref, :process, ^target, reason} ->
        IO.puts("Process down: #{inspect(reason)}")
    end
  end
end
```

### 选择策略

| 特性 | Link | Monitor |
|------|------|---------|
| 方向 | 双向 | 单向 |
| 影响 | 相互影响 | 仅通知 |
| 用途 | 构建 Supervision Tree | 观察进程状态 |
| 退出传播 | 是 | 否 |

## 分布式 Elixir

### 节点间通信

Elixir 进程可以在不同机器间透明通信：

```elixir
# 启动节点 1（机器 A）
# iex --sname node1@machine_a --cookie secret

# 启动节点 2（机器 B）
# iex --sname node2@machine_b --cookie secret

# 在 node2 上连接到 node1
Node.connect(:"node1@machine_a")

# 在 node2 上向 node1 发送消息
send({:some_process, :"node1@machine_a"}, :hello_from_node2)

# 在 node1 上接收
receive do
  msg -> IO.puts("Received: #{inspect(msg)}")
end
```

### 分布式任务

```elixir
defmodule DistributedTask do
  def run_on_all_nodes(task) do
    nodes = [Node.self() | Node.list()]

    Enum.map(nodes, fn node ->
      Task.Supervisor.async_nolink({MyApp.TaskSupervisor, node}, fn ->
        result = task.()
        {node, result}
      end)
    end)
    |> Enum.map(&Task.await/1)
  end
end

# 在所有节点上执行计算
results = DistributedTask.run_on_all_nodes(fn ->
  # 计算密集型任务
  Enum.sum(1..1_000_000)
end)

IO.inspect(results)
```

## 实际应用：构建容错计数器

```elixir
defmodule FaultTolerantCounter do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def increment do
    GenServer.cast(__MODULE__, :increment)
  end

  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  @impl true
  def init(state) do
    # 设置陷阱退出，处理链接进程的错误
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    IO.puts("Linked process exited: #{inspect(reason)}")
    {:noreply, state}
  end
end

# Supervisor 配置
defmodule CounterSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {FaultTolerantCounter, []}
    ]

    # 使用 transient 重启策略，只在异常退出时重启
    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 10
    )
  end
end
```

## OTP Application 与系统启动

完整的 Elixir/Erlang 系统通常以 OTP Application 的形式组织，它定义了应用的启动顺序、依赖关系和生命周期。

### Application 行为

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # 启动 ETS 表
      {MyApp.Cache, []},
      # 启动 GenServer
      {MyApp.ConfigStore, %{}},
      # 启动 Supervisor
      MyApp.Supervisor,
      # 启动动态监督者
      {DynamicSupervisor, strategy: :one_for_one, name: MyApp.TaskSupervisor}
    ]

    # 使用 one_for_one 监督策略
    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.TopSupervisor)
  end
end
```

### 启动阶段与依赖

| 启动阶段 | 说明 | 常用操作 |
|----------|------|----------|
| `compile` | 编译代码和依赖 | N/A |
| `load` | 加载 application 资源文件 | 读取 `.app` 文件 |
| `start` | 调用 `Application.start/2` | 启动监督树 |
| `临时应用` | 不强制要求 | 可选依赖 |
| `永久应用` | 崩溃时整个节点停止 | 核心依赖 |

```elixir
# mix.exs 中配置 application
def application do
  [
    mod: {MyApp.Application, []},
    extra_applications: [:logger, :runtime_tools]
  ]
end

# 启动应用
Application.ensure_all_started(:my_app)
```

## ETS 与并发数据共享

虽然 Elixir 强调"不共享状态"，但 ETS（Erlang Term Storage）提供了一种进程间高效共享数据的机制。

### ETS 表类型与用例

```elixir
defmodule MyApp.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    # 创建 public ETS 表，允许任何进程读写
    :ets.new(__MODULE__, [
      :set,         # 表类型：set（唯一键）
      :public,      # 访问权限
      :named_table, # 使用模块名作为表名
      read_concurrency: true,
      write_concurrency: true
    ])
    {:ok, nil}
  end

  def put(key, value) do
    :ets.insert(__MODULE__, {key, value})
  end

  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end
end
```

| ETS 表类型 | 特点 | 时间复杂度 | 适用场景 |
|-----------|------|-----------|----------|
| `:set` | 键唯一，无序 | O(1) | 键值缓存 |
| `:ordered_set` | 键唯一，有序 | O(log N) | 范围查询 |
| `:bag` | 键可重复，值唯一 | O(1) | 多值索引 |
| `:duplicate_bag` | 键和值都可重复 | O(1) | 日志存储 |

### ETS 安全模型

```elixir
# ETS 表归创建它的进程所有
# 所有者进程终止时，ETS 表会被销毁
# 可以通过将 ETS 所有者设为 Supervisor 下的 GenServer 来保证持久性

# 使用 :ets.give_away/3 转移表所有权
defmodule ETSOwner do
  use GenServer

  def init(_) do
    table = :ets.new(:my_table, [:set, :public])
    {:ok, table}
  end

  # 监控使用 ETS 的进程
  def monitor_user(pid) do
    Process.monitor(pid)
  end
end
```

## 并发测试与 ExUnit

Elixir 提供了强大的测试工具 ExUnit，特别适合测试并发代码。

### 异步测试

```elixir
defmodule MyApp.CacheTest do
  use ExUnit.Case, async: true

  setup do
    # 每个异步测试都有独立的进程
    {:ok, _pid} = MyApp.Cache.start_link([])
    :ok
  end

  test "stores and retrieves values" do
    MyApp.Cache.put(:user_1, %{name: "Alice"})
    assert {:ok, %{name: "Alice"}} == MyApp.Cache.get(:user_1)
  end

  test "returns error for missing keys" do
    assert :error == MyApp.Cache.get(:missing)
  end
end
```

### 测试并发行为

```elixir
defmodule CounterLoadTest do
  use ExUnit.Case

  test "concurrent increments are atomic" do
    {:ok, pid} = AtomicCounter.start_link(0)

    tasks = for _ <- 1..100 do
      Task.async(fn ->
        for _ <- 1..1000 do
          AtomicCounter.increment(pid)
        end
      end)
    end

    Enum.each(tasks, &Task.await/1)
    assert AtomicCounter.get(pid) == 100_000
  end

  test "process exit is detected" do
    pid = spawn(fn -> Process.exit(self(), :kill) end)
    ref = Process.monitor(pid)

    assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1000
  end
end
```

### ExUnit 特性一览

| 特性 | 语法 | 说明 |
|------|------|------|
| 异步测试 | `async: true` | 测试并行运行 |
| 临时捕获 | `capture_log` | 捕获日志输出 |
| 超时控制 | `@tag timeout: 5000` | 自定义测试超时 |
| 跳过测试 | `@tag :skip` | 跳过某些测试 |
| 测试分组 | `describe "group" do` | 逻辑分组 |
| 共享 setup | `setup_all` | 每个测试模块只执行一次 |

## 总结

Elixir 的并发和容错能力源于其独特的设计哲学：

1. **隔离性**：进程完全隔离，一个崩溃不影响其他
2. **监督**：Supervisor 自动重启失败进程
3. **消息传递**：避免共享状态带来的复杂性
4. **热升级**：不停机更新运行中的系统
5. **分布式透明**：跨节点通信与本地通信 API 一致
6. **OTP 框架**：Application、GenServer、Supervisor 提供标准化架构
7. **ETS**：在必要时提供高效并发数据共享
8. **测试友好**：ExUnit 原生支持并发测试

> "Let it crash" 不是忽视错误，而是设计系统时的基本假设 —— 组件会失败，但系统必须继续运行。

通过掌握这些概念，你可以构建出真正高可用、容错的分布式系统，充分利用多核 CPU 和集群环境。
$doc$,
    NULL,
    NULL,
    '<ul>
<li><a href="#为什么选择-elixir">为什么选择 Elixir？</a></li>
<li><a href="#elixir-进程模型">Elixir 进程模型</a></li>
<ul>
<li><a href="#轻量级进程">轻量级进程</a></li>
<li><a href="#进程隔离">进程隔离</a></li>
</ul>
<li><a href="#消息传递机制">消息传递机制</a></li>
<ul>
<li><a href="#异步消息">异步消息</a></li>
<li><a href="#消息邮箱">消息邮箱</a></li>
</ul>
<li><a href="#genserver-状态机模式">GenServer：状态机模式</a></li>
<ul>
<li><a href="#genserver-回调详解">GenServer 回调详解</a></li>
</ul>
<li><a href="#supervisor-监督策略">Supervisor 监督策略</a></li>
<ul>
<li><a href="#容错哲学-let-it-crash">容错哲学：Let it crash</a></li>
<li><a href="#监督策略对比">监督策略对比</a></li>
<li><a href="#重启策略">重启策略</a></li>
</ul>
<li><a href="#容错机制实践">容错机制实践</a></li>
<ul>
<li><a href="#链接进程-linking">链接进程（Linking）</a></li>
<li><a href="#监控进程-monitoring">监控进程（Monitoring）</a></li>
<li><a href="#选择策略">选择策略</a></li>
</ul>
<li><a href="#分布式-elixir">分布式 Elixir</a></li>
<ul>
<li><a href="#节点间通信">节点间通信</a></li>
<li><a href="#分布式任务">分布式任务</a></li>
</ul>
<li><a href="#实际应用-构建容错计数器">实际应用：构建容错计数器</a></li>
<li><a href="#otp-application-与系统启动">OTP Application 与系统启动</a></li>
<ul>
<li><a href="#application-行为">Application 行为</a></li>
<li><a href="#启动阶段与依赖">启动阶段与依赖</a></li>
</ul>
<li><a href="#ets-与并发数据共享">ETS 与并发数据共享</a></li>
<ul>
<li><a href="#ets-表类型与用例">ETS 表类型与用例</a></li>
<li><a href="#ets-安全模型">ETS 安全模型</a></li>
</ul>
<li><a href="#并发测试与-exunit">并发测试与 ExUnit</a></li>
<ul>
<li><a href="#异步测试">异步测试</a></li>
<li><a href="#测试并发行为">测试并发行为</a></li>
<li><a href="#exunit-特性一览">ExUnit 特性一览</a></li>
</ul>
<li><a href="#总结">总结</a></li>
</ul>',
    1505,
    8,
    'published',
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes'
) ON CONFLICT DO NOTHING;
