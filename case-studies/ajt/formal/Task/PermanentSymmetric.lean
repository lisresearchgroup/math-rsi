import Task.PermanentDiagonal

/-! A symmetric bipartite form of the AJT problem and a two-coordinate
obstruction to increasing the nullity of a symmetric diagonal perturbation. -/

noncomputable section

namespace AlonJaegerTarsi.PermanentApproach

open Matrix

variable {F : Type*} [Field F] {n : ℕ}

/-- Place a matrix and its transpose on the off-diagonal of a symmetric matrix. -/
def symmetricLift (A : Matrix (Fin n) (Fin n) F) :
    Matrix (Fin (n+n)) (Fin (n+n)) F :=
  (fromBlocks 0 A Aᵀ 0).submatrix finSumFinEquiv.symm finSumFinEquiv.symm

theorem symmetricLift_isSymm (A : Matrix (Fin n) (Fin n) F) : (symmetricLift A).IsSymm := by
  simp [symmetricLift, Matrix.IsSymm, transpose_submatrix, fromBlocks_transpose]

theorem symmetricLift_det_ne_zero (A : Matrix (Fin n) (Fin n) F) (hA : A.det ≠ 0) :
    (symmetricLift A).det ≠ 0 := by
  rw [symmetricLift, det_submatrix_equiv_self, ← isUnit_iff_ne_zero, ← isUnit_iff_isUnit_det,
    ← mulVec_injective_iff_isUnit]
  have hi := mulVec_injective_of_isUnit
    ((isUnit_iff_isUnit_det A).mpr (isUnit_iff_ne_zero.mpr hA))
  have hi' := mulVec_injective_of_isUnit
    ((isUnit_iff_isUnit_det Aᵀ).mpr (isUnit_iff_ne_zero.mpr (by simpa using hA)))
  intro x y h
  have hl := congrArg (fun z : Fin n ⊕ Fin n → F => z ∘ Sum.inl) h
  have hr := congrArg (fun z : Fin n ⊕ Fin n → F => z ∘ Sum.inr) h
  have hl' : x ∘ Sum.inr = y ∘ Sum.inr := hi (by simpa [fromBlocks_mulVec] using hl)
  have hr' : x ∘ Sum.inl = y ∘ Sum.inl := hi' (by simpa [fromBlocks_mulVec] using hr)
  funext j
  cases j with
  | inl k => exact congrFun hr' k
  | inr k => exact congrFun hl' k

theorem symmetricLift_iff (A : Matrix (Fin n) (Fin n) F) :
    HasAJTVector (symmetricLift A) ↔ HasAJTVector A ∧ HasAJTVector Aᵀ := by
  constructor
  · rintro ⟨x,hx,hy⟩
    let z := x ∘ finSumFinEquiv
    have hxy (k) : ((fromBlocks 0 A Aᵀ 0) *ᵥ z) k ≠ 0 := by
      simpa [symmetricLift, z, submatrix_mulVec_equiv] using hy (finSumFinEquiv k)
    exact ⟨⟨z ∘ Sum.inr, fun _ => hx _, fun i => by simpa [fromBlocks_mulVec] using hxy (.inl i)⟩,
      ⟨z ∘ Sum.inl, fun _ => hx _, fun i => by simpa [fromBlocks_mulVec] using hxy (.inr i)⟩⟩
  · rintro ⟨⟨x,hx,hAx⟩,⟨y,hy,hAy⟩⟩
    let z := Sum.elim y x
    refine ⟨z ∘ finSumFinEquiv.symm, fun k => ?_, fun k => ?_⟩
    · obtain ⟨j,rfl⟩ := finSumFinEquiv.surjective k
      simp only [Function.comp_apply, Equiv.symm_apply_apply]
      cases j with
      | inl i => simpa [z] using hy i
      | inr i => simpa [z] using hx i
    · obtain ⟨j,rfl⟩ := finSumFinEquiv.surjective k
      simp only [symmetricLift, submatrix_mulVec_equiv, Function.comp_def, Equiv.symm_apply_apply]
      cases j with
      | inl i => simpa [symmetricLift, z, submatrix_mulVec_equiv, fromBlocks_mulVec, Function.comp_def] using hAx i
      | inr i => simpa [symmetricLift, z, submatrix_mulVec_equiv, fromBlocks_mulVec, Function.comp_def] using hAy i

/-- It suffices to handle symmetric matrices in every dimension over the given field. -/
theorem of_universal_symmetric
    (hs : ∀ (d : ℕ) (B : Matrix (Fin d) (Fin d) F), B.IsSymm → B.det ≠ 0 → HasAJTVector B)
    (A : Matrix (Fin n) (Fin n) F) (hA : A.det ≠ 0) : HasAJTVector A :=
  ((symmetricLift_iff A).mp
    (hs _ _ (symmetricLift_isSymm A) (symmetricLift_det_ne_zero A hA))).1


