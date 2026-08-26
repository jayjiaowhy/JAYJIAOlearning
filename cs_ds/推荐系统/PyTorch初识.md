这次我们把 RecFlow 暂时放到第二位，先从**通用 PyTorch 的逻辑**讲起。你现在最需要的不是记住几十个 API，而是建立一个稳定的心智模型：

[  
\boxed{\text{Tensor 数据}  
\rightarrow  
\text{Model 前向计算}  
\rightarrow  
\text{Loss}  
\rightarrow  
\text{Autograd 求梯度}  
\rightarrow  
\text{Optimizer 更新参数}}  
]

这也是 PyTorch 官方入门教程的主线：Tensor → Dataset/DataLoader → Model → Autograd → Optimization → Save/Load。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/intro.html?utm_source=chatgpt.com "Learn the Basics — PyTorch Tutorials 2.13.0+cu130 documentation"))

需要先提醒一点：RecFlow 仓库的 `requirements` 写的是 **PyTorch 1.6**，而我下面参考的是当前 PyTorch 2.13 官方文档。版本跨度很大，但你今天学的这些核心概念——`Tensor`、`Dataset`、`DataLoader`、`nn.Module`、`forward`、autograd、optimizer、`bmm`、`unsqueeze` 等——都属于 PyTorch 的基础机制，足以用来理解 RecFlow 代码。([GitHub](https://github.com/recflow-iclr/recflow?utm_source=chatgpt.com "GitHub - RecFlow-ICLR/RecFlow · GitHub"))

---

# 一、先别管神经网络：PyTorch 到底是什么？

你可以先把 PyTorch 理解成：

> **NumPy + GPU + 自动求导 + 神经网络工具箱。**

这是理解 PyTorch 最好的起点。

假设以前用 NumPy：

```python
import numpy as np

x = np.array([1, 2, 3])
```

PyTorch：

```python
import torch

x = torch.tensor([1, 2, 3])
```

它们看起来很像。

真正区别在于 PyTorch 的 Tensor 可以：

```text
① 做多维数组运算
② 放到 GPU 上运算
③ 记录计算过程
④ 自动计算梯度
⑤ 和神经网络层、优化器无缝配合
```

官方文档也把 Tensor 定义为 PyTorch 中最核心的数据结构，它与 NumPy `ndarray` 很相似，同时支持硬件加速和 automatic differentiation。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/tensorqs_tutorial.html?utm_source=chatgpt.com "Tensors — PyTorch Tutorials 2.13.0+cu130 documentation"))

所以整个 PyTorch，其实可以理解成围绕：

[  
\boxed{\text{Tensor}}  
]

建立起来的一整套机器学习系统。

---

# 二、Tensor：PyTorch 最核心的东西

## 2.1 Tensor 就是“多维数组”

先看最简单的：

```python
x = torch.tensor(3.0)
```

这是一个标量：

```text
3.0
```

shape：

```python
x.shape
# torch.Size([])
```

---

一维：

```python
x = torch.tensor([1, 2, 3])
```

shape：

```text
[3]
```

可以想成一个向量：

$$
x=  
\begin{bmatrix}  
1&2&3  
\end{bmatrix}  $$


---

二维：

```python
x = torch.tensor([
    [1, 2, 3],
    [4, 5, 6]
])
```

shape：

```text
[2,3]
```

可以理解为：

[  
2\times3  
]

矩阵。

---

三维：

```python
x.shape = [32, 50, 64]
```

不要试图“画出三维数组”。

直接给每一个维度一个**语义**：

```text
32 = batch size
50 = sequence length
64 = embedding dimension
```

也就是：

[  
[B,L,D]  
]

这套 thinking 非常重要。

---

# 三、读深度学习源码，shape 比 API 名字重要

假设：

```python
x.shape
```

是：

```text
[128, 50, 64]
```

你应该马上问：

```text
维度 0：128 是什么？
维度 1：50 是什么？
维度 2：64 是什么？
```

推荐系统里经常是：

|符号|一般含义|
|---|---|
|`B`|Batch size，一批有多少样本|
|`L` / `T`|Sequence length，序列长度|
|`D`|Embedding dimension|
|`N`|Negative sample 数量|
|`K`|Candidate 数量|
|`C`|类别数|

于是：

```text
[B]
```

可能是：

> B 个用户各一个 label。

```text
[B,L]
```

可能是：

> B 个用户，每人 L 个历史点击 item ID。

```text
[B,L,D]
```

可能是：

> B 个用户，每人 L 个历史 item，每个 item 变成 D 维 embedding。

```text
[B,N,D]
```

可能是：

> B 个用户，每人 N 个负样本，每个负样本有 D 维 embedding。

以后读 PyTorch 源码，你应该养成一个习惯：

```python
seq        # [B, L]
seq_emb    # [B, L, D]
user_emb   # [B, D]
neg_emb    # [B, N, D]
```

即使原作者没写，你自己也要在脑子里标。

---

# 四、Tensor 有三个非常重要的属性

一个 Tensor 你经常要关注：

```python
x.shape
x.dtype
x.device
```

可以分别理解为：

```text
shape   ：长什么样
dtype   ：里面存什么类型
device  ：放在哪里
```

例如：

```python
x.shape
# torch.Size([32, 50])

x.dtype
# torch.int64

x.device
# cuda:0
```

意思：

> 一个 `[32,50]` 的整数 Tensor，现在放在第 0 块 GPU 上。

---

# 五、dtype：为什么有 float、long？

这是推荐系统里特别常见的问题。

## 浮点数

例如：

```python
torch.float32
```

适合：

```text
模型参数
embedding
logits
概率
loss
```

因为神经网络基本都是实数运算。

例如：

```python
x = torch.tensor([1.2, 3.4])
```

---

## 整数

例如：

