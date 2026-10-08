# Document Attachments External Storage for Microsoft Dynamics 365 Business Central

## Overview

The External Storage extension provides seamless integration between Microsoft Dynamics 365 Business Central and external storage systems such as Azure Blob Storage, SharePoint, and File Shares. This extension automatically manages document attachments by storing them in external storage systems while maintaining full functionality within Business Central.

## Key Features

### **Multi-Tenant, Multi-Environment, and Multi-Company Support**
- **Environment Hash**: Unique hash based on Tenant ID + Environment Name + Company System ID
- **Organized Folder Structure**: Files are stored in hierarchical folders: `RootFolder/EnvironmentHash/TableName/FileName`
- **Cross-Environment Compatibility**: Files from different tenants, environments, or companies are properly isolated
- **Migration Support**: Built-in migration tool to move files between company folders when needed
- **Environment Hash Display**: View current environment hash for reference and troubleshooting

### **Flexible Deletion Policies**
- **Delete from External Storage**: Optionally delete files from external storage when attachments are removed from BC
- **Fail-Closed Internal Cleanup**: Internal references and content remain even after successful external upload or readback; unsupported media release is explicitly blocked

### **Customizable Root Folder**
- Configure a custom root folder path for all attachments
- Interactive folder browser for easy selection
- Automatic folder creation and hierarchy management

### **Bulk Operations**
- Synchronize multiple files between internal and external storage
- Bulk upload to external storage
- Bulk download from external storage
- Progress tracking with detailed reporting

## Installation & Setup

### Prerequisites
- Microsoft Dynamics 365 Business Central version 28.0 or later
- File Account module configured with external storage connector
- Appropriate permissions for file operations

### Installation Steps

1. **Configure File Account**
   - Open **File Accounts** page
   - Create a new File Account with your preferred connector:
     - Azure Blob Storage
     - SharePoint
     - File Share
   - Assign the account to **External Storage** scenario

2. **Configure External Storage**
   - Open **File Accounts** page
   - Select assigned **External Storage** scenario
   - Open **Additional Scenario Setup**
   - Configure settings:
     - **Enabled**: Enable the External Storage feature
     - **Root Folder**: Select the root folder path for attachments (use AssistEdit to browse)
     - **Delete from External Storage**: Enable to delete external files when attachments are removed from BC

### Configuration Options

#### General Settings
- **Enabled**: Master switch to activate/deactivate the External Storage feature
- **Root Folder**: Base folder path in external storage where all attachments will be organized
  - Files are stored in: `RootFolder/EnvironmentHash/TableName/FileName`
  - Use AssistEdit button to browse and select folder interactively

#### Upload and Delete Policy
- **Delete from External Storage**: When enabled, files are deleted from external storage when the attachment is removed from Business Central
- **Record Automatic Cleanup Requests**: Off by default, including after upgrade. When explicitly enabled, new automatic uploads record a blocked cleanup request and retain internal content. This does not enable media release or schedule a new cleanup job. Existing attachments are not backfilled.
- **Cleanup Batch Size / Cleanup Run Budget**: Finite limits on records and elapsed work between files. These do not bound an individual connector's transfer duration or buffered response size.

### Blocked Internal Cleanup and Content Retention

**Internal cleanup is blocked. No internal reference is released and no database storage is reclaimed.** Runtime testing showed that clearing a Media field and modifying the attachment can delete physical media, including content referenced from another table. A successful remote readback does not make that release operation globally owner-preserving. The user-approved safety policy therefore retains the original internal references and bytes rather than clearing them, introducing a substitute owner/copy, or running global cleanup.

Upload keeps both internal content and the external reference. **Move to External** can create an external copy, but its internal-cleanup step reports blocked, not completed, moved, deleted, or accepted for later release. **Delete from Internal (Blocked)** records the same explicit blocked outcome. Manual **Upload to External** and **Copy to External** never create cleanup intent.

The **Internal Cleanup Requests** page shows the `Blocked` status, `InternalReleaseUnsupported` outcome, and the reason that internal content is retained with no reclamation. Rechecking a request does not enqueue a destructive operation, remove the safety gate, or adopt a different account/path. Cancellation retains both copies. Legacy rows without upload provenance remain blocked without invented historical bindings.

Previously pending requests can still be independently validated through **Schedule Pending Validation**. The worker uses the recorded exact account/path, fully consumes nonempty content, and rechecks source media, attachment/configuration versions, scenario, ownership/company/environment, policy, cancellation, and lease before recording the blocked release outcome. Successful readback is diagnostic evidence only; even a matching finalizer cannot release media or write a completed-cleanup state. Retrieval failures retain existing bounded retry diagnostics. No additional download or commit is added to attachment insertion or posting.

The optional metadata-only **External File Storage Context** binding is still required for independent validation. Account ID alone is insufficient: secret-free destination fingerprint and persistent account generation include API/base-path interpretation. Any account edit, including changing away and back or rotating credentials, invalidates the original binding. SharePoint descriptor version 2 includes the merged URL/Decoded Path setting. These checks cannot authorize unsupported internal release.

