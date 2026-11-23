#!/usr/bin/env python3
"""Explicit size-5 violation witnesses for relaxed 5-head sets (w=6, D=16).

usage: witness5_all.py            (paths are fixed below; run from the case dir)
Bit convention: coordinate j <-> bit j of a Python int / uint64.
Independent of work/20261122-o6, -o7, -planted.
"""
import gzip, hashlib, json, os, sys, time
import numpy as np

CASE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CATALOG = os.path.join(CASE, "work/20261122-catalog/qext/run_36_7_16/36_7_16.2")
R5 = os.path.join(CASE, "work/20261123-assembly/r5")
OUT = os.path.dirname(os.path.abspath(__file__))
IDXS = [1980, 2004]
W, D, M = 6, 16, 5
TAU = {1: 14, 2: 14, 3: 12, 4: 12, 5: 10}
CHUNK = 40000


def popc(x):
    return bin(x).count("1")


def catalog_block(path, idx):
    lines = open(path, "rb").read().decode("latin-1").replace("\r\n", "\n").replace("\r", "\n").split("\n")
    for i, l in enumerate(lines):
        t = l.strip()
        if t.startswith("?"):
            tok = t[1:].split()
            if int(tok[3]) == idx:
                k, n = int(tok[0]), int(tok[1])
                rows = []
                j = i + 1
                while len(rows) < k:
                    s = lines[j].strip(); j += 1
                    if s:
                        rows.append(s)
                return k, n, rows
    raise KeyError(idx)


def rref(rows, n):
    """leftmost-pivot RREF; returns (pivots, rows as ints ordered by pivot)."""
    v = [sum(1 << j for j, c in enumerate(r) if c == "1") for r in rows]
    piv, r = [], 0
    for col in range(n):
        b = 1 << col
        sel = next((t for t in range(r, len(v)) if v[t] & b), None)
        if sel is None:
            continue
        v[r], v[sel] = v[sel], v[r]
        for t in range(len(v)):
            if t != r and v[t] & b:
                v[t] ^= v[r]
        piv.append(col); r += 1
        if r == len(v):
            break
    return piv, v[:r]


def codeword_table(R):
    """cw[m] = xor of R[i] for bit i of m."""
    cw = [0]
    for i, r in enumerate(R):
        cw += [c ^ r for c in cw]
    return cw  # index m has bit i <-> row i (built by doubling)


def xs_array(s, free):
    """canonical x_s as uint64 (bit q_t of x = bit t of s)."""
    s = s.astype(np.uint64)
    x = np.zeros(s.shape, dtype=np.uint64)
    for t, q in enumerate(free):
        x |= ((s >> np.uint64(t)) & np.uint64(1)) << np.uint64(q)
    return x


def ext_matrix(R, free, svec, n):
    """12 x 42 generator rows as ints: K rows | 0 ; x_{s_i} | e_i + e_w."""
    rows = [r for r in R]
    for i, s in enumerate(svec):
        x = sum(((s >> t) & 1) << q for t, q in enumerate(free))
        tail = (1 << (n + i)) | (1 << (n + W - 1))
        rows.append(x | tail)
    return rows


