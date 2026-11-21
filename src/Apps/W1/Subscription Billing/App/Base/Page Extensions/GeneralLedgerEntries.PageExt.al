namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.GeneralLedger.Ledger;

pageextension 8087 "General Ledger Entries" extends "General Ledger Entries"
{
    layout
    {
        addafter("External Document No.")
        {
            field("Contract No."; Rec."Subscription Contract No.")
            {
                ApplicationArea = All;
            }
        }
    }
}
