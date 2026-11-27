import Task.MarkedFourier
import Task.MarkedNormalization
import Task.PolynomialMarkedData

namespace AlonJaegerTarsi.MarkedEleven

open Matrix Finset WeightTransform MarkedFourier
open scoped BigOperators

noncomputable section

set_option maxRecDepth 16000

abbrev Word := Fin 11 → ZMod 5
abbrev Matrix11 := Matrix (Fin 11) (Fin 11) (ZMod 5)
abbrev Cell := OM × X × Y

def wtIndex {d : ℕ} (v : Fin d → ZMod 5) : Fin (d+1) :=
  ⟨wt v, Nat.lt_succ_of_le (wt_le v)⟩

def primalKey (B : Matrix11) (x : Word) : Cell :=
  (pTag (mark 3 8 2 9 x (B *ᵥ x)), wtIndex (back 3 8 x), wtIndex (back 2 9 (B *ᵥ x)))

def dualKey (B : Matrix11) (y : Word) : Cell :=
  (vTag (mark 3 8 2 9 (-(Bᵀ *ᵥ y)) y), wtIndex (back 3 8 (-(Bᵀ *ᵥ y))), wtIndex (back 2 9 y))

def fiberTable {A : Type*} [Fintype A] (key : A → Cell) : Table :=
  fun o b d => (univ.filter fun x => key x = (o,b,d)).card

def primalTable (B : Matrix11) : Table := fiberTable (primalKey B)
def dualTable (B : Matrix11) : Table := fiberTable (dualKey B)

theorem fiberTable_nonneg {A : Type*} [Fintype A] (key : A → Cell) (o b d) :
    0 ≤ fiberTable key o b d := by unfold fiberTable; positivity

theorem sum_fiberTable {A R : Type*} [Fintype A] [Ring R] (key : A → Cell) (f : Cell → R) :
    (∑ x, f (key x)) = ∑ o, ∑ b, ∑ d, (fiberTable key o b d : R) * f (o,b,d) := by
  classical
  have h (p : Cell) : (∑ x, if key x = p then f (key x) else 0) =
      (fiberTable key p.1 p.2.1 p.2.2 : R) * f p := by
    simp only [ite_congr rfl (fun h => congrArg f h) (fun _ => rfl), ← Finset.sum_filter]
    simp [fiberTable]
  calc
    _ = ∑ x, ∑ p : Cell, if key x = p then f (key x) else 0 := by simp
    _ = ∑ p : Cell, ∑ x, if key x = p then f (key x) else 0 := Finset.sum_comm
    _ = _ := by simp only [h, Fintype.sum_prod_type]


theorem prefix_append (a b : ℕ) : markPrefix a = Fin.append (fun _ : Fin a => (1 : ZMod 5))
    (fun _ : Fin b => 0) := by
  funext i
  induction i using Fin.addCases with
  | left i => simp [markPrefix, Fin.val_castAdd]
  | right i => simp [markPrefix, Fin.val_natAdd]

theorem dot_prefix (a b : ℕ) (x : Vec 5 (a+b)) :
    markPrefix a ⬝ᵥ x = ∑ i, front a b x i := by
  rw [dot_parts (a := a) (b := b), prefix_append a b, front_append, back_append]
  simp [dotProduct]

theorem mark_sum_zero (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3) (x : Word) :
    ∑ i, mark 3 8 2 9 x (B *ᵥ x) i = 0 := by
  have h : markPrefix 2 ⬝ᵥ (B *ᵥ x) = -(markPrefix 3 ⬝ᵥ x) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hm, neg_dotProduct]
  rw [dot_prefix 2 9, dot_prefix 3 8] at h
  rw [Fin.sum_univ_add]
  simp [mark, h]

theorem leftWt_mark (x y : Word) : leftWt (mark 3 8 2 9 x y) = wtIndex (front 3 8 x) := by
  apply Fin.ext
  simp [leftWt, mark, wtIndex, wt]

theorem rightWt_mark (x y : Word) : rightWt (mark 3 8 2 9 x y) = wtIndex (front 2 9 y) := by
  apply Fin.ext
  simp [rightWt, mark, wtIndex, wt]

theorem wt_split (a b : ℕ) (x : Vec 5 (a+b)) :
    wt x = wt (front a b x) + wt (back a b x) := by
  simp only [wt, Finset.card_filter]
  exact Fin.sum_univ_add _

def translatePrefix (a b : ℕ) (c : ZMod 5) (v : Vec 5 (a+b)) : Vec 5 (a+b) :=
  v + c • markPrefix a

