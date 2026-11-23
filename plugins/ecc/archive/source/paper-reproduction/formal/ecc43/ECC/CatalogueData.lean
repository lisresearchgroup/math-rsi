import ECC.Packed

set_option maxRecDepth 4096
set_option maxHeartbeats 8000000

namespace ECC.Packed

def mother000 : List Nat := [787024734240, 1024293654592, 953370648769, 807229931906, 1060442376964, 1021373128200, 943268181040]

theorem mother000_verified :
    mother000.length = 7 ∧
    allRowsFit 40 mother000 = true ∧
    distanceCheck 40 7 18 mother000 = true ∧
    evenCheck 40 7 mother000 = true ∧
    fullSupportCheck 40 mother000 = true ∧
    weight 40 (encode mother000 1) = 18 := by
  decide +kernel

def mother001 : List Nat := [237268947040, 1024293707969, 403614810498, 807229883136, 1060442412548, 471617256456, 943268194352]

theorem mother001_verified :
    mother001.length = 7 ∧
    allRowsFit 40 mother001 = true ∧
    distanceCheck 40 7 18 mother001 = true ∧
    evenCheck 40 7 mother001 = true ∧
    fullSupportCheck 40 mother001 = true ∧
    weight 40 (encode mother001 1) = 18 := by
  decide +kernel

def mother002 : List Nat := [783775486048, 468039344321, 961848492418, 807006012160, 505977050628, 1029133974536, 391887743024]

theorem mother002_verified :
    mother002.length = 7 ∧
    allRowsFit 40 mother002 = true ∧
    distanceCheck 40 7 18 mother002 = true ∧
    evenCheck 40 7 mother002 = true ∧
    fullSupportCheck 40 mother002 = true ∧
    weight 40 (encode mother002 1) = 18 := by
  decide +kernel

def mother003 : List Nat := [788070453312, 474481795265, 403502743938, 257250198276, 510272017928, 470788226064, 394035226656]

theorem mother003_verified :
    mother003.length = 7 ∧
    allRowsFit 40 mother003 = true ∧
    distanceCheck 40 7 18 mother003 = true ∧
    evenCheck 40 7 mother003 = true ∧
    fullSupportCheck 40 mother003 = true ∧
    weight 40 (encode mother003 1) = 18 := by
  decide +kernel

def mother004 : List Nat := [910089336896, 755093369025, 917481734594, 735451849604, 946984830728, 768688197136, 1021980351520]

theorem mother004_verified :
    mother004.length = 7 ∧
    allRowsFit 40 mother004 = true ∧
    distanceCheck 40 7 18 mother004 = true ∧
    evenCheck 40 7 mother004 = true ∧
    fullSupportCheck 40 mother004 = true ∧
    weight 40 (encode mother004 1) = 18 := by
  decide +kernel

def mother005 : List Nat := [369145327745, 738323931522, 922597327748, 745683044104, 387593063952, 229725281312, 1009206392896]

theorem mother005_verified :
    mother005.length = 7 ∧
    allRowsFit 40 mother005 = true ∧
    distanceCheck 40 7 18 mother005 = true ∧
    evenCheck 40 7 mother005 = true ∧
    fullSupportCheck 40 mother005 = true ∧
    weight 40 (encode mother005 1) = 18 := by
  decide +kernel

def mother006 : List Nat := [369145327745, 738323931522, 372841530244, 745683044104, 937348861456, 779481111584, 459450562624]

theorem mother006_verified :
    mother006.length = 7 ∧
    allRowsFit 40 mother006 = true ∧
    distanceCheck 40 7 18 mother006 = true ∧
    evenCheck 40 7 mother006 = true ∧
    fullSupportCheck 40 mother006 = true ∧
    weight 40 (encode mother006 1) = 18 := by
  decide +kernel

def mother007 : List Nat := [944441536641, 720734806402, 951844389764, 735457675016, 912619949584, 803054459936, 987616852032]

theorem mother007_verified :
    mother007.length = 7 ∧
    allRowsFit 40 mother007 = true ∧
    distanceCheck 40 7 18 mother007 = true ∧
    evenCheck 40 7 mother007 = true ∧
    fullSupportCheck 40 mother007 = true ∧
    weight 40 (encode mother007 1) = 18 := by
  decide +kernel

def mother008 : List Nat := [262143, 134125994, 66659560172, 70826255126, 164930204632, 297814705120, 570421410816]

theorem mother008_verified :
    mother008.length = 7 ∧
    allRowsFit 40 mother008 = true ∧
    distanceCheck 40 7 18 mother008 = true ∧
    evenCheck 40 7 mother008 = true ∧
    fullSupportCheck 40 mother008 = true ∧
    weight 40 (encode mother008 1) = 18 := by
  decide +kernel

def mother009 : List Nat := [262143, 133987122, 66659719764, 70826242886, 164930200472, 297814705120, 570421410816]

theorem mother009_verified :
    mother009.length = 7 ∧
    allRowsFit 40 mother009 = true ∧
    distanceCheck 40 7 18 mother009 = true ∧
    evenCheck 40 7 mother009 = true ∧
    fullSupportCheck 40 mother009 = true ∧
    weight 40 (encode mother009 1) = 18 := by
  decide +kernel

def mother010 : List Nat := [262143, 134125010, 66659789134, 70826266344, 164930244748, 297814712560, 570421411584]

theorem mother010_verified :
    mother010.length = 7 ∧
    allRowsFit 40 mother010 = true ∧
    distanceCheck 40 7 18 mother010 = true ∧
    evenCheck 40 7 mother010 = true ∧
    fullSupportCheck 40 mother010 = true ∧
    weight 40 (encode mother010 1) = 18 := by
  decide +kernel

def mother011 : List Nat := [262143, 134034920, 66659727682, 70826266284, 164930244814, 297814712560, 570421411584]

theorem mother011_verified :
    mother011.length = 7 ∧
    allRowsFit 40 mother011 = true ∧
    distanceCheck 40 7 18 mother011 = true ∧
    evenCheck 40 7 mother011 = true ∧
    fullSupportCheck 40 mother011 = true ∧
    weight 40 (encode mother011 1) = 18 := by
  decide +kernel

def mother012 : List Nat := [262143, 134015826, 66659725702, 70826204888, 164930200348, 297814705120, 570421410816]

theorem mother012_verified :
    mother012.length = 7 ∧
    allRowsFit 40 mother012 = true ∧
    distanceCheck 40 7 18 mother012 = true ∧
    evenCheck 40 7 mother012 = true ∧
    fullSupportCheck 40 mother012 = true ∧
    weight 40 (encode mother012 1) = 18 := by
  decide +kernel

def mother013 : List Nat := [262143, 133986130, 66659776902, 70826208984, 164930237212, 297814705120, 570421410816]

theorem mother013_verified :
    mother013.length = 7 ∧
    allRowsFit 40 mother013 = true ∧
    distanceCheck 40 7 18 mother013 = true ∧
    evenCheck 40 7 mother013 = true ∧
    fullSupportCheck 40 mother013 = true ∧
    weight 40 (encode mother013 1) = 18 := by
  decide +kernel

def mother014 : List Nat := [262143, 134137242, 66659653602, 70826269108, 164930133704, 297814712560, 570421411584]

theorem mother014_verified :
    mother014.length = 7 ∧
    allRowsFit 40 mother014 = true ∧
    distanceCheck 40 7 18 mother014 = true ∧
    evenCheck 40 7 mother014 = true ∧
    fullSupportCheck 40 mother014 = true ∧
    weight 40 (encode mother014 1) = 18 := by
  decide +kernel

def mother015 : List Nat := [262143, 134161772, 66659638744, 70826235624, 164930197646, 297814712560, 570421411584]

theorem mother015_verified :
    mother015.length = 7 ∧
    allRowsFit 40 mother015 = true ∧
    distanceCheck 40 7 18 mother015 = true ∧
    evenCheck 40 7 mother015 = true ∧
    fullSupportCheck 40 mother015 = true ∧
    weight 40 (encode mother015 1) = 18 := by
  decide +kernel

def mother016 : List Nat := [262143, 134155574, 66659712900, 70826273240, 164930236958, 297814705120, 570421410816]

theorem mother016_verified :
    mother016.length = 7 ∧
    allRowsFit 40 mother016 = true ∧
    distanceCheck 40 7 18 mother016 = true ∧
    evenCheck 40 7 mother016 = true ∧
    fullSupportCheck 40 mother016 = true ∧
    weight 40 (encode mother016 1) = 18 := by
  decide +kernel

def mother017 : List Nat := [262143, 134028658, 66659593640, 70826273340, 164930139088, 297814705120, 570421410816]

theorem mother017_verified :
    mother017.length = 7 ∧
    allRowsFit 40 mother017 = true ∧
    distanceCheck 40 7 18 mother017 = true ∧
    evenCheck 40 7 mother017 = true ∧
    fullSupportCheck 40 mother017 = true ∧
    weight 40 (encode mother017 1) = 18 := by
  decide +kernel

def mother018 : List Nat := [262143, 134129330, 66659707658, 70826112908, 164930206672, 297814705120, 570421410816]

theorem mother018_verified :
    mother018.length = 7 ∧
    allRowsFit 40 mother018 = true ∧
    distanceCheck 40 7 18 mother018 = true ∧
    evenCheck 40 7 mother018 = true ∧
    fullSupportCheck 40 mother018 = true ∧
    weight 40 (encode mother018 1) = 18 := by
  decide +kernel

def mother019 : List Nat := [262143, 134113076, 66659764762, 70826112908, 164930206672, 297814705120, 570421410816]

theorem mother019_verified :
    mother019.length = 7 ∧
    allRowsFit 40 mother019 = true ∧
    distanceCheck 40 7 18 mother019 = true ∧
    evenCheck 40 7 mother019 = true ∧
    fullSupportCheck 40 mother019 = true ∧
    weight 40 (encode mother019 1) = 18 := by
  decide +kernel

def mother020 : List Nat := [262143, 134155580, 66659653170, 70826224468, 164930237336, 297814705120, 570421410816]

theorem mother020_verified :
    mother020.length = 7 ∧
    allRowsFit 40 mother020 = true ∧
    distanceCheck 40 7 18 mother020 = true ∧
    evenCheck 40 7 mother020 = true ∧
    fullSupportCheck 40 mother020 = true ∧
    weight 40 (encode mother020 1) = 18 := by
  decide +kernel

