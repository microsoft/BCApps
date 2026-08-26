namespace Microsoft.Integration.MDM;

/// <summary>
/// Assigned to the customer-registered Entra app on the SOURCE (Microsoft Entra Application Card) to grant
/// cross-environment, read-only access to master data. Deliberately NOT part of "Master Data Mgt. - Objects":
/// only this set grants execute on the ODataV4 source API, so local users cannot invoke it.
/// The per-synchronized-table read permissions are added dynamically as a tenant permission set as the user
/// edits Synchronization Tables (see design doc); this static set covers only the API surface.
/// </summary>
permissionset 7242 "MDM Cross-Env Read"
{
    Assignable = true;
    Access = Public;
    Caption = 'Master Data Mgt. - Cross Environment';

    Permissions = codeunit "MDM Cross-Env Source API" = X;
}
