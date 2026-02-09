# GitHub Copilot Agents

This directory contains GitHub Copilot agent definitions for the BCApps repository. These agents provide specialized, automated assistance for common repository tasks.

## What Are GitHub Copilot Agents?

GitHub Copilot agents are structured instruction files (`.agent.md`) that tell GitHub Copilot how to perform specific tasks in your repository. They act as domain experts, equipped with:

- Knowledge about your codebase structure
- Understanding of your build system and workflows
- Guidelines for performing tasks safely and correctly
- Context about common patterns and practices

## Available Agents

### Version Change Agent
**File:** `EngSys-VersionChange.agent.md`

Updates version numbers across the repository:
- Updates all `app.json` files with specified version
- Updates `repoVersion` in `.github/AL-Go-Settings.json`
- Handles dependency version updates

**Usage:**
```
@github-copilot Please update the versions from 28.0.0.0 to 29.0.0.0
```

### Build-Fix Agent
**File:** `BuildFix.agent.md`

Automates the build-fix cycle for pull requests:
- Triggers AL-Go builds using GitHub Actions workflows
- Parses build errors from SARIF logs
- Generates fixes for common error types
- Iterates until build passes (max 3 attempts)

**Usage:**
```
@github-copilot build and fix any errors
@github-copilot fix the build errors in this PR
```

## Agent File Format

Agent files use a YAML front matter + Markdown structure:

```markdown
---
name: Agent Name
description: Brief description of what the agent does
model: GPT-4.1 (copilot)
argument-hint: "Example invocation command"
---

# Agent Instructions

## Purpose
Detailed explanation of the agent's purpose...

## Tasks to Perform
Step-by-step instructions...

## Implementation Guidelines
How to perform the tasks safely and correctly...

## Example Usage
Examples of how to invoke the agent...
```

### Front Matter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name of the agent |
| `description` | Yes | Brief description (shown in agent list) |
| `model` | Yes | Model to use (typically "GPT-4.1 (copilot)") |
| `argument-hint` | Yes | Example of how to invoke the agent |

### Instruction Content

The Markdown content should include:

1. **Purpose**: What the agent does and why it exists
2. **Context**: Background knowledge about the repository/system
3. **Tasks**: Clear, actionable steps the agent should perform
4. **Guidelines**: How to perform tasks safely (error handling, validation)
5. **Examples**: Sample invocations and expected outcomes
6. **Limitations**: What the agent can't or shouldn't do

## How Agents Work

### Execution Flow

```mermaid
graph LR
    A[Developer invokes agent] --> B[GitHub Copilot reads .agent.md]
    B --> C[Agent executes instructions]
    C --> D[Uses available tools]
    D --> E[Reports results]
```

1. **Invocation**: Developer mentions `@github-copilot` with a command in a PR/issue
2. **Agent Selection**: GitHub Copilot matches the command to an agent
3. **Context Loading**: Agent instructions from `.agent.md` are loaded
4. **Execution**: Agent follows instructions using available tools
5. **Results**: Agent reports what it did and any issues

### Execution Environment

Agents run in GitHub Copilot's execution environment, which provides:

- **Linux environment** (bash shell)
- **Git** (for repository operations)
- **GitHub CLI** (`gh` command)
- **Standard utilities** (jq, curl, find, etc.)
- **File system access** (read/write repository files)
- **Network access** (GitHub API, external URLs)

**Important:** Agents cannot directly execute repository-specific scripts that require special environments (e.g., PowerShell scripts, Windows-only tools). Instead, agents should:
- Trigger GitHub Actions workflows
- Use platform-agnostic tools
- Parse outputs from workflow runs

### Tool Usage

Agents can use these tools:

| Tool | Purpose |
|------|---------|
| `git` | Clone, branch, commit, push |
| `gh` | GitHub API, workflow triggers, artifact downloads |
| File I/O | Read/write repository files |
| `jq` | Parse JSON |
| `curl` | HTTP requests |
| Scripting | bash, Python, Node.js |

## Creating a New Agent

### Step 1: Identify the Task

Determine:
- What repository task needs automation?
- Is it repetitive and well-defined?
- Can it be performed safely by an automated agent?
- What knowledge does the agent need?

**Good candidates:**
- Version updates
- Build validation and fixing
- Code formatting
- Dependency updates
- File generation from templates

**Poor candidates:**
- Complex architectural decisions
- Security-sensitive operations
- Tasks requiring human judgment

### Step 2: Gather Context

Document what the agent needs to know:
- Repository structure
- Build system architecture
- Workflow triggers and execution
- File formats and locations
- Common patterns and practices
- Safety constraints

### Step 3: Write the Agent File

Create `.github/agents/YourAgent.agent.md`:

```markdown
---
name: Your Agent Name
description: What your agent does
model: GPT-4.1 (copilot)
argument-hint: "Example command"
---

# Your Agent Instructions

## Purpose
Clear statement of what this agent does and why.

## Context
Background knowledge the agent needs:
- Repository structure
- Build system details
- Dependencies and constraints

## Tasks to Perform
Step-by-step instructions:
1. First, do this...
2. Then, do that...
3. Finally, verify...

## Implementation Guidelines
How to perform tasks safely:
- Validation steps
- Error handling
- Rollback strategies

## Safety Guidelines
What NOT to do:
- Don't modify protected branches
- Don't skip validation
- Don't introduce breaking changes

## Example Usage
Show how to invoke the agent and what to expect.
```

