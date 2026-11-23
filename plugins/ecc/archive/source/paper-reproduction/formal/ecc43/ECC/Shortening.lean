import ECC.ShorteningCore
import Mathlib.Tactic.FinCases

set_option maxHeartbeats 1000000

namespace ECC

def LastFourEven (C : Submodule F2 (Word 44)) : Prop :=
  ∀ x ∈ C, ∑ i : Fin 4, lastPart 40 4 x i = 0

def tripleIndex (i : Fin 3) : Fin 44 := Fin.natAdd 40 (Fin.castAdd 1 i)

theorem tripleIndex_injective : Function.Injective tripleIndex := by
  intro i j h
  apply Fin.ext
  have := congrArg Fin.val h
  simpa [tripleIndex] using this

def tripleProjection (C : Submodule F2 (Word 44)) : C →ₗ[F2] Word 3 :=
  (coordinateProjection tripleIndex).comp C.subtype

theorem four_ext_of_sum {v w : Word 4} (hv : ∑ i, v i = 0) (hw : ∑ i, w i = 0)
    (h : ∀ i : Fin 3, v (Fin.castAdd 1 i) = w (Fin.castAdd 1 i)) : v = w := by
  have h0 := h 0
  have h1 := h 1
  have h2 := h 2
  simp [Fin.sum_univ_succ] at hv hw
  change v 0 = w 0 at h0
  change v 1 = w 1 at h1
  change v 2 = w 2 at h2
  change v 0 + (v 1 + (v 2 + v 3)) = 0 at hv
  change w 0 + (w 1 + (w 2 + w 3)) = 0 at hw
  funext i
  fin_cases i
  · exact h0
  · exact h1
  · exact h2
  · rw [h0, h1, h2] at hv
    exact add_left_cancel (add_left_cancel (add_left_cancel (hv.trans hw.symm)))

theorem lastPart_zero_of_triple_zero (C : Submodule F2 (Word 44)) (hC : LastFourEven C)
    (x : C) (hz : tripleProjection C x = 0) : lastPart 40 4 x.val = 0 := by
  apply four_ext_of_sum (hC x x.property) (by simp)
  intro i
  exact congrFun hz i

