# Python 程序设计学习讲义

> 依据《Python 程序设计》课程课件整理，并补充现代 Python 执行模型、环境管理、基础语法、工程实践与数据科学学习路线。
>
> 标记说明：
>
> - **【课件内容】**：沿用课件的知识路线与核心结论。
> - **【拓展知识】**：为帮助真正理解和实践而补充的内容。

---

## 0. 先看全局：我们到底要学什么

Python 学习不只是记住 `if`、`for` 和几个函数。更完整的知识链是：

```text
计算机硬件
  ↓
操作系统与软件环境
  ↓
Python 解释器与第三方库
  ↓
Python 语法、数据结构与程序设计
  ↓
调试、测试、版本管理
  ↓
数据分析 / 自动化 / Web / 机器学习
```

**【课件内容】** 本课程的目标包括：掌握 Python 基础语法、控制语句、函数、模块、数据结构、文件读写、异常处理和面向对象编程；学习 NumPy、Pandas、Matplotlib；最终能够进行数据采集、清洗、分析和可视化。

**【拓展知识】** 学习时应同时培养三种能力：

1. **语言能力**：能读懂和写出 Python 代码。
2. **计算思维**：能把现实问题拆成输入、处理、输出和边界情况。
3. **工程能力**：会管理环境、阅读报错、调试、测试、使用 Git，并能让代码被别人复现。

---

# 第一部分　计算机、软件与程序

## 1. 计算机组成：程序运行的物理基础

### 1.1 五类硬件

**【课件内容｜第 8 页】** 计算机硬件可概括为五类：

| 硬件 | 主要作用 | 直观类比 |
|---|---|---|
| CPU | 读取并执行指令，完成计算 | 大脑、计算工人 |
| 内存 RAM | 暂存正在运行的程序和数据 | 工作台 |
| 硬盘 / SSD | 长期保存程序、数据和文件 | 仓库 |
| 输入设备 | 把外部信息送入计算机 | 键盘、鼠标、摄像头 |
| 输出设备 | 把处理结果呈现给外界 | 显示器、打印机 |

运行下面的程序时：

```python
scores = [88, 92, 95]
average = sum(scores) / len(scores)
print(average)
```

可以把过程粗略理解为：

```text
硬盘上的 .py 文件
        ↓ 读取
内存中的代码和 scores 对象
        ↓ CPU 执行指令
内存中的 average 结果
        ↓ 操作系统提供输出服务
显示器显示 91.666...
```

### 1.2 内存、磁盘与显存不要混淆

**【拓展知识】**

- 文件保存在磁盘上，不等于数据已经进入程序。
- `open()`、`pandas.read_csv()` 等操作把磁盘数据读入内存。
- 机器学习中，张量还可能从内存复制到 GPU 显存。

```python
import pandas as pd

df = pd.read_csv("sales.csv")  # 磁盘文件 → 内存中的 DataFrame
```

在 PyTorch 中常见：

```python
tensor = tensor.to("cuda")     # 内存 → GPU 显存
```

如果数据大于可用内存，就可能非常慢甚至崩溃。因此数据科学不仅关心代码正确，也关心数据规模和资源限制。

---

## 2. 软件层次：谁在为谁提供服务

**【课件内容｜第 9 页】** 课件将软件环境分为操作系统、系统软件和应用软件：

```text
用户
 ↓
应用软件
 ↓
系统软件
 ↓
操作系统
 ↓
硬件
```

- **操作系统**：管理 CPU、内存、磁盘、进程和设备，并为上层软件提供接口。
- **系统软件**：为其他软件运行提供条件，例如命令解释器、编译器、链接器、装载器。
- **应用软件**：直接解决用户问题，例如浏览器、数据分析工具和管理系统。

对 Python 学习者，更实用的层次是：

```text
你的 Python 程序
        ↓
NumPy / Pandas / Matplotlib / PyTorch
        ↓
Python 解释器（常见为 CPython）
        ↓
Windows / Linux / macOS
        ↓
CPU / 内存 / GPU / 磁盘
```

**【拓展知识】** `print("Hello")` 并不是 Python 代码直接控制显示器。Python 解释器会执行 `print`，再通过操作系统的标准输出机制显示文字。

---

## 3. 什么是计算机编程

**【课件内容｜第 10 页】** 编程的本质是编写一系列指令，指导计算机完成特定任务。机器语言接近 CPU，执行直接但难以编写；高级语言更接近人的表达，再由编译器或解释器转换。

一个程序通常可以抽象为：

```text
输入 → 数据表示 → 算法 / 规则 → 输出
```

例如计算及格人数：

```python
scores = [56, 78, 92, 45, 66]
passed = 0

for score in scores:
    if score >= 60:
        passed += 1

print("及格人数：", passed)
```

这里：

- 输入：`scores`
- 数据表示：整数构成的列表
- 算法：逐个判断是否大于等于 60
- 输出：及格人数

