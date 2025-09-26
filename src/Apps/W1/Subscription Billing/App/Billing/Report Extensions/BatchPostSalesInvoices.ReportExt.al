namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Document;

reportextension 8001 BatchPostSalesInvoices extends "Batch Post Sales Invoices"
{
    dataset
    {
        modify("Sales Header")
        {
            trigger OnBeforePostDataItem()
            begin
                if RecurringBillingOnly then
                    "Sales Header".SetRange("Recurring Billing", true);
            end;
        }

    }
    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(RecurringBillingOnly; RecurringBillingOnly)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recurring Billing only';
                    ToolTip = 'Specifies if you want to post invoices automatically created from subscription billing.';
                }
            }
        }
    }
    var
        RecurringBillingOnly: Boolean;
}
