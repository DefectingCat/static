INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Kubernetes 集群管理与编排实战',
    'kubernetes-guide',
    '从 Pod 调度到 Service 网络，从 Helm Charts 到 GitOps 工作流，全面讲解 Kubernetes 集群管理与生产部署实践。',
    $doc$
# Kubernetes 集群管理与编排实战

## 前言

Kubernetes（简称 K8s）已经成为容器编排的事实标准。如果你在用 Docker Compose 管理生产环境，迟早会遇到它的天花板：单机部署、没有自动故障转移、没有滚动更新、没有服务发现。当你开始面对这些问题的时候，就是该上 Kubernetes 的时候了。

这篇文章不是 K8s 的入门教程，官方文档和教程已经写得很好了。我想分享的是在实际生产环境中积累的经验——那些文档里不会告诉你、但你迟早会踩的坑。

---

## 一、核心架构

### 1.1 控制平面

Kubernetes 的控制平面（Control Plane）由几个核心组件组成：

- **kube-apiserver**：所有操作的入口，REST API 服务器
- **etcd**：分布式键值存储，保存集群的所有状态
- **kube-scheduler**：决定 Pod 运行在哪个节点
- **kube-controller-manager**：运行各种控制器，确保集群状态符合期望

控制平面的高可用很重要。生产环境至少要有 3 个 master 节点，etcd 也要做集群。我见过单 master 的集群在生产环境挂掉之后，整个集群不可用长达半小时的情况。

### 1.2 工作节点

每个工作节点（Worker Node）运行几个关键组件：

- **kubelet**：节点上的代理，负责管理 Pod 的生命周期
- **kube-proxy**：维护节点上的网络规则，实现 Service 的负载均衡
- **容器运行时**：containerd 或 CRI-O

节点的资源管理很关键。每个节点都有资源配额，调度器根据这些配额来决定 Pod 放在哪里。用 `kubectl describe node <node-name>` 可以查看节点的资源使用情况。

---

## 二、Pod 与调度

### 2.1 Pod 设计原则

Pod 是 K8s 中最小的调度单元。一个 Pod 可以包含一个或多个容器，它们共享网络命名空间和存储卷。

什么时候该用多容器 Pod？最常见的模式是 sidecar。比如在应用 Pod 旁边放一个日志收集容器，或者放一个 envoy 代理做服务网格。但不要把不相关的服务塞到同一个 Pod 里——它们应该独立扩缩容。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  containers:
  - name: app
    image: my-app:1.0
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
  - name: sidecar-log-agent
    image: log-agent:1.0
```

### 2.2 资源请求与限制

resources.requests 告诉调度器这个 Pod 需要多少资源，resources.limits 告诉 K8s 这个 Pod 最多能用多少资源。requests 影响调度决策，limits 影响运行时行为。

CPU 超限不会被杀掉，只会被限流。内存超限会触发 OOMKilled。这个区别很重要——很多"我的 Pod 怎么被杀了"的问题都是因为内存 limits 设太低。

### 2.3 调度策略

Kubernetes 的调度器根据多种因素来决定 Pod 运行在哪个节点：资源可用性、亲和性/反亲和性、污点和容忍、拓扑约束。

```yaml
# 节点亲和性：只调度到有 SSD 的节点
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disk-type
          operator: In
          values:
          - ssd

# Pod 反亲和性：同一 Deployment 的 Pod 分散到不同节点
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - my-app
      topologyKey: kubernetes.io/hostname
```

### 2.4 污点与容忍

Taint 和 Toleration 配合使用。Taint 加在节点上，表示"不容忍这个 taint 的 Pod 不能调度到这个节点"。Toleration 加在 Pod 上，表示"我可以容忍这个 taint"。

```bash
# 给节点加 taint
kubectl taint nodes node1 dedicated=gpu:NoSchedule

# Pod 需要 toleration 才能调度到这个节点
```

---

## 三、工作负载

### 3.1 Deployment

Deployment 管理无状态应用的副本集。它支持滚动更新和回滚。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: my-app:2.0
        ports:
        - containerPort: 8080
```

maxSurge 和 maxUnavailable 的设置很关键。maxUnavailable 设为 0 确保更新过程中始终有足够的 Pod 在服务请求。

