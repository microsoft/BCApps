#pragma warning disable AA0247
permissionset 11740 "CZ Advance Pack - Read CZA"
{
    Access = Internal;
    Assignable = false;
    Caption = 'CZ Advance Pack - Read';

    IncludedPermissionSets = "CZ Advance Pack - Objects CZA";

    Permissions = tabledata "Auto. Create Default Dim. CZA" = R,
                  tabledata "Detailed G/L Entry CZA" = R;
}