```python
torch.int64
```

PyTorch 里经常叫：

```text
Long
LongTensor
```

推荐系统中特别重要，因为：

```text
user_id
video_id
item_id
category_id
```

本质上不是“连续数值”，而是：

> **索引。**

例如：

```python
video_id = 5328
```

不是说这个视频具有“5328的数值大小”。

而是：

> 去 embedding table 找第 5328 行。

所以常见：

```python
video_id.long()
```

或者老代码：

```python
torch.LongTensor(video_id)
```

RecFlow 训练代码就把输入转成 `LongTensor` 后再放到 device 上。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/run_sasrec.py "RecFlow/retrieval/run_sasrec.py at main · RecFlow-ICLR/RecFlow · GitHub"))

---

# 六、device：CPU 和 GPU 是怎么回事？

你以后经常看到：

```python
device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)
```

然后：

```python
model = model.to(device)
x = x.to(device)
```

这只是：

> 把计算对象搬到 GPU 或 CPU。

为什么模型和数据都要搬？

因为不能：

```text
模型参数：GPU
输入数据：CPU
```

然后要求它们相乘。

它们必须在兼容的 device 上。

PyTorch 官方教程也是先选择 accelerator，然后调用 `.to(device)` 将模型和 Tensor 移动过去。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/quickstart_tutorial.html?utm_source=chatgpt.com "Quickstart — PyTorch Tutorials 2.13.0+cu130 documentation"))

所以：

```python
x.to(device)
```

不要神秘化。

就是：

[  
\boxed{\text{把 x 搬过去}}  
]

---

# 七、现在来到 PyTorch 最核心的能力：自动求导

假设我们有一个最简单的模型：

[  
\hat y=wx+b  
]

训练的本质是：

> 找到合适的 (w,b)，使预测 (\hat y) 接近真实 (y)。

例如 loss：

[  
L=(\hat y-y)^2  
]

我们想知道：

[  
$$\frac{\partial L}{\partial w},  
\qquad  
\frac{\partial L}{\partial b}  $$
]

然后更新：

[  
w\leftarrow w-\eta\frac{\partial L}{\partial w}  
]

以前学微积分需要自己求。

PyTorch：

```python
loss.backward()
```

自动算。

这就是：

[  
\boxed{\text{autograd}}  
]

PyTorch 官方将 `torch.autograd` 描述为自动微分引擎，它会根据计算图自动计算 loss 对模型参数的梯度。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/introyt/autogradyt_tutorial.html?utm_source=chatgpt.com "The Fundamentals of Autograd — PyTorch Tutorials 2.13.0+cu130 documentation"))

---

# 八、什么叫“计算图”？

我们来看：

```python
x = torch.tensor(2.0)

w = torch.tensor(
    3.0,
    requires_grad=True
)

y = w * x

loss = (y - 10) ** 2
```

实际计算：

[  
x=2  
]

[  
w=3  
]

于是：

[  
y=wx=6  
]

[  
L=(6-10)^2=16  
]

PyTorch 在运行的时候，不仅算出了 `16`。

它还偷偷记住：

```text
w
 ↓ ×x
y
 ↓ -10
...
 ↓ square
loss
```

所以调用：

```python
loss.backward()
```

它会沿这个图反向算：

[  
$\frac{\partial L}{\partial w}$  
]

这就是 backpropagation。

PyTorch 使用动态计算图：运行过程中发生了哪些 Tensor 运算，就根据这些实际运算建立求导关系。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/introyt/autogradyt_tutorial.html?utm_source=chatgpt.com "The Fundamentals of Autograd — PyTorch Tutorials 2.13.0+cu130 documentation"))

---

# 九、`requires_grad=True` 是什么？

```python
w = torch.tensor(
    3.0,
    requires_grad=True
)
```

意思是：

> PyTorch，请追踪所有与 `w` 有关的计算，我之后可能需要对 `w` 求梯度。

之后：

```python
loss.backward()
```

再看：

```python
w.grad
```

就是：

[  
$\frac{\partial L}{\partial w}$  
]

神经网络中你通常不用自己给每个参数写：

```python
requires_grad=True
```

因为：

```python
nn.Linear
nn.Embedding
```

等模型参数已经由 `nn.Module` 管理好了。

---

# 十、什么是“模型参数”？

假设：

```python
layer = nn.Linear(10, 3)
```

它代表：

[  
y=Wx+b  
]

那么里面有：

[  
W\in R^{3\times10}  
]

和：

[  
$b\in R^3$
]

这些：

```text
W
b
```

就是 trainable parameters。

所以：

```python
model.parameters()
```

可以理解成：

> 把这个模型里所有需要训练的 $(W,b,\text{embedding},\ldots)$ 都拿出来。

然后：

```python
optimizer = torch.optim.Adam(
    model.parameters()
)
```

意思就是：

> Adam，你负责更新这些参数。

PyTorch 的 `nn.Module` 会注册其中的 submodules 和 parameters，因此可以统一移动 device、保存参数，以及交给 optimizer 更新。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.nn.Module.html?utm_source=chatgpt.com "Module — PyTorch 2.13 documentation"))

---

# 十一、`nn.Module` 到底是什么？

绝大多数 PyTorch 模型长这样：

```python
class MyModel(nn.Module):

    def __init__(self):
        super().__init__()

        self.linear1 = nn.Linear(10, 32)
        self.linear2 = nn.Linear(32, 1)

    def forward(self, x):

        x = self.linear1(x)
        x = torch.relu(x)
        x = self.linear2(x)

        return x
```

这有两个核心区域。

---

# 十二、`__init__`：告诉 PyTorch“我有什么”

这里：

```python
self.linear1 = nn.Linear(10, 32)
self.linear2 = nn.Linear(32, 1)
```

相当于定义模型零件：

