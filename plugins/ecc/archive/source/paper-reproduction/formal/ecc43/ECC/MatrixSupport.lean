import ECC.MatrixBridge

namespace ECC

/-- Every coordinate is nonzero on at least one codeword. -/
def FullSupport {n : ℕ} (C : Submodule F2 (Word n)) : Prop :=
  ∀ i : Fin n, ∃ x ∈ C, x i ≠ 0

/-- A lower distance bound together with an attained nonzero word of that weight. -/
def ExactMinWeight {n : ℕ} (C : Submodule F2 (Word n)) (d : ℕ) : Prop :=
  MinWeight C d ∧ ∃ x ∈ C, x ≠ 0 ∧ weight x = d

theorem linearEncode_single (n : ℕ) (rows : List ℕ) (j : Fin rows.length) :
    linearEncode n rows (Pi.single j 1) = decodeWord n (rows.getD j.val 0) := by
  classical
  simp [linearEncode, Pi.single_apply, ite_smul]

theorem decodeWord_mem_range_of_mem {n : ℕ} {rows : List ℕ} {r : ℕ}
    (hr : r ∈ rows) : decodeWord n r ∈ LinearMap.range (linearEncode n rows) := by
  obtain ⟨j, hj⟩ := List.mem_iff_get.mp hr
  refine ⟨Pi.single j 1, ?_⟩
  rw [linearEncode_single]
  congr 1
  simpa [List.getD_eq_getElem?_getD] using hj

/-- A checked nonzero entry in each matrix column is realized by a row codeword.
The full-support property is derived from the Boolean check, not assumed. -/
theorem fullSupport_of_fullSupportCheck {n : ℕ} {rows : List ℕ}
    (h : Packed.fullSupportCheck n rows = true) :
    FullSupport (LinearMap.range (linearEncode n rows)) := by
  intro i
  have hi := List.all_eq_true.mp h i.val (List.mem_range.mpr i.isLt)
  obtain ⟨r, hr, hbit⟩ := List.any_eq_true.mp hi
  refine ⟨decodeWord n r, decodeWord_mem_range_of_mem hr, ?_⟩
  simp [decodeWord, hbit]

/-- The checked message bound gives a lower distance bound on this very matrix's
range, without changing the mathematical code to an existential witness. -/
theorem range_minWeight_of_distanceCheck {n d : ℕ} {rows : List ℕ}
    (h : Packed.distanceCheck n rows.length d rows = true) :
    MinWeight (LinearMap.range (linearEncode n rows)) d := by
  rintro y ⟨x, rfl⟩ hy
  apply distanceCheck_implies_message_bound h x
  intro hx
  apply hy
  rw [hx, map_zero]

/-- A concrete packed message attaining the positive bound proves the exact
minimum distance of the decoded code. The message need not be separately
assumed nonzero: its positive output weight supplies nonzeroness. -/
theorem exactMinWeight_of_distanceCheck {n d : ℕ} {rows : List ℕ} {u : ℕ}
    (hd : 0 < d) (h : Packed.distanceCheck n rows.length d rows = true)
    (hw : Packed.weight n (Packed.encode rows u) = d) :
    ExactMinWeight (LinearMap.range (linearEncode n rows)) d := by
  refine ⟨range_minWeight_of_distanceCheck h, ?_⟩
  let x := linearEncode n rows (decodeWord rows.length u)
  have hxw : weight x = d := by
    dsimp [x]
    rw [linearEncode_decodeWord, weight_decodeWord, hw]
  refine ⟨x, ⟨decodeWord rows.length u, rfl⟩, ?_, hxw⟩
  intro hx
  rw [hx, weight_zero] at hxw
  omega

end ECC
