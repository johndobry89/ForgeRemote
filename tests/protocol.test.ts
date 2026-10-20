import {describe,it,expect} from 'vitest';
import {parseServer,pointInImage} from '../packages/protocol/src/index';
describe('wire protocol',()=>{
 it('requires negotiated v1 and positive bounded geometry',()=>{
  expect(parseServer({type:'hello',version:1})).toEqual({type:'hello',version:1});
  for(const message of [{type:'hello',version:2},{type:'frame',id:1,epoch:1,width:9000,height:720},{type:'frame',id:1,epoch:0,width:1280,height:720},{type:'shell'},null])expect(()=>parseServer(message)).toThrow();
 });
 it('accepts current display geometry after resize',()=>{
  expect(parseServer({type:'frame',id:2,epoch:3,width:1080,height:1920}).type).toBe('frame');
 });
});
describe('letterboxed coordinate mapping',()=>{
 const box={left:10,top:20,width:400,height:400};
 it('excludes black bars',()=>expect(pointInImage(20,30,box,{width:1920,height:1080})).toBeNull());
 it('maps Retina image center to normalized center',()=>expect(pointInImage(210,220,box,{width:3840,height:2160})).toEqual({x:.5,y:.5}));
 it('recalculates after portrait resize',()=>expect(pointInImage(210,220,box,{width:1080,height:1920})).toEqual({x:.5,y:.5}));
 it('rejects zero and invalid dimensions',()=>{expect(pointInImage(0,0,box,{width:0,height:10})).toBeNull();expect(pointInImage(0,0,box,{width:NaN,height:10})).toBeNull();});
});
