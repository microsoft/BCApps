// Triage report publisher - pushes reports as wiki pages to a configurable repository.
// The TRIAGE_REPO env var overrides the target repo.

import { execFileSync } from 'child_process';
import { writeFileSync, existsSync, rmSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

// Default: use the source repo's own wiki. Override with TRIAGE_REPO env var.

/**
 * Publish a full triage report to the target repository's wiki.
 * Returns the URL of the published wiki page, or null on failure.
 *
 * @param {string} owner - Repository owner (e.g., "microsoft")
 * @param {string} repo - Source repository name (for context in commit messages)
 * @param {number} issueNumber - Issue number (used in page name)
 * @param {string} markdownContent - Full report markdown
 * @returns {Promise<string|null>} Wiki page URL or null
 */
export async function publishWikiReport(owner, repo, issueNumber, markdownContent) {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    console.warn('Wiki: No GITHUB_TOKEN available, skipping publish');
    return null;
  }

  const triageRepo = process.env.TRIAGE_REPO || repo;
  const wikiDir = join(tmpdir(), `wiki-${triageRepo}-${Date.now()}`);
  const cloneUrl = `https://x-access-token:${token}@github.com/${owner}/${triageRepo}.wiki.git`;
  const pageName = `Triage-Report-Issue-${issueNumber}`;
  const pageFile = `${pageName}.md`;

  try {
    // Shallow clone the wiki repo
    console.log(`Wiki: Cloning ${owner}/${triageRepo}.wiki.git...`);
    execFileSync('git', ['clone', '--depth', '1', cloneUrl, wikiDir], {
      timeout: 60000,
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Initialize wiki if empty (GitHub requires at least Home.md)
    ensureWikiInitialized(wikiDir, owner, repo, triageRepo);

    // Write the triage report page
    writeFileSync(join(wikiDir, pageFile), markdownContent, 'utf-8');

    // Configure git author
    execFileSync('git', ['config', 'user.name', 'github-actions[bot]'], { cwd: wikiDir });
    execFileSync('git', ['config', 'user.email', 'github-actions[bot]@users.noreply.github.com'], { cwd: wikiDir });

    // Stage and commit
    execFileSync('git', ['add', pageFile, 'Home.md'], { cwd: wikiDir });

    // Check if there are changes to commit
    try {
      execFileSync('git', ['diff', '--cached', '--quiet'], { cwd: wikiDir });
      console.log('Wiki: No changes detected, skipping commit');
    } catch {
      execFileSync('git', ['commit', '-m', `Update triage report for ${repo}#${issueNumber}`], {
        cwd: wikiDir,
        timeout: 10000,
      });

      console.log('Wiki: Pushing...');
      execFileSync('git', ['push'], {
        cwd: wikiDir,
        timeout: 60000,
        stdio: ['pipe', 'pipe', 'pipe'],
      });
    }

    const wikiUrl = `https://github.com/${owner}/${triageRepo}/wiki/${pageName}`;
    console.log(`Wiki: Published ${wikiUrl}`);
    return wikiUrl;

  } catch (err) {
    console.warn(`Wiki: Failed to publish report — ${err.message}`);
    return null;
  } finally {
    try {
      rmSync(wikiDir, { recursive: true, force: true });
    } catch {
      // Best-effort cleanup
    }
  }
}

/**
 * Ensure the wiki has a Home.md page.
 */
function ensureWikiInitialized(wikiDir, owner, sourceRepo, triageRepo) {
  const homePath = join(wikiDir, 'Home.md');
  if (!existsSync(homePath)) {
    const content = [
      `# Triage Reports`,
      ``,
      `This wiki contains AI triage reports for [${owner}/${sourceRepo}](https://github.com/${owner}/${sourceRepo}) issues.`,
      ``,
      `Reports are generated automatically when the \`ai-triage\` label is added to an issue.`,
      `Each report provides quality scoring, triage recommendations, and enrichment context.`,
      ``,
      `## How to find a report`,
      ``,
      `Reports are named \`Triage-Report-Issue-{number}\`. Use the wiki sidebar or search to find a specific issue's report.`,
      ``,
    ].join('\n');
    writeFileSync(homePath, content, 'utf-8');
  }
}

/**
 * Build the expected wiki page URL for a given issue number.
 */
export function getWikiPageUrl(owner, repo, issueNumber) {
  const triageRepo = process.env.TRIAGE_REPO || repo;
  return `https://github.com/${owner}/${triageRepo}/wiki/Triage-Report-Issue-${issueNumber}`;
}