### 3.2 StatefulSet

StatefulSet 管理有状态应用。每个 Pod 有稳定的网络标识（pod-0, pod-1, ...）和持久的存储。数据库、消息队列、ZooKeeper 这类需要稳定标识的服务应该用 StatefulSet。

### 3.3 DaemonSet

DaemonSet 确保每个节点（或指定节点）运行一个 Pod。日志收集、监控代理、网络插件这些基础设施组件适合用 DaemonSet。

### 3.4 Job 和 CronJob

Job 运行一次性任务，CronJob 按计划运行任务。批处理任务、数据迁移、定时备份适合用这些资源。

---

## 四、服务发现与网络

### 4.1 Service 类型

- **ClusterIP**（默认）：只在集群内部可达
- **NodePort**：在每个节点上开放一个端口
- **LoadBalancer**：创建云厂商的负载均衡器
- **ExternalName**：映射到外部 DNS 名称

大多数微服务之间的通信用 ClusterIP 就够了。只有需要外部访问的服务才用 LoadBalancer 或 NodePort。

### 4.2 Ingress

Ingress 是 HTTP 层的路由规则，把外部流量转发到集群内的 Service。Nginx Ingress Controller、Traefik、HAProxy 是常用的 Ingress Controller。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: api-v2
            port:
              number: 80
```

### 4.3 Network Policy

NetworkPolicy 是集群内部的防火墙规则，控制 Pod 之间的通信。默认情况下所有 Pod 之间都能互相通信，这在生产环境是不安全的。

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## 五、配置管理与 Secrets

### 5.1 ConfigMap

ConfigMap 存储非敏感的配置数据。可以通过环境变量或挂载文件的方式注入到 Pod 中。

### 5.2 Secrets

Secrets 存储敏感数据（密码、密钥、证书）。注意：Secrets 默认只是 base64 编码，不是加密。生产环境应该启用 etcd 加密或使用外部密钥管理（如 Vault）。

---

## 六、存储

### 6.1 Persistent Volume

PV（Persistent Volume）是集群级别的存储资源，PVC（Persistent Volume Claim）是 Pod 对存储的申请。StorageClass 定义了存储的类型和供应方式。

有状态应用（数据库、消息队列）必须使用持久化存储。无状态应用如果需要缓存或临时数据，可以用 emptyDir。

---

## 七、Helm

### 7.1 为什么用 Helm

Helm 是 K8s 的包管理器。它把相关的 K8s 资源打包成 Chart，支持模板化、版本管理和一键部署。没有 Helm 的话，管理几十个微服务的 K8s 清单文件是噩梦。

### 7.2 Chart 结构

```yaml
my-chart/
  Chart.yaml
  values.yaml
  templates/
    deployment.yaml
    service.yaml
    ingress.yaml
    configmap.yaml