section Augmentation

variable {ι : Type*} [Fintype ι] [DecidableEq ι] [Fintype F]

omit [Fintype F] in
private theorem exists_affine_exception (a b : F) (hab : a ≠ 0 ∨ b ≠ 0) :
    ∃ r : F, ∀ t ≠ r, a + t*b ≠ 0 := by
  by_cases hb : b = 0
  · exact ⟨0, fun _ _ => by simpa [hb] using hab.resolve_right (not_not_intro hb)⟩
  · exact ⟨-a/b, fun t ht h => ht ((eq_div_iff hb).mpr (by linear_combination h))⟩

omit [Field F] in
private theorem exists_avoiding (hF : 3 < Fintype.card F) (a b c : F) :
    ∃ t : F, t ≠ a ∧ t ≠ b ∧ t ≠ c := by
  classical
  let bad : Finset F := {a,b,c}
  have hcard : bad.card < Fintype.card F := by
    apply lt_of_le_of_lt _ hF
    calc
      bad.card ≤ ({b,c} : Finset F).card+1 := Finset.card_insert_le _ _
      _ ≤ (({c} : Finset F).card+1)+1 := Nat.add_le_add_right (Finset.card_insert_le _ _) 1
      _ = 3 := by simp
  obtain ⟨t,_,ht⟩ := Finset.exists_mem_notMem_of_card_lt_card (s:=bad) (t:=Finset.univ) hcard
  exact ⟨t, by simpa [bad, not_or] using ht⟩

omit [DecidableEq ι] [Fintype F] in
private theorem symm_pairing (M : Matrix ι ι F) (hM : M.IsSymm) (x y : ι → F) :
    x ⬝ᵥ (M *ᵥ y) = (M *ᵥ x) ⬝ᵥ y := by
  rw [dotProduct_mulVec]
  have h : x ᵥ* M = M *ᵥ x := by simpa only [hM.eq] using vecMul_transpose M x
  rw [h]

omit [Fintype F] in
/-- If a unit vector lies in the image of a symmetric matrix, its coordinate
vanishes on every vector in the kernel. -/
theorem inactive_of_unit_image (M : Matrix ι ι F) (hM : M.IsSymm) (i : ι)
    (u : ι → F) (hu : M *ᵥ u = Pi.single i 1) (x : ι → F) (hx : M *ᵥ x = 0) :
    x i = 0 := by
  have h := symm_pairing M hM u x
  simpa [hx, hu, single_dotProduct] using h.symm