def mother021 : List Nat := [262143, 134057366, 66659715788, 70826269928, 164930244622, 297814712560, 570421411584]

theorem mother021_verified :
    mother021.length = 7 ∧
    allRowsFit 40 mother021 = true ∧
    distanceCheck 40 7 18 mother021 = true ∧
    evenCheck 40 7 mother021 = true ∧
    fullSupportCheck 40 mother021 = true ∧
    weight 40 (encode mother021 1) = 18 := by
  decide +kernel

def mother022 : List Nat := [262143, 134186286, 66659654034, 70826208728, 164930204188, 297814705120, 570421410816]

theorem mother022_verified :
    mother022.length = 7 ∧
    allRowsFit 40 mother022 = true ∧
    distanceCheck 40 7 18 mother022 = true ∧
    evenCheck 40 7 mother022 = true ∧
    fullSupportCheck 40 mother022 = true ∧
    weight 40 (encode mother022 1) = 18 := by
  decide +kernel

def mother023 : List Nat := [262143, 134187350, 66659667658, 70826234856, 164930198668, 297814712560, 570421411584]

theorem mother023_verified :
    mother023.length = 7 ∧
    allRowsFit 40 mother023 = true ∧
    distanceCheck 40 7 18 mother023 = true ∧
    evenCheck 40 7 mother023 = true ∧
    fullSupportCheck 40 mother023 = true ∧
    weight 40 (encode mother023 1) = 18 := by
  decide +kernel

def mother024 : List Nat := [262143, 134071958, 66659732940, 70826268392, 164930230286, 297814712560, 570421411584]

theorem mother024_verified :
    mother024.length = 7 ∧
    allRowsFit 40 mother024 = true ∧
    distanceCheck 40 7 18 mother024 = true ∧
    evenCheck 40 7 mother024 = true ∧
    fullSupportCheck 40 mother024 = true ∧
    weight 40 (encode mother024 1) = 18 := by
  decide +kernel

def mother025 : List Nat := [262143, 134128942, 66659601610, 70826268314, 164930230508, 297814712560, 570421411584]

theorem mother025_verified :
    mother025.length = 7 ∧
    allRowsFit 40 mother025 = true ∧
    distanceCheck 40 7 18 mother025 = true ∧
    evenCheck 40 7 mother025 = true ∧
    fullSupportCheck 40 mother025 = true ∧
    weight 40 (encode mother025 1) = 18 := by
  decide +kernel

def mother026 : List Nat := [262143, 134128462, 66659732872, 70826268314, 164930230508, 297814712560, 570421411584]

theorem mother026_verified :
    mother026.length = 7 ∧
    allRowsFit 40 mother026 = true ∧
    distanceCheck 40 7 18 mother026 = true ∧
    evenCheck 40 7 mother026 = true ∧
    fullSupportCheck 40 mother026 = true ∧
    weight 40 (encode mother026 1) = 18 := by
  decide +kernel

def mother027 : List Nat := [262143, 134072742, 66659740170, 70826267576, 164930231500, 297814712560, 570421411584]

theorem mother027_verified :
    mother027.length = 7 ∧
    allRowsFit 40 mother027 = true ∧
    distanceCheck 40 7 18 mother027 = true ∧
    evenCheck 40 7 mother027 = true ∧
    fullSupportCheck 40 mother027 = true ∧
    weight 40 (encode mother027 1) = 18 := by
  decide +kernel

def mother028 : List Nat := [262143, 134043106, 66659754286, 70826219180, 164930230472, 297814712560, 570421411584]

theorem mother028_verified :
    mother028.length = 7 ∧
    allRowsFit 40 mother028 = true ∧
    distanceCheck 40 7 18 mother028 = true ∧
    evenCheck 40 7 mother028 = true ∧
    fullSupportCheck 40 mother028 = true ∧
    weight 40 (encode mother028 1) = 18 := by
  decide +kernel

def mother029 : List Nat := [262143, 134122356, 66659692990, 70826121930, 164930198764, 297814712560, 570421411584]

theorem mother029_verified :
    mother029.length = 7 ∧
    allRowsFit 40 mother029 = true ∧
    distanceCheck 40 7 18 mother029 = true ∧
    evenCheck 40 7 mother029 = true ∧
    fullSupportCheck 40 mother029 = true ∧
    weight 40 (encode mother029 1) = 18 := by
  decide +kernel

def mother030 : List Nat := [262143, 134155724, 66659706586, 70826175378, 164930138908, 297814705120, 570421410816]

theorem mother030_verified :
    mother030.length = 7 ∧
    allRowsFit 40 mother030 = true ∧
    distanceCheck 40 7 18 mother030 = true ∧
    evenCheck 40 7 mother030 = true ∧
    fullSupportCheck 40 mother030 = true ∧
    weight 40 (encode mother030 1) = 18 := by
  decide +kernel

def mother031 : List Nat := [262143, 134066350, 66659737878, 70826272348, 164930010008, 297814705120, 570421410816]

theorem mother031_verified :
    mother031.length = 7 ∧
    allRowsFit 40 mother031 = true ∧
    distanceCheck 40 7 18 mother031 = true ∧
    evenCheck 40 7 mother031 = true ∧
    fullSupportCheck 40 mother031 = true ∧
    weight 40 (encode mother031 1) = 18 := by
  decide +kernel

def mother032 : List Nat := [262143, 134189366, 66659632474, 70826236572, 164930198752, 297814712560, 570421411584]

theorem mother032_verified :
    mother032.length = 7 ∧
    allRowsFit 40 mother032 = true ∧
    distanceCheck 40 7 18 mother032 = true ∧
    evenCheck 40 7 mother032 = true ∧
    fullSupportCheck 40 mother032 = true ∧
    weight 40 (encode mother032 1) = 18 := by
  decide +kernel

def mother033 : List Nat := [262143, 134124858, 66659695540, 70826122438, 164930199272, 297814712560, 570421411584]

theorem mother033_verified :
    mother033.length = 7 ∧
    allRowsFit 40 mother033 = true ∧
    distanceCheck 40 7 18 mother033 = true ∧
    evenCheck 40 7 mother033 = true ∧
    fullSupportCheck 40 mother033 = true ∧
    weight 40 (encode mother033 1) = 18 := by
  decide +kernel

def mother034 : List Nat := [262143, 134042580, 66659710274, 70826296988, 164930197736, 297814712560, 570421411584]

theorem mother034_verified :
    mother034.length = 7 ∧
    allRowsFit 40 mother034 = true ∧
    distanceCheck 40 7 18 mother034 = true ∧
    evenCheck 40 7 mother034 = true ∧
    fullSupportCheck 40 mother034 = true ∧
    weight 40 (encode mother034 1) = 18 := by
  decide +kernel

def mother035 : List Nat := [262143, 134000308, 66659730586, 70826273580, 164930139088, 297814705120, 570421410816]

theorem mother035_verified :
    mother035.length = 7 ∧
    allRowsFit 40 mother035 = true ∧
    distanceCheck 40 7 18 mother035 = true ∧
    evenCheck 40 7 mother035 = true ∧
    fullSupportCheck 40 mother035 = true ∧
    weight 40 (encode mother035 1) = 18 := by
  decide +kernel

def mother036 : List Nat := [262143, 134057802, 66659636530, 70826236508, 164930200472, 297814705120, 570421410816]

theorem mother036_verified :
    mother036.length = 7 ∧
    allRowsFit 40 mother036 = true ∧
    distanceCheck 40 7 18 mother036 = true ∧
    evenCheck 40 7 mother036 = true ∧
    fullSupportCheck 40 mother036 = true ∧
    weight 40 (encode mother036 1) = 18 := by
  decide +kernel

def mother037 : List Nat := [262143, 134123314, 66659607946, 70826273340, 164930139088, 297814705120, 570421410816]

theorem mother037_verified :
    mother037.length = 7 ∧
    allRowsFit 40 mother037 = true ∧
    distanceCheck 40 7 18 mother037 = true ∧
    evenCheck 40 7 mother037 = true ∧
    fullSupportCheck 40 mother037 = true ∧
    weight 40 (encode mother037 1) = 18 := by
  decide +kernel

def mother038 : List Nat := [262143, 134122346, 66659563954, 70826250956, 164930198776, 297814712560, 570421411584]

theorem mother038_verified :
    mother038.length = 7 ∧
    allRowsFit 40 mother038 = true ∧
    distanceCheck 40 7 18 mother038 = true ∧
    evenCheck 40 7 mother038 = true ∧
    fullSupportCheck 40 mother038 = true ∧
    weight 40 (encode mother038 1) = 18 := by
  decide +kernel

def mother039 : List Nat := [262143, 134032842, 66659571064, 70826301596, 164930133728, 297814712560, 570421411584]

theorem mother039_verified :
    mother039.length = 7 ∧
    allRowsFit 40 mother039 = true ∧
    distanceCheck 40 7 18 mother039 = true ∧
    evenCheck 40 7 mother039 = true ∧
    fullSupportCheck 40 mother039 = true ∧
    weight 40 (encode mother039 1) = 18 := by
  decide +kernel

def mother040 : List Nat := [262143, 134122342, 66659692972, 70826121960, 164930198734, 297814712560, 570421411584]

theorem mother040_verified :
    mother040.length = 7 ∧
    allRowsFit 40 mother040 = true ∧
    distanceCheck 40 7 18 mother040 = true ∧
    evenCheck 40 7 mother040 = true ∧
    fullSupportCheck 40 mother040 = true ∧
    weight 40 (encode mother040 1) = 18 := by
  decide +kernel

def mother041 : List Nat := [262143, 134063446, 66659725706, 70826304060, 164930206672, 297814705120, 570421410816]

theorem mother041_verified :
    mother041.length = 7 ∧
    allRowsFit 40 mother041 = true ∧
    distanceCheck 40 7 18 mother041 = true ∧
    evenCheck 40 7 mother041 = true ∧
    fullSupportCheck 40 mother041 = true ∧
    weight 40 (encode mother041 1) = 18 := by
  decide +kernel

def mother042 : List Nat := [262143, 134003058, 66659736230, 70826234828, 164930198776, 297814712560, 570421411584]

