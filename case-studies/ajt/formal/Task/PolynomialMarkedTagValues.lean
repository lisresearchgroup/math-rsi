import Task.PolynomialMarkedData

/-! Checked orbit properties of the marked-coordinate tags. -/

open Finset Matrix
open scoped BigOperators

namespace AlonJaegerTarsi.MarkedEleven

set_option Elab.async false
set_option maxRecDepth 100000
set_option maxHeartbeats 0

def decode (i : ℕ) : Tuple :=
  ![(i / 625 : ℕ), (i / 125 : ℕ), (i / 25 : ℕ), (i / 5 : ℕ), (i : ℕ)]

theorem encode_lt (t : Tuple) : encode t < 3125 := by
  have h0 := (t 0).val_lt
  have h1 := (t 1).val_lt
  have h2 := (t 2).val_lt
  have h3 := (t 3).val_lt
  have h4 := (t 4).val_lt
  unfold encode
  omega

theorem decode_encode (t : Tuple) : decode (encode t) = t := by
  have h0 := (t 0).val_lt
  have h1 := (t 1).val_lt
  have h2 := (t 2).val_lt
  have h3 := (t 3).val_lt
  have h4 := (t 4).val_lt
  funext i
  apply ZMod.val_injective 5
  fin_cases i
  · change ((encode t / 625 : ℕ) : ZMod 5).val = (t 0).val
    rw [ZMod.val_natCast]; unfold encode; omega
  · change ((encode t / 125 : ℕ) : ZMod 5).val = (t 1).val
    rw [ZMod.val_natCast]; unfold encode; omega
  · change ((encode t / 25 : ℕ) : ZMod 5).val = (t 2).val
    rw [ZMod.val_natCast]; unfold encode; omega
  · change ((encode t / 5 : ℕ) : ZMod 5).val = (t 3).val
    rw [ZMod.val_natCast]; unfold encode; omega
  · change ((encode t : ℕ) : ZMod 5).val = (t 4).val
    rw [ZMod.val_natCast]; unfold encode; omega

/-- A separate bounded check on each block of 25 base-five codes proves the tuple assertion. -/
def Block25 (P : Tuple → Prop) (q : ℕ) : Prop := ∀ i : Fin 25, P (decode (q*25+i.val))

def block25Dec (P : Tuple → Prop) (d : ∀ t, Decidable (P t)) (q : ℕ) : Decidable (Block25 P q) :=
  @Nat.decidableForallFin 25 (fun i => P (decode (q*25+i.val))) (fun _ => d _)

theorem block25Check (P : Tuple → Prop) (d : ∀ t, Decidable (P t)) (q : ℕ)
    (h : @decide _ (block25Dec P d q) = true) : Block25 P q :=
  @of_decide_eq_true _ (block25Dec P d q) h

theorem tuple_blocks (P : Tuple → Prop) (h : ∀ q : Fin 125, Block25 P q.val) : ∀ t, P t := by
  intro t
  let q : Fin 125 := ⟨encode t / 25, by have := encode_lt t; omega⟩
  let i : Fin 25 := ⟨encode t % 25, Nat.mod_lt _ (by decide)⟩
  have he := h q i
  have hh : q.val * 25 + i.val = encode t := by dsimp [q,i]; omega
  simpa only [hh, decode_encode] using he

def shiftWeights (t : Tuple) : Multiset (Fin 4 × Fin 3) :=
  (univ : Finset (ZMod 5)).val.map (fun a => (leftWt (shifted t a), rightWt (shifted t a)))

private def stats (t : Tuple) : Prop :=
  (((∑ i, t i) = 0) → pwL (pTag t) = leftWt t ∧ pwR (pTag t) = rightWt t ∧
    (pTag t = 0 ↔ ∀ i, t i = 0)) ∧
  (vTag t = 0 ↔ ∀ i, t i = t 0) ∧
  (∀ a : ZMod 5, vTag (shifted t a) = vTag t) ∧
  (∀ s : ZMod 5, s ≠ 0 → vTag (fun i => s * t i) = vTag t) ∧
  shiftWeights t = shiftWeights (vRep (vTag t))

