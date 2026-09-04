# 003 — Pause the hero canvas particle loop off-screen and under reduced motion

- **Status**: DONE
- **Commit**: 7a59014
- **Severity**: MEDIUM
- **Category**: Performance
- **Estimated scope**: 1 file (`index.html`), JS only

## Problem

`index.html:1180-1219` (current, full block):

```js
/* ─── HERO CANVAS — partículas roxas suaves ─── */
(function(){
  var c=document.getElementById('hero-canvas');
  if(!c)return;
  var ctx=c.getContext('2d');
  var W,H,pts,raf;
  function setup(){
    W=window.innerWidth;H=window.innerHeight;
    var dpr=window.devicePixelRatio||1;
    c.width=W*dpr;c.height=H*dpr;c.style.width=W+'px';c.style.height=H+'px';
    ctx.scale(dpr,dpr);
    pts=[];
    for(var i=0;i<50;i++) pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.3,vy:(Math.random()-.5)*.3,r:1+Math.random()*1.5});
  }
  function draw(){
    ctx.clearRect(0,0,W,H);
    var dark=document.documentElement.getAttribute('data-theme')==='dark';
    var pc=dark?'rgba(128,112,200,':'rgba(97,84,160,';
    pts.forEach(function(p){
      p.x+=p.vx;p.y+=p.vy;
      if(p.x<0||p.x>W)p.vx*=-1;
      if(p.y<0||p.y>H)p.vy*=-1;
    });
    pts.forEach(function(p,i){
      pts.forEach(function(q,j){
        if(j<=i)return;
        var dx=p.x-q.x,dy=p.y-q.y,d=Math.sqrt(dx*dx+dy*dy);
        if(d<130){
          ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(q.x,q.y);
          ctx.strokeStyle=pc+(dark?.08:.05)*(1-d/130)+')';ctx.lineWidth=1;ctx.stroke();
        }
      });
      ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2);
      ctx.fillStyle=pc+(dark?.35:.20)+')';ctx.fill();
    });
    raf=requestAnimationFrame(draw);
  }
  setup();draw();
  var rt;window.addEventListener('resize',function(){clearTimeout(rt);rt=setTimeout(function(){cancelAnimationFrame(raf);setup();draw();},150);});
})();
```

This starts an unconditional `requestAnimationFrame` loop on page load that never stops: 50 particles, each frame doing an O(n²) pairwise distance check (~1,225 comparisons) to decide which to connect with a line, plus 50 arcs and up to ~1,225 strokes. It keeps running at full cost forever — including long after the user has scrolled past the hero section — and it never checks `prefers-reduced-motion`, so motion-sensitive users get a permanently-moving particle field with no way to opt out.

## Target

Replace the entire block above with:

```js
/* ─── HERO CANVAS — partículas roxas suaves ─── */
(function(){
  var c=document.getElementById('hero-canvas');
  if(!c)return;
  var reduceMotion=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if(reduceMotion)return;
  var ctx=c.getContext('2d');
  var W,H,pts,raf,running=false;
  function setup(){
    W=window.innerWidth;H=window.innerHeight;
    var dpr=window.devicePixelRatio||1;
    c.width=W*dpr;c.height=H*dpr;c.style.width=W+'px';c.style.height=H+'px';
    ctx.scale(dpr,dpr);
    pts=[];
    for(var i=0;i<50;i++) pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.3,vy:(Math.random()-.5)*.3,r:1+Math.random()*1.5});
  }
  function draw(){
    if(!running)return;
    ctx.clearRect(0,0,W,H);
    var dark=document.documentElement.getAttribute('data-theme')==='dark';
    var pc=dark?'rgba(128,112,200,':'rgba(97,84,160,';
    pts.forEach(function(p){
      p.x+=p.vx;p.y+=p.vy;
      if(p.x<0||p.x>W)p.vx*=-1;
      if(p.y<0||p.y>H)p.vy*=-1;
    });
    pts.forEach(function(p,i){
      pts.forEach(function(q,j){
        if(j<=i)return;
        var dx=p.x-q.x,dy=p.y-q.y,d=Math.sqrt(dx*dx+dy*dy);
        if(d<130){
          ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(q.x,q.y);
          ctx.strokeStyle=pc+(dark?.08:.05)*(1-d/130)+')';ctx.lineWidth=1;ctx.stroke();
        }
      });
      ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2);
      ctx.fillStyle=pc+(dark?.35:.20)+')';ctx.fill();
    });
    raf=requestAnimationFrame(draw);
  }
  function start(){ if(running)return; running=true; draw(); }
  function stop(){ running=false; if(raf)cancelAnimationFrame(raf); }
  setup();
  var heroSection=c.closest('section');
  var vio=new IntersectionObserver(function(entries){
    entries.forEach(function(e){ if(e.isIntersecting)start(); else stop(); });
  });
  if(heroSection)vio.observe(heroSection);
  else start();
  var rt;window.addEventListener('resize',function(){clearTimeout(rt);rt=setTimeout(function(){stop();setup();if(heroSection&&heroSection.getBoundingClientRect().bottom>0)start();},150);});
})();
```

