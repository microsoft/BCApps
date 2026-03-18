# Permissions

Role-based access control (RBAC) for E-Document features. Defines 6 permission sets spanning read-only access, transactional editing, administrative configuration, and licensed product tier integration. Enables granular security modeling from basic viewing to full document lifecycle management.

## Quick reference

- **Parent:** [App root](../CLAUDE.md)
- **Files:** 10 .al files (6 permission sets + 4 D365 extensions)
- **Key objects:** E-Doc. Core - Read/User/Edit/Admin, D365 Business Central permission set extensions
- **Assignable sets:** E-Doc. Core - Read, User, Edit (obsolete), Admin

## How it works

Permission sets use a layered inheritance model. "E-Doc. Core - Objects" (internal, non-assignable) grants X (execute) permission to all 154 objects (tables, pages, codeunits). "E-Doc. Core - Read" (public, assignable) includes Objects and grants R (read) tabledata permissions. "E-Doc. Core - User" (public, assignable) includes Read and adds IMD (insert/modify/delete) permissions for transactional objects but excludes service configuration. "E-Doc. Core - Admin" (public, assignable) includes User and adds IMD to service setup tables.

D365 license tier extensions inject E-Doc permissions into standard Business Central permission sets. D365 TEAM MEMBER adds E-Doc. Core - Read. D365 BUS FULL ACCESS and BUS PREMIUM add E-Doc. Core - User. D365 READ adds E-Doc. Core - Read for global read-only access.

Permission boundaries align with functional responsibilities: viewers can list documents and drill down to logs (Read), users can create/modify documents and match orders but not configure services (User), admins can create services and configure integrations (Admin).

The obsolete "E-Doc. Core - Edit" permission set (pending removal in v27.0) provides the same permissions as User but with different naming for backward compatibility during transition period.

## Key files

- **EDocCoreObjects.PermissionSet.al** -- Internal base set granting X (execute) to all 154 codeunits/pages/tables
- **EDocCoreRead.PermissionSet.al** -- Read-only access: R tabledata for all E-Document entities
- **EDocCoreUser.PermissionSet.al** -- Transactional access: IMD for documents, logs, order matching; excludes service configuration
- **EDocCoreEdit.PermissionSet.al** -- Obsolete v27.0, duplicate of User permissions
- **EDocCoreAdmin.PermissionSet.al** -- Administrative access: IMD for service setup, includes User permissions
- **EDocCoreBasic.PermissionSet.al** -- Legacy internal set, minimal execute permissions (not assignable)
- **D365BUSFULLACCESSEDocument.PermissionSetExt.al** -- Adds E-Doc. Core - User to D365 BUS FULL ACCESS license
- **D365BUSPREMIUMEDocument.PermissionsetExt.al** -- Adds E-Doc. Core - User to D365 BUS PREMIUM license
- **D365READEDocCore.PermissionsetExt.al** -- Adds E-Doc. Core - Read to D365 READ license
- **D365TEAMMEMBEREDocCore.PermissionsetExt.al** -- Adds E-Doc. Core - Read to D365 TEAM MEMBER license

## Things to know

- **IncludedPermissionSets cascades permissions** -- User includes Read, Admin includes User, creating 3-tier hierarchy
- **Objects permission set is Access = Internal** -- Never assigned directly; only included by public permission sets
- **Assignable = true enables user assignment** -- Read, User, Admin can be assigned to users; Objects, Basic cannot
- **Edit obsoleted in v27.0** -- Use User instead; Edit remains for backward compatibility during deprecation period
- **D365 extensions add, not replace** -- PermissionSetExt supplements existing permissions, doesn't override
- **InherentEntitlements/Permissions not used** -- Permission sets rely on explicit tabledata/object grants; pages/API use InherentPermissions = X
- **Service configuration restricted to Admin** -- E-Document Service, E-Doc. Service Supported Type require Admin permission set
- **Order Match tables require User** -- E-Doc. Order Match, E-Doc. Imported Line, E-Doc. PO Match Prop. Buffer need IMD from User set
- **API pages enforce own permissions** -- EDocumentsAPI uses InherentPermissions = X, respects user's underlying tabledata permissions regardless of permission set assignment

## Permission matrix

| Object | Objects | Read | User | Admin |
|--------|---------|------|------|-------|
| E-Document table | X | R | IMD | IMD |
| E-Document Log table | X | R | IMD | IMD |
| E-Document Service table | X | R | R | IMD |
| E-Doc. Service Supported Type | X | R | R | IMD |
| E-Document Service Status | X | R | IMD | IMD |
| E-Doc. Order Match | X | R | IMD | IMD |
| E-Document Services page | X | X | X | X |
| E-Document Service page | X | X | X | X |
| E-Documents page | X | X | X | X |
| E-Document Processing codeunit | X | X | X | X |
| E-Doc. Import codeunit | X | X | X | X |

## Permission sets

### E-Doc. Core - Objects (6100)

**Access:** Internal
**Assignable:** false
**Permissions:** 154 objects with X (execute)

