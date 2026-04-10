#pragma warning disable AA0247
page 14942 "G/L Corr. Analysis View List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Correspondence Analysis Views';
    CardPageID = "G/L Corr. Analysis View Card";
    Editable = false;
    PageType = List;
    SourceTable = "G/L Corr. Analysis View";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the general ledger correspondence.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the code that identifies the general ledger correspondence.';
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the record was last updated.';
                }
                field("Debit Dimension 1 Code"; Rec."Debit Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Debit Dimension 2 Code"; Rec."Debit Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Debit Dimension 3 Code"; Rec."Debit Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Credit Dimension 1 Code"; Rec."Credit Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Credit Dimension 2 Code"; Rec."Credit Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Credit Dimension 3 Code"; Rec."Credit Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension code by which you want to group the general ledger correspondence.';
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
        area(processing)
        {
            action(EditAnalysis)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Analysis View';
                Image = Edit;
                ToolTip = 'Open the selected analysis view in edit mode.';

                trigger OnAction()
                var
                    GLCorrAnalysisByDim: Page "G/L Corr. Analysis by Dim.";
                begin
                    Clear(GLCorrAnalysisByDim);
                    GLCorrAnalysisByDim.SetAnalysisViewCode(Rec.Code);
                    GLCorrAnalysisByDim.Run();
                end;
            }
            action("&Update")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Update';
                Image = Refresh;
                RunObject = Codeunit "Update G/L Corr. Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Update_Promoted"; "&Update")
                {
                }
                actionref(EditAnalysis_Promoted; EditAnalysis)
                {
                }
            }
        }
    }
}

