import Std

namespace ECC.Packed

/-- Least-significant bit is coordinate zero. The list order is message-bit order. -/
def encode : List Nat → Nat → Nat
  | [], _ => 0
  | r :: rs, u => (if u % 2 = 1 then r else 0) ^^^ encode rs (u / 2)

/-- Hamming weight of the first n bits, expressed using natural-number arithmetic. -/
def weight : Nat → Nat → Nat
  | 0, _ => 0
  | n + 1, x => x % 2 + weight n (x / 2)

def allRowsFit (n : Nat) (rows : List Nat) : Bool :=
  rows.all (fun r => r < 2 ^ n)

def distanceCheck (n k d : Nat) (rows : List Nat) : Bool :=
  (List.range (2 ^ k)).all (fun u => u == 0 || decide (d ≤ weight n (encode rows u)))

def evenCheck (n k : Nat) (rows : List Nat) : Bool :=
  (List.range (2 ^ k)).all (fun u => weight n (encode rows u) % 2 == 0)

def fullSupportCheck (n : Nat) (rows : List Nat) : Bool :=
  (List.range n).all (fun j => rows.any (fun r => r.testBit j))

theorem distanceCheck_sound {n k d : Nat} {rows : List Nat}
    (h : distanceCheck n k d rows = true) :
    ∀ u : Fin (2 ^ k), u.val ≠ 0 → d ≤ weight n (encode rows u.val) := by
  intro u hu
  have hi := List.all_eq_true.mp h u.val (List.mem_range.mpr u.isLt)
  simp only [Bool.or_eq_true, beq_iff_eq, decide_eq_true_eq] at hi
  exact hi.resolve_left hu

theorem evenCheck_sound {n k : Nat} {rows : List Nat}
    (h : evenCheck n k rows = true) :
    ∀ u : Fin (2 ^ k), weight n (encode rows u.val) % 2 = 0 := by
  intro u
  have hi := List.all_eq_true.mp h u.val (List.mem_range.mpr u.isLt)
  exact beq_iff_eq.mp hi

end ECC.Packed
