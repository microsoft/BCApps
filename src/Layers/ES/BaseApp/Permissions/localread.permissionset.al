namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.AuditCodes;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "340 Declaration Line" = R,
                  tabledata "Acc. Schedule Buffer" = R,
                  tabledata "AEAT Transference Format" = R,
                  tabledata "AEAT Transference Format XML" = R,
                  tabledata "Category Code" = R,
                  tabledata "Customer Cash Buffer" = R,
                  tabledata "Customer/Vendor Warning 349" = R,
                  tabledata "G/L Account Buffer" = R,
                  tabledata "Gen. Prod. Post. Group Buffer" = R,
                  tabledata "Inc. Stmt. Clos. Buffer" = R,
                  tabledata "No Taxable Entry" = R,
                  tabledata "Operation Code" = R,
                  tabledata "Sales/Purch. Book VAT Buffer" = R,
                  tabledata "Selected G/L Accounts" = R,
                  tabledata "Selected Gen. Prod. Post. 340" = R,
                  tabledata "Selected Gen. Prod. Post. Gr." = R,
                  tabledata "Selected Rev. Charge Grp. 340" = R,
                  tabledata "Statistical Code" = R;
}