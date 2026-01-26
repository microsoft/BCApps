namespace System.Security.AccessControl;

using Microsoft;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "340 Declaration Line" = R,
                  tabledata "Acc. Schedule Buffer" = R,
                  tabledata "AEAT Transference Format" = R,
                  tabledata "AEAT Transference Format XML" = R,
                  tabledata "BG/PO Comment Line" = R,
                  tabledata "BG/PO Post. Buffer" = R,
                  tabledata "Bill Group" = R,
                  tabledata "Cartera Doc." = R,
                  tabledata "Cartera Report Selections" = R,
                  tabledata "Cartera Setup" = R,
                  tabledata "Category Code" = R,
                  tabledata "Closed Bill Group" = R,
                  tabledata "Closed Cartera Doc." = R,
                  tabledata "Closed Payment Order" = R,
                  tabledata "Customer Cash Buffer" = R,
                  tabledata "Customer Rating" = R,
                  tabledata "Customer/Vendor Warning 349" = R,
                  tabledata "Doc. Post. Buffer" = R,
                  tabledata "Fee Range" = R,
                  tabledata "G/L Account Buffer" = R,
                  tabledata "Gen. Prod. Post. Group Buffer" = R,
                  tabledata "Inc. Stmt. Clos. Buffer" = R,
                  tabledata Installment = R,
                  tabledata "No Taxable Entry" = R,
                  tabledata "Non-Payment Period" = R,
                  tabledata "Operation Code" = R,
                  tabledata "Operation Fee" = R,
                  tabledata "Payment Day" = R,
                  tabledata "Payment Order" = R,
                  tabledata "Posted Bill Group" = R,
                  tabledata "Posted Cartera Doc." = R,
                  tabledata "Posted Payment Order" = R,
                  tabledata "Sales/Purch. Book VAT Buffer" = R,
                  tabledata "Selected G/L Accounts" = R,
                  tabledata "Selected Gen. Prod. Post. 340" = R,
                  tabledata "Selected Gen. Prod. Post. Gr." = R,
                  tabledata "Selected Rev. Charge Grp. 340" = R,
                  tabledata "SII Doc. Upload State" = R,
                  tabledata "SII History" = R,
                  tabledata "SII Purch. Doc. Scheme Code" = R,
                  tabledata "SII Sales Document Scheme Code" = R,
                  tabledata "SII Missing Entries State" = R,
                  tabledata "SII Session" = R,
                  tabledata "SII Setup" = R,
                  tabledata "Statistical Code" = R,
                  tabledata Suffix = R;
}