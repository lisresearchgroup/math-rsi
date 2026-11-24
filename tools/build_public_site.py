#!/usr/bin/env python3
"""Build the explicitly selected public Pages reader, never a repository mirror.

Reuse the existing offline packager's URL resolution/link-adaptation approach,
but do not recurse through linked files or copy any source directory wholesale.
"""
import argparse
from collections import Counter
from html import escape, unescape
from html.parser import HTMLParser
import json
import posixpath
from pathlib import Path
import re
import shutil
from urllib.parse import quote, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'site/public-files.json'
GITHUB = 'https://github.com/lisresearchgroup/math-rsi/blob/main/'
ATTR = re.compile(r'(?<![\w:-])(?P<key>href|src|poster)\s*=\s*(?P<q>["\'])(?P<value>.*?)(?P=q)', re.I | re.S)
CSS_URL = re.compile(r'url\(\s*(?P<q>["\']?)(?P<value>[^\)"\']+)(?P=q)\s*\)')
JS_URL = re.compile(r'(?P<q>["\'])(?P<value>(?:\.\.?/|assets/|readers/)[^"\'\r\n<>`]+)(?P=q)')
REPO_URL = re.compile(r'REPO\s*\+\s*(?P<q>["\'])(?P<value>[^"\']+)(?P=q)')
ALLOWED_SUFFIXES = {'.html', '.css', '.js', '.svg', '.png', '.webp', '.mp4', '.pdf', '.woff2', '.txt', '.json'}
FORBIDDEN_DEST_PARTS = {'plugins', 'archive', 'reviews', 'research', '.git', '.trellis', 'evidence', 'source-tree'}