**【拓展知识】** 真正写程序前，可以先问四个问题：

1. 输入是什么，类型和范围是什么？
2. 期望输出是什么？
3. 正常过程如何分解成步骤？
4. 空输入、错误输入、除零、文件不存在等边界情况怎么办？

---

## 4. 编译与解释：不要停留在“逐行执行”

### 4.1 课件中的入门模型

**【课件内容｜第 10 页】**

| 方式 | 入门理解 | 典型示例 |
|---|---|---|
| 编译 | 先整体转换为机器代码，再执行 | C、C++ |
| 解释 | 由解释器在运行时处理并执行 | Python、脚本语言 |

这个模型便于入门，但现实中的语言实现经常同时包含编译与解释。

### 4.2 CPython 的实际执行模型

**【拓展知识】** 我们平时从 Python 官网安装的实现通常是 **CPython**。它大致经历：

```text
源代码 main.py
    ↓ 词法与语法分析
抽象语法树 AST
    ↓ 编译
Python 字节码
    ↓ Python 虚拟机执行
程序结果
```

所以 Python 并非“完全不编译”。它通常先编译成与具体 CPU 无关的字节码，再由 Python 虚拟机执行。

可以观察函数的字节码：

```python
import dis

def add(a, b):
    return a + b

dis.dis(add)
```

导入模块时，Python 还可能在 `__pycache__` 中保存 `.pyc` 字节码缓存，以便下次更快加载。缓存不是独立应用程序，通常仍需兼容的 Python 解释器。

### 4.3 “语言”和“语言实现”不是一回事

**【拓展知识】**

- **Python**：语言规范与生态的统称。
- **CPython**：使用 C 编写的主流 Python 实现。
- **PyPy**：带即时编译等优化的另一种实现。
- **MicroPython**：面向微控制器和嵌入式设备。

因此，“Python 慢”是过度简化的说法。实际性能取决于实现、算法、库以及耗时部分是否由 C/C++、Fortran、CUDA 等底层代码完成。NumPy 的向量化计算通常比纯 Python 循环快很多。

---

## 5. 程序如何运行

### 5.1 通用程序运行过程

**【课件内容｜第 11 页】** 对典型编译型程序，过程包括：

1. 源代码写入磁盘文件。
2. 编译器把源代码转换为目标代码。
3. 链接器把目标代码和所需库连接成装入模块或可执行程序。
4. 装载器把程序加载到内存，操作系统创建进程。
5. 程序接收输入、执行计算并产生输出。

### 5.2 运行 Python 文件时发生什么

**【拓展知识】** 执行：

```powershell
python main.py
```

大致意味着：

1. 命令行根据 `PATH` 找到一个 Python 可执行文件。
2. 操作系统启动 Python 进程。
3. 解释器读取 `main.py`。
4. 代码被解析、编译为字节码并执行。
5. 进程访问文件、网络等资源时，请求操作系统服务。
6. 程序结束，操作系统回收进程占用的大部分资源。

### 5.3 进程、线程和程序

**【拓展知识】**

- **程序**：磁盘上的代码和资源，是静态的。
- **进程**：程序的一次运行，是动态的，有自己的内存空间和系统资源。
- **线程**：进程中的执行路径，一个进程可以有多个线程。

同一个 `main.py` 可以同时启动两次，形成两个进程。

---

# 第二部分　Python 语言与开发环境

## 6. Python 的特点和应用

### 6.1 主要特点

**【课件内容｜第 12 页】**

- 语法重视可读性和一致性。
- 开发效率高，通常能用较少代码完成任务。
- 具有跨平台能力。
- 标准库与第三方库丰富。
- 支持面向对象、函数式等多种编程风格。
- 能与 C、C++、Java 等语言或组件集成。

Python 使用缩进表示代码块：

```python
temperature = 32

if temperature >= 30:
    print("天气较热")
else:
    print("温度适中")
```

建议统一使用 **4 个空格**，不要混用 Tab 和空格。

### 6.2 应用领域

**【课件内容｜第 17 页】** Python 常用于：

- 数据分析与可视化
- 科学计算与数值分析
- 机器学习与人工智能
- Web 开发
- 自动化与系统脚本
- 网络数据采集
- 图形界面和原型开发
- 教育与研究

**【拓展知识】** Python 不是所有场景的最佳选择。例如对极低延迟、强实时或资源极受限的系统，C/C++、Rust 等可能更合适。选语言要看问题、团队、生态和性能约束，而不是只看排行榜。

课件介绍 TIOBE 指数时也强调：语言热度排行榜反映搜索和关注度，不等于“最佳语言”或代码量排名。

---

## 7. Python 环境搭建：解释器、PATH 与虚拟环境

### 7.1 运行环境与开发环境

**【课件内容｜第 18-19 页】**

- **运行环境**：运行 Python 程序所需的解释器和库。
- **开发环境**：帮助编写、运行、调试代码的工具，例如 VS Code、PyCharm、IPython。
- 应使用仍受支持的 Python 3，Python 2 已停止维护。

