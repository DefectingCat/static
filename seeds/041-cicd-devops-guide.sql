INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'CI/CD 流水线设计与 DevOps 实践',
    'cicd-devops-guide',
    '从构建自动化到部署策略，覆盖 Jenkins、GitHub Actions、GitLab CI、ArgoCD 工具链，讲解流水线设计、环境管理、质量门禁和发布策略。',
    $doc$
# CI/CD 流水线设计与 DevOps 实践

## 前言

CI/CD 不是工具问题，是文化问题。我见过太多团队买了昂贵的 CI/CD 平台，但开发流程还是老样子——手动测试、手动部署、出了问题再修。工具只是手段，目的是让代码从提交到上线这个过程更快、更可靠、更自动化。

这篇文章从实践角度出发，讲一讲 CI/CD 流水线的设计原则和常见方案。

---

## 一、持续集成（CI）

### 1.1 什么是持续集成

持续集成的核心实践：开发者频繁地把代码合并到主分支，每次合并都触发自动化构建和测试。

### 1.2 CI 流水线设计

一个典型的 CI 流水线包括：

1. **代码检出**：从 Git 仓库拉取代码
2. **依赖安装**：安装项目依赖
3. **代码检查**：lint、格式化检查
4. **单元测试**：运行单元测试
5. **集成测试**：运行集成测试
6. **代码覆盖率**：生成覆盖率报告
7. **安全扫描**：依赖漏洞扫描、SAST
8. **构建**：编译打包

### 1.3 质量门禁

质量门禁是 CI 的核心——不合格的代码不允许合并。

```yaml
# GitHub Actions 示例
- name: Quality Gate
  run: |
    # 测试通过率必须 100%
    # 代码覆盖率必须 > 80%
    # 没有 P0/P1 级别的安全漏洞
    # 代码 lint 没有 error
```

---

## 二、持续部署（CD）

### 2.1 部署策略

**蓝绿部署**：维护两套完全相同的环境，切换流量实现零停机。

**金丝雀发布**：先给一小部分用户使用新版本，观察没有问题后再全量发布。

**滚动更新**：逐步替换旧版本的实例。Kubernetes 的默认策略。

### 2.2 环境管理

开发环境 → 测试环境 → 预发布环境 → 生产环境。每个环境的配置通过环境变量或配置中心管理，不要硬编码在代码里。

### 2.3 回滚策略

任何部署都必须有回滚方案。最简单的回滚：回退到上一个版本的镜像重新部署。

---

## 三、CI/CD 工具

### 3.1 GitHub Actions

```yaml
name: CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm test
      - run: npm run lint

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        run: ./deploy.sh
```

### 3.2 GitLab CI

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  script:
    - npm ci
    - npm test

build:
  stage: build
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - docker push registry.example.com/myapp:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/myapp myapp=registry.example.com/myapp:$CI_COMMIT_SHA
  only:
    - main
```

### 3.3 Jenkins

Jenkins 是老牌的 CI/CD 工具，生态丰富但配置复杂。推荐用 Jenkins Pipeline 即代码的方式管理流水线。

---

## 四、GitOps

### 4.1 GitOps 原则

- 所有声明式配置存储在 Git 仓库中
- Git 仓库是系统的唯一事实来源
- 自动化工具将实际状态同步到 Git 中定义的期望状态
- 变更通过 Pull Request 流程审核

### 4.2 ArgoCD

ArgoCD 是 Kubernetes 原生的 GitOps 工具：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    path: apps/my-app
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 4.3 Flux

Flux 是另一个流行的 GitOps 工具，架构更模块化。

---

## 五、基础设施即代码（IaC）

### 5.1 Terraform

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

Terraform 的工作流：plan（预览变更）→ apply（执行变更）→ destroy（销毁资源）。

### 5.2 Ansible

Ansible 是配置管理工具，用 YAML 定义主机配置。

```yaml
- hosts: webservers
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Start nginx
      service:
        name: nginx
        state: started
```

---

## 六、容器化与 Kubernetes

### 6.1 Docker 构建优化

- 多阶段构建减小镜像体积
- 利用构建缓存加速
- 使用 .dockerignore 排除不需要的文件
- 固定依赖版本

### 6.2 Kubernetes 部署

- 使用 Deployment 管理无状态应用
- 配置健康检查和就绪探针
- 设置资源限制和请求
- 使用 ConfigMap 和 Secrets 管理配置
- 配置 HPA（Horizontal Pod Autoscaler）自动扩缩容

---

## 七、监控与可观测性

### 7.1 三大支柱

- **Metrics**：Prometheus + Grafana
- **Logging**：EFK 或 PLG
- **Tracing**：Jaeger 或 Zipkin

### 7.2 告警

```yaml
# Prometheus 告警规则
groups:
- name: app-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "高错误率告警"
```

---

## 八、安全

### 8.1 DevSecOps

安全左移——在 CI 阶段就集成安全扫描：

- SAST（静态应用安全测试）：Semgrep、SonarQube
- DAST（动态应用安全测试）：OWASP ZAP
- SCA（软件成分分析）：Snyk、Dependabot
- 容器镜像扫描：Trivy

### 8.2 Secrets 管理

不要在代码或配置文件中硬编码密钥。使用 Vault、AWS Secrets Manager、或 Kubernetes Secrets。

---

## 九、度量与改进

### 9.1 DORA 指标

- **部署频率**：多久部署一次
- **变更前置时间**：从提交到上线需要多长时间
- **变更失败率**：部署导致故障的比例
- **服务恢复时间**：从故障中恢复需要多长时间

### 9.2 持续改进

定期回顾 CI/CD 流水线的效率，识别瓶颈，持续优化。

---

## 总结

CI/CD 不是一次性搭建完成的，它需要根据团队的实际情况持续调整。从最简单的流水线开始，逐步添加质量门禁、安全扫描、自动化部署。记住，工具是手段，目标是更快、更可靠地交付价值。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days',
    NOW() - INTERVAL '6 days'
) ON CONFLICT DO NOTHING;