### Step 4: Test the Agent

1. Create a test PR or issue
2. Invoke the agent with various commands
3. Verify it follows instructions correctly
4. Test error handling and edge cases
5. Check that safety guidelines are respected

### Step 5: Document and Deploy

1. Add agent to this README
2. Document usage examples
3. Note any limitations
4. Deploy by committing to main branch

## Best Practices

### Writing Clear Instructions

✅ **Do:**
- Use clear, imperative language ("Read the file", "Update the version")
- Provide specific file paths and patterns
- Include error handling instructions
- Show examples of expected inputs/outputs
- Explain the "why" behind each step

❌ **Don't:**
- Use vague language ("maybe check", "if possible")
- Assume agent knows implicit context
- Skip validation steps
- Omit error handling
- Forget to document limitations

### Safety First

Always include safety guidelines:

```markdown
## Safety Guidelines

1. **Before making changes:**
   - Verify git working directory is clean
   - Confirm we're not on a protected branch (main, releases/*)
   - Validate inputs are in expected format

2. **During changes:**
   - Make atomic commits
   - Validate after each change
   - Preserve existing functionality

3. **After changes:**
   - Run validation checks
   - Report what was changed
   - Provide rollback instructions if needed
```

### Error Handling

Provide clear error handling instructions:

```markdown
## Error Handling

If [specific error] occurs:
1. Check [condition]
2. If [condition], then [action]
3. Otherwise, [fallback action]
4. Report error to user with [details]

Never silently ignore errors or continue with invalid state.
```

### Testing and Validation

Include validation steps in agent instructions:

```markdown
## Validation

After completing the task:
1. ✅ Verify all modified files are valid (syntax check)
2. ✅ Confirm expected changes were made
3. ✅ Check no unintended side effects
4. ✅ Run relevant tests if available
```

## Troubleshooting

### Agent Not Responding

**Possible causes:**
- Command doesn't match agent's `argument-hint`
- Agent file has syntax errors in front matter
- GitHub Copilot can't access the file

**Solutions:**
1. Check front matter is valid YAML
2. Verify file is in `.github/agents/` directory
3. Try explicit invocation: `@github-copilot use BuildFix agent to fix errors`

### Agent Does Wrong Thing

**Possible causes:**
- Instructions are ambiguous
- Missing context about constraints
- Error handling not specified

**Solutions:**
1. Review agent instructions for clarity
2. Add more specific guidelines
3. Include examples of edge cases
4. Test with various inputs

### Agent Causes Errors

**Possible causes:**
- Missing validation steps
- Inadequate error handling
- Safety checks not enforced

**Solutions:**
1. Add pre-flight validation checks
2. Include rollback instructions
3. Test in safe environment first
4. Add defensive programming checks

## Contributing

To contribute a new agent or improve existing ones:

1. **Propose the agent**: Open an issue describing the task and approach
2. **Create the agent file**: Follow the format and best practices above
3. **Test thoroughly**: Verify it works in various scenarios
4. **Document**: Update this README with usage examples
5. **Submit PR**: Include agent file and documentation updates

### Agent Review Checklist

Before submitting an agent:

- [ ] Front matter is valid YAML
- [ ] Instructions are clear and specific
- [ ] Context includes necessary background knowledge
- [ ] Safety guidelines are included
- [ ] Error handling is specified
- [ ] Validation steps are included
- [ ] Examples show expected usage
- [ ] Limitations are documented
- [ ] Tested with various inputs
- [ ] README updated with agent description

## Examples

### Simple Agent Example

For a simple file formatting agent:

```markdown
---
name: Format JSON Agent
description: Formats all JSON files in the repository
model: GPT-4.1 (copilot)
argument-hint: "Please format all JSON files"
---

# Format JSON Agent

## Purpose
Formats all JSON files in the repository with consistent indentation.

## Tasks
1. Find all `*.json` files: `find . -name "*.json" -type f`
2. For each file:
   - Read content
   - Parse JSON to validate
   - Reformat with 2-space indentation
   - Write back to file
3. Commit changes: `git commit -m "Format JSON files"`

## Validation
- Ensure all files are valid JSON after formatting
- Check no files were corrupted
```

### Complex Agent Example

For a complex multi-step agent, see `BuildFix.agent.md` which includes:
- Extensive context about build system
- Multi-iteration logic
- Error parsing from artifacts
- Safety constraints
- Rollback strategies

## Resources

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [AL-Go Framework](https://github.com/microsoft/AL-Go)
- [BCApps Build System](../../build/README.md)

## Support

For questions or issues with agents:

1. Check agent instructions for troubleshooting section
2. Review workflow run logs in GitHub Actions
3. Open an issue with:
   - Agent name
   - Invocation command
   - Expected vs. actual behavior
   - Any error messages

---

**Note:** Agents are powerful automation tools. Always review their changes before merging to ensure correctness and safety.