noncomputable def shortenedTripleKerEquiv (C : Submodule F2 (Word 44))
    (hC : LastFourEven C) :
    LinearMap.ker (tripleProjection C) ≃ₗ[F2] shortenedCode (n := 40) (m := 4) C :=
  LinearEquiv.ofBijective
    ({ toFun := fun x => ⟨firstPart 40 4 x.val.val, by
        change joinWord (firstPart 40 4 x.val.val) (0 : Word 4) ∈ C
        have hz := lastPart_zero_of_triple_zero C hC x.val x.property
        rw [← hz, join_parts]
        exact x.val.property⟩
       map_add' := by intros; rfl
       map_smul' := by intros; rfl } : LinearMap.ker (tripleProjection C) →ₗ[F2] shortenedCode (n := 40) (m := 4) C)
    (by
      constructor
      · intro x y h
        apply Subtype.ext
        apply Subtype.ext
        have hx := lastPart_zero_of_triple_zero C hC x.val x.property
        have hy := lastPart_zero_of_triple_zero C hC y.val y.property
        have hh : firstPart 40 4 x.val.val = firstPart 40 4 y.val.val := congrArg Subtype.val h
        rw [← join_parts (n := 40) (m := 4) x.val.val, ← join_parts (n := 40) (m := 4) y.val.val, hx, hy, hh]
      · intro a
        refine ⟨⟨⟨joinWord a.val (0 : Word 4), a.property⟩, ?_⟩, ?_⟩
        · change tripleProjection C ⟨joinWord a.val (0 : Word 4), a.property⟩ = 0
          funext i
          simp [tripleProjection, coordinateProjection, tripleIndex, joinWord]
        · apply Subtype.ext
          exact firstPart_join _ _)

theorem tripleProjection_surjective (C : Submodule F2 (Word 44))
    (hdual : MinWeight (dualCode C) 4) : Function.Surjective (tripleProjection C) :=
  projection_surjective_of_dual_minWeight C tripleIndex tripleIndex_injective (by decide) hdual

theorem shortened40_finrank (C : Submodule F2 (Word 44)) (hdim : Module.finrank F2 C = 10)
    (heven : LastFourEven C) (hdual : MinWeight (dualCode C) 4) :
    Module.finrank F2 (shortenedCode (n := 40) (m := 4) C) = 7 := by
  have hk := (tripleProjection C).finrank_range_add_finrank_ker
  have hr : Module.finrank F2 (LinearMap.range (tripleProjection C)) = 3 := by
    rw [LinearMap.range_eq_top.mpr (tripleProjection_surjective C hdual)]
    simp [Word, F2]
  rw [hr, hdim, (shortenedTripleKerEquiv C heven).finrank_eq] at hk
  omega

theorem exists_standard_rows (C : Submodule F2 (Word 44))
    (hLast : LastFourEven C) (hdual : MinWeight (dualCode C) 4) :
    ∃ a b c : Word 40,
      StandardExtension (shortenedCode (n := 40) (m := 4) C) a b c ≤ C := by
  have hs := tripleProjection_surjective C hdual
  obtain ⟨xa, hxa⟩ := hs (Pi.single 0 1)
  obtain ⟨xb, hxb⟩ := hs (Pi.single 1 1)
  obtain ⟨xc, hxc⟩ := hs (Pi.single 2 1)
  have ha : lastPart 40 4 xa.val = tail1 := by
    apply four_ext_of_sum (hLast xa xa.property) (by decide)
    intro i
    have h := congrFun hxa i
    fin_cases i <;> simpa [tripleProjection, coordinateProjection, tripleIndex, tail1,
      lastPart, Pi.single_apply] using h
  have hb : lastPart 40 4 xb.val = tail2 := by
    apply four_ext_of_sum (hLast xb xb.property) (by decide)
    intro i
    have h := congrFun hxb i
    fin_cases i <;> simpa [tripleProjection, coordinateProjection, tripleIndex, tail2,
      lastPart, Pi.single_apply] using h
  have hc : lastPart 40 4 xc.val = tail3 := by
    apply four_ext_of_sum (hLast xc xc.property) (by decide)
    intro i
    have h := congrFun hxc i
    fin_cases i <;> simpa [tripleProjection, coordinateProjection, tripleIndex, tail3,
      lastPart, Pi.single_apply] using h
  refine ⟨firstPart 40 4 xa.val, firstPart 40 4 xb.val, firstPart 40 4 xc.val, ?_⟩
  apply Submodule.span_le.mpr
  intro x hx
  rcases hx with ⟨k, rfl⟩ | hx
  · exact k.property
  · rcases hx with hx | hx | hx
    · subst x
      change joinWord (firstPart 40 4 xa.val) tail1 ∈ C
      rw [← ha, join_parts]
      exact xa.property
    · subst x
      change joinWord (firstPart 40 4 xb.val) tail2 ∈ C
      rw [← hb, join_parts]
      exact xb.property
    · rw [Set.mem_singleton_iff] at hx
      subst x
      change joinWord (firstPart 40 4 xc.val) tail3 ∈ C
      rw [← hc, join_parts]
      exact xc.property

@[simp] theorem dotWord_joinWord {n m : ℕ} (a c : Word n) (b d : Word m) :
    dotWord (joinWord a b) (joinWord c d) = dotWord a c + dotWord b d := by
  rw [dotWord, Fin.sum_univ_add]
  simp [joinWord, dotWord]

@[simp] theorem weight_single_one {n : ℕ} (i : Fin n) :
    weight (Pi.single i (1 : F2)) = 1 := by
  classical
  unfold weight
  have hs : Finset.univ.filter (fun x : Fin n => (Pi.single i (1 : F2) : Word n) x ≠ 0) = {i} := by
    ext j
    by_cases h : j = i <;> simp [Pi.single_apply, h, Ne.symm]
  rw [hs]
  simp

/-- Complementing the four tail coefficients by the known parity relation
always leaves a representative of weight at most two. This is an exact
finite-field lemma, checked by kernel computation over eight linear forms. -/
theorem small_tail_representative : ∀ z : Word 3, ∃ t : Word 4,
    weight t ≤ 2 ∧ ∀ v : Word 4, (∑ i, v i) = 0 →
      dotWord v t = dotWord (fun i : Fin 3 => v (Fin.castAdd 1 i)) z := by
  decide +kernel

theorem shortened40_fullSupport (C : Submodule F2 (Word 44))
    (hLast : LastFourEven C) (hdual : MinWeight (dualCode C) 4) :
    FullSupport (shortenedCode (n := 40) (m := 4) C) := by
  classical
  intro j
  by_contra hmissing
  have hzero : ∀ k ∈ shortenedCode (n := 40) (m := 4) C, k j = 0 := by
    simpa only [not_exists, not_and, not_not] using hmissing
  let f := tripleProjection C
  obtain ⟨s, hs⟩ := f.exists_rightInverse_of_surjective
    (LinearMap.range_eq_top.mpr (tripleProjection_surjective C hdual))
  let l : Word 3 →ₗ[F2] F2 :=
    (LinearMap.proj j).comp ((firstPart 40 4).comp (C.subtype.comp s))
  have hfactor : ∀ x : C, firstPart 40 4 x.val j = l (f x) := by
    intro x
    have hfs : f (s (f x)) = f x := LinearMap.congr_fun hs (f x)
    have hu : f (x - s (f x)) = 0 := by rw [map_sub, hfs, sub_self]
    have htail := lastPart_zero_of_triple_zero C hLast (x - s (f x)) hu
    have hmem : firstPart 40 4 (x - s (f x)).val ∈ shortenedCode (n := 40) (m := 4) C := by
      change joinWord (firstPart 40 4 (x - s (f x)).val) (0 : Word 4) ∈ C
      rw [← htail, join_parts]
      exact (x - s (f x)).property
    have hh := hzero _ hmem
    change firstPart 40 4 x.val j - firstPart 40 4 (s (f x)).val j = 0 at hh
    exact sub_eq_zero.mp hh
  let z : Word 3 := fun i => l (Pi.single i 1)
  obtain ⟨t, htweight, ht⟩ := small_tail_representative z
  let y := joinWord (Pi.single j (1 : F2)) t
  have hymem : y ∈ dualCode C := by
    intro x hx
    change dotWord x (joinWord (Pi.single j 1) t) = 0
    rw [← join_parts (n := 40) (m := 4) x, dotWord_joinWord]
    have hdot : dotWord (firstPart 40 4 x) (Pi.single j 1) = firstPart 40 4 x j := by
      simp [dotWord, Pi.single_apply, mul_ite]
    rw [hdot, ht _ (hLast x hx)]
    change firstPart 40 4 x j + dotWord (f ⟨x, hx⟩) z = 0
    rw [← functional_eq_dotWord l, ← hfactor ⟨x, hx⟩]
    exact CharTwo.add_self_eq_zero _
  have hyne : y ≠ 0 := by
    intro hz
    have hj := congrFun (congrArg (firstPart 40 4) hz) j
    simp [y, firstPart, joinWord] at hj
  have hd := hdual y hymem hyne
  have hw : weight y = 1 + weight t := by simp [y]
  omega

theorem shortened_standard_reduction (C : Submodule F2 (Word 44))
    (hdim : Module.finrank F2 C = 10) (hmin : MinWeight C 18) (heven : EvenCode C)
    (hLast : LastFourEven C) (hdual : MinWeight (dualCode C) 4) :
    ∃ K : Submodule F2 (Word 40), ∃ a b c : Word 40,
      Module.finrank F2 K = 7 ∧ MinWeight K 18 ∧ EvenCode K ∧ FullSupport K ∧
      EvenCode (StandardExtension K a b c) ∧ MinWeight (StandardExtension K a b c) 18 := by
  obtain ⟨a,b,c,hle⟩ := exists_standard_rows C hLast hdual
  refine ⟨shortenedCode (n := 40) (m := 4) C, a,b,c, shortened40_finrank C hdim hLast hdual,
    shortenedCode_minWeight (n := 40) (m := 4) C hmin,
    shortenedCode_even (n := 40) (m := 4) C heven,
    shortened40_fullSupport C hLast hdual, ?_, ?_⟩
  · intro x hx
    exact heven x (hle hx)
  · intro x hx hne
    exact hmin x (hle hx) hne

end ECC
