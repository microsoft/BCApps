namespace System.Integration.PowerBI;

page 6348 "Power BI Deployment Steps"
{
    Caption = 'Deployment Steps';
    PageType = List;
    SourceTable = "Power BI Deployment State";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Steps)
            {
                field(StatusReached; Rec."Status Reached")
                {
                    ApplicationArea = All;
                    Caption = 'Status Reached';
                    ToolTip = 'Specifies the upload status that had been reached when this record was created.';
                }
                field(Status; StepStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether this step completed successfully or failed.';
                    StyleExpr = StepStatusStyle;

                    trigger OnDrillDown()
                    var
                        FailedReason: Text;
                    begin
                        FailedReason := Rec.GetFailedReason();
                        if FailedReason <> '' then
                            Message(StrSubstNo(DeploymentFailedWithErrorMsg, FailedReason));
                    end;
                }
                field(ReachedAt; Rec."Reached At")
                {
                    ApplicationArea = All;
                    Caption = 'Reached At';
                    ToolTip = 'Specifies the date and time when this status was reached.';
                }
                field(FailedAt; Rec."Failed At")
                {
                    ApplicationArea = All;
                    Caption = 'Failed At';
                    ToolTip = 'Specifies the date and time when this step failed, if applicable.';
                    Visible = HasFailedSteps;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        DeploymentState: Record "Power BI Deployment State";
    begin
        DeploymentState.CopyFilters(Rec);
        DeploymentState.SetFilter("Failed At", '<>%1', 0DT);
        HasFailedSteps := not DeploymentState.IsEmpty();
    end;

    trigger OnAfterGetRecord()
    var
        NextState: Record "Power BI Deployment State";
        StepCompleted: Boolean;
    begin
        if Rec."Failed At" <> 0DT then begin
            StepStatus := FailedLbl;
            StepStatusStyle := 'Unfavorable';
        end else begin
            NextState.SetRange("Report Id", Rec."Report Id");
            NextState.SetFilter("Entry No.", '>%1', Rec."Entry No.");
            StepCompleted := NextState.FindFirst();
            if not StepCompleted then
                StepCompleted := Rec."Status Reached" = Enum::"Power BI Upload Status"::Completed;

            if StepCompleted then begin
                StepStatus := CompletedLbl;
                StepStatusStyle := 'Favorable';
            end else begin
                StepStatus := InProgressLbl;
                StepStatusStyle := 'Ambiguous';
            end;
        end;
    end;

    var
        HasFailedSteps: Boolean;
        StepStatus: Text;
        StepStatusStyle: Text;
        CompletedLbl: Label 'Completed';
        FailedLbl: Label 'Failed';
        InProgressLbl: Label 'In Progress';
        DeploymentFailedWithErrorMsg: Label 'Deployment step failure: %1', Comment = '%1 - Error message thrown by the deployment step';
}
