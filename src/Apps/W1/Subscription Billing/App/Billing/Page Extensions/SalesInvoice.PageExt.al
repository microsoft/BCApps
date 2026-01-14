namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Document;

pageextension 8066 "Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        addlast("Invoice Details")
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