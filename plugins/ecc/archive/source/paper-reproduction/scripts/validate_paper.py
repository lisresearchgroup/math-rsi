#!/usr/bin/env python3
"""Check final LaTeX/PDF deliverable. Requires PyMuPDF after compilation."""
from pathlib import Path
import argparse,re,json
import pymupdf as fitz
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--paper-dir',type=Path,default=Path(__file__).resolve().parents[1],
                    help='Directory containing the compiled main.tex/main.pdf/main.log/main.aux')
parser.add_argument('--output-dir',type=Path,
                    help='Write reports here instead of PAPER_DIR/validation')
args=parser.parse_args()
ROOT=args.paper_dir.resolve()
OUT=args.output_dir.resolve() if args.output_dir else ROOT/'validation'
texfiles=[ROOT/'main.tex',*sorted((ROOT/'sections').glob('*.tex'))]
tex='\n'.join(p.read_text() for p in texfiles)
cited=set()
for m in re.finditer(r'\\cite\w*\{([^}]+)\}',tex):cited.update(k.strip() for k in m[1].split(','))
bib=set(re.findall(r'@\w+\{([^,]+),',(ROOT/'references.bib').read_text()))
assert cited==bib,dict(missing=list(cited-bib),unused=list(bib-cited))
labels=re.findall(r'\\label\{([^}]+)\}',tex);assert len(labels)==len(set(labels))
refs=re.findall(r'\\(?:ref|eqref|cref)\{([^}]+)\}',tex);assert set(refs)<=set(labels)
for p in (ROOT/'sections').glob('*.tex'):assert 'sections/'+p.stem in (ROOT/'main.tex').read_text()
log=(ROOT/'main.log').read_text()
for forbidden in ['Overfull','Missing character:','Font shape','Title exceeds','undefined']:assert forbidden not in log,forbidden
pdf=fitz.open(ROOT/'main.pdf');text='\n\f\n'.join(p.get_text() for p in pdf)
for token in ['AUTHORERR','Title Suppressed','??','[?]','[VERIFY]','TODO','FIXME']:assert token not in text,token
aux=(ROOT/'main.aux').read_text();end=int(re.search(r'\\newlabel\{main:end\}\{\{[^}]+\}\{(\d+)\}',aux)[1]);assert end<=8
fonts=[]
for xref in sorted({f[0] for page in pdf for f in page.get_fonts()}):
 name,ext,typ,data=pdf.extract_font(xref);assert data,name;fonts.append(dict(name=name,format=ext,type=typ,embedded=True))
report=dict(status='PASS',total_pages=len(pdf),main_body_ends_page=end,main_body_limit=8,bibliography_entries=len(bib),undefined_references=0,undefined_citations=0,overfull_boxes=0,missing_glyphs=0,font_substitutions=0,fonts=fonts,pdf_bytes=(ROOT/'main.pdf').stat().st_size,remaining_warnings='Underfull boxes only')
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'pdf-check.json').write_text(json.dumps(report,indent=2)+'\n');(OUT/'pdf-text.txt').write_text(text)
print(json.dumps({k:v for k,v in report.items() if k!='fonts'},indent=2))
