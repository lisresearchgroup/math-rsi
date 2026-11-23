(() => {
'use strict';
const NS = 'http://www.w3.org/2000/svg';
const GH = 'https://github.com/lisresearchgroup/math-rsi';
const REPO = '../../../';
const Q7_TIME = 8100;
const DD_TIME = 8500;
const E86_V6_TIME = 10300;
const Q7_E16_TIME = 10950;
const HE_V6_TIME = 11180;
const Q7_FULL_TIME = 12600;
const HE_V7_TIME = 12900;
const ECC_V8_TIME = 14600;
const ECC_PAPER = REPO + 'plugins/ecc/archive/source/paper/main.pdf';
const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const clamp = x => x < 0 ? 0 : x > 1 ? 1 : x;
const f1 = n => n.toFixed(1);
const E = {
  out: x => 1 - Math.pow(1 - x, 3),
  io: x => x < .5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2,
  back: x => { const c = 1.5; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); }
};
function el(tag, attrs, parent) {
  const e = document.createElementNS(NS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  if (parent) parent.appendChild(e);
  return e;
}

/* ------------------------------------------------------------------ data */
const CASES = [
  { id: 'pb', short: 'Property B', title: 'Stronger guarantees for hypergraph coloring',
    status: 'Uniform k ≥ 12 theorem in Lean · small k scoped per parameter',
    read: REPO + 'case-studies/property-b/index.html', plugin: GH + '/tree/main/plugins/propertyb',
    quant: () => `<div class="qrow">${[35,67,131,267,543,1112,2275,4664].map((v,i)=>`<span><b>${v}</b><i>k = ${i+5}</i></span>`).join('')}</div><p class="qnote">Lower bounds on m(k), plus a uniform gain for every k ≥ 12.</p>` },
  { id: 'ecc', short: 'ECC', title: () => t >= ECC_V8_TIME ? 'From 4 to 13 exact code distances' : 'From three exact code distances to four',
    status: () => t >= ECC_V8_TIME ? 'v8 · 2 working upper bounds pending source-owner acceptance' : 'Exact distances · 45/11 remains open',
    read: () => t >= ECC_V8_TIME ? 'ecc-intervals.html' : ECC_PAPER, plugin: GH + '/tree/main/plugins/ecc',
    quant: () => t >= ECC_V8_TIME ? `<div class="qrow"><span><b>18</b><i>new lower bounds</i></span><span><b>32</b><i>new upper-bound deductions</i></span><span><b>57</b><i>total intervals</i></span></div><p class="qnote">MathRSI settled three settings in v0 and one more by v2. In v8, it connected published exclusions to known codes and settled nine more in one round.</p>` : `<p class="q-closed">${t >= 3400 ? '4' : '3'} exact optimal distances</p><div class="qrow">${[['43,10','16'],['44,10','17'],['44,11','16'],...(t >= 3400 ? [['42,16','12']] : [])].map(([p,v])=>`<span><b>${v}</b><i>d₂(${p})</i></span>`).join('')}<span class="open"><b>16–17</b><i>d₂(45,11) · open</i></span></div><p class="qnote">For each code length n and dimension k, d₂(n,k) is the largest achievable minimum distance. “Exact” means a construction meets the upper bound. ${t >= 3400 ? 'The fourth value, d₂(42,16)=12, applies a published 2020 theorem.' : 'The original exclusion fixes the three values shown.'}</p>` },
  { id: 'dd', short: 'Degree–Diameter', title: 'Our best constructions by setting',
    status: () => t >= DD_TIME ? 'Four showcased settings · D5 end-to-end Lean open' : t >= 6750 ? 'New (10,4) result produced with MathRSI v2 + DD' : 'Three dated table comparisons from earlier research',
    read: () => t >= DD_TIME ? 'dd-latest.html' : 'dd-10-4.html', plugin: GH + '/tree/main/plugins/degree-diameter',
    quant: () => t >= DD_TIME ? `<div class="qlist">${[['(10,4)','','2,567'],['(11,5)','37,631','37,632'],['(12,5)','42,402','42,433'],['(16,4)','','16,416']].map(([p,a,b])=>`<div${a ? ' class="is-new"' : ''}><i>${p}</i><span class="prev">${a}</span><span>${a ? '→' : ''}</span><b>${b}</b></div>`).join('')}</div><p class="qnote">D5 local increases: (11,5) +1; (12,5) +31.</p><p class="qnote">D5 Comellas comparison, 2026-11-16: (11,5) 37,631 → 37,632 (+1); (12,5) 42,352 → 42,433 (+81).</p><p class="qnote">Latest D5 run: v4 + local updates → v5 main maintenance.</p>` : `<div class="qlist">${[...(t >= 6750 ? [['(10,4)','2,566','2,567',true]] : []),['(11,5)','37,628','37,631'],['(12,5)','42,342','42,402'],['(16,4)','16,384','16,416']].map(([p,a,b,n])=>`<div${n ? ' class="is-new"' : ''}><i>${p}</i><span class="prev">${a}</span><span>→</span><b>${b}</b></div>`).join('')}</div><p class="qnote">${t >= 6750 ? 'Comellas comparisons rechecked 2026-11-05. Historical catalogue: 163 graphs / 44 parameter pairs / 49 concrete-graph Lean instances.' : 'Comellas comparisons rechecked 2026-11-05. Earlier catalogue: 153 graphs / 43 parameter pairs / 47 concrete-graph Lean instances.'}</p>` },
  { id: 'e86', short: 'Erdős 86', title: () => t >= E86_V6_TIME ? 'Finite and asymptotic bounds for C₄-free cubes' : 'A tighter ceiling for square-free hypercube graphs',
    status: () => t >= E86_V6_TIME ? 'Computer-assisted bounds · no Lean' : 'Exact certificate · no Lean',
    read: () => t >= E86_V6_TIME ? 'erdos-86-latest.html' : REPO + 'plugins/hypercube-extremal/archive/source/START_HERE.html', plugin: GH + '/tree/main/plugins/hypercube-extremal',
    quant: () => t >= E86_V6_TIME ? `<div class="qrow"><span><b>304</b><i>Q₇ · ≤304 source</i></span><span><b>682–683</b><i>Q₈ · 682 open</i></span><span><b>≤ 0.5912405943</b><i>Q∞ (T3)</i></span></div><p class="qnote">Q₇: 304-edge construction verified; 304 upper bound as reported in the source package, not re-verified in this pass. Q₈: four 682-edge constructions + Theorem B (refereeing pending). Q∞: T3 and T4 ≤ 0.5912405942 proved. Limit 1/2 remains open.</p>` : `<div class="qbig"><span class="prev">0.60318</span><span>→</span><b>≤ 0.59155154</b></div><p class="qnote">Asymptotic edge density of C₄-free subgraphs of Qₙ; the conjectured 1/2 remains open.</p>` },
  { id: 'q6', short: 'Ruskey–Savage', title: () => t >= Q7_FULL_TIME ? 'Every matching in Q₇ extends' : t >= Q7_TIME ? 'From Q₆ to dense Q₇ matchings' : 'Every matching in Q₆ extends to a Hamilton cycle',
    status: () => t >= Q7_FULL_TIME ? 'Full author working proof · external review pending' : t >= Q7_E16_TIME ? 'Q₇ ≥56-edge theorem (E16) · full Q₇ open' : t >= Q7_TIME ? 'Q₇ ≥57-edge theorem · full Q₇ open' : 'Computational proof · refereeing pending',
    read: () => t >= Q7_TIME ? 'q7.html' : REPO + 'plugins/hypercube-hamilton/archive/source/Ruskey-Savage_Q6_研究报告.html', plugin: GH + '/tree/main/plugins/hypercube-hamilton',
    quant: () => `${t >= Q7_FULL_TIME ? '<div class="qbig"><b>Q₇ · every matching</b></div><p class="qnote">128 vertices; every matching size, including empty and perfect matchings. Full R7 author working proof accepted in the source project on 2026-11-19; external peer review pending, no Lean. Run: v3 (local adaptation) → v6 main follow-up.</p><a href="q7.html">Q7 result & methods ↗</a><p class="p-eye">Q₆ evidence</p>' : t >= Q7_E16_TIME ? '<div class="qbig"><b>Q₇ · ≥56 edges</b></div><p class="qnote">128 vertices; complete E16 across all 16-hole classes μ ∈ {0,1,2,3,4}. Run: v3 (local adaptation) → informs v5 & v6. Matchings with ≤55 edges and full Q₇ remain open.</p><a href="q7.html">Q7 result & methods ↗</a><p class="p-eye">Q₆ evidence</p>' : t >= Q7_TIME ? '<div class="qbig"><b>Q₇ · ≥57 edges</b></div><p class="qnote">128 vertices; every prescribed edge retained. Run: v3 (local adaptation) → informs v5. Full Q₇ remains open.</p><a href="q7.html">Q7 result & methods ↗</a><p class="p-eye">Q₆ evidence</p>' : ''}<div class="qrow"><span><b>64</b><i>vertices</i></span><span><b>1024</b><i>forests</i></span><span><b>1024</b><i>rank</i></span></div><p class="qnote">The prescribed-endpoint P₆ path theorem and published lifting results cover matchings using ≤ 6 directions in any dimension.</p>` },
  { id: 'he', short: 'Happy Ending', title: () => t >= HE_V7_TIME ? 'Signotope capacities and planar bounds across m = 7–10' : t >= HE_V6_TIME ? 'Signotope capacities and m = 7–9 thresholds' : 'A tighter upper bound for convex heptagons',
    status: () => t >= HE_V7_TIME ? 'Bounded macOS replay passed · mathematical review pending' : t >= HE_V6_TIME ? 'Replayed duals/DRAT · assembly review pending' : '75/76/77 working manuscripts · independent review pending',
    read: () => t >= HE_V6_TIME ? 'happy-ending-latest.html' : REPO + 'case-studies/happy-ending/n7-20261103/START_HERE.html', plugin: GH + '/tree/main/plugins/happy-ending',
    quant: () => t >= HE_V7_TIME ? `<div class="qrow"><span><b>≤ 77</b><i>ES(7)</i></span><span><b>≤ 294</b><i>ES(8)</i></span><span><b>≤ 1100</b><i>ES(9)</i></span><span><b>≤ 3980</b><i>ES(10)</i></span></div><p class="qnote">Working manuscripts · review pending</p><a href="happy-ending-latest.html">Results & methods ↗</a>` : t >= HE_V6_TIME ? `<div class="qrow"><span><b>≤ 77</b><i>ES(7) · working</i></span><span><b>≤ 61</b><i>N(8,6,6) · DRAT</i></span><span><b>≤ 1148</b><i>ES(9) · working</i></span></div><p class="qnote">Replayed certificates prove N(8,6,6) ≤ 61, N(9,8,8) ≤ 688 and restricted D₉ ≤ 458. Signotope N(8,8,8) ≤ 318 (planar ES(8) ≤ 319 is Schroeder’s bound) and working corollaries ES(7) ≤ 77, ES(9) ≤ 1148 (vs. 1508 / 1501*) await independent review. Run: Trellis + ARIS + v3 → v6 main.</p><div class="qrow he-witness"><span><b>25</b><i>abstract cup–cap witness, checked separately</i></span></div>` : `<div class="qrow"><span><b>≤ 75</b><i>N(7,6,7)</i></span><span><b>≤ 76</b><i>N(7,7,7)</i></span><span><b>≤ 77</b><i>ES(7)</i></span></div><p class="qnote">Working manuscripts (independent mathematical review pending; no Lean), tightening our earlier 76 / 77 / 78 draft.</p><div class="qrow he-witness"><span><b>25</b><i>abstract cup–cap witness, checked separately</i></span></div>` }
];
const CN = { pb: 'Property B', ecc: 'ECC', dd: 'Degree–Diameter', e86: 'Erdős 86', q6: 'Ruskey–Savage', he: 'Happy Ending' };
const CI = {}; CASES.forEach((c, i) => { CI[c.id] = i; });

// k: result | draft (working result family) | evidence | open | progress   e: grow (built in workflow) | drop (research incorporated) | fade
const MS = [
  { c:'pb', v:0, k:'result', e:'grow', t:380, tag:'Pointwise bounds · k = 5–12', text:'Concrete lower bounds on m(k) for each k = 5–12, established with standalone research tools; each parameter retains its own verification scope.' },
  { c:'pb', v:1, k:'result', e:'drop', t:1820, tag:'Uniform theorem · all k ≥ 12', text:'A uniform analytic improvement over the specified RS baseline for every k ≥ 12, incorporated with the Property B methods into v1.' },
  { c:'pb', v:1, k:'evidence', e:'grow', t:2050, tag:'Lean verification', text:'End-to-end Lean proofs for m(5) ≥ 33, 34 and the uniform k ≥ 12 theorem; m(5) ≥ 35 has a complete written proof with Lean formalization in progress.' },
  { c:'ecc', v:0, k:'result', e:'grow', t:540, tag:'Exact parameter · 1', text:'d₂(43,10)=16: exclude distance 17 over the complete 172-parent domain and match a distance-16 construction.' },
  { c:'ecc', v:0, k:'result', e:'grow', t:620, tag:'Exact parameter · 2', text:'d₂(44,10)=17: the original exclusion and the known matching construction fix the optimal distance.' },
  { c:'ecc', v:0, k:'result', e:'grow', t:700, tag:'Exact parameter · 3', text:'d₂(44,11)=16: another exact parameter value following from the original exclusion and a matching lower bound.' },
  { c:'ecc', v:0, k:'open', e:'fade', t:780, tag:'Open question', text:'16 ≤ d₂(45,11) ≤ 17; distance 17 is still open.' },
  { c:'ecc', v:2, span:1, k:'evidence', e:'grow', t:2900, tag:'Proof connected', text:'Original matrices, parent data and reductions connected to Lean, with explicit external premises.' },
  { c:'ecc', v:2, span:1, k:'evidence', e:'grow', t:3150, tag:'Evidence replayed', text:'Portable proof and certificate package with fresh-copy build, audit and replay.' },
  { c:'ecc', v:2, span:1, k:'result', basis:'application', e:'grow', t:3400, tag:'Exact parameter · 4', text:'d₂(42,16)=12: a published 2020 theorem excludes distance 13, and an actual distance-12 matrix meets the bound.' },
  { c:'ecc', v:8, k:'result', e:'grow', t:ECC_V8_TIME, bound:'lower', tag:'Constructive lower bounds', text:'18 settings have better codes with downloadable generator matrices.' },
  { c:'ecc', v:8, k:'result', e:'grow', t:ECC_V8_TIME + 240, bound:'upper', tag:'Upper-bound deductions', text:'32 new upper bounds settle nine optimal distances. Two further proposed upper bounds await acceptance.' },
  { c:'dd', v:2, k:'result', e:'drop', t:3700, tag:'Construction · (11,5)', text:'37,628 → 37,631 vertices, constructive lower bound compared with the Comellas entry checked 2026-11-05.' },
  { c:'dd', v:2, k:'result', e:'drop', t:3780, tag:'Construction · (12,5)', text:'42,342 → 42,402 vertices under the same degree and diameter constraints; dated Comellas table comparison.' },
  { c:'dd', v:2, k:'result', e:'drop', t:3860, tag:'Construction · (16,4)', text:'16,384 → 16,416 vertices under the same degree and diameter constraints; dated Comellas table comparison.' },
  { c:'dd', v:2, k:'evidence', e:'drop', t:4000, tag:'Proof connected', text:'The earlier catalogue covers 153 constructed graphs across 43 parameter pairs, with 47 concrete-graph Lean proofs.' },
  { c:'ecc', v:3, k:'evidence', e:'grow', t:5950, tag:'Reusable checkers', text:'Packages the 172 parent-code exclusions (429,024 records) and one parent’s 148,785 pair rejections into reusable checkers.' },
  { c:'e86', v:3, k:'result', e:'drop', t:5050, tag:'Density upper bound', text:'Asymptotic edge density ≤ 0.59155154, improving the specified 0.60318 reference.' },
  { c:'e86', v:3, k:'evidence', e:'grow', t:5650, tag:'Evidence replayed', text:'Full final-Q₄ replay checks all 13,150,453 legal completions.' },
  { c:'q6', v:3, k:'result', e:'drop', t:5200, tag:'Q₆ theorem', text:'Every matching of Q₆ extends to a Hamilton cycle (computational proof reviewed in the same model family; independent refereeing pending).' },
  { c:'q6', v:3, k:'result', basis:'corollary', e:'drop', t:5350, tag:'Direction-lifting corollary', text:'The prescribed-endpoint P₆ path theorem, with published lifting results, covers matchings using at most six directions in any dimension.' },
  { c:'q6', v:3, k:'evidence', e:'grow', t:5750, tag:'Evidence replayed', text:'1,048,576 connectivity bits rebuilt; rank 1024 for 1024 forests.' },
  { c:'he', v:3, k:'result', e:'drop', t:5350, tag:'Abstract witness', text:'A separately checked 25-point abstract cup–cap witness (distinct from geometric point sets and from the ES(7) upper-bound argument).' },
  { c:'he', v:3, k:'progress', e:'drop', t:5450, tag:'Research in progress', text:'Archived v3 working draft: N(7,6,7) ≤ 76, N(7,7,7) ≤ 77, hence ES(7) ≤ 78. The follow-up manuscript is shown at v4.' },
  { c:'he', v:3, k:'evidence', e:'grow', t:5850, tag:'Witness replayed', text:'Fresh independent check of the abstract 25-point witness.' },
  { c:'he', v:4, k:'draft', e:'drop', t:6600, tag:'Structural upper-bound family · working manuscripts', text:'Working manuscripts give N(7,6,7) ≤ 75 and N(7,7,7) ≤ 76, and hence ES(7) ≤ 77, tightening our earlier 76 / 77 / 78 draft; independent mathematical review is pending, and there is no Lean formalization.' },
  { c:'dd', v:4, intake:true, k:'result', e:'drop', t:6750, tag:'New (10,4) construction · run with v2', text:'2,566 → 2,567 vertices: a 10-regular graph of diameter 4, exceeding the Comellas entry checked 2026-11-05. Constructed with MathRSI v2 and the DD plugin; its local-edit methods were built into the v4 plugin.' },
  { c:'dd', v:4, intake:true, k:'evidence', e:'drop', t:7000, tag:'Construction checks & Lean log', text:'Independent all-roots BFS checks all 2,567 vertices on the edge list, and preserved Final2567 logs verify the Fin 2567 Lean target under the three standard axioms (portable logs only; external review of that formalization is unfinished).' },
  { c:'dd', v:4, intake:true, k:'evidence', e:'drop', t:7050, tag:'Historical catalogue snapshot', text:'163 constructed graphs across 44 parameter pairs (including intermediate orders), together with 49 completed concrete-graph Lean proofs; orders 2,558–2,567 add one parameter pair and two of those Lean proofs.' },
  {"c": "q6", "v": 5, "intake": true, "k": "result", "e": "drop", "t": 8100, "tag": "Q₇ dense-matching theorem", "text": "Every Q₇ matching with at least 57 edges extends to a Hamilton cycle containing every prescribed edge. Run: v3 (local adaptation); methods inform v5."},
  {"c": "q6", "v": 5, "intake": true, "k": "result", "e": "drop", "t": 8300, "tag": "56-edge structure families", "text": "At the v5 snapshot, the 56-edge layer included all μ=2 and μ=4 cases and several μ=3 families. The later v6 follow-up covers every Q₇ matching."},
  {"c": "dd", "v": 5, "intake": true, "k": "result", "e": "drop", "t": 8500, "tag": "D5 follow-up · (11,5) & (12,5)", "text": "(11,5) 37,631 → 37,632 vertices (205,366 edges; +1 over Comellas 2026-11-16) and (12,5) 42,402 → 42,433 vertices through 31 valid increments (246,309 edges; +81 over Comellas 42,352). Run: 2026-11-11 v4-maintenance + local DD updates → informs v5 main maintenance."},
  {"c": "dd", "v": 5, "intake": true, "k": "evidence", "e": "drop", "t": 9250, "tag": "Deterministic rebuild & BFS checks", "text": "Both final graphs regenerate deterministically. D12 preserves the 42,402-vertex source and runs BFS from all 31 new vertices; D11 takes core–core distances from the H9 theorem under the stated σ/π identification and runs BFS from all 161 peripheral and new vertices. End-to-end Lean proofs and independent refereeing remain open."},
  {"c": "e86", "v": 6, "intake": true, "k": "result", "e": "drop", "t": 10300, "tag": "Q₇ · 304 (construction + source report)", "text": "304-edge construction verified; 304 upper bound as reported in the source package, not re-verified in this pass (two explicit 304-edge C₄-free subgraphs checked in-repo; 21 raw RUP traces omitted upstream)."},
  {"c": "e86", "v": 6, "intake": true, "k": "result", "e": "drop", "t": 10500, "tag": "Q₈ · 682 ≤ ex(Q₈, C₄) ≤ 683", "text": "Four 682-edge C₄-free constructions plus Theorem B ruling out 684 edges via 83 active cuts and 25 imported Q₆ DRAT certificates (checked computationally and reviewed in the same model family; independent refereeing pending). Closing ex(Q₈, C₄) ≤ 682 remains open."},
  {"c": "e86", "v": 6, "intake": true, "k": "result", "e": "drop", "t": 10700, "tag": "Q∞ · π_□(C₄) ≤ 0.5912405943", "text": "T3 ≤ 0.5912405943 (COP + cubic) and T4 ≤ 0.5912405942 (m = 1024 degree potential via a 5-line hypergeometric tower), both proved and rechecked in 128-bit C++20. Exploratory 0.5907 is an approximate fit (residual ≈ 3.9 × 10⁻⁴), an earlier 0.5899 claim was refuted and withdrawn, and limit 1/2 remains open."},
  {"c": "q6", "v": 6, "intake": true, "k": "result", "e": "drop", "t": 10950, "tag": "Q₇ complete E16 · ≥56 edges", "text": "Every Q₇ matching with at least 56 edges (at most 16 holes, all μ ∈ {0,1,2,3,4}) extends to a Hamilton cycle retaining every prescribed edge, by a computational argument reviewed in the same model family modulo the listed baseline imports (independent refereeing pending, no Lean). At the fixed v6 snapshot, ≤55 edges and full Q₇ were open; see the later v6 main R7 follow-up."},
  {"c": "e86", "v": 6, "intake": true, "k": "evidence", "e": "grow", "t": 11350, "tag": "C++17/20 replays & coevolution engine", "text": "Recompiled 128-bit C++20 verifiers on all 3,212,821 Q₄ orbits (T3/T4), C++17 13,150,453-completion replay for Q₈, explicit construction checks and 18 cube_coevolve tests."},
  {"c": "he", "v": 6, "intake": true, "k": "draft", "e": "drop", "t": 11180, "tag": "m = 7–9 capacities & ES(9) ≤ 1148", "text": "Replayed certificates prove N(8,6,6) ≤ 61 (milestone9 CNF+DRAT) and native-trace integer duals N(9,8,8) ≤ 688, restricted D₉ ≤ 458. Combined with R7/R20 and analytic m = 7–9 manuscripts, they give signotope N(8,8,8) ≤ 318 (planar ES(8) ≤ 319 is Schroeder’s bound) and working planar corollaries ES(7) ≤ 77, ES(9) ≤ 1148 (vs. 1508 / 1501*); independent review pending, no Lean. Run: Trellis + ARIS + v3 → v6 main maintenance."},
  {"c": "q6", "v": 6, "intake": true, "k": "evidence", "e": "grow", "t": 11420, "tag": "290 baseline imports & geometry checks", "text": "Bundled all 290 baseline imports and ran the 189-row μ=0 large-face table plus standalone MU0 and Q₆ A₈ geometry/plan checkers; 10 large .cnf/.drup traces are indexed in INVENTORY.json and stored in the external archive."},
  {"c": "he", "v": 6, "intake": true, "k": "evidence", "e": "grow", "t": 11480, "tag": "Native-trace dual & DRAT replays", "text": "Cross-platform stdlib & drat-trim checks verify N(9,8,8) ≤ 688, D₉ ≤ 458 (plus the 47,635-row depth-≤3 LP ceiling), N(8,6,6) ≤ 61 (115 rows + 9-hole matrix witness), Schroeder’s 15-file octagon trees (193 / 124) and m = 7 lock-block ≤4."},
  {"c": "q6", "v": 7, "intake": true, "k": "result", "e": "drop", "t": 12600, "tag": "Q₇ · full R7 author working proof", "text": "Every ordinary short-edge matching in Q₇, including empty and perfect matchings, extends to a 128-vertex Hamilton cycle retaining all its edges. E36 covers ≥46 edges; double counting gives ≥45 for maximal matchings, and E38 excludes exactly 45; add free edges to reach a maximal matching. Source acceptance: 2026-11-19, sound-modulo-imports / same-family / provisional; external review pending, no Lean. Run: v3 local adaptation → v6 main follow-up, 2026-11-20."},
  {"c": "q6", "v": 7, "intake": true, "k": "evidence", "e": "grow", "t": 12800, "tag": "E38 local C++ recomputation", "text": "Two original C++ programs run on Mac: 35,360 legal single faces and 18,237,120 ordered face pairs; zero pairs satisfy the directional necessary conditions for a maximal 45-edge matching. Some large older-layer certificates are omitted; the full imported proof chain was not replayed end to end."},
  {"c": "he", "v": 7, "intake": true, "k": "draft", "e": "drop", "t": HE_V7_TIME, "tag": "Same-input sector deficits", "text": "Working ES(7) ≤ 77 unchanged; ES(8) ≤ 294 versus Schroeder 319, ES(9) ≤ 1100 versus previous working 1148, ES(10) ≤ 3980. Bounded macOS finite replay passed; independent mathematical review pending, no Lean."}
];
const isOutcome = m => m.k === 'result' || m.k === 'draft';
const CALLOUTS = [
  { c:'pb', v:0, t:380, kind:'intro', value:'Lower bounds · k = 5–12' },
  { c:'ecc', v:0, t:700, kind:'intro', value:'3 exact code distances' },
  { c:'pb', v:1, t:1820, kind:'delta', value:'Pointwise → uniform', detail:'all k ≥ 12' },
  { c:'ecc', v:2, t:3400, kind:'delta', value:'3 → 4', detail:'exact code distances' },
  { c:'ecc', v:8, t:ECC_V8_TIME + 240, row:0, kind:'delta', value:'4 → 13', value2:'settled optimal distances', detail:'9 more in this round', paper:ECC_PAPER },
  { c:'dd', v:2, t:3860, kind:'intro', value:'Larger graphs · 3 records' },
  { c:'e86', v:3, t:5050, kind:'intro', value:'C₄-free density ≤ 0.59155154' },
  { c:'q6', v:3, t:5200, kind:'intro', value:'Every Q₆ matching lies in', detail:'a Hamilton cycle' },
  { c:'he', v:3, t:5450, kind:'intro', value:'ES(7) ≤ 78' },
  { c:'dd', v:4, t:6750, row:0, kind:'delta', value:'(10,4) 2,566 → 2,567', detail:'Run: v2' },
  { c:'he', v:4, t:6600, row:1, kind:'delta', value:'78 → 77', detail:'ES(7) upper bound' },
  {"c": "q6", "v": 5, "t": 8100, "row": 1, "kind": "delta", "value": "Q₇ · ≥57 edges", "detail": "128 vertices · Run: v3"},
  {"c": "dd", "v": 5, "t": 8500, "row": 0, "kind": "delta", "value": "(11,5) 37,631 → 37,632", "value2": "(12,5) 42,402 → 42,433", "detail": "Run: v4 + local updates"},
  {"c": "e86", "v": 6, "t": 10300, "row": 0, "kind": "delta", "value": "Q₇ 304 · Q₈ 682–683", "value2": "Q∞ ≤ 0.5912405943", "detail": "≤304 source · 682 open · Run: v3"},
  {"c": "q6", "v": 6, "t": 10950, "row": 1, "kind": "delta", "value": "Q₇ · ≥56 edges", "detail": "Author working proof · v3"},
  {"c": "he", "v": 6, "t": 11180, "row": 2, "kind": "delta", "value": "N(8,6,6) ≤ 61 · ES(9) ≤ 1148", "detail": "m = 7–9 working · Run: v3"},
  {"c": "q6", "v": 7, "t": 12600, "row": 0, "kind": "delta", "value": "Q₇ · every matching", "detail": "v6 main result → v7 method intake"},
  {"c": "he", "v": 7, "t": HE_V7_TIME, "row": 1, "kind": "delta", "value": "ES(8) ≤ 294 · ES(9) ≤ 1100", "value2": "ES(10) ≤ 3980", "detail": "Working manuscripts · review pending"}
];

const VERS = [
  { tag:'v0', state:'Origins', name:'Before the shared harness',
    base:[["Standalone research tools", "", "Use individual skills for literature, proof development, review and verification within each task."], ["Task knowledge and evidence", "", "Keep proofs, failed approaches, checks and reusable findings in the task workspace and research wiki."]],
    fullBase:['Standalone ARIS skills','Task workspaces, proofs, failures & wikis'],
    plug:[['note','Source: PB · ECC']],
    sum:'Property B and ECC were first studied with standalone ARIS skills; proofs, failures and checks accumulated in task workspaces (no release tag).' },
  { tag:'v1', state:'Release', name:'Shared research workflow',
    base:[["Five adaptive workflows", "pb ecc", "Connect preparation, route review, proof development, verification and handoff; return to earlier stages when needed."], ["Review and parallel proof work", "", "Challenge routes across models, delegate proof obligations, and connect completed work to the original problem."], ["Shared core, reusable knowledge", "", "Load domain plugins, read and update the task wiki, and use Lean when formal verification helps."]],
    fullBase:['Five adaptive workflows (from PB & ECC)','Base / plugin / task separation','Route review, real proof callers & optional Lean'],
    plug:[['add','PB','pb'],['add','ECC draft','ecc']],
    sum:'Research distilled into five adaptive workflows, separating the shared base, domain plugins and per-task wiki state.' },
  { tag:'v2', state:'Release', name:'Evidence-driven evolution',
    base:[["Research-driven evolution", "dd", "Turn proofs, failures and corrections into concrete updates to the existing base and domain plugins."], ["Baselines guide the next task", "", "Replan when published bounds improve, while preserving the user’s fixed mathematical objective."], ["Transfer evidence across changes", "", "Recheck inherited proofs and failures when objects change; send formal targets directly to Lean verification."]],
    fullBase:['Separate meta-evolve loop (from DD)','Proof/refutation transfer checks on changed objects','Shared coverage & direct Lean export checks'],
    plug:[['add','DD','dd'],['note','PB · ECC kept']],
    sum:'A separate meta-evolve loop turns finished research into concrete workflow updates; Degree–Diameter enters as a domain plugin.' },
  { tag:'v3', state:'Release', name:'Stronger base, six domains',
    base:[["Return full-domain counterexamples", "e86", "Test beyond working examples, send violations back to search, and retain the best verified candidate."], ["Preserve objects and prove coverage", "", "Keep roots, targets and required edges intact through reductions; connect finite certificates to every legal input."], ["Audit explicit Lean premises", "", "Distinguish kernel-proved results from assumptions about literature, classifications and computational scans."]],
    fullBase:['Full-domain counterexamples & accepted best (from Erdős 86)','Marked root/target/edge preservation across reductions','Finite rank bridges & legal failed-pool reuse','Explicit Lean premise audit & 5-stage wiki read/write/reuse'],
    plug:[['deep','ECC','ecc'],['add','Extremal','e86'],['add','Hamilton','q6'],['add','Happy Ending','he']],
    sum:'v3 release. Four strengthened evidence-loop actions, explicit 5-stage wiki reuse, an in-place ECC upgrade and three newly incorporated domains.' },
  { tag:'v4', state:'Release', name:'Equality structure & deeper plugins',
    base:[["Turn equality into a usable witness", "he", "Recover simultaneous equality conditions, make a legal exchange, and connect the resulting witness to the original problem."], ["Mandatory global progress checks", "", "When local work stops reducing the original gap, two independent agents reassess the route and total cost; use their findings to choose the next action.", "Research feedback · main maintenance"]],
    fullBase:['Implemented in route-loop, prove and verify: same-object equality chain → legal equal-size exchange → capacity-forced, endpoint-compatible witness','Subsequent maintenance on main: mandatory independent global progress checks ask whether reductions improve the original completion path; the fixed v4 snapshot is unchanged.'],
    plug:[['deep','Happy Ending','he'],['deep','DD','dd'],['deep','ECC · main','ecc'],['note','Other 3 domains retained']],
    pluginNote:'ECC on main: reuse exclusions and share computations.',
    sum:'v4 connected equality-chain recovery, legal exchanges and endpoint-compatible witnesses. Happy Ending and DD methods deepened; later main maintenance added global reassessment and ECC node reuse. v5 inherits these capabilities.' },
  {
  "tag": "v5",
  "state": "Release",
  "name": "Controlled choices & theorem reuse",
  "base": [
    [
      "Control auxiliary choices",
      "q6",
      "Choose legal auxiliary objects so the actual successor meets the next proof step."
    ],
    [
      "Reuse theorems before more work",
      "q6",
      "Apply new results across known legal representations; work on what all gates leave open."
    ],
    [
      "Consume results before dispatch",
      "dd",
      "Update current facts from returned evidence before issuing the next task or review, preventing duplicate work and stale-state rollback."
    ]
  ],
  "fullBase": [
    "Separate the original input, legal auxiliary choices and the actual successor; construct the interface the next theorem needs.",
    "Consume new theorems across known legal splits, transports and monotone completions before dispatching the residual domain.",
    "Check fixed or conditional finite plans for complete input coverage and original-edge-preserving expansion.",
    "Update current facts from returned evidence before issuing the next task or review, preventing duplicate work and stale-state rollback."
  ],
  "plug": [
    [
      "deep",
      "Hamilton",
      "q6"
    ],
    ["deep", "DD", "dd"],
    ["note", "Other 4 domains retained"]
  ],
  "pluginNote": "Q7: v3 local adaptation; DD: v4 + local updates. Methods feed v5.",
  "sum": "v5 absorbs Q7 controlled choices, theorem reuse and finite-plan coverage. The 2026-11-16 DD follow-up adds result consumption before dispatch; its plugin deepens joint completion and verified prefixes. Run provenance: Q7 used v3 local adaptation; DD used v4 + local updates."
},
  {
  "tag": "v6",
  "state": "Release",
  "name": "Hardest-remainder gates & coevolution",
  "base": [
    [
      "Probe the hardest remainder first",
      "q6",
      "Test candidate splits on the hardest open branch before adoption; measure net-new union coverage on the same actual input."
    ],
    [
      "Primal–dual coevolution",
      "e86",
      "Separate proof goal from search target, rotate signed residuals, and refute candidate cuts against the full archive."
    ],
    [
      "Stop at repair-residual floor",
      "e86",
      "Stop outer floating-point SDP/CP loops once gains fall to the rounding-repair residual, and record the residual beside any approximate fit."
    ]
  ],
  "fullBase": [
    "After proving a dense range, extend the original input without dropping any requirements. Check which maximal extensions still fall outside that range.",
    "Test candidate case splits with bounded probes on the hardest open branch, measuring net-new coverage on the same input.",
    "Run primal–dual coevolution with goal/target separation, 4-channel normalized signed residuals and full-archive refutation.",
    "Stop outer floating-point SDP/CP loops once apparent improvement drops to the rounding-repair residual, recording any nonzero residual beside approximate fits.",
    "v6 main maintenance: stop inside a fixed relaxation when dual and exact relaxation-feasible primal meet, and verify sparse integer duals from row parameters without giant LP matrices (fixed v6 tag unchanged)."
  ],
  "plug": [
    ["deep", "Extremal", "e86"],
    ["deep", "Hamilton", "q6"],
    ["deep", "Happy Ending", "he"],
    ["note", "Other 3 domains retained"]
  ],
  "pluginNote": "C₄-free, Q7 R7 & N(m,r,s): v3 research → v6 & main.",
  "sum": "v6 release + main maintenance. Incorporates C₄-free Q₇ (304 construction verified; 304 upper bound source-reported), Q₈ (682–683), asymptotic density Q∞ ≤ 0.5912405943, complete Q₇ E16 (≥56 edges), and the 2026-11-17 Happy Ending N(m,r,s) follow-up across m = 7, 8, 9 (replayed N(8,6,6) ≤ 61 and N(9,8,8) ≤ 688 / D₉ ≤ 458 duals, working ES(9) ≤ 1148; fixed v6 tag unchanged). Distills hardest-remainder split gating, primal–dual coevolution, repair-residual stopping and generative sparse dual checks into the shared base. The 2026-11-20 main follow-up adds the full Q₇ R7 author working proof (all matching sizes; source acceptance on 19 November, v3 local adaptation; external peer review pending, no Lean)."
},
  {
    "tag": "v7",
    "state": "Release",
    "name": "Same-input deficits & terminal completion",
    "base": [
      [
        "Keep the same actual input",
        "he",
        "Charge every deficit on the same input; retain shared endpoints, all penultimate choices and joint compatibility."
      ],
      [
        "Complete to the terminal case",
        "q6",
        "Preserve all original requirements while extending to a maximal object, then close every terminal obstruction."
      ]
    ],
    "fullBase": [
      "Keep deficits and equality constraints attached to the same actual input, rather than adding bounds attained on different objects.",
      "After a dense theorem, preserve the original input during monotone completion and exclude every remaining terminal obstruction."
    ],
    "plug": [
      [
        "deep",
        "Happy Ending",
        "he"
      ],
      [
        "deep",
        "Hamilton",
        "q6"
      ],
      [
        "note",
        "Other 4 domains retained"
      ]
    ],
    "pluginNote": "Q7 maximal completion; Happy Ending same-input sector budgets.",
    "sum": "Full Q7 R7 was already received in v6 main maintenance; v7 distills its terminal-completion method. Happy Ending retains ES(7) ≤ 77 and adds working ES(8) ≤ 294 (Schroeder comparator 319), ES(9) ≤ 1100 (previous working 1148), and ES(10) ≤ 3980. Bounded macOS finite replay passed; independent mathematical review pending, no Lean."
  },
  { tag:'v8', state:'Current', name:'Constructions, exclusions & exact closures',
    base:[['Carry the constructive witness', 'ecc', 'Carry a verified witness through transformations and keep the strongest result for each setting.'], ['Test rarely triggered rejection branches', 'ecc', 'Independently exercise rejection branches that routine successful runs rarely reach.'], ['Propagate exclusions with exact premises', 'ecc', 'Derive upper bounds from published exclusions while preserving each theorem’s precise assumptions.']],
    fullBase:['Carry constructive witnesses through transformations; deduplicate each setting by its strongest verified bound.', 'Independently test rarely triggered rejection branches, rather than relying on successful runs alone.', 'Propagate published upper exclusions with exact premises; separate established results from source-pending claims.'],
    plug:[['deep','ECC','ecc'],['note','Other 5 domains retained']],
    pluginNote:'v8 · constructive witnesses, rejection branches and exclusion propagation.',
    sum:'MathRSI went from four settled code distances to thirteen. This round alone settled nine by matching known codes with tighter upper bounds. New constructions improved the lower bound at 18 other settings. Two further upper bounds await final acceptance.' },
  { tag:'v9+', state:'Future', name:'Next research, next evolution',
    base:[["Learn from the next problem", "", "Use new research successes and failures to identify the next concrete workflow improvement."]],
    fullBase:['Open continuation — next research cycle feeds the next workflow evolution'],
    plug:[['note','New research → new tools']],
    sum:'Open continuation. Future research will guide the next concrete base and plugin improvements.' }
];

/* -------------------------------------------------------------- geometry */
const LAST = VERS.length - 2, FUTURE = VERS.length - 1;
const BW = 26, BH = 28, STEP = 32, PITCH = 36, X0 = 92;
const calloutHeight = d => d.value2 ? 80 : d.kind === 'delta' ? 58 : d.c === 'q6' ? 54 : 40;
const columnCards = v => CALLOUTS.filter(d => d.v === v).sort((a, b) => (a.row ?? 0) - (b.row ?? 0) || a.t - b.t);
const cardStackHeight = cards => cards.reduce((sum, d) => sum + calloutHeight(d), 0) + Math.max(0, cards.length - 1) * 4;
const columnDepth = v => Math.max(...CASES.map(c => MS.filter(m => m.c === c.id && isOutcome(m) && m.v <= v).length));
// Reserve the final tallest column and the 40px drop entrance before placing cards.
const CALLOUT_CLEARANCE = 14 + 40, SKY_TOP = 14;
const HEADROOM = Math.max(0, ...Array.from({ length: LAST + 1 }, (_, v) =>
  SKY_TOP + cardStackHeight(columnCards(v)) + CALLOUT_CLEARANCE - (284 - columnDepth(v) * STEP + 5)));
const H = 326 + HEADROOM, GUT = 80, COL = 232, W = GUT + COL * VERS.length;
const SPINE = 296 + HEADROOM, BASE = 284 + HEADROOM;
const cx = i => GUT + COL * i + COL / 2;
const R = [300, 1700, 3600, 5000, 6600, 8000, 10200, 12400, 14200], STOP = [1100, 2400, 4400, 6000, 7400, 9600, 12200, 14000, 15800], T = STOP[LAST];
const MOVE = [null, [1100, 600], [2400, 600], [4400, 600], [6000, 600], [7400, 600], [9600, 600], [12200, 200], [14000, 200]];
const KEYS = [[0,0],[1100,0],[1700,1],[2400,1],[3600,2],[4400,2],[5000,3],[6000,3],[6600,4],[7400,4],[8000,5],[9600,5],[10200,6],[12200,6],[12400,7],[14000,7],[14200,8],[T,8]];
const SEGS = [[1100,1700],[2400,3600],[4400,5000],[6000,6600],[7400,8000],[9600,10200],[12200,12400],[14000,14200]];

// Only a domain's first outcome opens a horizontal slot. Later outcomes grow upward.
const domainDebuts = CASES.map(c => MS.filter(m => m.c === c.id && isOutcome(m)).sort((a, b) => a.t - b.t)[0]);
function slotX(col, s, time = T) {
  const widths = domainDebuts.map((m, i) => {
    if (m.v > col) return 0;
    if (m.v < col || i === 0) return 1;
    return E.out(clamp((time - m.t) / 300));
  });
  const total = widths.reduce((a, b) => a + b, 0);
  const before = widths.slice(0, s).reduce((a, b) => a + b, 0);
  return cx(col) - BW / 2 + PITCH * (before - (total - 1) / 2);
}

const sky = $('#sky'), lanes = $('#lanes'), stage = $('#stage'), scroller = $('#scroller');
const panel = $('#panel'), playBtn = $('#play'), readout = $('#readout');
const anims = [], stacks = Array.from({ length: LAST + 1 }, () => ({})), deltaTags = [];
const blockPositions = [];
let bands = [], prog, fline, ph, halo, hit;

function topRound(x, y, w, h, r) {
  return `M${x} ${y + h}V${y + r}Q${x} ${y} ${x + r} ${y}H${x + w - r}Q${x + w} ${y} ${x + w} ${y + r}V${y + h}Z`;
}
function addAnim(node, type, s, d) { const a = { el: node, type, s, d, p: undefined }; anims.push(a); return a; }

function shape(g, m) {
  const c = `var(--${m.c})`;
  // All outcome blocks share one visual meaning; provenance and checks stay in the details.
  el('rect', { class:'b-res', width:BW, height:BH, rx:5, style:`fill:${c}` }, g);
  if (m.bound) {
    el('text', { class:'bound-label', x:BW / 2, y:BH / 2, 'text-anchor':'middle', dy:'.35em' }, g).textContent = m.bound === 'lower' ? 'LB' : 'UB';
  }
  el('title', {}, g).textContent = m.bound ? m.text : `${CN[m.c]} · ${m.tag} — ${m.text}`;
}

function buildSky() {
  sky.setAttribute('viewBox', `0 0 ${W} ${H}`);
  const defs = el('defs', {}, sky);
  const mk = el('marker', { id: 'sky-arrow', viewBox: '0 0 10 10', refX: '8', refY: '5', markerWidth: '8', markerHeight: '8', orient: 'auto' }, defs);
  el('path', { d: 'M0 1L9 5L0 9Z', fill: '#AEB6C2' }, mk);
  bands = VERS.map((V, i) => el('path', { class: 'band', d: topRound(cx(i) - 110, 8, 220, H - 8, 14) }, sky));
  el('text', { class: 'gut', x: 4, y: 172 + HEADROOM }, sky).textContent = 'Mathematical';
  el('text', { class: 'gut', x: 4, y: 190 + HEADROOM }, sky).textContent = 'results';
  for (let i = 0; i < VERS.length; i++) for (let s = 0; s < CASES.length; s++)
    el('rect', { class: i === FUTURE ? 'ghost fut' : 'ghost', x: slotX(i, s), y: BASE + 3, width: BW, height: 3, rx: 1.5 }, sky);
  el('line', { class: 'spine-base', x1: X0, y1: SPINE, x2: cx(LAST), y2: SPINE }, sky);
  el('line', { class: 'spine-fut', x1: cx(LAST) + 10, y1: SPINE, x2: W - 14, y2: SPINE, 'marker-end': 'url(#sky-arrow)' }, sky);
  prog = el('line', { class: 'spine-prog', x1: X0, y1: SPINE, x2: X0, y2: SPINE }, sky);
  fline = el('polyline', { class: 'focus-line', points: '' }, sky);

  CASES.forEach(c => {
    const marker = el('marker', { id:`trace-arrow-${c.id}`, viewBox:'0 0 10 10', refX:'8', refY:'5', markerWidth:'7', markerHeight:'7', orient:'auto' }, defs);
    el('path', { d:'M1 1L8 5L1 9', fill:'none', stroke:`var(--${c.id})`, 'stroke-width':'1.7', 'stroke-linecap':'round', 'stroke-linejoin':'round' }, marker);
  });
  el('title', {}, fline).textContent = 'Selected case trajectory; repeated blocks retain earlier outcomes.';

  const blocks = el('g', {}, sky);
  for (let col = 0; col <= LAST; col++) CASES.forEach((c, s) => {
    const items = MS.map((m, idx) => [m, idx]).filter(([m]) => m.c === c.id && isOutcome(m) && m.v <= col);
    const st = [];
    items.forEach(([m, idx], i) => {
      const y = BASE - (i + 1) * STEP + 5;
      const attrs = { class:'bk', 'data-c':c.id, 'data-m':idx, 'data-v':col, transform:`translate(${slotX(col, s)} ${y})` };
      if (m.bound) Object.assign(attrs, { href:`ecc-intervals.html#${m.bound}`, 'aria-label':m.text });
      const g = el(m.bound ? 'a' : 'g', attrs, blocks);
      blockPositions.push({ el:g, col, s, y });
      const a = el('g', { class: 'anim' }, g);
      shape(a, m);
      st.push(m.v === col ? addAnim(a, m.e, m.t, m.e === 'drop' ? 440 : 300) : addAnim(a, 'slide', MOVE[col][0], MOVE[col][1]));
    });
    if (st.length) stacks[col][c.id] = st;

  });

  // Reserve every card's final position from the start, so arrivals never shift earlier results.
  for (let v = 0; v <= LAST; v++) {
    const cards = columnCards(v);
    const stackTop = BASE - columnDepth(v) * STEP + 5;
    const bottom = Math.min(154 + HEADROOM, stackTop - CALLOUT_CLEARANCE);
    let y = bottom - cardStackHeight(cards);
    cards.forEach(d => { buildDeltaTag({ ...d, y, height:calloutHeight(d) }); y += calloutHeight(d) + 4; });
  }

  for (let i = 0; i <= LAST; i++) {
    el('circle', { class: 'node-base', cx: cx(i), cy: SPINE, r: 7 }, sky);
    addAnim(el('circle', { class: `node-on a-pop${i === LAST ? ' current' : ''}`, cx: cx(i), cy: SPINE, r: 7 }, sky), 'pop', R[i], 280);
  }
  halo = el('circle', { class: 'halo', cx: cx(FUTURE), cy: SPINE, r: 16 }, sky);
  el('circle', { class: 'node-fut', cx: cx(FUTURE), cy: SPINE, r: 7 }, sky);
  ph = el('g', { class: 'ph' }, sky);
  el('circle', { cx: 0, cy: SPINE, r: 12 }, ph);
  hit = el('rect', { class: 'axis-hit', x: GUT, y: SPINE - 12, width: W - GUT, height: 38, tabindex: '0', role: 'slider',
    'aria-label': 'MathRSI harness version (arrow keys to move, space to play)', 'aria-valuemin': '0', 'aria-valuemax': String(FUTURE) }, sky);
}

function buildDeltaTag(d) {
  const mi = MS.findIndex(m => m.c === d.c && m.v === d.v && m.t === d.t);
  const width = d.value2 || (d.c === 'dd' && d.v === 4) || (d.c === 'he' && d.v === 6) ? 220 : 200;
  const tagX = cx(d.v) - width / 2, ownX = slotX(d.v, CI[d.c]) + BW / 2;
  const items = MS.filter(m => m.c === d.c && isOutcome(m) && m.v <= d.v);
  const blockIndex = items.indexOf(MS[mi]);
  // The archived upper bound is separate from the abstract 25-point witness.
  const endY = d.kind === 'intro' && d.c === 'he' ? 160 + HEADROOM : BASE - (blockIndex + 1) * STEP;
  const intro = d.kind === 'intro', badge = intro ? (d.v === 0 ? 'Origins' : 'New') : 'Improved';
  const group = el('g', { transform:`translate(${tagX} ${d.y})`, style:'display:none;opacity:0' }, sky);
  const g = el('g', { class:`delta-tag bk ${intro ? 'intro-tag' : 'change-tag'}${d.value2 ? ' multiline-tag' : ''}`, 'data-c':d.c, 'data-m':mi,
    'data-kind':d.kind, 'data-v':d.v, 'data-t':d.t,
    style:`--c:var(--${d.c})`,
    role:'button', tabindex:'-1', 'aria-hidden':'true', 'aria-label':`${CN[d.c]}: ${d.value}${d.value2 ? '; ' + d.value2 : ''}${d.detail ? ', ' + d.detail : ''}. Inspect this result.` }, group);
  const leader = el('line', { class:'delta-leader', x1:ownX-tagX, x2:ownX-tagX, y1:d.height, y2:endY-d.y, style:'visibility:hidden' }, g);
  el('rect', { class:'delta-surface', width, height:d.height, rx:10 }, g);
  el('rect', { class:'callout-color', x:6, y:7, width:3, height:d.height-14, rx:1.5, fill:`var(--${d.c})` }, g);
  el('text', { class:'delta-kicker', x:15, y:intro ? 15 : 16 }, g).textContent = CN[d.c];
  if (!d.paper) el('text', { class:'callout-badge', x:width-10, y:intro ? 15 : 16, 'text-anchor':'end' }, g).textContent = badge;
  if (intro) {
    el('text', { class:'intro-value', x:15, y:30 }, g).textContent = d.value;
    if (d.detail) el('text', { class:'intro-detail', x:15, y:45 }, g).textContent = d.detail;
  } else {
    el('text', { class:`delta-value${d.c === 'pb' ? ' delta-word-value' : ''}`, x:15, y:35 }, g).textContent = d.value;
    if (d.value2) el('text', { class:'delta-value', x:15, y:54 }, g).textContent = d.value2;
    el('text', { class:'delta-detail', x:15, y:d.value2 ? 72 : 50 }, g).textContent = d.detail;
  }
  if (d.paper) {
    const link = el('a', { href:d.paper, class:'callout-paper', 'aria-label':'Original five-parameter paper (PDF)' }, group);
    el('rect', { x:width-125, y:1, width:120, height:22, rx:4, fill:'transparent' }, link);
    el('text', { x:width-10, y:16, 'text-anchor':'end' }, link).textContent = 'Five-parameter paper ↗';
  }
  deltaTags.push({ ...d, tagX, group, el:g, leader, endY });
}

function fromTag(ids) {
  return `<span class="from" data-cases="${ids}">from ${ids.split(' ').map(id => `<i style="--c:var(--${id})"></i>${CN[id]}`).join(' · ')}</span>`;
}
function buildLanes() {
  lanes.style.gridTemplateColumns = `${GUT / W * 100}% repeat(${VERS.length},minmax(0,1fr))`;
  stage.style.minWidth = `${W}px`;
  let h = '<div class="lane-lab lane-axis">Harness<br>version</div>';
  VERS.forEach((V, i) => {
    h += `<div class="cell row-v${i === FUTURE ? ' fut' : i === LAST ? ' current' : ''}" data-v="${i}"><button class="vbtn" type="button" data-goto="${i}" aria-label="Show MathRSI harness ${V.tag}: ${V.name}"><span class="vtag">${V.tag}</span><span class="vstate s-${V.state.toLowerCase()}">${V.state}</span><span class="vname">${V.name}</span></button></div>`;
  });
  h += '<div class="lane-lab row-b">Base<span class="lane-explain">Key improvements</span></div>';
  VERS.forEach((V, i) => {
    h += `<div class="cell row-b${i === FUTURE ? ' fut' : i === LAST ? ' current' : ''}" data-v="${i}"><ul>${V.base.slice(0, 3).map((b, j) => `<li style="--i:${j}"><strong>${b[0]}</strong><span class="base-action">${b[2] || ''}</span>${b[1] ? fromTag(b[1]) : b[3] ? `<span class="from" data-cases="">${b[3]}</span>` : ''}</li>`).join('')}</ul></div>`;
  });
  h += '<div class="lane-lab row-p">Plugins</div>';
  VERS.forEach((V, i) => {
    h += `<div class="cell row-p${i === FUTURE ? ' fut' : i === LAST ? ' current' : ''}" data-v="${i}"><div class="chiprow">${V.plug.map((p, j) => p[0] === 'note'
      ? `<span class="chip note" style="--i:${j}">${p[1]}</span>`
      : `<button class="chip" type="button" data-case="${p[2]}" aria-pressed="false" style="--i:${j};--c:var(--${p[2]})"><b>${p[0] === 'add' ? '+' : '↑'}</b>${p[1]}</button>`).join('')}</div>${V.pluginNote ? `<p class="plugin-note">${V.pluginNote}</p>` : ''}</div>`;
  });
  lanes.innerHTML = h;
  $('#chips').innerHTML = CASES.map(c => `<button class="case-chip" type="button" data-case="${c.id}" aria-pressed="false" style="--c:var(--${c.id})">${c.short}</button>`).join('');
}

/* --------------------------------------------------------------- clock */
let t = T, mode = null, playing = false, target = T, targetSel = LAST, last = 0, raf = 0;
let future = false, focus = null, hl = null, selPrev = -1, panelKey = '', touched = false, resumeMode = null, firstScroll = true;

function uAt(tt) {
  for (let i = 1; i < KEYS.length; i++) {
    const [a, ua] = KEYS[i - 1], [b, ub] = KEYS[i];
    if (tt <= b) return ua === ub ? ua : ua + (ub - ua) * E.io(clamp((tt - a) / (b - a)));
  }
  return LAST;
}
function tFromU(u) {
  if (u >= LAST) return T;
  const k = Math.floor(u), f = u - k;
  if (f < 1e-3) return STOP[k];
  const [a, b] = SEGS[k]; let lo = a, hi = b;
  for (let n = 0; n < 24; n++) { const m = (lo + hi) / 2; if (E.io((m - a) / (b - a)) < f) lo = m; else hi = m; }
  return (lo + hi) / 2;
}
function selAt() { if (future) return FUTURE; let s = 0; for (let i = 0; i <= LAST; i++) if (t >= R[i]) s = i; return s; }

function paint(a, p) {
  const s = a.el.style;
  const block = a.el.parentNode;
  if (block.localName === 'a') block.style.display = p > 0 ? '' : 'none';
  switch (a.type) {
    case 'grow': s.transform = `scaleY(${E.out(p)})`; s.opacity = p > 0 ? 1 : 0; break;
    case 'drop': s.transform = `translateY(${(1 - E.back(p)) * -40}px)`; s.opacity = clamp(p * 2.2); break;
    case 'slide': { const e = E.out(p); s.transform = `translateX(${(1 - e) * -COL}px)`; s.opacity = p > 0 ? .3 + .7 * e : 0; break; }
    case 'fade': s.opacity = E.out(p); break;
    case 'draw': s.strokeDashoffset = 100 * (1 - E.io(p)); s.opacity = p > 0 ? 1 : 0; break;
    case 'pop': s.transform = `scale(${p > 0 ? .4 + .6 * E.back(p) : .4})`; s.opacity = p > 0 ? 1 : 0; break;
  }
}

function scrollToCol(i) {
  if (scroller.scrollWidth <= scroller.clientWidth + 4) return;
  const k = stage.clientWidth / W;
  scroller.scrollTo({ left: cx(i) * k - scroller.clientWidth / 2, behavior: reduce || firstScroll ? 'auto' : 'smooth' });
  firstScroll = false;
}

function apply() {
  for (const b of blockPositions) b.el.setAttribute('transform', `translate(${slotX(b.col, b.s, t)} ${b.y})`);
  for (const a of anims) { const p = clamp((t - a.s) / a.d); if (p !== a.p) { a.p = p; paint(a, p); } }
  const activeCase = trajectoryCase();
  deltaTags.forEach(d => {
    const visible = t >= d.t && (!activeCase || activeCase === d.c);
    d.group.style.opacity = visible ? E.out(clamp((t - d.t) / 280)) : 0;
    d.group.style.display = visible ? '' : 'none';
    d.el.setAttribute('tabindex', visible ? '0' : '-1');
    d.el.setAttribute('aria-hidden', String(!visible));
    d.leader.style.visibility = visible && activeCase === d.c ? 'visible' : 'hidden';
    const leaderX = slotX(d.v, CI[d.c], t) + BW / 2 - d.tagX;
    d.leader.setAttribute('x1', leaderX);
    d.leader.setAttribute('x2', leaderX);
    if (!(d.kind === 'intro' && d.c === 'he')) {
      const n = (stacks[d.v][d.c] || []).filter(a => t >= a.s + a.d * .5).length;
      d.leader.setAttribute('y2', Math.min(d.endY, BASE - n * STEP) - d.y);
    }
  });
  $$('.bk', sky).forEach(b => b.classList.toggle('dim', !!activeCase && b.dataset.c !== activeCase));
  const u = uAt(t), hx = cx(0) + u * COL;
  const dx = t < 300 ? X0 + (cx(0) - X0) * E.out(t / 300) : hx;
  prog.setAttribute('x2', f1(dx));
  ph.setAttribute('transform', `translate(${f1(hx)} 0)`);
  halo.style.opacity = t > T - 800 ? (Math.sin(Math.PI * clamp((t - T + 800) / 800)) * .3).toFixed(3) : 0;
  $$('.cell[data-v]', lanes).forEach(c => { const v = +c.dataset.v; if (v <= LAST) c.classList.toggle('on', t >= R[v]); });
  const sel = selAt();
  if (sel !== selPrev) {
    bands.forEach((b, i) => b.classList.toggle('on', i === sel));
    $$('.cell[data-v]', lanes).forEach(c => c.classList.toggle('sel', +c.dataset.v === sel));
    const V = VERS[sel];
    readout.innerHTML = `<b>${V.tag}</b>${V.state}`;
    hit.setAttribute('aria-valuenow', sel);
    hit.setAttribute('aria-valuetext', `${V.tag}, ${V.name}`);
    selPrev = sel;
    scrollToCol(sel);
  }
  drawFocusLine(activeCase);
  paintTraceHint(activeCase);
  renderPanel(sel);
  syncPlay();
}

function tick(now) {
  const dt = Math.min(64, now - last); last = now;
  if (mode === 'play') { t += dt * 2.15; if (t >= T) { t = T; stop(); } }
  else if (mode === 'seek') { const d = target - t, step = dt * 5.5; if (Math.abs(d) <= step) { t = target; stop(); } else t += Math.sign(d) * step; }
  apply();
  raf = mode ? requestAnimationFrame(tick) : 0;
}
function kick() { if (!raf) { last = performance.now(); raf = requestAnimationFrame(tick); } }
function stop() { mode = null; playing = false; }
function play() { future = false; if (t >= T - 1) t = 0; mode = 'play'; playing = true; resumeMode = null; kick(); apply(); }
function pause() { stop(); resumeMode = null; apply(); }
function goTo(i) {
  touched = true; targetSel = i;
  if (i === FUTURE) { future = true; target = T; } else { future = false; target = STOP[i]; }
  selPrev = -1;
  if (reduce) { t = target; stop(); apply(); return; }
  mode = 'seek'; playing = false; kick(); apply();
}

const ICON = {
  play: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4 2.5v11l9-5.5z" fill="currentColor"/></svg>',
  pause: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4 2.5h3v11H4zM9 2.5h3v11H9z" fill="currentColor"/></svg>'
};
function syncPlay() {
  const s = playing ? 'pause' : 'play';
  if (playBtn.dataset.s === s) return;
  playBtn.dataset.s = s;
  playBtn.innerHTML = ICON[s] + `<span>${playing ? 'Pause' : 'Play'}</span>`;
  playBtn.setAttribute('aria-label', playing ? 'Pause evolution' : 'Play evolution from v0');
}

/* --------------------------------------------------------- focus + panel */
function trajectoryCase() { return focus; }

function drawFocusLine(id) {
  const pts = [];
  if (id === 'he') {
    // Compare only ES(7) upper bounds; the abstract witness has a different meaning.
    if (t >= 6600) pts.push(`${slotX(3, CI.he, t) + BW / 2},160`, `${slotX(4, CI.he, t) + BW / 2},160`);
  } else if (id) {
    for (let col = 0; col <= LAST; col++) {
      const st = stacks[col][id]; if (!st) continue;
      const n = st.filter(a => t >= a.s + a.d * .5).length; if (!n) continue;
      pts.push(`${slotX(col, CI[id], t) + BW / 2},${BASE - n * STEP - 1}`);
    }
  }
  fline.setAttribute('points', pts.length > 1 ? pts.join(' ') : '');
  fline.style.stroke = id ? `var(--${id})` : '';
  if (id) fline.setAttribute('marker-end', `url(#trace-arrow-${id})`);
  else fline.removeAttribute('marker-end');
}
function paintTraceHint(id) {
  const hint = $('#traceHint'), overview = $('#overview');
  if (overview) { overview.classList.toggle('on', !focus); overview.setAttribute('aria-pressed', String(!focus)); }
  if (!hint) return;
  if (!id) hint.textContent = 'Choose a case to follow its results across versions.';
  else if (id === 'ecc' && t >= ECC_V8_TIME) hint.textContent = 'ECC · From 4 to 13 exact distances. Nine more settled in v8. Select a block for lower or upper bounds.';
  else if (id === 'he') hint.textContent = t >= HE_V7_TIME ? 'Happy Ending · ES(7) ≤ 77 unchanged; working ES(8) ≤ 294, ES(9) ≤ 1100, ES(10) ≤ 3980. Same-input deficits → v7.' : t >= HE_V6_TIME ? 'Happy Ending · fixed v6: m = 7–9 capacities, working ES(9) ≤ 1148; later sector deficits appear in v7.' : 'Happy Ending · ES(7) upper bound 78 → 77; the 25-point witness is separate.';
  else if (id === 'q6') hint.textContent = 'Ruskey–Savage · Q₆ → Q₇ ≥57 (v5) → ≥56 (fixed v6) → every matching (v6 main author working proof). Run: v3 local adaptation.';
  else if (id === 'e86') hint.textContent = 'Erdős 86 · v3 asymptotic Q₄ bound → v6 Q₇ 304 (≤ source), Q₈ 682–683 & Q∞ ≤ 0.5912405943. Run: v3 + coevolution.';
  else if (id === 'dd') hint.textContent = 'Degree–Diameter · v2 historical results → v4 + local DD updates → two D5 improvements feeding v5 maintenance.';
  else hint.textContent = `${CN[id]} · follow this case; repeated blocks carry earlier results forward.`;
}
function focusCase(id, mi = null, force = false) {
  if (!force && id && id === focus && mi === null) id = null;
  focus = id || null; hl = focus ? mi : null;
  $$('.bk', sky).forEach(b => b.classList.toggle('dim', !!focus && b.dataset.c !== focus));
  $$('button[data-case]').forEach(b => { if (b.classList.contains('trace')) return; const on = b.dataset.case === focus; b.classList.toggle('on', on); b.setAttribute('aria-pressed', on); });
  $$('.from', lanes).forEach(f => f.classList.toggle('on', !!focus && f.dataset.cases.split(' ').includes(focus)));
  if (!focus) fline.setAttribute('points', '');
  panelKey = ''; apply();
}
function vlabel(m) { return m.intake ? `${VERS[m.v].tag} intake` : m.span ? 'v1–v2' : VERS[m.v].tag; }
function ddPath() {
  const later = t < 6750 ? ' later' : '';
  return `<ol class="p-path" aria-label="Degree–diameter research and harness feedback">
    <li><b>Earlier research</b><span>Three dated table records, developed with standalone ARIS tools</span></li>
    <li><b>v2 · DD plugin</b><span>Methods, failures and checks become reusable research tools</span></li>
    <li class="hot${later}"><b>v2 + DD run</b><span>(10,4): 2,566 → 2,567 vertices</span></li>
    <li class="pre${later}"><b>v4 · feedback</b><span>Local edit and exact replay examples implemented in the existing DD plugin</span></li>
    <li class="hot${t < DD_TIME ? ' later' : ''}"><b>v4 + local DD updates</b><span>(11,5) 37,632 · (12,5) 42,433 → v5 maintenance</span></li>
  </ol>`;
}
function eccMaintenance() {
  return `<section class="p-plugin-update"><p class="p-eye">ECC · historical main maintenance</p><h4>Place each step in the research tree</h4><p>Identify the branch before searching, reuse existing exclusions, and share computations across branches. Close a parent problem only after checking full coverage.</p><a href="${GH}/blob/main/plugins/ecc/skills/mathrsi-ecc/references/node-research.md">Read the node protocol ↗</a></section>`;
}
function renderPanel(sel) {
  const list = focus ? MS.map((m, i) => [m, i]).filter(([m]) => m.c === focus) : [];
  const reached = list.filter(([m]) => t >= m.t).length;
  const key = focus ? `${focus}|${hl}|${reached}` : `v|${sel}`;
  if (key === panelKey) return; panelKey = key;
  if (!focus) {
    const V = VERS[sel];
    panel.innerHTML = `<div><p class="p-eye">MathRSI harness · ${V.tag} · ${V.state}</p><h3>${V.name}</h3><p class="p-sum">${V.sum}</p>${sel === 4 ? eccMaintenance() : sel === 5 ? '<p class="p-links"><a href="q7.html">Q7 result & methods ↗</a> · <a href="dd-latest.html">DD latest results ↗</a></p>' : V.tag === 'v6' ? '<p class="p-links"><a href="erdos-86-latest.html">Erdős 86 results & methods ↗</a> · <a href="q7.html">Q7 result & methods ↗</a> · <a href="happy-ending-latest.html">Happy Ending results & methods ↗</a></p>' : V.tag === 'v8' ? `<p class="p-links"><a href="ecc-intervals.html">ECC intervals & methods ↗</a><a href="${ECC_PAPER}">Five-parameter paper ↗</a></p>` : V.tag === 'v7' ? '<p class="p-links"><a href="happy-ending-latest.html">Happy Ending results & methods ↗</a> · <a href="q7.html">Q7 result & methods ↗</a></p>' : ''}</div>
      <div><p class="p-eye">Shared base &amp; workflow details in ${V.tag}</p>
      <ul class="p-vlist">${V.fullBase.map(item => `<li>${item}</li>`).join('')}</ul>
      <p class="p-foot">Choose a change label or colored result block to inspect its conclusions and proof evidence.</p></div>`;
    return;
  }
  const c = CASES[CI[focus]];
  const items = list.slice().sort((a, b) => a[0].v - b[0].v || a[0].t - b[0].t);
  panel.innerHTML = `<div style="--c:var(--${c.id})"><p class="p-eye"><span class="dot"></span>${CN[c.id]}</p><h3>${typeof c.title === 'function' ? c.title() : c.title}</h3>${c.quant()}
      <p class="p-status">${typeof c.status === 'function' ? c.status() : c.status}</p>${c.id === 'dd' ? ddPath() : ''}${c.id === 'ecc' && t < ECC_V8_TIME ? eccMaintenance() : ''}
      <p class="p-links"><a href="${typeof c.read === 'function' ? c.read() : c.read}">${((c.id === "ecc" && t >= ECC_V8_TIME) || (c.id === "q6" && t >= Q7_TIME) || (c.id === "dd" && t >= DD_TIME) || (c.id === "e86" && t >= E86_V6_TIME)) ? "Result & methods ↗" : "Read the proof ↗"}<span class="source-language" data-no-i18n>${((c.id === "ecc" && t >= ECC_V8_TIME) || (c.id === "q6" && t >= Q7_TIME) || (c.id === "dd" && t >= DD_TIME) || (c.id === "e86" && t >= E86_V6_TIME)) ? "EN + 中文" : ["pb", "ecc", "dd"].includes(c.id) ? "EN" : "中文"}</span></a><a href="${c.plugin}">Plugin source ↗</a><button class="p-close" type="button" data-close>Close ✕</button></p></div>
    <div style="--c:var(--${c.id})"><p class="p-eye">Mathematical results</p><ol class="p-ms">${items.filter(([m]) => isOutcome(m)).map(([m, i]) => {
      const on = t >= m.t;
      return `<li class="${on ? '' : 'later'}${hl === i ? ' hl' : ''}"><span class="p-v">${vlabel(m)}</span><span class="p-k k-${m.k}">${m.tag}</span><span class="p-t">${m.text}${on ? '' : `<em>appears at ${vlabel(m)}</em>`}</span></li>`;
    }).join('')}</ol><details class="p-assurance"><summary>Proof, verification &amp; open questions</summary><ol class="p-ms">${items.filter(([m]) => !isOutcome(m)).map(([m]) => `<li class="${t >= m.t ? '' : 'later'}"><span class="p-v">${vlabel(m)}</span><span class="p-k k-${m.k}">${m.tag}</span><span class="p-t">${m.text}</span></li>`).join('')}</ol></details>${c.id === 'ecc' ? '<p class="p-foot">Historical five-interval snapshot: three exact distances were settled at v0, and d₂(42,16)=12 follows from a 2020 theorem; the reusable checkers cover the 172 parent exclusions, and 16 ≤ d₂(45,11) ≤ 17 remains open.</p>' : ''}</div>`;
}

/* ---------------------------------------------------------- card visuals */
const wrap = s => `<svg viewBox="0 0 320 200" aria-hidden="true" focusable="false">${s}</svg>`;
const VIZ = {
  pb() {
    const xs = [110, 160, 210], ys = [50, 100, 150], col = [[0,1,0],[1,0,1],[1,1,0]];
    let s = '';
    ys.forEach(y => { s += `<rect class="hg-edge" x="88" y="${y - 16}" width="144" height="32" rx="16"/>`; });
    xs.forEach(x => { s += `<rect class="hg-edge" x="${x - 16}" y="28" width="32" height="144" rx="16"/>`; });
    ys.forEach((y, r) => xs.forEach((x, c) => { s += `<circle cx="${x}" cy="${y}" r="9.5" style="fill:${col[r][c] ? '#F2A541' : 'var(--pb)'}" stroke="#fff" stroke-width="2"/>`; }));
    return wrap(s);
  },
  ecc() {
    const N = [42, 43, 44, 45], K = [10, 11, 16], x = n => 74 + (n - 42) * 58, Y = { 10: 44, 11: 90, 16: 136 };
    const V = { '43,10': ['16','s'], '44,10': ['17','s'], '44,11': ['16','s'], '42,16': ['12','l'], '45,11': ['16–17','o'] };
    let s = '<defs><pattern id="ecc-hatch" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="6" height="6" fill="#fff"/><line x1="0" y1="0" x2="0" y2="6" style="stroke:var(--ecc);stroke-opacity:.35" stroke-width="2"/></pattern></defs>';
    s += '<text class="vt it" x="30" y="30">n</text><text class="vt it" x="30" y="159">k</text>';
    N.forEach(n => { s += `<text class="vt" x="${x(n) + 25}" y="30" text-anchor="middle">${n}</text>`; });
    K.forEach(k => { s += `<text class="vt" x="62" y="${Y[k] + 23}" text-anchor="end">${k}</text>`; });
    K.forEach(k => N.forEach(n => {
      const v = V[`${n},${k}`], X = x(n), Yk = Y[k];
      if (!v) { s += `<rect class="e-empty" x="${X}" y="${Yk}" width="50" height="36" rx="7"/>`; return; }
      s += `<rect class="e-${v[1]}" x="${X}" y="${Yk}" width="50" height="36" rx="7"${v[1] === 'o' ? ' fill="url(#ecc-hatch)"' : ''}/><text class="e-t ${v[1]}" x="${X + 25}" y="${Yk + 23}" text-anchor="middle">${v[0]}</text>`;
    }));
    return wrap(s);
  },
  dd() {
    const P = [];
    for (let r of [80, 38]) for (let i = 0; i < 5; i++) { const a = (-90 + 72 * i) * Math.PI / 180; P.push([160 + r * Math.cos(a), 104 + r * Math.sin(a)]); }
    let s = '';
    for (let i = 0; i < 5; i++) for (const [a, b] of [[i, (i + 1) % 5], [i, i + 5], [i + 5, (i + 2) % 5 + 5]])
      s += `<line class="dd-e" x1="${f1(P[a][0])}" y1="${f1(P[a][1])}" x2="${f1(P[b][0])}" y2="${f1(P[b][1])}"/>`;
    P.forEach(p => { s += `<circle class="dd-v" cx="${f1(p[0])}" cy="${f1(p[1])}" r="7.5"/>`; });
    return wrap(s);
  },
  e86() {
    const e = [[30,0],[0,30],[14,-12],[80,8]], o = [98, 49];
    const P = Array.from({ length: 16 }, (_, v) => { let x = o[0], y = o[1]; for (let j = 0; j < 4; j++) if (v >> j & 1) { x += e[j][0]; y += e[j][1]; } return [x, y]; });
    let s = '';
    for (let v = 0; v < 16; v++) for (let j = 0; j < 4; j++) if (!(v >> j & 1)) { const w = v | 1 << j; s += `<line class="q4" x1="${P[v][0]}" y1="${P[v][1]}" x2="${P[w][0]}" y2="${P[w][1]}"/>`; }
    s += `<polygon class="c4" points="${[0, 1, 3, 2].map(i => P[i].join(',')).join(' ')}"/>`;
    P.forEach(p => { s += `<circle class="q4v" cx="${p[0]}" cy="${p[1]}" r="2.6"/>`; });
    const X = v => 30 + (v - .48) * 260 / .14, a = X(.5), b = X(.5912405943), c = X(.60318);
    s += `<rect class="gap" x="${f1(a)}" y="146" width="${f1(b - a)}" height="8" rx="4"/><line class="axis" x1="30" y1="150" x2="290" y2="150"/>`;
    s += `<circle class="m-half" cx="${f1(a)}" cy="150" r="5"/><circle class="m-prev" cx="${f1(c)}" cy="150" r="5"/><circle class="m-new" cx="${f1(b)}" cy="150" r="6"/>`;
    s += `<text class="vt" x="${f1(a)}" y="178" text-anchor="middle">1/2</text><text class="vt new" x="${f1(b)}" y="178" text-anchor="middle">0.59124</text><text class="vt" x="${f1(c + 6)}" y="132" text-anchor="middle">0.60318</text>`;
    return wrap(s);
  },
  q6() {
    const A = [0, 31, 58, 92, 119, 151], L = [1, .93, 1.04, .9, 1.02, .95], S = 46;
    const D = A.map((a, j) => [Math.cos(a * Math.PI / 180) * L[j] * S, -Math.sin(a * Math.PI / 180) * L[j] * S]);
    const half = D.reduce((h, d) => [h[0] + d[0] / 2, h[1] + d[1] / 2], [0, 0]);
    const P = Array.from({ length: 64 }, (_, v) => { let x = 160 - half[0], y = 100 - half[1]; for (let j = 0; j < 6; j++) if (v >> j & 1) { x += D[j][0]; y += D[j][1]; } return [x, y]; });
    const line = (p, q, cls) => `<line class="${cls}" x1="${f1(p[0])}" y1="${f1(p[1])}" x2="${f1(q[0])}" y2="${f1(q[1])}"/>`;
    let s = '<g class="q-cube">';
    for (let v = 0; v < 64; v++) for (let j = 0; j < 6; j++) if (!(v >> j & 1)) s += line(P[v], P[v | 1 << j], '');
    s += '</g>';
    const g = i => i ^ (i >> 1); // reflected Gray code: a Hamilton cycle of Q6
    s += `<polygon class="q-cyc" points="${Array.from({ length: 64 }, (_, i) => P[g(i)].map(f1).join(',')).join(' ')}"/>`;
    for (let m = 0; m < 16; m++) s += line(P[g(4 * m)], P[g(4 * m + 1)], 'q-match'); // disjoint cycle edges = a matching
    P.forEach(p => { s += `<circle class="q-v" cx="${f1(p[0])}" cy="${f1(p[1])}" r="2"/>`; });
    return wrap(s);
  },
  he() {
    const P = Array.from({ length: 7 }, (_, i) => { const a = (-90 + 360 / 7 * i) * Math.PI / 180; return [160 + 54 * Math.cos(a), 104 + 54 * Math.sin(a)]; });
    const cup = [[22,112],[42,138],[62,146],[82,140]], cap = [[238,84],[258,58],[278,50],[298,56]];
    let s = `<polygon class="he-poly" points="${P.map(p => p.map(f1).join(',')).join(' ')}"/>`;
    P.forEach(p => { s += `<circle class="he-v" cx="${f1(p[0])}" cy="${f1(p[1])}" r="4.5"/>`; });
    for (const ch of [cup, cap]) { s += `<polyline class="he-ch" points="${ch.map(p => p.join(',')).join(' ')}"/>`; ch.forEach(p => { s += `<circle class="he-p" cx="${p[0]}" cy="${p[1]}" r="3.8"/>`; }); }
    s += '<text class="vt" x="52" y="176" text-anchor="middle">cup</text><text class="vt" x="268" y="32" text-anchor="middle">cap</text>';
    return wrap(s);
  }
};

/* -------------------------------------------------------------- workflow */
const RP = [
  { v: '≈ 0.59175', h: 'Working-set candidate', p: 'A candidate reaches ≈0.59175 on the restricted working set; full-domain verification is still needed.', on: ['prove'] },
  { v: '≈ 0.83472', h: 'Full-domain check fails', p: 'The full-domain maximum is ≈0.83472, far above the working-set claim. Previous certificate retained.', bad: ['verify'] },
  { v: '800 rows', h: 'Counterexample returned', p: 'The violated rows go back to the route; later refinements consume them.', on: ['route'], arc: 'vr' },
  { v: '≤ 0.59155154', h: 'Exact certificate', p: 'An exact Gram certificate with full local coverage and analytic averaging gives the final bound.', on: ['verify', 'handoff'] }
];
let rp = 0, rpTimer = null;
const rpBtn = $('#rpPlay');

function buildFlow() {
  const S = [['prepare','Prepare','literature · spec'],['route','Route','cross-model review'],['prove','Prove','parallel proof work'],['verify','Verify','assemble · check'],['handoff','Handoff','deliver · record']];
  const X = i => 100 + 200 * i, Y = 92;
  let s = '<defs><marker id="mg" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 1L9 5L0 9z" fill="#AEB6C2"/></marker><marker id="mh" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 1L9 5L0 9z" fill="#2B59FF"/></marker></defs>';
  for (let i = 0; i < 4; i++) s += `<line class="fw" x1="${X(i) + 80}" y1="${Y}" x2="${X(i + 1) - 84}" y2="${Y}" marker-end="url(#mg)"/>`;
  [['rp','M300 62C300 20 100 20 100 62','new literature question',200,20],
   ['vp','M700 122C700 160 500 160 500 122','local gap',600,170],
   ['vr','M700 122C700 214 300 214 300 122','counterexample returned',500,214]].forEach(([id, d, l, lx, ly]) => {
    s += `<path class="arc" data-arc="${id}" d="${d}" marker-end="url(#mg)"/><text class="arc-l" data-arc="${id}" x="${lx}" y="${ly}" text-anchor="middle">${l}</text>`;
  });
  S.forEach(([id, n, sub], i) => {
    s += `<g class="st" data-st="${id}"><rect x="${X(i) - 78}" y="${Y - 30}" width="156" height="60" rx="30"/><text class="st-n" x="${X(i)}" y="${Y - 3}" text-anchor="middle">${n}</text><text class="st-s" x="${X(i)}" y="${Y + 18}" text-anchor="middle">${sub}</text></g>`;
  });
  $('#flow').innerHTML = `<svg viewBox="0 0 1000 228" role="img" aria-label="Five adaptive stages: Prepare, Route, Prove, Verify, Handoff, with return paths for new literature questions, local gaps and returned counterexamples">${s}</svg>`;
  $('#rpSteps').innerHTML = RP.map((r, i) => `<li class="${r.bad ? 'bad' : ''}"><button type="button" data-step="${i}"><span class="rp-n">Step ${i + 1}</span><span class="rp-v">${r.v}</span><span class="rp-h">${r.h}</span><span class="rp-p">${r.p}</span></button></li>`).join('');
}
function paintRP() {
  const st = RP[rp];
  $$('#flow .st').forEach(g => {
    g.classList.toggle('hot', !!st.on && st.on.includes(g.dataset.st));
    g.classList.toggle('bad', !!st.bad && st.bad.includes(g.dataset.st));
  });
  $$('#flow [data-arc]').forEach(a => {
    const h = st.arc === a.dataset.arc;
    a.classList.toggle('hot', h);
    if (a.tagName === 'path') a.setAttribute('marker-end', h ? 'url(#mh)' : 'url(#mg)');
  });
  $$('#rpSteps li').forEach((li, i) => { li.classList.toggle('on', i === rp); li.querySelector('button').setAttribute('aria-current', i === rp ? 'step' : 'false'); });
}
function rpStop() { clearTimeout(rpTimer); rpTimer = null; rpBtn.textContent = 'Play'; }
function rpRun() { if (rp >= RP.length - 1) { rpStop(); return; } rpTimer = setTimeout(() => { rp++; paintRP(); rpRun(); }, 2400); }

/* ---------------------------------------------------------------- events */
function uFromEvent(e) {
  const pt = sky.createSVGPoint(); pt.x = e.clientX; pt.y = e.clientY;
  const p = pt.matrixTransform(sky.getScreenCTM().inverse());
  return Math.max(0, Math.min(FUTURE, (p.x - cx(0)) / COL));
}
function bind() {
  playBtn.addEventListener('click', () => { touched = true; playing ? pause() : play(); });
  $('#replay').addEventListener('click', () => { touched = true; t = 0; play(); });

  let dragging = false;
  hit.addEventListener('pointerdown', e => { touched = true; dragging = true; hit.setPointerCapture(e.pointerId); stop(); future = false; t = tFromU(Math.min(LAST, uFromEvent(e))); apply(); });
  hit.addEventListener('pointermove', e => { if (!dragging) return; t = tFromU(Math.min(LAST, uFromEvent(e))); apply(); });
  hit.addEventListener('pointerup', e => { if (!dragging) return; dragging = false; goTo(Math.round(uFromEvent(e))); });
  hit.addEventListener('pointercancel', () => { dragging = false; });
  hit.addEventListener('keydown', e => {
    const s = mode === 'seek' ? targetSel : selAt();
    let n = null;
    if (e.key === 'ArrowRight' || e.key === 'ArrowUp') n = Math.min(FUTURE, s + 1);
    else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') n = Math.max(0, s - 1);
    else if (e.key === 'Home') n = 0;
    else if (e.key === 'End') n = FUTURE;
    else if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); touched = true; playing ? pause() : play(); return; }
    if (n !== null) { e.preventDefault(); goTo(n); }
  });

  sky.addEventListener('click', e => {
    if (e.target.closest('a')) return;
    const block = e.target.closest('.bk[data-m]');
    if (block) focusCase(block.dataset.c, +block.dataset.m, true);
  });
  sky.addEventListener('keydown', e => {
    const b = e.target.closest('.delta-tag[data-m]');
    if (b && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); focusCase(b.dataset.c, +b.dataset.m, true); }
  });
  const overview = $('#overview');
  if (overview) overview.addEventListener('click', () => focusCase(null, null, true));
  document.addEventListener('click', e => {
    const tr = e.target.closest('.trace');
    if (tr) { focusCase(tr.dataset.case, null, true); $('#evolution').scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' }); return; }
    const b = e.target.closest('button[data-case]'); if (b) { focusCase(b.dataset.case); return; }
    const g = e.target.closest('[data-goto]'); if (g) { goTo(+g.dataset.goto); return; }
    if (e.target.closest('[data-close]')) focusCase(null, null, true);
    const st = e.target.closest('[data-step]'); if (st) { rpStop(); rp = +st.dataset.step; paintRP(); }
  });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && focus) focusCase(null, null, true); });

  rpBtn.addEventListener('click', () => { if (rpTimer) { rpStop(); return; } if (rp >= RP.length - 1) { rp = 0; paintRP(); } rpBtn.textContent = 'Pause'; rpRun(); });
  $('#rpPrev').addEventListener('click', () => { rpStop(); rp = Math.max(0, rp - 1); paintRP(); });
  $('#rpNext').addEventListener('click', () => { rpStop(); rp = Math.min(RP.length - 1, rp + 1); paintRP(); });

  const nav = $('#nav');
  addEventListener('scroll', () => nav.classList.toggle('scrolled', scrollY > 8), { passive: true });

  if ('IntersectionObserver' in window) {
    new IntersectionObserver(es => es.forEach(en => {
      if (!en.isIntersecting && mode) { resumeMode = mode; stop(); apply(); }
      else if (en.isIntersecting && resumeMode) { mode = resumeMode; resumeMode = null; playing = mode === 'play'; kick(); }
    }), { threshold: .15 }).observe(stage);
    new IntersectionObserver(es => es.forEach(en => { if (!en.isIntersecting && rpTimer) rpStop(); }), { threshold: .1 }).observe($('#replay-box'));
  }
}

