"""Replay the dimension-eleven marked certificate from the public Lean arrays."""
from collections import Counter
from itertools import product
from math import comb
from pathlib import Path
import re


TASK = Path(__file__).resolve().parent / "formal" / "Task"
FIELD = range(5)
CLASSES = range(29)
X = range(9)
Y = range(10)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def packed_rows(source, name, count):
    pattern = rf"def {name} : ℕ → ℕ\n((?: +\| \d+ => \d+\n)+)"
    match = re.search(pattern, source)
    require(match is not None, f"Missing packed array {name}")
    rows = re.findall(r"\| (\d+) => (\d+)", match[1])
    require([int(i) for i, _ in rows] == list(range(count)), f"Bad row indices for {name}")
    return [int(value) for _, value in rows]


def integer_matrix(source, start, height, width):
    match = re.search(start + r"\s*!!\[([^\]]+)\]", source)
    require(match is not None, f"Missing integer matrix {start}")
    rows = [[int(value.strip()) for value in row.split(",")] for row in match[1].split(";")]
    require(len(rows) == height and all(len(row) == width for row in rows),
            f"Bad matrix dimensions for {start}")
    return rows


def representatives(source, name):
    match = re.search(rf"def {name} : OM → Tuple :=\s*!\[(.*)\]", source)
    require(match is not None, f"Missing representatives {name}")
    tuples = re.findall(r"!\[([0-4], [0-4], [0-4], [0-4], [0-4])\]", match[1])
    require(len(tuples) == len(CLASSES), f"Bad representative count for {name}")
    return [tuple(map(int, row.split(", "))) for row in tuples]


def digit(packed, position, width):
    return (packed >> (position * width)) & ((1 << width) - 1)


def signed_digit(packed, position, width):
    return digit(packed, position, width) - (1 << (width - 1))


def tag(chunks, word):
    code = 0
    for coordinate in word:
        code = 5 * code + coordinate
    row, position = divmod(code, 125)
    return digit(chunks[row], position, 5) % len(CLASSES)


def orbit_key(word, allow_translation):
    """Canonicalize the two blocks under site permutations and field actions."""
    shifts = FIELD if allow_translation else (0,)
    return min(
        tuple(sorted((scalar * value + shift) % 5 for value in word[:3]))
        + tuple(sorted((scalar * value + shift) % 5 for value in word[3:]))
        for scalar in range(1, 5)
        for shift in shifts
    )


def orbit_members(words, reps, chunks, allow_translation):
    keys = [orbit_key(rep, allow_translation) for rep in reps]
    require(len(set(keys)) == len(CLASSES), "Representatives repeat an orbit")
    members = [[] for _ in CLASSES]
    for word in words:
        label = tag(chunks, word)
        require(orbit_key(word, allow_translation) == keys[label], f"Wrong orbit label for {word}")
        members[label].append(word)
    require(all(members), "An orbit has no members")
    return members


def marked_kernel(data):
    primal_reps = representatives(data, "pRep")
    dual_reps = representatives(data, "vRep")
    words = list(product(FIELD, repeat=5))
    primal_words = [word for word in words if sum(word) % 5 == 0]
    require(all(sum(rep) % 5 == 0 for rep in primal_reps), "Nonzero-sum primal representative")
    primal = orbit_members(primal_words, primal_reps, packed_rows(data, "pChunk", 25), False)
    dual = orbit_members(words, dual_reps, packed_rows(data, "vChunk", 25), True)
    rows = packed_rows(data, "kernelChunk", len(CLASSES))
    kernel = []
    for p in CLASSES:
        coefficients = []
        for o in CLASSES:
            dots = Counter(sum(a * b for a, b in zip(word, primal_reps[o])) % 5 for word in dual[p])
            require(len({dots[v] for v in range(1, 5)}) == 1, f"Unequal nonzero dot counts at {p,o}")
            coefficient = dots[0] - dots[1]
            require(coefficient == signed_digit(rows[p], o, 11), f"Wrong marked kernel at {p,o}")
            coefficients.append(coefficient)
        kernel.append(coefficients)
    for name, orbits in (("Primal", primal), ("Dual", dual)):
        distribution = dict(sorted(Counter(map(len, orbits)).items()))
        print(f"{name}: {sum(map(len, orbits))} tuples, {len(orbits)} classes, "
              f"class size -> multiplicity {distribution}")
    print(f"Marked kernel: {len(CLASSES)**2} entries agree")
    return primal_reps, dual_reps, kernel


def krawtchouk(length):
    return [
        [
            sum((-1)**i * 4**(k-i) * comb(b, i) * comb(length-b, k-i) for i in range(k+1))
            for b in range(length + 1)
        ]
        for k in range(length + 1)
    ]


