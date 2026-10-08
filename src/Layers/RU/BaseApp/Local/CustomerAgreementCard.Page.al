#pragma warning disable AA0247
page 14901 "Customer Agreement Card"
{
    Caption = 'Customer Agreement Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Customer Agreement";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the agreement.';
                }
                field("External Agreement No."; Rec."External Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the customer agreement.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a customer agreement is active.';
                }
                field("Agreement Date"; Rec."Agreement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of when the customer agreement becomes effective.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Expire Date"; Rec."Expire Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that date that a customer agreement is no longer active.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this customer.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s email address.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                    trigger OnDrillDown()
                    var
                        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                    begin
                        DtldCustLedgEntry.SetRange("Customer No.", Rec."Customer No.");
                        DtldCustLedgEntry.SetRange("Agreement No.", Rec."No.");
                        CustLedgEntry.DrillDownOnEntries(DtldCustLedgEntry);
                    end;
                }
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum credit (in LCY) that can be extended to the customer.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Agreement Group"; Rec."Agreement Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer agreement group to which a customer agreement belongs.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Default Bank Code"; Rec."Default Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the default customer bank account.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                }
                field("Customer Price Group"; Rec."Customer Price Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer price group code.';
                }
                field("Customer Disc. Group"; Rec."Customer Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer discount group code.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer accepts partial shipment of orders.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("A&greement")
            {
                Caption = 'A&greement';
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GL;
                    RunObject = Page "Customer Ledger Entries";
                    RunPageLink = "Customer No." = field("Customer No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Customer No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Customer Agreement"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(14902),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                separator(Action100)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = field("Customer No."),
                                  "Agreement Filter" = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Customer Entry Statistics";
                    RunPageLink = "No." = field("Customer No."),
                                  "Agreement Filter" = field("No.");
                    ToolTip = 'View entry statistics for the record.';
                }
                action("S&ales")
                {
                    ApplicationArea = Suite;
                    Caption = 'S&ales';
                    Image = Sales;
                    RunObject = Page "Customer Sales";
                    RunPageLink = "No." = field("Customer No."),
                                  "Agreement Filter" = field("No.");
                }
            }
            group(Action82)
            {
                Caption = 'S&ales';
                Image = Sales;
                action(Quotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    Image = Quote;
                    RunObject = Page "Sales Quotes";
                    RunPageLink = "Sell-to Customer No." = field("Customer No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Sell-to Customer No.", "No.");
                    ToolTip = 'View any related sales quotes. ';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Blanket Orders';
                    Image = BlanketOrder;
                    RunObject = Page "Blanket Sales Orders";
                    RunPageLink = "Sell-to Customer No." = field("Customer No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Sell-to Customer No.");
                    ToolTip = 'View any related blanket sales orders. ';
                }
                action(Orders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Sales Order List";
                    RunPageLink = "Sell-to Customer No." = field("Customer No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Sell-to Customer No.", "No.");
                    ToolTip = 'View any related sales orders. ';
                }
                action("Return Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Sales Return Order List";
                    RunPageLink = "Sell-to Customer No." = field("Customer No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Sell-to Customer No.", "No.");
                    ToolTip = 'View any related sales return orders. ';
                }
                action("Service Orders")
                {
                    Caption = 'Service Orders';
                    Image = Document;
                    RunObject = Page "Service Orders";
                    RunPageLink = "Customer No." = field("Customer No.");
                    RunPageView = sorting("Document Type", "Customer No.");
                    ToolTip = 'View any related service orders. ';
                }
            }
        }
        area(creation)
        {
            action("Blanket Sales Order")
            {
                Caption = 'Blanket Sales Order';
                Image = BlanketOrder;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Blanket Sales Order";
                RunPageMode = Create;
                ToolTip = 'Create a blanket sales order for the customer.';
            }
            action("Sales Quote")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Quote';
                Image = NewSalesQuote;
                RunObject = Page "Sales Quote";
                RunPageMode = Create;
                ToolTip = 'Create a sales quote for the customer.';
            }
            action("Sales Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoice';
                Image = NewSalesInvoice;
                RunObject = Page "Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a sales invoice order for the customer.';
            }
            action("Sales Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Order';
                Image = Document;
                RunObject = Page "Sales Order";
                RunPageMode = Create;
                ToolTip = 'Create a sales order for the customer.';
            }
            action("Sales Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Credit Memo';
                Image = CreditMemo;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Sales Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a sales credit memo for the customer.';
            }
            action("Sales Return Order")
            {
                Caption = 'Sales Return Order';
                Image = ReturnOrder;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Sales Return Order";
                RunPageMode = Create;
                ToolTip = 'Create a sales return order for the customer.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref("Sales Order_Promoted"; "Sales Order")
                {
                }
                actionref("Sales Quote_Promoted"; "Sales Quote")
                {
                }
                actionref("Sales Invoice_Promoted"; "Sales Invoice")
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("S&ales_Promoted"; "S&ales")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        RecordFound: Boolean;
    begin
        RecordFound := Rec.Find(Which);
        CurrPage.Editable := RecordFound or (Rec.GetFilter("No.") = '');
        exit(RecordFound);
    end;
}

