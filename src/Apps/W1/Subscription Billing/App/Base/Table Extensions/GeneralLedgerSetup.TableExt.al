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
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
            DataClassification = CustomerContent;
            Caption = 'Dimension Code for Customer Subscription Contract';
            TableRelation = Dimension;
        }
    }

}
#endif
