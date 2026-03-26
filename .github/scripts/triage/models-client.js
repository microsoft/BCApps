// GitHub Copilot CLI client for model inference
// Uses `copilot -p` in programmatic mode instead of direct REST API calls.
// See: https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically

import { execFile } from 'node:child_process';
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

  const combinedPrompt = [
    systemPrompt,
    '',
    '---',
    '',
    userMessage,
  ].join('\n');

  console.log(`Calling: copilot -s --no-ask-user --model=${MODEL_NAME} (prompt: ${Math.round(combinedPrompt.length / 1024)}KB)`);

  let lastError;
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const output = await new Promise((resolve, reject) => {
        const child = execFile(
          'copilot',
          ['-s', '--no-ask-user', '--no-custom-instructions', `--model=${MODEL_NAME}`],
          {
            encoding: 'utf-8',
            timeout: 420_000,
            maxBuffer: 10 * 1024 * 1024,
            env: { ...process.env },
          },
          (err, stdout, stderr) => {
            if (err) {
              // Attach stderr for debugging CLI failures
              if (stderr) err.stderr = stderr.trim();
              return reject(err);
            }
            resolve(stdout);
          }
        );
        child.stdin.write(combinedPrompt);
        child.stdin.end();
      });

      // Extract the JSON object from the output.
      // The CLI may prepend conversational text before the JSON.
      let content = output.trim();
      if (content.startsWith('```')) {
        content = content.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
      }
      const jsonStart = content.indexOf('{');
      const jsonEnd = content.lastIndexOf('}');
      if (jsonStart !== -1 && jsonEnd > jsonStart) {
        content = content.slice(jsonStart, jsonEnd + 1);
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
      if (err.stderr) {
        console.warn(`Copilot CLI stderr: ${err.stderr.substring(0, 300)}`);
      }
      if (attempt === 0) {
        console.warn(`Copilot CLI error (attempt ${attempt + 1}), retrying in 5s...`);
        await sleep(5000);
        continue;
      }
      throw err;
    }
  }

  throw lastError;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
