import Task.WeightTables

namespace AlonJaegerTarsi.MarkedFourier

open Matrix Finset WeightTransform
open scoped BigOperators

abbrev Vec (p n : ℕ) := Fin n → ZMod p

def front {R : Type*} (a b : ℕ) (x : Fin (a+b) → R) : Fin a → R := fun i => x (Fin.castAdd b i)
def back {R : Type*} (a b : ℕ) (x : Fin (a+b) → R) : Fin b → R := fun i => x (Fin.natAdd a i)

@[simp] theorem front_append {R : Type*} {a b} (u : Fin a → R) (v : Fin b → R) :
    front a b (Fin.append u v) = u := funext (Fin.append_left u v)
@[simp] theorem back_append {R : Type*} {a b} (u : Fin a → R) (v : Fin b → R) :
    back a b (Fin.append u v) = v := funext (Fin.append_right u v)
@[simp] theorem append_parts {R : Type*} {a b} (x : Fin (a+b) → R) :
    Fin.append (front a b x) (back a b x) = x := by
  ext i
  induction i using Fin.addCases with
  | left j => exact Fin.append_left .. 
  | right j => exact Fin.append_right ..

def mark {R : Type*} (a b c d : ℕ) (x : Fin (a+b) → R) (y : Fin (c+d) → R) : Fin (a+c) → R :=
  Fin.append (front a b x) (front c d y)

/-- Separate the marked coordinates from the two blocks of unmarked coordinates. -/
def chart (p a b c d : ℕ) :
    (Vec p (a+b) × Vec p (c+d)) ≃ (Vec p (a+c) × Vec p b × Vec p d) where
  toFun z := (mark a b c d z.1 z.2, back a b z.1, back c d z.2)
  invFun z := (Fin.append (front a c z.1) z.2.1, Fin.append (back a c z.1) z.2.2)
  left_inv := by rintro ⟨x,y⟩; simp [mark]
  right_inv := by rintro ⟨e,f,g⟩; simp [mark]

theorem dot_parts {p a b} (x y : Vec p (a+b)) :
    x ⬝ᵥ y = front a b x ⬝ᵥ front a b y + back a b x ⬝ᵥ back a b y := by
  exact Fin.sum_univ_add _

private theorem char_parts {p a b c d} [NeZero p] (q : Vec p (a+c)) (u : Vec p b) (v : Vec p d)
    (x : Vec p (a+b)) (y : Vec p (c+d)) :
    ZMod.stdAddChar (Fin.append (front a c q) u ⬝ᵥ x) *
      ZMod.stdAddChar (Fin.append (back a c q) v ⬝ᵥ y) =
    ZMod.stdAddChar (q ⬝ᵥ mark a b c d x y) *
      ZMod.stdAddChar (u ⬝ᵥ back a b x) * ZMod.stdAddChar (v ⬝ᵥ back c d y) := by
  rw [← AddChar.map_add_eq_mul, ← AddChar.map_add_eq_mul, ← AddChar.map_add_eq_mul]
  congr 1
  rw [dot_parts (a := a) (b := b), dot_parts (a := c) (b := d) (y := y),
      dot_parts (a := a) (b := c) (x := q)]
  simp [mark, add_left_comm, add_comm, add_assoc]

variable {p a b c d : ℕ} [NeZero p]

private theorem sum_indicator {D : Type*} [Fintype D] [DecidableEq D] (s : Finset D) (f : D → ℂ) :
    (∑ d ∈ s, f d) = ∑ d, if d ∈ s then f d else 0 := by
  rw [← sum_filter]
  simp

private theorem triple_filtered {I J H : Type*} [Fintype I] [Fintype J] [Fintype H]
    [DecidableEq I] [DecidableEq J] [DecidableEq H]
    (s : Finset I) (t : Finset J) (u : Finset H) (f : I → ℂ) (g : J → ℂ) (h : H → ℂ) :
    (∑ i, ∑ j, ∑ k, if i ∈ s ∧ j ∈ t ∧ k ∈ u then f i*g j*h k else 0) =
      (∑ i ∈ s, f i) * (∑ j ∈ t, g j) * (∑ k ∈ u, h k) := by
  classical
  rw [sum_indicator s f, sum_indicator t g, sum_indicator u h, mul_assoc]
  simp only [sum_mul]
  simp only [mul_sum]
  apply sum_congr rfl
  intro i _
  apply sum_congr rfl
  intro j _
  apply sum_congr rfl
  intro k _
  by_cases hi : i ∈ s <;> by_cases hj : j ∈ t <;> by_cases hk : k ∈ u <;>
    simp [hi, hj, hk, mul_assoc]

