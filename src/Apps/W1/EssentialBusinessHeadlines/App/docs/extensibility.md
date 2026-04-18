# Extensibility Guide

The Essential Business Headlines app provides an open framework for displaying contextual insights on Business Central role center pages. This guide describes the integration events and patterns for extending headlines with custom data.

## Integration Events Published

The app publishes events on page extensions to control headline visibility and content. These events allow subscribers to inject custom headline text and visibility logic.

### Business Manager Role Center

**HeadlinesRCBusMgrExt** publishes:

- `OnSetVisibility` -- controls 14 headline variables for sales, purchasing, activities, and cash flow insights
- `OnSetVisibilityOpenVATReturn` -- controls open VAT return headline
- `OnSetVisibilityOverdueVATReturn` -- controls overdue VAT return headline

### Accountant Role Center

**HeadlinesRCAccountantExt** publishes:

- `OnSetVisibility` -- controls 6 headline variables for accounting-specific insights

### Order Processor Role Center

**HeadlinesRCOrderProcExt** publishes:

- `OnSetVisibility` -- controls 4 headline variables for order processing insights

### Relationship Manager Role Center

**HeadlinesRCRelMgtExt** publishes:

- `OnSetVisibility` -- controls 2 headline variables for relationship management insights

### Extensibility Stubs

The following page extensions provide minimal stub implementations designed for future extension:

- **HeadlinesRCAdminExt** -- `OnSetVisibility` with 2 generic headline variables
- **HeadlinesRCProjectMgrExt** -- `OnSetVisibility` with 2 generic headline variables
- **HeadlinesRCTeamMemberExt** -- `OnSetVisibility` with 2 generic headline variables

These stubs are deliberately minimal to allow other apps to provide headline content without modifying the base app.

## Event Subscriptions Consumed

The app subscribes to the following events from other apps:

- `RC Headlines Executor.OnComputeHeadlines` -- main computation trigger, routed by RoleCenterPageID. Subscribe here to compute your custom headlines.
- `RC Headlines Page Common.OnIsAnyExtensionHeadlineVisible` -- aggregate visibility check. Only sets true, never false. Subscribe here to report whether your extension has visible headlines.
- `User Settings.OnUpdateUserSettings` -- cache invalidation on language or work date change.
- `Company-Initialize.OnCompanyInitialize` -- install-time privacy classification registration.
- Page visibility events (`OnSetVisibilityXXX`) on each role center page extension.

## Extension Pattern

To add custom headlines to a role center:

1. **Compute headlines** -- Subscribe to `OnComputeHeadlines` from the RC Headlines Executor codeunit. Check the `RoleCenterPageID` parameter to determine which role center is requesting headlines. Compute your headline data and store it in your own table.

2. **Populate visibility and text** -- Subscribe to the relevant page extension's `OnSetVisibility` event. Read your stored headline data and set the appropriate visibility and text variables passed by reference.

3. **Report visibility** -- Subscribe to `OnIsAnyExtensionHeadlineVisible` from the RC Headlines Page Common codeunit. Set the `IsVisible` parameter to true if your extension has any visible headlines for the current role center. Do not set it to false -- the event aggregates visibility across all subscribers.

## Design Philosophy

This is an open framework. The Admin, Project Manager, and Team Member page extensions are deliberately minimal stubs with generic `Headline1Visible`, `Headline1Text`, `Headline2Visible`, and `Headline2Text` variables. These are designed for other apps to extend without requiring changes to the base app.

The framework separates computation (via `OnComputeHeadlines`) from presentation (via `OnSetVisibility`). This allows expensive headline calculations to run once and be reused across multiple page refreshes, while still allowing fine-grained control over what is displayed.
