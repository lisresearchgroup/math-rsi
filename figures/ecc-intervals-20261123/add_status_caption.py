#!/usr/bin/env python3
"""Preserve the archived vector figures and add an adjacent acceptance-status strip.

Requires pypdf and reportlab; pdftoppm renders the shareable PNGs.
Example: python add_status_caption.py --cjk-font /path/to/ArialUnicode.ttf
"""
import argparse
from io import BytesIO
from pathlib import Path
import subprocess

from pypdf import PdfReader, PdfWriter, PageObject, Transformation
from reportlab.pdfgen.canvas import Canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
ARCHIVE = ROOT / 'plugins/ecc/archive/intervals-57-20261123/figures'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cjk-font', type=Path, required=True,
                        help='Unicode TrueType font with Chinese glyphs; embedded in output')
    args = parser.parse_args()
    pdfmetrics.registerFont(TTFont('CaptionUnicode', str(args.cjk_font)))
    for language in ('en', 'zh'):
        source = ARCHIVE / f'mathrsi-bounds-20261123-{language}.pdf'
        original = PdfReader(source).pages[0]
        width, height = float(original.mediabox.width), float(original.mediabox.height)
        strip = 205
        stream = BytesIO()
        canvas = Canvas(stream, pagesize=(width, height + strip))
        canvas.setTitle('57 reported ECC interval updates — including 2 pending acceptance')
        canvas.setFillColorRGB(.97, .94, .86)
        canvas.rect(0, height, width, strip, fill=1, stroke=0)
        canvas.setFillColorRGB(.36, .15, .12)
        lines = ([
            '57 reported interval updates — includes 2 pending acceptance',
            '18 constructive lower bounds + 37 upper-bound updates; 2 further upper updates pending.',
            'Rows [41,12] and [42,12]: supplementary review passed; source project final acceptance pending.',
            'Of the source figure’s 15 exact values, 13 are accepted in the package; 2 remain pending.',
            'Status caption: MathRSI v8, 2026-11-23. Original author figure below; archived original unchanged.',
        ] if language == 'en' else [
            '57 个报告区间更新——其中 2 个仍待验收',
            '18 个构造性下界 + 37 个上界更新；另 2 个上界更新待验收。',
            '行 [41,12]、[42,12]：补充审阅已通过，仍待源项目最终验收。',
            '原图标示的 15 个精确值中，材料已验收 13 个，另 2 个仍待验收。',
            '状态说明：MathRSI v8，2026-11-23。下方保留作者原图；归档原件未改。',
        ])
        for i, line in enumerate(lines):
            canvas.setFont('CaptionUnicode', 30 if i == 0 else 21)
            canvas.drawString(38, height + strip - 45 - i * 34, line)
        canvas.save()
        caption = PdfReader(stream).pages[0]
        # The old content stream is merged without rasterization or alteration.
        page = PageObject.create_blank_page(width=width, height=height + strip)
        page.merge_transformed_page(original, Transformation(), over=True)
        page.merge_page(caption, over=True)
        writer = PdfWriter()
        writer.add_page(page)
        writer.add_metadata({'/Title': '57 ECC interval updates, including 2 pending acceptance'})
        target = HERE / f'ecc-intervals-status-{language}.pdf'
        with target.open('wb') as stream:
            writer.write(stream)
        subprocess.run(['pdftoppm', '-r', '110', '-png', '-singlefile', str(target),
                        str(target.with_suffix(''))], check=True)
        print(target.name)


if __name__ == '__main__':
    main()