```text
第一层
第二层
Embedding
Attention
LayerNorm
Dropout
……
```

可以理解成：

> **搭积木。**

但还没告诉数据按照什么顺序走。

---

# 十三、`forward()`：告诉 PyTorch“数据怎么走”

```python
def forward(self, x):

    x = self.linear1(x)
    x = torch.relu(x)
    x = self.linear2(x)

    return x
```

意思：

```text
input
 ↓
Linear
 ↓
ReLU
 ↓
Linear
 ↓
output
```

这才是真正的：

[  
x\rightarrow f(x)  
]

PyTorch 官方的模型构建方式也是：继承 `nn.Module`，在 `__init__` 中定义网络组件，在 `forward()` 中定义输入如何经过这些组件。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/quickstart_tutorial.html?utm_source=chatgpt.com "Quickstart — PyTorch Tutorials 2.13.0+cu130 documentation"))

---

# 十四、为什么写 `model(x)`，而不是 `model.forward(x)`？

你定义：

```python
def forward(self, x):
```

但一般调用：

```python
y = model(x)
```

而不是：

```python
y = model.forward(x)
```

因为 `nn.Module` 自己实现了调用机制。

简单理解：

```text
model(x)
   ↓
PyTorch Module.__call__()
   ↓
forward(x)
```

而 `__call__()` 还会处理 PyTorch 的一些内部机制，比如 hooks。

官方文档明确建议：定义计算逻辑放在 `forward()`，调用模型时使用 `model(x)` 而不是直接调用 `forward()`。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.nn.Module.html?utm_source=chatgpt.com "Module — PyTorch 2.13 documentation"))

所以看到：

```python
logits = model(x)
```

直接翻译：

> 输入 x 经过模型的 forward，得到 logits。

---

# 十五、`logits` 是什么？

这个词会反复出现。

简单来说：

> **logit = 模型直接输出的原始分数。**

例如二分类模型：

```python
logit = 2.3
```

它还不是：

```text
92%概率
```

经过：

```python
sigmoid(logit)
```

才可以转成概率。

多分类模型：

```python
logits.shape = [B, C]
```

例如：

```text
[2.3, -1.1, 0.8]
```

经过 softmax：

```text
[0.78, 0.03, 0.19]
```

推荐系统中也经常把：

[  
u^\top v  
]

这种 user-item matching score 称为：

```text
logit
score
```

---

# 十六、Loss 到底是什么？

模型输出：

```python
prediction
```

但我们需要告诉模型：

> 你预测得好不好？

于是定义：

[  
\boxed{L(\hat y,y)}  
]

也就是 loss。

例如回归：

[  
L=(\hat y-y)^2  
]

分类：

```python
nn.CrossEntropyLoss()
```

推荐排序可能：

[  
-\log\sigma(s^+-s^-)  
]

loss 的本质只有一句话：

> **把模型好坏压缩成一个可以优化的标量。**

训练就是：

[  
\min_\theta L(\theta)  
]

---

# 十七、Optimizer 又是什么？

有了：

[  
$\nabla_\theta L$
]

接下来必须改参数。

最基础的梯度下降：

[  
\theta  
\leftarrow  
\theta-\eta\nabla_\theta L  
]

其中：

[  
\eta  
]

就是 learning rate。

PyTorch 用：

```python
optimizer
```

封装更新规则。

例如：

```python
optimizer = torch.optim.SGD(
    model.parameters(),
    lr=0.01
)
```

或者：

```python
optimizer = torch.optim.Adam(
    model.parameters(),
    lr=0.001
)
```

官方教程把 optimizer 定义为负责根据梯度调整模型参数的对象；常见优化器包括 SGD、Adam 等。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/optimization_tutorial.html?utm_source=chatgpt.com "Optimizing Model Parameters — PyTorch Tutorials 2.13.0+cu130 documentation"))

---

# 十八、终于可以真正理解训练三连了

你以后会无数次看到：

```python
optimizer.zero_grad()
loss.backward()
optimizer.step()
```

它们不是三个“魔法命令”。

分别是：

```text
zero_grad()
    ↓
清除上一次留下的梯度

backward()
    ↓
计算这一次 loss 对参数的梯度

step()
    ↓
根据梯度真正修改参数
```

PyTorch 默认梯度会**累加**，因此典型训练循环中需要清梯度，然后 `backward()` 计算本 batch 梯度，最后 `step()` 更新参数。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/optimization_tutorial.html?utm_source=chatgpt.com "Optimizing Model Parameters — PyTorch Tutorials 2.13.0+cu130 documentation"))

---

# 十九、为什么 `zero_grad()` 必不可少？

假设第一次：

[  
w.grad=3  
]

第二次真正算出来：

[  
2  
]

如果不清：

```text
w.grad = 3 + 2 = 5
```

因为 PyTorch 默认：

[  
grad\leftarrow grad+new_grad  
]

而普通 mini-batch training 通常希望第二个 batch：

```text
只使用第二个 batch 的梯度
```

所以：

```python
optimizer.zero_grad()
```

然后才：

```python
loss.backward()
```

---

# 二十、把训练过程完整地理解一次

一个最典型训练循环：

```python
for x, y in loader:

    x = x.to(device)
    y = y.to(device)

    pred = model(x)

    loss = loss_fn(pred, y)

    optimizer.zero_grad()

    loss.backward()

    optimizer.step()
```

把 PyTorch 全删掉，只剩中文：

```text
拿到一批数据

↓

让模型预测

↓

比较预测值和真实值
得到 loss

↓

清除以前梯度

↓

根据 loss 计算新梯度

↓

更新模型参数

↓

下一批数据
```

实际上机器学习训练到这里就已经讲通了。

---

# 二十一、Epoch 和 Batch 是什么？

假设：

```text
训练集 10000 个样本
```

而：