theorem mother042_verified :
    mother042.length = 7 ∧
    allRowsFit 40 mother042 = true ∧
    distanceCheck 40 7 18 mother042 = true ∧
    evenCheck 40 7 mother042 = true ∧
    fullSupportCheck 40 mother042 = true ∧
    weight 40 (encode mother042 1) = 18 := by
  decide +kernel

def mother043 : List Nat := [262143, 134048646, 66612913594, 70780039634, 164900780316, 297818898912, 570417217024]

theorem mother043_verified :
    mother043.length = 7 ∧
    allRowsFit 40 mother043 = true ∧
    distanceCheck 40 7 18 mother043 = true ∧
    evenCheck 40 7 mother043 = true ∧
    fullSupportCheck 40 mother043 = true ∧
    weight 40 (encode mother043 1) = 18 := by
  decide +kernel

def mother044 : List Nat := [262143, 134186094, 66613089222, 70780075338, 164900886924, 297818907120, 570417217024]

theorem mother044_verified :
    mother044.length = 7 ∧
    allRowsFit 40 mother044 = true ∧
    distanceCheck 40 7 18 mother044 = true ∧
    evenCheck 40 7 mother044 = true ∧
    fullSupportCheck 40 mother044 = true ∧
    weight 40 (encode mother044 1) = 18 := by
  decide +kernel

def mother045 : List Nat := [262143, 134187628, 66613089734, 70780074318, 164900884872, 297818907120, 570417217024]

theorem mother045_verified :
    mother045.length = 7 ∧
    allRowsFit 40 mother045 = true ∧
    distanceCheck 40 7 18 mother045 = true ∧
    evenCheck 40 7 mother045 = true ∧
    fullSupportCheck 40 mother045 = true ∧
    weight 40 (encode mother045 1) = 18 := by
  decide +kernel

def mother046 : List Nat := [262143, 134068550, 66612945590, 70780005692, 164900778456, 297818898912, 570417217024]

theorem mother046_verified :
    mother046.length = 7 ∧
    allRowsFit 40 mother046 = true ∧
    distanceCheck 40 7 18 mother046 = true ∧
    evenCheck 40 7 mother046 = true ∧
    fullSupportCheck 40 mother046 = true ∧
    weight 40 (encode mother046 1) = 18 := by
  decide +kernel

def mother047 : List Nat := [262143, 134052230, 66613039804, 70780130094, 164900871624, 297818907120, 570417217024]

theorem mother047_verified :
    mother047.length = 7 ∧
    allRowsFit 40 mother047 = true ∧
    distanceCheck 40 7 18 mother047 = true ∧
    evenCheck 40 7 mother047 = true ∧
    fullSupportCheck 40 mother047 = true ∧
    weight 40 (encode mother047 1) = 18 := by
  decide +kernel

def mother048 : List Nat := [262143, 134050190, 66613081240, 70780135196, 164900878800, 297818898912, 570417217024]

theorem mother048_verified :
    mother048.length = 7 ∧
    allRowsFit 40 mother048 = true ∧
    distanceCheck 40 7 18 mother048 = true ∧
    evenCheck 40 7 mother048 = true ∧
    fullSupportCheck 40 mother048 = true ∧
    weight 40 (encode mother048 1) = 18 := by
  decide +kernel

def mother049 : List Nat := [262143, 134194266, 66613082260, 70780138296, 164900781504, 297818898912, 570417217024]

theorem mother049_verified :
    mother049.length = 7 ∧
    allRowsFit 40 mother049 = true ∧
    distanceCheck 40 7 18 mother049 = true ∧
    evenCheck 40 7 mother049 = true ∧
    fullSupportCheck 40 mother049 = true ∧
    weight 40 (encode mother049 1) = 18 := by
  decide +kernel

def mother050 : List Nat := [262143, 134126196, 66613073068, 70780148010, 164900864460, 297818907120, 570417217024]

theorem mother050_verified :
    mother050.length = 7 ∧
    allRowsFit 40 mother050 = true ∧
    distanceCheck 40 7 18 mother050 = true ∧
    evenCheck 40 7 mother050 = true ∧
    fullSupportCheck 40 mother050 = true ∧
    weight 40 (encode mother050 1) = 18 := by
  decide +kernel

def mother051 : List Nat := [262143, 134044978, 66613128276, 70780119430, 164900843928, 297818898912, 570417217024]

theorem mother051_verified :
    mother051.length = 7 ∧
    allRowsFit 40 mother051 = true ∧
    distanceCheck 40 7 18 mother051 = true ∧
    evenCheck 40 7 mother051 = true ∧
    fullSupportCheck 40 mother051 = true ∧
    weight 40 (encode mother051 1) = 18 := by
  decide +kernel

def mother052 : List Nat := [262143, 133995954, 66613095764, 70780168582, 164900778456, 297818898912, 570417217024]

theorem mother052_verified :
    mother052.length = 7 ∧
    allRowsFit 40 mother052 = true ∧
    distanceCheck 40 7 18 mother052 = true ∧
    evenCheck 40 7 mother052 = true ∧
    fullSupportCheck 40 mother052 = true ∧
    weight 40 (encode mother052 1) = 18 := by
  decide +kernel

def mother053 : List Nat := [262143, 134028722, 66613112084, 70780090758, 164900876760, 297818898912, 570417217024]

theorem mother053_verified :
    mother053.length = 7 ∧
    allRowsFit 40 mother053 = true ∧
    distanceCheck 40 7 18 mother053 = true ∧
    evenCheck 40 7 mother053 = true ∧
    fullSupportCheck 40 mother053 = true ∧
    weight 40 (encode mother053 1) = 18 := by
  decide +kernel

def mother054 : List Nat := [262143, 134193724, 66613066068, 70780121478, 164900847000, 297818898912, 570417217024]

theorem mother054_verified :
    mother054.length = 7 ∧
    allRowsFit 40 mother054 = true ∧
    distanceCheck 40 7 18 mother054 = true ∧
    evenCheck 40 7 mother054 = true ∧
    fullSupportCheck 40 mother054 = true ∧
    weight 40 (encode mother054 1) = 18 := by
  decide +kernel

def mother055 : List Nat := [262143, 134096628, 66612923770, 70780106060, 164900845968, 297818898912, 570417217024]

theorem mother055_verified :
    mother055.length = 7 ∧
    allRowsFit 40 mother055 = true ∧
    distanceCheck 40 7 18 mother055 = true ∧
    evenCheck 40 7 mother055 = true ∧
    fullSupportCheck 40 mother055 = true ∧
    weight 40 (encode mother055 1) = 18 := by
  decide +kernel

def mother056 : List Nat := [262143, 134001610, 66613130386, 70780134648, 164900780316, 297818898912, 570417217024]

theorem mother056_verified :
    mother056.length = 7 ∧
    allRowsFit 40 mother056 = true ∧
    distanceCheck 40 7 18 mother056 = true ∧
    evenCheck 40 7 mother056 = true ∧
    fullSupportCheck 40 mother056 = true ∧
    weight 40 (encode mother056 1) = 18 := by
  decide +kernel

def mother057 : List Nat := [262143, 134059828, 66613057962, 70780128716, 164900884494, 297818907120, 570417217024]

theorem mother057_verified :
    mother057.length = 7 ∧
    allRowsFit 40 mother057 = true ∧
    distanceCheck 40 7 18 mother057 = true ∧
    evenCheck 40 7 mother057 = true ∧
    fullSupportCheck 40 mother057 = true ∧
    weight 40 (encode mother057 1) = 18 := by
  decide +kernel

def mother058 : List Nat := [262143, 134185884, 66667074982, 70809999812, 164931772136, 297814712560, 570421411584]

theorem mother058_verified :
    mother058.length = 7 ∧
    allRowsFit 40 mother058 = true ∧
    distanceCheck 40 7 18 mother058 = true ∧
    evenCheck 40 7 mother058 = true ∧
    fullSupportCheck 40 mother058 = true ∧
    weight 40 (encode mother058 1) = 18 := by
  decide +kernel

def mother059 : List Nat := [262143, 134011446, 66666998490, 70809891692, 164931713936, 297814705120, 570421410816]

theorem mother059_verified :
    mother059.length = 7 ∧
    allRowsFit 40 mother059 = true ∧
    distanceCheck 40 7 18 mother059 = true ∧
    evenCheck 40 7 mother059 = true ∧
    fullSupportCheck 40 mother059 = true ∧
    weight 40 (encode mother059 1) = 18 := by
  decide +kernel

def mother060 : List Nat := [262143, 134140470, 66667000538, 70810018668, 164931713936, 297814705120, 570421410816]

theorem mother060_verified :
    mother060.length = 7 ∧
    allRowsFit 40 mother060 = true ∧
    distanceCheck 40 7 18 mother060 = true ∧
    evenCheck 40 7 mother060 = true ∧
    fullSupportCheck 40 mother060 = true ∧
    weight 40 (encode mother060 1) = 18 := by
  decide +kernel

def mother061 : List Nat := [262143, 134044310, 66667031212, 70810062906, 164931804364, 297814712560, 570421411584]

theorem mother061_verified :
    mother061.length = 7 ∧
    allRowsFit 40 mother061 = true ∧
    distanceCheck 40 7 18 mother061 = true ∧
    evenCheck 40 7 mother061 = true ∧
    fullSupportCheck 40 mother061 = true ∧
    weight 40 (encode mother061 1) = 18 := by
  decide +kernel

def mother062 : List Nat := [262143, 134017830, 66667063636, 70809979550, 164931777304, 297814705120, 570421410816]

theorem mother062_verified :
    mother062.length = 7 ∧
    allRowsFit 40 mother062 = true ∧
    distanceCheck 40 7 18 mother062 = true ∧
    evenCheck 40 7 mother062 = true ∧
    fullSupportCheck 40 mother062 = true ∧
    weight 40 (encode mother062 1) = 18 := by
  decide +kernel

def mother063 : List Nat := [262143, 134044554, 66667129628, 70810022430, 164931715024, 297814705120, 570421410816]

theorem mother063_verified :
    mother063.length = 7 ∧
    allRowsFit 40 mother063 = true ∧
    distanceCheck 40 7 18 mother063 = true ∧
    evenCheck 40 7 mother063 = true ∧
    fullSupportCheck 40 mother063 = true ∧
    weight 40 (encode mother063 1) = 18 := by
  decide +kernel

