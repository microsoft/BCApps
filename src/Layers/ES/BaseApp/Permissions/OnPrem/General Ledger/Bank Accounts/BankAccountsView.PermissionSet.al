namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

permissionset 1083 "Bank Accounts - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read bank accounts and entries';

    Permissions = tabledata "Bank Account" = R,
                  tabledata "Bank Account Ledger Entry" = R,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Bank Account Statement" = R,
                  tabledata "Bank Account Statement Line" = R,
                  tabledata "Bill Group" = R,
                  tabledata "Cartera Doc." = R,
                  tabledata "Check Ledger Entry" = R,
                  tabledata "Closed Bill Group" = R,
                  tabledata "Closed Cartera Doc." = R,
                  tabledata "Closed Payment Order" = R,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Payment Order" = R,
                  tabledata "Posted Bill Group" = R,
                  tabledata "Posted Cartera Doc." = R,
                  tabledata "Posted Payment Order" = R;
}
