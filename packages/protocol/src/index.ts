export const VERSION = 1;
export type State = 'disconnected' | 'connecting' | 'pairing' | 'authenticating' | 'connected' | 'error';
export type Input = {type:'pointer'; x:number; y:number; action:'move'|'down'|'up'; button:0|1; epoch:number} | {type:'scroll'; dx:number; dy:number} | {type:'text'; text:string} | {type:'key'; code:number; down:boolean};
export type ClientMessage = Input | {type:'ack'; id:number} | {type:'ping'};
export type ServerMessage = {type:'hello'; version:1} | {type:'frame'; id:number; epoch:number; width:number; height:number} | {type:'error'; message:string};
export function parseServer(value:unknown): ServerMessage {
  if (!value || typeof value !== 'object') throw Error('Invalid message');
  const m=value as Record<string,unknown>;
  if(m.type==='hello' && m.version===VERSION) return m as ServerMessage;
  if(m.type==='error' && typeof m.message==='string' && m.message.length<=256) return m as ServerMessage;
  if(m.type==='frame' && ['id','epoch','width','height'].every(k=>Number.isSafeInteger(m[k]) && (m[k] as number)>0) && (m.width as number)<=8192 && (m.height as number)<=8192) return m as ServerMessage;
  throw Error('Unsupported protocol message');
}
export function pointInImage(clientX:number,clientY:number,box:{left:number;top:number;width:number;height:number},image:{width:number;height:number}) {
  if (![box.width,box.height,image.width,image.height].every(n=>Number.isFinite(n)&&n>0)) return null;
  const scale=Math.min(box.width/image.width,box.height/image.height);
  const width=image.width*scale,height=image.height*scale;
  const x=(clientX-box.left-(box.width-width)/2)/width,y=(clientY-box.top-(box.height-height)/2)/height;
  return x>=0&&x<=1&&y>=0&&y<=1 ? {x,y}:null;
}
export const keyCodes = {Escape:53, Enter:36, Tab:48, Backspace:51, ArrowLeft:123, ArrowRight:124, ArrowDown:125, ArrowUp:126, MetaLeft:55, ShiftLeft:56, AltLeft:58, ControlLeft:59} as const;
