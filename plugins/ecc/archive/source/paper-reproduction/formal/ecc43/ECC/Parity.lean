import ECC.Basic

namespace ECC

/-- Add the coordinate sum as the first coordinate. Over `F2`, this is the
ordinary parity extension. -/
def parityMap (n : ℕ) : Word n →ₗ[F2] Word (n + 1) where
  toFun x := Fin.cons (∑ i, x i) x
  map_add' x y := by
    funext i
    refine Fin.cases ?_ (fun j => ?_) i
    · simp [Finset.sum_add_distrib]
    · simp
  map_smul' a x := by
    funext i
    refine Fin.cases ?_ (fun j => ?_) i
    · simp [Finset.mul_sum]
    · simp

theorem parityMap_injective (n : ℕ) : Function.Injective (parityMap n) := by
  intro x y h
  funext i
  have hi := congrFun h i.succ
  simpa [parityMap] using hi

theorem weight_cast_eq_sum {n : ℕ} (x : Word n) :
    (weight x : F2) = ∑ i, x i := by
  classical
  rw [weight, Finset.natCast_card_filter]
  apply Finset.sum_congr rfl
  intro i _
  have h : x i = 0 ∨ x i = 1 := by
    have h₂ : ∀ a : F2, a = 0 ∨ a = 1 := by decide
    exact h₂ (x i)
  rcases h with h | h <;> simp [h]

theorem weight_cast_add {n : ℕ} (x y : Word n) :
    (weight (x + y) : F2) = (weight x : F2) + (weight y : F2) := by
  simp only [weight_cast_eq_sum, Pi.add_apply, Finset.sum_add_distrib]

theorem even_weight_add {n : ℕ} {x y : Word n}
    (hx : Even (weight x)) (hy : Even (weight y)) : Even (weight (x + y)) := by
  apply ZMod.natCast_eq_zero_iff_even.mp
  rw [weight_cast_add, hx.natCast_zmod_two, hy.natCast_zmod_two, add_zero]

theorem even_weight_of_even_sub {n : ℕ} {x y : Word n}
    (hx : Even (weight x)) (hsub : Even (weight (y - x))) : Even (weight y) := by
  have h := even_weight_add hsub hx
  simpa only [sub_add_cancel] using h

theorem weight_cons {n : ℕ} (a : F2) (x : Word n) :
    weight (Fin.cons a x) = (if a ≠ 0 then 1 else 0) + weight x := by
  classical
  simp only [weight, Finset.card_filter, Fin.sum_univ_succ,
    Fin.cons_zero, Fin.cons_succ]

theorem parityMap_weight_ge {n : ℕ} (x : Word n) :
    weight x ≤ weight (parityMap n x) := by
  change weight x ≤ weight (Fin.cons (∑ i, x i) x)
  rw [weight_cons]
  omega

theorem parityMap_weight_even {n : ℕ} (x : Word n) :
    Even (weight (parityMap n x)) := by
  apply ZMod.natCast_eq_zero_iff_even.mp
  rw [weight_cast_eq_sum]
  change (∑ i, Fin.cons (∑ j, x j) x i) = 0
  rw [Fin.sum_univ_succ]
  simpa using CharTwo.add_self_eq_zero (∑ i, x i)

/-- Extending an odd-distance binary linear code by a parity coordinate
preserves dimension and raises the distance bound to the next even integer. -/
theorem codeExists_even_extension {n k d : ℕ} (hd : Odd d)
    (h : CodeExists n k d) :
    ∃ T : Submodule F2 (Word (n + 1)),
      Module.finrank F2 T = k ∧ MinWeight T (d + 1) ∧ EvenCode T := by
  rcases h with ⟨C, hk, hmin⟩
  let f : C →ₗ[F2] Word (n + 1) := (parityMap n).comp C.subtype
  have hf : Function.Injective f :=
    (parityMap_injective n).comp Subtype.val_injective
  refine ⟨LinearMap.range f, ?_, ?_, ?_⟩
  · rw [LinearMap.finrank_range_of_inj hf]
    exact hk
  · rintro y ⟨x, rfl⟩ hy
    have hx : (x : Word n) ≠ 0 := by
      intro hx
      apply hy
      change parityMap n (x : Word n) = 0
      rw [hx, map_zero]
    have hbound := (hmin x x.property hx).trans (parityMap_weight_ge (x : Word n))
    have heven := parityMap_weight_even (x : Word n)
    rcases heven with ⟨a, ha⟩
    rcases hd with ⟨b, hb⟩
    change d + 1 ≤ weight (parityMap n (x : Word n))
    omega
  · rintro y ⟨x, rfl⟩
    exact parityMap_weight_even (x : Word n)

theorem code431017_to_even441018 (h : CodeExists 43 10 17) :
    ∃ T : Submodule F2 (Word 44),
      Module.finrank F2 T = 10 ∧ MinWeight T 18 ∧ EvenCode T := by
  exact codeExists_even_extension (by decide) h

/-- Delete the first coordinate. -/
def punctureMap (n : ℕ) : Word (n + 1) →ₗ[F2] Word n where
  toFun x i := x i.succ
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

theorem weight_eq_head_add_puncture {n : ℕ} (x : Word (n + 1)) :
    weight x = (if x 0 ≠ 0 then 1 else 0) + weight (punctureMap n x) := by
  simp only [weight, Finset.card_filter, Fin.sum_univ_succ]
  rfl

/-- Distance at least two makes puncturing injective, so it preserves dimension;
the distance bound decreases by at most one. -/
theorem codeExists_puncture {n k d : ℕ} (hd : 2 ≤ d)
    (h : CodeExists (n + 1) k d) : CodeExists n k (d - 1) := by
  rcases h with ⟨C, hk, hmin⟩
  let f : C →ₗ[F2] Word n := (punctureMap n).comp C.subtype
  have hf : Function.Injective f := by
    intro x y hxy
    apply sub_eq_zero.mp
    by_contra hne
    have hne' : ((x - y : C) : Word (n + 1)) ≠ 0 := by
      intro hz
      exact hne (Subtype.ext hz)
    have hz : f (x - y) = 0 := by rw [map_sub, hxy, sub_self]
    have hw := weight_eq_head_add_puncture ((x - y : C) : Word (n + 1))
    change punctureMap n ((x - y : C) : Word (n + 1)) = 0 at hz
    rw [hz, weight_zero] at hw
    have hb := hmin _ (x - y).property hne'
    split_ifs at hw <;> omega
  refine ⟨LinearMap.range f, ?_, ?_⟩
  · rw [LinearMap.finrank_range_of_inj hf]
    exact hk
  · rintro y ⟨x, rfl⟩ hy
    have hx : (x : Word (n + 1)) ≠ 0 := by
      intro hx
      apply hy
      change punctureMap n (x : Word (n + 1)) = 0
      rw [hx, map_zero]
    have hb := hmin _ x.property hx
    have hw := weight_eq_head_add_puncture (x : Word (n + 1))
    change d - 1 ≤ weight (punctureMap n (x : Word (n + 1)))
    split_ifs at hw <;> omega

theorem code431017_iff_even441018 :
    CodeExists 43 10 17 ↔
    ∃ T : Submodule F2 (Word 44),
      Module.finrank F2 T = 10 ∧ MinWeight T 18 ∧ EvenCode T := by
  constructor
  · exact code431017_to_even441018
  · rintro ⟨T, hdim, hmin, _⟩
    exact codeExists_puncture (by decide : 2 ≤ 18) ⟨T, hdim, hmin⟩

end ECC
