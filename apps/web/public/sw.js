// Only immutable Vite assets and public shell files. Never API, socket, frames or input.
const CACHE='forge-shell-v1';
const SHELL=['/','/index.html','/icon.svg','/manifest.webmanifest'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(c=>c.addAll(SHELL))));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener('fetch',event=>{
 const u=new URL(event.request.url);
 if(event.request.method!=='GET'||u.origin!==self.location.origin||u.search||!(SHELL.includes(u.pathname)||/^\/assets\/[\w.-]+\.(js|css)$/.test(u.pathname)))return;
 event.respondWith(fetch(event.request).then(response=>{
  if(response.ok){const copy=response.clone();event.waitUntil(caches.open(CACHE).then(c=>c.put(event.request,copy)));}return response;
 }).catch(()=>caches.match(event.request).then(r=>r||Response.error())));
});