解释器和 IDE 不是同一个东西：

```text
IDE / 编辑器：你写代码、点运行、设断点的界面
Python 解释器：真正执行代码的程序
```

IDE 中“选择解释器”的目的，就是告诉 IDE：运行按钮应该调用哪个 Python。

### 7.2 PATH 是什么

**【课件内容】** 安装 Python 时可以选择将其加入 `PATH`，从而在命令行中直接使用 `python`。

**【拓展知识】** `PATH` 是操作系统用于搜索可执行文件的一组目录。当你输入：

```powershell
python --version
```

系统会按 `PATH` 的顺序寻找名为 `python` 的程序。电脑上有多个 Python 时，最常见的问题不是“没安装”，而是“当前找到的不是你以为的那个”。

Windows 中可检查：

```powershell
where.exe python
python -c "import sys; print(sys.executable)"
```

第二条输出的是当前实际使用的解释器路径。

### 7.3 为什么需要虚拟环境

**【拓展知识】** 不同项目可能依赖不同版本：

```text
项目 A：Python 3.x + pandas 某版本
项目 B：Python 3.x + pandas 另一版本
```

如果所有包都装进同一个全局环境，升级一个项目可能破坏另一个项目。虚拟环境为项目隔离解释器和依赖。

#### 使用 venv

```powershell
python -m venv .venv
```

Windows PowerShell 激活：

```powershell
.\.venv\Scripts\Activate.ps1
```

安装包：

```powershell
python -m pip install numpy pandas matplotlib
```

退出环境：

```powershell
deactivate
```

推荐写 `python -m pip`，因为它明确表示“使用当前这个 Python 所对应的 pip”。

### 7.4 pip、conda 和 venv 的分工

| 工具 | 主要作用 | 适合场景 |
|---|---|---|
| `pip` | 安装 Python 包 | 几乎所有 Python 项目 |
| `venv` | 创建轻量级 Python 虚拟环境 | 通用开发、依赖较简单 |
| `conda` | 管理环境、Python 版本及部分非 Python 二进制依赖 | 数据科学、科学计算、复杂依赖 |

使用 conda 的基本流程：

```powershell
conda create -n ds python=3.12
conda activate ds
conda install numpy pandas matplotlib
```

一个实用原则：优先保持环境简单；在同一环境混用 `conda` 和 `pip` 时，先用 conda 安装主要依赖，再用 pip 补充 conda 没有的包，并记录安装过程。

---

## 8. IDE、Anaconda 与 Jupyter

### 8.1 VS Code 与 PyCharm

**【课件内容｜第 19-20 页】**

- **PyCharm**：面向 Python 的完整 IDE，项目、解释器、运行和调试功能集中。
- **VS Code**：轻量、扩展丰富，需要安装 Python 扩展并选择解释器。

初学者配置完成后至少应确认：

1. 编辑器右下角或设置中显示的是目标 Python 环境。
2. 终端中 `sys.executable` 与 IDE 选择一致。
3. `import` 的包确实安装在该环境。

### 8.2 Anaconda

**【课件内容｜第 21 页】** Anaconda 是面向科学计算的 Python 发行版，包含 conda、常用数据科学包和 Navigator，可创建相互独立的环境。

**【拓展知识】** Anaconda、Miniconda 与 Python 官网版本可以这样理解：

- Python 官网版：基础、直接，搭配 `venv + pip`。
- Miniconda：只提供较精简的 conda 基础环境，按需安装。
- Anaconda：预装内容较多，开箱即用，但占用空间也更大。

安装策略应与课程、项目和磁盘空间匹配。一般不需要同时把多个发行版都加入 PATH。

### 8.3 Jupyter Notebook / JupyterLab

**【课件内容｜第 22 页】** Jupyter 是基于浏览器的交互式编程环境。代码写在单元格中，按 `Shift + Enter` 执行并显示结果。

```python
print("Hello, World!")
```

**【拓展知识】** Notebook 的优势是代码、解释、表格和图形可以放在一起，非常适合探索分析和教学；风险是单元格可以乱序运行，导致“页面看起来相同，结果却依赖之前的隐藏状态”。

建议：

- 从上到下组织单元格。
- 交付前执行“重启内核并全部运行”。
- 把可复用函数放进 `.py` 模块。
- 注意 Notebook 的内核也对应一个具体 Python 环境。

---

# 第三部分　Python 编程基础

## 9. 变量、对象与引用

### 9.1 变量不是盒子，而是名字

**【拓展知识】** 在 Python 中，更准确的模型是：变量名引用对象。

```python
x = 10
y = x
x = 20

print(y)  # 10
```

执行 `y = x` 时，`y` 引用了当时的整数对象 `10`；随后 `x = 20` 只是让 `x` 改为引用另一个对象。

### 9.2 可变对象与不可变对象

