Source: Magma online calculator, POST (form field `input`, urlencoded from `input.txt`) to https://magma.maths.usyd.edu.au/xml/calculator.xml via env HTTP proxy.
Request 1 (only request made) at 2026-11-22T19:06:45Z (system clock, UTC), HTTP 200 (req1_status.txt), Magma 2.29-10. Raw reply: magma_reply1.xml.
Reply: "[42, 12, 15] Linear Code over GF(2)", the generator matrix printed twice (by `C;` and `GeneratorMatrix(C);`; first 12 and last 12 rows identical, asserted), and MinimumDistance(C)=15 (Magma's claim; not used as evidence).
generator_12x42.txt = 12 rows x 42 bits parsed from the reply (systematic [I|A]); leftmost char = coordinate 1; row integer bit j = coordinate j+1.
Acceptance rests on the independent verification below, not on Magma's output.