def weight_distribution(rows):
    k = len(rows)
    cw = codeword_table(rows)
    h = {}
    for m in range(1, 1 << k):
        w = popc(cw[m]); h[w] = h.get(w, 0) + 1
    return dict(sorted(h.items()))


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def process(idx, report):
    t0 = time.time()
    k, n, crows = catalog_block(CATALOG, idx)
    gen = [l.strip() for l in open(os.path.join(R5, "%d.gen" % idx)) if l.strip()]
    info = {"idx": idx, "gen_equals_catalog_rows_in_order": gen == crows,
            "gen_equals_catalog_as_sets": sorted(gen) == sorted(crows), "k": k, "n": n}
    assert gen == crows and k == 7 and n == 36
    piv, R = rref(gen, n)
    free = [c for c in range(n) if c not in set(piv)]
    J = json.load(open(os.path.join(R5, "%d.relax5.full.json" % idx)))
    info["pivots"] = piv
    info["pivots_equal_json"] = piv == J["pivots"]
    info["free_equal_json"] = free == J["free"]
    assert piv == J["pivots"] and free == J["free"] and len(piv) == k
    cw = codeword_table(R)
    wts = [popc(c) for c in cw]
    info["K_even"] = all(w % 2 == 0 for w in wts)
    info["K_min_weight"] = min(w for w in wts[1:])
    info["K_weight_distribution"] = {str(w): wts[1:].count(w) for w in sorted(set(wts[1:]))}
    assert info["K_even"] and info["K_min_weight"] == 16
    cwarr = np.array(cw, dtype=np.uint64)

    S = np.array(J["solution_list"], dtype=np.int64)
    c5 = J["c5"]
    nsets = S.shape[0]
    del J["solution_list"]
    info["num_sets"] = nsets
    info["json_c5"] = c5
    info["json_solutions"] = J["solutions"]
    assert S.shape[1] == 5
    info["strictly_ascending_within_tuple"] = bool((S[:, 1:] > S[:, :-1]).all())
    info["max_syndrome_lt_2^29"] = bool(S.max() < (1 << 29)) and bool(S.min() >= 1)
    # lexicographic strictly-increasing => distinct
    a, b = S[:-1], S[1:]
    ne = a != b
    first = ne.argmax(axis=1)
    rowsel = np.arange(a.shape[0])
    anydiff = ne.any(axis=1)
    lex_inc = bool(anydiff.all() and (b[rowsel, first] > a[rowsel, first]).all())
    info["lexicographically_strictly_increasing"] = lex_inc
    if lex_inc:
        info["all_tuples_distinct"] = True
    else:
        info["all_tuples_distinct"] = int(np.unique(S, axis=0).shape[0]) == nsets
    del a, b, ne, first, rowsel, anydiff

    masks = list(range(1, 32))
    size_of = {m: popc(m) for m in masks}
    d5_all = np.zeros(nsets, dtype=np.int16)
    kmask_all = np.zeros(nsets, dtype=np.uint8)
    viol_sets = 0
    viol_by_size = {s: 0 for s in range(1, 6)}
    par_viol_sets = 0
    depth_hist = {s: np.zeros(40, dtype=np.int64) for s in range(1, 6)}
    pair_depth16_count_hist = np.zeros(11, dtype=np.int64)
    pair_idx = [m for m in masks if size_of[m] == 2]
    sizes = np.array([size_of[m] for m in masks])
    taus = np.array([TAU[size_of[m]] for m in masks])
    lt5 = sizes < 5
    wit_x = np.zeros(nsets, dtype=np.uint64)
    for c0 in range(0, nsets, CHUNK):
        Sc = S[c0:c0 + CHUNK]
        nc = Sc.shape[0]
        x = xs_array(Sc, free)                    # (nc,5)
        X = np.zeros((nc, 31), dtype=np.uint64)   # column m-1 <-> subset mask m
        for m in masks:
            low = m & -m
            rest = m ^ low
            xi = x[:, low.bit_length() - 1]
            X[:, m - 1] = xi if rest == 0 else (X[:, rest - 1] ^ xi)
        par = np.bitwise_count(X) & np.uint8(1)
        par_viol_sets += int((par.any(axis=1)).sum())
        Dm = np.full((nc, 31), 255, dtype=np.uint8)
        W5 = np.empty((nc, 128), dtype=np.uint8)
        for ci in range(128):
            wv = np.bitwise_count(X ^ cwarr[ci]).astype(np.uint8)
            np.minimum(Dm, wv, out=Dm)
            W5[:, ci] = wv[:, 30]
        # sanity: size-5 depth from W5 equals Dm[:,30]
        km = W5.argmin(axis=1)
        d5 = W5[np.arange(nc), km]
        assert (d5 == Dm[:, 30]).all()
        d5_all[c0:c0 + nc] = d5
        kmask_all[c0:c0 + nc] = km
        wit_x[c0:c0 + nc] = X[:, 30]
        bad = (Dm < taus[None, :]) & lt5[None, :]
        viol_sets += int(bad.any(axis=1).sum())
        for s in range(1, 5):
            viol_by_size[s] += int(bad[:, sizes == s].any(axis=1).sum())
        for s in range(1, 6):
            depth_hist[s] += np.bincount(Dm[:, sizes == s].ravel(), minlength=40)[:40]
        pd = Dm[:, [m - 1 for m in pair_idx]]
        pair_depth16_count_hist += np.bincount((pd == 16).sum(axis=1), minlength=11)[:11]
        if (d5 >= 10).any():
            j = int(np.nonzero(d5 >= 10)[0][0])
            svec = [int(v) for v in Sc[j]]
            rows = ext_matrix(R, free, svec, n)
            fn = os.path.join(OUT, "SOLUTION_FOUND_%d.txt" % idx)
            with open(fn, "w") as f:
                f.write("GENUINE SOLUTION: idx %d set %s d5=%d\n" % (idx, svec, int(d5[j])))
                for r in rows:
                    f.write("".join("1" if (r >> t) & 1 else "0" for t in range(n + W)) + "\n")
                f.write("weight distribution over 4095 nonzero codewords: %s\n" % json.dumps(weight_distribution(rows)))
            print("GENUINE SOLUTION FOUND, wrote", fn)
            sys.exit(3)

    info["a_violating_sets(sizes1-4 thresholds)"] = viol_sets
    info["a_violating_sets_by_size"] = viol_by_size
    info["sets_with_any_odd_subset_xor_weight"] = par_viol_sets
    info["d5_hist"] = {int(d): int(c) for d, c in zip(*np.unique(d5_all, return_counts=True))}
    info["max_d5"] = int(d5_all.max())
    info["sets_with_d5_ge_10"] = int((d5_all >= 10).sum())
    info["sets_with_d5_lt_10"] = int((d5_all < 10).sum())
    info["depth_hist_by_subset_size_aggregated"] = {
        str(s): {str(d): int(c) for d, c in enumerate(depth_hist[s]) if c} for s in range(1, 6)}
    info["pair_depths_histogram_aggregated"] = {str(d): int(c) for d, c in enumerate(depth_hist[2]) if c}
    info["sets_by_number_of_pairs_with_depth16(of 10)"] = {str(i): int(c) for i, c in enumerate(pair_depth16_count_hist) if c}

    # ---- explicit witness codeword: genuine GF(2) combination of 12x42 rows, vectorised over sets
    xfull = xs_array(S, free)  # (N,5)
    ext_rows = []  # per head i the row vectors, built for each set
    code42 = np.zeros(nsets, dtype=np.uint64)
    for i in range(k):  # K rows
        sel = ((kmask_all >> i) & 1).astype(bool)
        code42[sel] ^= np.uint64(R[i])
    for i in range(5):  # head rows with message bit 1: x_{s_i} | e_i + e_w
        tail = np.uint64((1 << (n + i)) | (1 << (n + W - 1)))
        code42 ^= (xfull[:, i] | tail)
    w42 = np.bitwise_count(code42).astype(np.int16)
    info["explicit_codeword_weight_equals_d5_plus_6_for_all"] = bool((w42 == d5_all.astype(np.int16) + 6).all())
    info["explicit_codeword_weight_lt_16_for_all"] = bool((w42 < 16).all())
    info["explicit_codeword_nonzero_for_all"] = bool((code42 != 0).all())
    assert info["explicit_codeword_weight_equals_d5_plus_6_for_all"]
    info["witness_weight_hist"] = {int(d): int(c) for d, c in zip(*np.unique(w42, return_counts=True))}
    info["c5_matches"] = (nsets == c5 == J["solutions"])
    # 4 spot checks with fully independent per-set Python weight-distribution of the 12x42 code
    spot = {}
    for j in sorted({0, nsets // 2, nsets - 1}):
        svec = [int(v) for v in S[j]]
        rows = ext_matrix(R, free, svec, n)
        wd = weight_distribution(rows)
        spot[str(j)] = {"set": svec, "min_weight_all_4095": min(wd), "weight_distribution": wd,
                        "d5_plus_6": int(d5_all[j]) + 6}
        assert min(wd) == int(d5_all[j]) + 6 or min(wd) <= int(d5_all[j]) + 6
    info["spot_full_weight_distributions"] = spot

    # ---- write witness file (deterministic gzip)
    path = os.path.join(OUT, "witness_%d.txt.gz" % idx)
    with open(path, "wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0, compresslevel=9) as gz:
            buf = []
            Sl = S.tolist(); kl = kmask_all.tolist(); wl = w42.tolist()
            for j in range(nsets):
                a = Sl[j]
                buf.append("%d %d %d %d %d %d %d\n" % (a[0], a[1], a[2], a[3], a[4], kl[j], wl[j]))
                if len(buf) >= 100000:
                    gz.write("".join(buf).encode()); buf = []
            if buf:
                gz.write("".join(buf).encode())
    info["witness_file"] = path
    info["witness_lines"] = nsets
    info["witness_sha256"] = sha256_file(path)
    info["seconds"] = round(time.time() - t0, 2)
    return info


def main():
    out = {}
    for idx in IDXS:
        print("processing", idx, flush=True)
        out[str(idx)] = process(idx, None)
        print(json.dumps({k: v for k, v in out[str(idx)].items() if k not in ("spot_full_weight_distributions",)}, indent=1), flush=True)
    with open(os.path.join(OUT, "witness5_stats.json"), "w") as f:
        json.dump(out, f, indent=1)


if __name__ == "__main__":
    main()
