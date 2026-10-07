#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
permissionset 27227 "QBMigration - Read"
#pragma warning restore AS0011
{
    Assignable = false;
    Access = Public;
    Caption = 'QB Migration - Read';

    IncludedPermissionSets = "QBMigration - Objects";

    Permissions = tabledata "MigrationQB Account" = R,
                    tabledata "MigrationQB Customer" = R,
                    tabledata "MigrationQB CustomerTrans" = R,
                    tabledata "MigrationQB Item" = R,
                    tabledata "MigrationQB Account Setup" = R,
                    tabledata "MigrationQB Config" = R,
                    tabledata "MigrationQB Vendor" = R,
                    tabledata "MigrationQB VendorTrans" = R;
}
