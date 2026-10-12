namespace Microsoft.Integration.MDM;

/// <summary>
/// The wire contract the cross-environment data source calls on the source's ODataV4 web service. One method
/// per unbound action; JSON in, JSON out. Kept as a seam so the HTTP/OAuth transport can be swapped for an
/// in-process transport in tests (the source and subsidiary run in the same environment there).
/// </summary>
interface "IMDM Source Transport"
{
    Access = Internal;

    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer; Filter: Text): Text;

    procedure LastModifiedAtPerTable(TableIds: Text): Text;

    procedure GetCapabilities(): Text;
}
