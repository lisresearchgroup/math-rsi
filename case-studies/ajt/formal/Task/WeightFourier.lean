import Task.WeightTransform

open scoped BigOperators Polynomial
open Matrix Finset Polynomial

namespace AlonJaegerTarsi.WeightTransform

private theorem char_sum {p : ℕ} [NeZero p] {ι : Type*} (s : Finset ι) (f : ι → ZMod p) :
    ZMod.stdAddChar (∑ i ∈ s, f i) = ∏ i ∈ s, ZMod.stdAddChar (f i) := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert i s hi ih => simp [sum_insert hi, prod_insert hi, AddChar.map_add_eq_mul, ih]

private theorem scalar_sum {p : ℕ} [NeZero p] (a : ZMod p) :
    ∑ z : ZMod p, ZMod.stdAddChar (z*a) = if a = 0 then (p : ℂ) else 0 := by
  simpa only [ZMod.card, apply_ite Nat.cast, Nat.cast_zero] using AddChar.sum_mulShift a (ZMod.isPrimitive_stdAddChar p)

private theorem scalar_weight_polynomial {p : ℕ} [NeZero p] (a : ZMod p) :
    (∑ z : ZMod p, C (ZMod.stdAddChar (z*a)) * X ^ (if z = 0 then 0 else 1)) =
      if a ≠ 0 then (1 + C (-1 : ℂ) * X) else 1 + C (p - 1 : ℂ) * X := by
  classical
  let u := (univ : Finset (ZMod p)).erase 0
  have hsum : (∑ z ∈ u, ZMod.stdAddChar (z*a)) + 1 = if a = 0 then (p : ℂ) else 0 := by
    rw [← scalar_sum]
    simpa [u] using sum_erase_add (univ : Finset (ZMod p)) (fun z => ZMod.stdAddChar (z*a))
      (mem_univ 0)
  have hsplit : (∑ z : ZMod p, C (ZMod.stdAddChar (z*a)) * X ^ (if z = 0 then 0 else 1)) =
      (∑ z ∈ u, C (ZMod.stdAddChar (z*a)) * X) + 1 := by
    rw [← sum_erase_add (univ : Finset (ZMod p)) _ (mem_univ 0)]
    simp only [zero_mul, AddChar.map_zero_eq_one, if_true, pow_zero, map_one, one_mul]
    congr 1
    apply sum_congr rfl
    intro k hk
    simp [(mem_erase.mp hk).1]
  rw [hsplit, ← sum_mul, ← map_sum]
  by_cases ha : a = 0
  · rw [if_neg (not_not.mpr ha)]
    rw [if_pos ha] at hsum
    have h : ∑ z ∈ u, ZMod.stdAddChar (z*a) = (p : ℂ)-1 := by linear_combination hsum
    rw [h, add_comm]
  · rw [if_pos ha]
    rw [if_neg ha] at hsum
    have h : ∑ z ∈ u, ZMod.stdAddChar (z*a) = -1 := by linear_combination hsum
    rw [h, add_comm]

private theorem weight_distribution_polynomial {p n : ℕ} [NeZero p] (x : Fin n → ZMod p) :
    (∑ z : Fin n → ZMod p, C (ZMod.stdAddChar (z ⬝ᵥ x)) * X^(wt z)) =
      (1 + C (-1 : ℂ) * X)^(wt x) * (1 + C (p-1 : ℂ) * X)^(n-wt x) := by
  classical
  have hterm (z : Fin n → ZMod p) :
      C (ZMod.stdAddChar (z ⬝ᵥ x)) * X^(wt z) =
        ∏ j, C (ZMod.stdAddChar (z j*x j)) * X^(if z j = 0 then 0 else 1) := by
    rw [Finset.prod_mul_distrib, ← map_prod, ← char_sum, Finset.prod_pow_eq_pow_sum]
    congr 1
    simp [wt, Finset.sum_ite]
  simp_rw [hterm]
  rw [← Fintype.prod_sum (fun (j : Fin n) (z : ZMod p) =>
    C (ZMod.stdAddChar (z*x j)) * X^(if z=0 then 0 else 1))]
  simp_rw [scalar_weight_polynomial, Finset.prod_ite, Finset.prod_const]
  congr 2
  have hs := card_filter_add_card_filter_not (s := (univ : Finset (Fin n))) (fun i => x i ≠ 0)
  simp only [not_ne_iff, card_univ, Fintype.card_fin] at hs ⊢
  unfold wt
  omega

