import ECC.Packed

set_option maxRecDepth 4096
set_option maxHeartbeats 8000000

namespace ECC.Packed

def lower44_10 : List Nat := [2860005872641, 5720011745283, 11440023490566, 3732392958991, 673493634067, 1809555608628, 204550108262, 408026474701, 57712634350, 114351526877]

theorem lower44_10_verified : lower44_10.length = 10 ∧
    allRowsFit 44 lower44_10 = true ∧ distanceCheck 44 10 17 lower44_10 = true := by
  decide +kernel

def lower44_11 : List Nat := [5178737328131, 10357474656262, 1218204696603, 2435335684150, 944061251695, 515129213098, 225190019387, 134966837980, 47094858883, 898731865, 514986475]

theorem lower44_11_verified : lower44_11.length = 11 ∧
    allRowsFit 44 lower44_11 = true ∧ distanceCheck 44 11 16 lower44_11 = true := by
  decide +kernel

end ECC.Packed
