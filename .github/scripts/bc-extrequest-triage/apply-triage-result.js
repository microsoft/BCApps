const fs = require('fs');

module.exports = async function applyTriageResult({
  github,
  context,
  core,
  issueNumber = Number(process.env.ISSUE_NUMBER),
  resultPath = 'result/triage-result.json'
}) {
  const result = JSON.parse(fs.readFileSync(resultPath, 'utf8'));
  const owner = context.repo.owner;
  const repo = context.repo.repo;

  if (result.issue_number !== issueNumber) {
    throw new Error(
      `Result is for issue #${result.issue_number}, expected #${issueNumber}.`
    );
  }

  if (result.skipped) {
    core.info(`Issue #${issueNumber} was skipped: ${result.reason}`);
    return;
  }

  const issue = await github.rest.issues.get({
    owner,
    repo,
    issue_number: issueNumber
  });
  const currentLabels = issue.data.labels.map(label =>
    typeof label === 'string' ? label : label.name
  );
  const desiredLabels = [...new Set(result.labels_to_set ?? [])];

  if (
    desiredLabels.length > 0 &&
    (
      currentLabels.length !== desiredLabels.length ||
      currentLabels.some(label => !desiredLabels.includes(label))
    )
  ) {
    await github.rest.issues.setLabels({
      owner,
      repo,
      issue_number: issueNumber,
      labels: desiredLabels
    });
  }

  if (result.comment_to_post) {
    await github.rest.issues.createComment({
      owner,
      repo,
      issue_number: issueNumber,
      body: result.comment_to_post
    });
  }

  if (
    result.issue_state?.toLowerCase() === 'closed' &&
    issue.data.state !== 'closed'
  ) {
    await github.rest.issues.update({
      owner,
      repo,
      issue_number: issueNumber,
      state: 'closed',
      state_reason: 'not_planned'
    });
  }
};
