// Uses the runner's repository-scoped token. No credential is stored or logged.
module.exports = async ({github, context, core}) => {
  const repo = context.repo;
  const {data: pr} = await github.rest.pulls.get({...repo, pull_number: 1});
  if (pr.state !== 'open' || pr.head.ref !== 'feature/forge-remote-mvp' || pr.head.sha !== context.sha) {
    core.notice('Skipping stale or unrelated PR update');
    return;
  }
  const jobs = await github.paginate(github.rest.actions.listJobsForWorkflowRun, {
    ...repo, run_id: context.runId, per_page: 100
  });
  const mac = jobs.find(job => job.name === 'mac');
  const outcome = name => mac?.steps.find(step => step.name === name)?.conclusion ?? 'not run';
  const run = `${context.serverUrl}/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`;
  const count = process.env.MAC_TEST_COUNT;
  const start = '<!-- forge-ci-start -->', end = '<!-- forge-ci-end -->';
  const lines = [
    start,
    '### Automated validation',
    '',
    `Source commit: \`${context.sha}\` · [Actions run](${run})`,
    '',
    `- Web job: **${process.env.WEB_JOB_RESULT}**.`,
    `- macOS job: **${process.env.MAC_JOB_RESULT}**.`,
    `- Swift tests step: **${outcome('Swift tests')}**.`,
    count ? `- XCTest XML: ${count} tests; ${process.env.MAC_FAILURES} failures; ${process.env.MAC_ERRORS} errors; ${process.env.MAC_SKIPPED} skipped.` : '- No current-run XCTest count available: **NOT VERIFIED**.',
    `- macOS release build step: **${outcome('macOS release build')}**.`,
    process.env.MAC_ARTIFACT_URL ? `- [Native evidence and resolved Swift dependencies](${process.env.MAC_ARTIFACT_URL}).` : '- Native evidence artifact: unavailable.',
    '- Input tests capture real CGEvents without injecting into the runner desktop. They cover modifier event types/flags, both mouse buttons, normal keys, cleanup ordering, permission loss and the host session teardown boundary.',
    '- Physical Mac/iPhone capture, OS acceptance of input/cleanup, private HTTPS and PWA installation: **NOT TESTED**. Follow `docs/PHYSICAL_ACCEPTANCE.md`.',
    end
  ];
  const section = lines.join('\n');
  const body = pr.body ?? '';
  const from = body.indexOf(start), to = body.indexOf(end);
  const next = from >= 0 && to >= from ? body.slice(0, from) + section + body.slice(to + end.length) : `${body}\n\n${section}`;
  await github.rest.pulls.update({...repo, pull_number: 1, body: next});
};
