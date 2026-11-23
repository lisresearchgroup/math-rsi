"""Fresh explicit-matrix recheck plus existing small mechanism checks.
No nonexistence search, no external classification is rerun.
"""
from collections import Counter
from pathlib import Path
import json
import subprocess
import sys

OUT = Path(__file__).resolve().parent
CASE = OUT.parent.parent
seed = json.loads((CASE / 'candidates/qr-seed-verified.json').read_text())
matrix = seed['matrix']['rows_0_1']
assert len(matrix) == 16 and all(len(row) == 42 for row in matrix)
assert all(x in (0, 1) for row in matrix for x in row)
rows = [sum(bit << j for j, bit in enumerate(row)) for row in matrix]
assert rows == seed['matrix']['rows_int']
# Independent pivot dictionary, operating on the explicit bit rows.
pivots = {}
for row in rows:
    while row:
        p = row.bit_length() - 1
        if p in pivots:
            row ^= pivots[p]
        else:
            pivots[p] = row
            break
assert len(pivots) == 16
# Direct message enumeration (not the old Gray-code implementation).
words = []
for message in range(1, 1 << 16):
    word = 0
    for i in range(16):
        if (message >> i) & 1:
            word ^= rows[i]
    words.append(word)
spectrum = Counter(w.bit_count() for w in words)
expected = {12: 675, 16: 9898, 20: 30659, 24: 21056, 28: 3161, 32: 85, 36: 1}
assert len(set(words)) == 65535 and 0 not in words
assert spectrum == expected
witness = next((u, w) for u, w in enumerate(words, 1) if w.bit_count() == 12)
checks = []
for relative, output in [
    ('work/20261020-source-corrections/verify_reduction_corrections.py', 'distance_and_shortening.log'),
    ('work/20261020-prop2-proof/verify_reduction.py', 'mechanisms.json'),
]:
    run = subprocess.run([sys.executable, str(CASE / relative)], cwd=CASE, capture_output=True, text=True)
    (OUT / output).write_text(run.stdout)
    if run.stderr:
        (OUT / (output + '.stderr')).write_text(run.stderr)
    assert run.returncode == 0, (relative, run.returncode, run.stderr)
    if output.endswith('.json'):
        data = json.loads(run.stdout)
        assert data['all_pass'] is True
        assert all(x['PASS'] for x in data['results'])
        assert all(x['PASS'] for x in data['controls'])
        count = {'mechanism_cases': len(data['results']), 'negative_controls': len(data['controls'])}
    else:
        assert 'ALL CHECKS PASSED' in run.stdout
        assert run.stdout.count('[PASS]') == 5
        assert '[FAIL]' not in run.stdout
        count = {'checks': 5}
    checks.append({'script': relative, 'exit_code': run.returncode, 'output': output, **count})
result = {
    'rank': len(pivots), 'nonzero_messages': len(words), 'distinct_nonzero_words': len(set(words)),
    'minimum_distance': min(spectrum), 'nonzero_weight_spectrum': dict(sorted(spectrum.items())),
    'witness_message': witness[0], 'witness_word': witness[1],
    'witness_support_1_based': [j + 1 for j in range(42) if (witness[1] >> j) & 1],
    'mechanism_checks': checks,
    'scope': 'Explicit lower-bound certificate and finite mechanism checks only. General upper-bound validity follows from algebra and the cited Proposition 2, not these tests.',
    'external_209_class_search_rerun': False,
}
(OUT / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False, indent=2))
