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
    /// Fetches a single source integration-table record by its identifier into SourceRecordRef.
    /// The identifier is the integration UID field value - for Master Data Management the SystemId -
    /// passed as a Guid or its text form. A RecordId is environment-specific and only resolvable by the
    /// local same-environment implementation; the cross-environment feed keys on SystemId, so it returns
    /// false for a RecordId. Returns true if found.
    /// </summary>
    procedure GetById(IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var SourceRecordRef: RecordRef): Boolean;

    /// <summary>
    /// Opens the source integration table and returns the set of records whose integration UID field
    /// matches UidFilter (a filter expression, e.g. a list of SystemIds). Returns true if any matched.
    /// </summary>
    procedure GetByUidFilter(IntegrationTableMapping: Record "Integration Table Mapping"; UidFilter: Text; var SourceRecordRef: RecordRef): Boolean;

    /// <summary>
    /// Opens SourceRecordRef on the source integration table and returns ALL records matching TableFilter
    /// (the whole set, not just those modified since the watermark) - used by coupling and uncoupling.
    /// Returns true if at least one record matches.
    /// </summary>
    procedure GetByFilter(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean;
}
