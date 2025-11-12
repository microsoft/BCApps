// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

page 555 "Analysis View Card"
{
    Caption = 'Analysis View Card';
    PageType = Card;
    SourceTable = "Analysis View";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for this card.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Account Source"; Rec."Account Source")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies an account that you can use as a filter to define what is displayed in the Analysis by Dimensions window. ';

                    trigger OnValidate()
                    begin
                        SetGLAccountSource();
                    end;
                }
                field("Account Filter"; Rec."Account Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which accounts are shown in the analysis view.';
                }
                field("Date Compression"; Rec."Date Compression")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the starting date of the campaign analysis.';
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the analysis view was last updated.';
                }
                field("Last Entry No."; Rec."Last Entry No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the last general ledger entry you posted, prior to updating the analysis view.';
                }
                field("Last Budget Entry No."; Rec."Last Budget Entry No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the last item budget entry you entered prior to updating the analysis view.';
                }
                field("Update on Posting"; Rec."Update on Posting")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the analysis view is updated every time that you post a general ledger entry.';
                }
                field("Include Budgets"; Rec."Include Budgets")
                {
                    ApplicationArea = Suite;
                    Editable = GLAccountSource;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 4 Code"; Rec."Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
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
        area(navigation)
        {
            group("&Analysis")
            {
                Caption = '&Analysis';
                Image = AnalysisView;
                action("Filter")
                {
                    ApplicationArea = Suite;
                    Caption = 'Filter';
                    Image = "Filter";
                    RunObject = Page "Analysis View Filter";
                    RunPageLink = "Analysis View Code" = field(Code);
                    ToolTip = 'Apply the filter.';
                }
            }
        }
        area(processing)
        {
            action("&Update")
            {
                ApplicationArea = Suite;
                Caption = '&Update';
                Image = Refresh;
                RunObject = Codeunit "Update Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
            action("Enable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enable Update on Posting';
                Image = Apply;
                ToolTip = 'Ensure that the analysis view is updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    Rec.SetUpdateOnPosting(true);
                end;
            }
            action("Disable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Disable Update on Posting';
                Image = UnApply;
                ToolTip = 'Ensure that the analysis view is not updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    Rec.SetUpdateOnPosting(false);
                end;
            }
            action(ResetAnalysisView)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset';
                Image = DeleteRow;
                ToolTip = 'Delete existing entries so you can recreate them. Use this action after a dimension correction was done or if entries are missing. To recreate the entries, choose Update or run the Update Analysis View report.';

                trigger OnAction()
                begin
                    if Confirm(ResetAnalysisViewQst) then
                        Rec.AnalysisViewReset();
                end;
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
                actionref(Filter_Promoted; Filter)
                {
                }
                actionref("Enable Update on Posting_Promoted"; "Enable Update on Posting")
                {
                }
                actionref("Disable Update on Posting_Promoted"; "Disable Update on Posting")
                {
                }
                actionref("ResetAnalysisView_Promoted"; ResetAnalysisView)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetGLAccountSource();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if CurrentRecordId <> Rec.RecordId then begin
            Rec.ShowResetNeededNotification();
            CurrentRecordId := Rec.RecordId;
        end;
    end;

    trigger OnOpenPage()
    begin
        GLAccountSource := true;
    end;

    var
        GLAccountSource: Boolean;

    local procedure SetGLAccountSource()
    begin
        GLAccountSource := Rec."Account Source" = Rec."Account Source"::"G/L Account";
    end;

    var
        CurrentRecordId: RecordId;
        ResetAnalysisViewQst: Label 'This action will delete all existing entries. It should be used only if there are missing entries or if the dimension corection was done. Invoke Update or run the Update Analysis View Report to create new set of entries.\\Do you want to continue?';
}

