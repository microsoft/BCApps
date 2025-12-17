namespace Microsoft.SubscriptionBilling;

using System.Security.User;

pageextension 8017 "User Setup" extends "User Setup"
{
    layout
    {
        addafter("Time Sheet Admin.")
        {
            field("Auto Contract Billing"; Rec."Auto Contract Billing")
            {
                ApplicationArea = All;
                Caption = 'Auto Contract Billing';
            }
        }
    }
}
