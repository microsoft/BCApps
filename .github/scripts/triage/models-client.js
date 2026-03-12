// GitHub Models API client for GPT-5.4
// See: docs/features/issue-triage-agent/design.md (section 6.4)

import { MODELS_API_ENDPOINT, MODEL_NAME, MODEL_TEMPERATURE } from './config.js';

/**
 * Call GPT via the GitHub Models API and return parsed JSON.
 * Uses COPILOT_API_KEY (a Copilot-entitled PAT) for higher rate limits.
 * Falls back to GITHUB_TOKEN if COPILOT_API_KEY is not set.
 * Retries once on rate-limit (429) or server error (5xx).
 */
export async function callGPT(systemPrompt, userMessage) {
  const token = process.env.COPILOT_API_KEY || process.env.GITHUB_TOKEN;
  if (!token) {
    throw new Error('COPILOT_API_KEY or GITHUB_TOKEN environment variable is required');
  }

  const body = {
    model: MODEL_NAME,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userMessage },
    ],
    temperature: MODEL_TEMPERATURE,
    response_format: { type: 'json_object' },
  };

  let lastError;
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const response = await fetch(MODELS_API_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(body),
      });

      if (response.status === 429 || response.status >= 500) {
        lastError = new Error(`GitHub Models API returned ${response.status}: ${await response.text()}`);
        if (attempt === 0) {
          console.warn(`Retrying after ${response.status} response (attempt ${attempt + 1})...`);
          await sleep(5000);
          continue;
        }
        throw lastError;
      }

      if (!response.ok) {
        const text = await response.text();
        throw new Error(`GitHub Models API error ${response.status}: ${text}`);
      }

      const data = await response.json();
      const content = data.choices?.[0]?.message?.content;
      if (!content) {
        throw new Error('No content in GitHub Models API response');
      }

      try {
        return JSON.parse(content);
      } catch (parseErr) {
        lastError = new Error(`Failed to parse JSON from model response: ${parseErr.message}`);
        if (attempt === 0) {
          console.warn(`JSON parse error, retrying (attempt ${attempt + 1})...`);
          await sleep(2000);
          continue;
        }
        throw lastError;
      }
    } catch (err) {
      lastError = err;
      if (attempt === 0 && (err.message?.includes('fetch') || err.message?.includes('JSON'))) {
        console.warn(`Error, retrying (attempt ${attempt + 1})...`);
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
