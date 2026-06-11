INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'gRPC 与 Protocol Buffers 微服务通信实战',
    'grpc-microservices-guide',
    '从 proto 文件定义到流式 RPC，从负载均衡到拦截器，覆盖 gRPC 在微服务架构中的完整应用实践。',
    $doc$
# gRPC 与 Protocol Buffers 微服务通信实战

## 前言

REST API 在微服务通信中有几个痛点：JSON 序列化体积大、传输效率低、没有严格的接口契约、不支持流式通信。gRPC 解决了这些问题——它用 Protocol Buffers 做序列化（体积小、速度快），HTTP/2 做传输（多路复用、头部压缩），IDL（接口定义语言）做契约（强类型、代码生成）。

这篇文章会从 proto 文件定义讲起，覆盖 gRPC 在微服务架构中的完整应用。

---

## 一、Protocol Buffers

### 1.1 基本语法

```protobuf
syntax = "proto3";

package user;

message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  repeated string tags = 4;
  map<string, string> metadata = 5;
}
```

proto3 相比 proto2 的主要变化：所有字段都是 optional，移除了 required 关键字，支持 map 类型。

### 1.2 字段编号

字段编号（1, 2, 3...）是 Protocol Buffers 的核心概念。它用于在二进制编码中标识字段。一旦使用了某个编号，就不能再改。

字段编号 1-15 只用 1 字节编码，16-2047 用 2 字节。常用的字段应该用小编号。

### 1.3 枚举和 Oneof

```protobuf
enum Status {
  UNKNOWN = 0;
  ACTIVE = 1;
  INACTIVE = 2;
}

message Event {
  oneof payload {
    TextMessage text = 1;
    ImageMessage image = 2;
    VideoMessage video = 3;
  }
}
```

Oneof 表示互斥的字段——同一时间只能有一个被设置。

---

## 二、gRPC 四种通信模式

### 2.1 一元 RPC（Unary）

最简单的模式：客户端发一个请求，服务端返回一个响应。

```protobuf
service UserService {
  rpc GetUser (GetUserRequest) returns (User);
}
```

### 2.2 服务端流式 RPC

客户端发一个请求，服务端返回一个流，可以发送多个响应。

```protobuf
service UserService {
  rpc ListUsers (ListUsersRequest) returns (stream User);
}
```

适用场景：大数据量分页返回、实时数据推送。

### 2.3 客户端流式 RPC

客户端发送一个流，服务端返回一个响应。

```protobuf
service UserService {
  rpc UploadUsers (stream User) returns (UploadResult);
}
```

适用场景：批量上传、日志收集。

### 2.4 双向流式 RPC

客户端和服务端都可以随时发送数据。

```protobuf
service ChatService {
  rpc Chat (stream ChatMessage) returns (stream ChatMessage);
}
```

适用场景：实时聊天、双向数据同步。

---

## 三、Go 实现 gRPC 服务

### 3.1 定义 proto 文件

```protobuf
syntax = "proto3";
package order;

service OrderService {
  rpc CreateOrder (CreateOrderRequest) returns (Order);
  rpc GetOrder (GetOrderRequest) returns (Order);
  rpc ListOrders (ListOrdersRequest) returns (stream Order);
}

message CreateOrderRequest {
  int32 user_id = 1;
  repeated OrderItem items = 2;
}

message Order {
  int32 id = 1;
  int32 user_id = 2;
  repeated OrderItem items = 3;
  string status = 4;
  float total = 5;
}
```

### 3.2 生成代码

```bash
protoc --go_out=. --go-grpc_out=. proto/order.proto
```

### 3.3 实现服务

```go
type OrderServer struct {
    pb.UnimplementedOrderServiceServer
}

func (s *OrderServer) CreateOrder(ctx context.Context, req *pb.CreateOrderRequest) (*pb.Order, error) {
    order := &pb.Order{
        Id:     generateID(),
        UserId: req.UserId,
        Items:  req.Items,
        Status: "created",
        Total:  calculateTotal(req.Items),
    }
    return order, nil
}
```

---

## 四、Java 实现 gRPC 服务

```java
public class OrderServiceImpl extends OrderServiceGrpc.OrderServiceImplBase {
    @Override
    public void createOrder(CreateOrderRequest request, StreamObserver<Order> responseObserver) {
        Order order = Order.newBuilder()
            .setId(generateId())
            .setUserId(request.getUserId())
            .addAllItems(request.getItemsList())
            .setStatus("created")
            .build();
        
        responseObserver.onNext(order);
        responseObserver.onCompleted();
    }
}
```

