# Permissions

Permission sets controlling access to E-Document Core tables, codeunits, and pages. The model follows a layered hierarchy where higher-level sets include lower-level ones.

## How it works

The active permission hierarchy is:

- **Admin** (`E-Doc. Core - Admin`, 6104) -- Full Insert/Modify/Delete on service configuration tables (E-Document Service, Mapping, Service Data Exch. Def., Service Supported Type). Includes User.
- **User** (`E-Doc. Core - User`, 6105) -- Insert/Modify/Delete on operational tables (E-Document, logs, mapping logs, data storage, order matching, purchase drafts, sample invoices). Includes Read. This is the standard permission set for users who process e-documents.
- **Read** (`E-Doc. Core - Read`, 6101) -- Read-only access to all E-Document tables. Includes Objects.
- **Objects** (`E-Doc. Core - Objects`, 6100) -- Execute permission on all tables, codeunits, and pages. Not assignable directly (`Assignable = false`, `Access = Internal`).

Four permission set extensions grant E-Document access to holders of standard D365 permission sets: `D365 BUS FULL ACCESS`, `D365 BUS PREMIUM`, `D365 READ`, and `D365 TEAM MEMBER`.

## Things to know

- **Basic** (6103) and **Edit** (6102) are obsolete (pending removal in v27). They are replaced by **User** and **Admin** respectively. Code gated by `#if not CLEAN27` keeps them available during the transition.
- **Objects** is the foundation layer and is not user-assignable. It exists purely to grant Execute permissions so the other sets can focus on data access (R/I/M/D).
- **Admin** vs **User** -- the key difference is that Admin gets full IMD on service configuration tables, while User only gets IM (insert/modify but not delete on services). Admin can delete and reconfigure services; User can only use existing ones.
- The D365 permission set extensions ensure that users with standard BC licenses automatically get some level of E-Document access without explicit per-user assignment.
- The Objects permission set is the definitive list of all AL objects in the E-Document Core app. If you add a new table, codeunit, or page, it must be added here.
