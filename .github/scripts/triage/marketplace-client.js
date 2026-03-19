// Microsoft AppSource marketplace client
// Searches for BC-related apps to gauge ecosystem interest in a capability.
// A high number of related apps indicates general market demand.
//
// Uses the public storefront API that powers appsource.microsoft.com search.

const STOREFRONT_API = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0/search';
const BC_PRODUCT_ID = 'DynBC';
const MAX_RESULTS = 5;

/**
 * Search the AppSource marketplace for BC apps related to the given keywords.
 * Returns the total count of matching apps and top results.
 */
export async function fetchMarketplaceApps(keywords) {
  if (!keywords || keywords.length === 0) {
    return { apps: [], totalCount: 0, searchTerms: '' };
  }

  // Use top 3 most specific keywords for search
  const searchTerms = keywords.slice(0, 3).join(' ');
  console.log(`AppSource: searching for "${searchTerms}"...`);

  try {
    const requestBody = {
      Query: searchTerms,
      Top: MAX_RESULTS,
      Skip: 0,
      Market: 'US',
      Language: 'EN',
      Filters: {
        ProductType: ['DynBC'],
      },
      OrderBy: ['Relevance'],
    };

    const response = await fetch(STOREFRONT_API, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(requestBody),
      signal: AbortSignal.timeout(15000),
    });

    if (!response.ok) {
      console.warn(`AppSource: storefront API returned ${response.status}`);
      // Try the legacy GET endpoint as fallback
      return await fetchViaGetEndpoint(searchTerms);
    }

    const data = await response.json();
    const results = data.Results || data.results || [];
    const totalCount = data.TotalCount || data.totalCount || results.length;

    const apps = results.slice(0, MAX_RESULTS).map(item => {
      const app = item.Product || item;
      return {
        title: app.Title || app.DisplayName || app.title || '(untitled)',
        publisher: app.PublisherName || app.PublisherDisplayName || app.publisher || 'Unknown',
        rating: app.AverageRating || app.Rating || null,
        url: app.DetailUrl || `https://appsource.microsoft.com/en-us/product/dynamics-365-business-central/${app.Id || app.id || ''}`,
      };
    });

    console.log(`AppSource: found ${totalCount} related apps`);
    return { apps, totalCount, searchTerms };

  } catch (err) {
    console.warn(`AppSource: search failed — ${err.message}`);
    return await fetchViaGetEndpoint(searchTerms);
  }
}

/**
 * Fallback: try the legacy GET search endpoint.
 */
async function fetchViaGetEndpoint(searchTerms) {
  try {
    const params = new URLSearchParams({
      q: searchTerms,
      product: 'dynamics-365-business-central',
      top: String(MAX_RESULTS),
    });

    const response = await fetch(`https://appsource.microsoft.com/api/search?${params}`, {
      headers: { 'Accept': 'application/json' },
      signal: AbortSignal.timeout(10000),
    });

    if (!response.ok) {
      console.warn(`AppSource: GET fallback returned ${response.status}`);
      return buildSearchUrlResult(searchTerms);
    }

    const data = await response.json();
    const results = data.apps || data.results || data.Results || [];
    const totalCount = data.totalCount || data.TotalCount || data.total || results.length;

    if (results.length === 0) {
      return buildSearchUrlResult(searchTerms);
    }

    const apps = results.slice(0, MAX_RESULTS).map(app => ({
      title: app.title || app.Title || app.DisplayName || '(untitled)',
      publisher: app.publisher || app.PublisherName || 'Unknown',
      rating: app.rating || app.AverageRating || null,
      url: `https://appsource.microsoft.com/en-us/product/dynamics-365-business-central/${app.id || app.Id || ''}`,
    }));

    console.log(`AppSource (GET fallback): found ${totalCount} related apps`);
    return { apps, totalCount, searchTerms };

  } catch (err) {
    console.warn(`AppSource: GET fallback failed — ${err.message}`);
    return buildSearchUrlResult(searchTerms);
  }
}

/**
 * Last resort: return a search URL for the LLM to reference.
 */
function buildSearchUrlResult(searchTerms) {
  const searchUrl = `https://appsource.microsoft.com/en-us/marketplace/apps?product=dynamics-365%3Bdynamics-365-business-central&search=${encodeURIComponent(searchTerms)}`;
  console.log(`AppSource: all API attempts failed, providing search URL`);
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
    return `### AppSource Marketplace\n\nCould not query AppSource directly. The model should search its knowledge for known BC apps related to "${result.searchTerms}" and estimate ecosystem interest.\n\nManual search: [AppSource](${result.searchUrl})\n`;
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
