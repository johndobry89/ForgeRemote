import {parseServer, type ClientMessage, type ServerMessage, type State} from '@forge/protocol';
export class Connection {
  private socket?:WebSocket;
  private pending?:Extract<ServerMessage,{type:'frame'}>;
  private timer?:ReturnType<typeof setInterval>;
  private decoding=false;
  private generation=0;
  constructor(private status:(s:State,error?:string)=>void,private frame:(blob:Blob,meta:Extract<ServerMessage,{type:'frame'}>)=>Promise<void>){}
  connect(){
    this.disconnect(); const generation=this.generation; this.status('authenticating');
    if(location.protocol!=='https:'){this.status('error','A trusted HTTPS connection is required.');return;}
    const ws=new WebSocket(`wss://${location.host}/socket`); this.socket=ws; ws.binaryType='blob';
    ws.onmessage=async event=>{
      try{
        if(typeof event.data==='string'){
          const m=parseServer(JSON.parse(event.data));
          if(m.type==='hello'){this.status('connected');this.timer=setInterval(()=>this.send({type:'ping'}),20000);}
          if(m.type==='error')throw Error(m.message);
          if(m.type==='frame'){if(this.pending||this.decoding)throw Error('Frame overlap');this.pending=m;}
        }else{
          if(!(event.data instanceof Blob)||!this.pending||event.data.size>2_000_000||this.decoding)throw Error('Invalid frame');
          const meta=this.pending; this.pending=undefined;this.decoding=true;
          await this.frame(event.data,meta);this.decoding=false;
          if(generation===this.generation)this.send({type:'ack',id:meta.id});
        }
      }catch{if(generation===this.generation){this.disconnect();this.status('error','Connection rejected or invalid stream. Pair again if access expired.');}}
    };
    ws.onclose=()=>{if(generation===this.generation){this.disconnect();this.status('disconnected','Session ended. Reconnect explicitly.');}};
    ws.onerror=()=>{if(generation===this.generation){this.disconnect();this.status('error','Cannot connect. Check HTTPS, pairing and the Mac.');}};
  }
  send(m:ClientMessage){if(this.socket?.readyState===WebSocket.OPEN&&this.socket.bufferedAmount<8192)this.socket.send(JSON.stringify(m));}
  disconnect(){this.generation++;clearInterval(this.timer);this.timer=undefined;this.socket?.close();this.socket=undefined;this.pending=undefined;this.decoding=false;this.status('disconnected');}
}
