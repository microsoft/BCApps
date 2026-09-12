# Agent Task Log JSON Export

The Agent Task troubleshooting experience supports exporting log information as a JSON document for manual investigation and test automation.

## User interface

- **Export selected** on the **Agent Task Log Entry List** exports the selected log entries.
- **Export log entries** on the **Agent Task List** exports the complete log and troubleshooting memory for the selected task.
- Downloaded filenames include the agent name when it can be resolved.

## Programmatic export

Codeunit `"Agent Task Log Export"` provides internal stream-based APIs:

```al
AgentTaskLogExport.ExportToJson(SelectedAgentTaskLogEntry, ExportOutStream);
AgentTaskLogExport.ExportTaskToJson(AgentTaskID, ExportOutStream);
```

File-download variants are also available:

```al
AgentTaskLogExport.ExportToJsonFile(SelectedAgentTaskLogEntry);
AgentTaskLogExport.ExportTaskToJsonFile(AgentTaskID);
```

The selected-entry API exports only the supplied log entries. The task API exports all log entries and memory entries for the given task.

## JSON content

The root document contains:

- `taskContext` with the task ID and available task, company, and agent information.
- `logEntries` in chronological order.
- `memoryEntries` in chronological order for a complete task export.

Log entries include the values shown by the details page, such as the description, reason, calculated details, action outcome, messages, related actions, and troubleshooting context. Context can include page stack, available tools, memorized data, task page settings, and serialized page information.

Valid JSON stored in memory details is emitted as native JSON. Other details remain JSON strings. Enum and option captions are exported in English for deterministic automation, and the caller's language is restored afterward.

## Security

Export uses the same agent-management access check as opening the Agent Task Log pages.

Serialized page content is sensitive and is included only when the current user has the **Troubleshoot All Agents** permission. Without that permission, the rest of the context is exported and the page content is replaced with explicit redaction information.

## Supporting changes

- Shared calculations were extracted from the Agent Task Log Entry page into codeunit `"Agent Task Log Entry"` so the page and JSON export use the same values.
- Temporary log records avoid persistent task, memory, message, and related-entry lookups where those relationships are unavailable.
- Tests cover chronological ordering, separation of log and memory entries, native memory JSON, English captions with language restoration, real task context, and redacted troubleshooting context.
- The AI Test Toolkit command-line page can load one authoritative Agent Task troubleshooting JSON document at a time for the latest eval suite version.
