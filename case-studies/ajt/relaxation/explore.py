from math import comb
import numpy as np
from scipy.optimize import linprog


def choose(n, k):
    return comb(n, k) if 0 <= k <= n else 0


def forbidden(i, j):
    return i + j <= 5 or (min(i, j) == 1 and max(i, j) <= 5)


def kraw(n):
    return [
        [
            sum((-1) ** t * 4 ** (r - t) * choose(i, t) * choose(n - i, r - t)
                for t in range(r + 1))
            for i in range(n + 1)
        ]
        for r in range(n + 1)
    ]


def lp(n, dual_mode="strong"):
    mu = np.asarray([comb(n, i) * 4**i for i in range(n + 1)], dtype=float)
    k = np.asarray(kraw(n), dtype=float)
    size = 5**n
    p = mu / (size - 1)
    xy = [(i, j) for i in range(1, n + 1) for j in range(i, n + 1)
          if not forbidden(i, j) and (i, j) != (n, n)]
    nx = len(xy)
    eq, eq_b, ub, ub_b = [], [], [], []
    for i in range(1, n + 1):
        eq.append([p[k] if i == j else p[j] if i == k else 0 for j, k in xy] + [0])
        eq_b.append(1)
    for i in range(nx):
        coefficients = [0] * (nx + 1)
        coefficients[i] = -1
        coefficients[-1] = 1
        ub.append(coefficients)
        ub_b.append(0)

    # B_{rs} divided by mu[r]mu[s]/(5^n - 1).
    transform = (k * mu[None, :]) / mu[:, None]
    for r in range(1, n + 1):
        for s in range(r, n + 1):
            values = [
                (transform[r, i] * transform[s, j] +
                 (0 if i == j else transform[r, j] * transform[s, i])) / size
                for i, j in xy
            ]
            offset = (size - 1) / size
            force_zero = (
                (dual_mode == "strong" and forbidden(r, s))
                or (dual_mode == "row" and r <= 2 and s <= 2)
            )
            if force_zero:
                eq.append(values + [0])
                eq_b.append(-offset)
            else:
                ub.append([-x for x in values] + [1])
                ub_b.append(offset)
    obj = [0] * nx + [-1]
    result = linprog(obj, A_ub=ub, b_ub=ub_b, A_eq=eq, b_eq=eq_b,
                     method="highs", options={"time_limit": 10})
    print(n, dual_mode, result.message, -result.fun if result.success else None, flush=True)
    return result, xy, mu

if __name__ == "__main__":
    for n in [6, 10, 11, 12, 13, 14, 16]:
        for dual_mode in ["strong", "row", "none"]:
            lp(n, dual_mode)
