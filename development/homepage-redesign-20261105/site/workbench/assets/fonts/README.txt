Local UI fonts / 本地界面字体

Inter, JetBrains Mono, Newsreader and Noto Sans SC are served locally from this directory. All four families use SIL Open Font License 1.1; their four license notices are included alongside the fonts. Original download URLs and subset metadata are in SOURCES.json. Inter, JetBrains Mono and Newsreader were selected from the SuperARIS design reference; Noto Sans SC supplies the Chinese UI subset.

The public index.html and hamming.html inline their @font-face declarations and request assets/fonts/ relative to the page. No Google Fonts runtime request is made. Latin font subsets retain their original Unicode ranges. Noto Sans SC covers the demo's selected CJK characters; additional characters use system fallback. font-display: swap keeps initial rendering readable.
