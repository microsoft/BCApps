# Sales Order Agent

## Business Skills

**Use Business Skills** in the final **Business Skills** card of **Configure Sales Order
Agent** controls each agent instance independently. It is off by default,
including for agents created before this setting was introduced. Choose **Update**
to apply a change.

Turning the option on shows a notification explaining the instruction change,
with an **Open Business Skills** link. Turning it off again dismisses the notice;
choose **Update** to save the mode change.

- **Off** uses the self-contained standard Sales Order Agent instructions and
  disables the runtime's Business Skills tools for this agent.
- **On** uses the skill-based instructions, creates or refreshes the packaged
  business skills, and enables Business Skills tools for this agent. The main
  instructions own configuration, authorization, review, and sending rules.
  Skills expose titles and descriptions for discovery and provide reusable
  procedures without interpreting SOA configuration.
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

Packaged skills use the System Application Business Skills API and are
tenant-wide, not company-scoped. Registration matches the owning SOA app and
resource path, never the title. Refreshes update metadata in place and advance
the content version only when the skill instructions change.

Applying setup with Business Skills enabled creates or refreshes the packaged
skills from the published app, even when the agent is disabled. Email retrieval
also refreshes them when an instruction sync is due, normally after 30 minutes.
Changes to local source files take effect only after the app is built and
published.

The underlying skills extension remains a dependency in both modes. Turning this
option off does not uninstall it, remove shared business skills, or affect another
agent's setting.

## Item descriptions and variants

Both modes use item-search variant metadata rather than descriptive words alone
to decide whether a request is variant-specific. For an otherwise matching item
with an empty `Variants` array, characteristics such as color or size remain part
of the item description and do not require a Variant Code. Items with actual
variants retain their existing matching and substitution-safety rules.
