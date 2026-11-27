import Task.PolynomialMarkedData

/-! Pairing an integer test function against the marked-coordinate Fourier transform. -/

open Finset
open scoped BigOperators

namespace AlonJaegerTarsi.MarkedEleven

structure Score where
  phi : Table
  wl : Fin 4 → X → ℤ
  wr : Fin 3 → Y → ℤ
  vl : Fin 4 → X → ℤ
  vr : Fin 3 → Y → ℤ
  wc : ℤ
  vc : ℤ

def kx (k b : X) : ℤ := WeightTransform.kraw 5 8 k b

def ky (l d : Y) : ℤ := WeightTransform.kraw 5 9 l d

def localAdj (φ : Table) : Table := fun o k l => ∑ p, K p o * φ p k l

def rightAdj (Q : Y → Y → ℤ) (g : Table) : Table := fun o k d => ∑ l, Q l d * g o k l

def leftAdj (P : X → X → ℤ) (t : Table) : Table := fun o b d => ∑ k, P k b * t o k d

def weightedLeft {U : Type*} [Fintype U] (profile : OM → U → ℤ) (u : U → X → ℤ) :
    Table := fun o b _ => ∑ j, profile o j * u j b

def weightedRight {U : Type*} [Fintype U] (profile : OM → U → ℤ) (u : U → Y → ℤ) :
    Table := fun o _ d => ∑ j, profile o j * u j d

def corner (a : ℤ) : Table := fun o b d => if o=0 ∧ b=0 ∧ d=0 then a else 0

def pProfileL (o : OM) (j : Fin 4) : ℤ := if pwL o = j then 1 else 0

def pProfileR (o : OM) (j : Fin 3) : ℤ := if pwR o = j then 1 else 0

def Score.wcoef (s : Score) (adj : Table) : Table := fun o b d =>
  adj o b d + weightedLeft pProfileL s.wl o b d + weightedRight pProfileR s.wr o b d +
    corner s.wc o b d

def Score.vcoef (s : Score) : Table := fun o b d =>
  -(5^11 * s.phi o b d) + weightedLeft vwL s.vl o b d + weightedRight vwR s.vr o b d +
    corner s.vc o b d

def leftMass (u : Fin 4) (b : X) : ℤ := WeightTransform.sphere 3 u * WeightTransform.sphere 8 b

def rightMass (u : Fin 3) (d : Y) : ℤ := WeightTransform.sphere 2 u * WeightTransform.sphere 9 d

def Score.rhs (s : Score) : ℤ := s.wc + 5 * s.vc +
  (∑ j, ∑ b, s.wl j b * leftMass j b) + (∑ j, ∑ d, s.wr j d * rightMass j d) +
  (∑ j, ∑ b, s.vl j b * (5 * leftMass j b)) + ∑ j, ∑ d, s.vr j d * (5 * rightMass j d)

private def pair (W C : Table) : ℤ := ∑ o, ∑ b, ∑ d, W o b d * C o b d

private theorem pair_add (W C E : Table) :
    pair W (fun o b d => C o b d + E o b d) = pair W C + pair W E := by
  simp [pair, mul_add, Finset.sum_add_distrib]

private theorem pair_corner (W : Table) (a : ℤ) : pair W (corner a) = W 0 0 0 * a := by
  simp [pair, corner, ite_and, mul_ite]

private theorem rotate {A B C : Type*} [Fintype A] [Fintype B] [Fintype C] (f : A → B → C → ℤ) :
    (∑ a, ∑ b, ∑ c, f a b c) = ∑ c, ∑ a, ∑ b, f a b c := by
  calc
    _ = ∑ a, ∑ c, ∑ b, f a b c := Finset.sum_congr rfl fun _ _ => Finset.sum_comm
    _ = _ := Finset.sum_comm

private theorem pair_left {U : Type*} [Fintype U] (W : Table) (m : OM → U → ℤ)
    (u mass : U → X → ℤ) (h : ∀ j b, ∑ o, ∑ d, m o j * W o b d = mass j b) :
    pair W (weightedLeft m u) = ∑ j, ∑ b, u j b * mass j b := by
  calc
    _ = ∑ a : OM × X × Y, ∑ j, u j a.2.1 * (m a.1 j * W a.1 a.2.1 a.2.2) := by
      simp only [pair, weightedLeft, Finset.mul_sum, Fintype.sum_prod_type]
      apply Finset.sum_congr rfl; intro o _
      apply Finset.sum_congr rfl; intro b _
      apply Finset.sum_congr rfl; intro d _
      apply Finset.sum_congr rfl; intro j _
      ring
    _ = ∑ j, ∑ a : OM × X × Y, u j a.2.1 * (m a.1 j * W a.1 a.2.1 a.2.2) := Finset.sum_comm
    _ = _ := by
      simp only [Fintype.sum_prod_type, ← h, Finset.mul_sum]
      apply Finset.sum_congr rfl; intro j _
      exact Finset.sum_comm