def mother064 : List Nat := [262143, 134044310, 66600012588, 70809997530, 164931771628, 297814712560, 570421411584]

theorem mother064_verified :
    mother064.length = 7 ∧
    allRowsFit 40 mother064 = true ∧
    distanceCheck 40 7 18 mother064 = true ∧
    evenCheck 40 7 mother064 = true ∧
    fullSupportCheck 40 mother064 = true ∧
    weight 40 (encode mother064 1) = 18 := by
  decide +kernel

def mother065 : List Nat := [262143, 134163546, 66599998882, 70809917660, 164931706592, 297814712560, 570421411584]

theorem mother065_verified :
    mother065.length = 7 ∧
    allRowsFit 40 mother065 = true ∧
    distanceCheck 40 7 18 mother065 = true ∧
    evenCheck 40 7 mother065 = true ∧
    fullSupportCheck 40 mother065 = true ∧
    weight 40 (encode mother065 1) = 18 := by
  decide +kernel

def mother066 : List Nat := [262143, 134098354, 66599933386, 70810048916, 164931772136, 297814712560, 570421411584]

theorem mother066_verified :
    mother066.length = 7 ∧
    allRowsFit 40 mother066 = true ∧
    distanceCheck 40 7 18 mother066 = true ∧
    evenCheck 40 7 mother066 = true ∧
    fullSupportCheck 40 mother066 = true ∧
    weight 40 (encode mother066 1) = 18 := by
  decide +kernel

def mother067 : List Nat := [262143, 134186286, 66599892170, 70809999756, 164931772136, 297814712560, 570421411584]

theorem mother067_verified :
    mother067.length = 7 ∧
    allRowsFit 40 mother067 = true ∧
    distanceCheck 40 7 18 mother067 = true ∧
    evenCheck 40 7 mother067 = true ∧
    fullSupportCheck 40 mother067 = true ∧
    weight 40 (encode mother067 1) = 18 := by
  decide +kernel

def mother068 : List Nat := [262143, 134157654, 66599875474, 70810052124, 164931714008, 297814705120, 570421410816]

theorem mother068_verified :
    mother068.length = 7 ∧
    allRowsFit 40 mother068 = true ∧
    distanceCheck 40 7 18 mother068 = true ∧
    evenCheck 40 7 mother068 = true ∧
    fullSupportCheck 40 mother068 = true ∧
    weight 40 (encode mother068 1) = 18 := by
  decide +kernel

def mother069 : List Nat := [262143, 134161772, 66599867578, 70810048964, 164931706616, 297814712560, 570421411584]

theorem mother069_verified :
    mother069.length = 7 ∧
    allRowsFit 40 mother069 = true ∧
    distanceCheck 40 7 18 mother069 = true ∧
    evenCheck 40 7 mother069 = true ∧
    fullSupportCheck 40 mother069 = true ∧
    weight 40 (encode mother069 1) = 18 := by
  decide +kernel

def mother070 : List Nat := [262143, 134157944, 66599936922, 70810055436, 164931582928, 297814705120, 570421410816]

theorem mother070_verified :
    mother070.length = 7 ∧
    allRowsFit 40 mother070 = true ∧
    distanceCheck 40 7 18 mother070 = true ∧
    evenCheck 40 7 mother070 = true ∧
    fullSupportCheck 40 mother070 = true ∧
    weight 40 (encode mother070 1) = 18 := by
  decide +kernel

def mother071 : List Nat := [262143, 134157628, 66599875222, 70810052424, 164931713936, 297814705120, 570421410816]

theorem mother071_verified :
    mother071.length = 7 ∧
    allRowsFit 40 mother071 = true ∧
    distanceCheck 40 7 18 mother071 = true ∧
    evenCheck 40 7 mother071 = true ∧
    fullSupportCheck 40 mother071 = true ∧
    weight 40 (encode mother071 1) = 18 := by
  decide +kernel

def mother072 : List Nat := [262143, 134171036, 66599856854, 70810055464, 164931715024, 297814705120, 570421410816]

theorem mother072_verified :
    mother072.length = 7 ∧
    allRowsFit 40 mother072 = true ∧
    distanceCheck 40 7 18 mother072 = true ∧
    evenCheck 40 7 mother072 = true ∧
    fullSupportCheck 40 mother072 = true ∧
    weight 40 (encode mother072 1) = 18 := by
  decide +kernel

def mother073 : List Nat := [262143, 134057396, 66599958978, 70810063244, 164931772136, 297814712560, 570421411584]

theorem mother073_verified :
    mother073.length = 7 ∧
    allRowsFit 40 mother073 = true ∧
    distanceCheck 40 7 18 mother073 = true ∧
    evenCheck 40 7 mother073 = true ∧
    fullSupportCheck 40 mother073 = true ∧
    weight 40 (encode mother073 1) = 18 := by
  decide +kernel

def mother074 : List Nat := [262143, 134155188, 66599893698, 70810063500, 164931706088, 297814712560, 570421411584]

theorem mother074_verified :
    mother074.length = 7 ∧
    allRowsFit 40 mother074 = true ∧
    distanceCheck 40 7 18 mother074 = true ∧
    evenCheck 40 7 mother074 = true ∧
    fullSupportCheck 40 mother074 = true ∧
    weight 40 (encode mother074 1) = 18 := by
  decide +kernel

def mother075 : List Nat := [262143, 134157940, 66676484018, 70837122392, 164933876124, 297818898912, 570417217024]

theorem mother075_verified :
    mother075.length = 7 ∧
    allRowsFit 40 mother075 = true ∧
    distanceCheck 40 7 18 mother075 = true ∧
    evenCheck 40 7 mother075 = true ∧
    fullSupportCheck 40 mother075 = true ∧
    weight 40 (encode mother075 1) = 18 := by
  decide +kernel

def mother076 : List Nat := [262143, 134065350, 66675293876, 70843025868, 164901359336, 297815765232, 570421411584]

theorem mother076_verified :
    mother076.length = 7 ∧
    allRowsFit 40 mother076 = true ∧
    distanceCheck 40 7 18 mother076 = true ∧
    evenCheck 40 7 mother076 = true ∧
    fullSupportCheck 40 mother076 = true ∧
    weight 40 (encode mother076 1) = 18 := by
  decide +kernel

def mother077 : List Nat := [262143, 134130254, 66675353274, 70843028252, 164901362640, 297815761888, 570421410816]

theorem mother077_verified :
    mother077.length = 7 ∧
    allRowsFit 40 mother077 = true ∧
    distanceCheck 40 7 18 mother077 = true ∧
    evenCheck 40 7 mother077 = true ∧
    fullSupportCheck 40 mother077 = true ∧
    weight 40 (encode mother077 1) = 18 := by
  decide +kernel

def mother078 : List Nat := [262143, 134059628, 66675358534, 70842997428, 164901397304, 297815753664, 570421410816]

theorem mother078_verified :
    mother078.length = 7 ∧
    allRowsFit 40 mother078 = true ∧
    distanceCheck 40 7 18 mother078 = true ∧
    evenCheck 40 7 mother078 = true ∧
    fullSupportCheck 40 mother078 = true ∧
    weight 40 (encode mother078 1) = 18 := by
  decide +kernel

def mother079 : List Nat := [262143, 134186158, 66675460762, 70843046610, 164901393180, 297815761888, 570421410816]

theorem mother079_verified :
    mother079.length = 7 ∧
    allRowsFit 40 mother079 = true ∧
    distanceCheck 40 7 18 mother079 = true ∧
    evenCheck 40 7 mother079 = true ∧
    fullSupportCheck 40 mother079 = true ∧
    weight 40 (encode mother079 1) = 18 := by
  decide +kernel

def mother080 : List Nat := [262143, 134071694, 66675494594, 70842996434, 164901394660, 297815761144, 570421411584]

theorem mother080_verified :
    mother080.length = 7 ∧
    allRowsFit 40 mother080 = true ∧
    distanceCheck 40 7 18 mother080 = true ∧
    evenCheck 40 7 mother080 = true ∧
    fullSupportCheck 40 mother080 = true ∧
    weight 40 (encode mother080 1) = 18 := by
  decide +kernel

def mother081 : List Nat := [262143, 134187598, 66675325142, 70843028118, 164901362916, 297815761144, 570421411584]

theorem mother081_verified :
    mother081.length = 7 ∧
    allRowsFit 40 mother081 = true ∧
    distanceCheck 40 7 18 mother081 = true ∧
    evenCheck 40 7 mother081 = true ∧
    fullSupportCheck 40 mother081 = true ∧
    weight 40 (encode mother081 1) = 18 := by
  decide +kernel

def mother082 : List Nat := [262143, 134126138, 66675390086, 70842997588, 164901381016, 297815737312, 570421410816]

theorem mother082_verified :
    mother082.length = 7 ∧
    allRowsFit 40 mother082 = true ∧
    distanceCheck 40 7 18 mother082 = true ∧
    evenCheck 40 7 mother082 = true ∧
    fullSupportCheck 40 mother082 = true ∧
    weight 40 (encode mother082 1) = 18 := by
  decide +kernel

def mother083 : List Nat := [262143, 134035116, 66675485338, 70843003602, 164901405468, 297815737312, 570421410816]

theorem mother083_verified :
    mother083.length = 7 ∧
    allRowsFit 40 mother083 = true ∧
    distanceCheck 40 7 18 mother083 = true ∧
    evenCheck 40 7 mother083 = true ∧
    fullSupportCheck 40 mother083 = true ∧
    weight 40 (encode mother083 1) = 18 := by
  decide +kernel

def mother084 : List Nat := [262143, 134109866, 66675307764, 70843018058, 164901368716, 297815753712, 570421410816]

theorem mother084_verified :
    mother084.length = 7 ∧
    allRowsFit 40 mother084 = true ∧
    distanceCheck 40 7 18 mother084 = true ∧
    evenCheck 40 7 mother084 = true ∧
    fullSupportCheck 40 mother084 = true ∧
    weight 40 (encode mother084 1) = 18 := by
  decide +kernel

def mother085 : List Nat := [262143, 134104686, 66694329658, 70846719370, 164908644812, 297802121712, 570417217024]

theorem mother085_verified :
    mother085.length = 7 ∧
    allRowsFit 40 mother085 = true ∧
    distanceCheck 40 7 18 mother085 = true ∧
    evenCheck 40 7 mother085 = true ∧
    fullSupportCheck 40 mother085 = true ∧
    weight 40 (encode mother085 1) = 18 := by
  decide +kernel

