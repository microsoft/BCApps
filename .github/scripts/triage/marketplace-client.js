// Microsoft AppSource marketplace client
// Searches for BC-related apps to gauge ecosystem interest in a capability.
// A high number of related apps indicates general market demand.

const APPSOURCE_SEARCH_URL = 'https://appsource.microsoft.com/view/searchresults';
const APPSOURCE_API_URL = 'https://appsource.microsoft.com/api/Marketplace/search';
const BC_PRODUCT_ID = 'dynamics-365-business-central';
const MAX_RESULTS = 5;

/**
 * Search the AppSource marketplace for BC apps related to the given keywords.
 * Returns the total count of matching apps and top results.
 */
export async function fetchMarketplaceApps(keywords) {
  if (!keywords || keywords.length === 0) {
    return { apps: [], totalCount: 0 };
  }

  // Use top 3 most specific keywords for search
  const searchTerms = keywords.slice(0, 3).join(' ');
  console.log(`AppSource: searching for "${searchTerms}"...`);

  try {
    const params = new URLSearchParams({
      query: searchTerms,
      product: 'dynamics-365;dynamics-365-business-central',
      page: '1',
      sortBy: 'Relevance',
    });

    const response = await fetch(`https://appsource.microsoft.com/api/Marketplace/search?${params}`, {
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'BCApps-Triage-Agent/1.0',
      },
      signal: AbortSignal.timeout(15000),
    });

    if (!response.ok) {
      // Fallback: try the storefront search page scraping approach
      console.warn(`AppSource API returned ${response.status}, trying fallback...`);
      return await fetchMarketplaceFallback(searchTerms);
    }

    const data = await response.json();
    const apps = (data.apps || data.results || []).slice(0, MAX_RESULTS).map(app => ({
      title: app.title || app.displayName || '(untitled)',
      publisher: app.publisher || app.publisherDisplayName || 'Unknown',
      rating: app.rating || app.averageRating || null,
      url: `https://appsource.microsoft.com/en-us/product/${BC_PRODUCT_ID}/${app.id || ''}`,
    }));

    const totalCount = data.totalCount || data.total || apps.length;

    console.log(`AppSource: found ${totalCount} related apps`);
    return { apps, totalCount, searchTerms };

  } catch (err) {
    console.warn(`AppSource: search failed — ${err.message}`);
    return await fetchMarketplaceFallback(searchTerms);
  }
}

/**
 * Fallback: construct a search URL for manual inclusion in the prompt.
 * Used when the API is unavailable or returns errors.
 */
async function fetchMarketplaceFallback(searchTerms) {
  const searchUrl = `https://appsource.microsoft.com/en-us/marketplace/apps?product=dynamics-365%3Bdynamics-365-business-central&search=${encodeURIComponent(searchTerms)}`;
  console.log(`AppSource: using fallback search URL`);
  return {
    apps: [],
    totalCount: null,
    searchTerms,
    searchUrl,
    fallback: true,
  };
}

/**
 * Format marketplace results for inclusion in the LLM prompt.
 */
export function formatMarketplaceContext(result) {
  if (!result) {
    return '### AppSource Marketplace\n\nMarketplace search not available.\n';
  }

  if (result.fallback) {
    return `### AppSource Marketplace\n\nDirect search was not available. Review related apps manually: [Search AppSource](${result.searchUrl})\n`;
  }

  if (result.totalCount === 0 || result.apps.length === 0) {
    return `### AppSource Marketplace\n\nNo related BC apps found on AppSource for "${result.searchTerms}".\nThis may indicate a niche capability with limited ecosystem support.\n`;
  }

  let output = `### AppSource Marketplace\n\n`;
  output += `Found **${result.totalCount}** related Business Central apps on AppSource for "${result.searchTerms}".\n`;

  if (result.totalCount >= 20) {
    output += `> **High ecosystem interest**: A large number of related apps suggests strong market demand for this capability.\n`;
  } else if (result.totalCount >= 5) {
    output += `> **Moderate ecosystem interest**: Several apps address this area, indicating established demand.\n`;
  } else {
    output += `> **Low ecosystem presence**: Few apps in this area — could be an opportunity or a niche capability.\n`;
  }

  output += `\n`;

  for (const app of result.apps) {
    output += `- **${app.title}** by ${app.publisher}`;
    if (app.rating) output += ` (${app.rating} stars)`;
    output += `\n`;
  }

  return output;
}
