namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.ReceivablesPayables;

tableextension 8101 "Invoice Posting Buffer" extends "Invoice Posting Buffer"
{
    fields
    {
        field(8051; "Subscription Contract No."; Code[20])
        {
            Caption = 'Subscription Contract No.';
            DataClassification = SystemMetadata;
        }
    }
}