```python
batch_size = 100
```

那么一次只给模型：

```text
100 个样本
```

所以一整个数据集大概需要：

[  
10000/100=100  
]

个 batch。

完整看完一次训练集：

[  
\boxed{1\ epoch}  
]

于是：

```python
for epoch in range(10):

    for batch in loader:
        ...
```

代表：

> 整个训练集训练 10 遍。

---

# 二十二、Dataset 和 DataLoader 是什么关系？

这是很多初学者第一次看最容易混乱的地方。

PyTorch 官方把它们分成两个对象：

```text
Dataset
    ↓
管理“样本是什么”

DataLoader
    ↓
管理“怎么一批一批取样本”
```

官方教程也是这样定义：`Dataset` 存储样本，而 `DataLoader` 提供围绕 Dataset 的可迭代 batch 访问。([PyTorch Docs](https://docs.pytorch.org/tutorials/beginner/basics/data_tutorial.html?utm_source=chatgpt.com "Datasets & DataLoaders — PyTorch Tutorials 2.13.0+cu130 documentation"))

---

# 二十三、Dataset：定义一个样本是什么

例如：

```python
class MyDataset(Dataset):

    def __len__(self):
        return 10000

    def __getitem__(self, idx):

        x = ...
        y = ...

        return x, y
```

其中：

```python
dataset[17]
```

本质会执行：

```python
dataset.__getitem__(17)
```

然后返回：

```text
第17个样本
```

例如：

```python
(image, label)
```

或者推荐系统：

```python
(user_history, positive_item, negative_items)
```

所以：

[  
$\boxed{__getitem__\text{ 决定一个 sample 长什么样}}$  
]

这句话非常重要。

---

# 二十四、DataLoader：把 sample 组成 batch

如果：

```python
dataset[0]
```

返回：

```python
x.shape = [10]
y.shape = []
```

那么：

```python
loader = DataLoader(
    dataset,
    batch_size=32
)
```

通常取出来：

```python
for x, y in loader:
```

会得到：

```text
x.shape = [32,10]
y.shape = [32]
```

也就是说：

```text
单样本
[10]

↓

32 个样本堆在一起

↓

[32,10]
```

这就是 batching。

所以你以后经常会发现：

```text
Dataset.__getitem__ 中没有 B
```

但是：

```text
model.forward 中突然出现 B
```

因为：

[  
\boxed{\text{DataLoader 把 batch 维加上去了}}  
]

---

# 二十五、Dataset、DataLoader、Model 的职责一定要分开

你可以这样理解：

```text
Dataset：
“第 i 个样本到底是什么？”

DataLoader：
“每次拿多少个？要不要 shuffle？怎么并行加载？”

Model：
“拿到这批样本后怎么算？”

Loss：
“怎么算做错多少？”

Optimizer：
“怎么改参数？”
```

这是 PyTorch 项目最基本的软件结构。

---

# 二十六、为什么 Dataset 里通常不写模型计算？

因为应该分工。

例如：

```text
dataset.py
负责读取文件、采样、padding

model.py
负责神经网络

train.py
负责训练循环
```

这样更容易修改。

比如你以后研究负采样：

> 很可能主要改 Dataset / sampling。

而不是重写整个 SASRec。

---

# 二十七、`model.train()` 与 `model.eval()` 到底是什么？

训练：

```python
model.train()
```

测试：

```python
model.eval()
```

你可能会误以为：

```text
train() = 开始训练
eval() = 开始预测
```

严格来说不是。

它们只是：

> **切换某些 layer 的工作模式。**

例如：

```text
Dropout
BatchNorm
```

在 training 和 evaluation 时行为不同。

官方文档明确说明，`eval()` 相当于 `train(False)`，会影响 Dropout、BatchNorm 等依赖训练模式的模块，而不是“关闭梯度”。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.nn.Module.html?utm_source=chatgpt.com "Module — PyTorch 2.13 documentation"))

因此：

```python
model.eval()
```

不会自动：

```text
禁止梯度计算
```

---

# 二十八、那 `torch.no_grad()` 是什么？

```python
with torch.no_grad():

    pred = model(x)
```

意思：

> 这一段只做 forward，不记录用于 backward 的梯度计算过程。

为什么测试时有用？

因为：

```text
不需要 backward
→ 不需要保存那么多中间计算
→ 更省显存
```

官方定义中，`torch.no_grad()` 会关闭 gradient calculation，典型用途就是 inference，并可减少本来用于梯度计算的内存消耗。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.no_grad.html?highlight=no_grad&utm_source=chatgpt.com "no_grad — PyTorch 2.7 documentation"))

所以标准 evaluation 经常：

```python
model.eval()

with torch.no_grad():
    pred = model(x)
```

两个解决的问题不同：

```text
model.eval()
→ 改模型行为

torch.no_grad()
→ 不建立 backward 所需的梯度记录
```

---

# 二十九、下面开始补“能读源码”的 Tensor 操作

前面的东西是 PyTorch 框架。

接下来这些：

```text
unsqueeze
squeeze
reshape/view
transpose
repeat_interleave
bmm
gt
```

是：

> **Tensor shape 操作。**

这部分不能死记，要用 shape 理解。

---

# 三十、先搞懂 `dim`

假设：

```python
x.shape = [32, 50, 64]
```

我们可以编号：

```text
dim=0   dim=1   dim=2
  ↓       ↓       ↓
 32      50      64
```

负数：

```text
dim=-1
```

就是最后一个维度：

```text
64
```

```text
dim=-2
```

就是：

```text
50
```

所以看到：

```python
torch.sum(x, dim=1)
```

如果：

```text
[B,L,D]
```

就是：

> 沿 L 这一维求和。

结果：

```text
[B,D]
```

---

# 三十一、`unsqueeze`：插一个大小为 1 的维度

