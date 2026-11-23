#!/usr/bin/env python3
"""Lead's black-box check of a verify binary (interface: SPEC_HITS.md section 3) against exhaustive enumeration.

  lead_bruteforce_check.py BINARY [seed] [iters]

Random small codes (N<=22, <=13 rows; with zero rows, zero coordinates, duplicate coordinates, duplicated rows).
True minimum distance dmin by enumerating the whole row space. For D in {1, dmin-1 .. dmin+3} the binary must
return d_ge_D == (dmin >= D), the right rank, a valid witness when false, and complete enumeration counts when true.
Does not read the binary's source."""
import json, os, random, subprocess, sys
from collections import Counter


def run_suite(binary, seed, iters, max_n=22):
    random.seed(seed)
    issues, cnt = [], 0
    g, o_path = '/tmp/lead_vb_G.%d.txt' % os.getpid(), '/tmp/lead_vb_o.%d.json' % os.getpid()
    for it in range(iters):
        n = random.randint(6, max_n)
        k = random.randint(1, min(11, n))
        rows = [random.getrandbits(n) for _ in range(k + random.randint(0, 2))]
        if it % 9 == 0:
            rows.append(0)
        if it % 7 == 0:
            rows = [r & ~1 for r in rows]
        if it % 11 == 0:
            rows = [(r & ~3) | (3 if r & 1 else 0) for r in rows]
        if it % 13 == 0:
            rows = [r for r in rows for _ in (0, 1)]
        span = {0}
        for r in rows:
            span |= {v ^ r for v in span}
        dmin = min((bin(v).count('1') for v in span if v), default=None)
        with open(g, 'w') as f:
            f.write('\n'.join(format(r, '0%db' % n)[::-1] for r in rows) + '\n')
        for D in ([1, dmin - 1, dmin, dmin + 1, dmin + 2, dmin + 3] if dmin else [3]):
            if D > 40:
                continue
            if os.path.exists(o_path):
                os.remove(o_path)
            rr = subprocess.run([binary, g, str(D), o_path, str(random.choice([1, 4, 8]))],
                                capture_output=True, text=True)
            exp = True if dmin is None else dmin >= D
            cnt += 1
            if rr.returncode != 0:
                issues.append(('RC', it, n, len(rows), dmin, D, rr.stderr.strip().split('\n')[-1]))
                continue
            o = json.load(open(o_path))
            if o['d_ge_D'] != exp:
                issues.append(('WRONG', it, n, len(rows), dmin, D, o['d_ge_D']))
                continue
            if o['k'] != len(span).bit_length() - 1:
                issues.append(('RANK', it, o['k']))
            if not exp:
                w = o['witness']
                cw = int(w['codeword'][::-1], 2)
                if not (cw in span and cw != 0 and bin(cw).count('1') == w['weight'] < D):
                    issues.append(('BADWIT', it, n, dmin, D, w))
            else:
                for e in (o.get('work') or {}).get('weights', []):
                    if not e['complete'] or e['enumeration_visits'] < e['expected']:
                        issues.append(('INCOMPLETE', it, D, e))
    for q in (g, o_path):
        if os.path.exists(q):
            os.remove(q)
    return cnt, issues


if __name__ == '__main__':
    binary = sys.argv[1]
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 20261123
    iters = int(sys.argv[3]) if len(sys.argv) > 3 else 400
    cnt, issues = run_suite(binary, seed, iters)
    print('binary', binary, 'seed', seed, 'checks', cnt, 'issues', dict(Counter(i[0] for i in issues)))
    for i in issues[:20]:
        print(' ', i)
    sys.exit(1 if issues else 0)