Behavior change: the particle field only animates while the hero `<section>` is at least partially in the viewport, and is skipped entirely (canvas left blank/transparent, matching the `opacity:.5` container already being subtle) when `prefers-reduced-motion: reduce` is set.

## Repo conventions to follow

- This IIFE already follows a `setup()` / `draw()` pair pattern shared by the other canvas block in this file (the dormant `prob-canvas` IIFE later in the same `<script>` tag, which this plan does not touch since its target element doesn't exist in the current markup). Keep the same two-function shape; only add `start`/`stop`/`running` around it.
- `window.matchMedia('(prefers-reduced-motion: reduce)').matches` is the standard one-shot check; this codebase has no existing reduced-motion check to imitate (see plan 001, which adds the CSS-side equivalent) — this is the first place it's introduced in JS, so keep it inline and simple exactly as shown rather than factoring out a shared helper.
- The existing resize-debounce pattern (`var rt;window.addEventListener('resize',function(){clearTimeout(rt);rt=setTimeout(...,150);});`) is reused verbatim in shape, just extended to re-check whether the hero is currently visible before restarting.

## Steps

1. In `index.html`, replace the full `hero-canvas` IIFE (currently lines 1180-1219, delimited by the `/* ─── HERO CANVAS — partículas roxas suaves ─── */` comment through the closing `})();`) with the Target block above.

## Boundaries

- Do NOT touch the `prob-canvas` IIFE that follows it in the same `<script>` tag — that code's target element (`#prob-canvas`) does not exist in the current markup, it is already inert, and touching it is out of scope for this plan.
- Do NOT touch any CSS file — this is a JS-only change to a single IIFE.
- Do NOT change the particle count (50), speed values, or connection distance (130) — visuals must be unchanged when the canvas is running.
- If the `hero-canvas` IIFE's content has drifted from what's quoted in Problem (e.g. different particle count), STOP and report rather than merging your own version over it.

## Verification

- **Mechanical**: open `index.html`, open DevTools console — no errors on load, resize, or scroll.
- **Feel check**:
  - With normal motion preference: load the page — the particle field animates in the hero exactly as before (same density, same connecting-line behavior, same colors in light/dark).
  - Scroll down past the hero (past the "O que é o Zhub" section): open DevTools → Performance → Record a few seconds while the hero is off-screen — there should be no `requestAnimationFrame` activity from this script (confirm via a `console.log` temporarily in `draw()`, or by checking the Performance panel's main-thread activity is quiet between scroll-triggered work).
  - Scroll back up so the hero re-enters the viewport — the particle animation must resume smoothly (not restart with a jarring flash — a `setup()` reset on resize only, not on every re-entry, is intentional and correct).
  - In DevTools → Rendering → emulate `prefers-reduced-motion: reduce`, reload — the canvas must show no particles and no animation at all (the `<canvas>` element still exists but stays empty).
  - Resize the browser window while the hero is visible — particles must re-seed at the new size without leaving duplicate rAF loops running (check the Performance panel shows only one `draw` cycle worth of work per frame, not a multiplying count).
- **Done when**: the particle animation runs only while the hero section is on-screen, never runs under reduced motion, and produces the same visual result as before whenever it is running.
