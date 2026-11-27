import Task.WeightTransform

/-! An exact linear inequality for symmetrized split weight enumerators over the field of five
elements. The accompanying numerical certificates supply the integer multipliers. -/

open Matrix Finset
open scoped BigOperators

namespace AlonJaegerTarsi.WeightTransform

abbrev WeightIndex (n : ℕ) := Fin (n + 1)
abbrev WeightTable (n : ℕ) := Matrix (WeightIndex n) (WeightIndex n) ℤ

def sphere (n i : ℕ) : ℤ := (n.choose i : ℤ) * 4 ^ i

def krawTable (n : ℕ) : WeightTable n := fun a i => kraw 5 n a i

/-- The identities and low-weight exclusions consumed by the certificates. The normalization
permits doubled integer counts obtained by adding a table to its transpose. -/
structure SpectrumConstraints (n : ℕ) (W V : WeightTable n) (mass : ℤ) : Prop where
  wnonneg : ∀ i j, 0 ≤ W i j
  vnonneg : ∀ i j, 0 ≤ V i j
  wsymm : ∀ i j, W i j = W j i
  vsymm : ∀ i j, V i j = V j i
  wzero : W 0 0 = mass
  vzero : V 0 0 = mass
  wrow : ∀ i, ∑ j, W i j = mass * sphere n i
  vrow : ∀ i, ∑ j, V i j = mass * sphere n i
  transform : ∀ a b, (5 : ℤ) ^ n * V a b =
    ∑ i, ∑ j, W i j * kraw 5 n a i * kraw 5 n b j
  wlow : ∀ i j : WeightIndex n, 1 ≤ i.val → i.val ≤ 2 → i.val ≤ j.val → j.val ≤ 3 → W i j = 0
  vlow : ∀ i j : WeightIndex n, i.val = 1 → i.val ≤ j.val → j.val ≤ 2 → V i j = 0

/-- The two row-sum multiplier lists and the transform multipliers. -/
structure SpectrumMultipliers (n : ℕ) where
  u : WeightIndex n → ℤ
  v : WeightIndex n → ℤ
  t : WeightTable n

def SpectrumMultipliers.wcoef {n : ℕ} (l : SpectrumMultipliers n) (K : WeightTable n) :
    WeightTable n := fun i j => l.u i + l.u j + (K.transpose * l.t * K) i j

def SpectrumMultipliers.vcoef {n : ℕ} (l : SpectrumMultipliers n) : WeightTable n :=
  fun i j => l.v i + l.v j - 5 ^ n * l.t i j

def SpectrumMultipliers.rhs {n : ℕ} (l : SpectrumMultipliers n) : ℤ :=
  2 * ∑ i, (l.u i + l.v i) * sphere n i

def primalException (n i j : ℕ) : Prop :=
  (i = 0 ∧ j = 0) ∨ (i = n ∧ j = n) ∨ (1 ≤ min i j ∧ min i j ≤ 2 ∧ max i j ≤ 3)

def dualException (i j : ℕ) : Prop :=
  (i = 0 ∧ j = 0) ∨ (min i j = 1 ∧ max i j ≤ 2)

instance (n i j : ℕ) : Decidable (primalException n i j) :=
  inferInstanceAs (Decidable ((_ ∧ _) ∨ (_ ∧ _) ∨ (_ ∧ _ ∧ _)))

instance (i j : ℕ) : Decidable (dualException i j) :=
  inferInstanceAs (Decidable ((_ ∧ _) ∨ (_ ∧ _)))

def pairing {n : ℕ} (W C : WeightTable n) : ℤ := ∑ i, ∑ j, W i j * C i j

private theorem pairing_add {n : ℕ} (W C E : WeightTable n) :
    pairing W (fun i j => C i j + E i j) = pairing W C + pairing W E := by
  simp [pairing, mul_add, Finset.sum_add_distrib]

private theorem pairing_sub {n : ℕ} (W C E : WeightTable n) :
    pairing W (fun i j => C i j - E i j) = pairing W C - pairing W E := by
  simp [pairing, mul_sub, Finset.sum_sub_distrib]

