namespace System.Security.AccessControl;

using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Intrastat;
using Microsoft.Purchases.Document;

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
                  tabledata "Delivery Reminder Comment Line" = R,
                  tabledata "Delivery Reminder Header" = R,
                  tabledata "Delivery Reminder Ledger Entry" = R,
                  tabledata "Delivery Reminder Level" = R,
                  tabledata "Delivery Reminder Line" = R,
                  tabledata "Delivery Reminder Term" = R,
                  tabledata "Delivery Reminder Text" = R,
                  tabledata "Issued Deliv. Reminder Header" = R,
                  tabledata "Issued Deliv. Reminder Line" = R,
                  tabledata "Key Buffer" = R,
                  tabledata "Number Series Buffer" = R,
                  tabledata "Place of Dispatcher" = R,
                  tabledata "Place of Receiver" = R;
}