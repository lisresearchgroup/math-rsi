import Task.PolynomialMarkedDotData

/-! The signed dot-product counts of the local Fourier transform, checked on all classes. -/

open scoped BigOperators
open Finset Matrix

namespace AlonJaegerTarsi.MarkedEleven

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩

set_option Elab.async false
set_option maxHeartbeats 0
set_option maxRecDepth 100000

def memberDotCount (p : OM) (t : Tuple) (a : ZMod 5) : ℕ :=
  (univ.filter (fun i : Fin (orbitSize p) => member p i.val ⬝ᵥ t = a)).card

private def repCorrect (p o : OM) : Prop :=
  K p o = (memberDotCount p (pRep o) 0 : ℤ) - (memberDotCount p (pRep o) 1 : ℤ)

private def repCorrectDec (p o : OM) : Decidable (repCorrect p o) := by
  unfold repCorrect
  infer_instance

private theorem checkRep (p : OM)
    (h : @decide _ (@Nat.decidableForallFin 29 (repCorrect p) (repCorrectDec p)) = true) :
    ∀ o, repCorrect p o := @of_decide_eq_true _ (@Nat.decidableForallFin 29 (repCorrect p) (repCorrectDec p)) h
private theorem rep0 : ∀ o, repCorrect 0 o := checkRep 0 (by decide)
private theorem rep1 : ∀ o, repCorrect 1 o := checkRep 1 (by decide)
private theorem rep2 : ∀ o, repCorrect 2 o := checkRep 2 (by decide)
private theorem rep3 : ∀ o, repCorrect 3 o := checkRep 3 (by decide)
private theorem rep4 : ∀ o, repCorrect 4 o := checkRep 4 (by decide)
private theorem rep5 : ∀ o, repCorrect 5 o := checkRep 5 (by decide)
private theorem rep6 : ∀ o, repCorrect 6 o := checkRep 6 (by decide)
private theorem rep7 : ∀ o, repCorrect 7 o := checkRep 7 (by decide)
private theorem rep8 : ∀ o, repCorrect 8 o := checkRep 8 (by decide)
private theorem rep9 : ∀ o, repCorrect 9 o := checkRep 9 (by decide)
private theorem rep10 : ∀ o, repCorrect 10 o := checkRep 10 (by decide)
private theorem rep11 : ∀ o, repCorrect 11 o := checkRep 11 (by decide)
private theorem rep12 : ∀ o, repCorrect 12 o := checkRep 12 (by decide)
private theorem rep13 : ∀ o, repCorrect 13 o := checkRep 13 (by decide)
private theorem rep14 : ∀ o, repCorrect 14 o := checkRep 14 (by decide)
private theorem rep15 : ∀ o, repCorrect 15 o := checkRep 15 (by decide)
private theorem rep16 : ∀ o, repCorrect 16 o := checkRep 16 (by decide)
private theorem rep17 : ∀ o, repCorrect 17 o := checkRep 17 (by decide)
private theorem rep18 : ∀ o, repCorrect 18 o := checkRep 18 (by decide)
private theorem rep19 : ∀ o, repCorrect 19 o := checkRep 19 (by decide)
private theorem rep20 : ∀ o, repCorrect 20 o := checkRep 20 (by decide)
private theorem rep21 : ∀ o, repCorrect 21 o := checkRep 21 (by decide)
private theorem rep22 : ∀ o, repCorrect 22 o := checkRep 22 (by decide)
private theorem rep23 : ∀ o, repCorrect 23 o := checkRep 23 (by decide)
private theorem rep24 : ∀ o, repCorrect 24 o := checkRep 24 (by decide)
private theorem rep25 : ∀ o, repCorrect 25 o := checkRep 25 (by decide)
private theorem rep26 : ∀ o, repCorrect 26 o := checkRep 26 (by decide)
private theorem rep27 : ∀ o, repCorrect 27 o := checkRep 27 (by decide)
private theorem rep28 : ∀ o, repCorrect 28 o := checkRep 28 (by decide)

theorem rep_correct (p : OM) : ∀ o, K p o =
    (memberDotCount p (pRep o) 0 : ℤ) - (memberDotCount p (pRep o) 1 : ℤ) := by
  fin_cases p
  · exact rep0
  · exact rep1
  · exact rep2
  · exact rep3
  · exact rep4
  · exact rep5
  · exact rep6
  · exact rep7
  · exact rep8
  · exact rep9
  · exact rep10
  · exact rep11
  · exact rep12
  · exact rep13
  · exact rep14
  · exact rep15
  · exact rep16
  · exact rep17
  · exact rep18
  · exact rep19
  · exact rep20
  · exact rep21
  · exact rep22
  · exact rep23
  · exact rep24
  · exact rep25
  · exact rep26
  · exact rep27
  · exact rep28

end AlonJaegerTarsi.MarkedEleven
