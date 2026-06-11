INSERT INTO posts (author_id, title, slug, summary, content_md, content_html, status, published_at, created_at, updated_at)
VALUES
(
    1,
    '常用数据结构与算法实战',
    'algorithms-practice-guide',
    '从排序到图论，从动态规划到回溯，覆盖 20+ 种常用算法的原理、实现、复杂度分析和 LeetCode 经典题解。',
    $doc$
# 常用数据结构与算法实战

## 前言

学算法不是为了刷题，是为了在面对问题时能想到高效的解决方案。我见过太多项目因为用了 O(n²) 的算法导致性能瓶颈，最后花几天时间重写成 O(n log n) 的版本。如果开发者脑子里没有算法这根弦，遇到性能问题根本不会往这个方向想。

这篇文章不追求算法的数学证明，重点放在每种算法的核心思想、适用场景和实际实现。

---

## 一、排序算法

### 1.1 快速排序

快速排序是实际应用中最常用的排序算法。核心思想：选一个基准值，把数组分成小于和大于基准值的两部分，递归排序。

```python
def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)
```

平均时间复杂度 O(n log n)，最坏 O(n²)。随机选择基准值可以避免最坏情况。

### 1.2 归并排序

归并排序是稳定的排序算法。核心思想：把数组分成两半，递归排序，然后合并。

```python
def mergesort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = mergesort(arr[:mid])
    right = mergesort(arr[mid:])
    return merge(left, right)

def merge(left, right):
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result
```

时间复杂度稳定 O(n log n)，但需要 O(n) 额外空间。

### 1.3 堆排序

堆排序利用堆数据结构实现排序。适合需要原地排序且空间受限的场景。

### 1.4 排序算法对比

| 算法 | 平均时间 | 最坏时间 | 空间 | 稳定性 |
|------|---------|---------|------|--------|
| 快速排序 | O(n log n) | O(n²) | O(log n) | 不稳定 |
| 归并排序 | O(n log n) | O(n log n) | O(n) | 稳定 |
| 堆排序 | O(n log n) | O(n log n) | O(1) | 不稳定 |
| 插入排序 | O(n²) | O(n²) | O(1) | 稳定 |

---

## 二、查找算法

### 2.1 二分查找

二分查找的前提是数组有序。每次比较中间元素，将搜索范围缩小一半。

```python
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1
```

时间复杂度 O(log n)。变体：查找第一个/最后一个等于目标值的位置、查找第一个大于等于目标值的位置。

### 2.2 哈希表

哈希表提供 O(1) 的平均查找时间。核心是哈希函数和冲突解决。

冲突解决方法：链地址法（Java HashMap）、开放寻址法（Python dict）。

---

## 三、数据结构

### 3.1 栈

栈是后进先出（LIFO）的数据结构。

应用场景：函数调用栈、表达式求值、括号匹配、浏览器前进/后退。

### 3.2 队列

队列是先进先出（FIFO）的数据结构。

变体：双端队列（deque）、优先队列（priority queue，基于堆实现）。

### 3.3 链表

链表是动态数据结构，插入和删除操作的时间复杂度是 O(1)。

```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next
```

链表的经典问题：反转链表、检测环、合并两个有序链表、找中间节点。

### 3.4 树

二叉搜索树（BST）：左子树所有节点值小于根节点，右子树所有节点值大于根节点。查找、插入、删除的平均时间复杂度是 O(log n)。

平衡二叉树（AVL、红黑树）：保证树的高度是 O(log n)，避免退化成链表。

### 3.5 图

图的表示方式：邻接矩阵、邻接表。

图的遍历：BFS（广度优先搜索，按层遍历）、DFS（深度优先搜索，沿一条路径走到底再回溯）。

---

## 四、经典算法

### 4.1 动态规划

动态规划的核心：把大问题分解成子问题，存储子问题的结果避免重复计算。

适用条件：最优子结构、重叠子问题。

经典问题：爬楼梯、最大子数组和、编辑距离、背包问题、最长公共子序列。

### 4.2 贪心算法

贪心算法每一步都选择当前看起来最优的选项。不一定能得到全局最优解，但在某些问题上能保证最优。

经典问题：活动选择、霍夫曼编码、Dijkstra 最短路径。

### 4.3 回溯

回溯是一种系统地搜索解空间的方法。在每一步做出选择，如果不满足条件就撤销选择。

经典问题：N 皇后、数独求解、全排列、组合总和。

### 4.4 分治

分治把问题分成若干个规模较小的子问题，递归求解，然后合并结果。归并排序和快速排序都是分治的典型应用。

---

## 五、复杂度分析

### 5.1 时间复杂度

常见的时间复杂度从低到高：O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)。

### 5.2 空间复杂度

除了算法本身需要的额外空间，还要考虑递归调用的栈空间。快速排序的空间复杂度是 O(log n)（递归栈），归并排序是 O(n)（合并用的临时数组）。

---

## 六、LeetCode 经典题

### 6.1 两数之和（HashMap）

```python
def twoSum(nums, target):
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
```

### 6.2 最大子数组和（动态规划）

```python
def maxSubArray(nums):
    max_sum = current_sum = nums[0]
    for num in nums[1:]:
        current_sum = max(num, current_sum + num)
        max_sum = max(max_sum, current_sum)
    return max_sum
```

### 6.3 反转链表（迭代）

```python
def reverseList(head):
    prev = None
    current = head
    while current:
        next_temp = current.next
        current.next = prev
        prev = current
        current = next_temp
    return prev
```

---

## 总结

算法学习是一个持续的过程。不需要背诵所有算法的模板，但要理解每种算法的核心思想和适用场景。遇到问题时，先分析时间复杂度需求，再选择合适的算法。
$doc$,
    NULL,
    'published',
    NOW() - INTERVAL '9 days',
    NOW() - INTERVAL '9 days',
    NOW() - INTERVAL '9 days'
) ON CONFLICT DO NOTHING;
