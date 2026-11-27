"""Replay the unmarked split-weight certificates from their published integer arrays."""
from math import comb
from pathlib import Path
import re


def integers(row):
    return [int(x.strip()) for x in row.split(",")]


def coefficients(n):
    stem = "PolynomialCertificateEleven" if n == 11 else "PolynomialCertificateValues"
    source = (Path(__file__).parent / "formal" / "Task" / (stem + ".lean")).read_text()
    pattern = (rf"private def multipliers{n} : SpectrumMultipliers {n} where\s+"
               r"u := !\[([^\]]+)\]\s+v := !\[([^\]]+)\]\s+t := !!\[([^\]]+)\]")
    match = re.search(pattern, source)
    if match is None:
        raise ValueError(f"Cannot find the three multiplier arrays for dimension {n}")
    u, v, rows = match.groups()
    return integers(u), integers(v), [integers(row) for row in rows.split(";")]


def kraw(n, a, i):
    return sum((-1)**j * 4**(a-j) * comb(i, j) * comb(n-i, a-j)
               for j in range(max(0, a+i-n), min(i, a)+1))


def replay(n):
    indices = range(n + 1)
    u, v, t = coefficients(n)
    assert len(u) == len(v) == len(t) == n+1 and all(len(row) == n+1 for row in t)
    k = [[kraw(n, a, i) for i in indices] for a in indices]
    mu = [comb(n, i) * 4**i for i in indices]
    wcoef = [[u[i] + u[j] + sum(k[a][i]*t[a][b]*k[b][j] for a in indices for b in indices)
              for j in indices] for i in indices]
    vcoef = [[v[i] + v[j] - 5**n*t[i][j] for j in indices] for i in indices]
    for i in indices:
        for j in indices:
            lo, hi = sorted((i, j))
            if (i, j) not in ((0, 0), (n, n)) and not (1 <= lo <= 2 and hi <= 3):
                assert wcoef[i][j] >= 0, (n, "primal", i, j)
            extra = n == 11 and (lo, hi) == (2, 3)
            if (i, j) != (0, 0) and not (lo == 1 and hi <= 2) and not extra:
                assert vcoef[i][j] >= 0, (n, "dual", i, j)
    rhs = 2 * sum((u[i]+v[i])*mu[i] for i in indices)
    gap = wcoef[0][0] + vcoef[0][0] - rhs
    assert gap > 0
    return gap


if __name__ == "__main__":
    for dimension in range(6, 12):
        print(f"n={dimension}: strict corner gap {replay(dimension)}")
