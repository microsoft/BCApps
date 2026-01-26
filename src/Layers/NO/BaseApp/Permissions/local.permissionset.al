namespace System.Security.AccessControl;

using Microsoft.Bank.DirectDebit;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "E-Invoice Export Header" = RIMD,
                  tabledata "E-Invoice Export Line" = RIMD,
                  tabledata "E-Invoice Transfer File" = RIMD,
                  tabledata "Gen. Jnl. Line Reg. Rep. Code" = RIMD,
                  tabledata "OCR Setup" = RIMD,
                  tabledata "Payment Order Data" = RIMD,
                  tabledata "Payment Type Code Abroad" = RIMD,
                  tabledata "Recurring Group" = RIMD,
                  tabledata "Recurring Post" = RIMD,
                  tabledata "Regulatory Reporting Code" = RIMD,
                  tabledata "Remittance Account" = RIMD,
                  tabledata "Remittance Agreement" = RIMD,
                  tabledata "Remittance Payment Order" = RIMD,
                  tabledata "Return Error" = RIMD,
                  tabledata "Return File" = RIMD,
                  tabledata "Return File Setup" = RIMD,
                  tabledata "Settled VAT Period" = RIMD,
                  tabledata "VAT Reporting Code" = RIMD,
                  tabledata "VAT Specification" = RIMD,
                  tabledata "VAT Note" = RIMD,
                  tabledata "VAT Period" = RIMD,
                  tabledata "Waiting Journal" = RIMD;
}
