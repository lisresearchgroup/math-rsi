import ECC.CatalogueData

set_option maxRecDepth 16384
set_option maxHeartbeats 8000000

namespace ECC.Packed

def catalogueRows : List (List Nat) := [
  mother000,
  mother001,
  mother002,
  mother003,
  mother004,
  mother005,
  mother006,
  mother007,
  mother008,
  mother009,
  mother010,
  mother011,
  mother012,
  mother013,
  mother014,
  mother015,
  mother016,
  mother017,
  mother018,
  mother019,
  mother020,
  mother021,
  mother022,
  mother023,
  mother024,
  mother025,
  mother026,
  mother027,
  mother028,
  mother029,
  mother030,
  mother031,
  mother032,
  mother033,
  mother034,
  mother035,
  mother036,
  mother037,
  mother038,
  mother039,
  mother040,
  mother041,
  mother042,
  mother043,
  mother044,
  mother045,
  mother046,
  mother047,
  mother048,
  mother049,
  mother050,
  mother051,
  mother052,
  mother053,
  mother054,
  mother055,
  mother056,
  mother057,
  mother058,
  mother059,
  mother060,
  mother061,
  mother062,
  mother063,
  mother064,
  mother065,
  mother066,
  mother067,
  mother068,
  mother069,
  mother070,
  mother071,
  mother072,
  mother073,
  mother074,
  mother075,
  mother076,
  mother077,
  mother078,
  mother079,
  mother080,
  mother081,
  mother082,
  mother083,
  mother084,
  mother085,
  mother086,
  mother087,
  mother088,
  mother089,
  mother090,
  mother091,
  mother092,
  mother093,
  mother094,
  mother095,
  mother096,
  mother097,
  mother098,
  mother099,
  mother100,
  mother101,
  mother102,
  mother103,
  mother104,
  mother105,
  mother106,
  mother107,
  mother108,
  mother109,
  mother110,
  mother111,
  mother112,
  mother113,
  mother114,
  mother115,
  mother116,
  mother117,
  mother118,
  mother119,
  mother120,
  mother121,
  mother122,
  mother123,
  mother124,
  mother125,
  mother126,
  mother127,
  mother128,
  mother129,
  mother130,
  mother131,
  mother132,
  mother133,
  mother134,
  mother135,
  mother136,
  mother137,
  mother138,
  mother139,
  mother140,
  mother141,
  mother142,
  mother143,
  mother144,
  mother145,
  mother146,
  mother147,
  mother148,
  mother149,
  mother150,
  mother151,
  mother152,
  mother153,
  mother154,
  mother155,
  mother156,
  mother157,
  mother158,
  mother159,
  mother160,
  mother161,
  mother162,
  mother163,
  mother164,
  mother165,
  mother166,
  mother167,
  mother168,
  mother169,
  mother170,
  mother171
]

theorem catalogue_size : catalogueRows.length = 172 := by decide

