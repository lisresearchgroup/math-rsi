import json
from fractions import Fraction
from math import comb, lcm
import numpy as np
from scipy.linalg import qr
from explore import forbidden, kraw, lp


def solve_square(matrix, rhs):
    augmented = [[Fraction(c) for c in row] + [Fraction(b)]
                 for row, b in zip(matrix, rhs)]
    n = len(augmented)
    for j in range(n):
        pivot = next(i for i in range(j, n) if augmented[i][j])
        augmented[j], augmented[pivot] = augmented[pivot], augmented[j]
        divisor = augmented[j][j]
        augmented[j] = [x / divisor for x in augmented[j]]
        for i in range(n):
            if i == j or not augmented[i][j]:
                continue
            multiplier = augmented[i][j]
            augmented[i] = [x - multiplier * y for x, y in zip(augmented[i], augmented[j])]
    return [row[-1] for row in augmented]


def recover(n, dual_mode):
    result, cells, _ = lp(n, dual_mode)
    assert result.success
    mu = [comb(n, i) * 4**i for i in range(n + 1)]
    k = kraw(n)
    size = 5**n
    # Recover in x coordinates, where A_ij = x_ij mu_i mu_j / (5^n-1).
    weights = [mu[i] * mu[j] for i, j in cells]
    matrix, rhs = [], []
    for i in range(1, n + 1):
        matrix.append([weight if i in (j, l) else 0 for (j, l), weight in zip(cells, weights)])
        rhs.append(mu[i] * (size - 1))
    for r in range(1, n + 1):
        for s in range(r, n + 1):
            if ((dual_mode == "strong" and forbidden(r, s))
                    or (dual_mode == "row" and r <= 2 and s <= 2)):
                matrix.append([
                    weight * (k[r][i] * k[s][j] + (0 if i == j else k[r][j] * k[s][i]))
                    for (i, j), weight in zip(cells, weights)
                ])
                rhs.append(-mu[r] * mu[s] * (size - 1))
    numeric = np.asarray(matrix, dtype=float)
    numeric /= np.max(np.abs(numeric), axis=1)[:, None]
    r, permutation = qr(numeric, pivoting=True, mode="r")
    assert np.all(np.abs(np.diag(r)) > 1e-10)
    pivots = [int(i) for i in permutation[:len(rhs)]]
    fixed = {j: Fraction(round(float(x) * 10**17), 10**17)
             for j, x in enumerate(result.x[:-1]) if j not in pivots}
    correction_rhs = [b - sum(row[j] * x for j, x in fixed.items())
                      for row, b in zip(matrix, rhs)]
    pivot_matrix = [[row[j] for j in pivots] for row in matrix]
    solution = fixed | dict(zip(pivots, solve_square(pivot_matrix, correction_rhs)))
    values = [solution[j] * weight / (size - 1) for j, weight in enumerate(weights)]
    denominator = lcm(*(v.denominator for v in values))
    result = {"n": n, "dual_mode": dual_mode, "denominator": denominator,
              "entries": [[i, j, int(v * denominator)] for (i, j), v in zip(cells, values)]}
    with open(f"certificate-{n}.json", "w") as out:
        json.dump(result, out, indent=1)
        out.write("\n")


if __name__ == "__main__":
    recover(12, "row")
    recover(16, "strong")
