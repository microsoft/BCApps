#pragma warning disable AA0247
page 14913 "Vendor Agreements"
{
    Caption = 'Vendor Agreements';
    CardPageID = "Vendor Agreement Card";
    Editable = false;
    PageType = List;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Vendor Agreement";
    SourceTableView = sorting("Agreement Group", "No.");

    layout
    {
        area(content)
        {
            repeater(Control1210002)
            {
                ShowCaption = false;
                field("Agreement Group"; Rec."Agreement Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer agreement group to which a customer agreement belongs.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
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
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the agreement.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that corresponds to the priority that you give the vendor.';
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
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
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
                separator(Action1210027)
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
        area(Promoted)
        {
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
}

