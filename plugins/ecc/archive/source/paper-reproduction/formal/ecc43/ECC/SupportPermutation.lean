import ECC.Permutation
import ECC.ShorteningCore
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Logic.Equiv.Fin.Basic

namespace ECC

theorem permuteCode_finrank {n : ℕ} (e : Fin n ≃ Fin n) (C : Submodule F2 (Word n)) :
    Module.finrank F2 (permuteCode e C) = Module.finrank F2 C :=
  (permuteWord e).finrank_map_eq C

theorem dotWord_permute {n : ℕ} (e : Fin n ≃ Fin n) (x y : Word n) :
    dotWord (permuteWord e x) (permuteWord e y) = dotWord x y := by
  change (∑ i, x (e i) * y (e i)) = ∑ i, x i * y i
  exact Equiv.sum_comp e (fun i => x i * y i)

theorem permuteWord_mem_dual {n : ℕ} (e : Fin n ≃ Fin n)
    (C : Submodule F2 (Word n)) {y : Word n} (hy : y ∈ dualCode C) :
    permuteWord e y ∈ dualCode (permuteCode e C) := by
  rintro _ ⟨x, hx, rfl⟩
  change dotWord (permuteWord e x) (permuteWord e y) = 0
  rw [dotWord_permute]
  exact hy x hx

theorem permuteCode_dual_minWeight {n d : ℕ} (e : Fin n ≃ Fin n)
    (C : Submodule F2 (Word n)) (h : MinWeight (dualCode C) d) :
    MinWeight (dualCode (permuteCode e C)) d := by
  intro y hy hne
  let z := (permuteWord e).symm y
  have hz : z ∈ dualCode C := by
    intro x hx
    have hh := hy (permuteWord e x) ⟨x, hx, rfl⟩
    have heq : permuteWord e z = y := (permuteWord e).apply_symm_apply y
    rw [← heq, dotWord_permute] at hh
    exact hh
  have hzne : z ≠ 0 := by
    intro hz
    apply hne
    rw [← (permuteWord e).apply_symm_apply y]
    change permuteWord e z = 0
    rw [hz, map_zero]
  have hb := h z hz hzne
  have hw := weight_permuteWord e z
  rw [(permuteWord e).apply_symm_apply] at hw
  exact hw.symm ▸ hb

/-- A finite support of cardinality m can be moved to the last m coordinates
by a coordinate permutation; no general linear change of coordinates is used. -/
theorem exists_support_permutation {n m : ℕ} (S : Finset (Fin (n + m)))
    (hS : S.card = m) :
    ∃ e : Fin (n + m) ≃ Fin (n + m),
      (∀ i : Fin n, e (Fin.castAdd m i) ∉ S) ∧
      (∀ j : Fin m, e (Fin.natAdd n j) ∈ S) := by
  classical
  have hc : Fintype.card {i : Fin (n+m) // i ∈ S} = m := by
    simpa only [Fintype.card_coe] using hS
  have hn : Fintype.card {i : Fin (n+m) // i ∉ S} = n := by
    rw [Fintype.card_subtype_compl, Fintype.card_fin, hc]
    omega
  let e0 := (Fintype.equivFinOfCardEq hn).symm
  let e1 := (Fintype.equivFinOfCardEq hc).symm
  let e : Fin (n+m) ≃ Fin (n+m) :=
    finSumFinEquiv.symm.trans ((Equiv.sumCongr e0 e1).trans
      ((Equiv.sumComm _ _).trans (Equiv.sumCompl (fun i => i ∈ S))))
  refine ⟨e, ?_, ?_⟩
  · intro i
    simpa only [e, Equiv.trans_apply, finSumFinEquiv_symm_apply_castAdd,
      Equiv.sumCongr_apply, Sum.map_inl, Equiv.sumComm_apply, Sum.swap_inl,
      Equiv.sumCompl_apply_inr] using (e0 i).property
  · intro j
    simpa only [e, Equiv.trans_apply, finSumFinEquiv_symm_apply_natAdd,
      Equiv.sumCongr_apply, Sum.map_inr, Equiv.sumComm_apply, Sum.swap_inr,
      Equiv.sumCompl_apply_inl] using (e1 j).property

theorem exists_permutation_supported_tail {n m : ℕ} (y : Word (n+m))
    (hy : weight y ≤ m) :
    ∃ e : Fin (n+m) ≃ Fin (n+m), firstPart n m (permuteWord e y) = 0 := by
  classical
  let S := Finset.univ.filter (fun i => y i ≠ 0)
  obtain ⟨U, hSU, _, hU⟩ := Finset.exists_subsuperset_card_eq
    (Finset.subset_univ S) hy (by simp : m ≤ (Finset.univ : Finset (Fin (n+m))).card)
  obtain ⟨e, he, _⟩ := exists_support_permutation U hU
  refine ⟨e, ?_⟩
  funext i
  change y (e (Fin.castAdd m i)) = 0
  by_contra hz
  exact he i (hSU (Finset.mem_filter.mpr ⟨Finset.mem_univ _, hz⟩))

theorem exists_permutation_exact_support {n m : ℕ} (y : Word (n+m))
    (hy : weight y = m) :
    ∃ e : Fin (n+m) ≃ Fin (n+m),
      firstPart n m (permuteWord e y) = 0 ∧
      lastPart n m (permuteWord e y) = (fun _ => 1) := by
  classical
  let S := Finset.univ.filter (fun i => y i ≠ 0)
  obtain ⟨e, he0, he1⟩ := exists_support_permutation S hy
  refine ⟨e, ?_, ?_⟩
  · funext i
    change y (e (Fin.castAdd m i)) = 0
    simpa only [S, Finset.mem_filter, Finset.mem_univ, true_and, not_not] using he0 i
  · funext j
    change y (e (Fin.natAdd n j)) = 1
    have hn : y (e (Fin.natAdd n j)) ≠ 0 := (Finset.mem_filter.mp (he1 j)).2
    have ht : ∀ a : F2, a = 0 ∨ a = 1 := by decide
    exact (ht _).resolve_left hn

/-- The all-one dual tail is exactly the even-tail constraint used by shortening. -/
theorem sum_tail_eq_zero_of_dual {n m : ℕ}
    (C : Submodule F2 (Word (n+m))) {y : Word (n+m)} (hy : y ∈ dualCode C)
    (h0 : firstPart n m y = 0) (h1 : lastPart n m y = fun _ => 1) :
    ∀ x ∈ C, (∑ i : Fin m, lastPart n m x i) = 0 := by
  intro x hx
  have hh := hy x hx
  unfold dotWord at hh
  rw [Fin.sum_univ_add] at hh
  have hzero : ∀ i : Fin n, y (Fin.castAdd m i) = 0 := congrFun h0
  have hone : ∀ i : Fin m, y (Fin.natAdd n i) = 1 := congrFun h1
  change (∑ i : Fin m, x (Fin.natAdd n i)) = 0
  simpa only [hzero, hone, mul_zero, Finset.sum_const_zero, mul_one, zero_add] using hh

end ECC
