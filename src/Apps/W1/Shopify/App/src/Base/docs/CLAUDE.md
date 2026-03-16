# Base

Part of [Shopify Connector](../../CLAUDE.md).

Core infrastructure for the Shopify Connector, including shop configuration, synchronization tracking, tag management, and shared utilities.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Shop (30102) | Central shop configuration and settings |
| Table | Shpfy Synchronization Info (30103) | Tracks last sync time per sync type |
| Table | Shpfy Tag (30104) | Stores tags for products, customers, orders |
| Table | Shpfy Initial Import Line (30137) | Guided initial import workflow |
| Table | Shpfy Cue (30138) | Activity cue counts for role center |
| Codeunit | Shpfy Communication Mgt. (30100) | HTTP communication and GraphQL requests |
| Codeunit | Shpfy Shop Mgt. (30101) | Shop management operations |
| Codeunit | Shpfy Installer (30102) | App installation and upgrade |
| Codeunit | Shpfy Filter Mgt. (30103) | Filter parsing and manipulation |
| Codeunit | Shpfy Initial Import (30104) | Initial data import orchestration |
| Codeunit | Shpfy Background Syncs (30105) | Background job queue sync tasks |
| Codeunit | Shpfy Guided Experience (30106) | Assisted setup and onboarding |
| Codeunit | Shpfy Upgrade Mgt. (30107) | Upgrade code for schema changes |
| Codeunit | Shpfy Communication Events (30108) | Event publishers for HTTP/GraphQL |
| Enum | Shpfy Synchronization Type (30100) | Products, Customers, Orders, etc. |
| Enum | Shpfy Logging Mode (30101) | Disabled, Error Only, Verbose |
| Enum | Shpfy Mapping Direction (30102) | ShopifyToBC, BCToShopify |
| Enum | Shpfy Import Action (30103) | Create, Update, Skip |
| Page | Shpfy Shops (30100) | Shop list page |
| Page | Shpfy Shop Card (30101) | Shop configuration card |
| Page | Shpfy Tags (30102) | Tag list page |
| Page | Shpfy Activities (30103) | Activity page for role center |

## Key concepts

- Shop as central configuration: Shpfy Shop table stores all settings for a Shopify store connection
- Multi-shop support: Single BC environment can connect to multiple Shopify shops
- Synchronization tracking: Shpfy Synchronization Info records last sync timestamp for each sync type (Products, Customers, Orders, etc.)
- Tag management: Shpfy Tag table stores tags for multiple entity types (products, customers, orders) using Parent Table No. and Parent Id
- Initial import workflow: Shpfy Initial Import Line tracks import jobs for guided setup
- Communication abstraction: Shpfy Communication Mgt. handles all HTTP/GraphQL communication with Shopify API
- Logging modes: Configurable logging (Disabled, Error Only, Verbose) for troubleshooting
- Background jobs: Shpfy Background Syncs creates job queue entries for automated sync