/* ----------------------------------------------------- interactive title */
function bindWordmark() {
  const mark = $('.wordmark'), plane = $('.wordmark-plane', mark);
  let bounds = null, bounce = null, glowTimer = null;
  const reset = () => {
    mark.classList.remove('is-active');
    for (const key of ['shift-x','shift-y']) mark.style.setProperty('--' + key, '0px');
    for (const key of ['tilt-x','tilt-y']) mark.style.setProperty('--' + key, '0deg');
  };
  mark.addEventListener('pointerenter', e => {
    if (e.pointerType !== 'mouse') return;
    bounds = mark.getBoundingClientRect();
    mark.classList.add('is-active');
  });
  mark.addEventListener('pointermove', e => {
    if (e.pointerType !== 'mouse' || !bounds) return;
    const x = clamp((e.clientX - bounds.left) / bounds.width);
    const y = clamp((e.clientY - bounds.top) / bounds.height);
    mark.style.setProperty('--light-x', `${x * 100}%`);
    mark.style.setProperty('--light-y', `${y * 100}%`);
    if (reduce) return;
    mark.style.setProperty('--shift-x', `${(x - .5) * 10}px`);
    mark.style.setProperty('--shift-y', `${(y - .5) * 6}px`);
    mark.style.setProperty('--tilt-x', `${(.5 - y) * 6}deg`);
    mark.style.setProperty('--tilt-y', `${(x - .5) * 9}deg`);
  });
  mark.addEventListener('pointerleave', reset);
  mark.addEventListener('pointercancel', reset);
  mark.addEventListener('click', () => {
    clearTimeout(glowTimer);
    mark.classList.add('pulsing');
    glowTimer = setTimeout(() => mark.classList.remove('pulsing'), 650);
    if (reduce) return;
    if (bounce) bounce.cancel();
    const base = getComputedStyle(plane).transform;
    bounce = plane.animate([
      { transform:base, offset:0 },
      { transform:'perspective(800px) translateY(-9px) scale(1.025) rotate(-.4deg)', offset:.25 },
      { transform:'perspective(800px) translateY(2px) scale(.992)', offset:.55 },
      { transform:base, offset:1 }
    ], { duration:620, easing:'cubic-bezier(.22,1,.36,1)' });
  });
}

/* ------------------------------------------------------------------ init */
buildSky();
buildLanes();
$$('[data-viz]').forEach(v => { v.innerHTML = VIZ[v.dataset.viz](); });
buildFlow();
paintRP();
bind();
bindWordmark();

const r = stage.getBoundingClientRect();
if (!reduce && r.top < innerHeight * .8 && r.bottom > 0) {
  t = 0; apply();                                   // one intentional entry: v0 → v5, then rest on the current release
  setTimeout(() => { if (!touched) play(); else if (!mode && t === 0) { t = T; apply(); } }, 250);
} else {
  t = T; apply();                                   // final state by default
}
})();
