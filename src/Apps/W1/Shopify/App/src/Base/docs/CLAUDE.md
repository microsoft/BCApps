# Shopify Connector -- Base module

Core configuration, communication, and synchronization orchestration layer for the Shopify Connector. This module owns the central `Shpfy Shop` table, the singleton HTTP/GraphQL communication hub, and the background sync scheduling infrastructure.

## Quick reference

- **Tech stack**: AL (Business Central), Shopify Admin GraphQL API (version 2026-01)
- **Entry point(s)**: `ShpfyShopCard.Page.al` (shop configuration), `ShpfyConnectorGuide.Page.al` (assisted setup wizard), `ShpfyBackgroundSyncs.Codeunit.al` (sync orchestration)
- **Key patterns**: SingleInstance codeunit for API state, Job Queue for background sync, event subscriber hooks for install/upgrade lifecycle, enum-driven configuration

## Structure

```
Base/
  Codeunits/
    ShpfyCommunicationMgt.Codeunit.al    -- SingleInstance HTTP/GraphQL hub
    ShpfyBackgroundSyncs.Codeunit.al     -- Job Queue sync orchestration
    ShpfyCommunicationEvents.Codeunit.al -- Internal events for test mocking
    ShpfyGuidedExperience.Codeunit.al    -- Checklist and assisted setup registration
    ShpfyInitialImport.Codeunit.al       -- First-run import scheduler
    ShpfyInstaller.Codeunit.al           -- Install trigger, retention policies, cue setup
    ShpfyShopMgt.Codeunit.al             -- API version notifications
    ShpfyShopReview.Codeunit.al          -- Shop review logic
    ShpfyUpgradeMgt.Codeunit.al          -- Upgrade triggers
    ShpfyFilterMgt.Codeunit.al           -- Filter helpers
    ShpfyChecklistItemList.Codeunit.al   -- Checklist item list
    CompanyDetailsChecklistItem.Codeunit.al
  Enums/
    ShpfySynchronizationType.Enum.al     -- Products, Orders, Customers, Companies
    ShpfyLoggingMode.Enum.al             -- Error Only, All, Disabled
    ShpfyImportAction.Enum.al            -- New, Update
    ShpfyMappingDirection.Enum.al        -- ShopifyToBC, BCToShopify
    ShpfyReturnLocationPriority.Enum.al  -- Default vs Original->Default
    ShpfyWeightUnit.Enum.al              -- Grams, Kilograms, Ounces, Pounds
  Tables/
    ShpfyShop.Table.al                   -- Central config entity (~130 fields)
    ShpfySynchronizationInfo.Table.al    -- Last sync timestamps per shop/type
    ShpfyTag.Table.al                    -- Shopify tags
    ShpfyCue.Table.al                    -- Role Center cue data
    ShpfyInitialImportLine.Table.al      -- Initial import job tracking
    ShpfyTemplatesWarnings.Table.al      -- Template warnings
  Pages/
    ShpfyShopCard.Page.al                -- Main shop configuration card
    ShpfyConnectorGuide.Page.al          -- Assisted setup wizard (NavigatePage)
    ShpfyShops.Page.al                   -- Shop list
    ShpfyActivities.Page.al              -- Role Center activities
    ShpfyInitialImport.Page.al           -- Initial import status page
    ShpfyShopSelection.Page.al           -- Shop picker
    ShpfyTags.Page.al / ShpfyTagFactbox.Page.al
  Enum Extensions/
  Page Extensions/
  Reports/
  Table Extensions/
```

## Documentation

- [docs/architecture.md](docs/architecture.md) -- Design decisions, data flow, and key patterns

## Key concepts

- `Shpfy Shop` (table 30102) is the central configuration entity; every sync operation starts by loading a shop record
- `Shpfy Communication Mgt.` (codeunit 30103) is a `SingleInstance` codeunit that holds the active shop context and executes all Shopify API calls
- Background syncs are dispatched via `Job Queue Entry` records with the `SHPFY` category code
- The connector guide (`ShpfyConnectorGuide`) walks users through OAuth, data import choices, and template selection in a multi-step wizard
- 12 event subscribers across 4 codeunits handle install, upgrade, company copy, environment cleanup, and job queue lifecycle
- Sync timestamps are tracked per shop and sync type in `Shpfy Synchronization Info`
- API version lifecycle is enforced at runtime via Azure Key Vault expiry dates with user-facing notifications