---

## 五、负载均衡

### 5.1 客户端负载均衡

gRPC 内置了客户端负载均衡。客户端从服务发现获取所有实例，自己做负载均衡。

```go
conn, err := grpc.Dial(
    "dns:///order-service:50051",
    grpc.WithDefaultServiceConfig(`{"loadBalancingConfig": [{"round_robin":{}}]}`),
)
```

### 5.2 服务端负载均衡

用 Nginx 或 Envoy 做服务端负载均衡。Nginx 1.13.10+ 支持 gRPC 代理。

---

## 六、拦截器（Interceptors）

拦截器类似于中间件，在 RPC 调用前后执行逻辑。

### 6.1 一元拦截器

```go
func loggingInterceptor(
    ctx context.Context,
    req interface{},
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (interface{}, error) {
    start := time.Now()
    resp, err := handler(ctx, req)
    log.Printf("Method: %s, Duration: %v, Error: %v",
        info.FullMethod, time.Since(start), err)
    return resp, err
}
```

### 6.2 链式拦截器

```go
server := grpc.NewServer(
    grpc.ChainUnaryInterceptor(
        recoveryInterceptor,
        loggingInterceptor,
        authInterceptor,
    ),
)
```

---

## 七、错误处理

gRPC 定义了标准的状态码：

| 状态码 | 含义 |
|--------|------|
| OK | 成功 |
| INVALID_ARGUMENT | 参数无效 |
| NOT_FOUND | 资源不存在 |
| ALREADY_EXISTS | 资源已存在 |
| PERMISSION_DENIED | 权限不足 |
| UNAUTHENTICATED | 未认证 |
| INTERNAL | 内部错误 |
| UNAVAILABLE | 服务不可用 |

不要把所有错误都返回 INTERNAL——使用正确的状态码让客户端能做出适当的处理。

---

## 八、认证

### 8.1 Token 认证

```go
// 客户端
token := &oauth2.Token{AccessToken: "my-token"}
conn, err := grpc.Dial(addr,
    grpc.WithTransportCredentials(insecure.NewCredentials()),
    grpc.WithPerRPCCredentials(&tokenAuth{token: token}),
)
```

### 8.2 TLS

```go
creds, err := credentials.NewServerTLSFromFile("server.crt", "server.key")
server := grpc.NewServer(grpc.Creds(creds))
```

---

## 九、健康检查

gRPC 定义了标准的健康检查协议：

```protobuf
service Health {
  rpc Check (HealthCheckRequest) returns (HealthCheckResponse);
}
```

Kubernetes 可以用这个协议做存活探针和就绪探针。

---

## 十、gRPC-Web

gRPC-Web 让浏览器可以直接调用 gRPC 服务。通过 Envoy 代理将 gRPC-Web 协议转换为标准 gRPC 协议。

---

## 十一、与 REST 共存

### 11.1 gRPC-Gateway

gRPC-Gateway 把 gRPC 服务映射为 REST API。通过 proto 文件中的注释定义 HTTP 映射。

### 11.2 同时暴露两种协议

一个服务同时监听 gRPC 端口和 HTTP 端口，满足不同客户端的需求。

---

## 十二、性能优化

### 12.1 连接管理

gRPC 基于 HTTP/2，支持多路复用。一个 TCP 连接可以并发多个 RPC 调用。客户端应该复用连接，不要为每次调用创建新连接。

### 12.2 消息大小

默认的 gRPC 消息大小限制是 4MB。对于大消息，需要调整 `maxSendMsgSize` 和 `maxRecvMsgSize`。

### 12.3 超时和截止时间

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
resp, err := client.GetOrder(ctx, &pb.GetOrderRequest{Id: orderId})
```

---

## 十三、测试

### 13.1 单元测试

gRPC 服务的单元测试可以用 bufconn 建立内存连接，不需要启动真实的服务器。

### 13.2 集成测试

用测试容器（testcontainers）启动真实的依赖服务，验证端到端的流程。

---

## 总结

gRPC 在微服务通信中比 REST 更高效、更可靠。Protocol Buffers 的强类型保证了接口契约，HTTP/2 提供了高效的传输，流式 RPC 支持了实时场景。但 gRPC 不是万能的——浏览器支持有限、调试不如 REST 直观、学习曲线较陡。选择 REST 还是 gRPC，取决于你的具体场景。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days'
) ON CONFLICT DO NOTHING;
