#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
permissionsetextension 20875 "D365 READQuickBooks Data Migration" extends "D365 READ"
#pragma warning restore AS0011
{
    Permissions = tabledata "MigrationQB Account" = R,
                  tabledata "MigrationQB Account Setup" = R,
                  tabledata "MigrationQB Config" = R,
                  tabledata "MigrationQB Customer" = R,
                  tabledata "MigrationQB CustomerTrans" = R,
                  tabledata "MigrationQB Item" = R,
                  tabledata "MigrationQB Vendor" = R,
                  tabledata "MigrationQB VendorTrans" = R;
}
