namespace System.Security.AccessControl;

#if not CLEAN28
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
#endif
#if not CLEAN27
using Microsoft.Finance.VAT.Reporting;
#endif
using Microsoft.Foundation.Address;
using Microsoft.Sales.FinanceCharge;

permissionset 1001 "LOCAL"
{
    Access = Public;
#if CLEAN28
    Assignable = false;
    Permissions = tabledata "Fin. Charge Interest Rate" = RIMD,
                  tabledata "Postcode Notification Memory" = RIMD;
#else
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "Accounting Period GB" = RIMD,
                  tabledata "BACS Ledger Entry" = RIMD,
                  tabledata "BACS Register" = RIMD,
                  tabledata "Fin. Charge Interest Rate" = RIMD,
#if not CLEAN27
                  tabledata "GovTalk Message Parts" = RIMD,
                  tabledata "GovTalk Setup" = r,
                  tabledata GovTalkMessage = RIMD,
#endif
                  tabledata "Postcode Notification Memory" = RIMD;
#endif
}