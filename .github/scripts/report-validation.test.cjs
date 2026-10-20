const {test} = require('node:test');
const assert = require('node:assert/strict');
const report = require('./report-validation.cjs');
function fixture(sha='tested-sha') {
  const updates=[];
  const pr={state:'open',head:{ref:'feature/forge-remote-mvp',sha},body:'Human review notes.'};
  return {
    updates,pr,
    github:{rest:{pulls:{get:async()=>({data:pr}),update:async arg=>updates.push(arg)},actions:{listJobsForWorkflowRun(){}}},
      paginate:async()=>[{name:'mac',steps:[{name:'Swift tests',conclusion:'failure'},{name:'macOS release build',conclusion:'success'}]}]},
    context:{repo:{owner:'example',repo:'ForgeRemote'},sha:'tested-sha',serverUrl:'https://github.com',runId:123},
    core:{notice(){}}
  };
}
test('reports a failed test step alongside a successful release build without claiming physical validation',async()=>{
  const f=fixture();
  process.env.MAC_TEST_COUNT='18';process.env.MAC_FAILURES='1';process.env.MAC_ERRORS='0';process.env.MAC_SKIPPED='0';
  process.env.MAC_JOB_RESULT='failure';process.env.WEB_JOB_RESULT='success';
  await report(f);
  assert.equal(f.updates.length,1);
  const body=f.updates[0].body;
  assert.match(body,/Human review notes/);
  assert.match(body,/Swift tests step: \*\*failure\*\*/);
  assert.match(body,/release build step: \*\*success\*\*/);
  assert.match(body,/18 tests; 1 failures/);
  assert.match(body,/Physical Mac\/iPhone.*\*\*NOT TESTED\*\*/);
});
test('never overwrites a newer or unrelated PR head',async()=>{
  const f=fixture('newer-sha');await report(f);assert.equal(f.updates.length,0);
});
test('replaces only its marked section and does not invent missing test counts',async()=>{
  const f=fixture();delete process.env.MAC_TEST_COUNT;
  f.pr.body='Before.\n<!-- forge-ci-start -->Old report.<!-- forge-ci-end -->\nAfter.';
  await report(f);const body=f.updates[0].body;
  assert.match(body,/Before\./);assert.match(body,/After\./);assert.doesNotMatch(body,/Old report/);
  assert.match(body,/No current-run XCTest count available: \*\*NOT VERIFIED\*\*/);
  assert.equal(body.match(/<!-- forge-ci-start -->/g).length,1);
});