private theorem pair_right {U : Type*} [Fintype U] (W : Table) (m : OM → U → ℤ)
    (u mass : U → Y → ℤ) (h : ∀ j d, ∑ o, ∑ b, m o j * W o b d = mass j d) :
    pair W (weightedRight m u) = ∑ j, ∑ d, u j d * mass j d := by
  calc
    _ = ∑ a : OM × X × Y, ∑ j, u j a.2.2 * (m a.1 j * W a.1 a.2.1 a.2.2) := by
      simp only [pair, weightedRight, Finset.mul_sum, Fintype.sum_prod_type]
      apply Finset.sum_congr rfl; intro o _
      apply Finset.sum_congr rfl; intro b _
      apply Finset.sum_congr rfl; intro d _
      apply Finset.sum_congr rfl; intro j _
      ring
    _ = ∑ j, ∑ a : OM × X × Y, u j a.2.2 * (m a.1 j * W a.1 a.2.1 a.2.2) := Finset.sum_comm
    _ = _ := by
      simp only [Fintype.sum_prod_type, ← h, Finset.mul_sum]
      apply Finset.sum_congr rfl; intro j _
      exact rotate _

private theorem pair_transform {W V : Table} (h : MarkedConstraints W V) (φ : Table) :
    pair W (leftAdj kx (rightAdj ky (localAdj φ))) =
      pair V (fun p k l => 5^11 * φ p k l) := by
  have hadj (o : OM) (b : X) (d : Y) :
      leftAdj kx (rightAdj ky (localAdj φ)) o b d =
        ∑ a : OM × X × Y, φ a.1 a.2.1 a.2.2 * K a.1 o * kx a.2.1 b * ky a.2.2 d := by
    simp only [leftAdj, rightAdj, localAdj, Finset.mul_sum, Fintype.sum_prod_type]
    rw [rotate]
    apply Finset.sum_congr rfl; intro p _
    apply Finset.sum_congr rfl; intro k _
    apply Finset.sum_congr rfl; intro l _
    ring
  calc
    _ = ∑ a : OM × X × Y, W a.1 a.2.1 a.2.2 *
      ∑ t : OM × X × Y, φ t.1 t.2.1 t.2.2 * K t.1 a.1 * kx t.2.1 a.2.1 * ky t.2.2 a.2.2 := by
        simp only [pair, hadj, Fintype.sum_prod_type]
    _ = ∑ t : OM × X × Y, φ t.1 t.2.1 t.2.2 *
      ∑ a : OM × X × Y, W a.1 a.2.1 a.2.2 * K t.1 a.1 * kx t.2.1 a.2.1 * ky t.2.2 a.2.2 := by
        simp only [Finset.mul_sum]
        rw [Finset.sum_comm]
        apply Finset.sum_congr rfl; intro t _
        apply Finset.sum_congr rfl; intro a _
        ring
    _ = _ := by
      simp only [pair, Fintype.sum_prod_type, kx, ky, ← h.transform]
      apply Finset.sum_congr rfl; intro o _
      apply Finset.sum_congr rfl; intro b _
      apply Finset.sum_congr rfl; intro d _
      ring

private theorem score_identity {W V : Table} (h : MarkedConstraints W V) (s : Score) :
    pair W (s.wcoef (leftAdj kx (rightAdj ky (localAdj s.phi)))) + pair V s.vcoef = s.rhs := by
  have hwl (j b) : ∑ o, ∑ d, pProfileL o j * W o b d = leftMass j b := by
    simpa [pProfileL, ite_mul, leftMass] using h.wleft j b
  have hwr (j d) : ∑ o, ∑ b, pProfileR o j * W o b d = rightMass j d := by
    simpa [pProfileR, ite_mul, rightMass] using h.wright j d
  have hneg : pair V (fun p k l => -(5^11 * s.phi p k l)) =
      -pair V (fun p k l => 5^11 * s.phi p k l) := by simp [pair]
  unfold Score.wcoef Score.vcoef
  rw [pair_add, pair_add, pair_add, pair_add, pair_add, pair_add,
    pair_left _ _ s.wl _ hwl, pair_right _ _ s.wr _ hwr,
    pair_left _ _ s.vl _ h.vleft, pair_right _ _ s.vr _ h.vright,
    pair_corner, pair_corner, h.wzero, h.vzero, pair_transform h, hneg]
  unfold Score.rhs leftMass rightMass
  ring

/-- Numerical certificate for infeasibility, using two intermediate integer tables so that
each kernel computation has only one finite sum. -/
theorem impossible_of_score {W V : Table} (h : MarkedConstraints W V) (s : Score)
    (P : X → X → ℤ) (Q : Y → Y → ℤ) (hp : P = kx) (hq : Q = ky) (g t : Table)
    (hg : g = localAdj s.phi) (ht : t = rightAdj Q g)
    (hw : ∀ o b d, wForbidden o b d ∨ 0 ≤ s.wcoef (leftAdj P t) o b d)
    (hv : ∀ o b d, vForbidden o b d ∨ 0 ≤ s.vcoef o b d) (hr : s.rhs < 0) : False := by
  subst P; subst Q; subst g; subst t
  have zw : 0 ≤ pair W (s.wcoef (leftAdj kx (rightAdj ky (localAdj s.phi)))) := by
    apply Finset.sum_nonneg; intro o _
    apply Finset.sum_nonneg; intro b _
    apply Finset.sum_nonneg; intro d _
    rcases hw o b d with he | hn
    · rw [h.wforbid o b d he, zero_mul]
    · exact mul_nonneg (h.wnonneg ..) hn
  have zv : 0 ≤ pair V s.vcoef := by
    apply Finset.sum_nonneg; intro o _
    apply Finset.sum_nonneg; intro b _
    apply Finset.sum_nonneg; intro d _
    rcases hv o b d with he | hn
    · rw [h.vforbid o b d he, zero_mul]
    · exact mul_nonneg (h.vnonneg ..) hn
  exact hr.not_ge (score_identity h s ▸ add_nonneg zw zv)

end AlonJaegerTarsi.MarkedEleven