常见不可变类型：`int`、`float`、`bool`、`str`、`tuple`。

常见可变类型：`list`、`dict`、`set`。

```python
a = [1, 2]
b = a
b.append(3)

print(a)  # [1, 2, 3]
```

`a` 和 `b` 引用同一个列表，所以通过 `b` 修改后，`a` 看到的对象也变了。如果需要浅复制：

```python
b = a.copy()
```

`==` 比较值是否相等，`is` 比较是否为同一个对象。判断空值应写：

```python
if result is None:
    print("没有结果")
```

---

## 10. 基础类型与类型转换

| 类型 | 示例 | 用途 |
|---|---|---|
| `int` | `42` | 整数 |
| `float` | `3.14` | 浮点数 |
| `bool` | `True`、`False` | 逻辑判断 |
| `str` | `"Python"` | 文本 |
| `NoneType` | `None` | 表示缺失或暂无结果 |

```python
age_text = input("请输入年龄：")  # input 返回字符串
age = int(age_text)
print(age + 1)
```

常见运算：

```python
7 + 3    # 10
7 - 3    # 4
7 * 3    # 21
7 / 3    # 2.333... 真除法
7 // 3   # 2，整除
7 % 3    # 1，取余
7 ** 3   # 343，幂
```

字符串支持格式化：

```python
name = "小林"
score = 92.5
print(f"{name} 的成绩是 {score:.1f}")
```

浮点数采用有限精度表示，不应假设所有小数都能被精确存储：

```python
print(0.1 + 0.2)  # 可能显示 0.30000000000000004
```

需要比较时可使用 `math.isclose()`；货币等场景可了解 `decimal.Decimal`。

---

## 11. 控制流：让程序作出选择并重复工作

### 11.1 条件判断

```python
score = 85

if score >= 90:
    level = "优秀"
elif score >= 60:
    level = "及格"
else:
    level = "不及格"

print(level)
```

常用比较与逻辑运算符：

```python
age >= 18
score != 0
60 <= score < 90
is_student and age < 25
weekend or holiday
not finished
```

### 11.2 for 循环

```python
total = 0

for number in [1, 2, 3, 4]:
    total += number

print(total)
```

需要索引时：

```python
names = ["甲", "乙", "丙"]

for index, name in enumerate(names, start=1):
    print(index, name)
```

### 11.3 while 循环

```python
count = 3

while count > 0:
    print(count)
    count -= 1
```

- `break`：立即退出当前循环。
- `continue`：跳过本轮剩余代码，进入下一轮。

必须确保 `while` 的条件最终可能变为假，或者存在可达的 `break`，否则会形成死循环。

---

## 12. 函数：把问题拆成可复用的小模块

```python
def calculate_average(scores):
    """返回成绩列表的平均值；空列表返回 None。"""
    if not scores:
        return None
    return sum(scores) / len(scores)


result = calculate_average([80, 90, 100])
print(result)
```

函数包含：

- 函数名
- 参数
- 函数体
- 返回值
- 可选的文档字符串

**【拓展知识】** `print()` 是显示信息，`return` 是把结果交回调用者。不要把两者混为一谈。

```python
def add_bad(a, b):
    print(a + b)       # 只显示，调用者拿不到结果


def add_good(a, b):
    return a + b       # 可继续参与计算
```

可以添加类型标注帮助阅读和工具检查：

```python
def area(width: float, height: float) -> float:
    return width * height
```

类型标注通常不会自动强制运行时类型，它首先是一种文档和静态检查信息。

---

## 13. 容器：组织一组数据

### 13.1 列表 list

有序、可变，可保存重复元素。

```python
scores = [88, 92, 75]
scores.append(95)
scores[0] = 90
print(scores[1:3])
```

列表推导式：

```python
squares = [x * x for x in range(1, 6)]
even_squares = [x * x for x in range(1, 11) if x % 2 == 0]
```

### 13.2 元组 tuple

有序、不可变，适合表达结构固定的记录。

```python
point = (3, 5)
x, y = point
```

### 13.3 字典 dict

按键查找值，适合有字段名的数据。

```python
student = {"name": "小周", "score": 91}
student["passed"] = student["score"] >= 60

for key, value in student.items():
    print(key, value)
```

### 13.4 集合 set

元素不重复，适合去重和集合运算。

```python
course_a = {"甲", "乙", "丙"}
course_b = {"乙", "丙", "丁"}

print(course_a & course_b)  # 交集
print(course_a | course_b)  # 并集
print(course_a - course_b)  # 差集
```

### 13.5 如何选择

| 需求 | 推荐容器 |
|---|---|
| 保持顺序、频繁增删 | `list` |
| 固定的一组值 | `tuple` |
| 按字段名或键快速查找 | `dict` |
| 去重、集合关系 | `set` |

---

## 14. 异常处理：对可预期的失败作出响应

异常不是语法错误，而是程序运行到某处时出现的异常情况。

