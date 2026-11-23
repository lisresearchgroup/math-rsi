import ECC42.Parity
import Mathlib.Algebra.Field.ZMod
import Mathlib.LinearAlgebra.Dimension.Free
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas

namespace ECC42

/-- Restrict a code to a subcode of any smaller prescribed dimension. -/
theorem codeExists_of_finrank_ge {n k d : ℕ} (C : Submodule F2 (Word n))
    (hk : k ≤ Module.finrank F2 C) (hmin : MinWeight C d) : CodeExists n k d := by
  have hr : Module.finrank F2 (Word k) ≤ Module.finrank F2 C := by
    simpa [Word] using hk
  obtain ⟨f, hf⟩ := finrank_le_iff_exists_linearMap.mp hr
  let g : Word k →ₗ[F2] Word n := C.subtype.comp f
  have hg : Function.Injective g := Subtype.val_injective.comp hf
  refine ⟨LinearMap.range g, ?_, ?_⟩
  · rw [LinearMap.finrank_range_of_inj hg]
    simp [Word]
  · rintro y ⟨x, rfl⟩ hy
    exact hmin _ (f x).property hy

/-- One shortening, followed if needed by passage to a subcode, loses exactly
one dimension and does not decrease the minimum-weight bound. -/
theorem codeExists_shorten {n k d : ℕ} (h : CodeExists (n + 1) k d) :
    CodeExists n (k - 1) d := by
  obtain ⟨C, hdim, hmin⟩ := h
  let p : C →ₗ[F2] F2 :=
    { toFun := fun x => x.val 0
      map_add' := fun _ _ => rfl
      map_smul' := fun _ _ => rfl }
  let K := LinearMap.ker p
  let f : K →ₗ[F2] Word n :=
    { toFun := fun x i => x.val.val i.succ
      map_add' := fun _ _ => rfl
      map_smul' := fun _ _ => rfl }
  have hf : Function.Injective f := by
    intro x y hxy
    apply Subtype.ext
    apply Subtype.ext
    funext i
    refine Fin.cases ?_ (fun j => ?_) i
    · have hx : x.val.val 0 = 0 := x.property
      have hy : y.val.val 0 = 0 := y.property
      exact hx.trans hy.symm
    · exact congrFun hxy j
  have hweight (x : K) : weight (f x) = weight x.val.val := by
    have hx : x.val.val 0 = 0 := x.property
    have heq : x.val.val = Fin.cons 0 (f x) := by
      funext i
      refine Fin.cases ?_ (fun j => ?_) i
      · simpa using hx
      · rfl
    rw [heq, weight_cons]
    simp
  have hr : Module.finrank F2 (LinearMap.range p) ≤ 1 := by
    simpa using (Submodule.finrank_le (LinearMap.range p))
  have hK : k - 1 ≤ Module.finrank F2 K := by
    have he := p.finrank_range_add_finrank_ker
    rw [hdim] at he
    change k - 1 ≤ Module.finrank F2 (LinearMap.ker p)
    omega
  apply codeExists_of_finrank_ge (LinearMap.range f)
  · rw [LinearMap.finrank_range_of_inj hf]
    exact hK
  · rintro y ⟨x, rfl⟩ hy
    rw [hweight]
    apply hmin _ x.val.property
    intro hz
    apply hy
    funext i
    exact congrFun hz i.succ

end ECC42
