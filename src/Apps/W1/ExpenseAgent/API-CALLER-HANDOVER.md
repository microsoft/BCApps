# Expense policy evaluation API handover

This handover describes caller changes required by the policy evaluation concurrency checks.

## Required caller changes

### Submit policy results with their source versions

Each `policiesToEvaluate` row includes:

- `subjectVersion`
- `policyVersion`

Copy both values unchanged into the corresponding `expensePolicyFlags` POST. Both fields are required, including when their value is `0`.

```json
{
  "subjectSystemId": "00000000-0000-0000-0000-000000000000",
  "subjectType": "Expense Report Line",
  "subjectVersion": 3,
  "policySystemId": "00000000-0000-0000-0000-000000000000",
  "policyVersion": 2,
  "reason": "Receipt includes alcohol.",
  "compliant": false
}
```

The server rejects the result if the expense line or policy changed after the caller fetched it. Discard all results for that evaluation attempt, fetch the current line and policies again, and restart evaluation.

### Complete evaluation with the evaluated subject version

`MarkPoliciesEvaluated` now requires `evaluatedSubjectVersion`.

Use the `policyEvalVersion` returned with the expense report line. Confirm that every returned `policiesToEvaluate.subjectVersion` has the same value before evaluating. If it doesn't, the line changed between requests and the caller must restart. The line field is also available when `policiesToEvaluate` returns no rows.

```json
{
  "evaluatedSubjectVersion": 3
}
```

The action fails when:

- The expense line changed after evaluation started.
- An applicable policy does not have a result for the current subject and policy versions.

On either failure, fetch the current data and restart evaluation.

### Do not send `flaggedAt`

`flaggedAt` is read-only. The server always assigns the timestamp when it accepts a policy result.

### Reevaluate moved expense lines

Moving an expense line creates a new line identity and clears its policy evaluation state. Use the line returned by the move action, fetch `policiesToEvaluate`, and evaluate it as a new subject.

## Recommended evaluation flow

1. Read the expense report line and save `policyEvalVersion`.
2. Read `policiesToEvaluate`.
3. Confirm each returned `subjectVersion` matches the saved `policyEvalVersion`.
4. Evaluate each returned policy against that line snapshot.
5. POST one `expensePolicyFlag` per returned policy, copying both versions.
6. Call `MarkPoliciesEvaluated` with the saved `policyEvalVersion`.
7. If any comparison, version, or outstanding-policy check fails, discard the attempt and restart at step 1.

Do not reuse policy results after a line, child record, or policy changes. Each relevant change advances the subject or policy version.

## Posted expense reports

Posting now stores the line's policy status as an immutable historical snapshot. Later policy changes don't alter that posted status. The snapshot isn't currently exposed by `PostedExpReportLinesAPI`, so callers don't need to change their posted-report requests.
