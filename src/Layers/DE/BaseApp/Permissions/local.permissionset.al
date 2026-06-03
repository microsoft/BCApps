namespace System.Security.AccessControl;

using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Data Exp. Primary Key Buffer" = RIMD,
                  tabledata "Data Export" = RIMD,
                  tabledata "Data Export Buffer" = RIMD,
                  tabledata "Data Export Record Definition" = RIMD,
                  tabledata "Data Export Record Field" = RIMD,
                  tabledata "Data Export Record Source" = RIMD,
                  tabledata "Data Export Record Type" = RIMD,
                  tabledata "Data Export Setup" = RIMD,
                  tabledata "Data Export Table Relation" = RIMD,
                  tabledata "Key Buffer" = RIMD,
                  tabledata "Number Series Buffer" = RIMD,
                  tabledata "Place of Dispatcher" = RIMD,
                  tabledata "Place of Receiver" = RIMD;
}