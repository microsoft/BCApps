#pragma warning disable AA0247
page 14902 "Vendor Agreement Card"
{
    Caption = 'Vendor Agreement Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Vendor Agreement";

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
                    ToolTip = 'Specifies the code that identifies an external vendor agreement.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not a vendor agreement is active.';
                }
                field("Agreement Date"; Rec."Agreement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of when the vendor agreement becomes effective.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the vendor agreement becomes active.';
                }
                field("Expire Date"; Rec."Expire Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the vendor agreement is no longer active.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this vendor.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s email address.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all completed purchase invoices and credit memos.';

                    trigger OnDrillDown()
                    var
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    begin
                        DtldVendLedgEntry.SetRange("Vendor No.", Rec."Vendor No.");
                        DtldVendLedgEntry.SetRange("Agreement No.", Rec."No.");
                        VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                    end;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
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
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that corresponds to the priority that you give the vendor.';
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
                field("Default Bank Code"; Rec."Default Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customer''s default bank code.';
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
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                }
            }
            group(Receiving)
            {
                Caption = 'Receiving';
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This object supports the Microsoft Dynamics NAV infrastructure and is intended only for internal use.';
                }
            }
            group("VAT Agent")
            {
                Caption = 'VAT Agent';
                field("VAT Agent Prod. Posting Group"; Rec."VAT Agent Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Payment Source Type"; Rec."VAT Payment Source Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Authority No."; Rec."Tax Authority No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the tax authority associated with the vendor.';
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
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = field("Vendor No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Vendor Agreement"),
                                  "No." = field("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(14901),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                }
                separator(Action11)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = field("Vendor No."),
                                  "Agreement Filter" = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Vendor Entry Statistics";
                    RunPageLink = "No." = field("Vendor No."),
                                  "Agreement Filter" = field("No.");
                }
                action(Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases';
                    Image = Purchase;
                    RunObject = Page "Vendor Purchases";
                    RunPageLink = "No." = field("Vendor No."),
                                  "Agreement Filter" = field("No.");
                }
            }
            group("&Purchases")
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action(Quotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    Image = Quote;
                    RunObject = Page "Purchase Quotes";
                    RunPageLink = "Buy-from Vendor No." = field("Vendor No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'View any related purchase quotes. ';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Blanket Orders';
                    Image = BlanketOrder;
                    RunObject = Page "Blanket Purchase Orders";
                    RunPageLink = "Buy-from Vendor No." = field("Vendor No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                }
                action(Orders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Purchase Order List";
                    RunPageLink = "Buy-from Vendor No." = field("Vendor No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.", "No.");
                    ToolTip = 'View any related purchase orders. ';
                }
                action("Return Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Order List";
                    RunPageLink = "Buy-from Vendor No." = field("Vendor No."),
                                  "Agreement No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.", "No.");
                    ToolTip = 'View any related return orders. ';
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
                RunObject = Page "Blanket Purchase Order";
                RunPageMode = Create;
            }
            action("Purchase Quote")
            {
                Caption = 'Purchase Quote';
                Image = Quote;
                RunObject = Page "Purchase Quote";
                RunPageMode = Create;
                ToolTip = 'Create a purchase quote for the vendor.';
            }
            action("Purchase Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoice';
                Image = NewPurchaseInvoice;
                RunObject = Page "Purchase Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a purchase invoice for the vendor.';
            }
            action("Purchase Order")
            {
                Caption = 'Purchase Order';
                Image = Document;
                RunObject = Page "Purchase Order";
                RunPageMode = Create;
                ToolTip = 'Create a purchase order for the vendor.';
            }
            action("Purchase Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit Memo';
                Image = CreditMemo;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Purchase Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a purchase credit memo for the vendor.';
            }
            action("Purchase Return Order")
            {
                Caption = 'Purchase Return Order';
                Image = ReturnOrder;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Purchase Return Order";
                RunPageMode = Create;
                ToolTip = 'Create a purchase return order for the vendor.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref("Purchase Order_Promoted"; "Purchase Order")
                {
                }
                actionref("Purchase Quote_Promoted"; "Purchase Quote")
                {
                }
                actionref("Purchase Invoice_Promoted"; "Purchase Invoice")
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
                actionref(Purchases_Promoted; Purchases)
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

