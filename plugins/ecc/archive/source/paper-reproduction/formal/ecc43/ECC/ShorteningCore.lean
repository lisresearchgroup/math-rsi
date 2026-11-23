import Mathlib.Algebra.Field.ZMod
import ECC.Coset
import ECC.MatrixSupport
import ECC.Dual
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Basis.VectorSpace
import Mathlib.LinearAlgebra.Pi

set_option maxHeartbeats 1000000

namespace ECC

def joinWord {n m : ℕ} (a : Word n) (b : Word m) : Word (n+m) :=
  Fin.addCases a b

def firstPart (n m : ℕ) : Word (n+m) →ₗ[F2] Word n where
  toFun x i := x (Fin.castAdd m i)
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

def lastPart (n m : ℕ) : Word (n+m) →ₗ[F2] Word m where
  toFun x i := x (Fin.natAdd n i)
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

@[simp] theorem firstPart_join {n m} (a : Word n) (b : Word m) :
    firstPart n m (joinWord a b) = a := by funext i; simp [firstPart, joinWord]

@[simp] theorem lastPart_join {n m} (a : Word n) (b : Word m) :
    lastPart n m (joinWord a b) = b := by funext i; simp [lastPart, joinWord]

@[simp] theorem join_parts {n m} (x : Word (n+m)) :
    joinWord (firstPart n m x) (lastPart n m x) = x := by
  funext i
  refine Fin.addCases (m := n) (n := m) ?_ ?_ i <;> intro j <;>
    simp [joinWord, firstPart, lastPart]

@[simp] theorem joinWord_add {n m} (a c : Word n) (b d : Word m) :
    joinWord (a+c) (b+d) = joinWord a b + joinWord c d := by
  funext i
  refine Fin.addCases (m := n) (n := m) ?_ ?_ i <;> intro j <;> simp [joinWord]

@[simp] theorem joinWord_smul {n m} (s : F2) (a : Word n) (b : Word m) :
    joinWord (s • a) (s • b) = s • joinWord a b := by
  funext i
  refine Fin.addCases (m := n) (n := m) ?_ ?_ i <;> intro j <;> simp [joinWord]

@[simp] theorem joinWord_zero {n m} : joinWord (0 : Word n) (0 : Word m) = 0 := by
  funext i
  refine Fin.addCases (m := n) (n := m) ?_ ?_ i <;> intro j <;> simp [joinWord]

@[simp] theorem weight_joinWord {n m} (a : Word n) (b : Word m) :
    weight (joinWord a b) = weight a + weight b := by
  simp only [weight, Finset.card_eq_sum_ones, Finset.sum_filter]
  rw [Fin.sum_univ_add (a := n) (b := m)]
  simp [joinWord]

def shortenedCode {n m : ℕ} (C : Submodule F2 (Word (n+m))) :
    Submodule F2 (Word n) where
  carrier := {a | joinWord a (0 : Word m) ∈ C}
  zero_mem' := by simp
  add_mem' := by
    intro a b ha hb
    change joinWord (a+b) 0 ∈ C
    simpa only [← joinWord_add, add_zero] using C.add_mem ha hb
  smul_mem' := by
    intro s a ha
    change joinWord (s • a) 0 ∈ C
    simpa only [← joinWord_smul, smul_zero] using C.smul_mem s ha

def tailProjection {n m : ℕ} (C : Submodule F2 (Word (n+m))) : C →ₗ[F2] Word m :=
  (lastPart n m).comp C.subtype

