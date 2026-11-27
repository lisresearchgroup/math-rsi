import Task.PolynomialCharacters

open scoped BigOperators
open Finset Matrix

namespace AlonJaegerTarsi.WeightTransform

def wt {K : Type*} [Zero K] [DecidableEq K] {n : ℕ} (x : Fin n → K) : ℕ :=
  (univ.filter fun i => x i ≠ 0).card

def counts {K : Type*} [Fintype K] [CommRing K] [DecidableEq K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) (i j : ℕ) : ℕ :=
  (univ.filter fun x => wt x = i ∧ wt (A *ᵥ x) = j).card

def kraw (p n a i : ℕ) : ℤ :=
  ∑ t ∈ range (a + 1), (-1 : ℤ)^t * (p - 1 : ℕ)^(a-t) * i.choose t * (n-i).choose (a-t)

theorem wt_le {K : Type*} [Zero K] [DecidableEq K] {n : ℕ} (x : Fin n → K) : wt x ≤ n := by
  simpa [wt] using Finset.card_filter_le (univ : Finset (Fin n)) (fun i => x i ≠ 0)

theorem wt_eq_full {K : Type*} [Zero K] [DecidableEq K] {n : ℕ} (x : Fin n → K) :
    wt x = n ↔ NowhereZero x := by
  simpa only [wt, NowhereZero, card_univ, Fintype.card_fin, mem_univ, forall_const] using
    (Finset.card_filter_eq_iff (s := (univ : Finset (Fin n))) (p := fun i => x i ≠ 0))

theorem counts_full_pos {K : Type*} [Fintype K] [CommRing K] [DecidableEq K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) : 0 < counts A n n ↔ HasAJTVector A := by
  simp [counts, Finset.card_pos, Finset.Nonempty, wt_eq_full, HasAJTVector]

end AlonJaegerTarsi.WeightTransform
