import ECC.Parity
import ECC.Packed

namespace ECC

/-- Decode an integer as n binary coordinates, coordinate zero first. -/
def decodeWord (n u : ℕ) : Word n :=
  fun i => if u.testBit i.val then 1 else 0

@[simp] theorem decodeWord_zero (n : ℕ) : decodeWord n 0 = 0 := by
  funext i
  simp [decodeWord]

theorem decodeWord_succ (n u : ℕ) :
    decodeWord (n + 1) u =
      Fin.cons ((u % 2 : ℕ) : F2) (decodeWord n (u / 2)) := by
  funext i
  refine Fin.cases ?_ (fun j => ?_) i
  · have h : u % 2 = 0 ∨ u % 2 = 1 := by omega
    rcases h with h | h <;>
      simp [decodeWord, Nat.testBit_eq_decide_div_mod_eq, h]
  · simp [decodeWord, Nat.testBit_div_two]

theorem decodeWord_xor (n u v : ℕ) :
    decodeWord n (u ^^^ v) = decodeWord n u + decodeWord n v := by
  funext i
  simp only [decodeWord, Nat.testBit_xor, Pi.add_apply]
  cases u.testBit i.val <;> cases v.testBit i.val <;> norm_num [F2]
  exact (CharTwo.add_self_eq_zero (1 : F2)).symm

theorem weight_decodeWord (n u : ℕ) :
    weight (decodeWord n u) = Packed.weight n u := by
  induction n generalizing u with
  | zero => simp [weight, Packed.weight]
  | succ n ih =>
    rw [decodeWord_succ, weight_cons, ih]
    have h : u % 2 = 0 ∨ u % 2 = 1 := by omega
    rcases h with h | h <;> simp [Packed.weight, h]

/-- Every F2-valued message is represented; enumeration does not omit messages. -/
theorem decodeWord_surjective (n : ℕ) (x : Word n) :
    ∃ u : ℕ, u < 2 ^ n ∧ decodeWord n u = x := by
  induction n with
  | zero =>
    refine ⟨0, by decide, ?_⟩
    funext i
    exact Fin.elim0 i
  | succ n ih =>
    obtain ⟨u, hu, hx⟩ := ih (Fin.tail x)
    let b : ℕ := (x 0).val
    have hb : b < 2 := ZMod.val_lt (x 0)
    have hbcast : (b : F2) = x 0 := ZMod.natCast_zmod_val (x 0)
    refine ⟨b + 2 * u, ?_, ?_⟩
    · rw [pow_succ]
      omega
    · rw [decodeWord_succ]
      have hm : (b + 2 * u) % 2 = b := by omega
      have hd : (b + 2 * u) / 2 = u := by omega
      rw [hm, hd, hbcast, hx]
      exact Fin.cons_self_tail x

/-- The actual F2-linear encoding map represented by the integer row list. -/
def linearEncode (n : ℕ) (rows : List ℕ) : Word rows.length →ₗ[F2] Word n where
  toFun u := ∑ i : Fin rows.length, u i • decodeWord n (rows.getD i.val 0)
  map_add' u v := by simp [add_smul, Finset.sum_add_distrib]
  map_smul' a u := by simp [Finset.smul_sum, smul_smul]

theorem linearEncode_cons (n r : ℕ) (rows : List ℕ) (u : Word (r :: rows).length) :
    linearEncode n (r :: rows) u =
      u 0 • decodeWord n r + linearEncode n rows (Fin.tail u) := by
  simp [linearEncode, Fin.sum_univ_succ]
  rfl

/-- Connect each arithmetic XOR computation to the mathematical generator map. -/
theorem linearEncode_decodeWord (n : ℕ) (rows : List ℕ) (u : ℕ) :
    linearEncode n rows (decodeWord rows.length u) =
      decodeWord n (Packed.encode rows u) := by
  induction rows generalizing u with
  | nil => simp [linearEncode, Packed.encode]
  | cons r rows ih =>
    rw [linearEncode_cons]
    simp only [List.length_cons]
    rw [decodeWord_succ]
    simp only [Fin.cons_zero, Fin.tail_cons]
    rw [ih]
    simp only [Packed.encode, decodeWord_xor]
    have h : u % 2 = 0 ∨ u % 2 = 1 := by omega
    rcases h with h | h <;> simp [h]

theorem distanceCheck_implies_message_bound {n d : ℕ} {rows : List ℕ}
    (h : Packed.distanceCheck n rows.length d rows = true)
    (x : Word rows.length) (hx : x ≠ 0) :
    d ≤ weight (linearEncode n rows x) := by
  obtain ⟨u, hu, rfl⟩ := decodeWord_surjective rows.length x
  have hne : u ≠ 0 := by
    intro hz
    simp [hz] at hx
  rw [linearEncode_decodeWord, weight_decodeWord]
  exact Packed.distanceCheck_sound h ⟨u, hu⟩ hne

theorem linearEncode_injective_of_distanceCheck {n d : ℕ} {rows : List ℕ}
    (hd : 0 < d) (h : Packed.distanceCheck n rows.length d rows = true) :
    Function.Injective (linearEncode n rows) := by
  apply (injective_iff_map_eq_zero (linearEncode n rows)).mpr
  intro x hx
  by_contra hne
  have hb := distanceCheck_implies_message_bound h x hne
  rw [hx, weight_zero] at hb
  omega

/-- A checked concrete matrix yields a code with the original mathematical parameters. -/
theorem codeExists_of_distanceCheck {n d : ℕ} {rows : List ℕ}
    (hd : 0 < d) (h : Packed.distanceCheck n rows.length d rows = true) :
    CodeExists n rows.length d := by
  refine ⟨LinearMap.range (linearEncode n rows), ?_, ?_⟩
  · rw [LinearMap.finrank_range_of_inj (linearEncode_injective_of_distanceCheck hd h)]
    simp [Word, F2]
  · rintro y ⟨x, rfl⟩ hne
    apply distanceCheck_implies_message_bound h x
    intro hx
    apply hne
    rw [hx, map_zero]

theorem evenCode_of_evenCheck {n : ℕ} {rows : List ℕ}
    (h : Packed.evenCheck n rows.length rows = true) :
    EvenCode (LinearMap.range (linearEncode n rows)) := by
  rintro y ⟨x, rfl⟩
  obtain ⟨u, hu, rfl⟩ := decodeWord_surjective rows.length x
  rw [linearEncode_decodeWord, weight_decodeWord]
  exact Nat.even_iff.mpr (Packed.evenCheck_sound h ⟨u, hu⟩)

end ECC
