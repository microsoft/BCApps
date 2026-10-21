#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
permissionset 27225 "QBMigration - Edit"
#pragma warning restore AS0011
{
    Assignable = false;
    Access = Public;
    Caption = 'QB Migration - Edit';

    IncludedPermissionSets = "QBMigration - Read";

    Permissions = tabledata "MigrationQB Account" = IMD,
                    tabledata "MigrationQB Customer" = IMD,
                    tabledata "MigrationQB CustomerTrans" = IMD,
                    tabledata "MigrationQB Item" = IMD,
                    tabledata "MigrationQB Account Setup" = IMD,
                    tabledata "MigrationQB Config" = IMD,
                    tabledata "MigrationQB Vendor" = IMD,
                    tabledata "MigrationQB VendorTrans" = IMD;
}
