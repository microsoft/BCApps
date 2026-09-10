namespace System.Security.AccessControl;

#if not CLEAN28
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
#endif
#if not CLEAN28
using Microsoft.Foundation.Address;
using Microsoft.Sales.FinanceCharge;
#endif

permissionset 1001 "LOCAL"
{
    Access = Public;
#if CLEAN28
    Assignable = false;
#else
    Assignable = true;
    Caption = 'Country/region-specific func.';

#if CLEAN28
    Permissions = tabledata "Accounting Period GB" = RIMD;
#endif
    Permissions = tabledata "Accounting Period GB" = RIMD,
                  tabledata "BACS Ledger Entry" = RIMD,
                  tabledata "BACS Register" = RIMD,
                  tabledata "Fin. Charge Interest Rate" = RIMD,
                  tabledata "Postcode Notification Memory" = RIMD;
#endif
}