这是一定要搞懂的。

假设：

```python
x.shape = [B, D]
```

执行：

```python
x.unsqueeze(1)
```

变成：

```text
[B,1,D]
```

执行：

```python
x.unsqueeze(-1)
```

变成：

```text
[B,D,1]
```

官方定义也非常直接：`unsqueeze` 在指定位置插入一个 size=1 的维度。([PyTorch Docs](https://docs.pytorch.org/docs/2.9/generated/torch.unsqueeze.html?utm_source=chatgpt.com "torch.unsqueeze — PyTorch 2.9 documentation"))

例如：

```python
x = torch.tensor([1,2,3])
```

shape：

```text
[3]
```

那么：

```python
x.unsqueeze(0)
```

：

```text
[[1,2,3]]

shape = [1,3]
```

而：

```python
x.unsqueeze(1)
```

：

```text
[[1],
 [2],
 [3]]

shape = [3,1]
```

数字没有变。

只是：

[  
\boxed{\text{改变观察数据的维度结构}}  
]

---

# 三十二、为什么要插一个“没什么用的 1”？

因为矩阵运算和 broadcasting 经常需要 shape 对齐。

假设：

```text
user_emb = [B,D]
```

但你需要：

```text
[B,1,D]
```

去和：

```text
[B,D,N]
```

做 batch matrix multiplication。

于是：

```python
user_emb.unsqueeze(1)
```

就解决了。

因此 `unsqueeze` 很多时候不是“增加信息”。

而是：

> **为了让后面的矩阵运算 shape 合法。**

---

# 三十三、`squeeze` 就反过来

假设：

```text
[B,1,N]
```

执行：

```python
x.squeeze(1)
```

得到：

```text
[B,N]
```

就是删除 size=1 的 dimension。

官方文档定义也是删除指定的 size-1 维。([PyTorch Docs](https://docs.pytorch.org/docs/main/generated/torch.squeeze.html?utm_source=chatgpt.com "torch.squeeze — PyTorch main documentation"))

不过实践中：

```python
x.squeeze()
```

要稍微小心。

因为它会删掉**所有大小为 1 的维度**。

如果：

```text
batch_size = 1
```

可能把 batch 维也删了。

所以代码更稳妥时常写：

```python
x.squeeze(-1)
```

明确指出删哪一维。

---

# 三十四、`reshape()` / `view()`

它们最直观的用途：

> 重新组织 shape。

例如：

```text
x.shape = [4,3]
```

里面一共：

[  
4\times3=12  
]

个元素。

可以：

```python
x.reshape(2,6)
```

变：

```text
[2,6]
```

元素还是 12 个。

也可以：

```python
x.reshape(-1)
```

变成：

```text
[12]
```

其中：

```text
-1
```

表示：

> 这一个维度 PyTorch 自己推算。

例如：

```python
x.reshape(4, -1)
```

总共 12 个元素，所以自动得到：

```text
[4,3]
```

---

# 三十五、`transpose`

假设：

```text
x.shape = [B,N,D]
```

执行：

```python
x.transpose(1, 2)
```

就是交换：

```text
N 和 D
```

得到：

```text
[B,D,N]
```

为什么推荐模型里很常见？

因为本来有：

```text
N 个 item embedding
[B,N,D]
```

如果用户向量：

```text
[B,1,D]
```

要做矩阵乘法，需要：

```text
[B,1,D]
@
[B,D,N]
```

所以把：

```text
[B,N,D]
```

转成：

```text
[B,D,N]
```

---

# 三十六、`bmm` 是什么？

`bmm`：

```python
torch.bmm(A, B)
```

全名：

> batch matrix multiplication。

普通矩阵：

 $$
[n,m]\times[m,p]  
\rightarrow[n,p]  
]$$

而 bmm：

[  
[B,n,m]\times[B,m,p]  
\rightarrow[B,n,p]  
]

官方定义也是：两个三维 Tensor 做 batch matrix-matrix product；如果输入分别是 `(b,n,m)` 和 `(b,m,p)`，结果就是 `(b,n,p)`。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.bmm.html?utm_source=chatgpt.com "torch.bmm — PyTorch 2.13 documentation"))

---

# 三十七、用一个具体例子理解 bmm

有：

```text
32 个用户
```

每个用户一个：

```text
64维向量
```

所以：

```text
user_emb
[32,64]
```

每个用户有：

```text
100 个 candidate item
```

每个 item：

```text
64维
```

所以：

```text
item_emb
[32,100,64]
```

我们想对每个用户计算：

[  
$$u^\top v_1,,  
u^\top v_2,,  
\dots,,  
u^\top v_{100} $$ 
]

先：

```python
user_emb.unsqueeze(1)
```

：

```text
[32,1,64]
```

item：

```python
item_emb.transpose(1,2)
```

：

```text
[32,64,100]
```

然后：

```python
torch.bmm(
    user_emb.unsqueeze(1),
    item_emb.transpose(1,2)
)
```

shape：

[  
[32,1,64]\times[32,64,100]  
]

变：

```text
[32,1,100]
```

`squeeze(1)`：

```text
[32,100]
```

含义：

> 32 个用户 × 每个用户 100 个 candidate score。

这就是推荐系统中非常典型的计算。

---

# 三十八、`repeat_interleave`

假设：

```python
x = torch.tensor([10,20,30])
```

执行：

```python
x.repeat_interleave(2)
```

得到：

```text
[10,10,20,20,30,30]
```

官方文档也是这个定义：逐元素重复；它和 `repeat()` 是不同操作。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.repeat_interleave.html?utm_source=chatgpt.com "torch.repeat_interleave — PyTorch 2.13 documentation"))

为什么推荐系统会用？

假设：

```text
B = 3
```

三个用户 positive score：

```text
[5.0, 3.0, 4.0]
```

