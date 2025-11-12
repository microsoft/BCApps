namespace Microsoft.AccountantPortal;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

page 9023 "Accounting Services RC"
{
    Caption = 'Outsourced Accounting Manager', Comment = 'Use same translation as ''Profile Description'' (if applicable)';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control1; "Accounting Services Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control2; "My Customers")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                action("Sales Quote")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quote';
                    Image = NewSalesQuote;
                    RunObject = Page "Sales Quote";
                    RunPageMode = Create;
                    ToolTip = 'Offer items or services to a customer.';
                }
                action("Sales Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoice';
                    Image = NewSalesInvoice;
                    RunObject = Page "Sales Invoice";
                    RunPageMode = Create;
                    ToolTip = 'Create a new invoice for the sales of items or services. Invoice quantities cannot be posted partially.';
                }
            }
        }
        area(embedding)
        {
            action(Customers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customers';
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            separator(History)
            {
                Caption = 'History';
                IsHeader = true;
            }
            action("Navi&gate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                RunObject = Page Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
            }
            action("Posted Sales Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Invoices';
                RunObject = Page "Posted Sales Invoices";
                ToolTip = 'Open the list of posted sales invoices.';
            }
        }
    }
}