theorem catalogue_all_distance :
    catalogueRows.all (fun rows => distanceCheck 40 7 18 rows) = true := by
  simp only [catalogueRows, List.all_cons, List.all_nil,
    mother000_verified.2.2.1,
    mother001_verified.2.2.1,
    mother002_verified.2.2.1,
    mother003_verified.2.2.1,
    mother004_verified.2.2.1,
    mother005_verified.2.2.1,
    mother006_verified.2.2.1,
    mother007_verified.2.2.1,
    mother008_verified.2.2.1,
    mother009_verified.2.2.1,
    mother010_verified.2.2.1,
    mother011_verified.2.2.1,
    mother012_verified.2.2.1,
    mother013_verified.2.2.1,
    mother014_verified.2.2.1,
    mother015_verified.2.2.1,
    mother016_verified.2.2.1,
    mother017_verified.2.2.1,
    mother018_verified.2.2.1,
    mother019_verified.2.2.1,
    mother020_verified.2.2.1,
    mother021_verified.2.2.1,
    mother022_verified.2.2.1,
    mother023_verified.2.2.1,
    mother024_verified.2.2.1,
    mother025_verified.2.2.1,
    mother026_verified.2.2.1,
    mother027_verified.2.2.1,
    mother028_verified.2.2.1,
    mother029_verified.2.2.1,
    mother030_verified.2.2.1,
    mother031_verified.2.2.1,
    mother032_verified.2.2.1,
    mother033_verified.2.2.1,
    mother034_verified.2.2.1,
    mother035_verified.2.2.1,
    mother036_verified.2.2.1,
    mother037_verified.2.2.1,
    mother038_verified.2.2.1,
    mother039_verified.2.2.1,
    mother040_verified.2.2.1,
    mother041_verified.2.2.1,
    mother042_verified.2.2.1,
    mother043_verified.2.2.1,
    mother044_verified.2.2.1,
    mother045_verified.2.2.1,
    mother046_verified.2.2.1,
    mother047_verified.2.2.1,
    mother048_verified.2.2.1,
    mother049_verified.2.2.1,
    mother050_verified.2.2.1,
    mother051_verified.2.2.1,
    mother052_verified.2.2.1,
    mother053_verified.2.2.1,
    mother054_verified.2.2.1,
    mother055_verified.2.2.1,
    mother056_verified.2.2.1,
    mother057_verified.2.2.1,
    mother058_verified.2.2.1,
    mother059_verified.2.2.1,
    mother060_verified.2.2.1,
    mother061_verified.2.2.1,
    mother062_verified.2.2.1,
    mother063_verified.2.2.1,
    mother064_verified.2.2.1,
    mother065_verified.2.2.1,
    mother066_verified.2.2.1,
    mother067_verified.2.2.1,
    mother068_verified.2.2.1,
    mother069_verified.2.2.1,
    mother070_verified.2.2.1,
    mother071_verified.2.2.1,
    mother072_verified.2.2.1,
    mother073_verified.2.2.1,
    mother074_verified.2.2.1,
    mother075_verified.2.2.1,
    mother076_verified.2.2.1,
    mother077_verified.2.2.1,
    mother078_verified.2.2.1,
    mother079_verified.2.2.1,
    mother080_verified.2.2.1,
    mother081_verified.2.2.1,
    mother082_verified.2.2.1,
    mother083_verified.2.2.1,
    mother084_verified.2.2.1,
    mother085_verified.2.2.1,
    mother086_verified.2.2.1,
    mother087_verified.2.2.1,
    mother088_verified.2.2.1,
    mother089_verified.2.2.1,
    mother090_verified.2.2.1,
    mother091_verified.2.2.1,
    mother092_verified.2.2.1,
    mother093_verified.2.2.1,
    mother094_verified.2.2.1,
    mother095_verified.2.2.1,
    mother096_verified.2.2.1,
    mother097_verified.2.2.1,
    mother098_verified.2.2.1,
    mother099_verified.2.2.1,
    mother100_verified.2.2.1,
    mother101_verified.2.2.1,
    mother102_verified.2.2.1,
    mother103_verified.2.2.1,
    mother104_verified.2.2.1,
    mother105_verified.2.2.1,
    mother106_verified.2.2.1,
    mother107_verified.2.2.1,
    mother108_verified.2.2.1,
    mother109_verified.2.2.1,
    mother110_verified.2.2.1,
    mother111_verified.2.2.1,
    mother112_verified.2.2.1,
    mother113_verified.2.2.1,
    mother114_verified.2.2.1,
    mother115_verified.2.2.1,
    mother116_verified.2.2.1,
    mother117_verified.2.2.1,
    mother118_verified.2.2.1,
    mother119_verified.2.2.1,
    mother120_verified.2.2.1,
    mother121_verified.2.2.1,
    mother122_verified.2.2.1,
    mother123_verified.2.2.1,
    mother124_verified.2.2.1,
    mother125_verified.2.2.1,
    mother126_verified.2.2.1,
    mother127_verified.2.2.1,
    mother128_verified.2.2.1,
    mother129_verified.2.2.1,
    mother130_verified.2.2.1,
    mother131_verified.2.2.1,
    mother132_verified.2.2.1,
    mother133_verified.2.2.1,
    mother134_verified.2.2.1,
    mother135_verified.2.2.1,
    mother136_verified.2.2.1,
    mother137_verified.2.2.1,
    mother138_verified.2.2.1,
    mother139_verified.2.2.1,
    mother140_verified.2.2.1,
    mother141_verified.2.2.1,
    mother142_verified.2.2.1,
    mother143_verified.2.2.1,
    mother144_verified.2.2.1,
    mother145_verified.2.2.1,
    mother146_verified.2.2.1,
    mother147_verified.2.2.1,
    mother148_verified.2.2.1,
    mother149_verified.2.2.1,
    mother150_verified.2.2.1,
    mother151_verified.2.2.1,
    mother152_verified.2.2.1,
    mother153_verified.2.2.1,
    mother154_verified.2.2.1,
    mother155_verified.2.2.1,
    mother156_verified.2.2.1,
    mother157_verified.2.2.1,
    mother158_verified.2.2.1,
    mother159_verified.2.2.1,
    mother160_verified.2.2.1,
    mother161_verified.2.2.1,
    mother162_verified.2.2.1,
    mother163_verified.2.2.1,
    mother164_verified.2.2.1,
    mother165_verified.2.2.1,
    mother166_verified.2.2.1,
    mother167_verified.2.2.1,
    mother168_verified.2.2.1,
    mother169_verified.2.2.1,
    mother170_verified.2.2.1,
    mother171_verified.2.2.1, Bool.true_and]