而每个 positive 对应：

```text
N = 2
```

个 negative。

你想比较：

```text
用户1：positive vs neg1
用户1：positive vs neg2

用户2：positive vs neg1
用户2：positive vs neg2

用户3：positive vs neg1
用户3：positive vs neg2
```

所以 positive 要变成：

```text
[5,5,3,3,4,4]
```

这就是：

```python
positive.repeat_interleave(2)
```

---

# 三十九、`torch.gt`

这个就简单得多。

```python
torch.gt(a, b)
```

就是：

```python
a > b
```

而且是逐元素比较。

例如：

```python
a = torch.tensor([3,1,5])
b = torch.tensor([2,2,5])

torch.gt(a,b)
```

得到：

```text
[True, False, False]
```

官方定义就是 element-wise `input > other`，输出布尔 Tensor，而且两个 Tensor 可以通过 broadcasting 配合。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.gt.html?utm_source=chatgpt.com "torch.gt — PyTorch 2.13 documentation"))

---

# 四十、真正需要理解的是 Broadcasting

这一块如果懂了，很多 PyTorch 代码突然就不神秘了。

假设：

```text
A.shape = [32,50,64]
B.shape = [64]
```

执行：

```python
A + B
```

PyTorch 可以自动理解成：

```text
[32,50,64]
+
[      64]
```

把 B 视作：

```text
[1,1,64]
```

然后自动扩展：

```text
[32,50,64]
```

所以你不需要真的复制 32×50 次。

---

# 四十一、再看一个非常重要的 broadcasting

有：

```text
mask
[B,L]
```

但是 embedding：

```text
[B,L,D]
```

你想：

```text
一个位置 mask=0
→ 这个位置整条 D 维 embedding 都变 0
```

那么：

```python
mask.unsqueeze(-1)
```

变：

```text
[B,L,1]
```

于是：

```text
[B,L,D]
*
[B,L,1]
```

PyTorch 会把最后：

```text
1
```

broadcast 成：

```text
D
```

于是一个：

```text
mask=0
```

就可以乘掉整个：

```text
D维 embedding
```

这就是 `unsqueeze(-1)` 在序列模型里特别常见的原因。

---

# 四十二、`nn.Embedding`：推荐系统必须真正理解

这是 RecFlow 中非常重要的通用 PyTorch 知识。

假设：

```python
embedding = nn.Embedding(
    num_embeddings=10000,
    embedding_dim=64
)
```

实际上就是维护一个：

[  
E\in R^{10000\times64}  
]

的参数矩阵。

可以想成：

```text
item_id      embedding

0       →  [64维向量]
1       →  [64维向量]
2       →  [64维向量]
...
9999    →  [64维向量]
```

如果输入：

```python
ids.shape = [32]
```

那么：

```python
embedding(ids)
```

输出：

```text
[32,64]
```

---

如果输入：

```text
[32,50]
```

输出：

```text
[32,50,64]
```

所以记住这个规则：

[  
\boxed{  
[\ldots]  
\xrightarrow{\text{Embedding}}  
[\ldots,D]  
}  
]

也就是：

> 原来的 ID shape 不动，在最后附加 embedding dimension。

---

# 四十三、为什么推荐系统特别依赖 Embedding？

因为：

```text
video_id = 13527
```

本身没意义。

我们希望模型学习：

```text
video 13527
→ [0.27, -0.83, ..., 0.14]
```

这个向量逐渐编码：

```text
内容偏好
用户兴趣
item similarity
协同过滤信息
……
```

然后：

[  
u^\top v  
]

就可以表示：

> user 和 item 的匹配程度。

---

# 四十四、`nn.Linear`

```python
nn.Linear(64, 32)
```

表示：

[  
y=Wx+b  
]

把最后一维：

```text
64
```

变：

```text
32
```

例如：

```text
[B,64]
```

→

```text
[B,32]
```

甚至：

```text
[B,L,64]
```

也可以变：

```text
[B,L,32]
```

因为 Linear 主要作用于最后一维。

所以看：

```python
nn.Linear(128,1)
```

往往可以读：

> 把 128 维 feature 压成一个 score。

---

# 四十五、ReLU、Sigmoid、Softmax 今天需要懂到什么程度？

ReLU：

[  
ReLU(x)=\max(0,x)  
]

作用：

> 提供非线性。

---

Sigmoid：

[  
\sigma(x)=\frac1{1+e^{-x}}  
]

把实数压到：

[  
(0,1)  
]

经常用于：

```text
binary probability
pairwise ranking
```

---

Softmax：

把一组 logits：

```text
[2.1, 0.7, -1.2]
```

变成和为 1 的权重：

```text
[p1, p2, p3]
```

经常用于：

```text
多分类
Attention weight
```

你现在暂时不需要研究数值稳定性等细节。

---

# 四十六、现在用一个最简单的通用 PyTorch 项目贯穿一遍

假设我们做二分类。

数据：

```text
每个人有 10 个 feature
预测 0 / 1
```

模型：

```python
class SimpleModel(nn.Module):

    def __init__(self):
        super().__init__()

        self.linear1 = nn.Linear(10, 32)
        self.linear2 = nn.Linear(32, 1)

    def forward(self, x):

        x = self.linear1(x)
        x = torch.relu(x)
        x = self.linear2(x)

        return x
```

输入：

```text
x
[B,10]
```

第一层：

```text
[B,10]
→
[B,32]
```

ReLU：

```text
[B,32]
→
[B,32]
```

第二层：

```text
[B,32]
→
[B,1]
```

输出 logits：

```text
[B,1]
```

---

# 四十七、训练循环再看

```python
model = SimpleModel().to(device)

optimizer = torch.optim.Adam(
    model.parameters(),
    lr=1e-3
)

for x, y in loader:

    x = x.to(device)
    y = y.to(device)

    logits = model(x)

    loss = loss_fn(logits, y)

    optimizer.zero_grad()

    loss.backward()

    optimizer.step()
```