```

values.yaml 定义默认配置，templates 下的文件用 Go 模板语法渲染。

### 7.3 Helm 最佳实践

把 Chart 发布到私有仓库（如 Harbor），每次部署使用特定版本号。不要在生产环境用 `latest` tag。用 `helm diff` 查看变更再部署。

---

## 八、监控与日志

### 8.1 Prometheus + Grafana

Prometheus 是 K8s 生态中最常用的监控方案。它通过 Service Discovery 自动发现集群中的 Pod 和 Service，抓取指标数据。Grafana 提供可视化面板。

### 8.2 日志收集

EFK（Elasticsearch + Fluentd + Kibana）或 PLG（Promtail + Loki + Grafana）是两种主流的日志方案。Fluentd/Promtail 作为 DaemonSet 运行在每个节点上，收集容器日志。

---

## 九、安全

### 9.1 RBAC

Role-Based Access Control 控制谁可以对哪些资源执行哪些操作。最小权限原则：只给用户和程序需要的最小权限。

### 9.2 Pod Security Standards

Kubernetes 1.25+ 移除了 PodSecurityPolicy，用 Pod Security Admission 替代。它定义了三个级别：privileged、baseline、restricted。

### 9.3 镜像安全

使用 Trivy 扫描镜像漏洞；只从可信的 Registry 拉取镜像；使用 ImagePolicyWebhook 禁止使用 latest tag。

---

## 十、GitOps

### 10.1 ArgoCD

ArgoCD 是 K8s 原生的 GitOps 工具。它监听 Git 仓库的变化，自动同步集群状态到 Git 中定义的期望状态。

### 10.2 Flux

Flux 是另一个流行的 GitOps 工具，由 Weaveworks 开发。它的架构更模块化，支持多种来源（Git、Helm、OCI）。

---

## 结尾

Kubernetes 的学习曲线很陡，但一旦你的集群稳定运行起来，它带来的效率提升是显著的。从一个小集群开始，先把无状态服务迁移上去，积累经验后再处理有状态服务。不要试图一步到位——K8s 生态太庞大了，一步一步来。
$doc$,
    NULL,
    '/images/covers/kubernetes-guide.jpg',
    '<ul>
<li><a href="#前言">前言</a></li>
<li><a href="#一-核心架构">一、核心架构</a></li>
<ul>
<li><a href="#1-1-控制平面">1.1 控制平面</a></li>
<li><a href="#1-2-工作节点">1.2 工作节点</a></li>
</ul>
<li><a href="#二-pod-与调度">二、Pod 与调度</a></li>
<ul>
<li><a href="#2-1-pod-设计原则">2.1 Pod 设计原则</a></li>
<li><a href="#2-2-资源请求与限制">2.2 资源请求与限制</a></li>
<li><a href="#2-3-调度策略">2.3 调度策略</a></li>
<li><a href="#2-4-污点与容忍">2.4 污点与容忍</a></li>
</ul>
<li><a href="#三-工作负载">三、工作负载</a></li>
<ul>
<li><a href="#3-1-deployment">3.1 Deployment</a></li>
<li><a href="#3-2-statefulset">3.2 StatefulSet</a></li>
<li><a href="#3-3-daemonset">3.3 DaemonSet</a></li>
<li><a href="#3-4-job-和-cronjob">3.4 Job 和 CronJob</a></li>
</ul>
<li><a href="#四-服务发现与网络">四、服务发现与网络</a></li>
<ul>
<li><a href="#4-1-service-类型">4.1 Service 类型</a></li>
<li><a href="#4-2-ingress">4.2 Ingress</a></li>
<li><a href="#4-3-network-policy">4.3 Network Policy</a></li>
</ul>
<li><a href="#五-配置管理与-secrets">五、配置管理与 Secrets</a></li>
<ul>
<li><a href="#5-1-configmap">5.1 ConfigMap</a></li>
<li><a href="#5-2-secrets">5.2 Secrets</a></li>
</ul>
<li><a href="#六-存储">六、存储</a></li>
<ul>
<li><a href="#6-1-persistent-volume">6.1 Persistent Volume</a></li>
</ul>
<li><a href="#七-helm">七、Helm</a></li>
<ul>
<li><a href="#7-1-为什么用-helm">7.1 为什么用 Helm</a></li>
<li><a href="#7-2-chart-结构">7.2 Chart 结构</a></li>
<li><a href="#7-3-helm-最佳实践">7.3 Helm 最佳实践</a></li>
</ul>
<li><a href="#八-监控与日志">八、监控与日志</a></li>
<ul>
<li><a href="#8-1-prometheus-grafana">8.1 Prometheus + Grafana</a></li>
<li><a href="#8-2-日志收集">8.2 日志收集</a></li>
</ul>
<li><a href="#九-安全">九、安全</a></li>
<ul>
<li><a href="#9-1-rbac">9.1 RBAC</a></li>
<li><a href="#9-2-pod-security-standards">9.2 Pod Security Standards</a></li>
<li><a href="#9-3-镜像安全">9.3 镜像安全</a></li>
</ul>
<li><a href="#十-gitops">十、GitOps</a></li>
<ul>
<li><a href="#10-1-argocd">10.1 ArgoCD</a></li>
<li><a href="#10-2-flux">10.2 Flux</a></li>
</ul>
<li><a href="#结尾">结尾</a></li>
</ul>',
    715,
    4,
    'published',
    NOW() - INTERVAL '14 days',
    NOW() - INTERVAL '14 days',
    NOW() - INTERVAL '14 days'
) ON CONFLICT DO NOTHING;
