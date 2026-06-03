namespace System.Security.AccessControl;

using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Data Exp. Primary Key Buffer" = R,
                  tabledata "Data Export" = R,
                  tabledata "Data Export Buffer" = R,
                  tabledata "Data Export Record Definition" = R,
                  tabledata "Data Export Record Field" = R,
                  tabledata "Data Export Record Source" = R,
                  tabledata "Data Export Record Type" = R,
                  tabledata "Data Export Setup" = R,
                  tabledata "Data Export Table Relation" = R,
                  tabledata "Key Buffer" = R,
                  tabledata "Number Series Buffer" = R,
                  tabledata "Place of Dispatcher" = R,
                  tabledata "Place of Receiver" = R;
}