// Git history analysis for triage enrichment
// Analyzes recent commit history in the detected app area to provide
// change velocity, active contributors, and keyword-matching commits.

import { execFileSync } from 'child_process';
import { join } from 'path';
import { existsSync } from 'fs';

const MAX_CHANGED_FILES = 10;
const MAX_CONTRIBUTORS = 5;
const MAX_KEYWORD_COMMITS = 10;
const HISTORY_MONTHS = 3;

/**
 * Resolve the repository root from the working directory or GITHUB_WORKSPACE.
 */
function getRepoRoot() {
  if (process.env.GITHUB_WORKSPACE) {
    return process.env.GITHUB_WORKSPACE;
  }
  return join(process.cwd(), '..', '..', '..');
}

/**
 * Fetch git history for the detected app area directory.
 *
 * @param {string} appAreaDirectory - Relative directory (e.g. "src/Apps/W1/Shopify/")
 * @param {string[]} keywords - Key terms extracted from the issue
 * @returns {{ topChangedFiles: Array, topContributors: Array, keywordCommits: Array, totalCommits: number }}
 */
export function fetchGitHistory(appAreaDirectory, keywords) {
  const repoRoot = getRepoRoot();
  const absDir = join(repoRoot, appAreaDirectory);

  if (!existsSync(absDir)) {
    console.log(`Git history: directory not found: ${absDir}`);
    return { topChangedFiles: [], topContributors: [], keywordCommits: [], totalCommits: 0 };
  }

  try {
    const output = execFileSync('git', [
      'log',
      `--since=${HISTORY_MONTHS} months ago`,
      '--name-only',
      '--pretty=format:%h|%an|%ad|%s',
      '--date=short',
      '--',
      appAreaDirectory,
    ], {
      cwd: repoRoot,
      encoding: 'utf-8',
      timeout: 15_000,
      // Prevent git from hanging on large repos
      maxBuffer: 5 * 1024 * 1024,
    });

    if (!output.trim()) {
      console.log(`Git history: no commits found in ${appAreaDirectory} in the last ${HISTORY_MONTHS} months`);
      return { topChangedFiles: [], topContributors: [], keywordCommits: [], totalCommits: 0 };
    }

    return parseGitLog(output, keywords);

  } catch (err) {
    console.warn(`Git history: failed - ${err.message}`);
    return { topChangedFiles: [], topContributors: [], keywordCommits: [], totalCommits: 0, error: err.message };
  }
}

/**
 * Parse git log output into structured data.
 */
function parseGitLog(output, keywords) {
  const fileChangeCounts = new Map();
  const contributorCounts = new Map();
  const keywordCommits = [];
  let totalCommits = 0;

  const kwLower = (keywords || []).map(k => k.toLowerCase());

  // Split by double newlines to get commit blocks
  // Format: hash|author|date|subject\nfile1\nfile2\n\nhash|...
  const blocks = output.split(/\n\n+/);

  for (const block of blocks) {
    const lines = block.split('\n').filter(l => l.trim());
    if (lines.length === 0) continue;

    const headerMatch = lines[0].match(/^([^|]+)\|([^|]+)\|([^|]+)\|(.*)$/);
    if (!headerMatch) continue;

    const [, hash, author, date, subject] = headerMatch;
    totalCommits++;

    // Count contributor
    contributorCounts.set(author, (contributorCounts.get(author) || 0) + 1);

    // Count file changes
    for (let i = 1; i < lines.length; i++) {
      const file = lines[i].trim();
      if (file) {
        fileChangeCounts.set(file, (fileChangeCounts.get(file) || 0) + 1);
      }
    }

    // Check if commit subject matches any keyword
    if (keywordCommits.length < MAX_KEYWORD_COMMITS) {
      const subjectLower = subject.toLowerCase();
      const matched = kwLower.filter(kw => subjectLower.includes(kw));
      if (matched.length > 0) {
        keywordCommits.push({ hash, author, date, subject, matchedKeywords: matched });
      }
    }
  }

  // Sort and take top N
  const topChangedFiles = [...fileChangeCounts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, MAX_CHANGED_FILES)
    .map(([path, count]) => ({ path, changeCount: count }));

  const topContributors = [...contributorCounts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, MAX_CONTRIBUTORS)
    .map(([name, commits]) => ({ name, commits }));

  console.log(`Git history: ${totalCommits} commits, ${fileChangeCounts.size} files changed, ${keywordCommits.length} keyword matches`);

  return { topChangedFiles, topContributors, keywordCommits, totalCommits };
}

/**
 * Format git history for inclusion in the LLM prompt.
 */
export function formatGitHistoryContext(result) {
  if (!result || result.totalCommits === 0) {
    if (result?.error) {
      return `### Git history\n\nCould not retrieve git history: ${result.error}\n`;
    }
    return '### Git history\n\nNo recent commits found in this app area (last 3 months).\n';
  }

  let output = `### Git history (last 3 months)\n\n`;
  output += `**${result.totalCommits} commits** in this area.\n\n`;

  if (result.topChangedFiles.length > 0) {
    output += `**Most frequently changed files:**\n\n`;
    for (const f of result.topChangedFiles) {
      output += `- \`${f.path}\` — ${f.changeCount} change${f.changeCount !== 1 ? 's' : ''}\n`;
    }
    output += '\n';
  }

  if (result.topContributors.length > 0) {
    output += `**Active contributors:**\n\n`;
    for (const c of result.topContributors) {
      output += `- ${c.name} — ${c.commits} commit${c.commits !== 1 ? 's' : ''}\n`;
    }
    output += '\n';
  }

  if (result.keywordCommits.length > 0) {
    output += `**Commits matching issue keywords:**\n\n`;
    for (const c of result.keywordCommits) {
      output += `- \`${c.hash}\` ${c.date} — ${c.subject} (by ${c.author})\n`;
    }
    output += '\n';
  }

  return output;
}