@[simp] theorem front_translatePrefix (a b : ℕ) (c : ZMod 5) (v : Vec 5 (a+b)) :
    front a b (translatePrefix a b c v) = fun i => front a b v i + c := by
  funext i
  simp [translatePrefix, front, markPrefix, Fin.val_castAdd]

@[simp] theorem back_translatePrefix (a b : ℕ) (c : ZMod 5) (v : Vec 5 (a+b)) :
    back a b (translatePrefix a b c v) = back a b v := by
  funext i
  simp [translatePrefix, back, markPrefix, Fin.val_natAdd]

theorem shifted_mark (x y : Word) (a : ZMod 5) :
    shifted (mark 3 8 2 9 x y) a = mark 3 8 2 9 (translatePrefix 3 8 a x) (translatePrefix 2 9 a y) := by
  funext i
  refine Fin.addCases (m := 3) (n := 2) (fun i => ?_) (fun i => ?_) i <;> simp [shifted, mark]

theorem dual_translate (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3)
    (a : ZMod 5) (y : Word) :
    -(Bᵀ *ᵥ translatePrefix 2 9 a y) = translatePrefix 3 8 a (-(Bᵀ *ᵥ y)) := by
  simp [translatePrefix, mulVec_add, mulVec_smul, hm, add_comm]

private theorem sumCellLeft {A : Type*} [Fintype A] (key : A → Cell) (f : OM → ℤ) (b : X) :
    (∑ o, ∑ d, f o * fiberTable key o b d) =
      ∑ x, if (key x).2.1 = b then f (key x).1 else 0 := by
  have he := sum_fiberTable key (fun p => if p.2.1 = b then f p.1 else 0)
  simpa [mul_ite, Finset.sum_ite_irrel, mul_comm] using he.symm

private theorem sumCellRight {A : Type*} [Fintype A] (key : A → Cell) (f : OM → ℤ) (d : Y) :
    (∑ o, ∑ b, f o * fiberTable key o b d) =
      ∑ x, if (key x).2.2 = d then f (key x).1 else 0 := by
  have he := sum_fiberTable key (fun p => if p.2.2 = d then f p.1 else 0)
  simpa [mul_ite, mul_comm] using he.symm

private theorem sumSphere (a : ℕ) (i : Fin (a+1)) :
    (∑ x : Vec 5 a, if wtIndex x = i then (1:ℤ) else 0) = sphere a i := by
  rw [← Finset.sum_filter]
  simp only [Finset.sum_const, nsmul_eq_mul, mul_one]
  have hf (x : Vec 5 a) : wtIndex x = i ↔ wt x = i := Fin.ext_iff
  simp only [hf]
  rw [sphere_card]
  push_cast
  rfl

private theorem splitSphere (a b : ℕ) (u : Fin (a+1)) (k : Fin (b+1)) :
    (∑ x : Vec 5 (a+b), if wtIndex (back a b x) = k then
      (if wtIndex (front a b x) = u then (1:ℤ) else 0) else 0) =
        sphere a u * sphere b k := by
  let e : Vec 5 a × Vec 5 b ≃ Vec 5 (a+b) := Fin.appendEquiv a b
  rw [← e.sum_comp, Fintype.sum_prod_type, ← sumSphere a u, ← sumSphere b k]
  simp only [e, Fin.appendEquiv, Equiv.coe_fn_mk, front_append, back_append, Finset.sum_mul, Finset.mul_sum]
  conv_rhs => rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro x _
  apply Finset.sum_congr rfl
  intro y _
  by_cases hx : wtIndex x = u <;> by_cases hy : wtIndex y = k <;> simp [hx,hy]

private theorem mulVecBij (B : Matrix11) (hB : B.det ≠ 0) : Function.Bijective B.mulVec := by
  letI : Fact (Nat.Prime 5) := ⟨by decide⟩
  have hu := (Matrix.isUnit_iff_isUnit_det B).mpr hB.isUnit
  exact ⟨Matrix.mulVec_injective_iff_isUnit.mpr hu, Matrix.mulVec_surjective_iff_isUnit.mpr hu⟩


private def shiftedEquiv (a b : ℕ) (c : ZMod 5) : Vec 5 (a+b) ≃ Vec 5 (a+b) where
  toFun := translatePrefix a b c
  invFun := fun x => x - c • markPrefix a
  left_inv := fun _ => add_sub_cancel_right ..
  right_inv := fun _ => sub_add_cancel ..

