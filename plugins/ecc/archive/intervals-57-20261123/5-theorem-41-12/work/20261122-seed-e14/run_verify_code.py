import sys, json
sys.path.insert(0,"/home/user/math/aris4math_v2/ecc_mathagent_harness_20260929/project")
from mathagent_ecc.verifier import verify_code
from mathagent_ecc.specs import ExpandedCode
lines=[l.strip() for l in open("generator_12x41.txt") if l.strip()]
rows=tuple(sum(1<<j for j,ch in enumerate(l) if ch=="1") for l in lines)
exp=ExpandedCode(rows=rows,n=41,k=12)
rep=verify_code(exp,target_distance=14,exact_dimension_limit=22,field=2,
  exact_after_probe_counterexample=True,collect_weight_distribution=True)
d=rep.to_dict()
d["weight_distribution_explicit"]=[list(t) for t in rep.weight_distribution] if rep.weight_distribution else None
d["weight_distribution_total"]=sum(c for _,c in rep.weight_distribution) if rep.weight_distribution else None
print(json.dumps(d,indent=1))
json.dump(d,open("verify_code_output.json","w"),indent=1)
