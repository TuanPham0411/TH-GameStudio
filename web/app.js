'use strict';
const $ = s => document.querySelector(s);
const games = [
  {name:'Rắn săn mồi',type:'offline',icon:'▦',description:'Game có sẵn · Chơi ngay không cần Internet.',action:'snake'},
  {name:'2048',type:'online',icon:'2048',description:'Ghép các ô số · Cần Internet, điều khiển bằng bàn phím.',url:'https://play2048.co/'},
  {name:'Thư viện mở',type:'online',icon:'↗',description:'Khám phá game trên itch.io · Khả năng chơi tùy từng game.',url:'https://itch.io/games/html5'}
];
let filter='all',lastFocus;
function render(){ $('#games').replaceChildren(); games.filter(g=>filter==='all'||g.type===filter).forEach(g=>{const button=document.createElement('button');button.className='card';button.innerHTML=`<div class="art" aria-hidden="true">${g.icon}</div><div class="details"><span class="tag">${g.type==='offline'?'OFFLINE · CÓ SẴN':'WEB · INTERNET'}</span><h2>${g.name}</h2><p>${g.description}</p></div>`;button.onclick=()=>{if(g.action==='snake')openSnake();else location.assign(g.url);};$('#games').append(button);});}
document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{filter=b.dataset.filter;document.querySelectorAll('[data-filter]').forEach(x=>x.classList.toggle('active',x===b));render();});
$('#fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await document.documentElement.requestFullscreen();}catch{$('#message').textContent='Trình duyệt không cho phép bật toàn màn hình.';}};
function clock(){$('#clock').textContent=new Date().toLocaleTimeString('vi-VN',{hour:'2-digit',minute:'2-digit'});}clock();setInterval(clock,10000);
const dialog=$('#play'),canvas=$('#board'),ctx=canvas.getContext('2d');let snake,food,direction,next,score,timer,over,turned;
function spawn(){const empty=[];for(let y=0;y<20;y++)for(let x=0;x<20;x++)if(!snake.some(p=>p.x===x&&p.y===y))empty.push({x,y});food=empty[Math.floor(Math.random()*empty.length)];}
function draw(){ctx.fillStyle='#0b1512';ctx.fillRect(0,0,480,480);ctx.fillStyle='#efad72';if(food)ctx.fillRect(food.x*24+3,food.y*24+3,18,18);snake.forEach((p,i)=>{ctx.fillStyle=i?'#70b971':'#c4f594';ctx.fillRect(p.x*24+1,p.y*24+1,22,22);});$('#score').textContent=`Điểm: ${score}`;}
function restart(){clearInterval(timer);snake=[{x:8,y:10},{x:7,y:10},{x:6,y:10}];direction=next={x:1,y:0};score=0;over=false;turned=false;spawn();draw();$('#hint').textContent='Phím mũi tên / D-pad để chơi · Enter / A để chơi lại';timer=setInterval(tick,150);}
function finish(text){over=true;clearInterval(timer);$('#hint').textContent=text+' · Enter / A để chơi lại';}
function tick(){direction=next;turned=false;const head={x:snake[0].x+direction.x,y:snake[0].y+direction.y};const eat=food&&head.x===food.x&&head.y===food.y;const body=eat?snake:snake.slice(0,-1);if(head.x<0||head.y<0||head.x>=20||head.y>=20||body.some(p=>p.x===head.x&&p.y===head.y)){finish('Hết lượt!');return;}snake.unshift(head);if(eat){score+=10;spawn();}else snake.pop();draw();if(!food)finish('Bạn đã thắng!');}
function openSnake(){lastFocus=document.activeElement;dialog.showModal();restart();$('#close').focus();}
dialog.addEventListener('close',()=>{clearInterval(timer);lastFocus?.focus();});$('#close').onclick=()=>dialog.close();$('#restart').onclick=restart;
function input(key){if(dialog.open){const dirs={ArrowUp:{x:0,y:-1},ArrowDown:{x:0,y:1},ArrowLeft:{x:-1,y:0},ArrowRight:{x:1,y:0}};if(key==='Escape')dialog.close();else if(key==='Enter')restart();else if(dirs[key]&&!turned&&!over){const d=dirs[key];if(d.x!==-direction.x||d.y!==-direction.y){next=d;turned=true;}}return;}
if(key==='Escape'){document.querySelector('[data-filter].active').focus();return;}const items=[...document.querySelectorAll('nav button,#games button,footer button')];let index=items.indexOf(document.activeElement);if(key==='Enter'){document.activeElement?.click();return;}const steps={ArrowLeft:-1,ArrowRight:1,ArrowUp:-1,ArrowDown:1};if(key in steps)items[(index+steps[key]+items.length)%items.length]?.focus();}
document.addEventListener('keydown',e=>{if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Escape'].includes(e.key)){e.preventDefault();input(e.key);}else if(e.key==='Enter'&&dialog.open){e.preventDefault();input(e.key);}});
let previous={},lastMove=0;
function poll(time){const pads=navigator.getGamepads?navigator.getGamepads():[];const pad=Array.from(pads).find(Boolean);$('#controller').textContent=pad?'Tay cầm đã kết nối':'Bàn phím';if(pad){const keys={Enter:pad.buttons[0]?.pressed,Escape:pad.buttons[1]?.pressed,ArrowUp:pad.buttons[12]?.pressed||pad.axes[1]<-.6,ArrowDown:pad.buttons[13]?.pressed||pad.axes[1]>.6,ArrowLeft:pad.buttons[14]?.pressed||pad.axes[0]<-.6,ArrowRight:pad.buttons[15]?.pressed||pad.axes[0]>.6};for(const [k,v]of Object.entries(keys)){if(v&&(!previous[k]||(k.startsWith('Arrow')&&time-lastMove>180))){input(k);lastMove=time;}}previous=keys;}else previous={};setTimeout(()=>requestAnimationFrame(poll),40);}
render();requestAnimationFrame(poll);
