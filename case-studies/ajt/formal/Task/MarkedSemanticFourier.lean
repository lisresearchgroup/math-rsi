import Task.MarkedCounts

namespace AlonJaegerTarsi.MarkedEleven

open Matrix Finset WeightTransform MarkedFourier
open scoped BigOperators

noncomputable section

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩
attribute [local irreducible] vTag pTag K

def rawDotCount (o : OM) (t : Tuple) (s : ZMod 5) : ℕ :=
  (univ.filter fun v : Tuple => vTag v = o ∧ v ⬝ᵥ t = s).card

/-- A scalar-invariant class has equal dot-product counts at all nonzero field values. -/
theorem rawDotCount_eq_one (scale : ∀ (v : Tuple) (a : ZMod 5), a ≠ 0 → vTag (a • v) = vTag v)
    (o : OM) (t : Tuple) {s : ZMod 5} (hs : s ≠ 0) : rawDotCount o t 1 = rawDotCount o t s := by
  classical
  let e := LinearEquiv.smulOfUnit (R := ZMod 5) (M := Tuple) (Units.mk0 s hs)
  have happ (v : Tuple) : e v = s • v := rfl
  apply Finset.card_bijective e e.bijective
  intro v
  simp only [mem_filter, mem_univ, true_and, happ, scale v s hs, smul_dotProduct, smul_eq_mul]
  apply and_congr_right
  intro _
  exact ⟨fun h => by rw [h, mul_one], fun h => mul_left_cancel₀ hs (h.trans (mul_one s).symm)⟩

/-- Compute the complex character sum of a five-coordinate class by two integer counts. -/
theorem local_character_of_counts
    (scale : ∀ (v : Tuple) (a : ZMod 5), a ≠ 0 → vTag (a • v) = vTag v)
    (o : OM) (t : Tuple) :
    (∑ v ∈ univ.filter (fun v : Tuple => vTag v = o), ZMod.stdAddChar (v ⬝ᵥ t)) =
      (rawDotCount o t 0 : ℂ) - (rawDotCount o t 1 : ℂ) := by
  classical
  let S := univ.filter (fun v : Tuple => vTag v = o)
  have H (s : ZMod 5) :
      (∑ v ∈ S.filter (fun v => v ⬝ᵥ t = s), ZMod.stdAddChar (v ⬝ᵥ t)) =
        (rawDotCount o t s : ℂ) * ZMod.stdAddChar s := by
    calc
      _ = ∑ _v ∈ S.filter (fun v => v ⬝ᵥ t = s), ZMod.stdAddChar s :=
        sum_congr rfl fun v hv => congrArg _ (mem_filter.mp hv).2
      _ = _ := by simp [S, rawDotCount, filter_filter]
  have allsum : (∑ s : ZMod 5, ZMod.stdAddChar s) = 0 := by
    simpa using AddChar.sum_mulShift (1 : ZMod 5) (ZMod.isPrimitive_stdAddChar 5)
  have equal (s : ZMod 5) :
      (rawDotCount o t s : ℂ) * ZMod.stdAddChar s =
      (rawDotCount o t 1 : ℂ) * ZMod.stdAddChar s +
        if s=0 then (rawDotCount o t 0 : ℂ) - (rawDotCount o t 1 : ℂ) else 0 := by
    by_cases hs : s = 0
    · subst s
      simp
    · simp [hs, rawDotCount_eq_one scale o t hs]
  calc
    _ = ∑ s : ZMod 5, ∑ v ∈ S.filter (fun v => v ⬝ᵥ t = s), ZMod.stdAddChar (v ⬝ᵥ t) :=
      (sum_fiberwise S (fun v => v ⬝ᵥ t) _).symm
    _ = _ := by simp only [H, equal, sum_add_distrib, ← mul_sum, allsum]; simp

/-- Apply the dimension-independent marked-site identity to the actual tables of B.
The two local hypotheses only concern tuples in the five displayed sites. -/
theorem actual_marked_transform (B : Matrix11)
    (hmark : ∀ x : Word, (∑ i, mark 3 8 2 9 x (B *ᵥ x) i) = 0)
    (scale : ∀ (v : Tuple) (a : ZMod 5), a ≠ 0 → vTag (a • v) = vTag v)
    (hlocal : ∀ (o : OM) (t : Tuple), (∑ i, t i) = 0 →
      K o (pTag t) = (rawDotCount o t 0 : ℤ) - rawDotCount o t 1) (p : OM) (k : X) (l : Y) :
    (5 : ℤ)^11 * dualTable B p k l =
      ∑ o, ∑ b, ∑ d, primalTable B o b d * K p o * kraw 5 8 k b * kraw 5 9 l d := by
  classical
  let S := univ.filter fun v : Tuple => vTag v = p
  have he := marked_macWilliams (a := 3) (b := 8) (c := 2) (d := 9) B S k l
  have hset : univ.filter (fun y : Word => mark 3 8 2 9 (-(Bᵀ *ᵥ y)) y ∈ S ∧
        wt (back 3 8 (-(Bᵀ *ᵥ y))) = k ∧ wt (back 2 9 y) = l) =
      univ.filter (fun y => dualKey B y = (p,k,l)) := by
    ext y
    simp [S, dualKey, Prod.ext_iff, wtIndex, Fin.ext_iff]
  let f (cell : Cell) : ℂ := (K p cell.1 : ℂ) * (kraw 5 8 k cell.2.1 : ℂ) *
    (kraw 5 9 l cell.2.2 : ℂ)
  have hs (x : Word) : (∑ q ∈ S, ZMod.stdAddChar (q ⬝ᵥ mark 3 8 2 9 x (B *ᵥ x))) =
      (K p (pTag (mark 3 8 2 9 x (B *ᵥ x))) : ℂ) := by
    rw [hlocal _ _ (hmark x), Int.cast_sub, Int.cast_natCast, Int.cast_natCast]
    exact local_character_of_counts scale _ _
  rw [hset] at he
  simp_rw [hs] at he
  change _ = ∑ x, f (primalKey B x) at he
  rw [sum_fiberTable] at he
  simp only [f, ← mul_assoc] at he
  exact_mod_cast he

end
end AlonJaegerTarsi.MarkedEleven
