# 002 — Stop re-triggering scroll-reveal animations on every pass

- **Status**: DONE
- **Commit**: 7a59014
- **Severity**: HIGH
- **Category**: Purpose & frequency / Interruptibility
- **Estimated scope**: 2 files (`index.html`, `assets/zhub.js`), JS only

## Problem

The `IntersectionObserver` callback never unobserves an element once it has been revealed, and it actively re-hides elements that leave the viewport in either direction. On a long sales page, a visitor scrolling up to reread a section (or just scrolling back and forth near a section boundary) re-triggers the full entrance animation every single time — an element that has already been seen keeps re-animating, which AUDIT.md §1 explicitly says to avoid ("tens of times" frequency bucket → remove or drastically reduce).

`index.html:1160-1178` (current):

```js
var io=new IntersectionObserver(function(entries){
  entries.forEach(function(e){
    if(e.isIntersecting){
      e.target.classList.remove('out');
      e.target.classList.add('in');
    } else {
      if(e.boundingClientRect.top>0){
        /* scrolled back up → exit downward */
        e.target.classList.add('out');
        e.target.classList.remove('in');
      } else {
        /* scrolled past → just mark out, no visible shift */
        e.target.classList.add('out');
        e.target.classList.remove('in');
      }
    }
  });
},{threshold:.08,rootMargin:'0px 0px -56px 0px'});
document.querySelectorAll('.anim,.anim-l,.anim-r,.anim-s,.anim-pop,.anim-blur').forEach(function(el){io.observe(el);});
```

`assets/zhub.js:76-90` (current, same defect, used by all 8 pages in `cursos/`):

```js
var io=new IntersectionObserver(function(entries){
  entries.forEach(function(e){
    if(e.isIntersecting){
      e.target.classList.remove('out');
      e.target.classList.add('in');
    } else {
      e.target.classList.add('out');
      e.target.classList.remove('in');
    }
  });
},{threshold:.08,rootMargin:'0px 0px -56px 0px'});
document.querySelectorAll('.anim,.anim-l,.anim-r,.anim-s').forEach(function(el){io.observe(el);});
```

## Target

`index.html` — replace the block above with:

```js
var io=new IntersectionObserver(function(entries){
  entries.forEach(function(e){
    if(e.isIntersecting){
      e.target.classList.add('in');
      io.unobserve(e.target);
    }
  });
},{threshold:.08,rootMargin:'0px 0px -56px 0px'});
document.querySelectorAll('.anim,.anim-l,.anim-r,.anim-s,.anim-pop,.anim-blur').forEach(function(el){io.observe(el);});
```

`assets/zhub.js` — replace the block above with:

```js
var io=new IntersectionObserver(function(entries){
  entries.forEach(function(e){
    if(e.isIntersecting){
      e.target.classList.add('in');
      io.unobserve(e.target);
    }
  });
},{threshold:.08,rootMargin:'0px 0px -56px 0px'});
document.querySelectorAll('.anim,.anim-l,.anim-r,.anim-s').forEach(function(el){io.observe(el);});
```

An element now animates in once, the first time it crosses the threshold, and stays visible for the rest of the session — matching how a one-time entrance should behave on a long-form marketing page.

## Repo conventions to follow

- Both files already declare `var io=new IntersectionObserver(...)` followed immediately by the `document.querySelectorAll(...).forEach(function(el){io.observe(el);});` registration line — keep that exact two-statement shape, only change what happens inside the callback.
- Do not rename the `io` variable or the callback parameter `e` — both are used only within this block in each file, but keep naming consistent with the rest of the file's terse style (see `updateThemeUI`, `tick`, etc. using short names throughout).

## Steps

1. In `index.html`, replace lines 1160-1178 (the `.anim` IntersectionObserver block, including its `document.querySelectorAll(...)` registration line) with the `index.html` Target block above.
2. In `assets/zhub.js`, replace lines 76-90 (the equivalent block, including its registration line) with the `assets/zhub.js` Target block above.
3. Leave the `.anim.out`, `.anim-l.out`, `.anim-r.out`, `.anim-s.out`, `.anim-pop.out`, `.anim-blur.out` CSS rules in place in both `index.html` and `assets/zhub.css` — they become dead code after this change (nothing adds the `.out` class anymore) but removing CSS is out of scope for this plan; leaving them is harmless.

## Boundaries

- Do NOT touch any CSS file in this plan — this is a JS-only change (the `.out` CSS rules are intentionally left in place per Step 3).
- Do NOT touch the hero canvas script or the reduced-motion media queries — those are plans 003 and 001 respectively.
- Do NOT change the `threshold`/`rootMargin` values (`.08` / `'0px 0px -56px 0px'`) — only the callback body and the `.out`-branch removal.
- If the cited line numbers have drifted (e.g. because plan 001 was applied first and shifted line numbers in `index.html`), locate the block by its content (`var io=new IntersectionObserver` followed by the `.anim,.anim-l,...` querySelectorAll) instead of by line number, but do not alter anything else nearby.

## Verification

- **Mechanical**: open `index.html` in a browser, open the DevTools console — no errors on load or on scroll.
- **Feel check**:
  - Scroll down the full page once: every section should fade/slide/scale into view exactly as before (same easing, same duration — nothing about the "in" animation itself changed).
  - Scroll back up past a section you already revealed, then scroll down again: the section must NOT disappear or re-animate — it stays fully visible (`opacity:1`, no transform) the whole time.
  - Repeat on a course page, e.g. `cursos/explore-sap-rap.html`, scrolling up/down past the "Sobre a trilha" and "Quem apresenta" sections.
  - In DevTools → Elements, confirm that after an element has been revealed once, its class list contains `anim in` and does not gain/lose `out` on further scrolling.
- **Done when**: no section on `index.html` or any `cursos/*.html` page re-plays its entrance animation after the first reveal, regardless of how much the user scrolls up and down.
