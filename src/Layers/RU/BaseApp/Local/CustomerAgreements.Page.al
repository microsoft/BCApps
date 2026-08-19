#pragma warning disable AA0247
page 14900 "Customer Agreements"
{
    Caption = 'Customer Agreements';
    CardPageID = "Customer Agreement Card";
    Editable = false;
    PageType = List;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Customer Agreement";
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
                    ToolTip = 'Specifies the code that identifies the customer agreement.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a customer agreement is active.';
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
                }
                separator(Action1210023)
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
            group(Action1210028)
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
                    ToolTip = 'View any related return orders. ';
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
                actionref("S&ales_Promoted"; "S&ales")
                {
                }
            }
        }
    }
}

