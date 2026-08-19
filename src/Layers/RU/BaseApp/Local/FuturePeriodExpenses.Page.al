#pragma warning disable AA0247
page 17338 "Future Period Expenses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Future Expenses';
    CardPageID = "Future Period Expense Card";
    Editable = false;
    PageType = List;
    SourceTable = "Fixed Asset";
    SourceTableView = where("FA Type" = const("Future Expense"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Tax Difference Code"; Rec."Tax Difference Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference code associated with the fixed asset.';
                }
                field(Inactive; Rec.Inactive)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last modified.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Future &Expense")
            {
                Caption = 'Future &Expense';
                action("Depreciation &Books")
                {
                    Caption = 'Depreciation &Books';
                    Image = DepreciationBooks;
                    RunObject = Page "FA Depreciation Books";
                    RunPageLink = "FA No." = field("No.");
                }
                action("Ledger E&ntries")
                {
                    Caption = 'Ledger E&ntries';
                    Image = LedgerEntries;
                    RunObject = Page "FA Ledger Entries";
                    RunPageLink = "FA No." = field("No.");
                    RunPageView = sorting("FA No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Error Ledger Entries")
                {
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    RunObject = Page "FA Error Ledger Entries";
                    RunPageLink = "Canceled from FA No." = field("No.");
                    RunPageView = sorting("Canceled from FA No.");
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Fixed Asset"),
                                  "No." = field("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5600),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                }
                separator(Action1210023)
                {
                    Caption = '';
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Fixed Asset Statistics";
                    RunPageLink = "FA No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("FA Posting Types Overview")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Types Overview';
                    Image = ShowMatrix;
                    RunObject = Page "FA Posting Types Overview";
                }
                action("Ta&x Differences Detailed")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ta&x Differences Detailed';
                    Image = LedgerBook;
                    ToolTip = 'View the tax difference detailed entries that are associated with the archived general journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowTaxDifferences();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }
}

