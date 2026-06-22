INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Docker 容器化技术完全指南：从入门到生产部署',
    'docker-deep-dive',
    '本文从架构设计、镜像构建、容器编排到生产部署，全面讲解 Docker 技术栈。涵盖命名空间、cgroups、UnionFS 等内核级原理，以及 compose、多阶段构建和安全加固实践。',
    $doc$
# Docker 容器化技术完全指南：从入门到生产部署

## 前言

我第一次接触 Docker 是在 2016 年。当时团队在用虚拟机部署微服务，每个服务需要单独的 CentOS 镜像，配环境就得花半小时。有一次我本地跑得好好的 Python 脚本，部署到服务器上死活报错，折腾了一下午才发现是 OpenSSL 版本不一致。这种"在我机器上能跑"的问题，在容器化出现之前几乎是每个后端工程师的噩梦。

Docker 改变了这个局面。它用一种轻量级的方式把应用和它的运行环境打包在一起，确保在任何地方都能一致地运行。但 Docker 不仅仅是一个部署工具，它的内核原理、网络模型和存储机制都值得深入理解。这篇文章会从底层原理讲起，覆盖从开发到生产的完整流程。

---

## 一、Docker 架构与核心概念

### 1.1 整体架构

Docker 采用客户端-服务端（C/S）架构。用户通过 Docker CLI 发送命令，Docker 守护进程（dockerd）负责实际的容器管理。

```
┌─────────────────────────────────────────────────────┐
│                    Docker Client                     │
│                  (docker CLI)                        │
└───────────────────────┬─────────────────────────────┘
                        │ REST API
┌───────────────────────▼─────────────────────────────┐
│                   Docker Daemon                      │
│                 (dockerd)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  镜像管理    │  │  容器管理    │  │  网络管理    │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└───────────────────────┬─────────────────────────────┘
                        │ containerd
┌───────────────────────▼─────────────────────────────┐
│              containerd-shim                          │
│              runc (OCI runtime)                       │
└─────────────────────────────────────────────────────┘
```

dockerd 不直接管理容器，它把任务交给 containerd，containerd 再通过 containerd-shim 启动 runc。runc 是符合 OCI（Open Container Initiative）标准的运行时，负责创建和运行容器。这个分层设计的好处是：即使 dockerd 崩溃，已经在运行的容器不会受到影响。

### 1.2 镜像 vs 容器

新手最容易混淆的概念。镜像是只读的模板，容器是镜像的运行实例。类比一下：镜像相当于一个 Class，容器就是这个 Class 的 Instance。

镜像由多层只读文件系统叠加而成。你拉取一个 nginx:latest 镜像，Docker 会下载多个层——基础系统层、nginx 安装层、配置层。容器在镜像之上加了一个可写层，所有的文件修改都发生在这个可写层里。

```bash
# 查看镜像的分层结构
docker history nginx:latest

# 查看容器的可写层
docker inspect <container_id> | grep -A 5 "GraphDriver"
```

### 1.3 Registry 与仓库

Registry 是存放镜像的服务。Docker Hub 是最大的公共 Registry，企业通常搭建私有 Registry。仓库（Repository）是同一镜像不同版本的集合，比如 nginx:1.24、nginx:1.25 属于同一个仓库。

```bash
# 拉取镜像（默认从 Docker Hub）
docker pull nginx:1.25

# 推送镜像到私有 Registry
docker tag myapp:latest registry.example.com/myapp:v1
docker push registry.example.com/myapp:v1
```

---

## 二、Docker 镜像深入解析

### 2.1 镜像分层原理

Docker 镜像的核心是 UnionFS（联合文件系统）。每一层都是只读的，当需要修改文件时，Docker 会在最上层创建一个副本进行修改。这个过程叫 Copy-on-Write（写时复制）。

```dockerfile
# 一个典型的 Dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3 python3-pip
COPY requirements.txt /app/
RUN pip3 install -r /app/requirements.txt
COPY . /app/
WORKDIR /app
CMD ["python3", "app.py"]
```

这个 Dockerfile 会生成 5 层：ubuntu:22.04 基础层、apt-get 安装层、COPY requirements.txt 层、pip install 层、COPY 源码层。每层都有唯一的 SHA256 摘要。如果两个镜像有相同的层，Docker 会复用，不重复存储。这就是为什么拉取镜像比复制整个虚拟机快得多。

### 2.2 构建缓存机制

Docker 构建时会逐层检查缓存。如果某一层没有变化，就直接复用缓存。一旦某一层发生变化，它之后的所有层都需要重新构建。

```dockerfile
# 不好的写法：缓存容易失效
COPY . /app/
RUN pip3 install -r /app/requirements.txt

# 好的写法：先复制依赖文件，再复制源码
COPY requirements.txt /app/
RUN pip3 install -r /app/requirements.txt
COPY . /app/
```

Docker 20.10 以后支持 BuildKit，它提供了更精细的缓存控制。

### 2.3 多阶段构建