private def statsDec (t : Tuple) : Decidable (stats t) := by
  unfold stats
  infer_instance

private theorem stats0 : Block25 stats 0 := block25Check stats statsDec 0 (by decide)
private theorem stats1 : Block25 stats 1 := block25Check stats statsDec 1 (by decide)
private theorem stats2 : Block25 stats 2 := block25Check stats statsDec 2 (by decide)
private theorem stats3 : Block25 stats 3 := block25Check stats statsDec 3 (by decide)
private theorem stats4 : Block25 stats 4 := block25Check stats statsDec 4 (by decide)
private theorem stats5 : Block25 stats 5 := block25Check stats statsDec 5 (by decide)
private theorem stats6 : Block25 stats 6 := block25Check stats statsDec 6 (by decide)
private theorem stats7 : Block25 stats 7 := block25Check stats statsDec 7 (by decide)
private theorem stats8 : Block25 stats 8 := block25Check stats statsDec 8 (by decide)
private theorem stats9 : Block25 stats 9 := block25Check stats statsDec 9 (by decide)
private theorem stats10 : Block25 stats 10 := block25Check stats statsDec 10 (by decide)
private theorem stats11 : Block25 stats 11 := block25Check stats statsDec 11 (by decide)
private theorem stats12 : Block25 stats 12 := block25Check stats statsDec 12 (by decide)
private theorem stats13 : Block25 stats 13 := block25Check stats statsDec 13 (by decide)
private theorem stats14 : Block25 stats 14 := block25Check stats statsDec 14 (by decide)
private theorem stats15 : Block25 stats 15 := block25Check stats statsDec 15 (by decide)
private theorem stats16 : Block25 stats 16 := block25Check stats statsDec 16 (by decide)
private theorem stats17 : Block25 stats 17 := block25Check stats statsDec 17 (by decide)
private theorem stats18 : Block25 stats 18 := block25Check stats statsDec 18 (by decide)
private theorem stats19 : Block25 stats 19 := block25Check stats statsDec 19 (by decide)
private theorem stats20 : Block25 stats 20 := block25Check stats statsDec 20 (by decide)
private theorem stats21 : Block25 stats 21 := block25Check stats statsDec 21 (by decide)
private theorem stats22 : Block25 stats 22 := block25Check stats statsDec 22 (by decide)
private theorem stats23 : Block25 stats 23 := block25Check stats statsDec 23 (by decide)
private theorem stats24 : Block25 stats 24 := block25Check stats statsDec 24 (by decide)
private theorem stats25 : Block25 stats 25 := block25Check stats statsDec 25 (by decide)
private theorem stats26 : Block25 stats 26 := block25Check stats statsDec 26 (by decide)
private theorem stats27 : Block25 stats 27 := block25Check stats statsDec 27 (by decide)
private theorem stats28 : Block25 stats 28 := block25Check stats statsDec 28 (by decide)
private theorem stats29 : Block25 stats 29 := block25Check stats statsDec 29 (by decide)
private theorem stats30 : Block25 stats 30 := block25Check stats statsDec 30 (by decide)
private theorem stats31 : Block25 stats 31 := block25Check stats statsDec 31 (by decide)
private theorem stats32 : Block25 stats 32 := block25Check stats statsDec 32 (by decide)
private theorem stats33 : Block25 stats 33 := block25Check stats statsDec 33 (by decide)
private theorem stats34 : Block25 stats 34 := block25Check stats statsDec 34 (by decide)
private theorem stats35 : Block25 stats 35 := block25Check stats statsDec 35 (by decide)
private theorem stats36 : Block25 stats 36 := block25Check stats statsDec 36 (by decide)
private theorem stats37 : Block25 stats 37 := block25Check stats statsDec 37 (by decide)
private theorem stats38 : Block25 stats 38 := block25Check stats statsDec 38 (by decide)
private theorem stats39 : Block25 stats 39 := block25Check stats statsDec 39 (by decide)
private theorem stats40 : Block25 stats 40 := block25Check stats statsDec 40 (by decide)
private theorem stats41 : Block25 stats 41 := block25Check stats statsDec 41 (by decide)
private theorem stats42 : Block25 stats 42 := block25Check stats statsDec 42 (by decide)
private theorem stats43 : Block25 stats 43 := block25Check stats statsDec 43 (by decide)
private theorem stats44 : Block25 stats 44 := block25Check stats statsDec 44 (by decide)
private theorem stats45 : Block25 stats 45 := block25Check stats statsDec 45 (by decide)
private theorem stats46 : Block25 stats 46 := block25Check stats statsDec 46 (by decide)
private theorem stats47 : Block25 stats 47 := block25Check stats statsDec 47 (by decide)
private theorem stats48 : Block25 stats 48 := block25Check stats statsDec 48 (by decide)
private theorem stats49 : Block25 stats 49 := block25Check stats statsDec 49 (by decide)
private theorem stats50 : Block25 stats 50 := block25Check stats statsDec 50 (by decide)
private theorem stats51 : Block25 stats 51 := block25Check stats statsDec 51 (by decide)
private theorem stats52 : Block25 stats 52 := block25Check stats statsDec 52 (by decide)
private theorem stats53 : Block25 stats 53 := block25Check stats statsDec 53 (by decide)
private theorem stats54 : Block25 stats 54 := block25Check stats statsDec 54 (by decide)
private theorem stats55 : Block25 stats 55 := block25Check stats statsDec 55 (by decide)
private theorem stats56 : Block25 stats 56 := block25Check stats statsDec 56 (by decide)
private theorem stats57 : Block25 stats 57 := block25Check stats statsDec 57 (by decide)
private theorem stats58 : Block25 stats 58 := block25Check stats statsDec 58 (by decide)
private theorem stats59 : Block25 stats 59 := block25Check stats statsDec 59 (by decide)
private theorem stats60 : Block25 stats 60 := block25Check stats statsDec 60 (by decide)
private theorem stats61 : Block25 stats 61 := block25Check stats statsDec 61 (by decide)
private theorem stats62 : Block25 stats 62 := block25Check stats statsDec 62 (by decide)
private theorem stats63 : Block25 stats 63 := block25Check stats statsDec 63 (by decide)
private theorem stats64 : Block25 stats 64 := block25Check stats statsDec 64 (by decide)
private theorem stats65 : Block25 stats 65 := block25Check stats statsDec 65 (by decide)
private theorem stats66 : Block25 stats 66 := block25Check stats statsDec 66 (by decide)
private theorem stats67 : Block25 stats 67 := block25Check stats statsDec 67 (by decide)
private theorem stats68 : Block25 stats 68 := block25Check stats statsDec 68 (by decide)
private theorem stats69 : Block25 stats 69 := block25Check stats statsDec 69 (by decide)
private theorem stats70 : Block25 stats 70 := block25Check stats statsDec 70 (by decide)
private theorem stats71 : Block25 stats 71 := block25Check stats statsDec 71 (by decide)
private theorem stats72 : Block25 stats 72 := block25Check stats statsDec 72 (by decide)
private theorem stats73 : Block25 stats 73 := block25Check stats statsDec 73 (by decide)
private theorem stats74 : Block25 stats 74 := block25Check stats statsDec 74 (by decide)
private theorem stats75 : Block25 stats 75 := block25Check stats statsDec 75 (by decide)
private theorem stats76 : Block25 stats 76 := block25Check stats statsDec 76 (by decide)
private theorem stats77 : Block25 stats 77 := block25Check stats statsDec 77 (by decide)
private theorem stats78 : Block25 stats 78 := block25Check stats statsDec 78 (by decide)
private theorem stats79 : Block25 stats 79 := block25Check stats statsDec 79 (by decide)
private theorem stats80 : Block25 stats 80 := block25Check stats statsDec 80 (by decide)
private theorem stats81 : Block25 stats 81 := block25Check stats statsDec 81 (by decide)
private theorem stats82 : Block25 stats 82 := block25Check stats statsDec 82 (by decide)
private theorem stats83 : Block25 stats 83 := block25Check stats statsDec 83 (by decide)
private theorem stats84 : Block25 stats 84 := block25Check stats statsDec 84 (by decide)
private theorem stats85 : Block25 stats 85 := block25Check stats statsDec 85 (by decide)
private theorem stats86 : Block25 stats 86 := block25Check stats statsDec 86 (by decide)
private theorem stats87 : Block25 stats 87 := block25Check stats statsDec 87 (by decide)
private theorem stats88 : Block25 stats 88 := block25Check stats statsDec 88 (by decide)
private theorem stats89 : Block25 stats 89 := block25Check stats statsDec 89 (by decide)
private theorem stats90 : Block25 stats 90 := block25Check stats statsDec 90 (by decide)
private theorem stats91 : Block25 stats 91 := block25Check stats statsDec 91 (by decide)
private theorem stats92 : Block25 stats 92 := block25Check stats statsDec 92 (by decide)
private theorem stats93 : Block25 stats 93 := block25Check stats statsDec 93 (by decide)
private theorem stats94 : Block25 stats 94 := block25Check stats statsDec 94 (by decide)
private theorem stats95 : Block25 stats 95 := block25Check stats statsDec 95 (by decide)
private theorem stats96 : Block25 stats 96 := block25Check stats statsDec 96 (by decide)
private theorem stats97 : Block25 stats 97 := block25Check stats statsDec 97 (by decide)
private theorem stats98 : Block25 stats 98 := block25Check stats statsDec 98 (by decide)
private theorem stats99 : Block25 stats 99 := block25Check stats statsDec 99 (by decide)
private theorem stats100 : Block25 stats 100 := block25Check stats statsDec 100 (by decide)
private theorem stats101 : Block25 stats 101 := block25Check stats statsDec 101 (by decide)
private theorem stats102 : Block25 stats 102 := block25Check stats statsDec 102 (by decide)
private theorem stats103 : Block25 stats 103 := block25Check stats statsDec 103 (by decide)
private theorem stats104 : Block25 stats 104 := block25Check stats statsDec 104 (by decide)
private theorem stats105 : Block25 stats 105 := block25Check stats statsDec 105 (by decide)
private theorem stats106 : Block25 stats 106 := block25Check stats statsDec 106 (by decide)
private theorem stats107 : Block25 stats 107 := block25Check stats statsDec 107 (by decide)
private theorem stats108 : Block25 stats 108 := block25Check stats statsDec 108 (by decide)
private theorem stats109 : Block25 stats 109 := block25Check stats statsDec 109 (by decide)
private theorem stats110 : Block25 stats 110 := block25Check stats statsDec 110 (by decide)
private theorem stats111 : Block25 stats 111 := block25Check stats statsDec 111 (by decide)
private theorem stats112 : Block25 stats 112 := block25Check stats statsDec 112 (by decide)
private theorem stats113 : Block25 stats 113 := block25Check stats statsDec 113 (by decide)
private theorem stats114 : Block25 stats 114 := block25Check stats statsDec 114 (by decide)
private theorem stats115 : Block25 stats 115 := block25Check stats statsDec 115 (by decide)
private theorem stats116 : Block25 stats 116 := block25Check stats statsDec 116 (by decide)
private theorem stats117 : Block25 stats 117 := block25Check stats statsDec 117 (by decide)
private theorem stats118 : Block25 stats 118 := block25Check stats statsDec 118 (by decide)
private theorem stats119 : Block25 stats 119 := block25Check stats statsDec 119 (by decide)
private theorem stats120 : Block25 stats 120 := block25Check stats statsDec 120 (by decide)
private theorem stats121 : Block25 stats 121 := block25Check stats statsDec 121 (by decide)
private theorem stats122 : Block25 stats 122 := block25Check stats statsDec 122 (by decide)
private theorem stats123 : Block25 stats 123 := block25Check stats statsDec 123 (by decide)
private theorem stats124 : Block25 stats 124 := block25Check stats statsDec 124 (by decide)