private theorem weighted_binomial_coeff (c : ℂ) (n a : ℕ) :
    (((1 : ℂ[X]) + C c * X)^n).coeff a = c^a * n.choose a := by
  induction n generalizing a with
  | zero =>
    cases a <;> simp [coeff_one]
  | succ n ih =>
    rw [pow_succ, mul_add, mul_one, ← mul_assoc, coeff_add]
    cases a with
    | zero => simp [ih]
    | succ a =>
      rw [coeff_mul_X, coeff_mul_C, ih, ih, Nat.choose_succ_succ, Nat.cast_add, pow_succ]
      ring

/-- The additive Fourier transform of a Hamming sphere is a Krawtchouk polynomial. -/
theorem sphere_transform {p n : ℕ} [NeZero p] (x : Fin n → ZMod p) (a : ℕ) :
    ∑ z ∈ (univ.filter fun z : Fin n → ZMod p => wt z = a), ZMod.stdAddChar (z ⬝ᵥ x) =
      (kraw p n a (wt x) : ℂ) := by
  classical
  have he := congrArg (fun f : ℂ[X] => f.coeff a) (weight_distribution_polynomial x)
  rw [finsetSum_coeff] at he
  simp only [coeff_C_mul_X_pow] at he
  simp only [coeff_mul,
    Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk, weighted_binomial_coeff] at he
  rw [sum_filter]
  simp only [eq_comm (a := a)] at he
  rw [he]
  simp only [kraw, Int.cast_sum, Int.cast_mul, Int.cast_pow, Int.cast_neg, Int.cast_one,
    Int.cast_natCast]
  apply sum_congr rfl
  intro t _
  rw [Nat.cast_sub (NeZero.one_le : 1 ≤ p)]
  ring


@[simp] theorem wt_neg {p n : ℕ} (x : Fin n → ZMod p) : wt (-x) = wt x := by
  simp [wt]

private theorem character_orthogonality {p n : ℕ} [NeZero p] (v : Fin n → ZMod p) :
    ∑ x : Fin n → ZMod p, ZMod.stdAddChar (v ⬝ᵥ x) = if v = 0 then (p:ℂ)^n else 0 := by
  classical
  let e := Equiv.ofBijective (CharacterMethod.dotChar (p := p) (n := n))
    CharacterMethod.dotChar_bijective
  calc
    _ = ∑ x : Fin n → ZMod p, (e x) v := rfl
    _ = ∑ ψ : AddChar (Fin n → ZMod p) ℂ, ψ v := e.sum_comp (fun ψ : AddChar (Fin n → ZMod p) ℂ => ψ v)
    _ = _ := by rw [AddChar.sum_apply_eq_ite]; simp

theorem graph_orthogonality {p n m : ℕ} [NeZero p] (A : Matrix (Fin m) (Fin n) (ZMod p))
    (z : Fin n → ZMod p) (y : Fin m → ZMod p) :
    (∑ x, ZMod.stdAddChar (z ⬝ᵥ x) * ZMod.stdAddChar (y ⬝ᵥ (A *ᵥ x))) =
      if z = -(Aᵀ *ᵥ y) then (p : ℂ)^n else 0 := by
  have h (x : Fin n → ZMod p) :
      y ⬝ᵥ (A *ᵥ x) = (Aᵀ *ᵥ y) ⬝ᵥ x :=
    (dotProduct_transpose_mulVec A x y).symm.trans (dotProduct_comm ..)
  simp_rw [h, ← AddChar.map_add_eq_mul, ← add_dotProduct, character_orthogonality, add_eq_zero_iff_eq_neg]

