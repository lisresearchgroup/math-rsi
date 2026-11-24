# Square-free subgraphs of the 8-cube

Contributed by [@mizopl](https://github.com/mizopl) and the we\* project (PROOFER) in [MathRSI #60](https://github.com/lisresearchgroup/math-rsi/issues/60). The [upstream package and paper argument](https://github.com/mizopl/we-star/tree/fcb18958d86716a2bb3120d83f46435ce8818a32/solutions/q8-c4-extremal-forcing) are pinned at `fcb18958`. The Python checker, Lean module and ten edge lists here are original upstream files, distributed with the [upstream license](LICENSE).

## Replay the graphs and the finite case

Run these commands from this directory with Python 3.10 or later. The checker uses the standard library.

```sh
python3 verify.py
python3 verify.py --json
```

The [atlas](atlas) contains ten square-free graphs with 675 to 682 edges. Each is maximal under edge addition. For example, the [682-edge graph with degrees 5 and 6](atlas/q8_682_deg56_zero_defect_n2o2_n2a10.edges) has 172 vertices of degree 5 and 84 of degree 6. It gives a concrete test case outside the family in which every square contains an odd number of selected edges. To test rejection, run `python3 verify.py --corrupt`. It keeps the edge count fixed, introduces a 4-cycle and exits with status 1.

Case 5A asks whether a hypothetical 683-edge graph at minimum distance five from the odd-square family can arise by deleting two edges and adding three to an odd-square 682-edge graph. The paper derives necessary conditions on those five edges. The Python replay covers 1,023 choices of a second deleted edge in 14 symmetry classes. It checks 31 candidate triples across their representatives and finds zero survivors. The reduction to these cases is given in the [upstream proof](https://github.com/mizopl/we-star/tree/fcb18958d86716a2bb3120d83f46435ce8818a32/solutions/q8-c4-extremal-forcing).

## Check the counting lemmas

```sh
lean +leanprover/lean4:v4.36.0 Q8EmptySquareForcing.lean
```

The [Lean module](Q8EmptySquareForcing.lean) starts from the three double-counting identities in `C4FreeCounts`. Under these hypotheses, 683 edges force at least one empty square. The graph-to-counts argument is supplied on paper. The [MathRSI result for unrestricted graphs](../../archive/q8-683/README.md) places the maximum at 682 or 683. Whether 683 edges are attainable remains open.
