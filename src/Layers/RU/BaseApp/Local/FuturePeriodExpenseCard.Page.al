#pragma warning disable AA0247
page 17331 "Future Period Expense Card"
{
    Caption = 'Future Period Expense Card';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Fixed Asset";
    SourceTableView = where("FA Type" = const("Future Expense"));

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
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a second description.';
                }
                field("Tax Difference Code"; Rec."Tax Difference Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference code associated with the fixed asset.';
                }
                field("Unrealized VAT Amount"; Rec."Unrealized VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unrealized VAT amount for this line if you use unrealized VAT.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the tax amount associated with the fixed asset.';

                    trigger OnValidate()
                    begin
                        TaxAmountOnAfterValidate();
                    end;
                }
            }
            part(DepreciationBook; "FE Depreciation Books Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "FA No." = field("No.");
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
                separator(Action39)
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
                action("Ta&x Difference Detailed")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ta&x Difference Detailed';
                    Image = LedgerBook;
                    ToolTip = 'View the tax difference detailed entries that are associated with the archived general journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowTaxDifferences();
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Copy Future Expense")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Future Expense';
                    Image = Copy;

                    trigger OnAction()
                    var
                        CopyFA: Report "Copy Fixed Asset";
                    begin
                        CopyFA.SetFANo(Rec."No.");
                        CopyFA.RunModal();
                    end;
                }
                action("Create FE Depreciation Books")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create FE Depreciation Books';
                    Image = CalculateLines;
                    RunPageOnRec = true;

                    trigger OnAction()
                    begin
                        FA.Reset();
                        FA.SetRange("No.", Rec."No.");
                        if FA.FindFirst() then
                            REPORT.Run(REPORT::"Create FA Depreciation Books", true, true, FA);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Copy Future Expense_Promoted"; "Copy Future Expense")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."FA Type" := Rec."FA Type"::"Future Expense";
    end;

    var
        FA: Record "Fixed Asset";

    local procedure TaxAmountOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

