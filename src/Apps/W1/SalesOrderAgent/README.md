# Sales Order Agent

## Business IQ

**Use Business IQ** in the final **Business IQ** card of **Configure Sales Order
Agent** controls each agent instance independently. It is off by default,
including for agents created before this setting was introduced. Choose **Update**
to apply a change.

- **Off** uses the self-contained standard Sales Order Agent instructions and
  disables the runtime's Business IQ tools for this agent.
- **On** uses the skill-based instructions, creates or refreshes the packaged
  business skills, and enables Business IQ tools for this agent. Each workflow
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
`app/.resources/Prompts/SalesOrderAgent-StandardInstructions.json`; the Business IQ
instructions remain in
`app/.resources/Prompts/SalesOrderAgent-AgentInstructions.json`. Changes to common
workflow behavior must be reflected in both resources.

Business IQ remains an extension dependency in both modes. Turning this option
off does not uninstall Business IQ, remove shared business skills, or affect
another agent's setting.
