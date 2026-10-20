import {beforeEach,afterEach,it,expect,vi} from 'vitest';
import {Connection} from '../apps/web/src/connection';
class Socket {
 static OPEN=1;static all:Socket[]=[];readyState=1;bufferedAmount=0;binaryType='';sent:string[]=[];
 onmessage?: (e:{data:unknown})=>Promise<void>; onclose?:()=>void;onerror?:()=>void;
 constructor(public url:string){Socket.all.push(this);}
 send(s:string){this.sent.push(s);}close(){this.readyState=3;}
}
beforeEach(()=>{vi.useFakeTimers();Socket.all=[];vi.stubGlobal('WebSocket',Socket);vi.stubGlobal('location',{protocol:'https:',host:'mac.test'});});
afterEach(()=>{vi.useRealTimers();vi.unstubAllGlobals();});
it('does not claim connected until protocol hello',async()=>{
 const status=vi.fn();const c=new Connection(status,async()=>{});c.connect();expect(status).toHaveBeenLastCalledWith('authenticating');
 await Socket.all[0].onmessage?.({data:'{"type":"hello","version":1}'});expect(status).toHaveBeenLastCalledWith('connected');c.disconnect();
});
it('rejects plaintext and never opens a socket',()=>{
 vi.stubGlobal('location',{protocol:'http:',host:'mac.test'});const s=vi.fn();new Connection(s,async()=>{}).connect();expect(Socket.all).toHaveLength(0);expect(s).toHaveBeenLastCalledWith('error',expect.stringContaining('HTTPS'));
});
it('acknowledges only after frame decode and rejects unsolicited binary',async()=>{
 let finish:()=>void=()=>{};const decode=vi.fn(()=>new Promise<void>(r=>finish=r)),s=vi.fn(),c=new Connection(s,decode);c.connect();const ws=Socket.all[0];
 await ws.onmessage?.({data:'{"type":"frame","id":1,"epoch":1,"width":1280,"height":720}'});
 const processing=ws.onmessage?.({data:new Blob(['jpeg'])});expect(ws.sent).toHaveLength(0);finish();await processing;expect(ws.sent).toEqual(['{"type":"ack","id":1}']);
 await ws.onmessage?.({data:new Blob(['unsolicited'])});expect(ws.readyState).toBe(3);expect(s).toHaveBeenLastCalledWith('error',expect.any(String));
});
it('drops late acknowledgements after disconnect',async()=>{
 let finish:()=>void=()=>{};const c=new Connection(vi.fn(),()=>new Promise<void>(r=>finish=r));c.connect();const ws=Socket.all[0];
 await ws.onmessage?.({data:'{"type":"frame","id":1,"epoch":1,"width":2,"height":2}'});
 const processing=ws.onmessage?.({data:new Blob(['jpeg'])});c.disconnect();finish();await processing;expect(ws.sent).toHaveLength(0);
});
it('requires explicit reconnect after transport loss',()=>{
 const s=vi.fn(),c=new Connection(s,async()=>{});c.connect();Socket.all[0].onclose?.();vi.advanceTimersByTime(60000);expect(Socket.all).toHaveLength(1);expect(s).toHaveBeenLastCalledWith('disconnected','Session ended. Reconnect explicitly.');
});
it('bounds outgoing queue',()=>{
 const c=new Connection(vi.fn(),async()=>{});c.connect();Socket.all[0].bufferedAmount=9000;c.send({type:'ping'});expect(Socket.all[0].sent).toHaveLength(0);expect(Socket.all[0].readyState).toBe(3);c.disconnect();
});
it('ignores stale socket hello after a replacement connection',async()=>{
 const status=vi.fn(),c=new Connection(status,async()=>{});c.connect();const old=Socket.all[0];c.connect();
 await old.onmessage?.({data:'{"type":"hello","version":1}'});expect(status).toHaveBeenLastCalledWith('authenticating');c.disconnect();
});