def signed_table(source, name, width):
    table = []
    for o in CLASSES:
        rows = packed_rows(source, f"{name}Row{o}", len(X))
        table.append([[signed_digit(row, d, width) for d in Y] for row in rows])
    return table


def weight_pair(word, shift=0):
    return (sum((x + shift) % 5 != 0 for x in word[:3]),
            sum((x + shift) % 5 != 0 for x in word[3:]))


def primal_forbidden(left, right):
    low = min(left, right)
    zero_mismatch = (left == 0) != (right == 0)
    short = low > 0 and (left + right < 5 or (left + right == 5 and low > 1))
    return zero_mismatch or (left, right) in {(11, 11), (3, 3)} or short


def dual_forbidden(left, right):
    low, high = sorted((left, right))
    return (left == 0) != (right == 0) or (low == 1 and high <= 3) or (left, right) == (2, 2)


def weighted_mass(multipliers, marked, unmarked):
    return sum(
        value * comb(marked, j) * comb(unmarked, b) * 4**(j+b)
        for j, row in enumerate(multipliers)
        for b, value in enumerate(row)
    )


def replay():
    data = (TASK / "PolynomialMarkedData.lean").read_text(encoding="utf-8")
    source = (TASK / "PolynomialMarkedValues.lean").read_text(encoding="utf-8")
    primal, dual, kernel = marked_kernel(data)

    k8, k9 = krawtchouk(8), krawtchouk(9)
    require(k8 == integer_matrix(source, r"def K8 : Matrix X X ℤ :=", 9, 9), "Wrong K8 table")
    require(k9 == integer_matrix(source, r"def K9 : Matrix Y Y ℤ :=", 10, 10), "Wrong K9 table")

    phi = signed_table(source, "phi", 77)
    local = signed_table(source, "gValues", 84)
    right = signed_table(source, "tValues", 95)
    wl = integer_matrix(source, r"\n  wl :=", 4, 9)
    wr = integer_matrix(source, r"\n  wr :=", 3, 10)
    vl = integer_matrix(source, r"\n  vl :=", 4, 9)
    vr = integer_matrix(source, r"\n  vr :=", 3, 10)
    corners = re.search(r"\n  wc := (-?\d+)\n  vc := (-?\d+)", source)
    require(corners is not None, "Missing corner multipliers")
    wc, vc = map(int, corners.groups())

    for o, b, d in product(CLASSES, X, Y):
        expected = sum(kernel[p][o] * phi[p][b][d] for p in CLASSES)
        require(local[o][b][d] == expected, f"Wrong local adjoint at {o,b,d}")
        expected = sum(k9[l][d] * local[o][b][l] for l in Y)
        require(right[o][b][d] == expected, f"Wrong right adjoint at {o,b,d}")
    cell_count = len(CLASSES) * len(X) * len(Y)
    print(f"Adjoints: both tables agree on all {cell_count} cells")

    allowed_w, allowed_v = [], []
    for o in CLASSES:
        left_weight, right_weight = weight_pair(primal[o])
        shifts = [weight_pair(dual[o], a) for a in FIELD]
        for b, d in product(X, Y):
            corner = (o, b, d) == (0, 0, 0)
            alpha = sum(k8[k][b] * right[o][k][d] for k in X)
            alpha += wl[left_weight][b] + wr[right_weight][d] + wc * corner
            beta = -5**11 * phi[o][b][d] + vc * corner
            beta += sum(vl[j][b] + vr[k][d] for j, k in shifts)
            if not primal_forbidden(left_weight + b, right_weight + d):
                require(alpha >= 0, f"Negative primal coefficient at {o,b,d}: {alpha}")
                allowed_w.append(alpha)
            if not any(dual_forbidden(j+b, k+d) for j, k in shifts):
                require(beta >= 0, f"Negative dual coefficient at {o,b,d}: {beta}")
                allowed_v.append(beta)

    for name, coefficients in (("Primal", allowed_w), ("Dual", allowed_v)):
        min_positive = min(value for value in coefficients if value > 0)
        print(f"{name} score: {cell_count-len(coefficients)} forbidden, {len(coefficients)} allowed, "
              f"{coefficients.count(0)} allowed zeros, least positive {min_positive}")

    terms = [weighted_mass(wl, 3, 8), weighted_mass(wr, 2, 9),
             5 * weighted_mass(vl, 3, 8), 5 * weighted_mass(vr, 2, 9)]
    rhs = wc + 5 * vc + sum(terms)
    print(f"Right-hand side: {rhs} (corner terms {wc}, {5*vc}; marginal terms {terms})")
    require(rhs < 0, "Right-hand side is not strictly negative")
    print("PASS: the marked equations and allowed-cell signs yield a contradiction")


if __name__ == "__main__":
    replay()
