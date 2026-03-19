// Microsoft AppSource marketplace context for triage enrichment
//
// AppSource does not expose a public API — all endpoints are protected by Azure WAF
// and require browser-based JavaScript challenges. Instead, we provide the search URL
// and instruct the LLM to estimate ecosystem interest from its training knowledge.

/**
 * Build AppSource marketplace context for the given keywords.
 * Returns search terms and a URL for the LLM and human reviewers.
 */
export async function fetchMarketplaceApps(keywords) {
  if (!keywords || keywords.length === 0) {
    return { searchTerms: '', searchUrl: null };
  }

  const searchTerms = keywords.slice(0, 3).join(' ');
  const searchUrl = `https://appsource.microsoft.com/en-us/marketplace/apps?product=dynamics-365%3Bdynamics-365-business-central&search=${encodeURIComponent(searchTerms)}`;

  console.log(`AppSource: built search URL for "${searchTerms}"`);
  return { searchTerms, searchUrl };
}

/**
 * Format marketplace context for inclusion in the LLM prompt.
 * Instructs the model to estimate ecosystem interest from its own knowledge.
 */
export function formatMarketplaceContext(result) {
  if (!result || !result.searchUrl) {
    return '';
  }

  return `### AppSource Marketplace

Based on your knowledge of the Microsoft AppSource marketplace for Business Central, estimate how many third-party apps exist in the area related to "${result.searchTerms}".

Use this as a demand signal:
- **Many apps (20+)**: Strong ecosystem interest — well-established capability, improvements have high value
- **Some apps (5-19)**: Moderate interest — established demand in this area
- **Few apps (<5)**: Niche area — could be an opportunity or low-demand capability

Include your estimate and reasoning in the enrichment output under "marketplace_signal".

Manual search: ${result.searchUrl}
`;
}
