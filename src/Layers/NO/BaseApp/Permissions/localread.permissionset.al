namespace System.Security.AccessControl;

using Microsoft.Bank.DirectDebit;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "E-Invoice Export Header" = R,
                  tabledata "E-Invoice Export Line" = R,
                  tabledata "E-Invoice Transfer File" = R,
                  tabledata "Gen. Jnl. Line Reg. Rep. Code" = R,
                  tabledata "OCR Setup" = R,
                  tabledata "Payment Order Data" = R,
                  tabledata "Payment Type Code Abroad" = R,
                  tabledata "Recurring Group" = R,
                  tabledata "Recurring Post" = R,
                  tabledata "Regulatory Reporting Code" = R,
                  tabledata "Remittance Account" = R,
                  tabledata "Remittance Agreement" = R,
                  tabledata "Remittance Payment Order" = R,
                  tabledata "Return Error" = R,
                  tabledata "Return File" = R,
                  tabledata "Return File Setup" = R,
                  tabledata "Settled VAT Period" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Specification" = R,
                  tabledata "VAT Note" = R,
                  tabledata "VAT Period" = R,
                  tabledata "Waiting Journal" = R;
}
