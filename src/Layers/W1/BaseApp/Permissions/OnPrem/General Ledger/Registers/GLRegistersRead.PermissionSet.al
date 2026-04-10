namespace System.Security.AccessControl;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

permissionset 6912 "G/L Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L registers';

    Permissions = tabledata "Bank Account Ledger Entry" = R,
                  tabledata "G/L Entry - VAT Entry Link" = R,
                  tabledata "G/L Entry" = R,
                  tabledata "G/L Register" = R,
                  tabledata "VAT Entry" = R;
}
