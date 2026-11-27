import Task.BalancedTranspose

open Matrix Finset
open scoped BigOperators

namespace AlonJaegerTarsi.BalancedCover

noncomputable section

open CharacterMethod

variable {p n : ℕ} [Fact p.Prime] {I : Type*} [Fintype I] [DecidableEq I]

/-- An affine hyperplane cover in which every single omission can be avoided
yields Boolean repair relations in the original, unaugmented coefficient space. -/
theorem repair_of_affine_cover (v : I → (Fin n → ZMod p)) (a : I → ZMod p)
    (blocked : ∀ x, ∃ i, v i ⬝ᵥ x = a i)
    (privatePoint : ∀ w, ∃ x, ∀ j, j ≠ w → v j ⬝ᵥ x ≠ a j)
    (b : I → ZMod p) (hb : ∀ i,b i ≠ 0) (w : I) :
    ∃ U ⊆ univ.erase w, ∃ T ⊆ univ.erase w,
      b w • v w = (∑ i ∈ U, b i • v i) - ∑ i ∈ T, b i • v i := by
  classical
  let u : Option I → (Fin (n+1) → ZMod p) := fun i =>
    i.elim (Pi.single 0 1) (fun j => Fin.cons (-a j) (v j))
  let d : Option I → ZMod p := fun i => i.elim 1 b
  have hd (i) : d i ≠ 0 := by cases i <;> simp [d, hb]
  have head (x : Fin (n+1) → ZMod p) : u none ⬝ᵥ x = x 0 := by simp [u]
  have coord (i : I) (x : Fin (n+1) → ZMod p) :
      u (some i) ⬝ᵥ x = -a i * x 0 + v i ⬝ᵥ (x ∘ Fin.succ) := by
    simp [u,dotProduct,Fin.sum_univ_succ]
  let g := fun i => d i • u i
  have hz : differences g univ = 0 := by
    apply eq_zero_of_charEval_eq_zero
    intro χ
    obtain ⟨x,rfl⟩ := dotChar_bijective.surjective χ
    by_contra h
    have hx := (eval_differences u univ d hd x).mp h
    have ht := hx none (mem_univ _)
    rw [head] at ht
    obtain ⟨j,hj⟩ := blocked ((x 0)⁻¹ • (x ∘ Fin.succ))
    rw [dotProduct_smul,smul_eq_mul] at hj
    have hi := hx (some j) (mem_univ _)
    rw [coord] at hi
    apply hi
    field_simp [ht] at hj
    linear_combination hj
  have he : differences g (univ.erase (some w)) ≠ 0 := by
    obtain ⟨x,hx⟩ := privatePoint w
    let z : Fin (n+1) → ZMod p := Fin.cons 1 x
    have hv : ∀ j ∈ univ.erase (some w), u j ⬝ᵥ z ≠ 0 := by
      rintro (_|j) hj
      · simp [head,z]
      · have hn : j ≠ w := fun hjw => (mem_erase.mp hj).1 (congrArg some hjw)
        rw [coord]
        have htail : z ∘ Fin.succ = x := by ext i; simp [z]
        rw [htail]
        change -a j * 1 + v j ⬝ᵥ x ≠ 0
        exact fun e => hx j hn (by linear_combination e)
    intro e
    apply (eval_differences u _ d hd z).mpr hv
    change charEval (dotChar z) (differences g (univ.erase (some w))) = 0
    rw [e,map_zero]
  obtain ⟨U,hU,T,hT,hrel⟩ := relation_of_essential g univ (some w) (mem_univ _) hz he
  have restrict (s : Finset (Option I)) (hs : s ⊆ univ.erase (some w)) : s.eraseNone ⊆ univ.erase w := by
    intro j hj
    exact mem_erase.mpr ⟨fun e => (mem_erase.mp (hs (mem_eraseNone.mp hj))).1 (congrArg some e),
      mem_univ _⟩
  have sums (s : Finset (Option I)) (j : Fin n) :
      (∑ i ∈ s,g i) j.succ = ∑ i ∈ s.eraseNone, b i * v i j := by
    rw [Finset.sum_apply, Finset.sum_eraseNone]
    apply sum_congr rfl
    rintro (_|i) _ <;> simp [g,d,u,Pi.single_apply]
  refine ⟨U.eraseNone, restrict _ hU, T.eraseNone, restrict _ hT, ?_⟩
  funext j
  have h := congrFun hrel j.succ
  simp only [Pi.sub_apply, sums] at h
  simpa [g,d,u, Finset.sum_apply, smul_eq_mul] using h

variable (A : Matrix (Fin n) (Fin n) (ZMod p))

/-- Being able to omit any one member of an actual affine cover makes every
shift achievable for the transpose. -/
theorem affine_transpose_of_irredundant (hp : 5 ≤ p) (a : Fin n ⊕ Fin n → ZMod p)
    (blocked : ∀ x, ∃ i, normals A i ⬝ᵥ x = a i)
    (privatePoint : ∀ w, ∃ x, ∀ j, j ≠ w → normals A j ⬝ᵥ x ≠ a j) :
    AffineReduction.AffineAJT Aᵀ := by
  classical
  let S := (univ : Finset (ZMod p)).erase 0
  have hs : Balanced S := balanced_nonzero (by rw [ZMod.card]; omega)
  intro t
  let c₀ : Fin n ⊕ Fin n → ZMod p := Sum.elim (-t) (fun _ => 0)
  obtain ⟨c,he,hc⟩ := represent_by_balanced (normals A) S hs
    (repair_of_affine_cover _ a blocked privatePoint) c₀
  rw [combine_normals,combine_normals] at he
  have h₀ : c₀ ∘ Sum.inl = -t := rfl
  have h₁ : c₀ ∘ Sum.inr = 0 := rfl
  rw [h₀,h₁,mulVec_zero,add_zero] at he
  refine ⟨c ∘ Sum.inr,fun j => (mem_erase.mp (hc (.inr j))).1,fun j h => ?_⟩
  apply (mem_erase.mp (hc (.inl j))).1
  have he' := congrFun he j
  change c (.inl j) + (Aᵀ *ᵥ (c ∘ Sum.inr)) j = -t j at he'
  change (Aᵀ *ᵥ (c ∘ Sum.inr)) j + t j = 0 at h
  linear_combination he' - h

/-- For symmetric matrices it suffices to find vectors avoiding every
affine constraint except for a single designated coordinate. -/
theorem affine_of_symmetric_deletions (hp : 5 ≤ p) (hs : A.IsSymm)
    (deletions : ∀ (a : Fin n ⊕ Fin n → ZMod p) (w : Fin n ⊕ Fin n),
      ∃ x, ∀ j, j ≠ w → normals A j ⬝ᵥ x ≠ a j) : AffineReduction.AffineAJT A := by
  rw [AffineReduction.affine_iff_avoid]
  intro u v
  by_contra no
  let a := Sum.elim u v
  have hb (x : Fin n → ZMod p) : ∃ i, normals A i ⬝ᵥ x = a i := by
    by_contra! h
    exact no ⟨x,fun j => by simpa [normals, a] using h (.inl j),fun j => h (.inr j)⟩
  have h := affine_transpose_of_irredundant A hp a hb (deletions a)
  rw [show Aᵀ = A from hs] at h
  exact no ((AffineReduction.affine_iff_avoid A).mp h u v)

end
end AlonJaegerTarsi.BalancedCover
