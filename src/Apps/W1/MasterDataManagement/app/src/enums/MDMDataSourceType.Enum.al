namespace Microsoft.Integration.MDM;

/// <summary>
/// Selects the master data source implementation. Non-extensible and internal: partners must not add
/// source types. The value is derived from setup (Source Environment Name), never stored directly.
/// </summary>
enum 7239 "MDM Data Source Type" implements "IMDM Data Source"
{
    Access = Internal;
    Extensible = false;

    value(0; LocalCompany)
    {
        Caption = 'Local Company';
        Implementation = "IMDM Data Source" = "MDM Local Data Source";
    }

    value(1; CrossEnvironment)
    {
        Caption = 'Cross Environment';
        Implementation = "IMDM Data Source" = "MDM Cross-Env Data Source";
    }
}
