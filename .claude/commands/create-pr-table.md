Fetch all open PRs by onbuyuka from https://github.com/microsoft/BCApps using WebFetch (URL: https://github.com/microsoft/BCApps/pulls?q=is%3Apr+is%3Aopen+author%3Aonbuyuka). Exclude any draft PRs.

Then for each PR, fetch its page (https://github.com/microsoft/BCApps/pull/<number>) to check for approvals.

Create an HTML file at ~/Downloads/pr-table.html with a bordered table containing columns: PR, Approval 1, Approval 2.

- The PR column should contain a clickable link to the PR on GitHub.
- The Approval columns should show a ✅ tick emoji followed by the GitHub username of each approver, or be empty if not yet approved.

After creating the file, tell the user to open it in a browser, select all (Ctrl+A), copy (Ctrl+C), and paste (Ctrl+V) into Teams.
