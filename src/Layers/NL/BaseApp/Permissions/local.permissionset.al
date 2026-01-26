namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Review;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Audit File Buffer" = RIMD,
                  tabledata "CBG Statement" = RIMD,
                  tabledata "CBG Statement Line" = RIMD,
                  tabledata "CBG Statement Line Add. Info." = RIMD,
                  tabledata "Detail Line" = RIMD,
                  tabledata "Elec. Tax Decl. Error Log" = RIMD,
                  tabledata "Elec. Tax Decl. Response Msg." = RIMD,
                  tabledata "Elec. Tax Decl. VAT Category" = RIMD,
                  tabledata "Elec. Tax Declaration Header" = RIMD,
                  tabledata "Elec. Tax Declaration Line" = RIMD,
                  tabledata "Elec. Tax Declaration Setup" = RIMD,
                  tabledata "Export Protocol" = RIMD,
                  tabledata "Freely Transferable Maximum" = RIMD,
                  tabledata "G/L Entry Application Buffer" = RIMD,
                  tabledata "Import Protocol" = RIMD,
                  tabledata "Payment History" = RIMD,
                  tabledata "Payment History Export Buffer" = RIMD,
                  tabledata "Payment History Line" = RIMD,
                  tabledata "Post Code Range" = RIMD,
                  tabledata "Post Code Update Log Entry" = RIMD,
                  tabledata "Proposal Line" = RIMD,
                  tabledata "Reconciliation Buffer" = RIMD,
                  tabledata "Reporting ICP" = RIMD,
                  tabledata "Transaction Mode" = RIMD;
}