/-- Two changes of a diagonal can activate two coordinates simultaneously while
preserving the entire original kernel. For the unit equations, a nonzero
cross-coordinate in either preimage suffices for a symmetric matrix. Each
change may avoid one arbitrary specified value. -/
theorem symmetric_two_coordinate_augmentation (M : Matrix ι ι F) (hM : M.IsSymm)
    (hF : 3 < Fintype.card F) (i j : ι) (hij : i ≠ j) (u v : ι → F)
    (hu : M *ᵥ u = Pi.single i 1) (hv : M *ᵥ v = Pi.single j 1)
    (hc : v i ≠ 0) (f g : F) :
    ∃ (s t : F) (z : ι → F), s ≠ f ∧ t ≠ g ∧ z i ≠ 0 ∧ z j ≠ 0 ∧
      (M - diagonal (Pi.single i s + Pi.single j t)) *ᵥ z = 0 ∧
      ∀ x, M *ᵥ x = 0 → (M - diagonal (Pi.single i s + Pi.single j t)) *ᵥ x = 0 := by
  classical
  have he : u j = v i := by
    have h := symm_pairing M hM u v
    simpa [hu, hv, single_dotProduct, dotProduct_single] using h
  have hce : u j * v i ≠ 0 := mul_ne_zero (he.trans_ne hc) hc
  let D := u j * v i - u i * v j
  have hβ : v j ≠ 0 ∨ D ≠ 0 := by
    by_cases h : v j = 0
    · exact Or.inr (by simpa [D,h] using hce)
    · exact Or.inl h
  have hγ : 1-g*v j ≠ 0 ∨ -u i-g*D ≠ 0 := by
    by_cases h : 1-g*v j = 0
    · right
      have hg : g ≠ 0 := by intro e; simp [e] at h
      intro h'
      apply (mul_ne_zero hg hce)
      dsimp [D] at h'
      linear_combination -h' - u i*h
    · exact Or.inl h
  obtain ⟨r₁,hr₁⟩ := exists_affine_exception (v j) D hβ
  obtain ⟨r₂,hr₂⟩ := exists_affine_exception (1-g*v j) (-u i-g*D) hγ
  obtain ⟨s,hs,hs₁,hs₂⟩ := exists_avoiding hF f r₁ r₂
  let den := v j + s*D
  have hden : den ≠ 0 := hr₁ s hs₁
  let t := (1-s*u i)/den
  have htden : t*den = 1-s*u i := by simp [t, hden]
  have ht : t ≠ g := by
    intro htg
    apply hr₂ s hs₂
    rw [htg] at htden
    dsimp [den] at htden
    linear_combination -htden
  let z := (s*v i) • u + (1-s*u i) • v
  have hzi : z i = v i := by
    dsimp [z]
    ring
  have hzj : z j = den := by
    dsimp [z,den,D]
    ring
  refine ⟨s,t,z,hs,ht,hzi.trans_ne hc,hzj.trans_ne hden,?_,?_⟩
  · ext k
    rw [sub_mulVec, Pi.sub_apply, mulVec_diagonal]
    change (M *ᵥ ((s*v i) • u + (1-s*u i) • v)) k - _ = 0
    rw [mulVec_add, mulVec_smul, mulVec_smul, hu, hv]
    by_cases hk : k=i
    · subst k
      simp [hij, hzi, z]
    · by_cases hk' : k=j
      · subst k
        simpa [Pi.single_apply, hij, hzj, sub_eq_zero] using htden.symm
      · simp [hk, hk']
  · intro x hx
    have hxi := inactive_of_unit_image M hM i u hu x hx
    have hxj := inactive_of_unit_image M hM j v hv x hx
    ext k
    rw [sub_mulVec, Pi.sub_apply, hx, mulVec_diagonal]
    by_cases hi : k=i
    · subst k
      simp [hxi]
    · by_cases hj : k=j
      · subst k
        simp [hxj]
      · simp [hi, hj]

/-- The kernel after subtracting the diagonal d. -/
def diagonalKernel (A : Matrix ι ι F) (d : ι → F) : Submodule F (ι → F) :=
  LinearMap.ker (A-diagonal d).mulVecLin

/-- Maximality by inclusion suffices for the two-coordinate argument. -/
def MaximalDiagonalKernel (A : Matrix ι ι F) (d : ι → F) : Prop :=
  ∀ e : ι → F, NowhereZero e → ¬diagonalKernel A d < diagonalKernel A e

theorem exists_maximal_diagonal_kernel (A : Matrix ι ι F) :
    ∃ d : ι → F, NowhereZero d ∧ MaximalDiagonalKernel A d := by
  classical
  let good : Finset (ι → F) := Finset.univ.filter NowhereZero
  have hgood : good.Nonempty :=
    ⟨fun _ => 1, Finset.mem_filter.mpr ⟨Finset.mem_univ _, fun _ => one_ne_zero⟩⟩
  obtain ⟨d,hd,hm⟩ := good.exists_max_image (fun e => Module.finrank F (diagonalKernel A e)) hgood
  refine ⟨d,(Finset.mem_filter.mp hd).2,fun e he hlt => ?_⟩
  exact (not_lt_of_ge (hm e (Finset.mem_filter.mpr ⟨Finset.mem_univ _,he⟩)))
    (Submodule.finrank_lt_finrank_of_lt hlt)

/-- At a maximal kernel over nonzero diagonals, the inverse restricted to two
inactive coordinates has no off-diagonal entry. The preimages need not be unique. -/
theorem maximal_diagonal_cross_zero (A : Matrix ι ι F) (hA : A.IsSymm)
    (d : ι → F) (hd : NowhereZero d) (hm : MaximalDiagonalKernel A d)
    (hF : 3 < Fintype.card F) (i j : ι) (hij : i ≠ j) (u v : ι → F)
    (hu : (A-diagonal d) *ᵥ u = Pi.single i 1)
    (hv : (A-diagonal d) *ᵥ v = Pi.single j 1) : v i = 0 := by
  classical
  let M := A-diagonal d
  have hM : M.IsSymm := hA.sub (isSymm_diagonal d)
  by_contra hc
  obtain ⟨s,t,z,hs,ht,hzi,_,hz,hkeep⟩ :=
    symmetric_two_coordinate_augmentation M hM hF i j hij u v hu hv hc (-d i) (-d j)
  let change : ι → F := Pi.single i s + Pi.single j t
  let e := d+change
  have he : NowhereZero e := by
    intro k
    by_cases hi : k=i
    · subst k
      simpa [e,change,hij,add_comm,add_eq_zero_iff_eq_neg] using hs
    · by_cases hj : k=j
      · subst k
        simpa [e,change,hij,add_comm,add_eq_zero_iff_eq_neg] using ht
      · simpa [e,change,hi,hj] using hd k
  have hsub : A-diagonal e = M-diagonal change := by change A-diagonal (d+change) = (A-diagonal d)-diagonal change; rw [sub_sub,diagonal_add]; rfl
  apply hm e he
  apply lt_of_le_of_ne
  · intro x hx
    change (A-diagonal e) *ᵥ x = 0
    exact hsub.symm ▸ hkeep x hx
  · intro h
    have hh : z ∈ diagonalKernel A e := by
      change (A-diagonal e) *ᵥ z = 0
      exact hsub.symm ▸ hz
    have hz' : z ∈ diagonalKernel A d := h.symm ▸ hh
    exact hzi (inactive_of_unit_image M hM i u hu z hz')

omit [Fintype F] in
/-- A coordinate vanishing on the kernel of a symmetric matrix has its unit
vector in the image. -/
theorem unit_image_of_inactive (M : Matrix ι ι F) (hM : M.IsSymm) (i : ι)
    (hi : ∀ x, M *ᵥ x = 0 → x i = 0) : ∃ u, M *ᵥ u = Pi.single i 1 := by
  classical
  let ev : (ι → F) →ₗ[F] F := LinearMap.proj i
  have hev : ev ∈ (LinearMap.ker M.mulVecLin).dualAnnihilator :=
    (Submodule.mem_dualAnnihilator _).mpr fun x hx => hi x hx
  rw [← LinearMap.range_dualMap_eq_dualAnnihilator_ker] at hev
  obtain ⟨g,hg⟩ := hev
  let u : ι → F := fun j => g (Pi.single j 1)
  have hdual (z : ι → F) : g z = u ⬝ᵥ z := by
    have hz : z = ∑ j, z j • (Pi.single j 1 : ι → F) := by
      ext k
      classical
      simp [Finset.sum_apply, Pi.single_apply]
    calc
      g z = g (∑ j, z j • Pi.single j 1) := congrArg _ hz
      _ = u ⬝ᵥ z := by simp [u, dotProduct, mul_comm]
  refine ⟨u,funext fun k => ?_⟩
  have h := LinearMap.congr_fun hg (Pi.single k 1)
  change g (M *ᵥ Pi.single k 1) = (Pi.single k 1 : ι → F) i at h
  rw [hdual,symm_pairing M hM,dotProduct_single_one] at h
  simpa [Pi.single_apply, eq_comm] using h

omit [Fintype F] in
/-- For one inactive coordinate, the diagonal entry of the inverse on that
coordinate must be zero or the unique value forced by the forbidden change. -/
theorem maximal_diagonal_entry (A : Matrix ι ι F) (hA : A.IsSymm)
    (d : ι → F) (hd : NowhereZero d) (hm : MaximalDiagonalKernel A d)
    (i : ι) (u : ι → F) (hu : (A-diagonal d) *ᵥ u = Pi.single i 1) :
    u i = 0 ∨ d i * u i = -1 := by
  classical
  by_cases ha : u i = 0
  · exact Or.inl ha
  right
  by_contra h
  let M := A-diagonal d
  have hM : M.IsSymm := hA.sub (isSymm_diagonal d)
  let s := (u i)⁻¹
  have hsafe : d i+s ≠ 0 := by
    intro hd'
    have ht := congrArg (· * u i) hd'
    apply h
    simpa [add_mul, s, ha, add_eq_zero_iff_eq_neg] using ht
  let e : ι → F := d + Pi.single i s
  have he : NowhereZero e := by
    intro k
    by_cases hi : k=i
    · subst k
      simpa [e] using hsafe
    · simpa [e,hi] using hd k
  have heq : A-diagonal e = M-diagonal (Pi.single i s) := by
    change A-diagonal (d+Pi.single i s) = (A-diagonal d)-diagonal (Pi.single i s)
    rw [sub_sub,diagonal_add]; rfl
  apply hm e he
  apply lt_of_le_of_ne
  · intro x hx
    change M *ᵥ x = 0 at hx
    have hxi := inactive_of_unit_image M hM i u hu x hx
    change (A-diagonal e) *ᵥ x = 0
    rw [heq,sub_mulVec,hx]
    ext k
    by_cases hi : k=i
    · subst k
      simp [mulVec_diagonal,hxi]
    · simp [mulVec_diagonal,hi]
  · intro hh
    have hmem : u ∈ diagonalKernel A e := by
      change (A-diagonal e) *ᵥ u = 0
      rw [heq,sub_mulVec,show M *ᵥ u = Pi.single i 1 from hu]
      ext k
      by_cases hi : k=i
      · subst k
        simp [mulVec_diagonal,s,ha]
      · simp [mulVec_diagonal,hi]
    have hu' : u ∈ diagonalKernel A d := hh.symm ▸ hmem
    exact ha (inactive_of_unit_image M hM i u hu u hu')

end Augmentation

end AlonJaegerTarsi.PermanentApproach
