#pragma warning disable AA0247
page 35603 Vendors
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendors';
    CardPageID = "Vendor Card";
    Editable = false;
    PageType = List;
    SourceTable = Vendor;
    SourceTableView = sorting("Vendor Type", "No.")
                      where("Vendor Type" = const(Vendor));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
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
                field("Post Code"; Rec."Post Code")
                {
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ToolTip = 'Specifies the fax number.';
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                    Visible = false;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency code for the record.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ToolTip = 'Specifies when the record was last modified.';
                    Visible = false;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ToolTip = 'Specifies how to apply payments to entries for this vendor.';
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    Visible = false;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ToolTip = 'Specifies a customizable calendar for delivery planning that holds the vendor''s working days and holidays.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1901138007; "Vendor Details FactBox")
            {
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            part(Control1904651607; "Vendor Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1903435607; "Vendor Hist. Buy-from FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1906949207; "Vendor Hist. Pay-to FactBox")
            {
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ven&dor")
            {
                Caption = 'Ven&dor';
                Image = Vendor;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';

                    trigger OnAction()
                    var
                        Vend: Record Vendor;
                    begin
                        Vend.Copy(Rec);
                        case Vend."Vendor Type" of
                            Vend."Vendor Type"::Vendor:
                                PAGE.Run(PAGE::"Vendor Card", Vend);
                            Vend."Vendor Type"::"Resp. Employee":
                                PAGE.Run(PAGE::"Resp. Employee Card", Vend);
                            Vend."Vendor Type"::"Tax Authority":
                                PAGE.Run(PAGE::"Tax Authority/Fund Card", Vend);
                        end;
                    end;
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Vendor),
                                  "No." = field("No.");
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(23),
                                      "No." = field("No.");
                        ShortCutKey = 'Shift+Ctrl+D';
                    }
                    action("Dimensions-&Multiple")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;

                        trigger OnAction()
                        var
                            Vend: Record Vendor;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Vend);
                            DefaultDimMultiple.SetMultiRecord(Vend, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = field("No.");
                }
                action("Order &Addresses")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Addresses';
                    Image = Addresses;
                    RunObject = Page "Order Address List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View a list of alternate order addresses for the vendor.';
                }
                action(Agreements)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Agreements';
                    Image = Agreement;
                    RunObject = Page "Vendor Agreements";
                    RunPageLink = "Vendor No." = field("No.");
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;

                    trigger OnAction()
                    begin
                        Rec.ShowContact();
                    end;
                }
                separator(Action55)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Vendor Entry Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                }
                action(Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases';
                    Image = Purchase;
                    RunObject = Page "Vendor Purchases";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                }
                separator(Action61)
                {
                }
                separator(Action1470000)
                {
                }
                action("Copy from Customer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy from Customer';
                    Image = Copy;

                    trigger OnAction()
                    begin
                        Rec.CopyFromCustomer(Rec);
                    end;
                }
            }
            group("&Purchases")
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action(Items)
                {
                    ApplicationArea = Suite;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Vendor Item Catalog";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                }
                action("Invoice &Discounts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Invoice &Discounts';
                    Image = CalculateInvoiceDiscount;
                    RunObject = Page "Vend. Invoice Discounts";
                    RunPageLink = Code = field("Invoice Disc. Code");
                    ToolTip = 'Set up different discounts applied to invoices for the selected customer. An invoice discount is automatically granted to the customer when the total on a sales invoice exceeds a certain amount.';
                }
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Price Lists';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up purchase price lists for products that you buy from the vendor. An product price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, "Price Amount Type"::Any);
                    end;
                }
                action(PriceLines)
                {
                    AccessByPermission = TableData "Purchase Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up purchase price lines for products that you buy from the vendor. A product price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, "Price Amount Type"::Price);
                    end;
                }
                action(DiscountLines)
                {
                    AccessByPermission = TableData "Purchase Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you buy from the vendor. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, "Price Amount Type"::Discount);
                    end;
                }
                action(Prices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prices';
                    Image = ResourcePrice;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'View or set up different prices for items that you buy from the vendor. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line Discounts';
                    Image = LineDiscount;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'View or set up different discounts for items that you buy from the vendor. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Purchase Prepmt. Percentages";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action("S&td. Vend. Purchase Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'S&td. Vend. Purchase Codes';
                    Image = CodesList;
                    RunObject = Page "Standard Vendor Purchase Codes";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View or edit recurring purchase lines for the vendor.';
                }
                separator(Action65)
                {
                }
                action(Quotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    Image = Quote;
                    RunObject = Page "Purchase Quotes";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'View any related purchase quotes. ';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Blanket Orders';
                    Image = BlanketOrder;
                    RunObject = Page "Blanket Purchase Orders";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                }
                action(Orders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Purchase Order List";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.", "No.");
                    ToolTip = 'View any related purchase orders. ';
                }
                action("Return Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Order List";
                    ToolTip = 'View any related return orders. ';
                }
                action("Item &Tracking Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    var
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(2, Rec."No.", '', '', '');
                    end;
                }
            }
            action("Vendor G/L Turnover")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor G/L Turnover';
                Image = GL;
                RunObject = Page "Vendor G/L Turnover";
                RunPageLink = "No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Analyze vendors'' turnover and account balances.';
            }
        }
        area(creation)
        {
            action(New)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Image = NewDocument;
                RunObject = Page "Vendor Card";
                RunPageMode = Create;
                ToolTip = 'Create a new vendor card.';
            }
            action("Blanket Purchase Order")
            {
                Caption = 'Blanket Purchase Order';
                Image = BlanketOrder;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Blanket Purchase Order";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
            }
            action("Purchase Quote")
            {
                Caption = 'Purchase Quote';
                Image = Quote;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "Purchase Quote";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a purchase quote for the vendor.';
            }
            action("Purchase Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoice';
                Image = NewPurchaseInvoice;
                RunObject = Page "Purchase Invoice";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a purchase invoice for the vendor.';
            }
            action("Purchase Order")
            {
                Caption = 'Purchase Order';
                Image = Document;
                RunObject = Page "Purchase Order";
                RunPageLink = "Buy-from Vendor No." = field("No.");
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
                RunPageLink = "Buy-from Vendor No." = field("No.");
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
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a purchase return order for the vendor.';
            }
        }
        area(processing)
        {
            action("Payment Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journal';
                Image = PaymentJournal;
                RunObject = Page "Payment Journal";
            }
            action("Purchase Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Journal';
                Image = Journals;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Purchase Journal";
            }
        }
        area(reporting)
        {
#if not CLEAN28

            action("Vendor - List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - List";
                ToolTip = 'View various kinds of basic information for vendors, such as vendor posting group, discount and payment information, priority level and the vendor''s default currency, and the vendor''s current balance (in LCY). The report can be used, for example, to maintain the information in the Vendor table.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor Register")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Register';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor Register";
            }
            action("Vendor - Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Detail Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - Detail Trial Balance";
                ToolTip = 'View the balance for vendors with balances on a specified date, for example, at the close of an accounting period or for an audit.';
            }
#if not CLEAN28
            action("Vendor - Summary Aging")
            {
                Caption = 'Vendor - Summary Aging';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - Summary Aging";
                ToolTip = 'View a summary of the payables owed to each vendor, divided into three time periods.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor - Order Summary")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Order Summary';
                Image = "Report";
                RunObject = Report "Vendor - Order Summary";
                ToolTip = 'View the order detail (the quantity not yet received) for each vendor in three periods of 30 days each, starting from a selected date. There are also columns with orders before and after the three periods and a column with the total order detail for each vendor. The report can be used to analyze a company''s expected purchase volume.';
            }
            action("Vendor - Order Detail")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Order Detail';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - Order Detail";
                ToolTip = 'View a list of items that have been ordered, but not yet received, from each vendor. The order amounts are totaled for each vendor and for the entire list. The report can be used, for example, to obtain an overview of purchases over the short term or to analyze possible receipt problems.';
            }
            action("Vendor - Purchase List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Purchase List';
                Image = "Report";
                RunObject = Report "Vendor - Purchase List";
                ToolTip = 'View a list of your purchases in a period, for example, to report purchase activity to customs and tax authorities.';
            }
            action("Vendor - Labels")
            {
                ApplicationArea = Suite;
                Caption = 'Vendor - Labels';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - Labels";
                ToolTip = 'View mailing labels with the vendors'' names and addresses.';
            }
