import ECC.SupportPermutation
import ECC.NoSmallDual
import ECC.MacWilliams
import ECC.Shortening
import ECC.Classification

namespace ECC

/-- E1 plus the proved Griesmer bound exclude every small dual word, regardless
of its support. The coordinate permutation is constructed from that support. -/
theorem dual_minWeight_four_of_published (hE1 : PublishedNonexistence41)
    (T : Submodule F2 (Word 44)) (hdim : Module.finrank F2 T = 10)
    (hmin : MinWeight T 18) : MinWeight (dualCode T) 4 := by
  intro y hy hne
  by_contra hlow
  have hw : weight y ≤ 3 := by omega
  obtain ⟨e, he⟩ := exists_permutation_supported_tail (n := 41) (m := 3) y hw
  have hz := no_nonzero_dual_supported_last3 hE1 (permuteCode e T)
    (by rwa [permuteCode_finrank]) (permuteCode_minWeight e T hmin)
    (permuteWord e y) (permuteWord_mem_dual e T hy) he
  apply hne
  have hi := congrArg (permuteWord e).symm hz
  simpa using hi

/-- The complete mathematical funnel from an arbitrary even target to a
full-support mother and its actual standard extension. E1 is the only external
premise at this stage; spectra, Griesmer, dual support, shortening and standard
form are all derived in Lean. -/
theorem target_to_standard_mother (hE1 : PublishedNonexistence41)
    (T : Submodule F2 (Word 44)) (hdim : Module.finrank F2 T = 10)
    (hmin : MinWeight T 18) (heven : EvenCode T) :
    ∃ K : Submodule F2 (Word 40), ∃ a b c : Word 40,
      MotherParameters K ∧ EvenCode (StandardExtension K a b c) ∧
      MinWeight (StandardExtension K a b c) 18 := by
  have hdual := dual_minWeight_four_of_published hE1 T hdim hmin
  obtain ⟨y, hy, hwy⟩ := exists_dual_weight_four T hdim hmin heven hdual
  obtain ⟨e, he0, he1⟩ := exists_permutation_exact_support (n := 40) (m := 4) y hwy
  let C := permuteCode e T
  have hcDim : Module.finrank F2 C = 10 := by
    dsimp [C]
    rwa [permuteCode_finrank]
  have hcMin : MinWeight C 18 := permuteCode_minWeight e T hmin
  have hcEven : EvenCode C := permuteCode_even e T heven
  have hcDual : MinWeight (dualCode C) 4 := permuteCode_dual_minWeight e T hdual
  have hcLast : LastFourEven C :=
    sum_tail_eq_zero_of_dual C (permuteWord_mem_dual e T hy) he0 he1
  obtain ⟨K, a, b, c, hkDim, hkMin, hkEven, hkFull, hsEven, hsMin⟩ :=
    shortened_standard_reduction C hcDim hcMin hcEven hcLast hcDual
  obtain ⟨x, hx, hw⟩ := exists_weight18_of_even_40_7_min18 K hkDim hkMin hkEven
  have hxn : x ≠ 0 := by
    intro hz
    rw [hz, weight_zero] at hw
    contradiction
  exact ⟨K, a, b, c, ⟨hkDim, ⟨hkMin, x, hx, hxn, hw⟩, hkEven, hkFull⟩,
    hsEven, hsMin⟩

/-- Global nonexistence from exactly the published and computational imports.
No target-to-catalogue reduction is an input: it is proved above. -/
theorem mainClaim_of_external_results
    (hE1 : PublishedNonexistence41)
    (hE2 : PublishedClassBound)
    (hDistinct : CatalogueInequivalent)
    (hComputed : ∀ i : Fin 172, PairIncompatible (catalogueCode i)) : MainClaim := by
  intro h
  obtain ⟨T, hdim, hmin, heven⟩ := code431017_to_even441018 h
  obtain ⟨K, a, b, c, hK, he, hm⟩ := target_to_standard_mother hE1 T hdim hmin heven
  have hPairs := all_mothers_incompatible hE2 hDistinct hComputed K hK
  exact no_standardExtension_of_pairIncompatible K hPairs a b c he hm

end ECC