```python
try:
    age = int(input("请输入年龄："))
except ValueError:
    print("年龄必须是整数")
else:
    print(f"明年你将 {age + 1} 岁")
finally:
    print("输入流程结束")
```

- `try`：可能失败的代码。
- `except`：处理指定异常。
- `else`：没有异常时执行。
- `finally`：无论是否异常都执行，常用于释放资源。

不要随意写：

```python
try:
    risky_operation()
except:
    pass
```

它会吞掉真实错误，使调试更困难。应捕获具体异常，并保留足够信息。

---

## 15. 模块、包与程序入口

### 15.1 import 做了什么

```python
import math

print(math.sqrt(16))
```

模块可以理解为可被导入的 Python 文件；包是用于组织相关模块的结构。`import` 会查找、加载并执行模块的顶层代码，然后把模块对象绑定到当前名字。

常见写法：

```python
import statistics
from pathlib import Path
import pandas as pd
```

避免 `from module import *`，因为它会污染命名空间，使名字来源不清楚。

### 15.2 `__name__ == "__main__"`

```python
def main():
    print("程序开始")


if __name__ == "__main__":
    main()
```

当文件被直接运行时，`__name__` 为 `"__main__"`；当它被其他文件导入时，`__name__` 通常是模块名。这样可以避免“仅用于直接运行的代码”在导入时自动执行。

---

## 16. 文件读写：让数据跨越程序生命周期

### 16.1 文本文件

```python
from pathlib import Path

path = Path("notes.txt")
path.write_text("第一行\n第二行\n", encoding="utf-8")
content = path.read_text(encoding="utf-8")
print(content)
```

也可以使用 `with`，它会在代码块结束时自动关闭文件：

```python
with open("notes.txt", "r", encoding="utf-8") as file:
    for line in file:
        print(line.rstrip())
```

### 16.2 JSON 与 CSV

```python
import json

student = {"name": "小周", "score": 91}

with open("student.json", "w", encoding="utf-8") as file:
    json.dump(student, file, ensure_ascii=False, indent=2)
```

数据科学中 CSV 很常见，但它不保存完整的数据类型信息，并且可能遇到编码、分隔符、缺失值等问题。读取后应主动检查列名、类型和缺失情况。

---

## 17. 面向对象编程 OOP

对象把数据和相关行为组织在一起。

```python
class Student:
    def __init__(self, name, scores):
        self.name = name
        self.scores = scores

    def average(self):
        if not self.scores:
            return None
        return sum(self.scores) / len(self.scores)


student = Student("小周", [88, 92, 95])
print(student.name)
print(student.average())
```

核心概念：

- **类**：对象的结构与行为定义。
- **实例**：根据类创建的具体对象。
- **属性**：对象保存的数据。
- **方法**：对象可执行的行为。
- **封装**：把相关数据和操作放在一起。
- **继承**：在已有类基础上扩展。
- **多态**：不同对象以共同接口响应同一操作。

**【拓展知识】** 不要为了“显得高级”而把所有代码写成类。简单的数据转换函数往往更清楚。是否使用 OOP，取决于问题中是否存在有状态、有行为、需要协作的对象。

---

# 第四部分　课件中的两个编程练习

## 18. 练习一：猜数字小游戏

### 18.1 课件目标

**【课件内容｜第 23 页】** 计算机随机生成 1 到 100 的整数，用户不断猜测，程序提示“太大”或“太小”，直到猜对。

这个练习综合了：模块导入、变量、输入、类型转换、`while`、`if / elif / else` 和 `break`。

### 18.2 基础版本

```python
import random

number = random.randint(1, 100)
print("我想了一个 1 到 100 之间的整数，来猜一猜吧！")

while True:
    guess = int(input("请输入你的猜测："))

    if guess < number:
        print("太小了，再试试！")
    elif guess > number:
        print("太大了，再试试！")
    else:
        print("恭喜你，猜对了！")
        break
```

### 18.3 健壮版本

**【拓展知识】** 用户可能输入字母、空字符串或范围外数字，应进行验证：

```python
import random


def read_guess():
    while True:
        raw = input("请输入 1 到 100 的整数：").strip()
        try:
            guess = int(raw)
        except ValueError:
            print("输入无效，请输入整数。")
            continue

        if 1 <= guess <= 100:
            return guess

        print("数字必须在 1 到 100 之间。")


def main():
    target = random.randint(1, 100)
    attempts = 0

    while True:
        guess = read_guess()
        attempts += 1

        if guess < target:
            print("太小了。")
        elif guess > target:
            print("太大了。")
        else:
            print(f"猜对了！你一共猜了 {attempts} 次。")
            break


if __name__ == "__main__":
    main()
```

可继续扩展：限制次数、设置难度、记录最佳成绩、允许重新开始。

---

## 19. 练习二：随机整数除法与异常处理

### 19.1 课件目标

