namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Intrastat;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Bank Directory" = RIMD,
                  tabledata "Data Exp. Primary Key Buffer" = RIMD,
                  tabledata "Data Export" = RIMD,
                  tabledata "Data Export Buffer" = RIMD,
                  tabledata "Data Export Record Definition" = RIMD,
                  tabledata "Data Export Record Field" = RIMD,
                  tabledata "Data Export Record Source" = RIMD,
                  tabledata "Data Export Record Type" = RIMD,
                  tabledata "Data Export Setup" = RIMD,
                  tabledata "Data Export Table Relation" = RIMD,
                  tabledata "DTA Setup" = RIMD,
                  tabledata "ESR Setup" = RIMD,
                  tabledata "Key Buffer" = RIMD,
                  tabledata "LSV Journal" = RIMD,
                  tabledata "LSV Journal Line" = RIMD,
                  tabledata "LSV Setup" = RIMD,
                  tabledata "Number Series Buffer" = RIMD,
                  tabledata "Place of Dispatcher" = RIMD,
                  tabledata "Place of Receiver" = RIMD,
                  tabledata "VAT Cipher Code" = RIMD,
                  tabledata "VAT Cipher Setup" = RIMD,
                  tabledata "VAT Currency Adjustment Buffer" = RIMD;
}