# Configuration Module - AI Context

The Configuration module defines the **data-driven rules** that control what inspections look like and when they're created.

## Sub-modules

```
Configuration/
├── GenerationRule/   When to create inspections (trigger conditions, templates, scheduling)
│   └── JobQueue/     Scheduled inspection creation via job queue
├── Template/         What to ask (inspection structure, test definitions)
│   └── Test/         Test definitions and lookup values
├── SourceConfiguration/  How to populate inspection from source record fields
└── Result/           What result options exist and what happens when selected
```

## Quick Reference

| Task | File |
|---|---|
| Add/modify when inspections trigger | `GenerationRule/QltyInspectionGenRule.Table.al` + `QltyInspecGenRuleMgmt.Codeunit.al` |
| Add/modify inspection template structure | `Template/QltyInspectionTemplateHdr.Table.al` + `QltyInspectionTemplateLine.Table.al` |
| Add test definitions | `Template/Test/QltyTest.Table.al` |
| Map source fields to inspection header | `SourceConfiguration/QltyInspectSourceConfig.Table.al` + `QltyTraversal.Codeunit.al` |
| Configure result behaviors | `Result/QltyInspectionResult.Table.al` + `QltyIResultConditConf.Table.al` |
| Schedule inspections | `GenerationRule/JobQueue/QltyJobQueueManagement.Codeunit.al` |
| Auto-configure common sources | `QltyAutoConfigure.Codeunit.al` |

## Relevant Docs
- `docs/architecture.md` - How configuration layers relate to inspection creation
- `docs/data-model.md` - Full table details for all configuration tables
- `src/Document/docs/` - How inspection creation consumes configuration
