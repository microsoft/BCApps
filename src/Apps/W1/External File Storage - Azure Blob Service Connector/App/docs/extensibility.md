# Extensibility

## Building a new connector

This app is the reference implementation for the External File Storage connector pattern. The framework lives in System Application; connectors are separate apps that plug in via interface implementation and enum extension. To build a new connector (say, for Google Cloud Storage), you need three things:

**1. Implement the interface.** Create a codeunit that implements `"External File Storage Connector"`. This interface defines the contract: file operations (list, get, create, delete, copy, move, exists), directory operations (list, create, delete, exists), account management (register, delete, get accounts, show info), and metadata (description, logo). Look at `ExtBlobStoConnectorImpl.Codeunit.al` for the full set of procedures -- your codeunit must implement all of them.

**2. Extend the enum.** Create an enum extension on `"Ext. File Storage Connector"` that adds your connector as a new value. The value must use the `Implementation` property to bind your interface implementation codeunit. This is how the framework discovers and dispatches to your connector:

```al
enumextension 50100 "My Cloud Storage Connector" extends "Ext. File Storage Connector"
{
    value(50100; "My Cloud Storage")
    {
        Caption = 'My Cloud Storage';
        Implementation = "External File Storage Connector" = "My Cloud Storage Impl.";
    }
}
```

**3. Manage your own account storage.** The framework does not prescribe how you store account configuration. This connector uses a dedicated table (`Ext. Blob Storage Account`) with IsolatedStorage for secrets. Your connector needs its own table for connection details. The framework only cares about the `File Account` temporary record (Account Id, Name, Connector enum value) that your `GetAccounts()` and `RegisterAccount()` procedures return.

## What the framework provides

The framework handles the UI for selecting connectors, listing accounts, and dispatching operations. Your connector never needs to build a "file browser" -- the framework provides that. Your job is to translate the abstract operations into your storage backend's API.

The `File Pagination Data` codeunit is worth understanding. The framework may call your listing procedures multiple times for the same path, passing this codeunit each time. You store your continuation token in it (via `SetMarker`/`GetMarker`) and signal completion with `SetEndOfListing`. The Blob Storage connector uses Azure's `NextMarker` for this, but you can store any string your backend needs for pagination.

## What you cannot extend on this connector

The wizard page (`ExtBlobStorAccountWizard.Page.al`) and container lookup page are both `Extensible = false`. The account card page is also `Extensible = false`. You cannot add fields to these pages via page extensions.

The table is extensible by default, but extending it would be unusual -- if you need different connection parameters, you would create your own table in your own connector app.

The codeunit is `Access = Internal`, so you cannot call its procedures directly from outside the app. The only public surface is the interface contract.

## No events to subscribe to

This connector publishes no events. It subscribes to one -- `EnvironmentCleanup::OnClearCompanyConfig` -- but that is a framework event, not one it defines. If you build a connector that stores credentials, you should subscribe to the same event and disable accounts on sandbox copy, following the pattern in the `EnvironmentCleanup_OnClearCompanyConfig` subscriber.