**【课件内容｜第 24 页】** 生成一组 0 到 10 的随机整数，对相邻数字做除法；遇到除数为零时捕获 `ZeroDivisionError`，并用打印信息观察执行过程。

```python
import random


def divide_numbers(a, b):
    try:
        result = a / b
    except ZeroDivisionError:
        print("Error: Division by zero is not allowed.")
        result = None
    return result


def main():
    numbers = [random.randint(0, 10) for _ in range(10)]
    print("Generated numbers:", numbers)

    for i in range(len(numbers) - 1):
        a = numbers[i]
        b = numbers[i + 1]
        print(f"Dividing {a} by {b}...")

        result = divide_numbers(a, b)
        if result is not None:
            print(f"Result: {result}\n")
        else:
            print("Skipping invalid division.\n")


if __name__ == "__main__":
    main()
```

### 19.2 逐段理解

```python
numbers = [random.randint(0, 10) for _ in range(10)]
```

这是列表推导式。`_` 表示循环变量本身不需要使用，共生成 10 个随机整数。

```python
for i in range(len(numbers) - 1):
```

最后一个可用索引是 `len(numbers) - 1`，但循环体还会访问 `numbers[i + 1]`，所以 `i` 最大只能到 `len(numbers) - 2`。

更直接的相邻配对方式是：

```python
for a, b in zip(numbers, numbers[1:]):
    print(a, b)
```

### 19.3 设计选择：返回 None 还是抛出异常

**【拓展知识】** 课件版本在函数内部捕获异常并返回 `None`，适合教学展示。工程代码中还可以让异常传播，由更上层决定如何处理：

```python
def divide_numbers(a, b):
    return a / b


try:
    result = divide_numbers(10, 0)
except ZeroDivisionError:
    print("当前记录无效，已跳过")
```

两种方式都可能合理，关键是明确函数契约：失败时返回什么，或者会抛出什么异常。

---

# 第五部分　调试、规范与工程实践

## 20. 调试：从“猜问题”变成“找证据”

**【课件内容｜第 25 页】** 课件展示了在 JupyterLab 中调试。调试的核心不是盯着代码看，而是观察程序状态如何变化。

### 20.1 三类常见错误

1. **语法错误**：代码无法被解析，例如漏掉冒号。
2. **运行时异常**：运行到某一步失败，例如除零、索引越界。
3. **逻辑错误**：程序能运行但结果不对，通常最难发现。

### 20.2 阅读 traceback

```python
numbers = [10, 20]
print(numbers[2])
```

会产生 `IndexError`。阅读报错时从最后一行开始：

- 异常类型是什么？
- 错误信息说了什么？
- 最后一个属于自己代码的文件和行号在哪里？
- 该行使用的变量当时是什么值？

### 20.3 调试方法

- 缩小问题：构造最小可复现示例。
- 打印关键变量、类型和形状。
- 使用 IDE 断点、单步执行和变量面板。
- 用 `assert` 写下必须成立的条件。
- 写自动化测试防止问题再次出现。

```python
def average(values):
    assert len(values) > 0, "values 不能为空"
    return sum(values) / len(values)
```

`assert` 适合开发期内部检查，不应代替面向用户的输入验证。

### 20.4 数据科学中的调试清单

```python
print(df.shape)
print(df.columns)
print(df.dtypes)
print(df.head())
print(df.isna().sum())
```

很多“模型问题”实际来自：标签错位、数据泄漏、类别编码错误、训练集与测试集预处理不一致、数组维度不符合预期。

---

## 21. 代码规范、测试与 Git

### 21.1 基本规范

- 使用有意义的名字：`total_price` 优于 `tp`。
- 函数只承担相对清晰的职责。
- 对“为什么这样做”写注释，不要逐字重复代码。
- 保持稳定的格式，了解 PEP 8。
- 不把密码、密钥和个人数据直接写进代码仓库。

### 21.2 最小测试意识

```python
def is_even(number):
    return number % 2 == 0


assert is_even(2) is True
assert is_even(3) is False
assert is_even(0) is True
```

测试应覆盖：正常情况、边界情况和错误情况。

### 21.3 Git 与 GitHub

**【课件内容｜第 27 页】** GitHub 是重要的开源代码托管平台。

**【拓展知识】** Git 是版本控制工具，GitHub 是托管 Git 仓库与协作的平台。最小工作流：

```text
修改文件 → 查看差异 → 暂存 → 提交 → 推送到远程仓库
```

一个项目建议至少包含：

```text
project/
├─ README.md
├─ requirements.txt 或 environment.yml
├─ src/
├─ tests/
├─ notebooks/
└─ data/               # 大数据通常不直接提交
```

README 应说明项目目的、环境安装、运行方法、数据来源和主要结果。

---

## 22. LeetCode、GitHub 与 Kaggle 应该怎么用

### 22.1 LeetCode

**【课件内容｜第 26 页】** LeetCode 提供从易到难的算法与数据结构练习。

