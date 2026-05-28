# Agent Test Library

Test helpers for authoring AI agent tests in Business Central. The library provides helper methods to create and manage agent tasks, messages, and user interventions, drive YAML-described turn loops via `Library - Agent.RunTurnAndWait` / `FinalizeTurn`, and integrate with the AI Test Toolkit for evaluation.

## Features

- **Turn-loop driver** — `RunTurnAndWait` + `FinalizeTurn` handle the multi-turn lifecycle from YAML.
- **Intervention validation** — type, suggestions, and semantic intent matching.
- **LLM-as-judge** — when an `intent` key is declared in `intervention_request`, the framework uses GPT-4.1 to semantically evaluate whether the agent's intervention message matches the expected intent. Requires the `Agent Test LLM Judge` Copilot Capability (registered automatically by the library's install codeunit).
- **Dynamic file generation** — `IAgentTestResourceProvider.GenerateResource` for test attachments that must be created at runtime.
- **Placeholder engine** — date/time formula substitution in YAML values.

## Public documentation

- [AI-TEST-AUTHORING.md](AI-TEST-AUTHORING.md) — YAML format reference for AI agent tests, the placeholder syntax, and how each YAML key maps to the library methods that consume it.