**Included objects:**
- All E-Document tables (6100-6199 range)
- All E-Document pages (6100-6199 range)
- All E-Document codeunits (processing, workflow, import, export, logging)
- Copilot integration objects (AOAI Function, PO Matching)
- PEPPOL format objects (import/export, pre-mapping)
- Service participant management
- Order matching UI and logic

**Usage:** Base set included by all public permission sets; provides execute permission for E-Document codeunits and access to pages

### E-Doc. Core - Read (6103)

**Access:** Public
**Assignable:** true
**Includes:** E-Doc. Core - Objects

**Tabledata permissions (R = Read):**
- E-Document, E-Document Log, E-Document Service, E-Document Service Status (all core entities)
- E-Doc. Data Storage (blob access for file downloads)
- E-Doc. Mapping, E-Doc. Mapping Log (transformation audit)
- E-Doc. Order Match, E-Doc. Imported Line (order matching view)
- Service Participant (trading partner lookup)
- E-Doc. Import Parameters, E-Document Purchase Header/Line (draft documents)

**Use case:** Viewers, auditors, read-only dashboards

### E-Doc. Core - User (6101)

**Access:** Public
**Assignable:** true
**Includes:** E-Doc. Core - Read

**Tabledata permissions (IMD = Insert/Modify/Delete):**
- E-Document, E-Document Log, E-Document Service Status (transactional operations)
- E-Doc. Data Storage (blob creation during export)
- E-Doc. Mapping, E-Doc. Mapping Log (transformation rules)
- E-Doc. Order Match, E-Doc. Imported Line, E-Doc. PO Match Prop. Buffer (order matching)
- Service Participant (trading partner management)
- E-Doc. Import Parameters, E-Document Purchase Header/Line (draft creation)

**Excluded from User:**
- E-Document Service table (IMD) -- requires Admin
- E-Doc. Service Supported Type (IMD) -- requires Admin
- E-Doc. Service Data Exch. Def. (IMD) -- requires Admin

**Use case:** Accountants, purchasing agents, document processors

### E-Doc. Core - Admin (6104)

**Access:** Public
**Assignable:** true
**Includes:** E-Doc. Core - User

**Additional tabledata permissions (IMD):**
- E-Document Service (service configuration)
- E-Doc. Service Supported Type (document type mapping)
- E-Doc. Service Data Exch. Def. (Data Exchange format setup)

**Use case:** IT admins, integration specialists, service configurators

### E-Doc. Core - Edit (6102, obsolete v27.0)

**Access:** Public
**Assignable:** true
**Includes:** E-Doc. Core - Read
**ObsoleteReason:** 'Use "E-Doc. Core - User" instead.'

**Permissions:** Duplicate of User permissions (IMD on same set of tables)

**Migration path:** Replace Edit assignments with User in customer environments before v27.0

### E-Doc. Core - Basic (6105)

**Access:** Internal
**Assignable:** false
**Permissions:** Minimal X (execute) on core codeunits

**Usage:** Legacy set, not used in current permission model

## D365 license integration

### D365 BUS FULL ACCESS + BUS PREMIUM

**Extensions:** D365BUSFULLACCESSEDocument, D365BUSPREMIUMEDocument
**Adds:** E-Doc. Core - User

**Effect:** Users with Business Central Full Access or Premium licenses can create/modify E-Documents, process inbound invoices, match orders, but cannot configure services

### D365 TEAM MEMBER

**Extension:** D365TEAMMEMBEREDocCore
**Adds:** E-Doc. Core - Read

**Effect:** Team Members can view E-Documents, drill down to logs, see status, but cannot create or modify

### D365 READ

**Extension:** D365READEDocCore
**Adds:** E-Doc. Core - Read

**Effect:** Read-only license gets read-only E-Document access (consistent with global read-only permissions)

## Security boundaries

**Service configuration (Admin-only):**
- Creating E-Document Service records
- Mapping document types to services (E-Doc. Service Supported Type)
- Configuring Data Exchange definitions
- Setting batch processing parameters
- Configuring import schedules

**Transactional operations (User-level):**
- Creating E-Documents from posted sales documents
- Processing inbound invoices
- Matching orders to E-Document lines
- Creating purchase drafts
- Exporting and sending documents
- Viewing logs and errors

**Read-only access (Read-level):**
- Listing E-Documents
- Viewing document details
- Drilling down to logs
- Seeing service status
- Downloading file content (via log export action)

## Migration notes

- **v27.0 removes E-Doc. Core - Edit** -- Replace all Edit assignments with User before upgrading
- **IncludedPermissionSets transitive** -- User includes Read includes Objects; assigning User grants all three levels
- **Permission set extensions cumulative** -- D365 BUS FULL ACCESS users get User permissions; if also granted Admin explicitly, they get Admin permissions
- **API permissions separate** -- API pages use InherentPermissions = X, check user's underlying tabledata permissions; assigning Read/User/Admin grants corresponding API access automatically

## Performance notes

- **Permission checks cached per session** -- First access checks permission, subsequent checks use session cache
- **InherentPermissions = X on API pages** -- No additional permission check overhead; uses existing tabledata permissions
- **IncludedPermissionSets flattened at assignment** -- Including Read inside User doesn't double-check Read permissions; flattened into single effective permission set
