import React,{useEffect,useRef,useState} from 'react';
import {createRoot} from 'react-dom/client';
import {pointInImage,keyCodes,type State} from '@forge/protocol';
import {Connection} from './connection';
import './style.css';
async function api(path:string,body:object){
 const r=await fetch(`/api/${path}`,{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:JSON.stringify(body),cache:'no-store'});
 if(!r.ok)throw Error(r.status===429?'Too many attempts. Wait a minute.':'Request refused. Check the code, HTTPS and Mac approval.');return r.json();
}
function App(){
 const [state,setState]=useState<State>('disconnected'),[error,setError]=useState(''),[code,setCode]=useState(''),[mode,setMode]=useState('Desktop'),[text,setText]=useState('');
 const canvas=useRef<HTMLCanvasElement>(null),meta=useRef({width:0,height:0,epoch:0}),active=useRef(false),ticket=useRef(''),[paired,setPaired]=useState(false);
 const conn=useRef<Connection|null>(null);
 if(!conn.current)conn.current=new Connection((s,e)=>{setState(s);if(e)setError(e);if(s!=='connected'){meta.current={width:0,height:0,epoch:0};const c=canvas.current;c?.getContext('2d')?.clearRect(0,0,c.width,c.height);}},async(blob,m)=>{
  const image=new Image(),url=URL.createObjectURL(blob);try{await new Promise<void>((resolve,reject)=>{image.onload=()=>resolve();image.onerror=reject;image.src=url;});if(!active.current)return;
  const c=canvas.current;if(c){c.width=m.width;c.height=m.height;c.getContext('2d')?.drawImage(image,0,0,m.width,m.height);meta.current=m;}}finally{URL.revokeObjectURL(url);}
 });
 useEffect(()=>{active.current=state==='connected';},[state]);
 useEffect(()=>{
  const stop=()=>{ticket.current='';conn.current?.disconnect();};const visibility=()=>{if(document.hidden)stop();};
  window.addEventListener('offline',stop);window.addEventListener('pagehide',stop);document.addEventListener('visibilitychange',visibility);
  return()=>{stop();window.removeEventListener('offline',stop);window.removeEventListener('pagehide',stop);document.removeEventListener('visibilitychange',visibility);};
 },[]);
 useEffect(()=>{if(state!=='pairing')return;const timer=setInterval(async()=>{const t=ticket.current;if(!t)return;try{const result=await api('pair/status',{ticket:t});if(ticket.current!==t)return;if(result.status==='approved'){ticket.current='';setPaired(true);conn.current?.connect();}}catch(e){ticket.current='';setState('error');setError(String(e));}},1500);return()=>clearInterval(timer);},[state]);
 async function pair(e:React.FormEvent){e.preventDefault();setError('');setState('connecting');try{if(location.protocol!=='https:')throw Error('Open this app using trusted HTTPS.');const r=await api('pair',{code,name:'iPhone browser'});ticket.current=r.ticket;setCode('');setState('pairing');}catch(e){setState('error');setError(String(e));}}
 function pointer(e:React.PointerEvent<HTMLCanvasElement>,action:'move'|'down'|'up'){
  if(state!=='connected'||!meta.current.epoch)return; const c=e.currentTarget;
  if(action==='down')c.setPointerCapture(e.pointerId);
  if(action==='move'&&e.pointerType==='touch'&&!c.hasPointerCapture(e.pointerId))return;
  const p=pointInImage(e.clientX,e.clientY,c.getBoundingClientRect(),meta.current);
  if(p)conn.current?.send({type:'pointer',...p,epoch:meta.current.epoch,action,button:e.button===2?1:0});
  if(action==='up'&&c.hasPointerCapture(e.pointerId))c.releasePointerCapture(e.pointerId);
 }
 const sendText=()=>{if(text){conn.current?.send({type:'text',text:text.slice(0,256)});setText('');}};
 function key(code:number){conn.current?.send({type:'key',code,down:true});conn.current?.send({type:'key',code,down:false});}
 return <main><header><a className="brand" href="/">F<span>Forge Remote</span></a><span className={`status ${state}`}>● {state}</span><button onClick={()=>{ticket.current='';conn.current?.disconnect();void api('disconnect',{}).catch(()=>{});}}>Disconnect</button></header>
 <section className="desktop"><canvas ref={canvas} onPointerDown={e=>pointer(e,'down')} onPointerMove={e=>pointer(e,'move')} onPointerUp={e=>pointer(e,'up')} onPointerCancel={()=>{conn.current?.disconnect();}} onContextMenu={e=>e.preventDefault()} onWheel={e=>{if(state==='connected')conn.current?.send({type:'scroll',dx:Math.max(-1000,Math.min(1000,e.deltaX)),dy:Math.max(-1000,Math.min(1000,e.deltaY))});}} aria-label="Live Mac desktop"/>
 {state!=='connected'&&<div className="welcome"><div className="symbol">⌘</div><p className="eyebrow">YOUR MAC. WITHIN REACH.</p><h1>A little closer<br/>to your desktop.</h1><p>Open Forge Remote on your Mac, generate a pairing code, then approve this device there.</p><form onSubmit={pair}><label htmlFor="code">Mac pairing code</label><div className="pair"><input id="code" inputMode="numeric" autoComplete="off" pattern="[0-9]{8}" maxLength={8} value={code} onChange={e=>setCode(e.target.value.replace(/\D/g,''))} placeholder="0000 0000" required/><button disabled={state==='pairing'||state==='connecting'}>Pair Mac ↗</button></div></form>{state==='pairing'&&<p role="status">Waiting for approval on your Mac…</p>}<button className="secondary" onClick={()=>{setError('');conn.current?.connect();}}>Reconnect {paired?'paired device':'with existing pairing'}</button>{error&&<p role="alert" className="error">{error}</p>}<small>Private connection · Local approval · No cloud relay</small></div>}
 </section><footer><nav aria-label="Control mode">{['Desktop','Trackpad','Keyboard','Actions'].map(m=><button aria-pressed={mode===m} key={m} onClick={()=>setMode(m)}>{m}</button>)}</nav>
 {state==='connected'&&mode==='Trackpad'&&<Trackpad send={(x,y,action)=>conn.current?.send({type:'pointer',x,y,action,button:0,epoch:meta.current.epoch})} scroll={dy=>conn.current?.send({type:'scroll',dx:0,dy})}/>}
 {state==='connected'&&mode==='Keyboard'&&<div className="controls"><input aria-label="Text to type on Mac" value={text} maxLength={256} onChange={e=>setText(e.target.value)} onKeyDown={e=>{if(e.key==='Enter')sendText();}}/><button onClick={sendText}>Send text</button>{(['Enter','Backspace','Tab','Escape'] as const).map(k=><button key={k} onClick={()=>key(keyCodes[k])}>{k}</button>)}</div>}
 {state==='connected'&&mode==='Actions'&&<div className="controls">{[['Copy',8],['Paste',9],['Select all',0],['Undo',6]].map(([label,code])=><button key={label} onClick={()=>{conn.current?.send({type:'key',code:55,down:true});key(Number(code));conn.current?.send({type:'key',code:55,down:false});}}>⌘ {label}</button>)}<button onClick={()=>{conn.current?.send({type:'pointer',x:.5,y:.5,epoch:meta.current.epoch,action:'down',button:1});conn.current?.send({type:'pointer',x:.5,y:.5,epoch:meta.current.epoch,action:'up',button:1});}}>Right click (center)</button></div>}
 <small>Forge Remote · {state==='connected'?'Live session — stop anytime on your Mac':'Your Mac stays in control'}</small></footer></main>;
}
function Trackpad({send,scroll}:{send:(x:number,y:number,a:'move'|'down'|'up')=>void;scroll:(dy:number)=>void}){
 const pos=useRef({x:.5,y:.5}),last=useRef<{x:number;y:number}|null>(null);
 return <div className="controls"><div className="trackpad" onPointerDown={e=>{e.currentTarget.setPointerCapture(e.pointerId);last.current={x:e.clientX,y:e.clientY};}} onPointerMove={e=>{if(!last.current)return;pos.current={x:Math.max(0,Math.min(1,pos.current.x+(e.clientX-last.current.x)/600)),y:Math.max(0,Math.min(1,pos.current.y+(e.clientY-last.current.y)/600))};last.current={x:e.clientX,y:e.clientY};send(pos.current.x,pos.current.y,'move');}} onPointerUp={()=>{last.current=null;}} onPointerCancel={()=>{last.current=null;}}>Slide to move</div><button onClick={()=>{send(pos.current.x,pos.current.y,'down');send(pos.current.x,pos.current.y,'up');}}>Click</button><button onClick={()=>scroll(-150)}>Scroll ↑</button><button onClick={()=>scroll(150)}>Scroll ↓</button></div>;
}
createRoot(document.getElementById('root')!).render(<App/>);
if('serviceWorker' in navigator && location.protocol==='https:')navigator.serviceWorker.register('/sw.js').catch(()=>{});