def mother086 : List Nat := [262143, 134132054, 66694206584, 70846716300, 164908638160, 297802129888, 570417217024]

theorem mother086_verified :
    mother086.length = 7 ∧
    allRowsFit 40 mother086 = true ∧
    distanceCheck 40 7 18 mother086 = true ∧
    evenCheck 40 7 mother086 = true ∧
    fullSupportCheck 40 mother086 = true ∧
    weight 40 (encode mother086 1) = 18 := by
  decide +kernel

def mother087 : List Nat := [262143, 134133126, 66694207666, 70846714708, 164908703128, 297802129888, 570417217024]

theorem mother087_verified :
    mother087.length = 7 ∧
    allRowsFit 40 mother087 = true ∧
    distanceCheck 40 7 18 mother087 = true ∧
    evenCheck 40 7 mother087 = true ∧
    fullSupportCheck 40 mother087 = true ∧
    weight 40 (encode mother087 1) = 18 := by
  decide +kernel

def mother088 : List Nat := [262143, 134112858, 66694359196, 70846755102, 164908514792, 297802121712, 570417217024]

theorem mother088_verified :
    mother088.length = 7 ∧
    allRowsFit 40 mother088 = true ∧
    distanceCheck 40 7 18 mother088 = true ∧
    evenCheck 40 7 mother088 = true ∧
    fullSupportCheck 40 mother088 = true ∧
    weight 40 (encode mother088 1) = 18 := by
  decide +kernel

def mother089 : List Nat := [262143, 134132278, 66694354090, 70846634300, 164908638160, 297802129888, 570417217024]

theorem mother089_verified :
    mother089.length = 7 ∧
    allRowsFit 40 mother089 = true ∧
    distanceCheck 40 7 18 mother089 = true ∧
    evenCheck 40 7 mother089 = true ∧
    fullSupportCheck 40 mother089 = true ∧
    weight 40 (encode mother089 1) = 18 := by
  decide +kernel

def mother090 : List Nat := [262143, 134177882, 66694228882, 70846624028, 164908645856, 297802121712, 570417217024]

theorem mother090_verified :
    mother090.length = 7 ∧
    allRowsFit 40 mother090 = true ∧
    distanceCheck 40 7 18 mother090 = true ∧
    evenCheck 40 7 mother090 = true ∧
    fullSupportCheck 40 mother090 = true ∧
    weight 40 (encode mother090 1) = 18 := by
  decide +kernel

def mother091 : List Nat := [262143, 133977724, 66694326106, 70846592424, 164908644812, 297802121712, 570417217024]

theorem mother091_verified :
    mother091.length = 7 ∧
    allRowsFit 40 mother091 = true ∧
    distanceCheck 40 7 18 mother091 = true ∧
    evenCheck 40 7 mother091 = true ∧
    fullSupportCheck 40 mother091 = true ∧
    weight 40 (encode mother091 1) = 18 := by
  decide +kernel

def mother092 : List Nat := [262143, 134157422, 66694229304, 70846675402, 164908741004, 297802121712, 570417217024]

theorem mother092_verified :
    mother092.length = 7 ∧
    allRowsFit 40 mother092 = true ∧
    distanceCheck 40 7 18 mother092 = true ∧
    evenCheck 40 7 mother092 = true ∧
    fullSupportCheck 40 mother092 = true ∧
    weight 40 (encode mother092 1) = 18 := by
  decide +kernel

def mother093 : List Nat := [262143, 134157940, 66694253746, 70846667096, 164908732828, 297802129888, 570417217024]

theorem mother093_verified :
    mother093.length = 7 ∧
    allRowsFit 40 mother093 = true ∧
    distanceCheck 40 7 18 mother093 = true ∧
    evenCheck 40 7 mother093 = true ∧
    fullSupportCheck 40 mother093 = true ∧
    weight 40 (encode mother093 1) = 18 := by
  decide +kernel

def mother094 : List Nat := [262143, 134092410, 66694229208, 70846691692, 164908708238, 297802121712, 570417217024]

theorem mother094_verified :
    mother094.length = 7 ∧
    allRowsFit 40 mother094 = true ∧
    distanceCheck 40 7 18 mother094 = true ∧
    evenCheck 40 7 mother094 = true ∧
    fullSupportCheck 40 mother094 = true ∧
    weight 40 (encode mother094 1) = 18 := by
  decide +kernel

def mother095 : List Nat := [262143, 134108774, 66694207818, 70846681996, 164908703184, 297802129888, 570417217024]

theorem mother095_verified :
    mother095.length = 7 ∧
    allRowsFit 40 mother095 = true ∧
    distanceCheck 40 7 18 mother095 = true ∧
    evenCheck 40 7 mother095 = true ∧
    fullSupportCheck 40 mother095 = true ∧
    weight 40 (encode mother095 1) = 18 := by
  decide +kernel

def mother096 : List Nat := [262143, 134090474, 66694327644, 70846572652, 164908708238, 297802121712, 570417217024]

theorem mother096_verified :
    mother096.length = 7 ∧
    allRowsFit 40 mother096 = true ∧
    distanceCheck 40 7 18 mother096 = true ∧
    evenCheck 40 7 mother096 = true ∧
    fullSupportCheck 40 mother096 = true ∧
    weight 40 (encode mother096 1) = 18 := by
  decide +kernel

def mother097 : List Nat := [262143, 134100708, 66680089198, 70826220728, 164921839822, 297814712560, 570421411584]

theorem mother097_verified :
    mother097.length = 7 ∧
    allRowsFit 40 mother097 = true ∧
    distanceCheck 40 7 18 mother097 = true ∧
    evenCheck 40 7 mother097 = true ∧
    fullSupportCheck 40 mother097 = true ∧
    weight 40 (encode mother097 1) = 18 := by
  decide +kernel

def mother098 : List Nat := [262143, 134121428, 66680113740, 70826267546, 164921744620, 297814712560, 570421411584]

theorem mother098_verified :
    mother098.length = 7 ∧
    allRowsFit 40 mother098 = true ∧
    distanceCheck 40 7 18 mother098 = true ∧
    evenCheck 40 7 mother098 = true ∧
    fullSupportCheck 40 mother098 = true ∧
    weight 40 (encode mother098 1) = 18 := by
  decide +kernel

def mother099 : List Nat := [262143, 134003878, 66680179082, 70826299820, 164921810632, 297814712560, 570421411584]

theorem mother099_verified :
    mother099.length = 7 ∧
    allRowsFit 40 mother099 = true ∧
    distanceCheck 40 7 18 mother099 = true ∧
    evenCheck 40 7 mother099 = true ∧
    fullSupportCheck 40 mother099 = true ∧
    weight 40 (encode mother099 1) = 18 := by
  decide +kernel

def mother100 : List Nat := [262143, 134177078, 66680105818, 70826143352, 164921750428, 297814705120, 570421410816]

theorem mother100_verified :
    mother100.length = 7 ∧
    allRowsFit 40 mother100 = true ∧
    distanceCheck 40 7 18 mother100 = true ∧
    evenCheck 40 7 mother100 = true ∧
    fullSupportCheck 40 mother100 = true ∧
    weight 40 (encode mother100 1) = 18 := by
  decide +kernel

def mother101 : List Nat := [262143, 134050418, 66680186522, 70826303708, 164921817880, 297814705120, 570421410816]

theorem mother101_verified :
    mother101.length = 7 ∧
    allRowsFit 40 mother101 = true ∧
    distanceCheck 40 7 18 mother101 = true ∧
    evenCheck 40 7 mother101 = true ∧
    fullSupportCheck 40 mother101 = true ∧
    weight 40 (encode mother101 1) = 18 := by
  decide +kernel

def mother102 : List Nat := [262143, 134056882, 66680163784, 70826266220, 164921856142, 297814712560, 570421411584]

theorem mother102_verified :
    mother102.length = 7 ∧
    allRowsFit 40 mother102 = true ∧
    distanceCheck 40 7 18 mother102 = true ∧
    evenCheck 40 7 mother102 = true ∧
    fullSupportCheck 40 mother102 = true ∧
    weight 40 (encode mother102 1) = 18 := by
  decide +kernel

def mother103 : List Nat := [262143, 134000308, 66680084182, 70826171034, 164921744620, 297814712560, 570421411584]

theorem mother103_verified :
    mother103.length = 7 ∧
    allRowsFit 40 mother103 = true ∧
    distanceCheck 40 7 18 mother103 = true ∧
    evenCheck 40 7 mother103 = true ∧
    fullSupportCheck 40 mother103 = true ∧
    weight 40 (encode mother103 1) = 18 := by
  decide +kernel

def mother104 : List Nat := [262143, 134170006, 66680114858, 70826235452, 164921809102, 297814712560, 570421411584]

theorem mother104_verified :
    mother104.length = 7 ∧
    allRowsFit 40 mother104 = true ∧
    distanceCheck 40 7 18 mother104 = true ∧
    evenCheck 40 7 mother104 = true ∧
    fullSupportCheck 40 mother104 = true ∧
    weight 40 (encode mother104 1) = 18 := by
  decide +kernel

def mother105 : List Nat := [262143, 134165158, 66680084922, 70826171096, 164921744620, 297814712560, 570421411584]

theorem mother105_verified :
    mother105.length = 7 ∧
    allRowsFit 40 mother105 = true ∧
    distanceCheck 40 7 18 mother105 = true ∧
    evenCheck 40 7 mother105 = true ∧
    fullSupportCheck 40 mother105 = true ∧
    weight 40 (encode mother105 1) = 18 := by
  decide +kernel

def mother106 : List Nat := [262143, 134063538, 66680170958, 70826266324, 164921848600, 297814705120, 570421410816]

theorem mother106_verified :
    mother106.length = 7 ∧
    allRowsFit 40 mother106 = true ∧
    distanceCheck 40 7 18 mother106 = true ∧
    evenCheck 40 7 mother106 = true ∧
    fullSupportCheck 40 mother106 = true ∧
    weight 40 (encode mother106 1) = 18 := by
  decide +kernel

def mother107 : List Nat := [262143, 134099828, 66667631726, 70838884518, 164930133704, 297814712560, 570421411584]