def local_target(owner, value):
    parsed = urlsplit(unescape(value))
    if parsed.scheme or parsed.netloc or not parsed.path:
        return None
    path = posixpath.normpath(posixpath.join(posixpath.dirname(owner), unquote(parsed.path)))
    if parsed.path.startswith('/') or path == '..' or path.startswith('../'):
        raise ValueError(f'Outside selected source root: {owner}: {value}')
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / '_site')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT or ROOT.is_relative_to(output):
        parser.error('Output must be a dedicated child or external staging directory')
    files = json.loads(MANIFEST.read_text())['files']
    if len(set(files.values())) != len(files):
        raise ValueError('Duplicate public destination')
    for source, destination in files.items():
        src, dst = Path(source), Path(destination)
        if src.is_absolute() or '..' in src.parts or not (ROOT / src).is_file():
            raise ValueError(f'Missing or invalid explicit input: {source}')
        if not (ROOT / src).resolve().is_relative_to(ROOT):
            raise ValueError(f'Input leaves checkout: {source}')
        if dst.is_absolute() or '..' in dst.parts or FORBIDDEN_DEST_PARTS.intersection(dst.parts):
            raise ValueError(f'Invalid public destination: {destination}')
        if dst.suffix not in ALLOWED_SUFFIXES:
            raise ValueError(f'Unexpected public file type: {destination}')
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    private_links, unavailable = [], []

    def url(owner, destination, value, navigation=False):
        try:
            target = local_target(owner, value)
        except ValueError:
            if navigation:
                unavailable.append({'owner': owner, 'reference': value})
                return None
            raise
        if target is None:
            return value
        parsed = urlsplit(unescape(value))
        suffix = ('?' + parsed.query if parsed.query else '') + ('#' + parsed.fragment if parsed.fragment else '')
        if target in files:
            return posixpath.relpath(files[target], posixpath.dirname(destination) or '.') + suffix
        if not navigation:
            raise ValueError(f'Runtime dependency not explicitly allowed: {owner} → {target}')
        if not (ROOT / target).exists():
            unavailable.append({'owner': owner, 'reference': value})
            return None
        private_links.append({'owner': owner, 'source': target})
        return GITHUB + quote(target, safe='/') + suffix

    for source, destination in files.items():
        dst = output / destination
        dst.parent.mkdir(parents=True, exist_ok=True)
        extension = dst.suffix
        if extension not in {'.html', '.css', '.js', '.svg'}:
            shutil.copyfile(ROOT / source, dst)
            continue
        text = (ROOT / source).read_text()
        if extension in {'.html', '.svg'}:
            def attr(match):
                key, value = match['key'].lower(), unescape(match['value'])
                is_navigation = key == 'href' and not value.lower().endswith(('.css', '.woff2'))
                changed = url(source, destination, value, is_navigation)
                if changed is None:
                    return 'aria-disabled="true" title="Material not included in this public reader / 此公开阅读页未附该材料"'
                return match['key'] + '=' + match['q'] + escape(changed, quote=True) + match['q']
            text = ATTR.sub(attr, text)
        if extension == '.css':
            text = CSS_URL.sub(lambda m: 'url(' + m['q'] + url(source, destination, m['value']) + m['q'] + ')', text)
        if extension == '.js':
            # app.js builds Read links with REPO + a root-relative source path.
            # Adapt ordinary URLs first, then REPO expressions so the new
            # public reader paths are not resolved a second time.
            text = JS_URL.sub(lambda m: m.group(0) if m['value'].endswith('/') else m['q'] + (url(source, destination, m['value'], True) or '#') + m['q'], text)
            text = REPO_URL.sub(lambda m: json.dumps(url(source, destination, '../../../' + m['value'], True), ensure_ascii=False), text)
            text = text.replace("const REPO = '../../../';", "const REPO = '';")
        if extension == '.html' and destination != 'index.html':
            home = posixpath.relpath('index.html', posixpath.dirname(destination) or '.')
            note = ('<p data-no-i18n style="max-width:1100px;margin:24px auto;padding:0 20px;font:13px/1.6 system-ui;overflow-wrap:anywhere">'
                    '<a href="' + home + '">MathRSI</a> · <a href="https://github.com/lisresearchgroup/math-rsi">GitHub ↗</a></p>')
            text = text.replace('</body>', note + '</body>')
        dst.write_text(text)
    (output / '.nojekyll').touch()
    # Audit the staged output itself: runtime loads and local navigation must
    # resolve under this artifact, including CSS fonts and JS Read destinations.
    broken = []
    def check(owner, value):
        try:
            target = local_target(owner, value)
        except ValueError as error:
            broken.append(str(error))
            return
        if target is not None and not (output / target).is_file():
            broken.append(f'{owner} → {value}')
    class Refs(HTMLParser):
        def handle_starttag(self, tag, attrs):
            for key, value in attrs:
                if key in {'href', 'src', 'poster'} and value:
                    check(self.owner, value)
    for path in output.rglob('*'):
        if not path.is_file():
            continue
        owner = path.relative_to(output).as_posix()
        if path.suffix in {'.html', '.svg'}:
            refs = Refs(); refs.owner = owner; refs.feed(path.read_text())
        elif path.suffix == '.css':
            for match in CSS_URL.finditer(path.read_text()):
                check(owner, match['value'])
        elif path.suffix == '.js':
            for match in JS_URL.finditer(path.read_text()):
                check(owner, match['value'])
    actual = {x.relative_to(output).as_posix() for x in output.rglob('*') if x.is_file()}
    expected = set(files.values()) | {'.nojekyll'}
    if actual != expected or broken:
        raise ValueError(json.dumps({'unexpected': sorted(actual - expected), 'missing': sorted(expected - actual), 'broken': broken}, ensure_ascii=False))
    report = {'public_files': len(actual), 'bytes': sum(x.stat().st_size for x in output.rglob('*') if x.is_file()),
              'source_to_destination': files, 'private_navigation_count': len(private_links),
              'unavailable_navigation_count': len(unavailable), 'broken_local_references': broken,
              'output_matches_explicit_list': actual == expected,
              'extensions': dict(Counter(Path(x).suffix for x in actual)),
              'private_navigation': private_links, 'unavailable_navigation': unavailable}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
    print(f'Public Pages build: {len(actual)} files, {report["bytes"]} bytes; exact allowlist, no broken local references.')


if __name__ == '__main__':
    main()
