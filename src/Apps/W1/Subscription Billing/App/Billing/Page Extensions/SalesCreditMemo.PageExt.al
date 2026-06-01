namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Document;

pageextension 8067 "Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {
        addlast("Credit Memo Details")
        {
            field("Contract Detail Overview"; Rec."Sub. Contract Detail Overview")
            {
                ApplicationArea = Basic, Suite;
                Enabled = Rec."Recurring Billing";
            }
            field("Auto Contract Billing"; Rec."Auto Contract Billing")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
        }
    }
}