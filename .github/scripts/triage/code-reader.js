// Repository code reader for issue triage context
// Reads AL source files from the checked-out repository to provide
// code context for more accurate triage assessments.

import { readdirSync, readFileSync, statSync, existsSync } from 'fs';
import { join, relative, extname } from 'path';

const MAX_CODE_BYTES = 15_000;
const AL_EXTENSIONS = new Set(['.al']);

/**
 * Resolve the repository root from the working directory or GITHUB_WORKSPACE.
 */
function getRepoRoot() {
  if (process.env.GITHUB_WORKSPACE) {
    return process.env.GITHUB_WORKSPACE;
  }
  // Fallback: assume CWD is .github/scripts/triage
  return join(process.cwd(), '..', '..', '..');
}

/**
 * Recursively list all files under a directory.
 * Returns paths relative to baseDir.
 */
function walkDir(dir, baseDir = dir) {
  const results = [];
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return results;
  }

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      // Skip node_modules, .git, etc.
      if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;
      results.push(...walkDir(fullPath, baseDir));
    } else if (entry.isFile() && AL_EXTENSIONS.has(extname(entry.name).toLowerCase())) {
      results.push({
        relativePath: relative(baseDir, fullPath),
        fullPath,
        name: entry.name,
      });
    }
  }
  return results;
}

/**
 * Score a file's relevance to the issue based on keyword matching.
 * Higher score = more relevant.
 */
function scoreFileRelevance(file, keywords) {
  if (keywords.length === 0) return 0;

  const nameLower = file.name.toLowerCase().replace(/\.[^.]+$/, '');
  const pathLower = file.relativePath.toLowerCase();

  let score = 0;
  for (const kw of keywords) {
    const kwLower = kw.toLowerCase();
    // Exact name match is highly valuable
    if (nameLower.includes(kwLower)) score += 3;
    // Path match (directory names)
    else if (pathLower.includes(kwLower)) score += 1;
  }
  return score;
}

/**
 * Read file content safely, returning null on error.
 */
function safeReadFile(filePath) {
  try {
    return readFileSync(filePath, 'utf-8');
  } catch {
    return null;
  }
}

/**
 * Fetch code context from the repository for a detected app area.
 *
 * @param {string} appAreaDirectory - Relative directory (e.g. "src/Apps/W1/Shopify/")
 * @param {string[]} keywords - Key terms extracted from the issue
 * @returns {{ fileList: string[], relevantFiles: { path: string, content: string }[], totalFiles: number, directory: string }}
 */
export function fetchCodeContext(appAreaDirectory, keywords) {
  const repoRoot = getRepoRoot();
  const absDir = join(repoRoot, appAreaDirectory);

  if (!existsSync(absDir)) {
    console.log(`Code reader: directory not found: ${absDir}`);
    return { fileList: [], relevantFiles: [], totalFiles: 0, directory: appAreaDirectory };
  }

  // Walk the directory and collect all AL files
  const allFiles = walkDir(absDir, join(repoRoot, 'src'));
  console.log(`Code reader: found ${allFiles.length} AL files in ${appAreaDirectory}`);

  if (allFiles.length === 0) {
    return { fileList: [], relevantFiles: [], totalFiles: 0, directory: appAreaDirectory };
  }

  // Build file listing (always included for directory overview)
  const fileList = allFiles.map(f => f.relativePath);

  // Score and rank files by relevance
  const scored = allFiles.map(f => ({
    ...f,
    score: scoreFileRelevance(f, keywords),
  }));
  scored.sort((a, b) => b.score - a.score);

  // Read top relevant files up to the byte cap
  const relevantFiles = [];
  let totalBytes = 0;

  for (const file of scored) {
    if (totalBytes >= MAX_CODE_BYTES) break;
    // Only include files that have some keyword relevance, unless we have very few files
    if (file.score === 0 && relevantFiles.length >= 5) break;

    const content = safeReadFile(file.fullPath);
    if (!content) continue;

    const contentBytes = Buffer.byteLength(content, 'utf-8');

    // Skip very large files (>10KB each) unless they're highly relevant
    if (contentBytes > 10_000 && file.score < 2) continue;

    if (totalBytes + contentBytes > MAX_CODE_BYTES && relevantFiles.length > 0) break;

    relevantFiles.push({
      path: file.relativePath,
      content,
      score: file.score,
    });
    totalBytes += contentBytes;
  }

  console.log(`Code reader: selected ${relevantFiles.length} relevant files (${totalBytes} bytes)`);

  return {
    fileList,
    relevantFiles,
    totalFiles: allFiles.length,
    directory: appAreaDirectory,
  };
}

/**
 * Format code context as a string block for inclusion in an LLM prompt.
 */
export function formatCodeContext(codeContext) {
  if (!codeContext || codeContext.totalFiles === 0) {
    return 'No repository source files found for the detected app area.';
  }

  let output = `### Repository code analysis\n\n`;
  output += `**App area directory**: \`${codeContext.directory}\`\n`;
  output += `**Total AL files**: ${codeContext.totalFiles}\n\n`;

  // File listing (capped for large directories)
  const MAX_LISTED_FILES = 50;
  const listedFiles = codeContext.fileList.slice(0, MAX_LISTED_FILES);
  output += `#### File listing (${listedFiles.length} of ${codeContext.totalFiles} files)\n\n`;
  output += '```\n';
  for (const file of listedFiles) {
    output += `${file}\n`;
  }
  if (codeContext.fileList.length > MAX_LISTED_FILES) {
    output += `... and ${codeContext.fileList.length - MAX_LISTED_FILES} more files\n`;
  }
  output += '```\n\n';

  // Relevant file contents
  if (codeContext.relevantFiles.length > 0) {
    output += `#### Source code of ${codeContext.relevantFiles.length} most relevant files\n\n`;
    for (const file of codeContext.relevantFiles) {
      output += `**File: \`${file.path}\`**\n`;
      output += '```al\n';
      output += file.content;
      if (!file.content.endsWith('\n')) output += '\n';
      output += '```\n\n';
    }
  }

  return output;
}
