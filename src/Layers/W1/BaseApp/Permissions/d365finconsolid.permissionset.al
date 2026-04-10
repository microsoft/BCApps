namespace System.Security.AccessControl;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Ledger;

permissionset 739 "D365 Fin. Consolid"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 Business Central Financial Consolidations';

    Permissions = tabledata "Business Unit" = R,
                    tabledata "Consolidation Setup" = RI,
                    tabledata "Consolidation Process" = RIM,
                    tabledata "Bus. Unit In Cons. Process" = RIM,
                    tabledata "G/L Entry" = rimd,
                    tabledata "Consolidation Log Entry" = R;
}