namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.History;

pageextension 8068 "Posted Sales Invoice" extends "Posted Sales Invoice"
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