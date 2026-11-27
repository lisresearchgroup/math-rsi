# Nowhere-zero points through dimension eleven

For every prime $p\ge5$, every $n\le11$, and every invertible matrix $A$ over $\mathbb F_p$ of size $n\times n$, there is a vector $x$ such that **every coordinate of both $x$ and $Ax$ is nonzero**. In the five-element field this covers all ten- and eleven-dimensional matrices. TCSExam reports the corresponding theorem through dimension nine in Appendix F.3, Eq. (9). [Preprint by SII MathRSI Team (PDF)](paper.pdf) · [Prior work](PRIOR-ART.md) · [TCSExam paper](https://arxiv.org/html/2611.07962v1#A6.SS3)

| What to check | Where to start |
| --- | --- |
| A proof for each original invertible matrix | [Lean project and replay instructions](formal/README.md) · [independent coordinate-level statements](formal/Audit.lean) |
| Why eleven dimensions close | [Dimension eleven](formal/Task/DimensionEleven.lean) joins an ordinary weight certificate to a marked five-coordinate Fourier certificate. [Normalization](formal/Task/MarkedCounterexample.lean) derives the marker from the hypothetical counterexample itself. |
| Which twelve-dimensional matrices are covered | All invertible matrices over prime fields of order at least seven already lie in Yu's bound. Over the five-element field, the verified symmetric theorem applies through dimension 23. [Affine and symmetric audit](formal/AuditAffine.lean) |
| What remains open | General invertible twelve-dimensional matrices over the five-element field. Two exact rational distributions show what specific unmarked real-valued weight constraints allow. [Distributions, precise constraints and verifier](relaxation/README.md) |
| How to rebuild the paper | Run `latexmk -pdf paper.tex` in this directory. [LaTeX source](paper.tex) · [Ordinary certificate replay](replay_ordinary.py) · [Marked certificate replay](replay_marked.py) |

The stronger run used MathRSI v8, GPT-6.2 Astra and Gemini Neon. The finite-dimensional theorem went through a separate Lean source rebuild and direct callers on the original coordinates. Follow-on work produced the real-relaxation certificates. The open benchmark asks for a proof or refutation in **all** dimensions. The preprint and its electronic supplement are open for discussion.

## 中文

给定一个可逆矩阵，能否找到一个向量，使它的每一项、以及乘上矩阵所得向量的每一项都非零？对于每个至少为 5 的素数域，这份 Lean 证明覆盖 **11 维以内的全部可逆矩阵**。TCSExam 论文此前报告到 9 维，本次推进的是五元域上的 **10、11 维**。在十一维，如果只记输入和输出各有多少个非零坐标，第一张证书会留下一个分支。证明从同一矩阵中找出三个输入坐标和两个输出坐标之间的线性关系，保留这五个坐标再计数，排除了剩余分支。[SII MathRSI Team 预印本（PDF）](paper.pdf) · [Lean 源码](formal/README.md)

**五元域上的一般 12 维仍然开放。** 若矩阵对称，这份证明已覆盖到 23 维。若素数至少为 7，一般 12 维早已落在 Yu 的已知范围。我们把这些结论及两份研究方法的反例证书分别列出，方便读者复算和讨论。[已知文献](PRIOR-ART.md) · [证书与重放](relaxation/README.md)
