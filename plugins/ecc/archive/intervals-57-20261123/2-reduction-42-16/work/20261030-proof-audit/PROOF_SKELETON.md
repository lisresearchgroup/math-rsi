# Proof-obligation ledger

Domain: all binary linear subspaces of F₂^42 of dimension 16; zero and repeated columns allowed.

## Symbols

C: hypothesized binary [42,16,d≥13] code.
E: parity extension in F₂^43, dimension 16, minimum distance ≥14.
i,j: coordinates whose two generator columns are linearly independent over F₂.
K: kernel of E→F₂², x↦(xᵢ,xⱼ), dimension 14.
D: shortening of E at i,j, a binary [41,14,δ≥14] code.
D': distance-descended and zero-padded binary [41,14,14] code.

## Dependency DAG

Binary weight/parity + injective extension -> E parameters.
Rank 16 -> two independent columns -> rank-nullity -> dim K=14.
Subcode distance monotonicity + deleting zero coordinates -> D parameters.
Positive-distance descent lemma -> D' exact parameters.
D' + Bouyuklieva–Bouyukliev 2020 Proposition 2 (import) -> contradiction -> upper bound 12.
Explicit matrix + rank + complete spectrum -> lower bound 12.
Upper and lower bound -> d₂(42,16)=12.

No reverse dependency from the desired upper bound to any reduction step. The public table upper bound 13 is not used.

## Obligations

- O1: extension preserves dimension; verified by original coordinates recovering the input.
- O2: w≥13 implies w+(w mod 2)≥14; verified by parity cases.
- O3: rank 16 guarantees independent pair of columns; verified by selecting a column basis.
- O4: restriction map rank is 2; verified by independent columns/functionals and injective generator map.
- O5: shortening is deletion of two identically zero coordinates on K; injective and weight-preserving.
- O6: δ≥14, K positive-dimensional; follows from O4/O5. Thus a minimum nonzero word exists.
- O7: delete δ−14 positions in its support; kernel zero because δ−14<δ. All nonzero images have weight ≥14 and selected image has weight exactly 14.
- O8: zero padding restores length 41 and is allowed in the target domain.
- O9: imported Proposition 2 covers exactly binary [41,14,14], with no projectivity or even-only assumption; verified against original PDF.
- O10: explicit lower-bound matrix has 16 independent rows and minimum weight 12; freshly recomputed over all 65,535 messages.

## Counterexample and boundary attempts

- Zero columns / repeated columns: do not invalidate rank selection; arbitrary two columns would be insufficient, hence select independent ones.
- Shortening can raise distance: accounted for by post-shortening distance descent, not assumed away.
- Descent target zero: excluded; old regression explicitly exhibits rank loss.
- Distances d>13: extension gives at least 14; no assumption of exact 13 required in the shorter proof.
- k=1 repetition family: falsifies blanket removal of dimension restrictions; not a counterexample to k=16.
- Original k≥16 threshold: sufficient but not necessary; shorter proof works for k≥3.
- No asymptotic limits, probability quantifiers, integrations or interchange obligations apply.

## Imports and unresolved replication

The Proposition 2 statement is an explicit published import. Its 209-class classification and 432-minute DimExtension run, and prior numeric inputs, were not independently reproduced in this recheck.