建议顺序：数组与字符串 → 哈希表 → 栈与队列 → 双指针 → 二分查找 → 递归与树 → 图与动态规划。

做题重点不是背答案，而是：

1. 先写清输入、输出和边界。
2. 写出能工作的简单解法。
3. 分析时间复杂度和空间复杂度。
4. 再学习更优思路并独立重写。

### 22.2 GitHub

不要只“收藏项目”。尝试阅读 README、运行示例、定位入口文件、修改一个小功能、提交清晰的 commit。阅读成熟代码可以学习项目结构、命名、测试和文档。

### 22.3 Kaggle

**【课件内容｜第 28 页】** Kaggle 提供数据集、Notebook、比赛和数据科学社区资源。

初学路线：

1. 选择结构化表格数据集。
2. 完成数据字典和探索性分析。
3. 建立简单基线模型。
4. 使用可靠的验证方法。
5. 做特征工程与误差分析。
6. 写一份可复现的分析报告。

不要只追排行榜分数。验证集设计、数据泄漏检查和解释结果通常比盲目堆模型更重要。

---

# 第六部分　数据科学三件套

## 23. NumPy：高效的数值数组

NumPy 的核心是同质、多维数组 `ndarray`。

```python
import numpy as np

scores = np.array([80, 90, 100])
print(scores.mean())
print(scores >= 90)
print(scores[scores >= 90])
```

向量化计算：

```python
prices = np.array([10.0, 20.0, 30.0])
discounted = prices * 0.9
```

相比逐个写 Python 循环，数组运算通常更简洁，并能调用高效底层实现。

关键概念：

- `shape`：数组各维度大小。
- `dtype`：元素类型。
- `axis`：沿哪个维度操作。
- 广播：不同形状数组在满足规则时自动对齐运算。

```python
matrix = np.array([[1, 2, 3], [4, 5, 6]])
print(matrix.shape)        # (2, 3)
print(matrix.mean(axis=0)) # 每列平均
```

---

## 24. Pandas：表格数据处理

Pandas 的核心结构：

- `Series`：带索引的一维数据。
- `DataFrame`：带行列标签的二维表格。

```python
import pandas as pd

df = pd.DataFrame({
    "name": ["甲", "乙", "丙"],
    "score": [88, 95, None],
    "class": [1, 1, 2],
})

print(df.head())
print(df.info())
print(df["score"].mean())
```

典型数据处理链：

```python
result = (
    df.dropna(subset=["score"])
      .assign(passed=lambda x: x["score"] >= 60)
      .groupby("class", as_index=False)
      .agg(avg_score=("score", "mean"),
           pass_rate=("passed", "mean"))
)
```

需要重点掌握：选择与过滤、缺失值、类型转换、去重、排序、分组聚合、连接合并、透视表、时间序列。

每次处理数据后都应验证行数、主键、缺失情况和字段类型，而不是只看前五行。

---

## 25. Matplotlib：把数据变成图形

```python
import matplotlib.pyplot as plt

months = ["Jan", "Feb", "Mar", "Apr"]
sales = [12, 18, 15, 24]

fig, ax = plt.subplots(figsize=(7, 4))
ax.plot(months, sales, marker="o")
ax.set_title("Monthly Sales")
ax.set_xlabel("Month")
ax.set_ylabel("Sales")
ax.grid(alpha=0.3)
fig.tight_layout()
plt.show()
```

图表选择：

| 目的 | 常见图形 |
|---|---|
| 比较类别大小 | 条形图 |
| 观察时间趋势 | 折线图 |
| 观察分布 | 直方图、箱线图 |
| 观察两个变量关系 | 散点图 |
| 表示组成 | 堆叠图；饼图应谨慎使用 |

好图表应有明确标题、坐标含义、单位、合理尺度和必要的数据来源。装饰不能代替信息。

---

# 第七部分　面向数据科学与机器学习的后续路线

## 26. 推荐学习路线

### 阶段 1：打牢 Python 基础

目标：能独立完成小型命令行程序。

- 基础类型、表达式、输入输出
- 条件和循环
- 函数与作用域
- 列表、元组、字典、集合
- 异常、文件、模块
- 基础 OOP

练习项目：记账程序、成绩分析、文本词频统计、文件批量整理。

### 阶段 2：建立工程习惯

目标：代码可运行、可调试、可复现。

- 虚拟环境与依赖管理
- IDE 调试器、日志与 traceback
- Git 和 GitHub
- 代码格式、类型标注、测试
- README 与项目结构

### 阶段 3：数据分析

目标：完成从原始数据到结论和图表的闭环。

- NumPy 数组与向量化
- Pandas 清洗、合并、聚合
- Matplotlib / Seaborn 可视化
- 描述统计与探索性数据分析
- SQL 基础

练习项目：选择一个公开数据集，完成数据字典、质量检查、分析问题、图表、结论和局限性。

### 阶段 4：机器学习基础

目标：理解模型为何有效、如何可靠评估，而不只是会调用接口。

