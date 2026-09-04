/* ─── DARK MODE ─── */
(function(){
  var html=document.documentElement;
  var stored=localStorage.getItem('theme')||'light';
  html.setAttribute('data-theme',stored);
  updateThemeUI(stored);

  var btn=document.getElementById('theme-btn');
  if(btn){
    btn.addEventListener('click',function(){
      var cur=html.getAttribute('data-theme');
      var next=cur==='dark'?'light':'dark';
      var flash=document.getElementById('theme-flash');
      if(flash){flash.classList.remove('flashing');void flash.offsetWidth;flash.classList.add('flashing');flash.addEventListener('animationend',function(){flash.classList.remove('flashing');},{once:true});}
      html.setAttribute('data-theme',next);
      localStorage.setItem('theme',next);
      updateThemeUI(next);
    });
  }

  function updateThemeUI(t){
    var icon=document.getElementById('theme-icon');
    var ll=document.getElementById('logo-l'); var ld=document.getElementById('logo-d');
    var fl=document.getElementById('footer-logo-l'); var fd=document.getElementById('footer-logo-d');
    var zl=document.getElementById('zhub-logo-l'); var zd=document.getElementById('zhub-logo-d');
    if(t==='dark'){
      if(icon) icon.textContent='light_mode';
      if(ll) ll.style.display='none'; if(ld) ld.style.display='block';
      if(fl) fl.style.display='none'; if(fd) fd.style.display='block';
      if(zl) zl.style.display='none'; if(zd) zd.style.display='block';
    } else {
      if(icon) icon.textContent='dark_mode';
      if(ll) ll.style.display='block'; if(ld) ld.style.display='none';
      if(fl) fl.style.display='block'; if(fd) fd.style.display='none';
      if(zl) zl.style.display='block'; if(zd) zd.style.display='none';
    }
  }
})();

/* ─── FAQ (se existir na página) ─── */
document.querySelectorAll('.faq-btn').forEach(function(btn){
  btn.addEventListener('click',function(){
    var expanded=this.getAttribute('aria-expanded')==='true';
    document.querySelectorAll('.faq-btn').forEach(function(b){b.setAttribute('aria-expanded','false');b.nextElementSibling.classList.remove('open');});
    if(!expanded){this.setAttribute('aria-expanded','true');this.nextElementSibling.classList.add('open');}
  });
});

/* ─── COOKIE ─── */
if(document.getElementById('cookie') && !localStorage.getItem('ck')){
  setTimeout(function(){document.getElementById('cookie').style.display='block';},3000);
}

/* ─── EXTERNAL LINKS → NOVA GUIA ─── */
document.querySelectorAll('a[href^="http"],a[href^="mailto"]').forEach(function(a){
  a.target='_blank';a.rel='noopener noreferrer';
});

/* ─── SMOOTH SCROLL (âncoras na mesma página) ─── */
document.querySelectorAll('a[href^="#"]').forEach(function(a){
  a.addEventListener('click',function(e){
    var t=document.querySelector(this.getAttribute('href'));
    if(t){e.preventDefault();window.scrollTo({top:t.getBoundingClientRect().top+window.pageYOffset-100,behavior:'smooth'});}
  });
});

/* ─── BACK TO TOP + NAV BORDER ─── */
window.addEventListener('scroll',function(){
  var b=document.getElementById('back-top');
  if(b) b.classList.toggle('vis',window.scrollY>400);
  var n=document.querySelector('nav');
  if(n) n.classList.toggle('scrolled',window.scrollY>10);
});

/* ─── ENTRANCE ANIMATIONS ─── */
var io=new IntersectionObserver(function(entries){
  entries.forEach(function(e){
    if(e.isIntersecting){
      e.target.classList.add('in');
      io.unobserve(e.target);
    }
  });
},{threshold:.08,rootMargin:'0px 0px -56px 0px'});
document.querySelectorAll('.anim,.anim-l,.anim-r,.anim-s').forEach(function(el){io.observe(el);});
