# Agent Test Library

Test helpers for authoring AI agent tests in Business Central. The library provides helper methods to create and manage agent tasks, messages, and user interventions, drive YAML-described turn loops via `Library - Agent.RunTurnAndWait` / `FinalizeTurn`, and integrate with the AI Test Toolkit for evaluation.

The library can also create tenant-scoped Business IQ test domains and active skills. Use `EnsureBusinessIQDomain` followed by `CreateActiveBusinessIQSkill`, and call `DeleteBusinessIQTestDomain` when switching test modes or cleaning up. Cleanup is tenant-wide for the specified domain code, so tests must use dedicated domain codes.

The BCApps library does not depend on a Business IQ app. These methods publish JSON-based `OnGetIQ` and `OnSaveIQ` integration events. Internal test apps can subscribe directly, while non-internal test apps can depend on `Agent Test Internal Library`, which provides a temporary Business IQ event subscriber.

## Public documentation

- [AI-TEST-AUTHORING.md](AI-TEST-AUTHORING.md) — YAML format reference for AI agent tests, the placeholder syntax, and how each YAML key maps to the library methods that consume it.