theorem mother107_verified :
    mother107.length = 7 ∧
    allRowsFit 40 mother107 = true ∧
    distanceCheck 40 7 18 mother107 = true ∧
    evenCheck 40 7 mother107 = true ∧
    fullSupportCheck 40 mother107 = true ∧
    weight 40 (encode mother107 1) = 18 := by
  decide +kernel

def mother108 : List Nat := [262143, 134112934, 66667457322, 70838726540, 164930139088, 297814705120, 570421410816]

theorem mother108_verified :
    mother108.length = 7 ∧
    allRowsFit 40 mother108 = true ∧
    distanceCheck 40 7 18 mother108 = true ∧
    evenCheck 40 7 mother108 = true ∧
    fullSupportCheck 40 mother108 = true ∧
    weight 40 (encode mother108 1) = 18 := by
  decide +kernel

def mother109 : List Nat := [262143, 134169942, 66667501962, 70838886972, 164930139088, 297814705120, 570421410816]

theorem mother109_verified :
    mother109.length = 7 ∧
    allRowsFit 40 mother109 = true ∧
    distanceCheck 40 7 18 mother109 = true ∧
    evenCheck 40 7 mother109 = true ∧
    fullSupportCheck 40 mother109 = true ∧
    weight 40 (encode mother109 1) = 18 := by
  decide +kernel

def mother110 : List Nat := [262143, 134057396, 66667550392, 70838887182, 164930206672, 297814705120, 570421410816]

theorem mother110_verified :
    mother110.length = 7 ∧
    allRowsFit 40 mother110 = true ∧
    distanceCheck 40 7 18 mother110 = true ∧
    evenCheck 40 7 mother110 = true ∧
    fullSupportCheck 40 mother110 = true ∧
    weight 40 (encode mother110 1) = 18 := by
  decide +kernel

def mother111 : List Nat := [262143, 134036054, 66667498852, 70838882702, 164930133704, 297814712560, 570421411584]

theorem mother111_verified :
    mother111.length = 7 ∧
    allRowsFit 40 mother111 = true ∧
    distanceCheck 40 7 18 mother111 = true ∧
    evenCheck 40 7 mother111 = true ∧
    fullSupportCheck 40 mother111 = true ∧
    weight 40 (encode mother111 1) = 18 := by
  decide +kernel

def mother112 : List Nat := [262143, 134164782, 66667502024, 70838754458, 164930133740, 297814712560, 570421411584]

theorem mother112_verified :
    mother112.length = 7 ∧
    allRowsFit 40 mother112 = true ∧
    distanceCheck 40 7 18 mother112 = true ∧
    evenCheck 40 7 mother112 = true ∧
    fullSupportCheck 40 mother112 = true ∧
    weight 40 (encode mother112 1) = 18 := by
  decide +kernel

def mother113 : List Nat := [262143, 134047442, 66599953244, 70805811740, 164931779480, 297814705120, 570421410816]

theorem mother113_verified :
    mother113.length = 7 ∧
    allRowsFit 40 mother113 = true ∧
    distanceCheck 40 7 18 mother113 = true ∧
    evenCheck 40 7 mother113 = true ∧
    fullSupportCheck 40 mother113 = true ∧
    weight 40 (encode mother113 1) = 18 := by
  decide +kernel

def mother114 : List Nat := [262143, 134066886, 66599954264, 70805829148, 164931713936, 297814705120, 570421410816]

theorem mother114_verified :
    mother114.length = 7 ∧
    allRowsFit 40 mother114 = true ∧
    distanceCheck 40 7 18 mother114 = true ∧
    evenCheck 40 7 mother114 = true ∧
    fullSupportCheck 40 mother114 = true ∧
    weight 40 (encode mother114 1) = 18 := by
  decide +kernel

def mother115 : List Nat := [262143, 134129478, 66599980760, 70805858964, 164931777304, 297814705120, 570421410816]

theorem mother115_verified :
    mother115.length = 7 ∧
    allRowsFit 40 mother115 = true ∧
    distanceCheck 40 7 18 mother115 = true ∧
    evenCheck 40 7 mother115 = true ∧
    fullSupportCheck 40 mother115 = true ∧
    weight 40 (encode mother115 1) = 18 := by
  decide +kernel

def mother116 : List Nat := [262143, 134060630, 66600020632, 70805828380, 164931715024, 297814705120, 570421410816]

theorem mother116_verified :
    mother116.length = 7 ∧
    allRowsFit 40 mother116 = true ∧
    distanceCheck 40 7 18 mother116 = true ∧
    evenCheck 40 7 mother116 = true ∧
    fullSupportCheck 40 mother116 = true ∧
    weight 40 (encode mother116 1) = 18 := by
  decide +kernel

def mother117 : List Nat := [262143, 134189654, 66599953082, 70805699372, 164931715024, 297814705120, 570421410816]

theorem mother117_verified :
    mother117.length = 7 ∧
    allRowsFit 40 mother117 = true ∧
    distanceCheck 40 7 18 mother117 = true ∧
    evenCheck 40 7 mother117 = true ∧
    fullSupportCheck 40 mother117 = true ∧
    weight 40 (encode mother117 1) = 18 := by
  decide +kernel

def mother118 : List Nat := [262143, 134189646, 66599953082, 70805698356, 164931714008, 297814705120, 570421410816]

theorem mother118_verified :
    mother118.length = 7 ∧
    allRowsFit 40 mother118 = true ∧
    distanceCheck 40 7 18 mother118 = true ∧
    evenCheck 40 7 mother118 = true ∧
    fullSupportCheck 40 mother118 = true ∧
    weight 40 (encode mother118 1) = 18 := by
  decide +kernel

def mother119 : List Nat := [262143, 134074710, 66599953772, 70805837450, 164931803276, 297814712560, 570421411584]

theorem mother119_verified :
    mother119.length = 7 ∧
    allRowsFit 40 mother119 = true ∧
    distanceCheck 40 7 18 mother119 = true ∧
    evenCheck 40 7 mother119 = true ∧
    fullSupportCheck 40 mother119 = true ∧
    weight 40 (encode mother119 1) = 18 := by
  decide +kernel

def mother120 : List Nat := [262143, 134063676, 66599875462, 70805859152, 164931711896, 297814705120, 570421410816]

theorem mother120_verified :
    mother120.length = 7 ∧
    allRowsFit 40 mother120 = true ∧
    distanceCheck 40 7 18 mother120 = true ∧
    evenCheck 40 7 mother120 = true ∧
    fullSupportCheck 40 mother120 = true ∧
    weight 40 (encode mother120 1) = 18 := by
  decide +kernel

def mother121 : List Nat := [262143, 134079246, 66600014954, 70805808724, 164931779480, 297814705120, 570421410816]

theorem mother121_verified :
    mother121.length = 7 ∧
    allRowsFit 40 mother121 = true ∧
    distanceCheck 40 7 18 mother121 = true ∧
    evenCheck 40 7 mother121 = true ∧
    fullSupportCheck 40 mother121 = true ∧
    weight 40 (encode mother121 1) = 18 := by
  decide +kernel

def mother122 : List Nat := [262143, 134076566, 66600012124, 70805811850, 164931771628, 297814712560, 570421411584]

theorem mother122_verified :
    mother122.length = 7 ∧
    allRowsFit 40 mother122 = true ∧
    distanceCheck 40 7 18 mother122 = true ∧
    evenCheck 40 7 mother122 = true ∧
    fullSupportCheck 40 mother122 = true ∧
    weight 40 (encode mother122 1) = 18 := by
  decide +kernel

def mother123 : List Nat := [262143, 134106488, 66600011420, 70805812266, 164931770572, 297814712560, 570421411584]

theorem mother123_verified :
    mother123.length = 7 ∧
    allRowsFit 40 mother123 = true ∧
    distanceCheck 40 7 18 mother123 = true ∧
    evenCheck 40 7 mother123 = true ∧
    fullSupportCheck 40 mother123 = true ∧
    weight 40 (encode mother123 1) = 18 := by
  decide +kernel

def mother124 : List Nat := [262143, 134106460, 66599945902, 70805845048, 164931803342, 297814712560, 570421411584]

theorem mother124_verified :
    mother124.length = 7 ∧
    allRowsFit 40 mother124 = true ∧
    distanceCheck 40 7 18 mother124 = true ∧
    evenCheck 40 7 mother124 = true ∧
    fullSupportCheck 40 mother124 = true ∧
    weight 40 (encode mother124 1) = 18 := by
  decide +kernel

def mother125 : List Nat := [262143, 134059256, 66660656994, 70844068524, 164906613552, 297799500736, 570421410816]

theorem mother125_verified :
    mother125.length = 7 ∧
    allRowsFit 40 mother125 = true ∧
    distanceCheck 40 7 18 mother125 = true ∧
    evenCheck 40 7 mother125 = true ∧
    fullSupportCheck 40 mother125 = true ∧
    weight 40 (encode mother125 1) = 18 := by
  decide +kernel

def mother126 : List Nat := [262143, 134186396, 66660784332, 70844082318, 164906602216, 297799512304, 570421411584]

theorem mother126_verified :
    mother126.length = 7 ∧
    allRowsFit 40 mother126 = true ∧
    distanceCheck 40 7 18 mother126 = true ∧
    evenCheck 40 7 mother126 = true ∧
    fullSupportCheck 40 mother126 = true ∧
    weight 40 (encode mother126 1) = 18 := by
  decide +kernel

def mother127 : List Nat := [262143, 134071916, 66660787378, 70844113978, 164906633404, 297799512256, 570421411584]

theorem mother127_verified :
    mother127.length = 7 ∧
    allRowsFit 40 mother127 = true ∧
    distanceCheck 40 7 18 mother127 = true ∧
    evenCheck 40 7 mother127 = true ∧
    fullSupportCheck 40 mother127 = true ∧
    weight 40 (encode mother127 1) = 18 := by
  decide +kernel

def mother128 : List Nat := [262143, 134157734, 66660685146, 70844065452, 164906613552, 297799500736, 570421410816]

theorem mother128_verified :
    mother128.length = 7 ∧
    allRowsFit 40 mother128 = true ∧
    distanceCheck 40 7 18 mother128 = true ∧
    evenCheck 40 7 mother128 = true ∧
    fullSupportCheck 40 mother128 = true ∧
    weight 40 (encode mother128 1) = 18 := by
  decide +kernel

