# I1 reading: Lemma 4, JCMCC 59 (2006), p.85

Source: `ref/lemma4-jcmcc-2006.pdf` (sha256 f037d7c7...e59bd8), PDF page 53 = printed p.85. Text read from page images (scan, no text layer). Quotes below transcribed from `jcmcc2006_p85_lower_230.png`; typography (e.g. spacing) normalised only in math layout.

## Lemma 4, verbatim (printed p.85)
Lead-in sentence:
> As the problem of whether a linear [39,10,16] code exists has not been solved until now, we give the answer in the following lemma.

Statement:
> **Lemma 4** *No linear* [39, 10, 16] *code exists.*

## Proof, verbatim
> *Proof.* Jaffe [14] proved that if a [39,10,16] code exists it is doubly-even with weight enumerator W(y) = 1 + 367y^16 + 414y^20 + 240y^24 + 2y^28. Then its residual code with respect to a codeword of weight 28 is a linear [11,9,2] even code. Exactly four inequivalent [11,9,2] even codes without zero coordinates exist but none of them can be extended to a doubly-even [39,10,16] code. □

Sentence immediately after the proof:
> This lemma gives that the highest possible weight of a SO [39,10] code is 14, but the number of inequivalent SO [39,10,14] codes is too large so they could not be computed with a reasonable amount of CPU time.

(The preceding text on p.85 is the [40,5,20] SO-code generator matrices A_{40,5,1..3} and weight enumerators W_{40,5,1}=1+28y^20+2y^24+y^32, W_{40,5,2}=1+27y^20+3y^24+y^28, W_{40,5,3}=1+26y^20+5y^24.)

## Domain of the lemma (what the text says)
- The lemma is stated for "linear [39,10,16] code", with no "self-orthogonal"/"SO" qualifier. The lead-in sentence likewise says "a linear [39,10,16] code". Printed p.34 (Introduction): "A binary linear [n,k] code C is a k-dimensional vector subspace of F_2^n ... In the sequel, all codes are assumed to be binary." and defines even/doubly-even ("If all codewords in an even code have weights divisible by 4, we say the code is doubly-even"). So as printed, Lemma 4 covers ALL binary linear [39,10,16] codes (binary by the standing convention), not only self-orthogonal ones.
- The proof does not assume self-orthogonality either: step 1 is Jaffe's result "if a [39,10,16] code exists it is doubly-even with weight enumerator ..." (general existence statement, attributed to [14]); the self-orthogonality connection only appears in the post-proof sentence (the lemma is used to conclude the SO [39,10] maximum distance is 14).
- (Not independently checked: whether a doubly-even code with that enumerator is automatically self-orthogonal; that is mathematics, not stated as a domain restriction.)

## What the proof depends on
1. Reference [14]: Jaffe's online table ("Information about binary linear codes", electronic table) for: any [39,10,16] code is doubly-even with W(y)=1+367y^16+414y^20+240y^24+2y^28. No derivation is given in the paper.
2. A residual-code step: the residual of the code w.r.t. a weight-28 codeword is a linear [11,9,2] even code (no justification written; standard residual-code fact, not cited).
3. An unreferenced classification claim, "Exactly four inequivalent [11,9,2] even codes without zero coordinates exist", and the exhaustive check "none of them can be extended to a doubly-even [39,10,16] code". No explicit citation of a program or reference for this; the paper's methods are computer searches generally (abstract p.33/34: "The results were obtained via two independent computer searches"), but for Lemma 4 the text itself names no program or output file. Reference [13] (Jaffe, Discrete Math. 223 (2000)) is not cited in the lemma's proof; only [14] is.

## Reference entry for Jaffe, verbatim (printed p.87)
> [14] D. B. Jaffe, Information about binary linear codes [electronic table; online], available at <URL: http://www.math.unl.edu/~djaffe/codes/webcodes/codeform.html>.

(Adjacent entry, for disambiguation, not cited in Lemma 4:)
> [13] D. B. Jaffe, Optimal binary linear codes of length ≤ 30, Discrete Math. 223 (2000), 135-155.

The journal spells the name "Jaffe" in refs (and "Jaffe" in the proof). Note the journal ref [14] number matches the proof citation "[14]"; the preprint numbering is the same ([13] and [14]).

## Table value / [39,10,15] mention in the published text
- In the printed p.85 text the only value statement is "the highest possible weight of a SO [39,10] code is 14" (SO, i.e. d=14 for self-orthogonal [39,10]). No mention of "[39,10,15]" on p.85. I did not read the journal's Table 1 pages (not located/inspected in the scan), so the journal's n=39,k=10 table entry is NOT verified from the scan. Search of other journal pages for "[39,10,15]" was not done (no text layer).

## Author preprint (`ref/sopaper12-author-preprint.pdf`, TeX output 2004-12-10)
Text-extracted with PyMuPDF; contains the same lead-in sentence, Lemma 4 and proof, on **PDF page 31 (printed p.31), directly above the "References" heading**, wording identical (verbatim from extraction):
> As the problem of whether a linear [39,10,16] code exists has not been solved until now, we give the answer in the following lemma. Lemma 4 No binary linear [39, 10, 16] code exists. Proof. Jaffe [14] proved that if a [39,10,16] code exists it is doubly-even with weight enumerator W(y) = 1+367y16 +414y20 +240y24 +2y28 [14]. Then its residual code with respect to a codeword of weight 28 is a linear [11, 9, 2] even code. Exactly four inequivalent [11,9,2] even codes without zero coordinates exist but none of them can be extended to a doubly-even [39,10,16] code. □ This lemma gives that the highest possible weight of a SO [39,10] code is 14, but the number of inequivalent SO [39,10,14] codes is too large so they could not be computed with a reasonable amount of CPU time.

Difference from the published version: the preprint's Lemma 4 reads "No **binary** linear [39,10,16] code exists"; the published reads "No linear [39,10,16] code exists" (binary only via the standing convention of p.34). The preprint adds "[14]" after the enumerator and lists "[14] D. B. Jaffe, Information about binary linear codes [electronic table; online], available at <URL: http://www.math.unl.edu/~djaffe/codes/webcodes/codeform.html>." (page 32). The preprint's Table 1 (page 33 extraction) row n=39 lists, in the k=10 column, d=14 with no count given (text-extraction reading: "39 | 20 12 | 20 4 | 18 50 | 16 | 16 | 16 | 16 | 14"); this is from machine text extraction, not an image read.

## Corroboration only (not proof): codetables.de, binary n=39, k=10
Fetched 2026-11-22: http://www.codetables.de/BKLC/BKLC.php?q=2&n=39&k=10 (HTTP 200; raw saved as `codetables_39_10.html`).
> Bounds on linear codes [39,10] over GF(2)
> lower bound: 15
> upper bound: 15
> Construction of a linear code [39,10,15] over GF(2) ... Construction type: X ... last modified: 2001-01-30
> From Brouwer's table (as of 2007-02-13)
> Lb(39,10) = 15 X
> Ub(39,10) = 15 Bou
> References: **Bou:** I. Boukliev, *Some new bounds on minimum length for quaternary codes of dimension five*, preprint, July 1994.  **X:** (empty)

Observation: the page's stated upper-bound reference "Bou" is the text above (a 1994 preprint titled on quaternary codes, as printed on the page); it does not name the 2006 JCMCC paper. The page's data is "as of 2007-02-13" (Brouwer's table) and page footer "Last change: 30.12.2011".
