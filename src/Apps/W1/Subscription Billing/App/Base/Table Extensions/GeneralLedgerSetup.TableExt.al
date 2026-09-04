#if not CLEANSCHEMA29
namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

tableextension 8051 "General Ledger Setup" extends "General Ledger Setup"
{
    fields
    {
        field(8051; "Dimension Code Cust. Contr."; Code[20])
        {
            ObsoleteReason = 'Moved to Subscription Contract Setup.';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
#pragma warning disable AS0072 // Bug 647877: temporary v30 suppression, restore ObsoleteTag to 30.0
            ObsoleteTag = '29.0';
#pragma warning restore AS0072
#endif
            DataClassification = CustomerContent;
            Caption = 'Dimension Code for Customer Subscription Contract';
            TableRelation = Dimension;
        }
    }

}
#endif
