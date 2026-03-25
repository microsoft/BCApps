# Integration Domain Knowledge

## API v2.0 Architecture

- BC exposes entities via **OData v4 REST APIs** at `/api/v2.0/` endpoints. Standard entities include customers, vendors, items, sales orders, purchase orders, and journal entries.
- **Custom API Pages** (PageType = API) allow extensions to expose additional entities with custom endpoints.
- API pages support **deep inserts** (creating parent + child records in one request) and **batch requests** for performance.
- **API field mapping**: API field names use camelCase and may differ from the underlying table field names. Missing or renamed fields are a common integration issue.
- **Webhooks** notify external systems of entity changes via registered subscription URLs.
- **$filter, $expand, $select, $top, $skip** query parameters control response shape and pagination.

## Dataverse Integration

- **Bidirectional sync** between BC and Dataverse (used by Dynamics 365 Sales, Customer Service, etc.).
- **Integration Table Mappings** define which BC tables sync with which Dataverse tables, including field mappings and sync direction.
- **Coupling** links a BC record to a Dataverse row via a GUID pair. Uncoupled records are not synced.
- **Sync conflicts** occur when both sides modify a record between sync cycles. Resolution rules: BC wins, Dataverse wins, or manual resolution.
- **Scheduled sync** runs via the Job Queue at configured intervals. Full sync vs. incremental sync options.
- **Virtual Tables**: Dataverse can expose BC data as virtual tables without copying data — uses the BC API under the hood.

## Job Queue

- **Job Queue Entries** (T472) run codeunits or reports on a schedule in a background session.
- **Recurrence**: Configured with start time, interval (minutes), and specific run days.
- **Error handling**: Failed entries move to an error state with an error message. **Maximum No. of Attempts to Run** controls automatic retries.
- **Job Queue Categories** group related entries. **NAS** (No Active Session) runs job queue entries in the service tier.
- Common failure causes: record locks (deadlocks), permission errors, timeout on long-running operations, and missing setup data.

## Email Module

- The **Email Module** in System Application provides a pluggable email framework.
- **Email Accounts** (SMTP, Outlook REST, Exchange Online) are configured separately from the email sending logic.
- **Email Scenarios** map business events to email accounts (e.g., sales invoices use one account, purchase orders use another).
- **Sent Emails** and **Email Outbox** tables track email status and allow resending.
- **Word Templates** and **Email Body Templates** support merge fields from BC records.

## Workflow Engine

- BC's built-in **Workflow** engine (T1501) defines event-response chains for business process automation.
- **Workflow Events**: OnSendForApproval, OnApprove, OnReject, OnDelegate, plus custom events from extensions.
- **Workflow Responses**: Send approval request, create notification, restrict usage, apply new values, plus custom responses.
- **Approval Workflows** are the most common type — they gate document posting behind an approval chain with amount limits.
- **Power Automate** integration allows BC workflows to trigger Power Automate flows and vice versa.

## System Application Foundation

- The **System Application** provides core services used by all other apps: Telemetry, Permissions, User Settings, Data Classification, Retention Policies, and more.
- **Extension Management** handles app lifecycle — install, upgrade, uninstall with corresponding event triggers.
- **Guided Experience** framework provides setup wizards and checklists for onboarding.
- Changes to System Application affect the entire platform and require careful backward compatibility consideration.

## Common Issues

- API field mapping errors when custom extensions add fields that are not exposed on the API page
- Dataverse sync conflicts when bulk operations modify records on both sides simultaneously
- Job Queue failures due to record locking during high-concurrency posting operations
- Email sending failures from authentication token expiry (OAuth2) or SMTP relay configuration changes
- Workflow approval chain breaks when approver users are disabled or limit amounts are misconfigured
- Power Automate connector timeout when BC operations take longer than the HTTP request timeout
