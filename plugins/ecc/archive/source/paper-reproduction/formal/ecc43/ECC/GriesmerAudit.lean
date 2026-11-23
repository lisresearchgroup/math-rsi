import ECC.Griesmer

#check ECC.codeExists_griesmer
#check ECC.no_code_41_8_19
#check ECC.no_code_40_7_20
#check ECC.exists_weight18_of_41_8_min18
#check ECC.exists_weight18_of_even_40_7_min18
#print axioms ECC.Griesmer.residualMap_ker
#print axioms ECC.Griesmer.residualMap_min
#print axioms ECC.Griesmer.bound_le_length
#print axioms ECC.codeExists_griesmer
#print axioms ECC.no_code_41_8_19
#print axioms ECC.no_code_40_7_20
#print axioms ECC.exists_weight18_of_41_8_min18
#print axioms ECC.exists_weight18_of_even_40_7_min18

example : ECC.Griesmer.bound 8 19 = 42 := by decide
example : ECC.Griesmer.bound 7 20 = 42 := by decide
