page 135187 "Mock - Sales Invoice Entity"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'salesInvoices', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesInvoice';
    EntitySetName = 'salesInvoices';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Sales Invoice Entity Aggregate";

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
                    Caption = 'Number', Locked = true;
                    Editable = false;
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalDocumentNumber', Locked = true;
                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;
                }
                field(customerPurchaseOrderReference; "Your Reference")
                {
                    ApplicationArea = All;
                    Caption = 'customerPurchaseOrderReference', Locked = true;
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
                field(orderId; "Order Id")
                {
                    ApplicationArea = All;
                    Caption = 'orderId', Locked = true;
                    Editable = false;
                }
                field(orderNumber; "Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'orderNumber', Locked = true;
                    Editable = false;
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
                    ToolTip = 'Specifies the total tax amount for the sales invoice.';
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
                    ToolTip = 'Specifies the status of the Sales Invoice (cancelled, paid, on hold, created).';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                field(phoneNumber; "Sell-to Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'PhoneNumber', Locked = true;
                }
                field(email; "Sell-to E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'Email', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}
