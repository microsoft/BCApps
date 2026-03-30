# Shopify External URL

Open-source extension for the Business Central Shopify Connector that syncs external product page URLs to Shopify as variant metafields (`namespace: shopify`, `key: external_url`).

## Background

Shopify's [Agentic Plan](https://www.shopify.com/agentic-plan) enables merchants to sell through AI assistants (ChatGPT, Google AI Mode, Gemini, Microsoft Copilot) without migrating their commerce platform. The `external_url` variant metafield is a required field that provides a fallback link to the merchant's own product detail page where customers can complete purchases.

## How it works

1. Configure a **Product URL Template** on the Shopify Shop Card (under Item Synchronization)
2. During product sync, the extension subscribes to the product export flow and creates an `external_url` metafield on each variant
3. The URL is resolved from the template using placeholder substitution, or from a per-variant override

## URL Template Placeholders

| Placeholder | Value |
|-------------|-------|
| `{item-no}` | BC Item No. |
| `{variant-code}` | BC Item Variant Code |
| `{sku}` | Shopify Variant SKU |
| `{barcode}` | Shopify Variant Barcode |
| `{shopify-product-id}` | Shopify Product ID |
| `{shopify-variant-id}` | Shopify Variant ID |

**Example:** `https://mywebshop.com/products/{item-no}?variant={variant-code}`

> The template must start with `https://` or `http://`. Shopify rejects URLs without a scheme.

## Per-variant override

You can set a specific URL per variant on the Shopify Variants page. When set, it takes priority over the template.

## Installation

This is a PTE (Per-Tenant Extension). Compile against the Shopify Connector symbols and publish to your environment.
