import Task.PolynomialMarkedDotValues

/-! The signed dot-product counts of the local Fourier transform, checked on all classes. -/

open scoped BigOperators
open Finset Matrix

namespace AlonJaegerTarsi.MarkedEleven

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩

set_option Elab.async false
set_option maxHeartbeats 0
set_option maxRecDepth 100000

def dotCount (p : OM) (t : Tuple) (a : ZMod 5) : ℕ :=
  (univ.filter (fun u : Tuple => vTag u = p ∧ u ⬝ᵥ t = a)).card

private theorem dotCount_members (p : OM) (t : Tuple) (a : ZMod 5) :
    dotCount p t a = memberDotCount p t a := by
  classical
  symm
  apply Finset.card_bij (fun (i : Fin (orbitSize p)) _ => member p i.val)
  · intro i hi
    rw [Finset.mem_filter] at hi ⊢
    exact ⟨Finset.mem_univ _, vTag_member p i, hi.2⟩
  · intro i _ j _ hij
    apply Fin.ext
    simpa only [orbitRank_member] using congrArg orbitRank hij
  · intro v hv
    obtain ⟨_,hp,hd⟩ := Finset.mem_filter.mp hv
    subst p
    let i : Fin (orbitSize (vTag v)) := ⟨orbitRank v, orbitRank_lt v⟩
    refine ⟨i, Finset.mem_filter.mpr ⟨Finset.mem_univ _, ?_⟩, member_rank v⟩
    simpa only [i, member_rank] using hd

private def dualTransport (s : (ZMod 5)ˣ) (g : Fin 12) : Tuple ≃ Tuple where
  toFun v i := s.val * v ((sitePerm g).symm i)
  invFun v i := (↑s⁻¹ : ZMod 5) * v (sitePerm g i)
  left_inv v := by
    funext i
    change (↑s⁻¹ : ZMod 5) * (↑s * v ((sitePerm g).symm (sitePerm g i))) = v i
    rw [Equiv.symm_apply_apply, ← mul_assoc, Units.inv_mul, one_mul]
  right_inv v := by
    funext i
    change (↑s : ZMod 5) * (↑s⁻¹ * v (sitePerm g ((sitePerm g).symm i))) = v i
    rw [Equiv.apply_symm_apply, ← mul_assoc, Units.mul_inv, one_mul]

private theorem transport_tag (s : (ZMod 5)ˣ) (g : Fin 12) (v : Tuple) :
    vTag (dualTransport s g v) = vTag v := by
  let v' : Tuple := fun i => v ((sitePerm g).symm i)
  have h := vTag_perm v' g
  have he : (fun i => v' (sitePerm g i)) = v := by funext i; simp [v']
  rw [he] at h
  exact (vTag_scale v' s.val s.ne_zero).trans h.symm

private theorem transport_dot (t : Tuple) (ht : ∑ i, t i = 0) (v : Tuple) :
    dualTransport (Units.mk0 (scalarToRep t) (tag_rep_action t ht).1) (permToRep t) v ⬝ᵥ
        pRep (pTag t) = v ⬝ᵥ t := by
  let g := sitePerm (permToRep t)
  change (∑ i, (scalarToRep t * v (g.symm i)) * pRep (pTag t) i) = ∑ i, v i * t i
  rw [← Equiv.sum_comp g (fun i => scalarToRep t * v (g.symm i) * pRep (pTag t) i)]
  apply Finset.sum_congr rfl
  intro i _
  rw [g.symm_apply_apply, (tag_rep_action t ht).2 i]
  ring

private theorem dotCount_rep (t : Tuple) (ht : ∑ i, t i = 0) (p : OM) (a : ZMod 5) :
    dotCount p t a = dotCount p (pRep (pTag t)) a := by
  classical
  let s := Units.mk0 (scalarToRep t) (tag_rep_action t ht).1
  let e := dualTransport s (permToRep t)
  apply Finset.card_bijective e e.bijective
  intro v
  simp only [Finset.mem_filter, Finset.mem_univ, true_and, e, transport_tag, s, transport_dot t ht]

/-- The finite normal-site transform at a primal tuple is the difference between the
numbers of dual orbit members with dot product zero and with dot product one. -/
theorem local_dot_counts (p : OM) (t : Tuple) (h : ∑ i, t i = 0) :
    K p (pTag t) =
      ((univ.filter (fun v : Tuple => vTag v = p ∧ v ⬝ᵥ t = 0)).card : ℤ) -
      ((univ.filter (fun v : Tuple => vTag v = p ∧ v ⬝ᵥ t = 1)).card : ℤ) := by
  change K p (pTag t) = (dotCount p t 0 : ℤ) - (dotCount p t 1 : ℤ)
  rw [dotCount_rep t h p 0, dotCount_rep t h p 1, dotCount_members, dotCount_members]
  exact rep_correct p (pTag t)

end AlonJaegerTarsi.MarkedEleven