private theorem pairing_row {n : ℕ} (W : WeightTable n) (u : WeightIndex n → ℤ) (mass : ℤ)
    (hs : ∀ i j, W i j = W j i) (hr : ∀ i, ∑ j, W i j = mass * sphere n i) :
    pairing W (fun i j => u i + u j) = 2 * mass * ∑ i, u i * sphere n i := by
  have hfirst : pairing W (fun i _ => u i) = mass * ∑ i, u i * sphere n i := by
    simp only [pairing, ← Finset.sum_mul, hr, Finset.mul_sum]
    congr 1
    funext i
    ring
  have hsecond : pairing W (fun _ j => u j) = pairing W (fun i _ => u i) := by
    unfold pairing
    rw [Finset.sum_comm]
    exact Finset.sum_congr rfl (fun i _ => Finset.sum_congr rfl (fun j _ => by rw [hs j i]))
  rw [pairing_add W (fun i _ => u i) (fun _ j => u j), hsecond, hfirst]
  ring

private theorem pairing_transform {n : ℕ} {W V : WeightTable n} {mass : ℤ}
    (h : SpectrumConstraints n W V mass) (T : WeightTable n) :
    pairing W ((krawTable n).transpose * T * krawTable n) =
      pairing V (fun a b => 5 ^ n * T a b) := by
  have he (i j : WeightIndex n) :
      ((krawTable n).transpose * T * krawTable n) i j =
        ∑ s : WeightIndex n × WeightIndex n, T s.1 s.2 * kraw 5 n s.1 i * kraw 5 n s.2 j := by
    simp only [Matrix.mul_apply, Matrix.transpose_apply, krawTable, Finset.sum_mul,
      Fintype.sum_prod_type]
    rw [Finset.sum_comm]
    exact Finset.sum_congr rfl (fun a _ => Finset.sum_congr rfl (fun b _ => by ring))
  calc
    pairing W ((krawTable n).transpose * T * krawTable n) =
      ∑ s : WeightIndex n × WeightIndex n, W s.1 s.2 *
        ∑ t : WeightIndex n × WeightIndex n, T t.1 t.2 * kraw 5 n t.1 s.1 * kraw 5 n t.2 s.2 := by
          simp only [pairing, he, Fintype.sum_prod_type]
    _ = ∑ t : WeightIndex n × WeightIndex n, T t.1 t.2 *
        ∑ s : WeightIndex n × WeightIndex n, W s.1 s.2 * kraw 5 n t.1 s.1 * kraw 5 n t.2 s.2 := by
          simp only [Finset.mul_sum]
          rw [Finset.sum_comm]
          exact Finset.sum_congr rfl (fun t _ => Finset.sum_congr rfl (fun s _ => by ring))
    _ = pairing V (fun a b => 5 ^ n * T a b) := by
          simp only [Fintype.sum_prod_type, ← h.transform, pairing]
          exact Finset.sum_congr rfl (fun a _ => Finset.sum_congr rfl (fun b _ => by ring))

theorem multiplier_identity {n : ℕ} {W V : WeightTable n} {mass : ℤ}
    (h : SpectrumConstraints n W V mass) (l : SpectrumMultipliers n) :
    pairing W (l.wcoef (krawTable n)) + pairing V l.vcoef = mass * l.rhs := by
  unfold SpectrumMultipliers.wcoef SpectrumMultipliers.vcoef
  rw [pairing_add W (fun i j => l.u i + l.u j) ((krawTable n).transpose * l.t * krawTable n),
    pairing_sub V (fun i j => l.v i + l.v j) (fun a b => 5 ^ n * l.t a b),
    pairing_transform h, pairing_row W _ _ h.wsymm h.wrow, pairing_row V _ _ h.vsymm h.vrow]
  unfold SpectrumMultipliers.rhs
  simp only [add_mul, Finset.sum_add_distrib]
  ring

