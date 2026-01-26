namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Bank Account Buffer" = R,
                  tabledata "FR Acc. Schedule Line" = R,
                  tabledata "FR Acc. Schedule Name" = R,
                  tabledata "Payment Address" = R,
                  tabledata "Payment Class" = R,
                  tabledata "Payment Header" = R,
                  tabledata "Payment Header Archive" = R,
                  tabledata "Payment Line" = R,
                  tabledata "Payment Line Archive" = R,
                  tabledata "Payment Post. Buffer" = R,
                  tabledata "Payment Status" = R,
                  tabledata "Payment Step" = R,
                  tabledata "Payment Step Ledger" = R,
                  tabledata "Shipment Invoiced" = R,
                  tabledata "Unreal. CV Ledg. Entry Buffer" = R;
}
