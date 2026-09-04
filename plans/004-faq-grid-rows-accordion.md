# 004 — Replace FAQ max-height animation with a grid-rows accordion

- **Status**: DONE
- **Commit**: 7a59014
- **Severity**: MEDIUM
- **Category**: Easing & duration / Performance
- **Estimated scope**: 1 file (`index.html`), CSS only

## Problem

`index.html:279-280` (current):

```css
.faq-body{overflow:hidden;max-height:0;transition:max-height .35s ease,padding .25s ease;}
.faq-body.open{max-height:400px;padding-bottom:20px;}
```

Two problems:

1. `max-height` is a layout property (AUDIT.md §5: animate `transform`/`opacity` only — `max-height`/`height` trigger layout + paint on every frame of the transition, not just compositor work).
2. The target height is a hardcoded `400px` ceiling, but the actual FAQ answers (see `index.html`'s FAQ section, e.g. `.faq-body><p>` elements) are all noticeably shorter than that. Animating from `0` to a fixed `400px` means the perceived expansion speed is inconsistent per question — a short answer reaches its real height almost immediately and then the timing function keeps "coasting" toward the unused remainder of the 400px budget, while `ease` is also a bare, weak built-in curve rather than the strong custom curve already used elsewhere on this page (`cubic-bezier(.22,1,.36,1)`, defined inline and reused across `.anim`).

## Target

```css
.faq-body{overflow:hidden;display:grid;grid-template-rows:0fr;transition:grid-template-rows .35s cubic-bezier(.22,1,.36,1);}
.faq-body>p{min-height:0;padding-bottom:20px;}
.faq-body.open{grid-template-rows:1fr;}
```

This is the standard CSS grid accordion technique: `grid-template-rows` animates between an explicit `0fr` and `1fr` track size, the single grid item (`.faq-body > p`) needs `min-height:0` so it's allowed to shrink below its content height inside the track, and the always-present `overflow:hidden` on `.faq-body` clips the child to the animated track size — so the answer's real height is what gets revealed, at a consistent perceived speed regardless of how long the answer text is.

## Repo conventions to follow

- The custom ease-out curve `cubic-bezier(.22,1,.36,1)` is already used verbatim in the `.anim`/`.anim-l`/`.anim-r` rules a few lines below (`index.html:300-302`) — reuse that exact same value here rather than introducing a new curve, for cohesion (AUDIT.md §7).
- `.faq-body` currently wraps a single `<p>` per FAQ item (see any `.faq-item` in the FAQ section, e.g. `<div class="faq-body"><p>Consultores funcionais...</p></div>`) — the Target CSS assumes exactly that single-child shape; no HTML changes are needed because a `<p>` is naturally the sole grid item.

## Steps

1. In `index.html`, replace the two-line rule pair at lines 279-280 (`.faq-body{...}` and `.faq-body.open{...}`) with the three-rule Target block above (note the target adds a new `.faq-body>p{...}` rule that didn't exist before — insert it between the other two, in the order shown).
2. Do not touch the `.faq-item`, `.faq-btn`, or `.faq-icon` rules, or any FAQ markup in the body of the page.

## Boundaries

- Do NOT touch `.faq-icon` — that's plan 005.
- Do NOT change the FAQ HTML markup — this is styling only, and relies on each `.faq-body` already having exactly one `<p>` child.
- Do NOT change the `.35s` duration or introduce a different curve than `cubic-bezier(.22,1,.36,1)`.
- If any `.faq-body` in the current markup contains more than a single `<p>` child (drift since commit `7a59014`), STOP and report — the grid-rows technique still works with multiple children, but wrapping them may be needed and that's outside this plan's scope.

## Verification

- **Mechanical**: open `index.html` in a browser, open every FAQ item — no console errors, no layout overlap or clipped text once fully open.
- **Feel check**:
  - Click each of the 6 FAQ questions in turn (they're implemented as an accordion — opening one closes any other that was open). Confirm each answer expands smoothly to exactly its own content height, with no dead space and no clipped last line.
  - In DevTools → Animations panel (or the Elements > Computed panel while toggling), set playback to 10% or use "Slow 3G" style throttling and confirm the expand/collapse motion visually matches the same strong ease-out feel as the page's scroll-reveal animations (fast start, gentle settle) — not the flat, mechanical feel of the previous `ease`.
  - Compare a short answer (e.g. "Como funciona o acesso após a compra?") against the longest answer (e.g. the Clean Core / agents-vs-ChatGPT one) — both should feel like they take the same ~350ms to fully reveal their own (different) heights, not like the short one "waits" for a fixed 400px ceiling.
  - Resize the browser to a narrow mobile width (so text reflows to more lines) and confirm the accordion still opens to the correct new height without clipping.
- **Done when**: every FAQ answer expands/collapses to its exact own height (no more, no less) using the shared `cubic-bezier(.22,1,.36,1)` curve, with no `max-height` property remaining in the FAQ CSS.