def mother129 : List Nat := [262143, 134063766, 66660814008, 70844050604, 164906633422, 297799512304, 570421411584]

theorem mother129_verified :
    mother129.length = 7 ∧
    allRowsFit 40 mother129 = true ∧
    distanceCheck 40 7 18 mother129 = true ∧
    evenCheck 40 7 mother129 = true ∧
    fullSupportCheck 40 mother129 = true ∧
    weight 40 (encode mother129 1) = 18 := by
  decide +kernel

def mother130 : List Nat := [262143, 134011346, 66679632228, 70793794198, 164902411494, 297815761144, 570421411584]

theorem mother130_verified :
    mother130.length = 7 ∧
    allRowsFit 40 mother130 = true ∧
    distanceCheck 40 7 18 mother130 = true ∧
    evenCheck 40 7 mother130 = true ∧
    fullSupportCheck 40 mother130 = true ∧
    weight 40 (encode mother130 1) = 18 := by
  decide +kernel

def mother131 : List Nat := [262143, 134101842, 66679685526, 70793775514, 164902441500, 297815761888, 570421410816]

theorem mother131_verified :
    mother131.length = 7 ∧
    allRowsFit 40 mother131 = true ∧
    distanceCheck 40 7 18 mother131 = true ∧
    evenCheck 40 7 mother131 = true ∧
    fullSupportCheck 40 mother131 = true ∧
    weight 40 (encode mother131 1) = 18 := by
  decide +kernel

def mother132 : List Nat := [262143, 134015788, 66679652694, 70793742934, 164902433688, 297815737312, 570421410816]

theorem mother132_verified :
    mother132.length = 7 ∧
    allRowsFit 40 mother132 = true ∧
    distanceCheck 40 7 18 mother132 = true ∧
    evenCheck 40 7 mother132 = true ∧
    fullSupportCheck 40 mother132 = true ∧
    weight 40 (encode mother132 1) = 18 := by
  decide +kernel

def mother133 : List Nat := [262143, 134048310, 66679621274, 70793713362, 164902443804, 297815761888, 570421410816]

theorem mother133_verified :
    mother133.length = 7 ∧
    allRowsFit 40 mother133 = true ∧
    distanceCheck 40 7 18 mother133 = true ∧
    evenCheck 40 7 mother133 = true ∧
    fullSupportCheck 40 mother133 = true ∧
    weight 40 (encode mother133 1) = 18 := by
  decide +kernel

def mother134 : List Nat := [262143, 134106822, 66679523450, 70793655186, 164902363932, 297815737312, 570421410816]

theorem mother134_verified :
    mother134.length = 7 ∧
    allRowsFit 40 mother134 = true ∧
    distanceCheck 40 7 18 mother134 = true ∧
    evenCheck 40 7 mother134 = true ∧
    fullSupportCheck 40 mother134 = true ∧
    weight 40 (encode mother134 1) = 18 := by
  decide +kernel

def mother135 : List Nat := [262143, 134096602, 66621459272, 70787962220, 164900313486, 297818907120, 570417217024]

theorem mother135_verified :
    mother135.length = 7 ∧
    allRowsFit 40 mother135 = true ∧
    distanceCheck 40 7 18 mother135 = true ∧
    evenCheck 40 7 mother135 = true ∧
    fullSupportCheck 40 mother135 = true ∧
    weight 40 (encode mother135 1) = 18 := by
  decide +kernel

def mother136 : List Nat := [262143, 134130282, 66604683940, 70842490036, 164898217672, 297814712560, 570421411584]

theorem mother136_verified :
    mother136.length = 7 ∧
    allRowsFit 40 mother136 = true ∧
    distanceCheck 40 7 18 mother136 = true ∧
    evenCheck 40 7 mother136 = true ∧
    fullSupportCheck 40 mother136 = true ∧
    weight 40 (encode mother136 1) = 18 := by
  decide +kernel

def mother137 : List Nat := [262143, 134066854, 66652907412, 70843578196, 164906023832, 297798976480, 570421410816]

theorem mother137_verified :
    mother137.length = 7 ∧
    allRowsFit 40 mother137 = true ∧
    distanceCheck 40 7 18 mother137 = true ∧
    evenCheck 40 7 mother137 = true ∧
    fullSupportCheck 40 mother137 = true ∧
    weight 40 (encode mother137 1) = 18 := by
  decide +kernel

def mother138 : List Nat := [262143, 134071898, 66652918444, 70843580590, 164906113840, 297798984640, 570421410816]

theorem mother138_verified :
    mother138.length = 7 ∧
    allRowsFit 40 mother138 = true ∧
    distanceCheck 40 7 18 mother138 = true ∧
    evenCheck 40 7 mother138 = true ∧
    fullSupportCheck 40 mother138 = true ∧
    weight 40 (encode mother138 1) = 18 := by
  decide +kernel

def mother139 : List Nat := [262143, 134010538, 66681661132, 70844651654, 164898151672, 297814712560, 570421411584]

theorem mother139_verified :
    mother139.length = 7 ∧
    allRowsFit 40 mother139 = true ∧
    distanceCheck 40 7 18 mother139 = true ∧
    evenCheck 40 7 mother139 = true ∧
    fullSupportCheck 40 mother139 = true ∧
    weight 40 (encode mother139 1) = 18 := by
  decide +kernel

def mother140 : List Nat := [262143, 134113964, 66681631572, 70844455832, 164898218782, 297814705120, 570421410816]

theorem mother140_verified :
    mother140.length = 7 ∧
    allRowsFit 40 mother140 = true ∧
    distanceCheck 40 7 18 mother140 = true ∧
    evenCheck 40 7 mother140 = true ∧
    fullSupportCheck 40 mother140 = true ∧
    weight 40 (encode mother140 1) = 18 := by
  decide +kernel

def mother141 : List Nat := [262143, 134187322, 66681629516, 70844494456, 164898160528, 297814705120, 570421410816]

theorem mother141_verified :
    mother141.length = 7 ∧
    allRowsFit 40 mother141 = true ∧
    distanceCheck 40 7 18 mother141 = true ∧
    evenCheck 40 7 mother141 = true ∧
    fullSupportCheck 40 mother141 = true ∧
    weight 40 (encode mother141 1) = 18 := by
  decide +kernel

def mother142 : List Nat := [262143, 134114118, 66681746074, 70815098652, 164835310480, 297814705120, 570421410816]

theorem mother142_verified :
    mother142.length = 7 ∧
    allRowsFit 40 mother142 = true ∧
    distanceCheck 40 7 18 mother142 = true ∧
    evenCheck 40 7 mother142 = true ∧
    fullSupportCheck 40 mother142 = true ∧
    weight 40 (encode mother142 1) = 18 := by
  decide +kernel

def mother143 : List Nat := [262143, 134125812, 66631412026, 70778565196, 164898160528, 297814705120, 570421410816]

theorem mother143_verified :
    mother143.length = 7 ∧
    allRowsFit 40 mother143 = true ∧
    distanceCheck 40 7 18 mother143 = true ∧
    evenCheck 40 7 mother143 = true ∧
    fullSupportCheck 40 mother143 = true ∧
    weight 40 (encode mother143 1) = 18 := by
  decide +kernel

def mother144 : List Nat := [262143, 134048934, 66664879576, 70826695156, 164929609448, 297814712560, 570421411584]

theorem mother144_verified :
    mother144.length = 7 ∧
    allRowsFit 40 mother144 = true ∧
    distanceCheck 40 7 18 mother144 = true ∧
    evenCheck 40 7 mother144 = true ∧
    fullSupportCheck 40 mother144 = true ∧
    weight 40 (encode mother144 1) = 18 := by
  decide +kernel

def mother145 : List Nat := [262143, 134071100, 66664961720, 70826812590, 164929706188, 297814712560, 570421411584]

theorem mother145_verified :
    mother145.length = 7 ∧
    allRowsFit 40 mother145 = true ∧
    distanceCheck 40 7 18 mother145 = true ∧
    evenCheck 40 7 mother145 = true ∧
    fullSupportCheck 40 mother145 = true ∧
    weight 40 (encode mother145 1) = 18 := by
  decide +kernel

def mother146 : List Nat := [262143, 134066522, 66664958936, 70826840732, 164929674472, 297814712560, 570421411584]

theorem mother146_verified :
    mother146.length = 7 ∧
    allRowsFit 40 mother146 = true ∧
    distanceCheck 40 7 18 mother146 = true ∧
    evenCheck 40 7 mother146 = true ∧
    fullSupportCheck 40 mother146 = true ∧
    weight 40 (encode mother146 1) = 18 := by
  decide +kernel

def mother147 : List Nat := [262143, 134164826, 66664877016, 70826758812, 164929674472, 297814712560, 570421411584]

theorem mother147_verified :
    mother147.length = 7 ∧
    allRowsFit 40 mother147 = true ∧
    distanceCheck 40 7 18 mother147 = true ∧
    evenCheck 40 7 mother147 = true ∧
    fullSupportCheck 40 mother147 = true ∧
    weight 40 (encode mother147 1) = 18 := by
  decide +kernel

def mother148 : List Nat := [262143, 134043996, 66678060174, 70811556054, 164923907816, 297814712560, 570421411584]

theorem mother148_verified :
    mother148.length = 7 ∧
    allRowsFit 40 mother148 = true ∧
    distanceCheck 40 7 18 mother148 = true ∧
    evenCheck 40 7 mother148 = true ∧
    fullSupportCheck 40 mother148 = true ∧
    weight 40 (encode mother148 1) = 18 := by
  decide +kernel

def mother149 : List Nat := [262143, 134035050, 66678045364, 70811546328, 164923941662, 297814705120, 570421410816]

theorem mother149_verified :
    mother149.length = 7 ∧
    allRowsFit 40 mother149 = true ∧
    distanceCheck 40 7 18 mother149 = true ∧
    evenCheck 40 7 mother149 = true ∧
    fullSupportCheck 40 mother149 = true ∧
    weight 40 (encode mother149 1) = 18 := by
  decide +kernel

def mother150 : List Nat := [262143, 134057684, 66636130660, 70755495014, 164909789574, 297803170296, 570417217024]

