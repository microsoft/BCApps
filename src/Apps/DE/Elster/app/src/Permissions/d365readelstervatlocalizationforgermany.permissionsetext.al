#pragma warning disable AA0247
#pragma warning disable AS0011 // Accepted: renaming this existing object to add the mandatory affix would break references. Tracked by AB#640773.
permissionsetextension 9615 "D365 READ - ELSTER VAT Localization for Germany" extends "D365 READ"
#pragma warning restore AS0011
{
    Permissions = tabledata "Elec. VAT Decl. Setup" = R,
                  tabledata "Sales VAT Advance Notif." = R,
                  tabledata "Elec. VAT Decl. Buffer" = R;
}
