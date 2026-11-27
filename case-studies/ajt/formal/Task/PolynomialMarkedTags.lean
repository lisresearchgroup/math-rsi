import Task.PolynomialMarkedTagValues

open Finset Matrix
open scoped BigOperators

namespace AlonJaegerTarsi.MarkedEleven

theorem vTag_realize (t : Tuple) (a : ZMod 5) :
    ∃ c : ZMod 5, leftWt (shifted t c) = shiftL (vTag t) a ∧
      rightWt (shifted t c) = shiftR (vTag t) a := by
  have h : (shiftL (vTag t) a, shiftR (vTag t) a) ∈ shiftWeights (vRep (vTag t)) := by
    exact Multiset.mem_map.mpr ⟨a, Finset.mem_univ a, rfl⟩
  rw [← vTag_weight_pairs t] at h
  obtain ⟨c, _, hc⟩ := Multiset.mem_map.mp h
  exact ⟨c, congrArg Prod.fst hc, congrArg Prod.snd hc⟩

theorem vwL_actual (t : Tuple) (u : Fin 4) : vwL (vTag t) u =
    ((univ.filter (fun a : ZMod 5 => leftWt (shifted t a) = u)).card : ℤ) := by
  have h := congrArg (fun m : Multiset (Fin 4 × Fin 3) => m.countP (fun a => a.1 = u))
    (vTag_weight_pairs t)
  simp only [shiftWeights, Multiset.countP_map] at h
  exact congrArg (fun n : ℕ => (n : ℤ)) h.symm

theorem vwR_actual (t : Tuple) (u : Fin 3) : vwR (vTag t) u =
    ((univ.filter (fun a : ZMod 5 => rightWt (shifted t a) = u)).card : ℤ) := by
  have h := congrArg (fun m : Multiset (Fin 4 × Fin 3) => m.countP (fun a => a.2 = u))
    (vTag_weight_pairs t)
  simp only [shiftWeights, Multiset.countP_map] at h
  exact congrArg (fun n : ℕ => (n : ℤ)) h.symm

end AlonJaegerTarsi.MarkedEleven