theorem mother150_verified :
    mother150.length = 7 ∧
    allRowsFit 40 mother150 = true ∧
    distanceCheck 40 7 18 mother150 = true ∧
    evenCheck 40 7 mother150 = true ∧
    fullSupportCheck 40 mother150 = true ∧
    weight 40 (encode mother150 1) = 18 := by
  decide +kernel

def mother151 : List Nat := [262143, 134110546, 66637157030, 70819947868, 164924963224, 297803170272, 570417217024]

theorem mother151_verified :
    mother151.length = 7 ∧
    allRowsFit 40 mother151 = true ∧
    distanceCheck 40 7 18 mother151 = true ∧
    evenCheck 40 7 mother151 = true ∧
    fullSupportCheck 40 mother151 = true ∧
    weight 40 (encode mother151 1) = 18 := by
  decide +kernel

def mother152 : List Nat := [262143, 134061170, 66637150388, 70819982552, 164924997918, 297803182560, 570417217024]

theorem mother152_verified :
    mother152.length = 7 ∧
    allRowsFit 40 mother152 = true ∧
    distanceCheck 40 7 18 mother152 = true ∧
    evenCheck 40 7 mother152 = true ∧
    fullSupportCheck 40 mother152 = true ∧
    weight 40 (encode mother152 1) = 18 := by
  decide +kernel

def mother153 : List Nat := [262143, 134154038, 66627259000, 70819929432, 164892479900, 297802129888, 570417217024]

theorem mother153_verified :
    mother153.length = 7 ∧
    allRowsFit 40 mother153 = true ∧
    distanceCheck 40 7 18 mother153 = true ∧
    evenCheck 40 7 mother153 = true ∧
    fullSupportCheck 40 mother153 = true ∧
    weight 40 (encode mother153 1) = 18 := by
  decide +kernel

def mother154 : List Nat := [262143, 134122684, 66627196280, 70820010062, 164892450704, 297802129888, 570417217024]

theorem mother154_verified :
    mother154.length = 7 ∧
    allRowsFit 40 mother154 = true ∧
    distanceCheck 40 7 18 mother154 = true ∧
    evenCheck 40 7 mother154 = true ∧
    fullSupportCheck 40 mother154 = true ∧
    weight 40 (encode mother154 1) = 18 := by
  decide +kernel

def mother155 : List Nat := [262143, 134059372, 66677466850, 70807362356, 164897694648, 297815753664, 570421410816]

theorem mother155_verified :
    mother155.length = 7 ∧
    allRowsFit 40 mother155 = true ∧
    distanceCheck 40 7 18 mother155 = true ∧
    evenCheck 40 7 mother155 = true ∧
    fullSupportCheck 40 mother155 = true ∧
    weight 40 (encode mother155 1) = 18 := by
  decide +kernel

def mother156 : List Nat := [262143, 134161980, 66677467880, 70807276374, 164897649560, 297815737312, 570421410816]

theorem mother156_verified :
    mother156.length = 7 ∧
    allRowsFit 40 mother156 = true ∧
    distanceCheck 40 7 18 mother156 = true ∧
    evenCheck 40 7 mother156 = true ∧
    fullSupportCheck 40 mother156 = true ∧
    weight 40 (encode mother156 1) = 18 := by
  decide +kernel

def mother157 : List Nat := [262143, 134187406, 66677430968, 70807360214, 164897692900, 297815761144, 570421411584]

theorem mother157_verified :
    mother157.length = 7 ∧
    allRowsFit 40 mother157 = true ∧
    distanceCheck 40 7 18 mother157 = true ∧
    evenCheck 40 7 mother157 = true ∧
    fullSupportCheck 40 mother157 = true ∧
    weight 40 (encode mother157 1) = 18 := by
  decide +kernel

def mother158 : List Nat := [262143, 134162034, 66677549912, 70807368284, 164897700768, 297815753664, 570421410816]

theorem mother158_verified :
    mother158.length = 7 ∧
    allRowsFit 40 mother158 = true ∧
    distanceCheck 40 7 18 mother158 = true ∧
    evenCheck 40 7 mother158 = true ∧
    fullSupportCheck 40 mother158 = true ∧
    weight 40 (encode mother158 1) = 18 := by
  decide +kernel

def mother159 : List Nat := [262143, 134101562, 66690020194, 70828217162, 164851049356, 297798960112, 570421410816]

theorem mother159_verified :
    mother159.length = 7 ∧
    allRowsFit 40 mother159 = true ∧
    distanceCheck 40 7 18 mother159 = true ∧
    evenCheck 40 7 mother159 = true ∧
    fullSupportCheck 40 mother159 = true ∧
    weight 40 (encode mother159 1) = 18 := by
  decide +kernel

def mother160 : List Nat := [262143, 134187606, 66657528250, 70807376588, 164930198752, 297814712560, 570421411584]

theorem mother160_verified :
    mother160.length = 7 ∧
    allRowsFit 40 mother160 = true ∧
    distanceCheck 40 7 18 mother160 = true ∧
    evenCheck 40 7 mother160 = true ∧
    fullSupportCheck 40 mother160 = true ∧
    weight 40 (encode mother160 1) = 18 := by
  decide +kernel

def mother161 : List Nat := [262143, 134163030, 66682705626, 70814701932, 164908178864, 297803178432, 570417217024]

theorem mother161_verified :
    mother161.length = 7 ∧
    allRowsFit 40 mother161 = true ∧
    distanceCheck 40 7 18 mother161 = true ∧
    evenCheck 40 7 mother161 = true ∧
    fullSupportCheck 40 mother161 = true ∧
    weight 40 (encode mother161 1) = 18 := by
  decide +kernel

def mother162 : List Nat := [262143, 134186582, 66682697626, 70814718236, 164908178912, 297803178480, 570417217024]

theorem mother162_verified :
    mother162.length = 7 ∧
    allRowsFit 40 mother162 = true ∧
    distanceCheck 40 7 18 mother162 = true ∧
    evenCheck 40 7 mother162 = true ∧
    fullSupportCheck 40 mother162 = true ∧
    weight 40 (encode mother162 1) = 18 := by
  decide +kernel

def mother163 : List Nat := [262143, 134101116, 68241903254, 99216446250, 165674181580, 293884625904, 574972230656]

theorem mother163_verified :
    mother163.length = 7 ∧
    allRowsFit 40 mother163 = true ∧
    distanceCheck 40 7 18 mother163 = true ∧
    evenCheck 40 7 mother163 = true ∧
    fullSupportCheck 40 mother163 = true ∧
    weight 40 (encode mother163 1) = 18 := by
  decide +kernel

def mother164 : List Nat := [262143, 134137674, 68233637094, 99247924564, 165655333272, 293901431264, 574955453952]

theorem mother164_verified :
    mother164.length = 7 ∧
    allRowsFit 40 mother164 = true ∧
    distanceCheck 40 7 18 mother164 = true ∧
    evenCheck 40 7 mother164 = true ∧
    fullSupportCheck 40 mother164 = true ∧
    weight 40 (encode mother164 1) = 18 := by
  decide +kernel

def mother165 : List Nat := [16718208209, 208029711762, 371387055892, 117369154072, 1016883624032, 58427111824, 1008609955728]

theorem mother165_verified :
    mother165.length = 7 ∧
    allRowsFit 40 mother165 = true ∧
    distanceCheck 40 7 18 mother165 = true ∧
    evenCheck 40 7 mother165 = true ∧
    fullSupportCheck 40 mother165 = true ∧
    weight 40 (encode mother165 32) = 18 := by
  decide +kernel

def mother166 : List Nat := [262143, 134042270, 68504102714, 101153190444, 165043387344, 306123621344, 570685651968]

theorem mother166_verified :
    mother166.length = 7 ∧
    allRowsFit 40 mother166 = true ∧
    distanceCheck 40 7 18 mother166 = true ∧
    evenCheck 40 7 mother166 = true ∧
    fullSupportCheck 40 mother166 = true ∧
    weight 40 (encode mother166 1) = 18 := by
  decide +kernel

def mother167 : List Nat := [262143, 134106714, 68504168550, 101153190540, 165043387632, 306123620600, 570685652736]

theorem mother167_verified :
    mother167.length = 7 ∧
    allRowsFit 40 mother167 = true ∧
    distanceCheck 40 7 18 mother167 = true ∧
    evenCheck 40 7 mother167 = true ∧
    fullSupportCheck 40 mother167 = true ∧
    weight 40 (encode mother167 1) = 18 := by
  decide +kernel

def mother168 : List Nat := [262143, 133979814, 68504202074, 101153092364, 165043388304, 306123621344, 570685651968]

theorem mother168_verified :
    mother168.length = 7 ∧
    allRowsFit 40 mother168 = true ∧
    distanceCheck 40 7 18 mother168 = true ∧
    evenCheck 40 7 mother168 = true ∧
    fullSupportCheck 40 mother168 = true ∧
    weight 40 (encode mother168 1) = 18 := by
  decide +kernel

def mother169 : List Nat := [262143, 134010706, 68485759594, 101139519308, 165064940528, 297950503808, 570018757632]

theorem mother169_verified :
    mother169.length = 7 ∧
    allRowsFit 40 mother169 = true ∧
    distanceCheck 40 7 18 mother169 = true ∧
    evenCheck 40 7 mother169 = true ∧
    fullSupportCheck 40 mother169 = true ∧
    weight 40 (encode mother169 1) = 18 := by
  decide +kernel

def mother170 : List Nat := [4194303, 34351769876, 51276131930, 83994283116, 147864145840, 280707731392, 553463574528]

theorem mother170_verified :
    mother170.length = 7 ∧
    allRowsFit 40 mother170 = true ∧
    distanceCheck 40 7 18 mother170 = true ∧
    evenCheck 40 7 mother170 = true ∧
    fullSupportCheck 40 mother170 = true ∧
    weight 40 (encode mother170 5) = 18 := by
  decide +kernel

def mother171 : List Nat := [1095233376015, 1099494854640, 1099511623680, 847806907750, 454355109546, 612281133731, 1034834463948]

theorem mother171_verified :
    mother171.length = 7 ∧
    allRowsFit 40 mother171 = true ∧
    distanceCheck 40 7 18 mother171 = true ∧
    evenCheck 40 7 mother171 = true ∧
    fullSupportCheck 40 mother171 = true ∧
    weight 40 (encode mother171 24) = 18 := by
  decide +kernel

end ECC.Packed