private theorem pairing_ge_corner {n : ℕ} (C E : WeightTable n) (mass : ℤ)
    (hcorner : E 0 0 = mass) (h : ∀ i j, ¬(i = 0 ∧ j = 0) → 0 ≤ E i j * C i j) :
    mass * C 0 0 ≤ pairing E C := by
  have hb (i j : WeightIndex n) : (if i = 0 ∧ j = 0 then mass * C 0 0 else 0) ≤ E i j * C i j := by
    split_ifs with hz
    · rcases hz with ⟨rfl, rfl⟩
      rw [hcorner]
    · exact h i j hz
  calc
    mass * C 0 0 = ∑ i : WeightIndex n, ∑ j : WeightIndex n,
      if i = 0 ∧ j = 0 then mass * C 0 0 else 0 := by simp [ite_and]
    _ ≤ pairing E C := Finset.sum_le_sum (fun i _ => Finset.sum_le_sum (fun j _ => hb i j))

/-- Sufficient numerical inequalities for positive full weight, with an explicit table of
Krawtchouk values to allow efficient checks of the matrix products. -/
theorem full_positive_of_multipliers_with_zeros {n : ℕ} {W V : WeightTable n} {mass : ℤ}
    (h : SpectrumConstraints n W V mass) (hm : 0 < mass) (l : SpectrumMultipliers n)
    (K : WeightTable n) (hk : K = krawTable n)
    (hw : ∀ i j : WeightIndex n, primalException n i j ∨ 0 ≤ l.wcoef K i j)
    (hv : ∀ i j : WeightIndex n, dualException i j ∨ V i j = 0 ∨ 0 ≤ l.vcoef i j)
    (hn : l.rhs < l.wcoef K 0 0 + l.vcoef 0 0) :
    0 < W (Fin.last n) (Fin.last n) := by
  subst K
  by_contra! hbad
  have hnn := le_antisymm hbad (h.wnonneg ..)
  have hw' := pairing_ge_corner (l.wcoef (krawTable n)) W mass h.wzero (fun i j hnz => by
    rcases hw i j with hex | hnpos
    · have z : W i j = 0 := by
        rcases hex with h0 | hn' | hlo
        · exact False.elim (hnz ⟨Fin.ext h0.1, Fin.ext h0.2⟩)
        · simpa [show i = Fin.last n from Fin.ext hn'.1, show j = Fin.last n from Fin.ext hn'.2] using hnn
        · by_cases hij : i.val ≤ j.val
          · exact h.wlow _ _ (by omega) (by omega) hij (by omega)
          · rw [h.wsymm]
            exact h.wlow _ _ (by omega) (by omega) (by omega) (by omega)
      rw [z, zero_mul]
    · exact mul_nonneg (h.wnonneg ..) hnpos)
  have hv' := pairing_ge_corner l.vcoef V mass h.vzero (fun i j hnz => by
    rcases hv i j with hex | hz | hnpos
    · have z : V i j = 0 := by
        rcases hex with h0 | hlo
        · exact False.elim (hnz ⟨Fin.ext h0.1, Fin.ext h0.2⟩)
        · by_cases hij : i.val ≤ j.val
          · exact h.vlow _ _ (by omega) hij (by omega)
          · rw [h.vsymm]
            exact h.vlow _ _ (by omega) (by omega) (by omega)
      rw [z, zero_mul]
    · rw [hz, zero_mul]
    · exact mul_nonneg (h.vnonneg ..) hnpos)
  have hlin := add_le_add hw' hv'
  rw [multiplier_identity h l, ← mul_add] at hlin
  exact (not_le_of_gt (mul_lt_mul_of_pos_left hn hm)) hlin

theorem full_positive_of_multipliers {n : ℕ} {W V : WeightTable n} {mass : ℤ}
    (h : SpectrumConstraints n W V mass) (hm : 0 < mass) (l : SpectrumMultipliers n)
    (K : WeightTable n) (hk : K = krawTable n)
    (hw : ∀ i j : WeightIndex n, primalException n i j ∨ 0 ≤ l.wcoef K i j)
    (hv : ∀ i j : WeightIndex n, dualException i j ∨ 0 ≤ l.vcoef i j)
    (hn : l.rhs < l.wcoef K 0 0 + l.vcoef 0 0) :
    0 < W (Fin.last n) (Fin.last n) := by
  apply full_positive_of_multipliers_with_zeros h hm l K hk hw _ hn
  intro i j
  exact (hv i j).imp_right Or.inr

end AlonJaegerTarsi.WeightTransform
