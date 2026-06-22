INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, cover_image, toc_html, word_count, reading_time, status, published_at, created_at, updated_at)
VALUES
(
    1,
    'Vue 3 Composition API 与响应式系统深入',
    'vue3-composition-api',
    '从 Reactivity 原理到组件设计模式，深入讲解 Vue 3 Composition API、ref vs reactive、composables 设计和大型项目架构。',
    $doc$
# Vue 3 Composition API 与响应式系统深入

## 前言

Vue 3 最重大的变化不是性能提升，而是 Composition API。它改变了我们组织组件逻辑的方式。Options API 在小组件里很清晰，但当一个组件有几百行代码、需要复用多块逻辑时，代码会变得支离破碎——数据在这里，方法在那里，watch 在另一个地方。Composition API 让你可以把相关的逻辑组织在一起，代码的内聚性好得多。

这篇文章不是 API 文档的翻译，我想从实际开发的角度聊一聊 Vue 3 的核心机制和最佳实践。

---

## 一、响应式系统

### 1.1 Proxy vs defineProperty

Vue 2 用 `Object.defineProperty` 实现响应式。它有一个根本限制：只能监听已有属性的读写，不能监听新增/删除属性，也不能监听数组索引和长度。

Vue 3 改用 `Proxy`。Proxy 拦截的是整个对象的操作，包括属性访问、赋值、删除、in 操作符等。

```javascript
// Vue 2 的限制
const vm = new Vue({
  data: { name: 'Alice' }
});
vm.age = 25;  // 这个属性不是响应式的

// Vue 3 没有这个限制
const state = reactive({ name: 'Alice' });
state.age = 25;  // 完全响应式
```

### 1.2 ref vs reactive

Vue 3 提供了两种创建响应式状态的方式：`ref` 和 `reactive`。

```javascript
import { ref, reactive } from 'vue';

// ref：基本类型
const count = ref(0);
console.log(count.value);  // 0
count.value++;             // 修改需要 .value

// reactive：对象类型
const state = reactive({
  name: 'Alice',
  items: [1, 2, 3]
});
console.log(state.name);   // 不需要 .value
state.name = 'Bob';        // 直接修改
```

一个常见的困惑：什么时候用 ref，什么时候用 reactive？

我的原则：**优先用 ref**。理由：
- ref 可以包装任何类型，包括基本类型
- ref 解构后不会丢失响应性（通过 .value 访问）
- reactive 解构会丢失响应性

```javascript
// reactive 解构会丢失响应性
const state = reactive({ count: 0 });
const { count } = state;  // count 不再是响应式的

// ref 解构不会丢失
const count = ref(0);
const myCount = count;  // myCount.value 仍然是响应式的
```

### 1.3 computed

computed 是派生状态，依赖其他响应式状态自动更新。

```javascript
import { ref, computed } from 'vue';

const firstName = ref('John');
const lastName = ref('Doe');

const fullName = computed(() => {
  return `${firstName.value} ${lastName.value}`;
});

// computed 也是 ref
console.log(fullName.value);  // 'John Doe'
```

computed 有缓存：只有依赖变化时才重新计算。这在处理昂贵计算（如排序、过滤大数组）时很有用。

### 1.4 watch 和 watchEffect

```javascript
import { ref, watch, watchEffect } from 'vue';

const query = ref('');

// watch：明确指定要监听的源
watch(query, (newVal, oldVal) => {
  console.log(`搜索词从 "${oldVal}" 变为 "${newVal}"`);
  fetchResults(newVal);
});

// watchEffect：自动追踪依赖
watchEffect(() => {
  console.log(`当前搜索词: ${query.value}`);
  // query.value 变化时自动重新执行
});
```

watch 和 watchEffect 的区别：watch 需要明确指定源，可以获取新旧值；watchEffect 自动追踪依赖，更简洁但不能获取旧值。

### 1.5 toRef 和 toRefs

```javascript
const state = reactive({ name: 'Alice', age: 25 });

// toRef：创建单个属性的 ref
const nameRef = toRef(state, 'name');

// toRefs：解构所有属性为 ref
const { name, age } = toRefs(state);
```

toRefs 在 composable 中特别有用，让你可以从 reactive 对象中解构属性而不丢失响应性。

---

## 二、生命周期

### 2.1 组合式 API 生命周期

```javascript
import { onMounted, onUpdated, onUnmounted } from 'vue';

// 组件挂载后
onMounted(() => {
  console.log('组件已挂载');
});

// 组件更新后
onUpdated(() => {
  console.log('组件已更新');
});

// 组件卸载前
onUnmounted(() => {
  console.log('组件即将卸载');
});
```

### 2.2 生命周期钩子对照

- `beforeCreate` → 不需要（setup 本身就是）
- `created` → 不需要（setup 本身就是）
- `beforeMount` → `onBeforeMount`
- `mounted` → `onMounted`
- `beforeUpdate` → `onBeforeUpdate`
- `updated` → `onUpdated`
- `beforeUnmount` → `onBeforeUnmount`
- `unmounted` → `onUnmounted`

---

## 三、Composables

### 3.1 什么是 Composable

Composable 是利用 Composition API 封装可复用逻辑的函数。它类似于 React Hooks，但有一些关键区别：没有依赖数组，不需要担心闭包陷阱，可以自由使用 reactive 和 ref。

```javascript
// composables/useCounter.js
import { ref } from 'vue';

export function useCounter(initialValue = 0) {
  const count = ref(initialValue);
  
  function increment() {
    count.value++;
  }
  
  function decrement() {
    count.value--;
  }
  
  function reset() {
    count.value = initialValue;
  }
  
  return {
    count,
    increment,
    decrement,
    reset
  };
}

// 使用
const { count, increment, decrement } = useCounter(10);
```

### 3.2 常用 Composable 模式

**useFetch**：

```javascript
export function useFetch(url) {
  const data = ref(null);
  const error = ref(null);
  const loading = ref(true);

  fetch(url)
    .then(res => res.json())
    .then(json => { data.value = json; })
    .catch(err => { error.value = err; })
    .finally(() => { loading.value = false; });

  return { data, error, loading };
}
```

**useLocalStorage**：

```javascript
export function useLocalStorage(key, defaultValue) {
  const stored = localStorage.getItem(key);
  const data = ref(stored ? JSON.parse(stored) : defaultValue);

  watch(data, (newVal) => {
    localStorage.setItem(key, JSON.stringify(newVal));
  }, { deep: true });

  return data;
}
```

### 3.3 Composables vs Mixins

Composables 相比 Vue 2 的 Mixins 的优势：命名清晰（不会出现属性来源不明的问题）、类型推断更好、不会产生命名冲突、可以返回任意类型。

---

## 四、provide / inject

### 4.1 基本用法

```javascript
// 父组件
import { provide } from 'vue';

provide('theme', 'dark');
provide('user', currentUser);

// 子组件
import { inject } from 'vue';

const theme = inject('theme', 'light');  // 第二个参数是默认值
const user = inject('user');
```

### 4.2 响应式 provide

```javascript
// 父组件
const theme = ref('dark');
provide('theme', theme);

// 子组件
const theme = inject('theme');
// theme.value 是响应式的
```

### 4.3 应用全局配置

```javascript
// app.config.globalProperties
app.config.globalProperties.$theme = 'dark';

// 在组件中
const theme = getCurrentInstance().proxy.$theme;
```

---

## 五、Teleport

Teleport 把组件的 DOM 渲染到指定的目标节点，不受父组件 CSS 的影响。

```vue
<template>
  <button @click="showModal = true">打开弹窗</button>
  
  <Teleport to="body">
    <div v-if="showModal" class="modal-overlay">
      <div class="modal">
        <p>这是一个弹窗</p>
        <button @click="showModal = false">关闭</button>
      </div>
    </div>
  </Teleport>
</template>
```

弹窗、通知、工具提示这些需要突破父组件 overflow:hidden 限制的场景，Teleport 是最佳解决方案。

---

## 六、Suspense

```vue
<template>
  <Suspense>
    <template #default>
      <AsyncComponent />
    </template>
    <template #fallback>
      <Loading />
    </template>
  </Suspense>
</template>
```

Suspense 用于处理异步组件的加载状态。配合 `<script setup>` 中的 async 组件使用。

---

## 七、大型项目架构

### 7.1 目录结构

```
src/
  components/       # 通用组件
  composables/      # 可复用逻辑
  views/            # 页面组件
  router/           # 路由配置
  stores/           # Pinia 状态管理
  utils/            # 工具函数
  types/            # TypeScript 类型
  assets/           # 静态资源
```

### 7.2 组件设计原则

- 单一职责：每个组件只做一件事
- Props 向下，Events 向上
- 用 slots 实现组件内容的灵活定制
- 用 provide/inject 实现深层组件通信
- 用 composable 替代 mixin 做逻辑复用

---

## 八、与 TypeScript 的配合

Vue 3 的 TypeScript 支持比 Vue 2 好得多。`<script setup>` + TypeScript 是推荐的开发方式。

```vue
<script setup lang="ts">
interface Props {
  title: string;
  count?: number;
}

const props = withDefaults(defineProps<Props>(), {
  count: 0
});

const emit = defineEmits<{
  change: [value: number];
}>();
</script>
```

---

## 总结

Vue 3 的 Composition API 不仅仅是语法变化，它带来了更好的逻辑复用、更清晰的代码组织、更好的 TypeScript 支持。掌握 ref vs reactive 的选择、composables 的设计模式、provide/inject 的正确用法，你的 Vue 3 代码质量会有质的提升。
$doc$,
    NULL,
    '/images/covers/vue3-composition-api.jpg',
    '<ul>
<li><a href="#前言">前言</a></li>
<li><a href="#一-响应式系统">一、响应式系统</a></li>
<ul>
<li><a href="#1-1-proxy-vs-defineproperty">1.1 Proxy vs defineProperty</a></li>
<li><a href="#1-2-ref-vs-reactive">1.2 ref vs reactive</a></li>
<li><a href="#1-3-computed">1.3 computed</a></li>
<li><a href="#1-4-watch-和-watcheffect">1.4 watch 和 watchEffect</a></li>
<li><a href="#1-5-toref-和-torefs">1.5 toRef 和 toRefs</a></li>
</ul>
<li><a href="#二-生命周期">二、生命周期</a></li>
<ul>
<li><a href="#2-1-组合式-api-生命周期">2.1 组合式 API 生命周期</a></li>
<li><a href="#2-2-生命周期钩子对照">2.2 生命周期钩子对照</a></li>
</ul>
<li><a href="#三-composables">三、Composables</a></li>
<ul>
<li><a href="#3-1-什么是-composable">3.1 什么是 Composable</a></li>
<li><a href="#3-2-常用-composable-模式">3.2 常用 Composable 模式</a></li>
<li><a href="#3-3-composables-vs-mixins">3.3 Composables vs Mixins</a></li>
</ul>
<li><a href="#四-provide-inject">四、provide / inject</a></li>
<ul>
<li><a href="#4-1-基本用法">4.1 基本用法</a></li>
<li><a href="#4-2-响应式-provide">4.2 响应式 provide</a></li>
<li><a href="#4-3-应用全局配置">4.3 应用全局配置</a></li>
</ul>
<li><a href="#五-teleport">五、Teleport</a></li>
<li><a href="#六-suspense">六、Suspense</a></li>
<li><a href="#七-大型项目架构">七、大型项目架构</a></li>
<ul>
<li><a href="#7-1-目录结构">7.1 目录结构</a></li>
<li><a href="#7-2-组件设计原则">7.2 组件设计原则</a></li>
</ul>
<li><a href="#八-与-typescript-的配合">八、与 TypeScript 的配合</a></li>
<li><a href="#总结">总结</a></li>
</ul>',
    731,
    4,
    'published',
    NOW() - INTERVAL '11 days',
    NOW() - INTERVAL '11 days',
    NOW() - INTERVAL '11 days'
) ON CONFLICT DO NOTHING;
