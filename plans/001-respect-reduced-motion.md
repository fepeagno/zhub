# 001 — Respect prefers-reduced-motion for decorative CSS animations

- **Status**: DONE
- **Commit**: 7a59014
- **Severity**: HIGH
- **Category**: Accessibility
- **Estimated scope**: 2 files (`index.html`, `assets/zhub.css`), CSS only

## Problem

Neither `index.html` nor `assets/zhub.css` contains a single `@media (prefers-reduced-motion: reduce)` rule, despite several continuous/decorative animations running on every page:

```css
/* index.html:132 */
.chip-dot{width:6px;height:6px;border-radius:50%;background:var(--green);animation:pulse 2s infinite;flex-shrink:0;}
/* index.html:189-191 */
.f-a{animation:floatA 5s ease-in-out infinite;}
.f-b{animation:floatB 6s ease-in-out infinite .5s;}
.f-c{animation:floatC 4.5s ease-in-out infinite 1s;}
/* index.html:300-305 — scroll-reveal transforms, also present in assets/zhub.css:203-207 */
.anim     {opacity:0;transform:translateY(28px);transition:opacity .50s cubic-bezier(.22,1,.36,1),transform .50s cubic-bezier(.22,1,.36,1);}
.anim-l   {opacity:0;transform:translateX(-32px);transition:opacity .50s cubic-bezier(.22,1,.36,1),transform .50s cubic-bezier(.22,1,.36,1);}
.anim-r   {opacity:0;transform:translateX(32px);transition:opacity .50s cubic-bezier(.22,1,.36,1),transform .50s cubic-bezier(.22,1,.36,1);}
.anim-s   {opacity:0;transform:scale(.94);transition:opacity .45s ease,transform .45s cubic-bezier(.34,1.56,.64,1);}
.anim-pop {opacity:0;transform:scale(.88) translateY(16px);transition:opacity .40s ease,transform .40s cubic-bezier(.34,1.56,.64,1);}
.anim-blur{opacity:0;filter:blur(8px);transform:translateY(16px);transition:opacity .55s ease,filter .55s ease,transform .55s ease;}
```

Users with `prefers-reduced-motion: reduce` set (vestibular disorders, motion sensitivity) get the full experience: pulsing dot, floating badges, and every section sliding/scaling/blurring into place as they scroll. Per AUDIT.md §6, reduced motion should keep opacity/color feedback but drop movement — it is not currently gated at all.

`assets/zhub.css` only defines `.anim`, `.anim-l`, `.anim-r`, `.anim-s` (no `.anim-pop`/`.anim-blur`, no floaters — those classes/animations don't exist in that file) and reuses `.chip-dot` (lines 124-125).

## Target

Add this block to `index.html`, right after the existing `.d7{...}.d8{...}` delay-utility line (index.html:316) and before the `/* DARK MODE TRANSITION FLASH */` comment (index.html:318):

```css
/* REDUCED MOTION */
@media (prefers-reduced-motion: reduce) {
  .chip-dot,.f-a,.f-b,.f-c{animation:none!important;}
  .anim,.anim-l,.anim-r,.anim-s,.anim-pop,.anim-blur{
    transform:none!important;filter:none!important;
    transition:opacity .3s ease!important;
  }
  .anim.out,.anim-l.out,.anim-r.out,.anim-s.out,.anim-pop.out,.anim-blur.out{opacity:0;}
}
```

Add this block to `assets/zhub.css`, right after the `.d7{...}.d8{...}` line (assets/zhub.css — same delay-utility line present near the end of the "ANIMATIONS" section) and before the `/* DARK MODE TRANSITION FLASH */` comment:

```css
/* REDUCED MOTION */
@media (prefers-reduced-motion: reduce) {
  .chip-dot{animation:none!important;}
  .anim,.anim-l,.anim-r,.anim-s{
    transform:none!important;
    transition:opacity .3s ease!important;
  }
  .anim.out,.anim-l.out,.anim-r.out,.anim-s.out{opacity:0;}
}
```

Note: the `.in` state already only sets `opacity:1;transform:none;filter:none;` (see the shared `.anim.in,...{opacity:1;transform:none;filter:none;}` rule) — no change needed there, since removing `transform`/`filter` on the base state under reduced motion makes the elements start already in their final position, and the transition rule above then only fades opacity in.

## Repo conventions to follow

- Both files already group related rules under a `/* SECTION NAME */` comment header — follow that exact style (all-caps, `/* ... */`).
- Both files place this kind of cross-cutting override right before `/* DARK MODE TRANSITION FLASH */`, which is itself the last "behavioral" override before the generic utility rules at the end of the file (`.material-symbols-rounded`, `::-webkit-scrollbar`). Keep the new block in that same position, in both files.
- `!important` is not used elsewhere in either file — it is justified here only because the reduced-motion query must win over the more specific `.anim`/`.f-a` selectors without duplicating them; do not use `!important` anywhere else while making this change.

## Steps

1. In `index.html`, insert the "REDUCED MOTION" block shown in Target immediately after line 316 (`.d7{transition-delay:.38s}.d8{transition-delay:.46s}`) and before line 318 (`/* DARK MODE TRANSITION FLASH */`).
2. In `assets/zhub.css`, insert the second "REDUCED MOTION" block in the equivalent position (after the `.d7/.d8` delay-utility line, before `/* DARK MODE TRANSITION FLASH */`).
3. Do not touch any other file. Course pages (`cursos/*.html`) all load `assets/zhub.css`, so step 2 covers all 8 of them automatically.

## Boundaries

- Do NOT touch the hero canvas particle script (`index.html`'s `hero-canvas` IIFE) — that is covered by plan 003.
- Do NOT touch the `IntersectionObserver` re-trigger logic — that is covered by plan 002.
- Do NOT change markup/structure — CSS only.
- Do NOT add new dependencies.
- If the `.d7/.d8` line or the `/* DARK MODE TRANSITION FLASH */` comment aren't found at the cited locations (drift since commit `7a59014`), STOP and report instead of guessing a new insertion point.

## Verification

- **Mechanical**: open `index.html` and each file in `cursos/` in a browser; page must render identically to before this change (no visual diff) with a normal (non-reduced) motion preference. No console errors.
- **Feel check**:
  - In Chrome DevTools → Rendering panel → "Emulate CSS media feature prefers-reduced-motion" → set to "reduce". Reload `index.html`.
    - The purple `chip-dot` in the announcement chips must be static (no pulsing).
    - The floating hero badges/cards (`SAP BTP`, `ABAP RAP`, `Clean Core`, `S/4HANA` tags and the two glass cards) must be static (no float).
    - Scroll the page: every section must still fade in, but must NOT slide up, scale, or blur — it should just appear via opacity.
  - Toggle the emulation back to "no preference" and confirm the original slide/scale/blur entrance motion is unchanged.
  - Repeat the reduced-motion check on one course page, e.g. `cursos/sap-core-foundations.html` (it shares `assets/zhub.css`).
- **Done when**: with reduced-motion emulated, nothing on the page moves except opacity fades, on both `index.html` and the course pages; with no preference emulated, the page is pixel-identical to before this plan.
