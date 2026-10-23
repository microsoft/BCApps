# Authoring AI Agent Tests — YAML Reference

AI agent tests evaluate Business Central agent behavior through declarative YAML scenarios. The **AI Test Suite** is the main driver:
it runs each test as a per-turn loop — provide input, run the agent, assert state. **`Library - Agent`** is a helper that structures the YAML input into agent task operations in a reusable way, so individual tests do not have to wire up the agent task framework directly.

You can find a sample test implementation at
[`SalesValidationAgent3P`](https://github.com/microsoft/BCTech/tree/master/samples/BCAgents/SalesValidationAgent/test).

This document is the **input contract** for AI agent tests: the YAML structure and the library methods each key flows into.

What you'll find here:

- The YAML schema (top-level keys, per-test keys, `turn_setup`, `query`, `expected_data`).
- The placeholder syntax (`$Placeholder-…$`, `$DateFormula-…$`, `$DateTimeFormula-…$`).
- For each YAML key that the framework interprets, the library method  that consumes it.
- A quick reference for `Library - Agent`, `AIT Test Context`, and  `Test Input Json`.

---

## 1. File kinds

Two YAML kinds, distinguished by their top-level shape. Conventional locations under your test app's `.resources/`:

| Kind | Convention path | Top-level shape | Required |
|---|---|---|---|
| Suite-setup file | `.resources/suite_setup/<NAME>.yaml` | `name:` scalar + `suite_setup:` **object** + `description:` | optional |
| Test dataset file | `.resources/datasets/<NAME>.yaml` | `suite_setup:` **scalar** (reference) + `tests:` array | required |

A **suite-setup file** is optional. It holds data that needs to be set up only once for the whole suite — typical examples are master records
that every test relies on (locations, customers, posting groups). The framework runs it before the first test and skips it on subsequent
turns; test code gates re-execution via `IsSuiteSetupDone()` /
`SetEvalSuiteSetupCompleted()`.

A **test dataset file** is the per-suite input that the test runner iterates over. It usually references a suite-setup by name but can stand alone if no shared setup is needed.
The framework loads `*.yaml` recursively from `.resources/`, so folder names are convention only.

---

## 2. Top-level keys

| Key | Type | Required | Notes |
|---|---|---|---|
| `name` | scalar | required on setup files | Becomes `Test Input Group."Group Name"`. Other datasets reference a setup by this exact string. |
| `description` | scalar | optional | Free-form. |
| `language` | scalar | optional | Windows language tag (`en-US`, …). Used to pick a language-variant suite-setup. |
| `suite_setup` | scalar **or** object | optional | Scalar = reference to another group's `name:`. Object = inline content (used in setup files only). |
| `tests` | array | required for test datasets | One element per test case. |
| `continue_on_failure` | bool | optional | Per-test flag — if `true`, turn iteration continues after a failed turn. |

---

## 3. Suite-setup file shape

```yaml
name: <MYAGENT>-SETUP                    # required — datasets reference this string
description: Shared master data for the <agent> suite.
suite_setup:                             # OBJECT form = inline content
  setup_actions:
    - action_type: <create_xxx>
      action_data:
        - "<FieldName1>": <value>
          "<FieldName2>": <value>
        - "<FieldName1>": <value>
```

- `suite_setup:` as an **object** means "this is the setup payload".
- Author **one file per language** for localised suites — e.g.  `<MYAGENT>-SETUP.yaml` and `<MYAGENT>-SETUP-FR.yaml`. The same  one-file-per-language convention applies to test dataset files (§4).
- The shape under `suite_setup` (`setup_actions` / `action_type` /  `action_data`) is **convention defined by your test app** — see §6.

---

## 4. Test dataset file shape

```yaml
suite_setup: <MYAGENT>-SETUP             # SCALAR form = reference to a setup group's name
tests:
  - name: <UNIQUE_TEST_CODE>             # required — becomes Test Input "Code"
    description: <one-line summary>
    turns:
      - turn_setup: { ... }              # see §6
        query: { ... }                   # see §7
        expected_data: { ... }           # see §8
      - query: { intervention: { ... } } # continuation turn — see §7.2
        expected_data: { ... }
```

Always use the `turns:` array. For a single-turn test, write a single-element `turns:` list rather than putting `query:` / `expected_data:` directly under the test entry. The multi-turn syntax is the only supported shape.

---

## 5. Per-test keys

| Key | Consumed by | Notes |
|---|---|---|
| `name` | Test Runner | Required. Stored as `TestInput.Code`. |
| `description` | Test Runner | Optional. |
| `turns` | AIT Test Toolkit | Detected via `IsMultiTurn`; turns are 1-indexed. |
| `query` | `Library - Agent` via `AITTestContext.GetQuery()` | One per turn. |
| `expected_data` | Validator + `Library - Agent` (for `intervention_request`) via `AITTestContext.GetExpectedData()` | One per turn. Multi-turn aware: returns the current turn's slice. |
| `turn_setup` | Dispatcher via `AITTestContext.GetTurnSetup(var Found)` | One per turn. |
| `continue_on_failure` | AIT Test Toolkit via `AITTestContext.GetCanContinueOnFailure()` | Per-test boolean. |

---

## 6. `turn_setup` — opaque to the framework

`turn_setup` is **opaque JSON**. The framework hands the entire sub-tree to your test code via:

```al
AITTestContext.GetTurnSetup(var Found: Boolean): Codeunit "Test Input Json"
```

Likewise for the suite-level setup:

```al
AITTestContext.GetEvalSuiteSetupDataInput(): Codeunit "Test Input Json"
```

Your test library walks the JSON and dispatches to handlers. 
**The recommended `setup_actions` / `action_type` / `action_data` shape is identical to the suite-setup convention in 3** — the framework imposes no schema, but using the same shape across both means one dispatcher can drive both suite-level and per-turn data setup.

Example with per-turn data and a nested application-specific block:

```yaml
turn_setup:
  setup_actions:
    - action_type: create_sales_order        # your dispatcher's known type
      action_data:                            # always an array (so one action_type can create N records)
        - "Sell-to Customer No.": SVCUST01
          "Shipping Advice": Complete
          "Shipment Date": "$DateFormula-<CW+1M+1D>$"
          lines:                              # nested objects are application-specific
            - Quantity: 10
              "Location Code": SVLocation
              quantity_in_inventory: 10
              reserve: true
```

Recommendation is to match the AL field captions exactly, **quoted** when they contain spaces or special characters: `"Sell-to Customer No."`. Dates should be expressed through the placeholders see details under (§9), which calculate values relative to `WorkDate`. Avoid hardcoding dates — tests written that way drift out of date and need frequent maintenance.

---

## 7. `query` — what the agent receives

`query` is consumed primarily by `Library - Agent.RunTurnAndWait`, which is the recommended high-level driver. It auto-detects the shape from which keys are present and dispatches to the appropriate lower-level call. Authors who need finer control can call the granular methods directly — `CreateTaskAndWait` / `CreateMessageAndWait` for input queries, `CreateUserInterventionAndWait` / `CreateUserInterventionFromSuggestionAndWait` / `ContinueTaskAndWait` for interventions. See §11 for the full list.

### 7.1 Choosing the input shape

A `query` is one of two shapes depending on the agent's task state:

- **Task input** — when starting a new agent task (typically turn 1,  or any time the agent is not already paused waiting for the user). Use `from` / `title` / `message` / `attachments`. See §7.2.
- **Intervention** — when the agent is paused waiting for user input (typically turn 2+). Use `intervention.suggestion` or  `intervention.instruction`. See §7.3.

The library detects which shape is present from the YAML keys and dispatches accordingly. Mixing both shapes in one query is an error (see §7.4).

### 7.2 Task input

```yaml
query:
  from: <sender display name>
  title: <task title>
  message: <task message body>
  attachments:
    - file: <relative path inside .resources>   # static file
    - file:                                      # OR: dynamically generated
        action_type: <generator name>
        action_data:
          <key>: <value>                         # arbitrary data for the generator
```

The `file` key supports two forms: a **scalar** value (static file path) or an **object** with `action_type` / `action_data` (dynamically generated file).

It is also possible to provide a `timeout` key (in milliseconds) inside `query` to override the default wait timeout for a specific turn.

How keys flow into library calls:

| YAML key | Flows into |
|---|---|
| `query.title` | `AgentTaskBuilder.Initialize(AgentUserSecurityId, title)` — required, asserted via `Library Assert`. |
| `query.from` | `AgentTaskMessageBuilder.Initialize(from, ...)`. If `from` is missing, no message is added (only the task title). |
| `query.message` | `AgentTaskMessageBuilder.Initialize(..., message)`. Optional. |
| `query.attachments[].file` (scalar) | `IAgentTestResourceProvider.GetResource(file, ...)` → `AgentTaskMessageBuilder.AddAttachment(...)`. Use the `RunTurnAndWait` overload that accepts a provider when YAML uses attachments. |
| `query.attachments[].file` (object) | `IAgentTestResourceProvider.GenerateResource(action_type, action_data, ...)` → `AgentTaskMessageBuilder.AddAttachment(...)`. The `action_data` sub-object is extracted and passed as a `Test Input Json` codeunit; `action_type` is passed separately. |

### 7.3 Intervention continuation

```yaml
query:
  intervention:
    suggestion: <code from the agent's offered suggestions>
    # OR
    instruction: <free-text reply to the agent>
```

A `timeout` key (in milliseconds) can also be provided inside `query` to override the default wait timeout.

How keys flow:

| YAML key | Flows into |
|---|---|
| `query.intervention.suggestion` | `LibraryAgent.CreateUserInterventionFromSuggestionAndWait(AgentTask, SuggestionCode)` |
| `query.intervention.instruction` | `LibraryAgent.CreateUserInterventionAndWait(AgentTask, UserInput)` |

### 7.4 Mutual exclusion

| Condition | Result |
|---|---|
| `query` has both `title` and `intervention` | `InvalidQueryBothErr` |
| `query` has neither `title` nor `intervention` | `InvalidQueryNeitherErr` |
| `intervention` has both `suggestion` and `instruction` | `InvalidInterventionErr` |

---

## 8. `expected_data` — what to validate

`expected_data` is **opaque JSON** to the framework with **one** recognized sub-key (`intervention_request`). Additional validation keys can be defined per agent test app and implemented in the validator as needed.

```yaml
expected_data:
  intervention_request:                     # framework-recognized
    type: Assistance                        # required when intervention_request is present
    suggestions:                            # optional — list of suggestion codes that MUST be present
      - <CODE_A>
      - <CODE_B>
  <agent_specific_count_key>: 1             # implemented per agent test app
  <agent_specific_status_key>: Released     # implemented per agent test app
```

### 8.1 Framework-recognized: `intervention_request`

| YAML key | Flows into |
|---|---|
| `expected_data.intervention_request.type` | `LibraryAgent.ParseUserInterventionRequestType(text)` → `Enum "Agent User Int Request Type"`. Values: `Assistance`, `Review`, `Message` (English ordinal names; no translation). |
| `expected_data.intervention_request.suggestions[]` | Validated by `LibraryAgent.ValidateInterventionRequest` — every expected code must be present on the actual request. |

Automatic validation in `LibraryAgent.FinalizeTurn`:

- If `intervention_request` is declared in YAML: the agent must have paused for an intervention with the matching `type` and including every `suggestion` code listed.
- If `intervention_request` is **not** declared: the agent must **not** have paused for an intervention. Unexpected interventions fail the turn.

So: declare `intervention_request` on every turn where you expect the
agent to pause. Otherwise omit it.

### 8.2 Agent-specific keys

Additional validation keys can be defined per agent test app. Read them via `AITTestContext.GetExpectedData()` and implement the validation logic in the test library as needed. The framework does not interpret or enforce these keys.

---

## 9. Placeholders

Embed in any string YAML value using the `$...$` syntax. During a test method, resolution is **automatic** when `Test Input Json.ValueAsText()` is called. The shared engine is `Test Input Data Tools`; `AIT Test Context` returns input wrappers rather than exposing a separate placeholder API.

| Form | Resolves to | Example |
|---|---|---|
| `$Placeholder-<name>$` | registered text, as a whole value or substring | `"Create an order for $Placeholder-Customer1No$"` |
| `$DateFormula-<formula>$` (whole value) | `Date` | `"$DateFormula-<CW+1M+1D>$"` |
| `$DateFormula-<formula>$` (inside text) | substring → `Format(Date)` | `"Process orders for $DateFormula-<CW+1M+1D>$"` |
| `$DateTimeFormula-<formula>$` | `DateTime` (time = `0T`) | `"$DateTimeFormula-<CD>$"` |
| `$DateTimeFormula-<formula>-HH:MM:SS$` | `DateTime` with explicit time | `"$DateTimeFormula-<CW>-13:30:11$"` |
| `$DateTimeFormula-<formula>-HH:MM:SS.FFF$` | `DateTime` with milliseconds | `"$DateTimeFormula-<CW>-13:30:11.130$"` |

The date/datetime result types above refer to typed getters. `ValueAsText()` always returns the resolved value as formatted text.

`<formula>` is a standard AL DateFormula evaluated against `WorkDate()`
(`<CD>`, `<CW>`, `<CM>`, `<CW+1M+1D>`, `<-7D>`, `<+30D>`, …).

**Always quote** placeholder strings in YAML — the `<` and `>` characters are otherwise interpreted as flow-style delimiters by some parsers.

### 9.1 Registering runtime values

Use named tokens directly in YAML; no declaration block or import-time substitution is needed:

```yaml
query:
  title: "Order for $Placeholder-MY-SCENARIO-Customer1No$"
  message: "Use item $Placeholder-MY-SCENARIO-BlockedItem1$."
expected_data:
  customer_no: "$Placeholder-MY-SCENARIO-Customer1No$"
```

After creating or finding the records in AL setup, register their actual values:

```al
DataTools.SetPlaceholder('MY-SCENARIO-Customer1No', Customer."No.");
DataTools.SetPlaceholder('MY-SCENARIO-BlockedItem1', BlockedItem."No.");
Found := DataTools.GetPlaceholder('MY-SCENARIO-Customer1No', CustomerNo);
MessageText := AITTestContext.GetQuery().Element('message').ValueAsText();
```

Here `DataTools` is codeunit `Test Input Data Tools`. Set an existing key again to overwrite it; the next read, including a read through an existing input wrapper, sees the new value. An already returned AL `Text` variable does not change.

Names are case-insensitive, contain 1-250 ASCII letters, digits, underscores, or hyphens, and cannot be blank. Supply the bare name to the API, not the complete token. The fixed `$Placeholder-` prefix remains case-sensitive.

If a setup field declares the token, let the framework extract its name rather than parsing token syntax in consuming AL:

```yaml
customerNo: "$Placeholder-MY-SCENARIO-Customer1No$"
```

```al
PlaceholderName := DataTools.GetPlaceholderName(SetupInput.Element('customerNo'));
LibrarySales.CreateCustomer(Customer);
DataTools.SetPlaceholder(PlaceholderName, Customer."No.");
```

`GetPlaceholderName` validates a single complete named token and reads the definition raw, even when that name already has a registered value. Invalid definitions raise an error before record creation. Normal reads of the same element resolve the current registered value.

Values are stored as UTF-8 text in a BLOB. Reading a multiline value normalizes line endings to the platform-standard separator while preserving empty lines, Unicode, whitespace within lines, and leading zeros. An empty registered value is valid and replaces its token with empty text. `GetPlaceholder` returns `false` and clears its output argument when no value exists; unresolved tokens in input text remain unchanged. Malformed generic tokens also remain literal.

Registration rejects values containing complete supported named/date/datetime tokens, even if the referenced name is unknown. Replacement is non-recursive, and there is no escape syntax.

### 9.2 Full names and company fallback

The storage key is `(Name, Company)`. Use full names such as `MY-SCENARIO-Customer1No` (prefix) or `Customer1No-MY-SCENARIO` (suffix) to distinguish scenarios. Prefixes and suffixes are literal parts of the name, not separate settings or implicit lookup context. The 250-character limit applies to the complete name.

Test authors own naming uniqueness. Concurrent executions using the same full name in the same company address the same registration. If a run identifier is needed, include it in both the input token and the AL registration; changing only the registration name will not resolve the original token.

| API | Scope |
|---|---|
| `SetPlaceholder(Name, Value)` / `GetPlaceholder(Name, var Value)` | Full name, current company. |
| `SetPlaceholderForCompany(Name, Value, Company)` / `GetPlaceholderForCompany(Name, var Value, Company)` | Full name, explicit company. |

Default operations use `CompanyName()`. Passing `''` to a company-specific API stores or reads a shared-company row. For a nonblank company, lookup first reads the exact company and then the shared row with the **same full name**. An existing local row containing empty text suppresses fallback. Explicit company operations do not change the company used by subsequent default operations or text reads.

For example, `SetPlaceholderForCompany('MY-SCENARIO-Customer1No', 'SHARED-CUST', '')` provides a shared fallback. A current-company registration for the same full name takes precedence, without changing the shared row.

### 9.3 Resolving reads, raw reads, and manual cleanup

`ValueAsText()` and `ResolveText()` always resolve named, date, and datetime tokens lazily. The same behavior applies during setup, test execution, teardown, and outside a test run. There is no enable/disable switch or runner lifecycle requirement.

Choose the read API explicitly. Use `ElementValue().AsText()` for raw scalar text, including definitions, previews, or invalid formulas that must not be evaluated. Raw reads do not change subsequent resolving reads. Typed date/datetime getters retain their conversion behavior; invalid conversions raise errors rather than returning silent defaults.

Registrations are ordinary database rows shared through the explicit company key. No helper commits or automatically deletes registrations. Test isolation and transaction rollback govern persistence, so committed suite-setup registrations can be reused when setup is skipped.

`Element()` / `ElementAt()` only navigate. `ElementValue()`, `ValueAsJsonObject()`, `AsJsonToken()`, and `ToText()` remain raw; neither the input JSON nor its property names are rewritten. Numeric/Boolean accessors are unchanged. Only the text being read is scanned, so separately loaded suite setup and directly initialized input wrappers work too.

When a consumer requires a concrete reference, `ContainsNamedPlaceholderMarker(ResolvedText)` detects a remaining named-placeholder marker without hardcoding its syntax. This includes incomplete references; it does not look up registrations or change the normal missing-token behavior.

Cleanup is explicit:

| API | Deletes |
|---|---|
| `DeletePlaceholder(Name)` | The exact full name in the current company. Returns `false` if absent; never follows shared fallback. |
| `DeletePlaceholderForCompany(Name, Company)` | The exact full name and company. Explicit blank company deletes only the shared row. Returns `false` if absent; never follows shared fallback. |
| `DeleteAllPlaceholders()` | **All registrations across all names and companies.** Use only when that full scope is intended. |

Cleanup uses exact matching, not prefix/suffix or wildcard matching, and follows the caller's transaction/test isolation. To clean up a scenario, retain its full names and delete those exact registrations.

---

## 10. XML suite definition

Wires datasets to a test codeunit. Lives at `.resources/configuration/<NAME>.xml`:

```xml
<?xml version="1.0" encoding="UTF-16" standalone="no"?>
<Root>
  <AITSuite Code="<MYAGENT>-ACCR"
            Description="<Agent Name> — Accuracy Tests"
            Dataset="<MYAGENT>-P0.YAML"
            Capability="<Agent Capability Name>"
            Frequency="Daily"
            TestRunnerId="130451"
            TestType="Agent">
    <Line CodeunitID="<your-test-codeunit-id>"
          Description="P0 Happy Path"
          Dataset="<MYAGENT>-P0.YAML" />
  </AITSuite>
</Root>
```

| Attribute | Required | Notes |
|---|---|---|
| `Code` | yes | Suite key. Conventional pattern: `<AGENT>-<KIND>` (`-ACCR`, `-LOAD`, …). |
| `Dataset` | yes | Default dataset for lines that don't override. |
| `<Line CodeunitID>` | yes | Your `[Test]` codeunit. |
| `<Line Dataset>` | yes | YAML filename. Resolved against the test app's resources. |
| `TestRunnerId` | recommended | `130451` (`Test Runner - Isol. Disabled`) — agent tasks span transactions. |
| `TestType` | recommended | `Agent`. |
| `Capability` | no | Free text. |
| `Frequency` | no | `Daily` / `Weekly` / `Manual`. |

Encoding **must** be `UTF-16`.

---

## 11. API quick reference

### `AIT Test Context`

| Procedure | Returns | Use |
|---|---|---|
| `GetEvalSuiteSetupDataInput()` | `Test Input Json` | Suite-setup content. |
| `IsSuiteSetupDone()` / `SetEvalSuiteSetupCompleted()` | bool / void | Idempotent suite-setup gate. |
| `GetTurnSetup(var Found)` | `Test Input Json` | Current turn's `turn_setup:`. |
| `GetQuery()` | `Test Input Json` | Current turn's `query:`. |
| `GetExpectedData()` | `Test Input Json` | Current turn's `expected_data:` (multi-turn aware). |
| `NextTurn()` | bool | Advance turn pointer. Usually called via `LibraryAgent.FinalizeTurn`. |
| `GetCanContinueOnFailure()` | bool | Per-test flag. |

### `Library - Agent` (codeunit `130560`)

The recommended high-level driver is `RunTurnAndWait` + `FinalizeTurn`, which are YAML-aware and handle the turn loop end to end. The other procedures in this codeunit are **lower-level alternatives** for tests that need finer control (e.g. building a task message manually, polling intervention state, supplying a custom user input outside the YAML flow).

#### Recommended high-level driver

| Procedure | Use |
|---|---|
| `EnsureAgentIsActive(AgentUserSecurityId)` | Activate before first turn. |
| `GetAgentUnderTest(var AgentUserSecurityID)` | Resolve the agent user id used by the test suite. |
| `RunTurnAndWait(AgentUserSecurityId, var AgentTask)` | Reads `query:`, runs the turn, waits. |
| `RunTurnAndWait(..., AgentTestResourceProvider)` | Same, with attachment resolver. Use when YAML has `attachments[].file`. |
| `FinalizeTurn(var AgentTask, TurnSuccessful, ErrorReason): Continue` | Always call after each turn — writes output, validates intervention expectation, advances. |

#### Alternatives — manual task management

| Procedure | Use |
|---|---|
| `CreateTaskAndWait(var AgentTaskBuilder)` | Create a task from a manually-built `AgentTaskBuilder` and wait. |
| `CreateTaskAndWait(var AgentTaskBuilder, var CreatedAgentTask)` | Same, returning the created task record. |
| `CreateMessageAndWait(var AgentTaskMessageBuilder)` | Append a message to an existing task and wait. |
| `CreateMessageAndWait(var AgentTaskMessageBuilder, var AgentTask)` | Same, returning the task record. |
| `ContinueTaskAndWait(var AgentTask)` | Continue a paused task (default user input). |
| `ContinueTaskAndWait(var AgentTask, UserInput)` | Continue a paused task with custom free-text input. |
| `WaitForTaskToComplete(var AgentTask)` | Block until a task finishes — for end-to-end scenarios that start the task from product code. |
| `StopTasks(AgentUserSecurityId)` / `StopAllTasks()` | Teardown helpers. |
| `SetAgentTaskTimeout(NewTimeout)` | Override the default timeout for all wait calls (global). |

#### Alternatives — manual intervention handling

| Procedure | Use |
|---|---|
| `RequiresUserIntervention(AgentTask)` | Poll whether a task is paused awaiting user input. |
| `GetLastUserInterventionRequestDetails(...)` | Read the most recent intervention request (request, annotations, suggestions). |
| `GetUserInterventionRequestDetails(LogEntry, ...)` | Read the intervention request attached to a specific log entry. |
| `CreateUserInterventionAndWait(var AgentTask, UserInput)` | Reply to an intervention with free-text input and wait. |
| `CreateUserInterventionFromSuggestionAndWait(var AgentTask, SuggestionCode)` | Reply to an intervention with a suggestion code and wait. |
| `ParseUserInterventionRequestType(Text)` | Text → `Enum "Agent User Int Request Type"`. |
| `GetExpectedInterventionRequest(var ExpectedIntRequest)` | Read the YAML's expected intervention request. |
| `ValidateInterventionRequest(AgentTask, ExpectedIntRequest)` | Manual intervention assertion (rarely needed; `FinalizeTurn` covers it). |

#### Output

| Procedure | Use |
|---|---|
| `WriteTaskToOutput(var AgentTask, var Output)` | Serialise task details + log entries to JSON. |
| `WriteTaskToOutput(var AgentTask, var Output, FromDateTime)` | Same, filtered by timestamp. |
| `WriteTurnToOutput(var AgentTask, TurnSuccessful, ErrorReason)` | Set the answer used for evaluation in the AI Test Context. Called by `FinalizeTurn` automatically. |

### `Test Input Json`

| Procedure | Notes |
|---|---|
| `Element(Name)` | Child by name (errors if missing). |
| `ElementExists(Name, var Found)` | Safe lookup. |
| `ElementAt(Index)` | Array element by 0-based index. |
| `GetElementCount()` | Number of elements. |
| `ValueAsText()` | Always resolves known named/date/datetime tokens lazily. |
| `ElementValue().AsText()` | Reads raw scalar text without resolving or evaluating placeholders. |
| `ValueAsInteger()` / `ValueAsDecimal()` / `ValueAsBoolean()` | Native typed accessors; no placeholder conversion. |
| `ValueAsDate()` / `ValueAsDateTime()` | Typed date accessors, including date/datetime formulas. |
| `ValueAsJsonObject()` / `AsJsonToken()` | Escape to raw native JSON. |
| `ToText()` | Serializes unresolved content; does not preserve original YAML/JSON formatting. |

### `Test Input Data Tools`

See [Placeholders](#9-placeholders) for full-name and company-scope rules.

| Procedure | Use |
|---|---|
| `GetPlaceholderName(Definition)` | Validate a raw input element and extract its bare placeholder name. |
| `ContainsNamedPlaceholderMarker(InputText)` | Detect a remaining named marker, including incomplete references, without parsing syntax in consumer AL. |
| `SetPlaceholder(Name, Value)` / `SetPlaceholderForCompany(Name, Value, Company)` | Register or overwrite the exact key with literal text. |
| `GetPlaceholder(Name, var Value)` / `GetPlaceholderForCompany(Name, var Value, Company)` | Read registered text with platform-standard line breaks, returning whether the registration exists. |
| `DeletePlaceholder(Name)` / `DeletePlaceholderForCompany(Name, Company)` | Delete the exact key without following shared fallback. |
| `DeleteAllPlaceholders()` | Delete all registrations. |
