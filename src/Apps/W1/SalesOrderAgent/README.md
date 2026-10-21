# Sales Order Agent

## Business IQ

**Use Business IQ** in the final **Business IQ** card of **Configure Sales Order
Agent** controls each agent instance independently. It is off by default,
including for agents created before this setting was introduced. Choose **Update**
to apply a change.

- **Off** uses the self-contained standard Sales Order Agent instructions and
  disables the runtime's Business IQ tools for this agent.
- **On** uses the skill-based instructions, creates or refreshes the packaged
  business skills, and enables Business IQ tools for this agent. The main
  instructions contain the agent's role, communication guidelines, and an
  ordered high-level workflow. Each stage asks Business IQ for detailed
  instructions from its corresponding skill, in this order:
  **Find Requested Items**, **Create and Populate Sales Quote**, and
  **Convert Quote to Sales Order**.
  Organization-wide Azure OpenAI privacy approval is required when enabling this
  option.

The packaged Business IQ skills follow the default SOA workflow: no inventory
availability checks or capable-to-promise, send the quote for customer
acceptance, then convert the accepted quote and send the order confirmation.
They do not request additional quote/order document reviews. Change workflow
instructions in the skills rather than adding setup-dependent prompt branches.

Required skill lookups must succeed before the agent performs the business
operation. A failed Business IQ lookup requires assistance, not a guessed
workflow. Quote and order skills each require a successful **Download as PDF**
action and the returned file ID in the outgoing message attachments. After a
document changes, its PDF must be downloaded again before sending.

SOA setup fields remain visible in both modes. Native item-search filtering,
availability information, and capable-to-promise calculations continue to use
the existing SOA setup values, including when Business IQ is enabled. Enabling
Business IQ does not override those values or introduce different native
configuration behavior.

Email signature, mailbox, message-review, runtime permissions, and privacy
settings still apply. Updating the option also refreshes instructions when the
agent is disabled. Use a new task to compare modes without retained instructions
or task memory from an earlier run.

The standard instructions are packaged in
`app/.resources/Prompts/SalesOrderAgent-StandardInstructions.json`; the Business IQ
instructions remain in
`app/.resources/Prompts/SalesOrderAgent-AgentInstructions.json`. The standard
resource matches the monolithic `SalesOrderAgent-AgentInstructions.json` on
`main`. Keep Business IQ workflow changes in `app/.resources/Prompts/Skills/`
rather than adding setup-dependent branches to the main instructions.

Refreshing skills also deactivates the five superseded helper skills when their
titles and descriptions still match the old packaged metadata. Their records,
history, and company/domain links are retained; unrelated skills are not removed.

Business IQ remains an extension dependency in both modes. Turning this option
off does not uninstall Business IQ, remove shared business skills, or affect
another agent's setting.

## Default permissions

New Sales Order Agent instances default to the built-in **SUPER** permission set
in the company where they are created, in both instruction modes. This grants
administrator-level access in that company rather than restricting new skill
procedures to **SOA - Edit**. Existing agents keep their assigned permission sets;
this default does not update them or grant access to other companies.

Task execution still uses permissions shared by the agent and the task
creator/approver. Licensing and runtime/tool restrictions still apply. SUPER
does not make unsupported actions available or resolve Business IQ service
connection errors.

## Item descriptions and variants

Both modes use item-search variant metadata rather than descriptive words alone
to decide whether a request is variant-specific. For an otherwise matching item
with an empty `Variants` array, characteristics such as color or size remain part
of the item description and do not require a Variant Code. Items with actual
variants retain their existing matching and substitution-safety rules.