theorem catalogue_all_shape_even_support :
    catalogueRows.all (fun rows => rows.length == 7 && allRowsFit 40 rows &&
      evenCheck 40 7 rows && fullSupportCheck 40 rows) = true := by
  simp only [catalogueRows, List.all_cons, List.all_nil,
    mother000_verified.1, mother000_verified.2.1, mother000_verified.2.2.2.1, mother000_verified.2.2.2.2.1,
    mother001_verified.1, mother001_verified.2.1, mother001_verified.2.2.2.1, mother001_verified.2.2.2.2.1,
    mother002_verified.1, mother002_verified.2.1, mother002_verified.2.2.2.1, mother002_verified.2.2.2.2.1,
    mother003_verified.1, mother003_verified.2.1, mother003_verified.2.2.2.1, mother003_verified.2.2.2.2.1,
    mother004_verified.1, mother004_verified.2.1, mother004_verified.2.2.2.1, mother004_verified.2.2.2.2.1,
    mother005_verified.1, mother005_verified.2.1, mother005_verified.2.2.2.1, mother005_verified.2.2.2.2.1,
    mother006_verified.1, mother006_verified.2.1, mother006_verified.2.2.2.1, mother006_verified.2.2.2.2.1,
    mother007_verified.1, mother007_verified.2.1, mother007_verified.2.2.2.1, mother007_verified.2.2.2.2.1,
    mother008_verified.1, mother008_verified.2.1, mother008_verified.2.2.2.1, mother008_verified.2.2.2.2.1,
    mother009_verified.1, mother009_verified.2.1, mother009_verified.2.2.2.1, mother009_verified.2.2.2.2.1,
    mother010_verified.1, mother010_verified.2.1, mother010_verified.2.2.2.1, mother010_verified.2.2.2.2.1,
    mother011_verified.1, mother011_verified.2.1, mother011_verified.2.2.2.1, mother011_verified.2.2.2.2.1,
    mother012_verified.1, mother012_verified.2.1, mother012_verified.2.2.2.1, mother012_verified.2.2.2.2.1,
    mother013_verified.1, mother013_verified.2.1, mother013_verified.2.2.2.1, mother013_verified.2.2.2.2.1,
    mother014_verified.1, mother014_verified.2.1, mother014_verified.2.2.2.1, mother014_verified.2.2.2.2.1,
    mother015_verified.1, mother015_verified.2.1, mother015_verified.2.2.2.1, mother015_verified.2.2.2.2.1,
    mother016_verified.1, mother016_verified.2.1, mother016_verified.2.2.2.1, mother016_verified.2.2.2.2.1,
    mother017_verified.1, mother017_verified.2.1, mother017_verified.2.2.2.1, mother017_verified.2.2.2.2.1,
    mother018_verified.1, mother018_verified.2.1, mother018_verified.2.2.2.1, mother018_verified.2.2.2.2.1,
    mother019_verified.1, mother019_verified.2.1, mother019_verified.2.2.2.1, mother019_verified.2.2.2.2.1,
    mother020_verified.1, mother020_verified.2.1, mother020_verified.2.2.2.1, mother020_verified.2.2.2.2.1,
    mother021_verified.1, mother021_verified.2.1, mother021_verified.2.2.2.1, mother021_verified.2.2.2.2.1,
    mother022_verified.1, mother022_verified.2.1, mother022_verified.2.2.2.1, mother022_verified.2.2.2.2.1,
    mother023_verified.1, mother023_verified.2.1, mother023_verified.2.2.2.1, mother023_verified.2.2.2.2.1,
    mother024_verified.1, mother024_verified.2.1, mother024_verified.2.2.2.1, mother024_verified.2.2.2.2.1,
    mother025_verified.1, mother025_verified.2.1, mother025_verified.2.2.2.1, mother025_verified.2.2.2.2.1,
    mother026_verified.1, mother026_verified.2.1, mother026_verified.2.2.2.1, mother026_verified.2.2.2.2.1,
    mother027_verified.1, mother027_verified.2.1, mother027_verified.2.2.2.1, mother027_verified.2.2.2.2.1,
    mother028_verified.1, mother028_verified.2.1, mother028_verified.2.2.2.1, mother028_verified.2.2.2.2.1,
    mother029_verified.1, mother029_verified.2.1, mother029_verified.2.2.2.1, mother029_verified.2.2.2.2.1,
    mother030_verified.1, mother030_verified.2.1, mother030_verified.2.2.2.1, mother030_verified.2.2.2.2.1,
    mother031_verified.1, mother031_verified.2.1, mother031_verified.2.2.2.1, mother031_verified.2.2.2.2.1,
    mother032_verified.1, mother032_verified.2.1, mother032_verified.2.2.2.1, mother032_verified.2.2.2.2.1,
    mother033_verified.1, mother033_verified.2.1, mother033_verified.2.2.2.1, mother033_verified.2.2.2.2.1,
    mother034_verified.1, mother034_verified.2.1, mother034_verified.2.2.2.1, mother034_verified.2.2.2.2.1,
    mother035_verified.1, mother035_verified.2.1, mother035_verified.2.2.2.1, mother035_verified.2.2.2.2.1,
    mother036_verified.1, mother036_verified.2.1, mother036_verified.2.2.2.1, mother036_verified.2.2.2.2.1,
    mother037_verified.1, mother037_verified.2.1, mother037_verified.2.2.2.1, mother037_verified.2.2.2.2.1,
    mother038_verified.1, mother038_verified.2.1, mother038_verified.2.2.2.1, mother038_verified.2.2.2.2.1,
    mother039_verified.1, mother039_verified.2.1, mother039_verified.2.2.2.1, mother039_verified.2.2.2.2.1,
    mother040_verified.1, mother040_verified.2.1, mother040_verified.2.2.2.1, mother040_verified.2.2.2.2.1,
    mother041_verified.1, mother041_verified.2.1, mother041_verified.2.2.2.1, mother041_verified.2.2.2.2.1,
    mother042_verified.1, mother042_verified.2.1, mother042_verified.2.2.2.1, mother042_verified.2.2.2.2.1,
    mother043_verified.1, mother043_verified.2.1, mother043_verified.2.2.2.1, mother043_verified.2.2.2.2.1,
    mother044_verified.1, mother044_verified.2.1, mother044_verified.2.2.2.1, mother044_verified.2.2.2.2.1,
    mother045_verified.1, mother045_verified.2.1, mother045_verified.2.2.2.1, mother045_verified.2.2.2.2.1,
    mother046_verified.1, mother046_verified.2.1, mother046_verified.2.2.2.1, mother046_verified.2.2.2.2.1,
    mother047_verified.1, mother047_verified.2.1, mother047_verified.2.2.2.1, mother047_verified.2.2.2.2.1,
    mother048_verified.1, mother048_verified.2.1, mother048_verified.2.2.2.1, mother048_verified.2.2.2.2.1,
    mother049_verified.1, mother049_verified.2.1, mother049_verified.2.2.2.1, mother049_verified.2.2.2.2.1,
    mother050_verified.1, mother050_verified.2.1, mother050_verified.2.2.2.1, mother050_verified.2.2.2.2.1,
    mother051_verified.1, mother051_verified.2.1, mother051_verified.2.2.2.1, mother051_verified.2.2.2.2.1,
    mother052_verified.1, mother052_verified.2.1, mother052_verified.2.2.2.1, mother052_verified.2.2.2.2.1,
    mother053_verified.1, mother053_verified.2.1, mother053_verified.2.2.2.1, mother053_verified.2.2.2.2.1,
    mother054_verified.1, mother054_verified.2.1, mother054_verified.2.2.2.1, mother054_verified.2.2.2.2.1,
    mother055_verified.1, mother055_verified.2.1, mother055_verified.2.2.2.1, mother055_verified.2.2.2.2.1,
    mother056_verified.1, mother056_verified.2.1, mother056_verified.2.2.2.1, mother056_verified.2.2.2.2.1,
    mother057_verified.1, mother057_verified.2.1, mother057_verified.2.2.2.1, mother057_verified.2.2.2.2.1,
    mother058_verified.1, mother058_verified.2.1, mother058_verified.2.2.2.1, mother058_verified.2.2.2.2.1,
    mother059_verified.1, mother059_verified.2.1, mother059_verified.2.2.2.1, mother059_verified.2.2.2.2.1,
    mother060_verified.1, mother060_verified.2.1, mother060_verified.2.2.2.1, mother060_verified.2.2.2.2.1,
    mother061_verified.1, mother061_verified.2.1, mother061_verified.2.2.2.1, mother061_verified.2.2.2.2.1,
    mother062_verified.1, mother062_verified.2.1, mother062_verified.2.2.2.1, mother062_verified.2.2.2.2.1,
    mother063_verified.1, mother063_verified.2.1, mother063_verified.2.2.2.1, mother063_verified.2.2.2.2.1,
    mother064_verified.1, mother064_verified.2.1, mother064_verified.2.2.2.1, mother064_verified.2.2.2.2.1,
    mother065_verified.1, mother065_verified.2.1, mother065_verified.2.2.2.1, mother065_verified.2.2.2.2.1,
    mother066_verified.1, mother066_verified.2.1, mother066_verified.2.2.2.1, mother066_verified.2.2.2.2.1,
    mother067_verified.1, mother067_verified.2.1, mother067_verified.2.2.2.1, mother067_verified.2.2.2.2.1,
    mother068_verified.1, mother068_verified.2.1, mother068_verified.2.2.2.1, mother068_verified.2.2.2.2.1,
    mother069_verified.1, mother069_verified.2.1, mother069_verified.2.2.2.1, mother069_verified.2.2.2.2.1,
    mother070_verified.1, mother070_verified.2.1, mother070_verified.2.2.2.1, mother070_verified.2.2.2.2.1,
    mother071_verified.1, mother071_verified.2.1, mother071_verified.2.2.2.1, mother071_verified.2.2.2.2.1,
    mother072_verified.1, mother072_verified.2.1, mother072_verified.2.2.2.1, mother072_verified.2.2.2.2.1,
    mother073_verified.1, mother073_verified.2.1, mother073_verified.2.2.2.1, mother073_verified.2.2.2.2.1,
    mother074_verified.1, mother074_verified.2.1, mother074_verified.2.2.2.1, mother074_verified.2.2.2.2.1,
    mother075_verified.1, mother075_verified.2.1, mother075_verified.2.2.2.1, mother075_verified.2.2.2.2.1,
    mother076_verified.1, mother076_verified.2.1, mother076_verified.2.2.2.1, mother076_verified.2.2.2.2.1,
    mother077_verified.1, mother077_verified.2.1, mother077_verified.2.2.2.1, mother077_verified.2.2.2.2.1,
    mother078_verified.1, mother078_verified.2.1, mother078_verified.2.2.2.1, mother078_verified.2.2.2.2.1,
    mother079_verified.1, mother079_verified.2.1, mother079_verified.2.2.2.1, mother079_verified.2.2.2.2.1,
    mother080_verified.1, mother080_verified.2.1, mother080_verified.2.2.2.1, mother080_verified.2.2.2.2.1,
    mother081_verified.1, mother081_verified.2.1, mother081_verified.2.2.2.1, mother081_verified.2.2.2.2.1,
    mother082_verified.1, mother082_verified.2.1, mother082_verified.2.2.2.1, mother082_verified.2.2.2.2.1,
    mother083_verified.1, mother083_verified.2.1, mother083_verified.2.2.2.1, mother083_verified.2.2.2.2.1,
    mother084_verified.1, mother084_verified.2.1, mother084_verified.2.2.2.1, mother084_verified.2.2.2.2.1,
    mother085_verified.1, mother085_verified.2.1, mother085_verified.2.2.2.1, mother085_verified.2.2.2.2.1,
    mother086_verified.1, mother086_verified.2.1, mother086_verified.2.2.2.1, mother086_verified.2.2.2.2.1,
    mother087_verified.1, mother087_verified.2.1, mother087_verified.2.2.2.1, mother087_verified.2.2.2.2.1,
    mother088_verified.1, mother088_verified.2.1, mother088_verified.2.2.2.1, mother088_verified.2.2.2.2.1,
    mother089_verified.1, mother089_verified.2.1, mother089_verified.2.2.2.1, mother089_verified.2.2.2.2.1,
    mother090_verified.1, mother090_verified.2.1, mother090_verified.2.2.2.1, mother090_verified.2.2.2.2.1,
    mother091_verified.1, mother091_verified.2.1, mother091_verified.2.2.2.1, mother091_verified.2.2.2.2.1,
    mother092_verified.1, mother092_verified.2.1, mother092_verified.2.2.2.1, mother092_verified.2.2.2.2.1,
    mother093_verified.1, mother093_verified.2.1, mother093_verified.2.2.2.1, mother093_verified.2.2.2.2.1,
    mother094_verified.1, mother094_verified.2.1, mother094_verified.2.2.2.1, mother094_verified.2.2.2.2.1,
    mother095_verified.1, mother095_verified.2.1, mother095_verified.2.2.2.1, mother095_verified.2.2.2.2.1,
    mother096_verified.1, mother096_verified.2.1, mother096_verified.2.2.2.1, mother096_verified.2.2.2.2.1,
    mother097_verified.1, mother097_verified.2.1, mother097_verified.2.2.2.1, mother097_verified.2.2.2.2.1,
    mother098_verified.1, mother098_verified.2.1, mother098_verified.2.2.2.1, mother098_verified.2.2.2.2.1,
    mother099_verified.1, mother099_verified.2.1, mother099_verified.2.2.2.1, mother099_verified.2.2.2.2.1,
    mother100_verified.1, mother100_verified.2.1, mother100_verified.2.2.2.1, mother100_verified.2.2.2.2.1,
    mother101_verified.1, mother101_verified.2.1, mother101_verified.2.2.2.1, mother101_verified.2.2.2.2.1,
    mother102_verified.1, mother102_verified.2.1, mother102_verified.2.2.2.1, mother102_verified.2.2.2.2.1,
    mother103_verified.1, mother103_verified.2.1, mother103_verified.2.2.2.1, mother103_verified.2.2.2.2.1,
    mother104_verified.1, mother104_verified.2.1, mother104_verified.2.2.2.1, mother104_verified.2.2.2.2.1,
    mother105_verified.1, mother105_verified.2.1, mother105_verified.2.2.2.1, mother105_verified.2.2.2.2.1,
    mother106_verified.1, mother106_verified.2.1, mother106_verified.2.2.2.1, mother106_verified.2.2.2.2.1,
    mother107_verified.1, mother107_verified.2.1, mother107_verified.2.2.2.1, mother107_verified.2.2.2.2.1,
    mother108_verified.1, mother108_verified.2.1, mother108_verified.2.2.2.1, mother108_verified.2.2.2.2.1,
    mother109_verified.1, mother109_verified.2.1, mother109_verified.2.2.2.1, mother109_verified.2.2.2.2.1,
    mother110_verified.1, mother110_verified.2.1, mother110_verified.2.2.2.1, mother110_verified.2.2.2.2.1,
    mother111_verified.1, mother111_verified.2.1, mother111_verified.2.2.2.1, mother111_verified.2.2.2.2.1,
    mother112_verified.1, mother112_verified.2.1, mother112_verified.2.2.2.1, mother112_verified.2.2.2.2.1,
    mother113_verified.1, mother113_verified.2.1, mother113_verified.2.2.2.1, mother113_verified.2.2.2.2.1,
    mother114_verified.1, mother114_verified.2.1, mother114_verified.2.2.2.1, mother114_verified.2.2.2.2.1,
    mother115_verified.1, mother115_verified.2.1, mother115_verified.2.2.2.1, mother115_verified.2.2.2.2.1,
    mother116_verified.1, mother116_verified.2.1, mother116_verified.2.2.2.1, mother116_verified.2.2.2.2.1,
    mother117_verified.1, mother117_verified.2.1, mother117_verified.2.2.2.1, mother117_verified.2.2.2.2.1,
    mother118_verified.1, mother118_verified.2.1, mother118_verified.2.2.2.1, mother118_verified.2.2.2.2.1,
    mother119_verified.1, mother119_verified.2.1, mother119_verified.2.2.2.1, mother119_verified.2.2.2.2.1,
    mother120_verified.1, mother120_verified.2.1, mother120_verified.2.2.2.1, mother120_verified.2.2.2.2.1,
    mother121_verified.1, mother121_verified.2.1, mother121_verified.2.2.2.1, mother121_verified.2.2.2.2.1,
    mother122_verified.1, mother122_verified.2.1, mother122_verified.2.2.2.1, mother122_verified.2.2.2.2.1,
    mother123_verified.1, mother123_verified.2.1, mother123_verified.2.2.2.1, mother123_verified.2.2.2.2.1,
    mother124_verified.1, mother124_verified.2.1, mother124_verified.2.2.2.1, mother124_verified.2.2.2.2.1,
    mother125_verified.1, mother125_verified.2.1, mother125_verified.2.2.2.1, mother125_verified.2.2.2.2.1,
    mother126_verified.1, mother126_verified.2.1, mother126_verified.2.2.2.1, mother126_verified.2.2.2.2.1,
    mother127_verified.1, mother127_verified.2.1, mother127_verified.2.2.2.1, mother127_verified.2.2.2.2.1,
    mother128_verified.1, mother128_verified.2.1, mother128_verified.2.2.2.1, mother128_verified.2.2.2.2.1,
    mother129_verified.1, mother129_verified.2.1, mother129_verified.2.2.2.1, mother129_verified.2.2.2.2.1,
    mother130_verified.1, mother130_verified.2.1, mother130_verified.2.2.2.1, mother130_verified.2.2.2.2.1,
    mother131_verified.1, mother131_verified.2.1, mother131_verified.2.2.2.1, mother131_verified.2.2.2.2.1,
    mother132_verified.1, mother132_verified.2.1, mother132_verified.2.2.2.1, mother132_verified.2.2.2.2.1,
    mother133_verified.1, mother133_verified.2.1, mother133_verified.2.2.2.1, mother133_verified.2.2.2.2.1,
    mother134_verified.1, mother134_verified.2.1, mother134_verified.2.2.2.1, mother134_verified.2.2.2.2.1,
    mother135_verified.1, mother135_verified.2.1, mother135_verified.2.2.2.1, mother135_verified.2.2.2.2.1,
    mother136_verified.1, mother136_verified.2.1, mother136_verified.2.2.2.1, mother136_verified.2.2.2.2.1,
    mother137_verified.1, mother137_verified.2.1, mother137_verified.2.2.2.1, mother137_verified.2.2.2.2.1,
    mother138_verified.1, mother138_verified.2.1, mother138_verified.2.2.2.1, mother138_verified.2.2.2.2.1,
    mother139_verified.1, mother139_verified.2.1, mother139_verified.2.2.2.1, mother139_verified.2.2.2.2.1,
    mother140_verified.1, mother140_verified.2.1, mother140_verified.2.2.2.1, mother140_verified.2.2.2.2.1,
    mother141_verified.1, mother141_verified.2.1, mother141_verified.2.2.2.1, mother141_verified.2.2.2.2.1,
    mother142_verified.1, mother142_verified.2.1, mother142_verified.2.2.2.1, mother142_verified.2.2.2.2.1,
    mother143_verified.1, mother143_verified.2.1, mother143_verified.2.2.2.1, mother143_verified.2.2.2.2.1,
    mother144_verified.1, mother144_verified.2.1, mother144_verified.2.2.2.1, mother144_verified.2.2.2.2.1,
    mother145_verified.1, mother145_verified.2.1, mother145_verified.2.2.2.1, mother145_verified.2.2.2.2.1,
    mother146_verified.1, mother146_verified.2.1, mother146_verified.2.2.2.1, mother146_verified.2.2.2.2.1,
    mother147_verified.1, mother147_verified.2.1, mother147_verified.2.2.2.1, mother147_verified.2.2.2.2.1,
    mother148_verified.1, mother148_verified.2.1, mother148_verified.2.2.2.1, mother148_verified.2.2.2.2.1,
    mother149_verified.1, mother149_verified.2.1, mother149_verified.2.2.2.1, mother149_verified.2.2.2.2.1,
    mother150_verified.1, mother150_verified.2.1, mother150_verified.2.2.2.1, mother150_verified.2.2.2.2.1,
    mother151_verified.1, mother151_verified.2.1, mother151_verified.2.2.2.1, mother151_verified.2.2.2.2.1,
    mother152_verified.1, mother152_verified.2.1, mother152_verified.2.2.2.1, mother152_verified.2.2.2.2.1,
    mother153_verified.1, mother153_verified.2.1, mother153_verified.2.2.2.1, mother153_verified.2.2.2.2.1,
    mother154_verified.1, mother154_verified.2.1, mother154_verified.2.2.2.1, mother154_verified.2.2.2.2.1,
    mother155_verified.1, mother155_verified.2.1, mother155_verified.2.2.2.1, mother155_verified.2.2.2.2.1,
    mother156_verified.1, mother156_verified.2.1, mother156_verified.2.2.2.1, mother156_verified.2.2.2.2.1,
    mother157_verified.1, mother157_verified.2.1, mother157_verified.2.2.2.1, mother157_verified.2.2.2.2.1,
    mother158_verified.1, mother158_verified.2.1, mother158_verified.2.2.2.1, mother158_verified.2.2.2.2.1,
    mother159_verified.1, mother159_verified.2.1, mother159_verified.2.2.2.1, mother159_verified.2.2.2.2.1,
    mother160_verified.1, mother160_verified.2.1, mother160_verified.2.2.2.1, mother160_verified.2.2.2.2.1,
    mother161_verified.1, mother161_verified.2.1, mother161_verified.2.2.2.1, mother161_verified.2.2.2.2.1,
    mother162_verified.1, mother162_verified.2.1, mother162_verified.2.2.2.1, mother162_verified.2.2.2.2.1,
    mother163_verified.1, mother163_verified.2.1, mother163_verified.2.2.2.1, mother163_verified.2.2.2.2.1,
    mother164_verified.1, mother164_verified.2.1, mother164_verified.2.2.2.1, mother164_verified.2.2.2.2.1,
    mother165_verified.1, mother165_verified.2.1, mother165_verified.2.2.2.1, mother165_verified.2.2.2.2.1,
    mother166_verified.1, mother166_verified.2.1, mother166_verified.2.2.2.1, mother166_verified.2.2.2.2.1,
    mother167_verified.1, mother167_verified.2.1, mother167_verified.2.2.2.1, mother167_verified.2.2.2.2.1,
    mother168_verified.1, mother168_verified.2.1, mother168_verified.2.2.2.1, mother168_verified.2.2.2.2.1,
    mother169_verified.1, mother169_verified.2.1, mother169_verified.2.2.2.1, mother169_verified.2.2.2.2.1,
    mother170_verified.1, mother170_verified.2.1, mother170_verified.2.2.2.1, mother170_verified.2.2.2.2.1,
    mother171_verified.1, mother171_verified.2.1, mother171_verified.2.2.2.1, mother171_verified.2.2.2.2.1, beq_self_eq_true, Bool.true_and]

