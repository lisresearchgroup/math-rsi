from pathlib import Path
from html import escape
import json
P=Path(__file__).parent
D=json.loads((P/'data.json').read_text())
COL=['#4C5BD4','#0E9384','#D9822B','#D9467A','#0EA5E9','#65A30D']
def render(lang):
 z=lang=='zh'; a=[]
 def t(x,y,s,size=17,color='#3D4655',weight=400,anchor='start'):
  a.append(f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" font-weight="{weight}" text-anchor="{anchor}">{escape(str(s))}</text>')
 def line(x,y,X,Y,c='#D3D8E0',w=1):a.append(f'<line x1="{x}" y1="{y}" x2="{X}" y2="{Y}" stroke="{c}" stroke-width="{w}"/>')
 def rect(x,y,w,h,c):a.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="{c}"/>')
 for i,key in enumerate(['pb','ecc','dd','e86','q6','he']):
  x=32+(i%2)*450;y=32+(i//2)*300;c=COL[i]
  t(x,y+21,D[key]['name'][lang],22,c,650)
  if key=='pb':
   t(x,y+50,'逐点 + 统一下界' if z else 'Pointwise + uniform bounds',18,'#0B1220',550)
   line(x+20,y+167,x+386,y+167)
   for j,g in enumerate(D[key]['gains']):
    bx=x+30+j*46;h=g*2.2;rect(bx,y+167-h,20,h,c);t(bx+10,y+159-h,'+'+str(g),15,c,600,'middle');t(bx+10,y+190,str(5+j),15,anchor='middle')
   t(x,y+218,'k = 5–12 · '+('相对指定参考界的增益' if z else 'gains over stated references'),16)
   t(x,y+246,'统一定理：所有 k ≥ 12' if z else 'Uniform theorem: every k ≥ 12',18,c,550)
  elif key=='ecc':
   e=D[key]['current'];counts=e['counts']
   t(x,y+50,'v8 · 57 个收紧区间' if z else 'v8 · 57 tightened intervals',18,'#0B1220',550)
   t(x,y+89,'构造下界' if z else 'Constructive lower bounds',17,'#3D4655',550)
   t(x+380,y+91,counts['lower'],30,c,650,'end')
   line(x,y+109,x+390,y+109,'#E4E7EC')
   t(x,y+143,'已确立的上界改进' if z else 'Established upper updates',17,'#3D4655',550)
   t(x+380,y+145,counts['established_upper'],30,c,650,'end')
   t(x,y+176,'另有 2 个暂定上界 · 待来源方验收' if z else '+ 2 provisional upper updates · source-pending',16,'#667085')
   t(x,y+215,'13 个已确认精确值 + 2 个待验收' if z else '13 confirmed exact values + 2 pending',17,c,600)
   t(x,y+244,'此前 5 个 + 新增 52 个 · 含文献推论' if z else '5 previous + 52 added · includes corollaries',15)
   t(x,y+265,'构造与排除分别计数；并非 57 个新定理' if z else 'Constructions and exclusions counted separately',14,'#667085')
  elif key=='dd':
   t(x,y+50,'各组参数下的最佳构造' if z else 'Our best constructions by setting',18,'#0B1220',550)
   for j,r in enumerate(D[key]['settings']):
    yy=y+92+j*40;t(x,yy,r['parameter'],18);t(x+370,yy,f"{r['vertices']:,}",25,c,650,'end')
   t(x,y+256,'顶点数 · 四组展示参数' if z else 'Vertices · four showcased settings',16)
  elif key=='e86':
   t(x,y+50,'无四圈超立方体的有限维与渐近界' if z else 'Finite & asymptotic C₄-free cube bounds',17,'#0B1220',550)
   t(x,y+84,'Q₇: 304',18,'#0B1220',600);t(x+112,y+84,'304构造已验；上界按原包报告' if z else '≥304 verified; ≤304 source report',14,'#667085')
   t(x,y+114,'Q₈: 682–683',18,'#0B1220',600);t(x+138,y+114,'682 仍开放 · 暂定审查' if z else '≤682 open · audit provisional',14,'#667085')
   t(x,y+148,'Q∞: 0.60318 → ≤ 0.5912405943',20,c,650)
   X=lambda v:x+20+(v-.5)/.11*360
   line(X(.5),y+194,X(.61),y+194,'#667085',2)
   for v in [.5,.5912405943,.60318]:
    xx=X(v);line(xx,y+186,xx,y+202,c,2)
   t(X(.5),y+222,'0.5',15,anchor='middle');t(X(.5912405943),y+179,'T3/T4',14,c,600,'end');t(X(.60318)+4,y+222,'参考' if z else 'prior',15,anchor='middle')
   t(x,y+254,'T4 ≤ 0.5912405942 · 猜想值 1/2 开放' if z else 'T4 ≤ 0.5912405942 · Conjecture 1/2 open',15)
  elif key=='q6':
   t(x,y+52,'Q₇ · 任意匹配' if z else 'Q₇ · every matching',23,'#0B1220',600)
   t(x,y+82,'均可扩展为保留原边的 Hamilton 圈' if z else 'extends to a Hamilton cycle, keeping every edge',17,c,600)
   t(x,y+117,'128 个顶点 · 空匹配至完美匹配' if z else '128 vertices · empty to perfect matchings',17)
   t(x,y+153,'完整作者工作证明 · 2026-11-19' if z else 'Full author working proof · 2026-11-19',17,'#0B1220',550)
   t(x,y+183,'待外部同行评议 · 无 Lean' if z else 'External peer review pending · no Lean',16)
   t(x,y+221,'保留 Q₆ 全称定理' if z else 'Universal Q₆ theorem retained',18,c,550)
   t(x,y+256,'至多六方向提升：指定端点 P₆ + 引用结果' if z else '≤6 directions via endpoint P₆ + imports',15)
  else:
   t(x,y+50,'Signotope 容量与平面阈值 (m = 7, 8, 9)' if z else 'Signotope capacities & thresholds (m = 7–9)',17,'#0B1220',550)
   t(x,y+90,'m = 7: ES(7) ≤ 77',19,'#0B1220',600);t(x+198,y+90,'78 → 77 · 工作稿' if z else '78 → 77 · working',15,'#667085')
   t(x,y+130,'m = 8: N(8,6,6) ≤ 61',19,c,650);t(x+206,y+130,'signotope · N(8,8,8) ≤ 318',13.5,'#667085')
   t(x,y+172,'m = 9: ES(9) ≤ 1148',21,c,650);t(x+224,y+172,'对比 1508 / 1501*' if z else 'vs. 1508 / 1501*',15,'#667085')
   t(x,y+214,'已复核整数对偶 C₉ ≤ 688 · D₉ ≤ 458' if z else 'Replayed duals C₉ ≤ 688 · D₉ ≤ 458',16,'#0B1220',550)
   t(x,y+254,'五套有限证书已复核 · 装配手稿待独立审阅' if z else '5 finite suites replayed · assembly review pending',15)
  if i<4:line(x,y+280,x+398,y+280,'#E4E7EC')
 return '<svg xmlns="http://www.w3.org/2000/svg" width="900" height="934" viewBox="0 0 900 934" role="img"><title>'+('MathRSI 六领域成果' if z else 'MathRSI results across six domains')+'</title><rect width="900" height="934" fill="white"/><g font-family="Arial, PingFang SC, Microsoft YaHei, sans-serif">'+''.join(a)+'</g></svg>'
if __name__=='__main__':
 import argparse
 parser=argparse.ArgumentParser(description='Generate bilingual SVG overviews; optionally render PNG previews.')
 parser.add_argument('--png',action='store_true',help='Also export PNGs using Playwright Chromium')
 args=parser.parse_args()
 for lang in ['en','zh']:
  (P/f'results-overview.{lang}.svg').write_text(render(lang))
 if args.png:
  from playwright.sync_api import sync_playwright
  with sync_playwright() as p:
   browser=p.chromium.launch()
   for lang in ['en','zh']:
    page=browser.new_page(viewport={'width':900,'height':934},device_scale_factor=1)
    page.goto((P/f'results-overview.{lang}.svg').resolve().as_uri());page.screenshot(path=str(P/f'results-overview.{lang}.png'));page.close()
   browser.close()