private theorem shiftedMass (a b : ℕ) (u : Fin (a+1)) (k : Fin (b+1))
    (w : Word → Vec 5 (a+b)) (hw : Function.Bijective w) :
    (∑ y, if wtIndex (back a b (w y)) = k then
        ((univ.filter fun c : ZMod 5 => wtIndex (front a b (translatePrefix a b c (w y))) = u).card : ℤ)
      else 0) = 5 * (sphere a u * sphere b k) := by
  have h (y) :
      (if wtIndex (back a b (w y)) = k then
        ((univ.filter fun c : ZMod 5 => wtIndex (front a b (translatePrefix a b c (w y))) = u).card : ℤ)
      else 0) = ∑ c : ZMod 5, if wtIndex (back a b (translatePrefix a b c (w y))) = k then
        (if wtIndex (front a b (translatePrefix a b c (w y))) = u then 1 else 0) else 0 := by
    by_cases hb : wtIndex (back a b (w y)) = k
    · simp only [back_translatePrefix, hb, if_true, Finset.card_filter, Nat.cast_sum,
        apply_ite (Nat.cast : ℕ → ℤ), Nat.cast_one, Nat.cast_zero]
    · simp [hb]
  simp_rw [h]
  rw [Finset.sum_comm]
  have ht (c : ZMod 5) : (∑ y, if wtIndex (back a b (translatePrefix a b c (w y))) = k then
        (if wtIndex (front a b (translatePrefix a b c (w y))) = u then (1:ℤ) else 0) else 0) =
        sphere a u * sphere b k := by
    let e := (Equiv.ofBijective w hw).trans (shiftedEquiv a b c)
    exact (e.sum_comp (fun x => if wtIndex (back a b x) = k then
      (if wtIndex (front a b x) = u then (1:ℤ) else 0) else 0)).trans (splitSphere a b u k)
  simp only [ht, sum_const, card_univ, ZMod.card, nsmul_eq_mul, Nat.cast_ofNat]

theorem primalLeft (hTag : ∀ t : Tuple, (∑ i, t i) = 0 → pwL (pTag t) = leftWt t)
    (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3) (u : Fin 4) (b : X) :
    (∑ o, ∑ d, if pwL o = u then primalTable B o b d else 0) = sphere 3 u * sphere 8 b := by
  have he := sumCellLeft (primalKey B) (fun o => if pwL o = u then 1 else 0) b
  have hi (x : Word) : pwL (pTag (mark 3 8 2 9 x (B *ᵥ x))) = wtIndex (front 3 8 x) :=
    (hTag _ (mark_sum_zero B hm x)).trans (leftWt_mark ..)
  simpa only [primalKey, primalTable, ite_mul, one_mul, zero_mul, hi] using he.trans
    (by simpa only [primalKey,hi] using splitSphere 3 8 u b)

theorem primalRight (hTag : ∀ t : Tuple, (∑ i, t i) = 0 → pwR (pTag t) = rightWt t)
    (B : Matrix11) (hB : B.det ≠ 0) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3)
    (u : Fin 3) (d : Y) :
    (∑ o, ∑ b, if pwR o = u then primalTable B o b d else 0) = sphere 2 u * sphere 9 d := by
  have he := sumCellRight (primalKey B) (fun o => if pwR o = u then 1 else 0) d
  have hi (x : Word) : pwR (pTag (mark 3 8 2 9 x (B *ᵥ x))) = wtIndex (front 2 9 (B *ᵥ x)) :=
    (hTag _ (mark_sum_zero B hm x)).trans (rightWt_mark ..)
  let e := Equiv.ofBijective B.mulVec (mulVecBij B hB)
  have hp := (e.sum_comp (fun x => if wtIndex (back 2 9 x) = d then
    (if wtIndex (front 2 9 x) = u then (1:ℤ) else 0) else 0)).trans (splitSphere 2 9 u d)
  simpa only [primalKey, primalTable, ite_mul, one_mul, zero_mul, hi] using he.trans
    (by simpa only [primalKey,hi,e,Equiv.ofBijective_apply] using hp)

theorem dualLeft
    (hTag : ∀ (t : Tuple) (u : Fin 4), vwL (vTag t) u =
      ((univ.filter fun a : ZMod 5 => leftWt (shifted t a) = u).card : ℤ))
    (B : Matrix11) (hB : B.det ≠ 0) (u : Fin 4) (b : X) :
    (∑ o, ∑ d, vwL o u * dualTable B o b d) = 5 * (sphere 3 u * sphere 8 b) := by
  let w (y : Word) := -(Bᵀ *ᵥ y)
  have hw : Function.Bijective w := neg_bijective.comp (mulVecBij Bᵀ (by simpa using hB))
  have he := sumCellLeft (dualKey B) (fun o => vwL o u) b
  refine he.trans ?_
  simpa only [dualKey, hTag, shifted_mark, leftWt_mark, w] using shiftedMass 3 8 u b w hw