多阶段构建解决了一个长期问题：构建环境和运行环境分离。很多编译型语言（Go、Rust、Java）在构建时需要完整的工具链，但运行时只需要二进制文件。

```dockerfile
# 构建阶段
FROM golang:1.21-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server .

# 运行阶段
FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

最终镜像只包含一个静态编译的二进制文件和 SSL 证书，大小可能只有几十 MB，而构建阶段的 Alpine 镜像有几百 MB。

### 2.4 镜像优化技巧

几个要点：用 alpine 或 distroless 基础镜像，不要用 ubuntu；`--only=production` 跳过 devDependencies；最后用 USER 指令切换到非 root 用户；合并 RUN 指令减少层数。

---

## 三、容器网络

### 3.1 网络驱动

Docker 提供了多种网络驱动：bridge（单机多容器）、host（高性能网络）、overlay（跨主机通信）、macvlan（需要独立 MAC 地址）、none（完全隔离）。默认的 bridge 网络有个限制：容器之间只能通过 IP 通信，不能通过容器名。自定义 bridge 网络支持 DNS 解析。

### 3.2 容器间通信原理

在 bridge 网络中，每个容器都有自己的网络命名空间。Docker 通过 veth pair（虚拟以太网设备对）连接容器和宿主机的 docker0 网桥。iptables 规则负责 NAT 和端口映射。

### 3.3 自定义网络配置

生产环境中，默认的网络配置通常不够用。你需要调整 MTU、定义子网、配置 DNS。禁用 IP masquerade 可以避免 Docker 的 NAT 干扰容器获取真实客户端 IP。

---

## 四、数据持久化：Volume 与 Bind Mount

### 4.1 三种存储类型

Docker 有三种主要的持久化方式：Volume（Docker 管理的存储区域）、Bind Mount（直接挂载宿主机目录到容器）、tmpfs（挂载到内存）。Volume 推荐用于数据库等有状态服务，Bind Mount 推荐用于开发时的代码同步。

### 4.2 Volume vs Bind Mount 对比

Volume 由 Docker 管理，跨平台兼容，但备份需要额外操作。Bind Mount 直接复制目录即可备份，但路径依赖宿主机。开发环境倾向用 Bind Mount，生产环境用 Volume。

---

## 五、Docker Compose

### 5.1 基础配置

docker-compose.yml 是定义多容器应用的标准方式。一个典型的 Web 应用可能包含 Web 服务器、应用服务器和数据库。depends_on 控制启动顺序，但有坑：它只等待容器启动，不等待服务就绪。用 healthcheck + condition 才能确保真正的就绪。

### 5.2 环境变量与 Secrets

`.env` 文件存放默认值，`.env.production` 存放生产配置。注意不要把 `.env` 提交到 Git。Docker BuildKit Secrets 可以在构建时使用密码但不留在镜像层。

### 5.3 Profiles 与选择性启动

Profiles 可以按场景分组服务，用 `docker compose --profile production up` 只启动特定 profile 下的服务。

---

## 六、Dockerfile 最佳实践

### 6.1 指令优化顺序

Dockerfile 的指令顺序影响构建缓存效率。把变化频率低的指令放前面，变化频率高的放后面。基础镜像放最前面，应用代码放最后面。

### 6.2 安全相关实践

使用 `COPY --chown` 避免后续 chown 操作；用 `npm cache clean --force` 清理缓存减小镜像体积；不要在镜像里硬编码密码或密钥；用 `.dockerignore` 排除敏感文件。

### 6.3 健康检查

健康检查配合 `restart: unless-stopped` 可以实现自动重启。

---

## 七、Docker 安全加固

### 7.1 Linux 内核隔离机制

Docker 的安全模型建立在 Linux 内核的几个关键特性上：Namespace 提供进程隔离，cgroups 限制容器的资源使用，UnionFS 提供文件系统隔离。

### 7.2 容器逃逸防护

不要用 `--privileged` 模式运行容器；只授予必要的能力；禁止容器获取新权限；使用只读文件系统。

### 7.3 镜像安全扫描

使用 Trivy 或 Docker Scout 扫描镜像漏洞。

---

## 八、生产环境部署

### 8.1 日志管理

Docker 默认的日志驱动是 json-file，生产环境需要配置日志轮转。对于集中式日志收集，推荐用 syslog 或 journald 驱动。

### 8.2 资源限制

生产环境必须设置资源限制，防止某个容器拖垮整个宿主机。limits 是上限，reservations 是保证的最低资源。

### 8.3 重启策略

生产环境用 `unless-stopped` 最合适。

### 8.4 滚动更新

`order: start-first` 先启动新容器，再停止旧容器，确保零停机时间。`failure_action: rollback` 在更新失败时自动回滚。

---

## 九、Docker 底层原理

### 9.1 Namespace 详解

Linux Namespace 是容器隔离的基础。Docker 使用了 7 种 Namespace：PID、NET、MNT、UTS、IPC、USER、CGROUP。

### 9.2 Cgroups v2

现代 Linux 发行版默认使用 cgroups v2，它提供了更精细的资源控制：memory.swap.max、io.latency、cpu.weight。

### 9.3 OverlayFS

Docker 默认使用 OverlayFS（overlay2 存储驱动）来实现分层文件系统。当容器删除时，可写层的数据也会丢失。

---

## 十、实战案例

文中覆盖了 Python Django、Go 微服务、Java Spring Boot 三种典型项目的 Docker 化部署方案，包括 Dockerfile 编写和 docker-compose 配置。

---

## 十一、常见问题与排查

容器无法启动时查看日志和退出码；网络问题测试连通性和 DNS 解析；磁盘空间不足用 `docker system df` 和 `docker system prune` 清理；性能问题用 `docker stats` 监控。

---

## 结尾

这篇文章覆盖了 Docker 从基础概念到生产部署的主要知识点。Docker 是整个容器化生态的基础，理解它的内核原理和最佳实践，才能更好地使用上层工具。

建议从搭建一个完整的本地开发环境开始，用 docker-compose 把你常用的数据库、缓存、消息队列都跑起来，写一个简单的 Web 应用部署到上面。
$doc$,
    NULL,
    '/images/covers/docker-deep-dive.jpg',
    '<ul>
<li><a href="#前言">前言</a></li>
<li><a href="#一-docker-架构与核心概念">一、Docker 架构与核心概念</a></li>
<ul>
<li><a href="#1-1-整体架构">1.1 整体架构</a></li>
<li><a href="#1-2-镜像-vs-容器">1.2 镜像 vs 容器</a></li>
<li><a href="#1-3-registry-与仓库">1.3 Registry 与仓库</a></li>
</ul>
<li><a href="#二-docker-镜像深入解析">二、Docker 镜像深入解析</a></li>
<ul>
<li><a href="#2-1-镜像分层原理">2.1 镜像分层原理</a></li>
<li><a href="#2-2-构建缓存机制">2.2 构建缓存机制</a></li>
<li><a href="#2-3-多阶段构建">2.3 多阶段构建</a></li>
<li><a href="#2-4-镜像优化技巧">2.4 镜像优化技巧</a></li>
</ul>
<li><a href="#三-容器网络">三、容器网络</a></li>
<ul>
<li><a href="#3-1-网络驱动">3.1 网络驱动</a></li>
<li><a href="#3-2-容器间通信原理">3.2 容器间通信原理</a></li>
<li><a href="#3-3-自定义网络配置">3.3 自定义网络配置</a></li>
</ul>
<li><a href="#四-数据持久化-volume-与-bind-mount">四、数据持久化：Volume 与 Bind Mount</a></li>
<ul>
<li><a href="#4-1-三种存储类型">4.1 三种存储类型</a></li>
<li><a href="#4-2-volume-vs-bind-mount-对比">4.2 Volume vs Bind Mount 对比</a></li>
</ul>
<li><a href="#五-docker-compose">五、Docker Compose</a></li>
<ul>
<li><a href="#5-1-基础配置">5.1 基础配置</a></li>
<li><a href="#5-2-环境变量与-secrets">5.2 环境变量与 Secrets</a></li>
<li><a href="#5-3-profiles-与选择性启动">5.3 Profiles 与选择性启动</a></li>
</ul>
<li><a href="#六-dockerfile-最佳实践">六、Dockerfile 最佳实践</a></li>
<ul>
<li><a href="#6-1-指令优化顺序">6.1 指令优化顺序</a></li>
<li><a href="#6-2-安全相关实践">6.2 安全相关实践</a></li>
<li><a href="#6-3-健康检查">6.3 健康检查</a></li>
</ul>
<li><a href="#七-docker-安全加固">七、Docker 安全加固</a></li>
<ul>
<li><a href="#7-1-linux-内核隔离机制">7.1 Linux 内核隔离机制</a></li>
<li><a href="#7-2-容器逃逸防护">7.2 容器逃逸防护</a></li>
<li><a href="#7-3-镜像安全扫描">7.3 镜像安全扫描</a></li>
</ul>
<li><a href="#八-生产环境部署">八、生产环境部署</a></li>
<ul>
<li><a href="#8-1-日志管理">8.1 日志管理</a></li>
<li><a href="#8-2-资源限制">8.2 资源限制</a></li>
<li><a href="#8-3-重启策略">8.3 重启策略</a></li>
<li><a href="#8-4-滚动更新">8.4 滚动更新</a></li>
</ul>
<li><a href="#九-docker-底层原理">九、Docker 底层原理</a></li>
<ul>
<li><a href="#9-1-namespace-详解">9.1 Namespace 详解</a></li>
<li><a href="#9-2-cgroups-v2">9.2 Cgroups v2</a></li>
<li><a href="#9-3-overlayfs">9.3 OverlayFS</a></li>
</ul>
<li><a href="#十-实战案例">十、实战案例</a></li>
<li><a href="#十一-常见问题与排查">十一、常见问题与排查</a></li>
<li><a href="#结尾">结尾</a></li>
</ul>',
    739,
    4,
    'published',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '15 days'
) ON CONFLICT DO NOTHING;
