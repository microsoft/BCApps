#pragma warning disable AA0247
page 14944 "G/L Corr. Analysis View Entr."
{
    Caption = 'G/L Corr. Analysis View Entr.';
    Editable = false;
    PageType = List;
    SourceTable = "G/L Corr. Analysis View Entry";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("G/L Corr. Analysis View Code"; Rec."G/L Corr. Analysis View Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the general ledger correspondence analysis view.';
                }
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                }
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account number associated with the general ledger correspondence.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with the general ledger correspondence.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Debit Dimension 1 Value Code"; Rec."Debit Dimension 1 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension value code by which the general ledger correspondence is grouped.';
                }
                field("Debit Dimension 2 Value Code"; Rec."Debit Dimension 2 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension value code by which the general ledger correspondence is grouped.';
                }
                field("Debit Dimension 3 Value Code"; Rec."Debit Dimension 3 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension value code by which the general ledger correspondence is grouped.';
                }
                field("Credit Dimension 1 Value Code"; Rec."Credit Dimension 1 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension value code by which the general ledger correspondence is grouped.';
                }
                field("Credit Dimension 2 Value Code"; Rec."Credit Dimension 2 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension value code by which the general ledger correspondence is grouped.';
                }
                field("Credit Dimension 3 Value Code"; Rec."Credit Dimension 3 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension value code by which the general ledger correspondence is grouped.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount associated with the general ledger correspondence.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Amount (ACY)"; Rec."Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional reporting currency (ACY) amount associated with the general ledger correspondence.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    var
        TempGLCorrEntry: Record "G/L Correspondence Entry" temporary;

    local procedure DrillDown()
    begin
        SetAnalysisViewEntry(Rec);
        PAGE.RunModal(PAGE::"G/L Correspondence Entries", TempGLCorrEntry);
    end;

    local procedure SetAnalysisViewEntry(var AnalysisViewEntry: Record "G/L Corr. Analysis View Entry")
    var
        AnalysisViewEntryToGLEntries: Codeunit GLCorrAnViewEntrToGLCorrEntr;
    begin
        TempGLCorrEntry.Reset();
        TempGLCorrEntry.DeleteAll();
        AnalysisViewEntryToGLEntries.GetGLCorrEntries(AnalysisViewEntry, TempGLCorrEntry);
    end;
}

