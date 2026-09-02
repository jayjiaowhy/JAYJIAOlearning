# PyTorch 训练循环

## 一句话解释

PyTorch 训练循环把批数据依次送入模型，计算损失与梯度，再由优化器更新参数，核心闭环是 `Tensor -> Model -> Loss -> Autograd -> Optimizer`。

## 前置知识

- Python 与多维数组
- 矩阵乘法和张量维度
- 梯度下降与链式法则

## 关联课程

- [[cs_ds/机器学习/00-机器学习索引|机器学习]]
- [[cs_ds/推荐系统/00-推荐系统索引|推荐系统]]

## 常见题型

- 标注 `[B, L, D, N, K]` 等维度语义，并判断 reshape、广播或批量矩阵乘法是否正确。
- 解释 `zero_grad()`、`backward()`、`step()` 的顺序以及梯度为何默认累加。
- 区分 `model.train()`、`model.eval()` 与 `torch.no_grad()` 的作用。

## 已有笔记链接

- [[cs_ds/推荐系统/PyTorch初识|PyTorch 初识：从 Tensor 到 RecFlow 训练代码]]
- [[cs_ds/机器学习/11、动手学深度学习-pytorch.pdf|动手学深度学习 PyTorch 版]]
- [[cs_ds/机器学习/机器学习路线_ISLP-CS229-李航|机器学习 14 周路线：PyTorch 桥接实践]]
