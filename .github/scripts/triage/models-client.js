// GitHub Copilot CLI client for model inference
// Uses `copilot -p` in programmatic mode instead of direct REST API calls.
// See: https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically

import { execSync } from 'node:child_process';
import { writeFileSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { MODEL_NAME } from './config.js';

/**
 * Call GPT via GitHub Copilot CLI (`copilot -p`) and return parsed JSON.
 * Authentication is handled by COPILOT_GITHUB_TOKEN (a PAT with Copilot Requests permission).
 * Retries once on transient errors or JSON parse failures.
 */
export async function callGPT(systemPrompt, userMessage) {
  if (!process.env.COPILOT_GITHUB_TOKEN && !process.env.GH_TOKEN && !process.env.GITHUB_TOKEN) {
    throw new Error('COPILOT_GITHUB_TOKEN, GH_TOKEN, or GITHUB_TOKEN environment variable is required');
  }

  const promptFile = join(tmpdir(), `triage-prompt-${Date.now()}.md`);

  try {
    const combinedPrompt = [
      systemPrompt,
      '',
      '---',
      '',
      userMessage,
    ].join('\n');

    writeFileSync(promptFile, combinedPrompt, 'utf-8');

    console.log(`Calling: copilot -s --no-ask-user --model=${MODEL_NAME}`);

    let lastError;
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const output = execSync(
          `cat ${JSON.stringify(promptFile)} | copilot -s --no-ask-user --model=${MODEL_NAME}`,
          {
            encoding: 'utf-8',
            timeout: 180_000,
            maxBuffer: 10 * 1024 * 1024,
            env: { ...process.env },
          }
        );

        // Strip markdown code block wrapping if present
        let content = output.trim();
        if (content.startsWith('```')) {
          content = content.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
        }

        try {
          return JSON.parse(content);
        } catch (parseErr) {
          lastError = new Error(
            `Failed to parse JSON from Copilot CLI response: ${parseErr.message}\nRaw output (first 500 chars): ${content.slice(0, 500)}`
          );
          if (attempt === 0) {
            console.warn(`JSON parse error, retrying (attempt ${attempt + 1})...`);
            await sleep(2000);
            continue;
          }
          throw lastError;
        }
      } catch (err) {
        lastError = err;
        if (attempt === 0 && (err.message?.includes('JSON') || err.status)) {
          console.warn(`Error, retrying (attempt ${attempt + 1})...`);
          await sleep(5000);
          continue;
        }
        throw err;
      }
    }

    throw lastError;
  } finally {
    try { unlinkSync(promptFile); } catch { /* temp file cleanup */ }
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