#if not CLEAN28
            action("Vendor - Top 10 List")
            {
                ApplicationArea = Suite;
                Caption = 'Vendor - Top 10 List';
                Image = "Report";
                RunObject = Report "Vendor - Top 10 List";
                ToolTip = 'View a list of the vendors from whom you purchase the most or to whom you owe the most.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Purchase Statistics")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Statistics';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Purchase Statistics";
                ToolTip = 'Get an overview of amounts for purchases, invoice discount, and payment discount in LCY for each vendor, for example, to analyze item purchases for an individual customer and trends for item purchases.';
            }
            action("Vendor/Item Purchases")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor/Item Purchases';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor/Item Purchases";
                ToolTip = 'View a list of item entries for each vendor in a selected period.';
            }
#if not CLEAN28
            action("Payments on Hold")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payments on Hold';
                Image = "Report";
                RunObject = Report "Payments on Hold";
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor Item Catalog")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Item Catalog';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor Item Catalog";
                ToolTip = 'View a list of the items that your vendors supply.';
            }
            action("Vendor - Balance to Date")
            {
                Caption = 'Vendor - Balance to Date';
                Image = "Report";
                RunObject = Report "Vendor - Balance to Date";
                ToolTip = 'View a detail balance for selected vendors.';
            }
#if not CLEAN28
            action("Aged Accounts Payable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accounts Payable';
                Image = "Report";
                RunObject = Report "Aged Accounts Payable";
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor - Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor - Trial Balance";
                ToolTip = 'View the beginning and ending balance for vendors with entries within a specified period. The report can be used to verify that the balance for a vendor posting group is equal to the balance on the corresponding general ledger account on a certain date.';
            }
            action("Purch. without Vend. VAT Inv.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purch. without Vend. VAT Inv.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Purch. without Vend. VAT Inv.";
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(New_Promoted; New)
                {
                }
                actionref("Purchase Invoice_Promoted"; "Purchase Invoice")
                {
                }
                actionref("Purchase Order_Promoted"; "Purchase Order")
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Payment Journal_Promoted"; "Payment Journal")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref(Agreements_Promoted; Agreements)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Vendor G/L Turnover_Promoted"; "Vendor G/L Turnover")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Vendor - Order Summary_Promoted"; "Vendor - Order Summary")
                {
                }
                actionref("Vendor - Purchase List_Promoted"; "Vendor - Purchase List")
                {
                }
#if not CLEAN28
                actionref("Vendor - Top 10 List_Promoted"; "Vendor - Top 10 List")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                actionref("Payments on Hold_Promoted"; "Payments on Hold")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
                actionref("Vendor - Balance to Date_Promoted"; "Vendor - Balance to Date")
                {
                }
#if not CLEAN28
                actionref("Aged Accounts Payable_Promoted"; "Aged Accounts Payable")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
            }
            group(Category_Category6)
            {
                Caption = 'Category 6';

                actionref(PriceLists_Promoted; PriceLists)
                {
                }
                actionref(PriceLines_Promoted; PriceLines)
                {
                }
                actionref(DiscountLines_Promoted; DiscountLines)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ExtendedPriceEnabled: Boolean;

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        Vend: Record Vendor;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Vend);
        exit(SelectionFilterManagement.GetSelectionFilterForVendor(Vend));
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var Vend: Record Vendor)
    begin
        CurrPage.SetSelectionFilter(Vend);
    end;
}

