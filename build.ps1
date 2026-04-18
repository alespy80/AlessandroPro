$f = "alessandropro/app.js"
$enc = [System.Text.Encoding]::UTF8

$code = @'
// ===== INIT =====
document.addEventListener('DOMContentLoaded', function() {
  animarIntro();
  atualizarData();
  renderKPIs();
});

// ===== PARTICULAS =====
function animarIntro() {
  var c = document.getElementById('intro-canvas');
  if (!c) return;
  var ctx = c.getContext('2d');
  c.width = window.innerWidth; c.height = window.innerHeight;
  var pts = [];
  for (var i = 0; i < 80; i++) {
    pts.push({ x: Math.random()*c.width, y: Math.random()*c.height,
      vx: (Math.random()-.5)*.3, vy: (Math.random()-.5)*.3,
      r: Math.random()*1.5+.5, a: Math.random()*.4+.1 });
  }
  (function draw() {
    ctx.clearRect(0,0,c.width,c.height);
    pts.forEach(function(p) {
      ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2);
      ctx.fillStyle = 'rgba(14,165,233,'+p.a+')'; ctx.fill();
      p.x+=p.vx; p.y+=p.vy;
      if(p.x<0||p.x>c.width) p.vx*=-1;
      if(p.y<0||p.y>c.height) p.vy*=-1;
    });
    requestAnimationFrame(draw);
  })();
}

// ===== ENTRAR =====
function entrar() {
  document.getElementById('intro').style.display = 'none';
  document.getElementById('app').style.display = 'flex';
  renderKPIs();
}

// ===== NAVEGACAO =====
var TITULOS = {
  dashboard: 'Dashboard',
  alunos: 'Alunos & Consultoria',
  financeiro: 'Financeiro',
  'avaliacao-fisica': 'Avaliacao Fisica',
  'avaliacao-postural': 'Avaliacao Postural',
  evolucao: 'Evolucao Visual',
  treinos: 'Banco de Treinos',
  projecao: 'Projecao de Aluno',
  'curso-avaliacao': 'Curso de Avaliacao',
  'curso-massagem': 'Curso de Massagem',
  estudo: 'Estudo Personal',
  calculadora: 'Calculadora Fisica',
  cartao: 'Cartao Digital'
};

function irModulo(id, btn) {
  document.querySelectorAll('.modulo').forEach(function(m){ m.classList.remove('ativo'); });
  document.querySelectorAll('.nav-item').forEach(function(b){ b.classList.remove('ativo'); });
  var mod = document.getElementById('mod-' + id);
  if (mod) mod.classList.add('ativo');
  if (btn) btn.classList.add('ativo');
  else {
    var navBtn = document.querySelector('[onclick*="irModulo(\'' + id + '\'"]');
    if (navBtn) navBtn.classList.add('ativo');
  }
  document.getElementById('topbar-titulo').textContent = TITULOS[id] || id;
  // Fechar sidebar no mobile
  if (window.innerWidth <= 800) {
    document.getElementById('sidebar').classList.remove('aberta');
  }
}

function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('aberta');
}

// ===== DATA =====
function atualizarData() {
  var h = new Date();
  var hora = h.getHours();
  var saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';
  var el = document.getElementById('dash-saudacao');
  if (el) el.textContent = saudacao + ', Alessandro!';
  var dataEl = document.getElementById('dash-data-full');
  if (dataEl) dataEl.textContent = h.toLocaleDateString('pt-BR', { weekday:'long', day:'2-digit', month:'long', year:'numeric' });
  var topData = document.getElementById('topbar-data');
  if (topData) topData.textContent = h.toLocaleDateString('pt-BR', { day:'2-digit', month:'short', year:'numeric' });
}

// ===== KPIs DO DASHBOARD =====
function renderKPIs() {
  var div = document.getElementById('dash-kpis');
  if (!div) return;
  // Ler dados dos modulos via localStorage
  var alunos = [];
  try { var d = JSON.parse(localStorage.getItem('cpro_v1')); if (d && d.alunos) alunos = d.alunos; } catch(e) {}
  var pagamentos = [];
  try { var d2 = JSON.parse(localStorage.getItem('cpro_v1')); if (d2 && d2.pagamentos) pagamentos = d2.pagamentos; } catch(e) {}

  var h = new Date();
  var ativos = alunos.filter(function(a) {
    var dias = Math.floor((new Date(a.venc) - h) / (1000*60*60*24));
    return dias >= 0;
  }).length;
  var receitaMes = pagamentos.filter(function(p) {
    if (p.status !== 'pago' || !p.pago) return false;
    var d = new Date(p.pago);
    return d.getMonth() === h.getMonth() && d.getFullYear() === h.getFullYear();
  }).reduce(function(s,p){ return s + (parseFloat(p.valor)||0); }, 0);
  var pendente = pagamentos.filter(function(p){ return p.status === 'pendente' || p.status === 'atrasado'; })
    .reduce(function(s,p){ return s + (parseFloat(p.valor)||0); }, 0);
  var vencendo = alunos.filter(function(a) {
    var dias = Math.floor((new Date(a.venc) - h) / (1000*60*60*24));
    return dias >= 0 && dias <= 7;
  }).length;

  div.innerHTML = [
    { v: alunos.length || '--', l: 'Total Alunos', cls: 'cyan' },
    { v: ativos || '--', l: 'Alunos Ativos', cls: 'green' },
    { v: 'R$' + (receitaMes > 0 ? receitaMes.toFixed(0) : '--'), l: 'Receita do Mes', cls: 'cyan' },
    { v: 'R$' + (pendente > 0 ? pendente.toFixed(0) : '0'), l: 'A Receber', cls: pendente > 0 ? 'orange' : 'green' },
    { v: vencendo || '0', l: 'Vencendo (7d)', cls: vencendo > 0 ? 'red' : 'green' }
  ].map(function(k) {
    return '<div class="kpi-card ' + k.cls + '"><div class="kpi-v">' + k.v + '</div><div class="kpi-l">' + k.l + '</div></div>';
  }).join('');
}
'@

[System.IO.File]::WriteAllText($f, $code, $enc)
Write-Output "ok - $((Get-Content $f).Count) linhas"