theorem catalogue_all_attains_distance :
    ∀ rows ∈ catalogueRows, ∃ u : Nat, weight 40 (encode rows u) = 18 := by
  simp only [catalogueRows, List.forall_mem_cons]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · exact ⟨1, mother000_verified.2.2.2.2.2⟩
  · exact ⟨1, mother001_verified.2.2.2.2.2⟩
  · exact ⟨1, mother002_verified.2.2.2.2.2⟩
  · exact ⟨1, mother003_verified.2.2.2.2.2⟩
  · exact ⟨1, mother004_verified.2.2.2.2.2⟩
  · exact ⟨1, mother005_verified.2.2.2.2.2⟩
  · exact ⟨1, mother006_verified.2.2.2.2.2⟩
  · exact ⟨1, mother007_verified.2.2.2.2.2⟩
  · exact ⟨1, mother008_verified.2.2.2.2.2⟩
  · exact ⟨1, mother009_verified.2.2.2.2.2⟩
  · exact ⟨1, mother010_verified.2.2.2.2.2⟩
  · exact ⟨1, mother011_verified.2.2.2.2.2⟩
  · exact ⟨1, mother012_verified.2.2.2.2.2⟩
  · exact ⟨1, mother013_verified.2.2.2.2.2⟩
  · exact ⟨1, mother014_verified.2.2.2.2.2⟩
  · exact ⟨1, mother015_verified.2.2.2.2.2⟩
  · exact ⟨1, mother016_verified.2.2.2.2.2⟩
  · exact ⟨1, mother017_verified.2.2.2.2.2⟩
  · exact ⟨1, mother018_verified.2.2.2.2.2⟩
  · exact ⟨1, mother019_verified.2.2.2.2.2⟩
  · exact ⟨1, mother020_verified.2.2.2.2.2⟩
  · exact ⟨1, mother021_verified.2.2.2.2.2⟩
  · exact ⟨1, mother022_verified.2.2.2.2.2⟩
  · exact ⟨1, mother023_verified.2.2.2.2.2⟩
  · exact ⟨1, mother024_verified.2.2.2.2.2⟩
  · exact ⟨1, mother025_verified.2.2.2.2.2⟩
  · exact ⟨1, mother026_verified.2.2.2.2.2⟩
  · exact ⟨1, mother027_verified.2.2.2.2.2⟩
  · exact ⟨1, mother028_verified.2.2.2.2.2⟩
  · exact ⟨1, mother029_verified.2.2.2.2.2⟩
  · exact ⟨1, mother030_verified.2.2.2.2.2⟩
  · exact ⟨1, mother031_verified.2.2.2.2.2⟩
  · exact ⟨1, mother032_verified.2.2.2.2.2⟩
  · exact ⟨1, mother033_verified.2.2.2.2.2⟩
  · exact ⟨1, mother034_verified.2.2.2.2.2⟩
  · exact ⟨1, mother035_verified.2.2.2.2.2⟩
  · exact ⟨1, mother036_verified.2.2.2.2.2⟩
  · exact ⟨1, mother037_verified.2.2.2.2.2⟩
  · exact ⟨1, mother038_verified.2.2.2.2.2⟩
  · exact ⟨1, mother039_verified.2.2.2.2.2⟩
  · exact ⟨1, mother040_verified.2.2.2.2.2⟩
  · exact ⟨1, mother041_verified.2.2.2.2.2⟩
  · exact ⟨1, mother042_verified.2.2.2.2.2⟩
  · exact ⟨1, mother043_verified.2.2.2.2.2⟩
  · exact ⟨1, mother044_verified.2.2.2.2.2⟩
  · exact ⟨1, mother045_verified.2.2.2.2.2⟩
  · exact ⟨1, mother046_verified.2.2.2.2.2⟩
  · exact ⟨1, mother047_verified.2.2.2.2.2⟩
  · exact ⟨1, mother048_verified.2.2.2.2.2⟩
  · exact ⟨1, mother049_verified.2.2.2.2.2⟩
  · exact ⟨1, mother050_verified.2.2.2.2.2⟩
  · exact ⟨1, mother051_verified.2.2.2.2.2⟩
  · exact ⟨1, mother052_verified.2.2.2.2.2⟩
  · exact ⟨1, mother053_verified.2.2.2.2.2⟩
  · exact ⟨1, mother054_verified.2.2.2.2.2⟩
  · exact ⟨1, mother055_verified.2.2.2.2.2⟩
  · exact ⟨1, mother056_verified.2.2.2.2.2⟩
  · exact ⟨1, mother057_verified.2.2.2.2.2⟩
  · exact ⟨1, mother058_verified.2.2.2.2.2⟩
  · exact ⟨1, mother059_verified.2.2.2.2.2⟩
  · exact ⟨1, mother060_verified.2.2.2.2.2⟩
  · exact ⟨1, mother061_verified.2.2.2.2.2⟩
  · exact ⟨1, mother062_verified.2.2.2.2.2⟩
  · exact ⟨1, mother063_verified.2.2.2.2.2⟩
  · exact ⟨1, mother064_verified.2.2.2.2.2⟩
  · exact ⟨1, mother065_verified.2.2.2.2.2⟩
  · exact ⟨1, mother066_verified.2.2.2.2.2⟩
  · exact ⟨1, mother067_verified.2.2.2.2.2⟩
  · exact ⟨1, mother068_verified.2.2.2.2.2⟩
  · exact ⟨1, mother069_verified.2.2.2.2.2⟩
  · exact ⟨1, mother070_verified.2.2.2.2.2⟩
  · exact ⟨1, mother071_verified.2.2.2.2.2⟩
  · exact ⟨1, mother072_verified.2.2.2.2.2⟩
  · exact ⟨1, mother073_verified.2.2.2.2.2⟩
  · exact ⟨1, mother074_verified.2.2.2.2.2⟩
  · exact ⟨1, mother075_verified.2.2.2.2.2⟩
  · exact ⟨1, mother076_verified.2.2.2.2.2⟩
  · exact ⟨1, mother077_verified.2.2.2.2.2⟩
  · exact ⟨1, mother078_verified.2.2.2.2.2⟩
  · exact ⟨1, mother079_verified.2.2.2.2.2⟩
  · exact ⟨1, mother080_verified.2.2.2.2.2⟩
  · exact ⟨1, mother081_verified.2.2.2.2.2⟩
  · exact ⟨1, mother082_verified.2.2.2.2.2⟩
  · exact ⟨1, mother083_verified.2.2.2.2.2⟩
  · exact ⟨1, mother084_verified.2.2.2.2.2⟩
  · exact ⟨1, mother085_verified.2.2.2.2.2⟩
  · exact ⟨1, mother086_verified.2.2.2.2.2⟩
  · exact ⟨1, mother087_verified.2.2.2.2.2⟩
  · exact ⟨1, mother088_verified.2.2.2.2.2⟩
  · exact ⟨1, mother089_verified.2.2.2.2.2⟩
  · exact ⟨1, mother090_verified.2.2.2.2.2⟩
  · exact ⟨1, mother091_verified.2.2.2.2.2⟩
  · exact ⟨1, mother092_verified.2.2.2.2.2⟩
  · exact ⟨1, mother093_verified.2.2.2.2.2⟩
  · exact ⟨1, mother094_verified.2.2.2.2.2⟩
  · exact ⟨1, mother095_verified.2.2.2.2.2⟩
  · exact ⟨1, mother096_verified.2.2.2.2.2⟩
  · exact ⟨1, mother097_verified.2.2.2.2.2⟩
  · exact ⟨1, mother098_verified.2.2.2.2.2⟩
  · exact ⟨1, mother099_verified.2.2.2.2.2⟩
  · exact ⟨1, mother100_verified.2.2.2.2.2⟩
  · exact ⟨1, mother101_verified.2.2.2.2.2⟩
  · exact ⟨1, mother102_verified.2.2.2.2.2⟩
  · exact ⟨1, mother103_verified.2.2.2.2.2⟩
  · exact ⟨1, mother104_verified.2.2.2.2.2⟩
  · exact ⟨1, mother105_verified.2.2.2.2.2⟩
  · exact ⟨1, mother106_verified.2.2.2.2.2⟩
  · exact ⟨1, mother107_verified.2.2.2.2.2⟩
  · exact ⟨1, mother108_verified.2.2.2.2.2⟩
  · exact ⟨1, mother109_verified.2.2.2.2.2⟩
  · exact ⟨1, mother110_verified.2.2.2.2.2⟩
  · exact ⟨1, mother111_verified.2.2.2.2.2⟩
  · exact ⟨1, mother112_verified.2.2.2.2.2⟩
  · exact ⟨1, mother113_verified.2.2.2.2.2⟩
  · exact ⟨1, mother114_verified.2.2.2.2.2⟩
  · exact ⟨1, mother115_verified.2.2.2.2.2⟩
  · exact ⟨1, mother116_verified.2.2.2.2.2⟩
  · exact ⟨1, mother117_verified.2.2.2.2.2⟩
  · exact ⟨1, mother118_verified.2.2.2.2.2⟩
  · exact ⟨1, mother119_verified.2.2.2.2.2⟩
  · exact ⟨1, mother120_verified.2.2.2.2.2⟩
  · exact ⟨1, mother121_verified.2.2.2.2.2⟩
  · exact ⟨1, mother122_verified.2.2.2.2.2⟩
  · exact ⟨1, mother123_verified.2.2.2.2.2⟩
  · exact ⟨1, mother124_verified.2.2.2.2.2⟩
  · exact ⟨1, mother125_verified.2.2.2.2.2⟩
  · exact ⟨1, mother126_verified.2.2.2.2.2⟩
  · exact ⟨1, mother127_verified.2.2.2.2.2⟩
  · exact ⟨1, mother128_verified.2.2.2.2.2⟩
  · exact ⟨1, mother129_verified.2.2.2.2.2⟩
  · exact ⟨1, mother130_verified.2.2.2.2.2⟩
  · exact ⟨1, mother131_verified.2.2.2.2.2⟩
  · exact ⟨1, mother132_verified.2.2.2.2.2⟩
  · exact ⟨1, mother133_verified.2.2.2.2.2⟩
  · exact ⟨1, mother134_verified.2.2.2.2.2⟩
  · exact ⟨1, mother135_verified.2.2.2.2.2⟩
  · exact ⟨1, mother136_verified.2.2.2.2.2⟩
  · exact ⟨1, mother137_verified.2.2.2.2.2⟩
  · exact ⟨1, mother138_verified.2.2.2.2.2⟩
  · exact ⟨1, mother139_verified.2.2.2.2.2⟩
  · exact ⟨1, mother140_verified.2.2.2.2.2⟩
  · exact ⟨1, mother141_verified.2.2.2.2.2⟩
  · exact ⟨1, mother142_verified.2.2.2.2.2⟩
  · exact ⟨1, mother143_verified.2.2.2.2.2⟩
  · exact ⟨1, mother144_verified.2.2.2.2.2⟩
  · exact ⟨1, mother145_verified.2.2.2.2.2⟩
  · exact ⟨1, mother146_verified.2.2.2.2.2⟩
  · exact ⟨1, mother147_verified.2.2.2.2.2⟩
  · exact ⟨1, mother148_verified.2.2.2.2.2⟩
  · exact ⟨1, mother149_verified.2.2.2.2.2⟩
  · exact ⟨1, mother150_verified.2.2.2.2.2⟩
  · exact ⟨1, mother151_verified.2.2.2.2.2⟩
  · exact ⟨1, mother152_verified.2.2.2.2.2⟩
  · exact ⟨1, mother153_verified.2.2.2.2.2⟩
  · exact ⟨1, mother154_verified.2.2.2.2.2⟩
  · exact ⟨1, mother155_verified.2.2.2.2.2⟩
  · exact ⟨1, mother156_verified.2.2.2.2.2⟩
  · exact ⟨1, mother157_verified.2.2.2.2.2⟩
  · exact ⟨1, mother158_verified.2.2.2.2.2⟩
  · exact ⟨1, mother159_verified.2.2.2.2.2⟩
  · exact ⟨1, mother160_verified.2.2.2.2.2⟩
  · exact ⟨1, mother161_verified.2.2.2.2.2⟩
  · exact ⟨1, mother162_verified.2.2.2.2.2⟩
  · exact ⟨1, mother163_verified.2.2.2.2.2⟩
  · exact ⟨1, mother164_verified.2.2.2.2.2⟩
  · exact ⟨32, mother165_verified.2.2.2.2.2⟩
  · exact ⟨1, mother166_verified.2.2.2.2.2⟩
  · exact ⟨1, mother167_verified.2.2.2.2.2⟩
  · exact ⟨1, mother168_verified.2.2.2.2.2⟩
  · exact ⟨1, mother169_verified.2.2.2.2.2⟩
  · exact ⟨5, mother170_verified.2.2.2.2.2⟩
  · exact ⟨24, mother171_verified.2.2.2.2.2⟩
  · exact List.forall_mem_nil _

end ECC.Packed
