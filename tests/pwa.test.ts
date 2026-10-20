import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import {it,expect} from 'vitest';
it('declares standalone same-origin PWA',()=>{
 const manifest=JSON.parse(readFileSync('apps/web/public/manifest.webmanifest','utf8'));expect(manifest.display).toBe('standalone');expect(manifest.start_url).toBe('/');expect(manifest.icons.length).toBeGreaterThan(0);
});
it('service worker ignores credentials, frames, third-party requests and mutations',()=>{
 const listeners:Record<string,(e:unknown)=>void>={};
 runInNewContext(readFileSync('apps/web/public/sw.js','utf8'),{URL,self:{location:{origin:'https://mac.test'},addEventListener:(k:string,cb:(e:unknown)=>void)=>listeners[k]=cb}});
 for(const [path,method] of [['/api/pair','POST'],['/api/health','GET'],['/socket','GET'],['/frame.jpg','GET'],['https://other.test/icon.svg','GET'],['/?token=private','GET']]){
  let intercepted=false;listeners.fetch({request:{url:new URL(path,'https://mac.test').href,method},respondWith:()=>{intercepted=true;}});expect(intercepted,path).toBe(false);
 }
});
