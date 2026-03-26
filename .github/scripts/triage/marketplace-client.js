// Microsoft Marketplace (formerly AppSource) context for triage enrichment
//
// The Marketplace does not expose a public API — all endpoints are protected by
// Azure WAF and require browser-based JavaScript challenges. Instead, we provide
// the search URL and instruct the LLM to produce a structured ecosystem assessment
// from its training knowledge.

/**
 * Build Marketplace context for the given keywords.
 * Returns search terms and a URL for the LLM and human reviewers.
 */
export async function fetchMarketplaceApps(keywords) {
  if (!keywords || keywords.length === 0) {
    return { searchTerms: '', searchUrl: null };
  }

  const searchTerms = keywords.slice(0, 3).join(' ');
  const searchUrl = `https://appsource.microsoft.com/en-us/marketplace/apps?product=dynamics-365%3Bdynamics-365-business-central&search=${encodeURIComponent(searchTerms)}`;

  return { searchTerms, searchUrl };
}

/**
 * Format marketplace context for inclusion in the LLM prompt.
 * Instructs the model to produce a structured ecosystem assessment.
 */
export function formatMarketplaceContext(result) {
  if (!result || !result.searchUrl) {
    return '';
  }

  return `### Marketplace Ecosystem

Based on your knowledge of the Microsoft Dynamics 365 Business Central Marketplace (formerly AppSource), assess the third-party app ecosystem in the area related to "${result.searchTerms}".

Classify the ecosystem density:
- **Rich (20+ apps)**: Strong ecosystem interest — well-established capability, improvements have high value
- **Moderate (5-19 apps)**: Established demand — third-party solutions exist in this space
- **Sparse (<5 apps)**: Niche area — could be an opportunity or low-demand capability
- **Unknown**: Not enough information to assess

Provide your classification and a brief rationale in the \`marketplace_ecosystem\` output field.

Manual search: ${result.searchUrl}
`;
}
