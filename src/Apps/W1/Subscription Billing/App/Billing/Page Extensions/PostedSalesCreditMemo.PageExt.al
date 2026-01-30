namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.History;

pageextension 8069 "Posted Sales Credit Memo" extends "Posted Sales Credit Memo"
{
    layout
    {
        addlast("Invoice Details")
        {
            field("Contract Detail Overview"; Rec."Sub. Contract Detail Overview")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Auto Contract Billing"; Rec."Auto Contract Billing")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
        }
    }
}