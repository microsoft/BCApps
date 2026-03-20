# Extensibility

## What you can extend

Almost nothing. This connector is deliberately closed. It is a leaf
implementation of the External File Storage framework -- it consumes an
interface, it does not define one.

The table `Ext. File Share Account` (4570) is extensible by default (no
`Extensible = false`), so you can add fields to it with a table
extension. This is the only real extension point. You might use this to
store additional per-account metadata, but be aware that the wizard and
card pages are both `Extensible = false`, so you cannot add those fields
to the standard UI without building your own page.

## What you cannot extend

- Both pages (`Ext. File Share Account` and `Ext. File Share Account
  Wizard`) are marked `Extensible = false`. You cannot add fields,
  actions, or layout changes.
- The implementation codeunit is `Access = Internal`. You cannot call its
  procedures directly from outside the app (unless you are the test app
  declared in `internalsVisibleTo`).
- The auth type enum is `Access = Internal`. You cannot add new
  authentication methods via enum extension.
- The connector publishes no events. There are no subscriber hooks for
  intercepting or augmenting file operations.

## How to build a different connector

This app is best understood as a reference implementation. If you want to
connect to a different storage backend, you do not extend this app -- you
build a new one that follows the same pattern:

1. Create an enum extension on `"Ext. File Storage Connector"` that adds
   your connector value and binds it to your implementation codeunit via
   the `Implementation` property.
2. Implement the `"External File Storage Connector"` interface in your
   codeunit.
3. Create your own account table, account page, and wizard.
4. Register your connector's permission sets by extending `"File Storage
   - Admin"` and `"File Storage - Edit"`.

The framework discovers connectors through the enum, not through any
registration API. Adding a value to the enum is all it takes to appear
in the connector list.

## Permission set structure

The permission sets follow a layered pattern: Objects (execute on table
and pages) is included by Read (select on tabledata), which is included
by Edit (insert/modify/delete on tabledata). The permission set
extensions wire Edit into the framework's `"File Storage - Admin"` set
and Read into `"File Storage - Edit"` set, so framework-level permission
assignments automatically grant the right access to this connector's
objects.

The implicit entitlement (`ExtFileShareConnector.Entitlement.al`) grants
Edit-level access, meaning all SaaS users with the entitlement get full
CRUD on account records without explicit permission set assignment.
