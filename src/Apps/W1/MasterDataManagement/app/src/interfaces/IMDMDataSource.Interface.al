namespace Microsoft.Integration.MDM;

using Microsoft.Integration.SyncEngine;

/// <summary>
/// Abstracts reading source-company master data so the same synchronization logic can run against a
/// local company (ChangeCompany) or, in a future release, a remote environment over OData.
/// Sealed to Microsoft: partners must not implement it or ride the synchronization credentials.
/// </summary>
interface "IMDM Data Source"
{
    Access = Internal;

    /// <summary>
    /// Opens SourceRecordRef on the source integration table for the given mapping and applies the
    /// supplied table filter. Returns true if at least one record matches.
    /// </summary>
    procedure GetModifiedSet(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean;

    /// <summary>
    /// Fetches a single source record from the given integration table by its SystemId into
    /// SourceRecordRef. Returns true if the record was found.
    /// </summary>
    procedure GetBySystemId(IntegrationTableId: Integer; SystemId: Guid; var SourceRecordRef: RecordRef): Boolean;

    /// <summary>
    /// Fetches a single source integration-table record by its id (the integration UID field value,
    /// a RecordId, or a business-key text) into SourceRecordRef. Returns true if found.
    /// </summary>
    procedure GetById(IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var SourceRecordRef: RecordRef): Boolean;
}
