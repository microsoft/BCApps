namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.AuditCodes;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "340 Declaration Line" = RIMD,
                  tabledata "Acc. Schedule Buffer" = RIMD,
                  tabledata "AEAT Transference Format" = RIMD,
                  tabledata "AEAT Transference Format XML" = RIMD,
                  tabledata "Category Code" = RIMD,
                  tabledata "Customer Cash Buffer" = RIMD,
                  tabledata "Customer/Vendor Warning 349" = RIMD,
                  tabledata "G/L Account Buffer" = RIMD,
                  tabledata "Gen. Prod. Post. Group Buffer" = RIMD,
                  tabledata "Inc. Stmt. Clos. Buffer" = RIMD,
                  tabledata "No Taxable Entry" = Rimd,
                  tabledata "Operation Code" = RIMD,
                  tabledata "Sales/Purch. Book VAT Buffer" = RIMD,
                  tabledata "Selected G/L Accounts" = RIMD,
                  tabledata "Selected Gen. Prod. Post. 340" = RIMD,
                  tabledata "Selected Gen. Prod. Post. Gr." = RIMD,
                  tabledata "Selected Rev. Charge Grp. 340" = RIMD,
                  tabledata "Statistical Code" = RIMD;
}