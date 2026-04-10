#pragma warning disable AA0247
page 17332 "FE Depreciation Books Subform"
{
    Caption = 'Lines';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    DelayedInsert = true;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "FA Depreciation Book";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';
                }
                field("Depreciation Method"; Rec."Depreciation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';
                }
                field("Depreciation Starting Date"; Rec."Depreciation Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';
                }
                field("Depreciation Ending Date"; Rec."Depreciation Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';
                }
                field("No. of Depreciation Years"; Rec."No. of Depreciation Years")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in years.';
                }
                field("No. of Depreciation Months"; Rec."No. of Depreciation Months")
                {
                    ToolTip = 'Specifies the length of the depreciation period, expressed in months.';
                    Visible = false;
                }
                field("Straight-Line %"; Rec."Straight-Line %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to depreciate the fixed asset by the straight-line principle, but with a fixed yearly percentage.';
                }
                field("Fixed Depr. Amount"; Rec."Fixed Depr. Amount")
                {
                    Visible = false;
                }
                field(Disposed; Disposed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Disposed';
                    Editable = false;
                }
                field("Acquisition Cost"; Rec."Acquisition Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                }
                field(Depreciation; Rec.Depreciation)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Book Value"; Rec."Book Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the book value for the fixed asset.';

                    trigger OnDrillDown()
                    var
                        FALedgEntry: Record "FA Ledger Entry";
                    begin
                        if Rec."Disposal Date" > 0D then
                            Rec.ShowBookValueAfterDisposal()
                        else begin
                            FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
                            FALedgEntry.SetRange("FA No.", Rec."FA No.");
                            FALedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
                            FALedgEntry.SetRange("Part of Book Value", true);
                            PAGE.Run(0, FALedgEntry);
                        end;
                    end;
                }
                field("Depreciation Table Code"; Rec."Depreciation Table Code")
                {
                    ToolTip = 'Specifies the code of the depreciation table to use if you have selected the User-Defined option in the Depreciation Method field.';
                    Visible = false;
                }
                field("First User-Defined Depr. Date"; Rec."First User-Defined Depr. Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date for the user-defined depreciation table if you have entered a code in the Depreciation Table Code field.';
                }
                field("Final Rounding Amount"; Rec."Final Rounding Amount")
                {
                    ToolTip = 'Specifies the final rounding amount to use.';
                    Visible = false;
                }
                field("Ending Book Value"; Rec."Ending Book Value")
                {
                    ToolTip = 'Specifies the amount to use as the ending book value.';
                    Visible = false;
                }
                field("Use FA Ledger Check"; Rec."Use FA Ledger Check")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Depr. Book")
            {
                Caption = '&Depr. Book';
                action("Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger Entries';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        ShowFALedgEntries();
                    end;
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;

                    trigger OnAction()
                    begin
                        ShowFAErrorLedgEntries();
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        ShowStatistics();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Disposed := (Rec."Disposal Date" > 0D) and (Rec."Book Value" = 0);
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        Disposed: Boolean;

    [Scope('OnPrem')]
    procedure ShowFALedgEntries()
    begin
        DepreciationCalc.SetFAFilter(FALedgEntry, Rec."FA No.", Rec."Depreciation Book Code", false);
        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
    end;

    [Scope('OnPrem')]
    procedure ShowFAErrorLedgEntries()
    begin
        FALedgEntry.Reset();
        FALedgEntry.SetCurrentKey("Canceled from FA No.");
        FALedgEntry.SetRange("Canceled from FA No.", Rec."FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
        PAGE.Run(PAGE::"FA Error Ledger Entries", FALedgEntry);
    end;

    [Scope('OnPrem')]
    procedure ShowStatistics()
    begin
        FADeprBook.SetRange("FA No.", Rec."FA No.");
        FADeprBook.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
        PAGE.Run(PAGE::"Fixed Asset Statistics", FADeprBook);
    end;
}

