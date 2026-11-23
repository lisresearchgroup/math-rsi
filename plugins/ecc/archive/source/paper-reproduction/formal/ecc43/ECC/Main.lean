import ECC.Reduction
import ECC.ExtensionPermutation

namespace ECC

/-- The original development interface: every hypothetical even target is carried by
the E1/Griesmer/dual-weight-four/shortening/classification/coordinate-equivalence
argument to one of these actual standard extensions. -/
def CatalogueReduction : Prop :=
  ∀ T : Submodule F2 (Word 44),
    Module.finrank F2 T = 10 → MinWeight T 18 → EvenCode T →
    ∃ rows ∈ Packed.catalogueRows, ∃ a b c : Word 40,
      EvenCode (StandardExtension (matrixCode 40 rows) a b c) ∧
      MinWeight (StandardExtension (matrixCode 40 rows) a b c) 18

/-- External exhaustive-computation input: all 172 actual mother codes satisfy the universal
no-edge statement. Accepted-point checks alone do not establish this. -/
def CatalogueExclusions : Prop :=
  ∀ rows ∈ Packed.catalogueRows, PairIncompatible (matrixCode 40 rows)

/-- The formerly missing development interface is now proved. Only E1, E2 and
the external finite catalogue-inequivalence result are used; no exhaustive
extension rejection is needed to establish this mathematical reduction. -/
theorem catalogueReduction_of_published_results
    (hE1 : PublishedNonexistence41)
    (hE2 : PublishedClassBound)
    (hDistinct : CatalogueInequivalent) : CatalogueReduction := by
  intro T hdim hmin heven
  obtain ⟨K, a, b, c, hK, hsEven, hsMin⟩ :=
    target_to_standard_mother hE1 T hdim hmin heven
  obtain ⟨i, e, he⟩ := catalogue_covers_of_class_bound hE2 hDistinct K hK
  refine ⟨catalogueAt i, catalogueAt_mem i,
    permuteWord e a, permuteWord e b, permuteWord e c, ?_, ?_⟩
  · have h := standardExtension_permute_even e K a b c hsEven
    rw [he] at h
    exact h
  · have h := standardExtension_permute_minWeight e K a b c hsMin
    rw [he] at h
    exact h

/-- General assembly interface retained for comparison with the initial project.
The completed reduction is now implemented in `ECC.Reduction`; the final
`mainClaim_of_external_results` no longer takes this reduction as a premise. -/
theorem mainClaim_of_reduction_and_exclusions
    (hReduction : CatalogueReduction) (hExclusions : CatalogueExclusions) :
    MainClaim := by
  intro h
  obtain ⟨T, hdim, hmin, heven⟩ := code431017_to_even441018 h
  obtain ⟨rows, hr, a, b, c, he, hm⟩ := hReduction T hdim hmin heven
  exact no_standardExtension_of_pairIncompatible
    (matrixCode 40 rows) (hExclusions rows hr) a b c he hm

theorem optimal431016_of_mainClaim (h : MainClaim) : OptimalDistance 43 10 16 :=
  ⟨code431016, h⟩

/-- The exact optimum follows from the actual lower-bound matrix and the proved
global implication from the four original external mathematical/computational facts. -/
theorem optimal431016_of_external_results
    (hE1 : PublishedNonexistence41)
    (hE2 : PublishedClassBound)
    (hDistinct : CatalogueInequivalent)
    (hComputed : ∀ i : Fin 172, PairIncompatible (catalogueCode i)) :
    OptimalDistance 43 10 16 :=
  ⟨code431016, mainClaim_of_external_results hE1 hE2 hDistinct hComputed⟩

/-- An expanded boundary for the same external scan evidence: valid concrete
normalizers, exhaustive accepted/rejected representatives, and actual saved
pair witnesses. Lean proves their implication to universal incompatibility
and then to the original nonexistence claim. The evidence is an explicit input;
this theorem does not claim the historical scanner has been run in Lean. -/
theorem mainClaim_of_scan_facts
    (hE1 : PublishedNonexistence41)
    (hE2 : PublishedClassBound)
    (hDistinct : CatalogueInequivalent)
    (F : Fin 172 → Finset (Word 40))
    (projection : ∀ i : Fin 172, Word 40 →ₗ[F2] catalogueCode i)
    (hRetract : ∀ (i : Fin 172) (k : catalogueCode i), projection i k.val = k)
    (hCoverage : ∀ (i : Fin 172) (a : Word 40),
      projection i a = 0 → Even (weight a) →
      a ∈ F i ∨ ∃ k ∈ catalogueCode i, weight (a + k) < 16)
    (hPairs : ∀ i : Fin 172, SavedPairWitnesses (catalogueCode i) (F i)) : MainClaim := by
  apply mainClaim_of_external_results hE1 hE2 hDistinct
  intro i
  apply pairIncompatible_of_projection_certificates (catalogueCode i)
    (catalogueCode_parameters i).2.2.1 (F i) (projection i) (hRetract i)
  · exact complete_of_rejection_witnesses (catalogueCode i) (F i)
      (fun a => projection i a = 0) (hCoverage i)
  · exact hPairs i

end ECC
