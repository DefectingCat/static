INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'React 18 新特性与现代前端架构实战',
    'react18-guide',
    '从 Concurrent Rendering 到 Server Components，覆盖 React 18 核心 API 与大型项目架构实践',
    $doc$
# React 18 新特性与现代前端架构实战

## 写在前面

去年我们团队把一个日活过百万的 C 端产品从 React 16 迁移到 React 18，前后花了将近四个月。过程中踩了不少坑，也积累了一些经验。这篇文章不是官方文档的复述，而是基于真实项目经验，把 React 18 中我认为最关键的改动梳理出来。

React 18 发布于 2022 年 3 月，这是 React 自 2017 年 16.0 以来最大的一次架构变革。核心变化集中在三个方面：并发渲染、自动批处理、以及流式 SSR。

## 并发渲染：React 调度机制的根本变化

### 什么是 Concurrent Mode

React 16 的渲染是同步的——一旦开始渲染，就会一直执行到完成，期间主线程被占用。如果组件树很大，用户交互就会卡顿。

React 18 引入了并发渲染（Concurrent Rendering），本质上是给 React 的 reconciler 加了一个优先级调度器。不同类型的更新可以被打断、暂停、恢复，高优先级的更新（比如用户点击）可以插队到低优先级更新（比如数据预取）前面。

```tsx
// React 17
import ReactDOM from 'react-dom';
ReactDOM.render(<App />, document.getElementById('root'));

// React 18
import { createRoot } from 'react-dom/client';
const root = createRoot(document.getElementById('root'));
root.render(<App />);
```

切换到 `createRoot` 之后，React 18 默认开启所有并发特性。

### Rendering 与 Committing 的分离

要理解并发渲染，需要分清两个阶段：Render 阶段调用组件函数计算虚拟 DOM 树的 diff，可以被打断和重试；Commit 阶段把计算结果批量应用到真实 DOM，是同步不可中断的。

## Transitions：控制更新优先级的 API

### useTransition

`useTransition` 让你把一个状态更新标记为"过渡"，告诉 React 这个更新可以被中断，优先处理更紧急的更新。

```tsx
import { useState, useTransition } from 'react';

function SearchPage() {
  const [query, setQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  function handleChange(e) {
    setQuery(e.target.value);
    startTransition(() => {
      setSearchResults(filterData(e.target.value));
    });
  }

  return (
    <div>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <Results data={searchResults} />
    </div>
  );
}
```

没有 `useTransition` 的时候，每次输入都会触发一次完整的 re-render。用了 `useTransition` 之后，输入框的响应是即时的，搜索结果的更新可以在空闲时处理。

### useDeferredValue

`useDeferredValue` 和 `useTransition` 做的事情类似，但用法不同。它接受一个值，返回一个延迟版本的值。当你无法控制上游传入的值时，它特别有用。

## Suspense：声明式的加载状态管理

### Suspense 的工作原理

Suspense 本质上是一个边界声明。当子树中有组件还在等待异步操作时，React 会渲染 fallback；异步操作完成后，React 用实际内容替换 fallback。

React 18 扩展了 Suspense 的能力，让它支持数据加载场景。原理是当组件在 render 过程中抛出一个 Promise 时，React 会捕获它，暂停渲染，等 Promise resolve 后再恢复。

### Suspense 边界的设计

在大型应用中，Suspense 边界放哪里直接影响用户体验。放得太外层，整个页面都会显示 loading；放得太里层，fallback 切换会很频繁，造成视觉闪烁。

我的经验是在路由级别放一个 Suspense 边界，然后在页面内部按模块粒度放二级边界。

## 流式 SSR 与 Hydration

React 18 的流式 SSR 基于 `renderToPipeableStream`。配合 Suspense，服务端可以在组件数据还没准备好时先发送 HTML shell 和 loading 状态，数据就绪后再通过内联 `<script>` 标签追加内容。

## 自动批处理：减少不必要的 re-render

React 18 把批处理扩展到了所有场景——事件处理、Promise、setTimeout、原生事件，一律合并为一次 re-render。

```tsx
// React 18
async function fetchData() {
  const result = await fetch('/api/data');
  // 只有一次 re-render
  setData(result);
  setLoading(false);
}
```

## 新 Hooks 详解

### useId

`useId` 生成一个在服务端和客户端之间保持一致的唯一 ID，解决了 SSR 中 ID 不匹配的问题。

### useSyncExternalStore

`useSyncExternalStore` 订阅外部数据源，保证在并发模式下不会出现撕裂。Redux、Zustand、Jotai 都用它来集成 React 18 的并发特性。

### useInsertionEffect

`useInsertionEffect` 在 DOM 变更前同步执行，用于注入 CSS-in-JS 的样式。绝大多数应用不需要直接使用，它是给 CSS-in-JS 库作者用的。

## 状态管理：Zustand、Jotai 与 Recoil

React 18 的并发特性对状态管理库提出了新要求。Zustand 是目前最轻量的方案，天然兼容 React 18 的并发特性。Jotai 是原子化状态管理方案，适合状态之间有大量派生关系的场景。

## 性能优化

React.memo 对 props 做浅比较，props 没变时跳过 re-render。useMemo 和 useCallback 分别缓存计算结果和函数引用。虚拟化（react-window、@tanstack/react-virtual）只渲染可视区域内的元素。

## Server Components

Server Components 允许组件只在服务端渲染，不发送 JavaScript 到客户端。目前主要通过 Next.js App Router 使用。

## 迁移实战

从 React 16/17 迁移到 React 18，核心步骤是：升级 react 和 react-dom 到 18.x；把 ReactDOM.render 改成 createRoot；检查所有异步上下文中的状态更新；测试第三方库兼容性。

## 总结

React 18 不是一次 API 层面的大改，而是一次架构层面的升级。迁移成本不高，但需要仔细测试。建议先升级到 React 18，然后逐步引入并发特性。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '5 days'
) ON CONFLICT DO NOTHING;