现在你应该把它理解成：

```text
model(x)
=
做 forward prediction

loss_fn
=
衡量预测错误

zero_grad
=
清旧梯度

backward
=
算新梯度

step
=
改参数
```

这就是 PyTorch 的核心。

---

# 四十八、现在再回头看 RecFlow，你会发现它没那么特殊

RecFlow retrieval baseline 的训练文件就是典型的 PyTorch workflow。

仓库中首先构造：

```text
Dataset
↓
DataLoader
↓
SASRec
↓
Adam
↓
training loop
```

训练循环里从 DataLoader 取 batch，转成 Tensor 并移动到 device，然后调用模型得到正负样本 logits，构造 pairwise loss，接着 `zero_grad → backward → step`。这和我们上面讲的通用 PyTorch 训练流程完全一样。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/run_sasrec.py "RecFlow/retrieval/run_sasrec.py at main · RecFlow-ICLR/RecFlow · GitHub"))

也就是说：

[  
\boxed{\text{RecFlow 并没有发明一套特殊的 PyTorch}}  
]

它只是把：

```text
x
y
```

换成：

```text
历史序列
positive video
negative videos
```

而已。

---

# 四十九、用 Dataset 的知识重新看 RecFlow

RecFlow 的 retrieval Dataset 继承：

```python
Dataset
```

然后 `__getitem__()` 返回的大致结构是：

```text
sequence
sequence mask
positive video
negative videos
```

仓库中 baseline 的 `__getitem__()` 最后返回四个对象，而 hard-negative 版本仍返回相同的四类对象，只是 negative videos 的构造方法变成 random negatives 加 stage negatives；FSLTR 版本则返回 sequence、mask、candidate videos 和 priority。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/dataset.py "RecFlow/retrieval/dataset.py at main · RecFlow-ICLR/RecFlow · GitHub"))

这个例子可以很好地理解：

> **Dataset 决定模型每次究竟吃什么数据。**

---

# 五十、用 shape 的知识重新看 SASRec

RecFlow SASRec 中大致有：

```text
seq       [B,T]
tgt_vid   [B]
neg_vids  [B,N]
```

经过 video embedding：

```text
seq_emb   [B,T,D]
tgt_emb   [B,D]
neg_emb   [B,N,D]
```

代码随后给 sequence embedding 加 position embedding，用 `unsqueeze(-1)` 构造 mask；经过 attention 和 feed-forward 后取最后一个时刻形成 `[B,D]` 的 user representation，然后分别计算 positive 和 negatives 的匹配分数。源码中的 shape 注释基本就沿着这条链走。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/models.py "RecFlow/retrieval/models.py at main · RecFlow-ICLR/RecFlow · GitHub"))

你现在不用完全懂 SASRec。

你只要发现：

[  
[B,T]  
\rightarrow  
[B,T,D]  
\rightarrow  
[B,D]  
]

这实际上就是：

```text
ID序列
↓
Embedding
↓
序列模型
↓
用户向量
```

---

# 五十一、现在 RecFlow 中的 `bmm` 就很自然了

源码里：

```text
final_state
[B,D]
```

negative embedding：

```text
neg_emb
[B,N,D]
```

作者希望计算：

[  
u^\top v_1,\dots,u^\top v_N  
]

所以：

```text
[B,D]
→ unsqueeze
[B,1,D]
```

而：

```text
[B,N,D]
→ transpose
[B,D,N]
```

然后：

[  
[B,1,D]  
\times  
[B,D,N]  
\rightarrow  
[B,1,N]  
]

最后 squeeze：

```text
[B,N]
```

这正是 RecFlow `torch.bmm(...)` 那行代码在干的事情。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/models.py "RecFlow/retrieval/models.py at main · RecFlow-ICLR/RecFlow · GitHub"))

你看，现在根本不需要“背 bmm”。

只要：

[  
\boxed{\text{跟 shape}}  
]

---

# 五十二、RecFlow 的 `repeat_interleave` 为什么出现？

baseline 中：

```text
positive score
[B]
```

而每个用户有：

```text
N negatives
```

所以 negative scores 最终有：

```text
[B×N]
```

为了让每个 positive 与自己的 N 个 negative 比较，需要：

```text
[B]
```

变成：

```text
[B×N]
```

于是用：

```python
repeat_interleave(N)
```

RecFlow baseline 训练代码正是这样构造正样本 logits，再计算正负分数差。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/run_sasrec.py "RecFlow/retrieval/run_sasrec.py at main · RecFlow-ICLR/RecFlow · GitHub"))

数学上对应：

[  
s^+-s^-_1  
]

[  
s^+-s^-_2  
]

[  
\cdots  
]

[  
s^+-s^-_N  
]

---

# 五十三、现在再解释你之前最难理解的 FSLTR `unsqueeze + gt`

这里先完全不讲 RecFlow。

假设：

```python
priority = torch.tensor([
    [6, 4, 2]
])
```

shape：

```text
[1,3]
```

我们想构造：

[  
priority_i>priority_j  
]

的两两比较矩阵。

---

先：

```python
priority.unsqueeze(-1)
```

shape：

```text
[1,3,1]
```

可以想象：

```text
[
  [
    [6],
    [4],
    [2]
  ]
]
```

然后：

```python
priority.unsqueeze(1)
```

shape：

```text
[1,1,3]
```

大致：

```text
[
  [
    [6,4,2]
  ]
]
```

现在做：

```python
torch.gt(
    priority.unsqueeze(-1),
    priority.unsqueeze(1)
)
```

由于 broadcasting：

```text
[1,3,1]
>
[1,1,3]
```

得到：