- 监督学习与无监督学习
- 特征、标签、训练集、验证集、测试集
- 回归、分类、聚类
- 过拟合、正则化、偏差与方差
- 指标选择和交叉验证
- 数据泄漏与可复现性
- scikit-learn Pipeline

```python
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

model = Pipeline([
    ("imputer", SimpleImputer()),
    ("scaler", StandardScaler()),
    ("classifier", LogisticRegression()),
])
```

### 阶段 5：选择方向深入

- 深度学习：PyTorch、神经网络、GPU 训练。
- 自然语言处理：文本表示、Transformer、语言模型。
- 计算机视觉：图像处理、卷积网络、视觉 Transformer。
- 数据工程：数据库、ETL、工作流、分布式计算。
- 后端与部署：API、Docker、监控、模型服务。

---

## 27. 与大模型协作，但不放弃自己的判断

**【课件内容】** 课程强调处理好实践与大模型的关系。

可以让大模型帮助：

- 解释报错和概念。
- 生成最小示例。
- 提出测试用例。
- 比较不同实现。
- 审查代码的可读性和潜在风险。

但需要自己验证：

1. 代码能否在当前环境运行？
2. 输出是否满足题意？
3. 边界情况是否覆盖？
4. 库和接口是否真实存在、版本是否匹配？
5. 是否泄漏隐私、密码或敏感数据？
6. 自己能否逐行解释代码？

最有效的提问方式通常包括：目标、输入示例、期望输出、当前代码、完整报错、运行环境和已经尝试的方法。

---

# 第八部分　复习与实践

## 28. 本章知识地图

```text
计算机组成
├─ CPU：执行指令
├─ 内存：保存运行时数据
├─ 磁盘：长期保存文件
└─ 输入 / 输出：连接外部世界

软件层次
├─ 操作系统：管理资源
├─ 系统软件：提供运行和开发条件
└─ 应用软件：解决用户问题

Python 运行
├─ 源代码
├─ CPython 编译为字节码
├─ Python 虚拟机执行
└─ 操作系统调度硬件资源

开发环境
├─ Python 解释器
├─ PATH
├─ venv / conda
├─ pip
└─ VS Code / PyCharm / Jupyter

程序设计
├─ 类型、变量、对象、引用
├─ 条件与循环
├─ 函数与模块
├─ 列表、元组、字典、集合
├─ 异常与文件
└─ 面向对象

数据科学
├─ NumPy：数值数组
├─ Pandas：表格数据
├─ Matplotlib：可视化
└─ 机器学习：建模与评估
```

## 29. 自测题

1. CPU、内存和磁盘的职责有什么区别？
2. Python 解释器和 IDE 是什么关系？
3. 输入 `python main.py` 后，操作系统和解释器分别做了什么？
4. 为什么说 Python 既有编译过程，也有解释执行过程？
5. `PATH` 配错时可能出现什么现象？
6. `pip`、`venv` 和 `conda` 分别解决什么问题？
7. `a = b` 对列表意味着什么？为什么修改 `b` 可能影响 `a`？
8. `==` 与 `is` 有什么区别？
9. `print` 与 `return` 有什么区别？
10. 列表、元组、字典和集合各适合什么场景？
11. 为什么应捕获具体异常，而不是使用空的 `except`？
12. `if __name__ == "__main__":` 有什么作用？
13. Notebook 为什么可能出现运行顺序导致的隐藏状态问题？
14. 机器学习中为什么必须区分训练集、验证集和测试集？
15. 大模型生成的代码至少要做哪些验证？

## 30. 综合练习

### 练习 A：学生成绩分析器

要求：

1. 从 CSV 读取姓名、班级和成绩。
2. 检查缺失值和非法成绩。
3. 计算每班平均分、最高分、最低分和及格率。
4. 绘制班级平均分条形图。
5. 将汇总结果保存为新的 CSV。
6. 使用函数拆分读取、清洗、统计、绘图和保存步骤。
7. 对文件不存在、列缺失和成绩无法转换等情况给出清楚提示。

### 练习 B：可复现的 Kaggle 入门项目

要求：

1. 选择一个结构化表格数据集。
2. 建立数据字典并描述预测目标。
3. 划分训练集和验证集。
4. 用简单模型建立基线。
5. 选择与问题匹配的评价指标。
6. 使用 Pipeline 防止预处理泄漏。
7. 分析错误案例，不只报告一个分数。
8. 在 GitHub 仓库中提供 README、依赖文件和运行说明。

---

## 结语

Python 的语法门槛不高，但真正的能力来自持续完成“理解问题 → 设计数据与步骤 → 编写代码 → 验证结果 → 调试改进 → 清楚表达”的完整循环。

先把基础语法和两个课件练习真正写熟，再用一个完整数据项目串联 NumPy、Pandas、Matplotlib、Git 和机器学习。这样学到的不是零散命令，而是一套可以迁移到新问题上的解决方法。
