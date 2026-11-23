import ECC.Main

-- Actual bodies, not the prose intention.
#print ECC.Word
#print ECC.weight
#print ECC.MinWeight
#print ECC.CodeExists
#print ECC.MainClaim
#print ECC.ExactMinWeight
#print ECC.FullSupport
#print ECC.CatalogueReduction
#print ECC.CatalogueExclusions
#print ECC.PublishedNonexistence41
#print ECC.PublishedClassBound
#print ECC.CatalogueInequivalent
#print ECC.MotherParameters
#print ECC.CoordinateEquivalent
#print ECC.PairIncompatible

-- Closed results connected to actual data.
#check ECC.code431016
#check ECC.seed43_exact_distance
#check ECC.Packed.catalogue_size
#check ECC.catalogue_member_parameters
#check ECC.code431017_iff_even441018

-- Historical interfaces followed by their now-completed concrete callers.
#check ECC.dualFour_lower_bound
#check ECC.no_standardExtension_of_projection_certificates
#check ECC.mainClaim_of_reduction_and_exclusions
#check ECC.exists_dual_weight_four
#check ECC.codeExists_griesmer
#check ECC.dual_minWeight_four_of_published
#check ECC.target_to_standard_mother
#check ECC.catalogueReduction_of_published_results
#check ECC.mainClaim_of_external_results
#check ECC.mainClaim_of_scan_facts
#check ECC.optimal431016_of_external_results

-- Transitive audit: a clean axiom list does not discharge theorem parameters.
#print axioms ECC.Packed.seed43_verified
#print axioms ECC.Packed.catalogue_all_distance
#print axioms ECC.Packed.catalogue_all_shape_even_support
#print axioms ECC.Packed.catalogue_all_attains_distance
#print axioms ECC.decodeWord_surjective
#print axioms ECC.linearEncode_decodeWord
#print axioms ECC.code431016
#print axioms ECC.seed43_exact_distance
#print axioms ECC.catalogue_member_parameters
#print axioms ECC.code431017_iff_even441018
#print axioms ECC.dualFour_lower_bound
#print axioms ECC.no_standardExtension_of_projection_certificates
#print axioms ECC.mainClaim_of_reduction_and_exclusions
#print axioms ECC.exists_dual_weight_four
#print axioms ECC.codeExists_griesmer
#print axioms ECC.dual_minWeight_four_of_published
#print axioms ECC.target_to_standard_mother
#print axioms ECC.catalogue_covers_of_class_bound
#print axioms ECC.catalogueReduction_of_published_results
#print axioms ECC.mainClaim_of_external_results
#print axioms ECC.mainClaim_of_scan_facts
#print axioms ECC.optimal431016_of_external_results
