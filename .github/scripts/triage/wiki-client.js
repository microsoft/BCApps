// GitHub Wiki client - publishes triage reports as wiki pages
// Wiki repos are separate git repos at {owner}/{repo}.wiki.git.
// No REST API exists for wiki operations, so we clone, write, and push via git.

import { execFileSync } from 'child_process';
import { writeFileSync, existsSync, mkdirSync, rmSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

/**
 * Publish a full triage report to the repository wiki.
 * Returns the URL of the published wiki page, or null on failure.
 *
 * @param {string} owner - Repository owner
 * @param {string} repo - Repository name
 * @param {number} issueNumber - Issue number (used in page name)
 * @param {string} markdownContent - Full report markdown
 * @returns {Promise<string|null>} Wiki page URL or null
 */
export async function publishWikiReport(owner, repo, issueNumber, markdownContent) {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    console.warn('Wiki: No GITHUB_TOKEN available, skipping wiki publish');
    return null;
  }

  const wikiDir = join(tmpdir(), `wiki-${repo}-${Date.now()}`);
  const cloneUrl = `https://x-access-token:${token}@github.com/${owner}/${repo}.wiki.git`;
  const pageName = `Triage-Report-Issue-${issueNumber}`;
  const pageFile = `${pageName}.md`;

  try {
    // Shallow clone the wiki repo
    console.log(`Wiki: Cloning ${owner}/${repo}.wiki.git...`);
    execFileSync('git', ['clone', '--depth', '1', cloneUrl, wikiDir], {
      timeout: 60000,
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Initialize wiki if empty (GitHub requires at least Home.md)
    ensureWikiInitialized(wikiDir, owner, repo);

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
      // No changes — page content is identical to what's already there
      console.log('Wiki: No changes detected, skipping commit');
    } catch {
      // diff --quiet exits non-zero when there are changes — commit them
      execFileSync('git', ['commit', '-m', `Update triage report for issue #${issueNumber}`], {
        cwd: wikiDir,
        timeout: 10000,
      });

      // Push
      console.log('Wiki: Pushing...');
      execFileSync('git', ['push'], {
        cwd: wikiDir,
        timeout: 60000,
        stdio: ['pipe', 'pipe', 'pipe'],
      });
    }

    const wikiUrl = `https://github.com/${owner}/${repo}/wiki/${pageName}`;
    console.log(`Wiki: Published ${wikiUrl}`);
    return wikiUrl;

  } catch (err) {
    console.warn(`Wiki: Failed to publish report — ${err.message}`);
    return null;
  } finally {
    // Clean up temp directory
    try {
      rmSync(wikiDir, { recursive: true, force: true });
    } catch {
      // Best-effort cleanup
    }
  }
}

/**
 * Ensure the wiki has a Home.md page (required for GitHub to display the wiki).
 * Also updates the Home page with a link to the latest report.
 */
function ensureWikiInitialized(wikiDir, owner, repo) {
  const homePath = join(wikiDir, 'Home.md');
  if (!existsSync(homePath)) {
    const homeContent = [
      `# Triage Reports`,
      ``,
      `This wiki contains detailed AI triage reports for [${owner}/${repo}](https://github.com/${owner}/${repo}) issues.`,
      ``,
      `Reports are generated automatically when the \`ai-triage\` label is added to an issue.`,
      `Each report provides quality scoring, triage recommendations, and enrichment context.`,
      ``,
      `## How to find a report`,
      ``,
      `Reports are named \`Triage-Report-Issue-{number}\`. Use the wiki sidebar or search to find a specific issue's report.`,
      ``,
    ].join('\n');
    writeFileSync(homePath, homeContent, 'utf-8');
  }
}

/**
 * Build the expected wiki page URL for a given issue number.
 * Useful for generating links without actually publishing.
 */
export function getWikiPageUrl(owner, repo, issueNumber) {
  return `https://github.com/${owner}/${repo}/wiki/Triage-Report-Issue-${issueNumber}`;
}
