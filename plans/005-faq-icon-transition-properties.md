# 005 — Replace `transition: all` on the FAQ icon with explicit properties

- **Status**: DONE
- **Commit**: 7a59014
- **Severity**: LOW
- **Category**: Performance
- **Estimated scope**: 1 file (`index.html`), CSS only

## Problem

`index.html:274` (current):

```css
.faq-icon{flex-shrink:0;width:24px;height:24px;border-radius:50%;border:1px solid var(--border-2);display:flex;align-items:center;justify-content:center;transition:all .2s;}
```

`transition: all` is always a finding per AUDIT.md §5 — it transitions every animatable property that changes, not just the ones intended. The only properties that actually change on this element (see the two rules immediately below it) are `border-color` and `background`:

```css
/* index.html:276-277 */
.faq-btn[aria-expanded="true"] .faq-icon{border-color:var(--purple);background:var(--pbg);}
.faq-btn[aria-expanded="true"] .faq-icon svg{transform:rotate(45deg);}
```

(The `svg` rotation is already handled by its own separate, correctly-scoped `transition:transform .25s` on `.faq-icon svg` at `index.html:275` — not part of this finding.)

## Target

```css
.faq-icon{flex-shrink:0;width:24px;height:24px;border-radius:50%;border:1px solid var(--border-2);display:flex;align-items:center;justify-content:center;transition:border-color .2s,background-color .2s;}
```

## Repo conventions to follow

- This codebase already lists explicit comma-separated properties everywhere else motion is defined (e.g. `.card{transition:border-color .2s,box-shadow .2s;}` at `index.html:136`, `.btn-green{transition:background .2s,transform .15s,box-shadow .2s;}` at `index.html:106`) — `transition:all` on `.faq-icon` is the only outlier in the whole file. Match the existing explicit-property style exactly.
- Keep the `.2s` duration unchanged — only the transitioned properties change, not the timing.

## Steps

1. In `index.html`, in the `.faq-icon{...}` rule at line 274, change `transition:all .2s;` to `transition:border-color .2s,background-color .2s;`. No other part of the rule changes.

## Boundaries

- Do NOT touch `.faq-icon svg` or `.faq-btn[aria-expanded="true"] .faq-icon` — only the base `.faq-icon` rule's `transition` value changes.
- Do NOT touch the FAQ markup or the grid-rows accordion work from plan 004.
- Do NOT change the `.2s` duration.

## Verification

- **Mechanical**: open `index.html`, open DevTools console — no errors.
- **Feel check**: click a FAQ question open and closed a few times, watching the small circular icon — the border and background should still fade in/out over the same ~200ms as before (visually identical to pre-change), confirming no property needed for the visible effect was dropped.
- **Done when**: `.faq-icon`'s `transition` lists only `border-color` and `background-color`, and the icon's open/close visual feedback is unchanged.