theorem dualRight
    (hTag : ∀ (t : Tuple) (u : Fin 3), vwR (vTag t) u =
      ((univ.filter fun a : ZMod 5 => rightWt (shifted t a) = u).card : ℤ))
    (B : Matrix11) (u : Fin 3) (d : Y) :
    (∑ o, ∑ b, vwR o u * dualTable B o b d) = 5 * (sphere 2 u * sphere 9 d) := by
  have he := sumCellRight (dualKey B) (fun o => vwR o u) d
  refine he.trans ?_
  simpa only [dualKey, hTag, shifted_mark, rightWt_mark,id_eq] using
    shiftedMass 2 9 u d id Function.bijective_id


@[simp] private theorem frontPrefix (a b : ℕ) (c : ZMod 5) :
    front a b (c • markPrefix a) = fun _ => c := by
  funext i
  simp [front,markPrefix, Fin.val_castAdd]

@[simp] private theorem backPrefix (a b : ℕ) (c : ZMod 5) :
    back a b (c • markPrefix a) = 0 := by
  funext i
  simp [back,markPrefix, Fin.val_natAdd]

private theorem eqPrefix_of_parts (a b : ℕ) (v : Vec 5 (a+b)) (c : ZMod 5)
    (hf : front a b v = fun _ => c) (hb : back a b v = 0) : v = c • markPrefix a := by
  calc
    v = Fin.append (front a b v) (back a b v) := (append_parts v).symm
    _ = Fin.append (front a b (c • markPrefix a)) (back a b (c • markPrefix a)) := by simp [hf,hb]
    _ = _ := append_parts _

theorem primalCorner
    (hTag : ∀ t : Tuple, (∑ i, t i) = 0 → (pTag t = 0 ↔ t = 0))
    (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3) : primalTable B 0 0 0 = 1 := by
  have hz (x : Word) : primalKey B x = (0,0,0) ↔ x = 0 := by
    constructor
    · intro he
      have htag := congrArg (fun p : Cell => p.1) he
      have ht := (hTag _ (mark_sum_zero B hm x)).mp htag
      have hback := (wt_eq_zero _).mp (congrArg (fun p : Cell => p.2.1.val) he)
      have hf0 : front 3 2 (0 : Tuple) = 0 := rfl
      have hfront : front 3 8 x = 0 := by simpa only [mark,front_append,hf0] using congrArg (front 3 2) ht
      simpa using eqPrefix_of_parts 3 8 x 0 hfront hback
    · rintro rfl
      have hmark : mark 3 8 2 9 (0 : Word) (0 : Word) = 0 := by
        funext i
        refine Fin.addCases (m := 3) (n := 2) (fun j => ?_) (fun j => ?_) i <;> simp [mark, front]
      have hz (a b : ℕ) : back a b (0 : Vec 5 (a+b)) = 0 := rfl
      simp [primalKey,hmark,(hTag (0 : Tuple) (by simp)).2 rfl,wtIndex,hz]
  have hs : (univ.filter fun x => primalKey B x = (0,0,0)) = {0} := by ext x; simp [hz]
  simp [primalTable, fiberTable, hs]

theorem dualCorner
    (hTag : ∀ t : Tuple, vTag t = 0 ↔ ∀ i, t i = t 0)
    (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3) : dualTable B 0 0 0 = 5 := by
  classical
  let word (c : ZMod 5) : Word := c • markPrefix 2
  have hinj : Function.Injective word :=
    fun a b h => by simpa [word,markPrefix] using congrFun h (0 : Fin 11)
  have hz (y : Word) : dualKey B y = (0,0,0) ↔ y ∈ Set.range word := by
    constructor
    · intro he
      let t := mark 3 8 2 9 (-(Bᵀ *ᵥ y)) y
      have htag := congrArg (fun p : Cell => p.1) he
      have ht : ∀ i, t i = t 0 := (hTag t).mp htag
      have hback := (wt_eq_zero _).mp (congrArg (fun p : Cell => p.2.2.val) he)
      have hfront : front 2 9 y = fun _ => t 0 := by
        funext i
        exact (Fin.append_right ..).symm.trans (ht (Fin.natAdd 3 i))
      exact ⟨t 0, (eqPrefix_of_parts 2 9 y (t 0) hfront hback).symm⟩
    · rintro ⟨c, rfl⟩
      have hx : -(Bᵀ *ᵥ word c) = c • markPrefix 3 := by simp [word, mulVec_smul, hm]
      have hmark : mark 3 8 2 9 (c • markPrefix 3) (word c) = fun _ => c := by
        change Fin.append (front 3 8 (c • markPrefix 3)) (front 2 9 (c • markPrefix 2)) = _
        rw [frontPrefix 3 8 c, frontPrefix 2 9 c]
        funext i
        refine Fin.addCases (m := 3) (n := 2) (fun j => ?_) (fun j => ?_) i <;> simp
      have htag : vTag (fun _ : Fin 5 => c) = 0 := (hTag _).2 (fun _ => rfl)
      simp only [dualKey, hx, hmark, htag, word, wtIndex]
      rfl
  have hs : (univ.filter fun y => dualKey B y = (0,0,0)) = univ.image word := by
    ext y
    simp only [mem_filter,mem_univ,true_and,hz,mem_image]
    simp
  rw [dualTable,fiberTable, hs, card_image_of_injective _ hinj,card_univ,ZMod.card]
  rfl

