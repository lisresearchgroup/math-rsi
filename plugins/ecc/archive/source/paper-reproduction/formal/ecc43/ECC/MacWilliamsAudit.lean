import ECC.MacWilliams

-- An independent import checks the actual exported theorem at its caller type.
example (C : Submodule ECC.F2 (ECC.Word 44))
    (hdim : Module.finrank ECC.F2 C = 10)
    (hmin : ECC.MinWeight C 18) (heven : ECC.EvenCode C)
    (hdualmin : ECC.MinWeight (ECC.dualCode C) 4) :
    ∃ y ∈ ECC.dualCode C, ECC.weight y = 4 :=
  ECC.exists_dual_weight_four C hdim hmin heven hdualmin

#check ECC.exists_dual_weight_four
#print axioms ECC.exists_dual_weight_four
#print axioms ECC.code_character_sum
#print axioms ECC.characterShell_eq_polynomial
