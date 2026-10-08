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

### **External File Retention**
- **External Retention**: Physical external-file deletion is blocked as an interim data-loss prevention measure, including when attachments are removed from BC
- **Verified Local Retirement**: A local external reference can be retired only when its current attachment has confirmed nonempty internal media content; the remote file is not contacted or deleted
- **No External Cleanup**: No automatic or deferred external cleanup is scheduled

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
     - **External Cleanup Status**: Review the retention notice; the saved deletion policy is currently inactive

### Configuration Options

#### General Settings
- **Enabled**: Master switch to activate/deactivate the External Storage feature
- **Root Folder**: Base folder path in external storage where all attachments will be organized
  - Files are stored in: `RootFolder/EnvironmentHash/TableName/FileName`
  - Use AssistEdit button to browse and select folder interactively

#### Upload and Delete Policy
- **External Cleanup Status**: This extension does not physically delete external files. The saved **Delete External File on Attachment Delete** setting is disabled on the setup page and does not enable cleanup.
- **Attachment Deletion**: Business Central attachment rows can still be removed, but their external bytes are retained, including lone files and files shared by copied or posted attachments.
- **Retire External Reference**: After confirmation, the action locks the current permanent attachment and its media, requires **Stored Internally** plus an existing, nonempty media blob, and clears only local external metadata. Shared/copied/foreign-environment rows with valid internal bytes can retire safely because the remote file is never contacted. Missing, empty, inconsistent, temporary, missing-row or stale references remain blocked with an explanation.
- **Copy to Internal Storage**: Restore internal content while preserving both internal and external references.
- **Move to Internal Storage**: Restore internal content and locally retire the external reference only after the same actual-content checks. Existing valid internal copies can retire without reading the remote account again. The report distinguishes locally retired references, retained remote files, restore failures and blocked retirements.
- **Retention Consequences**: Removing an attachment row can leave an orphaned external file. Storage consumption can grow; there is no retention period, cleanup job, or automatic re-enablement on upgrade.
- **Configuration Lifecycle**: Copy alone keeps external-reference safeguards active. To disable the feature or change/unassign the account, use **To Internal Storage + Move**, or restore with Copy and then **Retire External Reference**. Once all local external references have safely retired, those safeguards no longer block configuration changes. There is no force-detach bypass for missing internal bytes.

This is an interim mitigation for shared external attachment deletion (AB#647643), not an authoritative ownership or deferred-deletion protocol. A shared-reference lookup cannot close the concurrent copy/delete window, and current generic connectors cannot all prove deletion of the exact owned remote object. External cleanup remains blocked for every connector; no provider-subset or live-path deletion fallback is used. Read, upload, internal restoration and existing migration behavior remain available.

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
- **Retire External Reference**: Confirm actual internal content and retire local external metadata only; retain the remote file
- **Delete from Internal Storage**: Remove file from internal storage only

#### Bulk Operations
From **External Storage Synchronize** report:
- **To External Storage**: Upload multiple files to external storage
- **From External Storage**: Download multiple files from external storage
- **Copy to Internal Storage**: Restore content and keep both references
- **Move to Internal Storage**: Restore content and retire the local external reference while retaining remote bytes

### File Access and Compatibility
- Files uploaded to external storage remain fully accessible through standard Business Central functionality
- Document preview, download, and management work seamlessly
- Files deleted internally are automatically retrieved from external storage when accessed
- Upload, read and internal restore remain available; retirement messages identify local metadata retirement and retained remote bytes, never completed physical deletion
- Cross-environment and cross-company access is handled automatically

## Important Notes

### Data Safety
- **This extension is provided as-is**
- Always maintain proper backups of your external storage
- Test thoroughly in a sandbox environment before production use
- Verify file accessibility after migration
- This interim policy only prevents deletion sent by this extension. It does not protect against other storage consumers, remote administrators, unsupported metadata changes, or unrelated migration/internal-storage failures.
- Actual-content checks establish local byte availability, not remote-object ownership or independent provider readback provenance. This retention/local-retirement policy works independently of any deferred internal-cleanup component; it does not claim that existing internal media release is globally owner-safe.
- If a deferred internal-cleanup component is introduced later, that separate integration must preserve its cancellation and provenance rules on restore and local retirement. Such future integration is not a prerequisite for this policy.

### Environment Changes
- When moving between environments, use the **Migrate Files** action
- Environment hash changes with tenant, environment, or company changes
- Files from previous environments are not automatically deleted
- Manual cleanup of old environment folders may be required

### Feature Disable Protection
- Cannot disable External Storage setup while attachments retain external references
- Restore with **To Internal Storage + Move**, or **Copy then Retire External Reference**, before disabling the feature
- Once all local references are safely retired, the scenario can be changed or unassigned; remote safety copies remain retained

**© 2025 Microsoft Corporation. All rights reserved.**
