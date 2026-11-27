import argparse
import json
from itertools import product
from math import comb
from pathlib import Path


def choose(n, k):
    return comb(n, k) if 0 <= k <= n else 0


def forbidden(i, j):
    return i + j <= 5 or (min(i, j) == 1 and max(i, j) <= 5)


def load(path):
    certificate = json.loads(path.read_text())
    n = certificate["n"]
    denominator = certificate["denominator"]
    mode = certificate["dual_mode"]
    assert denominator > 0
    a = [[0 for _ in range(n + 1)] for _ in range(n + 1)]
    a[0][0] = denominator
    seen = set()
    for i, j, count in certificate["entries"]:
        assert 1 <= i <= j <= n and count > 0
        assert (i, j) not in seen
        a[i][j] = a[j][i] = count
        seen.add((i, j))
    return a, denominator, mode


def check(a, denominator, dual_mode):
    n = len(a) - 1
    axis_range = range(n + 1)
    positive_range = range(1, n + 1)
    mu = [comb(n, i) * 4**i for i in axis_range]
    assert a[0][0] == denominator
    assert all(v >= 0 for row in a for v in row)
    assert all(a[0][i] == a[i][0] == 0 for i in positive_range)
    assert all(a[i][j] == a[j][i] for i, j in product(axis_range, repeat=2))
    assert all(a[i][j] == 0 for i, j in product(positive_range, repeat=2) if forbidden(i, j))
    assert a[n][n] == 0
    assert [sum(row) for row in a] == [denominator * v for v in mu]

    k = [[sum((-1) ** t * 4 ** (r - t) * choose(i, t) * choose(n - i, r - t)
              for t in range(r + 1))
          for i in axis_range] for r in axis_range]
    ka = [[sum(k[r][i] * a[i][j] for i in axis_range) for j in axis_range] for r in axis_range]
    b = [[sum(ka[r][j] * k[s][j] for j in axis_range) for s in axis_range] for r in axis_range]
    dual_denominator = denominator * 5**n
    assert all(v >= 0 for row in b for v in row)
    assert b[0][0] == dual_denominator
    assert all(b[0][i] == b[i][0] == 0 for i in positive_range)
    assert all(b[r][s] == b[s][r] for r, s in product(axis_range, repeat=2))
    assert [sum(row) for row in b] == [dual_denominator * v for v in mu]
    if dual_mode == "row":
        assert all(b[r][s] == 0 for r, s in product((1, 2), repeat=2))
    else:
        assert dual_mode == "strong"
        assert all(b[r][s] == 0 for r, s in product(positive_range, repeat=2) if forbidden(r, s))
    entries = sum(a[i][j] > 0 for i in positive_range for j in range(i, n + 1))
    print(f"PASS n={n} exact rational primal and dual; dual-zero mode={dual_mode}; "
          f"positive upper-triangle primal entries={entries}")


def convolve(a, b):
    m = len(a) + len(b) - 1
    c = [[0 for _ in range(m)] for _ in range(m)]
    for i, j in product(range(len(a)), repeat=2):
        if a[i][j] == 0:
            continue
        for r, s in product(range(len(b)), repeat=2):
            c[i + r][j + s] += a[i][j] * b[r][s]
    return c


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("certificates", type=Path, nargs="*")
    parser.add_argument("--twice", action="store_true")
    args = parser.parse_args()
    paths = args.certificates or sorted(Path(__file__).parent.glob("certificate-*.json"))
    assert paths
    for path in paths:
        a, denominator, mode = load(path)
        check(a, denominator, mode)
        if args.twice:
            check(convolve(a, a), denominator**2, mode)