private theorem fiberZero {A : Type*} [Fintype A] (key : A → Cell) (o b d)
    (h : ∀ x, key x ≠ (o,b,d)) : fiberTable key o b d = 0 := by
  have hs : (univ.filter fun x => key x = (o,b,d)) = ∅ := by simp [h]
  simp [fiberTable, hs]

theorem primalForbid
    (hL : ∀ t : Tuple, (∑ i, t i) = 0 → pwL (pTag t) = leftWt t)
    (hR : ∀ t : Tuple, (∑ i, t i) = 0 → pwR (pTag t) = rightWt t)
    (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3)
    (hw : ∀ x : Word, ¬primalForbidden (wt x) (wt (B *ᵥ x))) (o b d) (h : wForbidden o b d) :
    primalTable B o b d = 0 := by
  apply fiberZero
  intro x he
  have hh : wForbidden (primalKey B x).1 (primalKey B x).2.1 (primalKey B x).2.2 := he.symm ▸ h
  simp only [wForbidden,primalKey,hL _ (mark_sum_zero B hm x),hR _ (mark_sum_zero B hm x),
    leftWt_mark,rightWt_mark,wtIndex, ← wt_split] at hh
  exact hw x hh

theorem dualForbid
    (htag : ∀ (t : Tuple) (a : ZMod 5), ∃ c : ZMod 5, leftWt (shifted t c) = shiftL (vTag t) a ∧
      rightWt (shifted t c) = shiftR (vTag t) a)
    (B : Matrix11) (hm : Bᵀ *ᵥ markPrefix 2 = -markPrefix 3)
    (hv : ∀ y : Word, ¬dualForbidden (wt (-(Bᵀ *ᵥ y))) (wt y))
    (o b d) (h : vForbidden o b d) : dualTable B o b d = 0 := by
  apply fiberZero
  intro y he
  obtain ⟨a, ha⟩ : vForbidden (dualKey B y).1 (dualKey B y).2.1 (dualKey B y).2.2 := he.symm ▸ h
  let z := -(Bᵀ *ᵥ y)
  let t := mark 3 8 2 9 z y
  obtain ⟨c, hL, hR⟩ := htag t a
  apply hv (translatePrefix 2 9 c y)
  rw [dual_translate B hm, wt_split 3 8, wt_split 2 9,back_translatePrefix,back_translatePrefix]
  change dualForbidden ((shiftL (vTag t) a).val + wt (back 3 8 z))
    ((shiftR (vTag t) a).val + wt (back 2 9 y)) at ha
  rw [← hL, ← hR, show t = mark 3 8 2 9 z y from rfl, shifted_mark, leftWt_mark, rightWt_mark] at ha
  exact ha

/-- Zero ordinary counts exclude every vector having the indicated forbidden weight pair. -/
theorem notForbiddenOfCounts {P : ℕ → ℕ → Prop} (B : Matrix11)
    (hz : ∀ i j, P i j → counts B i j = 0) (x : Word) : ¬P (wt x) (wt (B *ᵥ x)) := by
  intro h
  have pos : 0 < counts B (wt x) (wt (B *ᵥ x)) := Finset.card_pos.mpr ⟨x, by simp⟩
  exact pos.ne' (hz _ _ h)


/-- Convert the transpose enumerator's usual input/output order into the
left/right order of the dual graph code. -/
theorem dualNotForbiddenOfCounts (B : Matrix11)
    (hz : ∀ i j, dualForbidden j i → counts Bᵀ i j = 0) (y : Word) :
    ¬dualForbidden (wt (-(Bᵀ *ᵥ y))) (wt y) := by
  rw [wt_neg]
  exact notForbiddenOfCounts (P := fun i j => dualForbidden j i) Bᵀ hz y

end
end AlonJaegerTarsi.MarkedEleven
