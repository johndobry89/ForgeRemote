import {test,expect} from '@playwright/test';
test('mobile shell never fabricates connection and refuses plaintext',async({page})=>{
 await page.goto('/');await expect(page.getByRole('heading',{name:/A little closer/})).toBeVisible();
 await expect(page.locator('.status')).toHaveText('● disconnected');
 await page.getByLabel('Mac pairing code').fill('12345678');await page.getByRole('button',{name:'Pair Mac'}).click();
 await expect(page.getByRole('alert')).toContainText('trusted HTTPS');
 await expect(page.locator('.status')).toHaveText('● error');
 await expect(page.getByRole('navigation',{name:'Control mode'})).toBeVisible();
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
});
test('desktop shell and modes are accessible without remote input',async({page})=>{
 await page.setViewportSize({width:1280,height:800});await page.goto('/');
 for(const name of ['Desktop','Trackpad','Keyboard','Actions']){
  const button=page.getByRole('button',{name,exact:true});await button.click();await expect(button).toHaveAttribute('aria-pressed','true');
 }
 await expect(page.getByRole('button',{name:'Send text'})).toHaveCount(0);
 await page.getByRole('button',{name:'Reconnect with existing pairing'}).click();
 await expect(page.getByRole('alert')).toContainText('HTTPS');
});
