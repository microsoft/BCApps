page 135188 "Mock - Sales Cr. Memo Entity"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'salesCreditMemos', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesCreditMemo';
    EntitySetName = 'salesCreditMemos';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Sales Cr. Memo Entity Buffer";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                    Editable = false;
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalDocumentNumber', Locked = true;
                }
                field(creditMemoDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'creditMemoDate', Locked = true;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;
                }
                field(contactId; "Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'contactId', Locked = true;
                }
                field(customerNumber; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNumber', Locked = true;
                }
                field(customerName; "Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'customerName', Locked = true;
                    Editable = false;
                }
                field(currencyId; "Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'CurrencyId', Locked = true;
                }
                field(paymentTermsId; "Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'PaymentTermsId', Locked = true;
                }
                field(shipmentMethodId; "Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'ShipmentMethodId', Locked = true;
                }
                field(salesperson; "Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'salesperson', Locked = true;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;
                    Editable = false;
                }
                field(discountAmount; "Invoice Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'discountAmount', Locked = true;
                }
                field(discountAppliedBeforeTax; "Discount Applied Before Tax")
                {
                    ApplicationArea = All;
                    Caption = 'discountAppliedBeforeTax', Locked = true;
                    Editable = false;
                }
                field(totalAmountExcludingTax; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountExcludingTax', Locked = true;
                    Editable = false;
                }
                field(totalTaxAmount; "Total Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'totalTaxAmount', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the total tax amount for the sales credit memo.';
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;
                    Editable = false;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the status of the Sales Credit Memo (cancelled, paid, on hold, created).';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                field(invoiceNumber; "Applies-to Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceNumber', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}