Existing external-only attachments retain their existing retrieval behavior; this change cannot restore previously lost internal media. Retention is a deliberate behavior change from the earlier unvalidated detach-only plan, not a claim that the old failing media tests were harmless.

Remote-source company/environment migration invalidates cleanup intent and cannot infer that the original internal source matches the migrated object. Both-storage migrated attachments remain blocked rather than silently adopting a new binding.

Deliberately resetting an external reference cancels pending cleanup and invalidates the old upload provenance in the same local transaction. Reapplying old flags/path cannot reactivate that provenance. Ordinary Copy to Internal preserves both references while cancelling the pending cleanup request; it is not reference retirement.

When integrating the separate retention-only guard, explicit **local** external-reference retirement is permitted only after a current permanent attachment is locked and both `Stored Internally = true` and actual nonempty internal media content are confirmed. Move to Internal restores first, then retires local external tracking while leaving remote bytes as safety copies; content-missing/external-only rows remain blocked. Retirement makes no remote request or deletion. That consumer owns the content guard; cleanup-provenance invalidation does not itself establish that retirement is safe.

Use **Schedule Pending Validation** only for previously pending work. Existing On Hold/Error jobs are not silently restarted; a job queue administrator must resume them. New blocked requests do not schedule a worker. Finite batch and elapsed-work controls apply between files, not to an individual transfer's duration, buffering, or memory use.

No attachment media field is cleared, no Tenant Media row is deleted, and no global media cleanup is invoked or scheduled by this internal-cleanup path. **There is no storage reclamation from this feature.** A future supported globally owner-preserving release operation would require separate proof and approval; there is no enablement switch or readback receipt that bypasses the current gate.

Successful readback establishes point-in-time retrievability, not immutable-byte or semantic document integrity. SharePoint can transform Office/.msg bytes and length, so source SHA256/length equality is not required. This is not a backup policy or protection against later remote deletion, replacement, configuration loss or outages.


## Usage

### Multi-Company and Multi-Environment Support

#### Environment Hash
Every file uploaded to external storage includes an environment hash that uniquely identifies:
- **Tenant ID**: Your Business Central tenant
- **Environment Name**: Current environment (e.g., Production, Sandbox)
- **Company System ID**: Unique identifier for the company

This ensures files from different tenants, environments, or companies are properly isolated in external storage.

#### Folder Structure
Files are organized hierarchically:
```
RootFolder/
  ├── [EnvironmentHash-1]/
  │   ├── Sales_Header/
  │   │   └── invoice-{guid}.pdf
  │   └── Purchase_Header/
  │       └── order-{guid}.pdf
  └── [EnvironmentHash-2]/
      └── Sales_Header/
          └── quote-{guid}.pdf
```

#### File Migration
When moving data between environments or companies:
1. Open **External Storage Setup** page
2. Click **Migrate Files** action
3. System automatically:
   - Identifies files from previous environment/company
   - Copies files to current environment/company folder structure
   - Updates file paths and environment hash
   - Maintains all file metadata and associations

#### Environment Hash Display
- Click **Show Current Environment Hash** to view your current hash
- Use this hash to identify your files in external storage
- Helpful for troubleshooting and cross-environment scenarios

### Manual Operations

#### Setup Page Actions
From **External Storage Setup** page:
- **Storage Sync**: Run synchronization manually to upload/download files
- **Migrate Files**: Migrate all files from previous environment/company to current folder structure
- **Show Current Environment Hash**: Display the current environment hash for reference
- **Document Attachments**: Open the list of all document attachments with external storage information

#### Individual File Operations
From **Document Attachment - External** page:
- **Upload to External Storage**: Upload selected file manually
- **Download from External Storage**: Download file for viewing
- **Download to Internal Storage**: Restore file to internal storage
- **Delete from External Storage**: Remove file from external storage
- **Delete from Internal (Blocked)**: Record the reason why internal cleanup is unavailable while retaining internal references and actual content

#### Bulk Operations
From **External Storage Synchronize** report:
- **To External Storage**: Upload multiple files to external storage
- **From External Storage**: Download multiple files from external storage
- **Move to External**: Copy externally when needed, then report the internal-cleanup step as blocked; retain both references and content

### File Access and Compatibility
- Files uploaded to external storage remain fully accessible through standard Business Central functionality
- Document preview, download, and management work seamlessly
- Files deleted internally are automatically retrieved from external storage when accessed
- Internal cleanup is blocked even after successful verification; internal storage is not reclaimed
- Cross-environment and cross-company access is handled automatically

## Important Notes

### Data Safety
- **This extension is provided as-is**
- Always maintain proper backups of your external storage
- Test thoroughly in a sandbox environment before production use
- Verify file accessibility after migration

### Environment Changes
- When moving between environments, use the **Migrate Files** action
- Environment hash changes with tenant, environment, or company changes
- Files from previous environments are not automatically deleted
- Manual cleanup of old environment folders may be required

### Feature Disable Protection
- Cannot disable External Storage setup if files are uploaded
- Must delete all uploaded files before disabling the feature
- Cannot unassign External Storage scenario if files exist in external storage

**© 2025 Microsoft Corporation. All rights reserved.**
