namespace System.Security.AccessControl;

#if not CLEAN28
using Microsoft.Bank.Payment;
#endif
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions =
#if not CLEAN28
                  tabledata "Bank Account Buffer" = RIMD,
#endif
                  tabledata "FR Acc. Schedule Line" = RIMD,
                  tabledata "FR Acc. Schedule Name" = RIMD,
#if not CLEAN28
                  tabledata "Payment Address" = RIMD,
                  tabledata "Payment Class" = RIMD,
                  tabledata "Payment Header" = RIMD,
                  tabledata "Payment Header Archive" = RIMD,
                  tabledata "Payment Line" = RIMD,
                  tabledata "Payment Line Archive" = RIMD,
                  tabledata "Payment Post. Buffer" = RIMD,
                  tabledata "Payment Status" = RIMD,
                  tabledata "Payment Step" = RIMD,
                  tabledata "Payment Step Ledger" = RIMD,
#endif
                  tabledata "Shipment Invoiced" = RIMD,
                  tabledata "Unreal. CV Ledg. Entry Buffer" = RIMD;
}