private theorem allStats : ∀ t, stats t := by
  apply tuple_blocks
  intro q
  fin_cases q
  · exact stats0
  · exact stats1
  · exact stats2
  · exact stats3
  · exact stats4
  · exact stats5
  · exact stats6
  · exact stats7
  · exact stats8
  · exact stats9
  · exact stats10
  · exact stats11
  · exact stats12
  · exact stats13
  · exact stats14
  · exact stats15
  · exact stats16
  · exact stats17
  · exact stats18
  · exact stats19
  · exact stats20
  · exact stats21
  · exact stats22
  · exact stats23
  · exact stats24
  · exact stats25
  · exact stats26
  · exact stats27
  · exact stats28
  · exact stats29
  · exact stats30
  · exact stats31
  · exact stats32
  · exact stats33
  · exact stats34
  · exact stats35
  · exact stats36
  · exact stats37
  · exact stats38
  · exact stats39
  · exact stats40
  · exact stats41
  · exact stats42
  · exact stats43
  · exact stats44
  · exact stats45
  · exact stats46
  · exact stats47
  · exact stats48
  · exact stats49
  · exact stats50
  · exact stats51
  · exact stats52
  · exact stats53
  · exact stats54
  · exact stats55
  · exact stats56
  · exact stats57
  · exact stats58
  · exact stats59
  · exact stats60
  · exact stats61
  · exact stats62
  · exact stats63
  · exact stats64
  · exact stats65
  · exact stats66
  · exact stats67
  · exact stats68
  · exact stats69
  · exact stats70
  · exact stats71
  · exact stats72
  · exact stats73
  · exact stats74
  · exact stats75
  · exact stats76
  · exact stats77
  · exact stats78
  · exact stats79
  · exact stats80
  · exact stats81
  · exact stats82
  · exact stats83
  · exact stats84
  · exact stats85
  · exact stats86
  · exact stats87
  · exact stats88
  · exact stats89
  · exact stats90
  · exact stats91
  · exact stats92
  · exact stats93
  · exact stats94
  · exact stats95
  · exact stats96
  · exact stats97
  · exact stats98
  · exact stats99
  · exact stats100
  · exact stats101
  · exact stats102
  · exact stats103
  · exact stats104
  · exact stats105
  · exact stats106
  · exact stats107
  · exact stats108
  · exact stats109
  · exact stats110
  · exact stats111
  · exact stats112
  · exact stats113
  · exact stats114
  · exact stats115
  · exact stats116
  · exact stats117
  · exact stats118
  · exact stats119
  · exact stats120
  · exact stats121
  · exact stats122
  · exact stats123
  · exact stats124

