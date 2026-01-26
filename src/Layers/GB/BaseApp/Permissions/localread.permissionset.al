namespace System.Security.AccessControl;

#if not CLEAN28
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
#endif
#if not CLEAN27
using Microsoft.Finance.VAT.Reporting;
#endif
#if not CLEAN28
using Microsoft.Foundation.Address;
using Microsoft.Sales.FinanceCharge;
#endif
permissionset 1002 "LOCAL READ"
{
    Access = Public;
#if CLEAN28
    Assignable = false;
#else
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

#if CLEAN28
    Permissions = tabledata "Accounting Period GB" = R;
#endif
    Permissions = tabledata "Accounting Period GB" = R,
                  tabledata "BACS Ledger Entry" = R,
                  tabledata "BACS Register" = R,
                  tabledata "Fin. Charge Interest Rate" = R,
#if not CLEAN27
                  tabledata "GovTalk Message Parts" = R,
                  tabledata "GovTalk Setup" = r,
                  tabledata GovTalkMessage = R,
#endif
                  tabledata "Postcode Notification Memory" = R;
#endif
}