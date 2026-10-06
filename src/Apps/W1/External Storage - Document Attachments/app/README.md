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
- **Verified Internal Cleanup**: A separate job queue verifies external retrievability before detaching an attachment's internal media reference

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
- **Automatic Verified Internal Cleanup**: Off by default, including after upgrade. When explicitly enabled, new automatic uploads request background cleanup. Existing both-storage attachments are not backfilled.
- **Cleanup Batch Size / Cleanup Run Budget**: Finite limits on records and elapsed work between files. These do not bound an individual connector's transfer duration or buffered response size.

### Verified Internal Cleanup

An upload first leaves both the internal content and external reference intact. **Move to External** and **Delete from Internal** request a separate background operation; they do not synchronously remove internal content. Manual **Upload to External** and **Copy to External** never create cleanup intent.

The **Internal Cleanup Requests** page shows requests, attempts, retry times, and blocked diagnostics. The worker uses the account and exact path recorded at upload, consumes a complete nonempty readback, then rechecks the attachment, source media, account configuration, company/environment ownership, cancellation and attempt lease before detaching this attachment's reference. Downloads are not added to attachment insertion or ledger posting.

Failures and inconclusive validation preserve internal media and external tracking. Retrieval failures retry at bounded intervals, with a maximum of five attempts; blocked or exhausted requests require an explicit retry. Retry does not adopt a different destination or invent missing upload provenance. Cancelling a request retains both copies.

Storage accounts require the optional metadata-only **External File Storage Context** capability for cleanup. Account ID alone is insufficient: the binding includes a secret-free destination fingerprint and a persistent configuration generation. Any account edit, including changing away and back or rotating credentials, invalidates the original cleanup binding. Unsupported connectors continue to support copy/download but block internal cleanup.

Legacy both-storage rows without recorded upload provenance remain untouched. Existing external-only attachments continue to use their existing retrieval behavior; this feature cannot restore previously lost internal content.

Remote-source company/environment migration invalidates cleanup intent and cannot infer that the original internal source matches the migrated object. Both-storage migrated attachments remain blocked rather than silently adopting a new binding.

Use **Schedule Cleanup Worker** to provision a worker for saved requests when necessary. Existing On Hold/Error jobs are not silently restarted; a job queue administrator must resume them. With automatic cleanup disabled, a temporary recurring worker drains manual requests and retries, then retires when no manual work remains.

Cleanup releases only this attachment's media reference. It does not explicitly delete Tenant Media or invoke/schedule global media cleanup. **Physical database-space reclamation may be delayed until independently operated detached-media cleanup.** Platform runtime verification of reference detachment with remaining shared owners is required before release.

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
- **Delete from Internal Storage**: Request verified background detachment of the internal attachment reference

#### Bulk Operations
From **External Storage Synchronize** report:
- **To External Storage**: Upload multiple files to external storage
- **From External Storage**: Download multiple files from external storage
- **Move to External**: Copy externally and request independent verified internal cleanup

### File Access and Compatibility
- Files uploaded to external storage remain fully accessible through standard Business Central functionality
- Document preview, download, and management work seamlessly
- Files deleted internally are automatically retrieved from external storage when accessed
- Internal cleanup is asynchronous and can remain blocked while both copies are retained
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