theorem pTag_left (t : Tuple) (h : ∑ i, t i = 0) : pwL (pTag t) = leftWt t :=
  ((allStats t).1 h).1

theorem pTag_right (t : Tuple) (h : ∑ i, t i = 0) : pwR (pTag t) = rightWt t :=
  ((allStats t).1 h).2.1

theorem pTag_zero_iff (t : Tuple) (h : ∑ i, t i = 0) : pTag t = 0 ↔ t = 0 := by
  rw [((allStats t).1 h).2.2]
  exact ⟨fun h => funext h, fun h i => congrFun h i⟩

@[simp] theorem leftWt_zero : leftWt 0 = 0 := by decide
@[simp] theorem rightWt_zero : rightWt 0 = 0 := by decide
@[simp] theorem pTag_zero : pTag 0 = 0 := by decide
@[simp] theorem vTag_zero : vTag 0 = 0 := by decide

theorem vTag_zero_iff (t : Tuple) : vTag t = 0 ↔ ∀ i, t i = t 0 := (allStats t).2.1

theorem vTag_shifted (t : Tuple) (a : ZMod 5) : vTag (shifted t a) = vTag t := (allStats t).2.2.1 a

theorem vTag_scale (t : Tuple) (s : ZMod 5) (h : s ≠ 0) : vTag (fun i => s * t i) = vTag t :=
  (allStats t).2.2.2.1 s h

theorem vTag_weight_pairs (t : Tuple) : shiftWeights t = shiftWeights (vRep (vTag t)) :=
  (allStats t).2.2.2.2


end AlonJaegerTarsi.MarkedEleven