/-- Regroup a function of the two weights by the size of each simultaneous fiber. -/
theorem sum_by_weights {p n : ℕ} [NeZero p] (A : Matrix (Fin n) (Fin n) (ZMod p))
    (f : ℕ → ℕ → ℂ) :
    (∑ x, f (wt x) (wt (A *ᵥ x))) = ∑ i : Fin (n+1), ∑ j : Fin (n+1),
      (counts A i j : ℂ) * f i j := by
  classical
  let w (x : Fin n → ZMod p) : Fin (n+1) := ⟨wt x, Nat.lt_succ_of_le (wt_le x)⟩
  let key (x : Fin n → ZMod p) := (w x, w (A *ᵥ x))
  calc
    _ = ∑ k : Fin (n+1) × Fin (n+1), ∑ x ∈ univ.filter (fun x => key x = k),
          f (wt x) (wt (A *ᵥ x)) := (Finset.sum_fiberwise (g := key) ..).symm
    _ = ∑ k : Fin (n+1) × Fin (n+1), (counts A k.1 k.2 : ℂ) * f k.1 k.2 := by
        apply sum_congr rfl
        rintro ⟨i,j⟩ _
        have eqset : univ.filter (fun x => key x = (i,j)) =
            univ.filter (fun x => wt x = i ∧ wt (A *ᵥ x) = j) := by
          ext x
          simp [key, Prod.ext_iff, w, Fin.ext_iff]
        rw [eqset]
        calc
          _ = ∑ _x ∈ univ.filter (fun x => wt x = i ∧ wt (A *ᵥ x) = j), f i j := by
            exact sum_congr rfl fun x hx => by
              rw [(mem_filter.mp hx).2.1, (mem_filter.mp hx).2.2]
          _ = _ := by simp [counts]
    _ = _ := Fintype.sum_prod_type _

/-- Split MacWilliams identity for the graph of an arbitrary square matrix.
The transpose occurs with the output weight first on the transform side. -/
theorem macWilliams {p n : ℕ} [NeZero p] (A : Matrix (Fin n) (Fin n) (ZMod p))
    (a b : ℕ) :
    (p : ℤ)^n * counts Aᵀ b a =
      ∑ i : Fin (n+1), ∑ j : Fin (n+1), (counts A i j : ℤ) * kraw p n a i * kraw p n b j := by
  classical
  let sphere (c : ℕ) := univ.filter fun z : Fin n → ZMod p => wt z = c
  have expand (x : Fin n → ZMod p) :
      (kraw p n a (wt x) : ℂ) * (kraw p n b (wt (A *ᵥ x)) : ℂ) =
        ∑ y ∈ sphere b, ∑ z ∈ sphere a, ZMod.stdAddChar (z ⬝ᵥ x) * ZMod.stdAddChar (y ⬝ᵥ (A *ᵥ x)) := by
    rw [← sphere_transform x a, ← sphere_transform (A *ᵥ x) b, mul_sum]
    exact sum_congr rfl fun y _ => sum_mul .. 
  have hFourier : (∑ x, (kraw p n a (wt x) : ℂ) * (kraw p n b (wt (A *ᵥ x)) : ℂ)) =
      (p : ℂ)^n * counts Aᵀ b a := by
    simp_rw [expand]
    rw [Finset.sum_comm]
    calc
      _ = ∑ y ∈ sphere b, ∑ z ∈ sphere a, if z = -(Aᵀ *ᵥ y) then (p : ℂ)^n else 0 := by
        apply sum_congr rfl
        intro y _
        rw [Finset.sum_comm]
        exact sum_congr rfl fun z _ => graph_orthogonality A z y
      _ = ∑ y ∈ sphere b, if wt (Aᵀ *ᵥ y) = a then (p : ℂ)^n else 0 := by
        apply sum_congr rfl
        intro y _
        simp [sphere, Finset.sum_ite_eq']
      _ = _ := by
        rw [← Finset.sum_filter]
        simp [sphere, counts, filter_filter, mul_comm]
  rw [sum_by_weights A (fun i j => (kraw p n a i : ℂ) * (kraw p n b j : ℂ))] at hFourier
  simp only [← mul_assoc] at hFourier
  exact_mod_cast hFourier.symm

end AlonJaegerTarsi.WeightTransform
