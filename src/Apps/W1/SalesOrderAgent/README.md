# Sales Order Agent

## Business Skills

**Use Business Skills** in the final **Business Skills** card of **Configure Sales Order
Agent** controls each agent instance independently. It is off by default,
including for agents created before this setting was introduced. Choose **Update**
to apply a change.

- **Off** uses the self-contained standard Sales Order Agent instructions and
  disables the runtime's Business Skills tools for this agent.
- **On** uses the skill-based instructions, creates or refreshes the packaged
  business skills, and enables Business Skills tools for this agent. Each workflow
  step specifies the skill to retrieve by name in natural language. Missing
  skills and failed or incomplete lookups require assistance rather than a
  different skill or a general-knowledge fallback.
  Organization-wide Azure OpenAI privacy approval is required when enabling this
  option.

Both modes retain the configured availability, capable-to-promise, quote/order
review, quote confirmation, and email signature settings. Updating the option
also refreshes instructions when the agent is disabled. Use a new task to compare
the modes without retained instructions or task memory from an earlier run.

The standard instructions are packaged in
`app/.resources/Prompts/SalesOrderAgent-StandardInstructions.json`; the Business Skills
instructions remain in
`app/.resources/Prompts/SalesOrderAgent-AgentInstructions.json`. Changes to common
workflow behavior must be reflected in both resources.

The underlying skills extension remains a dependency in both modes. Turning this
option off does not uninstall it, remove shared business skills, or affect another
agent's setting.

## Item descriptions and variants

Both modes use item-search variant metadata rather than descriptive words alone
to decide whether a request is variant-specific. For an otherwise matching item
with an empty `Variants` array, characteristics such as color or size remain part
of the item description and do not require a Variant Code. Items with actual
variants retain their existing matching and substitution-safety rules.
