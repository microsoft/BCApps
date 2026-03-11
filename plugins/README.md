# AI-First skills marketplace

24 reusable skills for AI-first development workflows, available in [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) and [Claude Code](https://code.claude.com/docs/en/plugin-marketplaces).

## Quick start

### Add the marketplace

```
/plugin marketplace add .
```

### Browse available skills

```
/plugin marketplace browse ai-first-skills
```

### Install a specific plugin

```
/plugin install workflow@ai-first-skills
```

### Install all plugins

```
/plugin install document-review@ai-first-skills
/plugin install architecture@ai-first-skills
/plugin install engineering@ai-first-skills
/plugin install product@ai-first-skills
/plugin install utility@ai-first-skills
/plugin install workflow@ai-first-skills
```

### Use the skills

Once installed, invoke skills with `/skill-name`:

```
/prd                    # Start PRD workflow
/prd design             # Create design doc only
/prd tasks              # Generate tasks from design
/prd implement          # Execute tasks step-by-step

/review                 # Critical document analysis
/summarize              # Document summarization
/architect              # System architecture docs
/code-review            # Root-cause code review
```

## Available plugins

### workflow (1 skill)

Complete product requirements workflow from design to implementation.

| Skill | Command | Description |
|-------|---------|-------------|
| PRD | `/prd` | Design, tasks, and implementation workflow |

### document-review (8 skills)

Comprehensive document analysis and review tools.

| Skill | Command | Description |
|-------|---------|-------------|
| Critical Review | `/review` | Comprehensive critical assessment |
| Summarize | `/summarize` | Document summarization |
| Argument Analysis | `/review-argument` | Evaluate argument structure and logic |
| Fact Check | `/review-fact-check` | Verify factual claims and credibility |
| Sentiment | `/review-sentiment` | Analyze emotional tone with evidence |
| Decomposition | `/review-decomposition` | Evaluate problem breakdown and MECE coverage |
| Structure | `/review-structure` | Document organization analysis |
| Persuasive | `/review-persuasive` | Identify persuasion techniques |

### architecture (2 skills)

System and backend architecture design.

| Skill | Command | Description |
|-------|---------|-------------|
| Architect | `/architect` | System architecture with Mermaid diagrams |
| Backend | `/backend-architect` | Backend system design and cloud infrastructure |

### engineering (3 skills)

Engineering and security tools.

| Skill | Command | Description |
|-------|---------|-------------|
| AI Engineer | `/ai-engineer` | AI/ML implementation, LLM integration, and RAG systems |
| Code Review | `/code-review` | Root-cause focused code review |
| SecOps | `/secops` | Threat detection, vulnerability analysis, and compliance |

### product (3 skills)

Product management and team tools.

| Skill | Command | Description |
|-------|---------|-------------|
| Feedback | `/feedback` | User feedback synthesis across channels |
| Sprint | `/sprint` | Sprint planning and backlog prioritization |
| Split Work | `/split-work` | Parallel work distribution for teams |

### utility (7 skills)

General-purpose utilities.

| Skill | Command | Description |
|-------|---------|-------------|
| Decompose | `/decompose` | Hypothesis-driven problem decomposition |
| Tone/Style | `/tone-style` | Writing tone and style analysis |
| API Test | `/api-test` | API functional, security, and performance testing |
| Perf Test | `/perf-test` | Performance benchmarking and load testing |
| Exec Summary | `/exec-summary` | McKinsey-style executive summaries |
| Sync Marketplace | `/sync-marketplace` | Sync marketplace manifests from disk |

## Directory structure

```
ai-first/
├── .github/plugin/
│   └── marketplace.json            # Copilot CLI marketplace catalog
├── .claude-plugin/
│   └── marketplace.json            # Claude Code marketplace catalog
├── plugins/
│   ├── workflow/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── skills/
│   │       └── prd/
│   │           ├── SKILL.md
│   │           ├── prd-design.md
│   │           ├── prd-tasks.md
│   │           └── prd-implement.md
│   ├── document-review/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── skills/
│   │       ├── review/SKILL.md
│   │       ├── summarize/SKILL.md
│   │       └── ...
│   ├── architecture/
│   ├── engineering/
│   ├── product/
│   └── utility/
└── README.md
```

## Updating

To update to the latest version:

```
/plugin marketplace update ai-first-skills
```

## Contributing

Skills are defined in `plugins/[plugin-name]/skills/[skill-name]/SKILL.md`.

### SKILL.md format

```markdown
---
name: skill-name
description: Brief description shown in skill listings
---

Your skill prompt here. This is what the agent receives when the skill is invoked.
```

### Adding a new skill

1. Create the skill directory: `plugins/[plugin-name]/skills/[skill-name]/`
2. Create `SKILL.md` with frontmatter and prompt content
3. Update `plugins/[plugin-name]/.claude-plugin/plugin.json` if needed
4. Test locally with `/plugin marketplace add .`

### Adding a new plugin

1. Create plugin directory: `plugins/[plugin-name]/`
2. Create `.claude-plugin/plugin.json`:

   ```json
   {
     "name": "plugin-name",
     "description": "What this plugin does",
     "version": "1.0.0"
   }
   ```

3. Add skills in `skills/[skill-name]/SKILL.md`
4. Add the plugin to the marketplace manifests

For more details, see the [Agent Skills documentation](https://docs.github.com/copilot/concepts/agents/about-agent-skills).