noncomputable def shortenedKerEquiv {n m : ℕ} (C : Submodule F2 (Word (n+m))) :
    LinearMap.ker (tailProjection C) ≃ₗ[F2] shortenedCode C :=
  LinearEquiv.ofBijective
    ({ toFun := fun x => ⟨firstPart n m x.val.val, by
        change joinWord (firstPart n m x.val.val) 0 ∈ C
        have hz : lastPart n m x.val.val = 0 := x.property
        rw [← hz, join_parts]
        exact x.val.property⟩
       map_add' := by intros; rfl
       map_smul' := by intros; rfl } : LinearMap.ker (tailProjection C) →ₗ[F2] shortenedCode C)
    (by
      constructor
      · intro x y h
        apply Subtype.ext
        apply Subtype.ext
        have hx : lastPart n m x.val.val = 0 := x.property
        have hy : lastPart n m y.val.val = 0 := y.property
        have hh : firstPart n m x.val.val = firstPart n m y.val.val := congrArg Subtype.val h
        rw [← join_parts x.val.val, ← join_parts y.val.val, hx, hy, hh]
      · intro a
        refine ⟨⟨⟨joinWord a.val 0, a.property⟩, ?_⟩, ?_⟩
        · change lastPart n m (joinWord a.val 0) = 0
          simp
        · apply Subtype.ext
          exact firstPart_join _ _)

theorem shortenedCode_finrank {n m : ℕ} (C : Submodule F2 (Word (n+m))) :
    Module.finrank F2 (LinearMap.range (tailProjection C)) +
      Module.finrank F2 (shortenedCode C) = Module.finrank F2 C := by
  rw [← (shortenedKerEquiv C).finrank_eq]
  exact (tailProjection C).finrank_range_add_finrank_ker

theorem shortenedCode_minWeight {n m d : ℕ} (C : Submodule F2 (Word (n+m)))
    (h : MinWeight C d) : MinWeight (shortenedCode C) d := by
  intro a ha hne
  have hn : joinWord a (0 : Word m) ≠ 0 := by
    intro hz
    have := congrArg (firstPart n m) hz
    exact hne (by simpa using this)
  simpa using h _ ha hn

theorem shortenedCode_even {n m : ℕ} (C : Submodule F2 (Word (n+m)))
    (h : EvenCode C) : EvenCode (shortenedCode C) := by
  intro a ha
  simpa using h (joinWord a (0 : Word m)) ha

theorem weight_le_length {n : ℕ} (x : Word n) : weight x ≤ n := by
  exact (Finset.card_filter_le _ _).trans_eq (Finset.card_fin n)

def coordinateProjection {n m : ℕ} (r : Fin m → Fin n) : Word n →ₗ[F2] Word m where
  toFun x := x ∘ r
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

def liftCoordinates {n m : ℕ} (r : Fin m → Fin n) (z : Word m) : Word n :=
  ∑ i, z i • Pi.single (r i) 1

theorem dotWord_liftCoordinates {n m : ℕ} (r : Fin m → Fin n) (z : Word m)
    (x : Word n) : dotWord x (liftCoordinates r z) = dotWord (coordinateProjection r x) z := by
  classical
  simp only [dotWord, liftCoordinates, Finset.sum_apply, Pi.smul_apply, smul_eq_mul,
    Finset.mul_sum]
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro i _
  simp [Pi.single_apply, mul_comm, coordinateProjection]

theorem liftCoordinates_at {n m : ℕ} {r : Fin m → Fin n} (hr : Function.Injective r)
    (z : Word m) (i : Fin m) : liftCoordinates r z (r i) = z i := by
  classical
  simp [liftCoordinates, Finset.sum_apply, Pi.single_apply, hr.eq_iff]

theorem weight_liftCoordinates_le {n m : ℕ} (r : Fin m → Fin n) (z : Word m) :
    weight (liftCoordinates r z) ≤ m := by
  classical
  have hsub : (Finset.univ.filter (fun i => liftCoordinates r z i ≠ 0)) ⊆
      Finset.univ.image r := by
    intro i hi
    by_contra hni
    have hn : ∀ j, r j ≠ i := by simpa using hni
    have hz : liftCoordinates r z i = 0 := by
      simp [liftCoordinates, Finset.sum_apply, hn]
    exact (Finset.mem_filter.mp hi).2 hz
  exact (Finset.card_le_card hsub).trans ((Finset.card_image_le).trans_eq (Finset.card_fin m))

theorem functional_eq_dotWord {m : ℕ} (f : Word m →ₗ[F2] F2) (x : Word m) :
    f x = dotWord x (fun i => f (Pi.single i 1)) := by
  classical
  have heq : x = ∑ i, x i • Pi.single i (1 : F2) := by
    funext j
    simp [Finset.sum_apply, Pi.single_apply]
  rw [heq, map_sum]
  simp only [map_smul, smul_eq_mul]
  congr 1
  funext i
  rw [← heq]

theorem projection_surjective_of_dual_minWeight {n m d : ℕ}
    (C : Submodule F2 (Word n)) (r : Fin m → Fin n) (hr : Function.Injective r)
    (hd : m < d) (hdual : MinWeight (dualCode C) d) :
    Function.Surjective ((coordinateProjection r).comp C.subtype) := by
  classical
  let f := (coordinateProjection r).comp C.subtype
  by_contra hsurj
  have hlt : LinearMap.range f < ⊤ := lt_top_iff_ne_top.mpr (by
    intro ht
    exact hsurj (LinearMap.range_eq_top.mp ht))
  obtain ⟨l, hl, hker⟩ := Submodule.exists_le_ker_of_lt_top (K := F2) (V := Word m) (LinearMap.range f) hlt
  let z : Word m := fun i => l (Pi.single i 1)
  let y := liftCoordinates r z
  have hymem : y ∈ dualCode C := by
    intro x hx
    rw [dotWord_liftCoordinates, ← functional_eq_dotWord]
    exact hker ⟨⟨x, hx⟩, rfl⟩
  have hyne : y ≠ 0 := by
    intro hz
    apply hl
    apply LinearMap.ext
    intro x
    rw [functional_eq_dotWord]
    have hz' : z = 0 := by
      funext i
      have hi := congrFun hz (r i)
      simpa [y, liftCoordinates_at hr] using hi
    change dotWord x z = 0
    rw [hz', dotWord_zero_right]
  have hw := hdual y hymem hyne
  have hle : weight y ≤ m := weight_liftCoordinates_le r z
  omega

end ECC
