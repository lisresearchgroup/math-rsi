import ECC.Packed

set_option maxRecDepth 4096
set_option maxHeartbeats 8000000

namespace ECC.Packed

def seed43 : List Nat := [137539745726, 5740911900901, 3801465813127, 7302904556701, 3853442440940, 2103915382859, 5144838248083, 7496890689917, 7842576845701, 8787570300677]

theorem seed43_verified :
    seed43.length = 10 ∧
    allRowsFit 43 seed43 = true ∧
    distanceCheck 43 10 16 seed43 = true ∧
    weight 43 (encode seed43 6) = 16 := by
  decide +kernel

end ECC.Packed
