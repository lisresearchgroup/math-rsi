import ECC.Basic

namespace ECC

/-- Coordinate permutation only: the original Hamming metric is preserved. -/
def permuteWord {n : ℕ} (e : Fin n ≃ Fin n) : Word n ≃ₗ[F2] Word n where
  toFun x i := x (e i)
  invFun x i := x (e.symm i)
  left_inv x := by funext i; simp
  right_inv x := by funext i; simp
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

@[simp] theorem permuteWord_apply {n : ℕ} (e : Fin n ≃ Fin n) (x : Word n) (i : Fin n) :
    permuteWord e x i = x (e i) := rfl

@[simp] theorem weight_permuteWord {n : ℕ} (e : Fin n ≃ Fin n) (x : Word n) :
    weight (permuteWord e x) = weight x := by
  classical
  unfold weight
  change (Finset.univ.filter (fun i => x (e i) ≠ 0)).card =
    (Finset.univ.filter (fun i => x i ≠ 0)).card
  simp only [Finset.card_filter]
  exact Equiv.sum_comp e (fun i => if x i ≠ 0 then (1 : ℕ) else 0)

def permuteCode {n : ℕ} (e : Fin n ≃ Fin n) (C : Submodule F2 (Word n)) :
    Submodule F2 (Word n) := C.map (permuteWord e).toLinearMap

@[simp] theorem mem_permuteCode {n : ℕ} (e : Fin n ≃ Fin n)
    (C : Submodule F2 (Word n)) (x : Word n) :
    permuteWord e x ∈ permuteCode e C ↔ x ∈ C := by
  constructor
  · rintro ⟨y, hy, hxy⟩
    exact (permuteWord e).injective hxy ▸ hy
  · intro hx
    exact ⟨x, hx, rfl⟩

theorem permuteCode_minWeight {n d : ℕ} (e : Fin n ≃ Fin n)
    (C : Submodule F2 (Word n)) (h : MinWeight C d) :
    MinWeight (permuteCode e C) d := by
  rintro y ⟨x, hx, rfl⟩ hne
  change d ≤ weight (permuteWord e x)
  rw [weight_permuteWord]
  apply h x hx
  intro hz
  exact hne (by simp [hz])

theorem permuteCode_even {n : ℕ} (e : Fin n ≃ Fin n)
    (C : Submodule F2 (Word n)) (h : EvenCode C) : EvenCode (permuteCode e C) := by
  rintro y ⟨x, hx, rfl⟩
  simpa using h x hx

/-- Equivalence under a permutation of coordinates, not arbitrary GL(n,2). -/
def CoordinateEquivalent {n : ℕ} (C D : Submodule F2 (Word n)) : Prop :=
  ∃ e : Fin n ≃ Fin n, permuteCode e C = D

theorem coordinateEquivalent_refl {n : ℕ} (C : Submodule F2 (Word n)) :
    CoordinateEquivalent C C := by
  refine ⟨Equiv.refl _, ?_⟩
  ext x
  change (∃ y, y ∈ C ∧ permuteWord (Equiv.refl _) y = x) ↔ x ∈ C
  simp [permuteWord]

theorem coordinateEquivalent_symm {n : ℕ} {C D : Submodule F2 (Word n)}
    (h : CoordinateEquivalent C D) : CoordinateEquivalent D C := by
  obtain ⟨e, rfl⟩ := h
  refine ⟨e.symm, ?_⟩
  ext x
  constructor
  · rintro ⟨y, ⟨z, hz, rfl⟩, rfl⟩
    simpa [permuteWord] using hz
  · intro hx
    refine ⟨permuteWord e x, ⟨x, hx, rfl⟩, ?_⟩
    funext i
    simp

end ECC
