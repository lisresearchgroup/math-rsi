import ECC.Main
import ECC.TableLowerBoundData

namespace ECC

/-- Shortening one coordinate loses at most one dimension and does not decrease
the distance. Taking a subcode gives exactly the stated dimension, including
the case when the shortened coordinate was identically zero. -/
theorem codeExists_shorten_one {n k d : ℕ} (h : CodeExists (n+1) (k+1) d) :
    CodeExists n k d := by
  obtain ⟨C, hdim, hmin⟩ := h
  have hr := shortenedCode_finrank (n := n) (m := 1) C
  have hp : Module.finrank F2 (LinearMap.range (tailProjection (n := n) (m := 1) C)) ≤ 1 := by
    have h := Submodule.finrank_le (LinearMap.range (tailProjection (n := n) (m := 1) C))
    simpa [Word, F2] using h
  rw [hdim] at hr
  exact codeExists_of_finrank_ge (shortenedCode (n := n) (m := 1) C)
    (by omega) (shortenedCode_minWeight (n := n) (m := 1) C hmin)

theorem no_code441018_of_mainClaim (h : MainClaim) : ¬ CodeExists 44 10 18 := by
  intro hc
  exact h (codeExists_puncture (by decide : 2 ≤ 18) hc)

theorem no_code441117_of_mainClaim (h : MainClaim) : ¬ CodeExists 44 11 17 := by
  intro hc
  exact h (codeExists_shorten_one (n := 43) (k := 10) hc)

theorem no_code451118_of_mainClaim (h : MainClaim) : ¬ CodeExists 45 11 18 := by
  intro hc
  exact no_code441117_of_mainClaim h (codeExists_puncture (by decide : 2 ≤ 18) hc)

/-- Actual reconstructed matrix from the published quasicyclic lower bound. -/
theorem code441017 : CodeExists 44 10 17 := by
  have hd : Packed.distanceCheck 44 Packed.lower44_10.length 17 Packed.lower44_10 = true := by
    simpa only [Packed.lower44_10_verified.1] using Packed.lower44_10_verified.2.2
  have h := codeExists_of_distanceCheck (by decide : 0 < 17) hd
  simpa only [Packed.lower44_10_verified.1] using h

theorem code441116 : CodeExists 44 11 16 := by
  have hd : Packed.distanceCheck 44 Packed.lower44_11.length 16 Packed.lower44_11 = true := by
    simpa only [Packed.lower44_11_verified.1] using Packed.lower44_11_verified.2.2
  have h := codeExists_of_distanceCheck (by decide : 0 < 16) hd
  simpa only [Packed.lower44_11_verified.1] using h

def zeroExtend (n : ℕ) : Word n →ₗ[F2] Word (n+1) where
  toFun x := Fin.cons 0 x
  map_add' x y := by
    funext i
    refine Fin.cases ?_ (fun j => ?_) i <;> simp
  map_smul' a x := by
    funext i
    refine Fin.cases ?_ (fun j => ?_) i <;> simp

theorem codeExists_zeroExtend {n k d : ℕ} (h : CodeExists n k d) :
    CodeExists (n+1) k d := by
  obtain ⟨C, hdim, hmin⟩ := h
  let f : C →ₗ[F2] Word (n+1) := (zeroExtend n).comp C.subtype
  have hf : Function.Injective f := by
    intro x y hxy
    apply Subtype.ext
    funext i
    exact congrFun hxy i.succ
  refine ⟨f.range, ?_, ?_⟩
  · rw [LinearMap.finrank_range_of_inj hf]
    exact hdim
  · rintro y ⟨x, rfl⟩ hy
    have hx : (x : Word n) ≠ 0 := by
      intro hz
      apply hy
      change zeroExtend n (x : Word n) = 0
      rw [hz, map_zero]
    have hb := hmin x x.property hx
    change d ≤ weight (Fin.cons (0 : F2) (x : Word n))
    simpa only [weight_cons, ne_eq, not_true_eq_false, ite_false, zero_add] using hb

theorem code451116 : CodeExists 45 11 16 := codeExists_zeroExtend code441116

/-- The user's four table consequences, with every lower bound constructed
from an actual matrix and every upper bound proved by shortening/puncturing. -/
theorem four_table_consequences (h : MainClaim) :
    ThreeClosedEntries ∧ (CodeExists 45 11 16 ∧ ¬ CodeExists 45 11 18) := by
  exact ⟨⟨⟨code431016, h⟩, ⟨code441017, no_code441018_of_mainClaim h⟩,
    ⟨code441116, no_code441117_of_mainClaim h⟩⟩,
    code451116, no_code451118_of_mainClaim h⟩

theorem four_table_consequences_of_external_results
    (hE1 : PublishedNonexistence41) (hE2 : PublishedClassBound)
    (hDistinct : CatalogueInequivalent)
    (hComputed : ∀ i : Fin 172, PairIncompatible (catalogueCode i)) :
    ThreeClosedEntries ∧ (CodeExists 45 11 16 ∧ ¬ CodeExists 45 11 18) :=
  four_table_consequences (mainClaim_of_external_results hE1 hE2 hDistinct hComputed)

end ECC
