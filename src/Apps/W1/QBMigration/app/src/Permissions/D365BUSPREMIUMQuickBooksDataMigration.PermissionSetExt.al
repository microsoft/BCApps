#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
permissionsetextension 44603 "D365 BUS PREMIUMQuickBooks Data Migration" extends "D365 BUS PREMIUM"
#pragma warning restore AS0011
{
    Permissions = tabledata "MigrationQB Account" = RIMD,
                  tabledata "MigrationQB Account Setup" = RIMD,
                  tabledata "MigrationQB Config" = RIMD,
                  tabledata "MigrationQB Customer" = RIMD,
                  tabledata "MigrationQB CustomerTrans" = RIMD,
                  tabledata "MigrationQB Item" = RIMD,
                  tabledata "MigrationQB Vendor" = RIMD,
                  tabledata "MigrationQB VendorTrans" = RIMD;
}
