namespace System.Security.AccessControl;

using Microsoft.Bank.Setup;
using Microsoft.Bank.Reconciliation;
using System.IO;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.BankAccount;
using System.Xml;
using Microsoft.Bank.Payment;

permissionset 5047 "SEPA Direct Debit - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'SEPA Direct Debit';

    Permissions = tabledata "Bank Export/Import Setup" = R,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = RIMD,
                  tabledata "Credit Trans Re-export History" = RIMD,
                  tabledata "Credit Transfer Entry" = RIMD,
                  tabledata "Credit Transfer Register" = RIMD,
                  tabledata "Data Exch." = Rimd,
                  tabledata "Data Exch. Column Def" = R,
                  tabledata "Data Exch. Def" = R,
                  tabledata "Data Exch. Field" = Rimd,
                  tabledata "Data Exch. Field Mapping" = R,
                  tabledata "Data Exch. Line Def" = R,
                  tabledata "Data Exch. Mapping" = R,
                  tabledata "Data Exch. Field Grouping" = R,
                  tabledata "Data Exch. FlowField Gr. Buff." = R,
                  tabledata "Data Exchange Type" = Rimd,
                  tabledata "Data Exch. Table Filter" = Rimd,
                  tabledata "Direct Debit Collection" = RIMD,
                  tabledata "Direct Debit Collection Entry" = RIMD,
                  tabledata "Intermediate Data Import" = Rimd,
                  tabledata "Ledger Entry Matching Buffer" = RIMD,
                  tabledata "Outstanding Bank Transaction" = RIMD,
                  tabledata "Payment Application Proposal" = RIMD,
                  tabledata "Payment Export Data" = Rimd,
                  tabledata "Payment Jnl. Export Error Text" = RIMD,
                  tabledata "Payment Matching Details" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "SEPA Direct Debit Mandate" = RIMD,
                  tabledata "XML Buffer" = R,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