private theorem transform_rectangle (x : Vec p (a+b)) (y : Vec p (c+d))
    (S : Finset (Vec p (a+c))) (k l : ℕ) :
    (∑ z : Vec p (a+b) × Vec p (c+d),
      if mark a b c d z.1 z.2 ∈ S ∧ wt (back a b z.1) = k ∧ wt (back c d z.2) = l
      then ZMod.stdAddChar (z.1 ⬝ᵥ x) * ZMod.stdAddChar (z.2 ⬝ᵥ y) else 0) =
      (∑ q ∈ S, ZMod.stdAddChar (q ⬝ᵥ mark a b c d x y)) *
      (kraw p b k (wt (back a b x)) : ℂ) * (kraw p d l (wt (back c d y)) : ℂ) := by
  classical
  rw [← (chart p a b c d).symm.sum_comp, Fintype.sum_prod_type]
  simp only [chart, Equiv.coe_fn_symm_mk, mark, front_append, back_append, append_parts,
    Fintype.sum_prod_type, char_parts]
  rw [← sphere_transform (back a b x) k, ← sphere_transform (back c d y) l]
  simpa only [mem_filter, mem_univ, true_and, mark] using
    triple_filtered S (univ.filter fun z : Vec p b => wt z = k)
      (univ.filter fun z : Vec p d => wt z = l)
      (fun q => ZMod.stdAddChar (q ⬝ᵥ mark a b c d x y))
      (fun u => ZMod.stdAddChar (u ⬝ᵥ back a b x)) (fun v => ZMod.stdAddChar (v ⬝ᵥ back c d y))

/-- A marked-site Fourier transform for any rectangular graph. Each test set of
local coordinates can be combined with any two exterior Hamming spheres. -/
theorem marked_macWilliams (A : Matrix (Fin (c+d)) (Fin (a+b)) (ZMod p))
    (S : Finset (Vec p (a+c))) (k l : ℕ) :
    (p : ℂ)^(a+b) * (((univ : Finset (Vec p (c+d))).filter fun y =>
      mark a b c d (-(Aᵀ *ᵥ y)) y ∈ S ∧ wt (back a b (-(Aᵀ *ᵥ y))) = k ∧
      wt (back c d y) = l).card : ℕ) =
      ∑ x : Vec p (a+b), (∑ q ∈ S, ZMod.stdAddChar (q ⬝ᵥ mark a b c d x (A *ᵥ x))) *
        (kraw p b k (wt (back a b x)) : ℂ) * (kraw p d l (wt (back c d (A *ᵥ x))) : ℂ) := by
  classical
  let P (z : Vec p (a+b) × Vec p (c+d)) :=
    mark a b c d z.1 z.2 ∈ S ∧ wt (back a b z.1) = k ∧ wt (back c d z.2) = l
  simp_rw [← transform_rectangle]
  rw [Finset.sum_comm, Fintype.sum_prod_type, Finset.sum_comm]
  have inner (z : Vec p (a+b)) (y : Vec p (c+d)) :
      (∑ x : Vec p (a+b), if P (z,y) then
        ZMod.stdAddChar (z ⬝ᵥ x) * ZMod.stdAddChar (y ⬝ᵥ (A *ᵥ x)) else 0) =
      if z = -(Aᵀ *ᵥ y) then (if P (z,y) then (p:ℂ)^(a+b) else 0) else 0 := by
    by_cases h : P (z,y) <;> simp [h, graph_orthogonality]
  change _ = ∑ y : Vec p (c+d), ∑ z : Vec p (a+b), ∑ x : Vec p (a+b), if P (z,y) then
    ZMod.stdAddChar (z ⬝ᵥ x) * ZMod.stdAddChar (y ⬝ᵥ (A *ᵥ x)) else 0
  simp_rw [inner]
  simp only [Finset.sum_ite_eq', Finset.mem_univ, if_true]
  rw [← Finset.sum_filter]
  simp [P, mul_comm]

end AlonJaegerTarsi.MarkedFourier