```text
[1,3,3]
```

实际就是：

```text
        6      4      2

6     6>6    6>4    6>2
4     4>6    4>4    4>2
2     2>6    2>4    2>2
```

结果：

```text
False True  True
False False True
False False False
```

这就是：

[  
\boxed{\text{pairwise comparison matrix}}  
]

`torch.gt` 本身只是逐元素大于比较；真正巧妙的是 `unsqueeze` 加 broadcasting，把一个 `[B,K]` 向量变成了 `[B,K,K]` 的两两比较矩阵。([PyTorch Docs](https://docs.pytorch.org/docs/stable/generated/torch.gt.html?utm_source=chatgpt.com "torch.gt — PyTorch 2.13 documentation"))

而 RecFlow 的 FSLTR 代码正是用 `priority.unsqueeze(-1)`、`priority.unsqueeze(1)` 和 `torch.gt` 构造这个 pairwise priority mask，同时对 logits 做同样的两两差值。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/run_sasrec_fsltr.py "RecFlow/retrieval/run_sasrec_fsltr.py at main · RecFlow-ICLR/RecFlow · GitHub"))

所以：

[  
priority_i>priority_j  
]

对应要求：

[  
score_i>score_j  
]

这才是那几行代码的本质。

---

# 五十四、你目前其实不需要系统学完 PyTorch

PyTorch 官方完整教程还会涉及：

```text
Transforms
CNN
RNN
Distributed training
AMP
torch.compile
custom autograd
deployment
……
```

你现在完全不需要。

你现在真正应该形成的是下面这张“源码翻译表”：

|看到代码|脑中翻译|
|---|---|
|`Tensor`|多维数据|
|`.shape`|每个维度是什么|
|`.to(device)`|搬到 CPU/GPU|
|`.long()`|转整数索引|
|`.float()`|转浮点计算|
|`Dataset`|一个 sample 怎么构造|
|`__getitem__`|第 i 个 sample 返回什么|
|`DataLoader`|sample 拼 batch|
|`nn.Module`|模型|
|`__init__`|定义模型有哪些组件|
|`forward`|数据怎么经过模型|
|`model(x)`|执行 forward|
|`nn.Embedding`|ID → D维向量|
|`nn.Linear`|线性变换|
|`logits`|模型原始分数|
|`loss`|模型错多少|
|`optimizer`|参数怎么更新|
|`zero_grad()`|清旧梯度|
|`backward()`|自动求梯度|
|`step()`|修改参数|
|`train()`|训练模式|
|`eval()`|evaluation 模式|
|`no_grad()`|不记录梯度|
|`unsqueeze`|插入 size=1 维|
|`squeeze`|删除 size=1 维|
|`reshape/view`|重排 shape|
|`transpose`|交换维度|
|`repeat_interleave`|每个元素重复|
|`bmm`|batch 矩阵乘法|
|`gt`|逐元素 `>`|

---

# 五十五、最后给你一个读 PyTorch 源码最有效的方法

以后不要看到：

```python
neg_logits = torch.bmm(
    final_state.unsqueeze(1),
    neg_emb.transpose(2,1)
).squeeze()
```

就问：

> “`bmm` API 到底是什么意思？”

正确读法应该是连续问：

1. `final_state.shape` 是什么？
    
2. `unsqueeze(1)` 后是什么？
    
3. `neg_emb.shape` 是什么？
    
4. `transpose(2,1)` 后是什么？
    
5. 两个矩阵为什么可以乘？
    
6. 输出 shape 是什么？
    
7. 这个输出在业务上代表什么？
    

例如：

```text
user
[B,D]

↓ unsqueeze

[B,1,D]


negative items
[B,N,D]

↓ transpose

[B,D,N]


bmm

[B,1,D] @ [B,D,N]

↓

[B,1,N]

↓

[B,N]
```

然后最后一句：

> **每个用户对 N 个 negative item 的打分。**

做到这一步，才叫“读懂源码”。

而不是“知道 `torch.bmm` 是 batch matrix multiplication”。

---

# 你这阶段学习 PyTorch 的正确边界

你现在至少要真正吃透下面这一个链条：

[  
\boxed{  
\text{Dataset}  
\rightarrow  
\text{DataLoader}  
\rightarrow  
\text{Tensor}  
\rightarrow  
\text{Model.forward}  
\rightarrow  
\text{logits}  
\rightarrow  
\text{loss}  
\rightarrow  
\text{backward}  
\rightarrow  
\text{optimizer.step}  
}  
]

其次一定要养成：

[  
\boxed{\text{任何 Tensor 操作都追 shape}}  
]

的习惯。

至于 `unsqueeze`、`bmm`、`repeat_interleave`、`gt`，它们不是另一门知识，只是在这条主线里面用于**调整 Tensor shape、完成矩阵计算和构造比较关系**的工具。

如果把这次讲解和 RecFlow 对照起来，你现在最值得自己动手做的是：拿 `retrieval/run_sasrec.py` 的训练循环，只给每个变量写 shape，不研究 SASRec 内部 Attention；然后再进入 `models.py`，从 `seq [B,T]` 一直追到 `tgt_logits [B]` 和 `neg_logits [BN]`。RecFlow 源码本身已经给其中不少 Tensor 标了 shape，是一个很适合练这套方法的仓库。([GitHub](https://github.com/RecFlow-ICLR/RecFlow/blob/main/retrieval/run_sasrec.py "RecFlow/retrieval/run_sasrec.py at main · RecFlow-ICLR/RecFlow · GitHub"))

[PyTorch 官方 Learn the Basics](https://docs.pytorch.org/tutorials/beginner/basics/intro.html?utm_source=chatgpt.com)  
[RecFlow GitHub 仓库](https://github.com/RecFlow-ICLR/RecFlow?utm_source=chatgpt.com)