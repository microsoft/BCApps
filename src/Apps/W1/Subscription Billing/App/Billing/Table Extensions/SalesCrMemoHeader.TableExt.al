namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.History;

tableextension 8057 "Sales Cr. Memo Header" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(8051; "Recurring Billing"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Recurring Billing';
            ToolTip = 'Specifies whether the document was created by Subscription Billing.';
            Editable = false;
        }
        field(8052; "Sub. Contract Detail Overview"; Enum "Contract Detail Overview")
        {
            Caption = 'Subscription Contract Detail Overview';
            ToolTip = 'Specifies whether to automatically print the billing details for this document. This is only relevant if you are using Subscription Billing functionalities.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8053; "Auto Contract Billing"; Boolean)
        {
            Caption = 'Auto Contract Billing';
            ToolTip = 'Specifies whether the Document has been created by an auto billing template.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
}