# Create a Memory Bank

## Quick Start

Run this prompt in your AI assistant:

```text
init memory bank
```

## Output Structure

The memory bank creates **3 compressed files** (~500 lines total):

| File | Lines | Purpose |
|------|-------|---------|
| context.md | ~150 | Tech stack, constraints, structure |
| patterns.md | ~200 | Architecture, conventions, entities |
| current.md | ~150 | Active work, key files, debt |
| README.md | ~30 | Quick reference |

## For Small Projects (<10k LOC)

Use the quick prompt above. Review and refine as needed.

## For Large Legacy Codebases (>10k LOC)

Run [run-on-brownfield.md](./run-on-brownfield.md) for a structured 3-phase process:

1. **Discovery** - Map structure, count files, identify critical files
2. **Analysis** - Read critical files, extract patterns as tables
3. **Compression** - Write 3 files, validate size targets

**What you get:**
- **3 compressed files** (~500 lines target, ~1400 max) instead of 4,000+
- **Evidence-based** - Every pattern has a file reference
- **Verification** - All claims verifiable by grep/find commands
- **No speculation** - Zero "typically", "usually", "probably"
- **Tables over prose** - Dense, token-efficient format
- **Actionable** - Build commands, naming conventions, entity relationships

**Output requirements:**
- Total ≤ 1400 lines
- Tables over prose
- Code blocks ≤ 15 lines
- Entity relationships as tables (not ASCII trees)
- Every pattern cites a source file

## Compression Principles

| DO | DON'T |
|----|-------|
| Tables for structured data | Prose explanations |
| Pattern templates (≤15 lines) | Full code examples |
| File paths for references | Line number citations |
| Naming convention tables | "Why" explanations |
| Entity relationship tables | ASCII tree diagrams |

## Validation

After creation, verify:
- [ ] Total ≤ 1400 lines
- [ ] Every pattern has a file reference
- [ ] No code blocks over 15 lines
- [ ] Build commands work
- [ ] Zero speculation words (typically, usually, probably)

## Revision

If too verbose:

```text
Compress the memory bank. Replace prose with tables, remove code blocks over 15 lines, remove explanations.
```

If missing detail:

```text
Add [specific pattern/entity] to patterns.md as a table.
```

```text
In `systemPatterns.md`, list all major sections. Starting with the first section and moving through to the end, verify each section and subsection using only what you can confirm in the codebase. Create an evidence-based version grounded in actual code.
```

To zoom in on a single topic:

```text
Update `Resource Scheduling Pattern` using only what you can verify in the codebase. Create an evidence-based version grounded in the actual code.
```

## Validate and critique

To validate the contents, use this prompt:

```text
The memory bank helps developers use LLMs to fix bugs and build features in this codebase. Analyze the current memory bank files to determine what should be added, changed, or removed as unhelpful. Only list findings. Do not edit any files until I tell you to.
```

It will list strengths and suggestions. Work with Copilot to make changes.

You can also ask for a skeptical review:

```text
Review `systemPatterns.md` like a skeptical reviewer. Highlight any claims or assumptions not traceable to code or patterns. Suggest what evidence is needed to validate them.
```

Or identify mismatched patterns:

```text
In `activeContext.md`, list common patterns that do NOT apply to this codebase.
```

If you spot something wrong, ask about the specific area:

```text
Is the `Repository Pattern Implementation` section correct?
```