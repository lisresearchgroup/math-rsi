# MathRSI visual tour / 可视化导览

The interactive **English / 中文 homepage** presents seven mathematical research cases, their results, the evolution of the base and domain plugins, and a historical research-workflow replay.

**[Public homepage / 公开主页](https://lisresearchgroup.github.io/math-rsi/)** — interactive bilingual homepage and selected research papers and case readers, linked directly to the public GitHub repository. Publication runs automatically when changes merge into main.

[Public build scope and workflow](PAGES.md)

For each tagged version, add one bilingual News entry to the two root READMEs and the homepage (`index.html` and `zh-CN.js`). Use the GitHub publication date in UTC+8, or the tag date for a tag-only snapshot. Link the version to that release or snapshot and keep the three newest entries expanded.

**[Homepage source and local entry](../development/homepage-redesign-20261105/site/index.html)**

GitHub displays this HTML as source. To use the interactive page, clone or download the repository, then open the file in a browser. On macOS, from the clone root:

```sh
open development/homepage-redesign-20261105/site/index.html
```

For a loopback preview with all relative links preserved, run the server **from the complete clone root**:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Then open [http://127.0.0.1:8000/development/homepage-redesign-20261105/site/index.html](http://127.0.0.1:8000/development/homepage-redesign-20261105/site/index.html) in your browser. Choose a free port if 8000 is busy. Keep `case-studies/`, `plugins/` and the rest of the clone together; serving only the `site/` subdirectory breaks relative evidence links. No npm build or site regeneration is needed.

Copyable agent request / 可直接发给 Agent：

```text
Clone the complete lisresearchgroup/math-rsi repository,
or reuse my existing clone. From its root, start a loopback HTTP server:
python3 -m http.server 8000 --bind 127.0.0.1
Use a free port if needed. Open the browser at
http://127.0.0.1:8000/development/homepage-redesign-20261105/site/index.html
(with the chosen port). Check EN / 中文, the evolution animation and result links.
Keep the server rooted at the complete clone; no npm build or regeneration is needed.
```

中文：克隆完整仓库（或复用现有克隆），在仓库根启动上述本地服务器，打开对应网址，检查中英切换、演进动画与成果链接。端口占用时换空闲端口；无需重新生成网页或运行 npm 构建。

The source stays at its existing location so its relative figure, case-reader and proof links keep working. This guide links the public Pages entry and preserves local viewing of the original clone.

中文：克隆或下载后，在浏览器中打开上述 HTML。右上角可切换中英文；页面包含七个案例的成果、Base／Plugins 演进和历史研究回放。GitHub 上的 HTML 链接显示源码，交互阅读需打开本地文件。

- [Six results, methods and evidence scopes](../case-studies/README.md)
- [Start your own task](QUICKSTART.md)
- [Current v6 workflow](V6_CHANGES.md) · [v5 history](V5_CHANGES.md) · [v4 history](V4_CHANGES.md)
- [Architecture figure gallery](../figures/mathrsi/README.md)
- [Documentation](README.md)
