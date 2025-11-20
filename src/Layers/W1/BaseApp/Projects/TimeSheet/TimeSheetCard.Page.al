// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Projects.Resources.Resource;
using System.Security.User;

page 973 "Time Sheet Card"
{
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Time Sheet Header";
    Caption = 'Time Sheet';
    InsertAllowed = false;
    DataCaptionExpression = GetDataCaption();

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the starting date for a time sheet.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ending date for a time sheet.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                    Editable = false;
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource for the time sheet.';
                    Editable = false;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description for the time sheet.';
                    Importance = Additional;
                }
            }
            part(TimeSheetLines; "Time Sheet Lines Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Time Sheet No." = field("No.");
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            part(TimeSheetStatusFactBox; "Time Sheet Status FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Time Sheet Status';
            }
            part(ActualSchedSummaryFactBox; "Actual/Sched. Summary FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Actual/Budgeted Summary';
                Visible = true;
            }
            part(TimeSheetLineDetailsFactBox; "TimeSheet Line Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                Provider = TimeSheetLines;
                SubPageLink = "Time Sheet No." = field("Time Sheet No."), "Line No." = field("Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(TimeSheetComments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Time Sheet Comment Sheet";
                RunPageLink = "No." = field("No."),
                                  "Time Sheet Line No." = const(0);
                ToolTip = 'View comments about the time sheet.';
            }
        }
        area(processing)
        {
            action(Submit)
            {
                ApplicationArea = Jobs;
                Caption = '&Submit';
                Image = ReleaseDoc;
                Enabled = SubmitEnabled;
                Visible = not ManagerTimeSheet;
                ShortCutKey = 'F9';
                ToolTip = 'Submit all open time sheet lines for approval. Each line must have a Type defined. For dedicated line approval select the Submit action on the lines section.';

                trigger OnAction()
                begin
                    SubmitLines();
                end;
            }
            action(ReopenSubmitted)
            {
                ApplicationArea = Jobs;
                Caption = '&Reopen';
                Image = ReOpen;
                Enabled = ReopenSubmittedEnabled;
                Visible = not ManagerTimeSheet;
                ToolTip = 'Reopen all submitted or rejected time sheet lines. Each line must have a Type defined. For dedicated line reopen select the Reopen action on the lines section.';

                trigger OnAction()
                begin
                    ReopenSubmittedLines();
                end;
            }
            action(Approve)
            {
                ApplicationArea = Jobs;
                Caption = '&Approve';
                Image = ReleaseDoc;
                Enabled = ApproveEnabled;
                Visible = ManagerTimeSheet;
                ToolTip = 'Approve all submitted time sheet lines. Each line must have a Type defined. For dedicated line approval select the Approve action on the lines section.';

                trigger OnAction()
                begin
                    ApproveLines();
                end;
            }
            action(ReopenApproved)
            {
                ApplicationArea = Jobs;
                Caption = '&Reopen';
                Image = ReOpen;
                Enabled = ReopenApprovedEnabled;
                Visible = ManagerTimeSheet;
                ToolTip = 'Reopen all approved or rejected time sheet lines. Each line must have a Type defined. For dedicated line reopen select the Reopen action on the lines section.';

                trigger OnAction()
                begin
                    ReopenApprovedLines();
                end;
            }
            action(Reject)
            {
                ApplicationArea = Jobs;
                Caption = 'Reject';
                Image = Reject;
                Enabled = ApproveEnabled;
                Visible = ManagerTimeSheet;
                ToolTip = 'Reject all submitted time sheet lines. Each line must have a Type defined. For dedicated line rejection select the Reject action on the lines section.';

                trigger OnAction()
                begin
                    RejectLines();
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyLinesFromTS)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy lines from time sheet';
                    Image = Copy;
                    ToolTip = 'Copy information from the selected time sheet, such as type and description, and then modify the lines. If a line is related to a project, the project number is copied.';
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        TimeSheetMgt.SelectAndCopyTimeSheetLines(Rec, false);
                    end;
                }
                action(CopyLinesFromTSWithComments)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy lines from time sheet with comments';
                    Image = Copy;
                    ToolTip = 'Copy information from the selected time sheet, such as type and description, and then modify the lines. If a line is related to a project, the project number is copied. Comments will be copied as well.';
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        TimeSheetMgt.SelectAndCopyTimeSheetLines(Rec, true);
                    end;
                }
                action(CreateLinesFromJobPlanning)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create lines from &project planning';
                    Image = CreateLinesFromJob;
                    ToolTip = 'Create time sheet lines that are based on project planning lines.';
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        TimeSheetMgt.CheckCreateLinesFromJobPlanning(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ReopenSubmitted_Promoted; ReopenSubmitted)
                {
                }
                actionref(ReopenApproved_Promoted; ReopenApproved)
                {
                }
                actionref(Submit_Promoted; Submit)
                {
                }
                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(TimeSheetComments_Promoted; TimeSheetComments)
                {
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                group(Category_CopyTSLines)
                {
                    Caption = 'Copy lines from time sheet';
                    ShowAs = SplitButton;

                    actionref(SelectAndCopyLinesFromTS_Promoted; CopyLinesFromTS)
                    {
                    }
                    actionref(SelectAndCopyLinesFromTSWithComments_Promoted; CopyLinesFromTSWithComments)
                    {
                    }
                }
                actionref(CreateLinesFromJobPlanning_Promoted; CreateLinesFromJobPlanning)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, IsHandled);
        if not IsHandled then begin
            CheckSetDefaultOwnerFilter();
            RemoveFilterFromLinesExistField();
        end;

        OnAfterOnOpenPage(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.TimeSheetLines.Page.SetColumns(Rec."No.");
        UpdateControls();
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        RefActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject;
        EmploymentQst: Label 'Time Sheet: %1 for dates prior to the Employment Date: %2  for Resource user.Do you still want to submit open lines?', Comment = '%1=Time Sheet No; %2= Resource Employment Date';

    protected var
        SubmitEnabled: Boolean;
        ReopenSubmittedEnabled: Boolean;
        ReopenApprovedEnabled: Boolean;
        ApproveEnabled: Boolean;
        ManagerTimeSheet: Boolean;

    procedure SetManagerTimeSheetMode()
    begin
        ManagerTimeSheet := true;
        CurrPage.TimeSheetLines.Page.SetManagerTimeSheetMode();
    end;

    local procedure CheckSetDefaultOwnerFilter()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then;
        if not UserSetup."Time Sheet Admin." then begin
            Rec.FilterGroup(2);
            if (Rec.GetFilter("Owner User ID") = '') and (Rec.GetFilter("Approver User ID") = '') then
                TimeSheetMgt.FilterTimeSheets(Rec, Rec.FieldNo("Owner User ID"));
            Rec.FilterGroup(0);
        end;
    end;

    local procedure UpdateControls()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        CurrPage.ActualSchedSummaryFactBox.PAGE.UpdateData(Rec);
        CurrPage.TimeSheetStatusFactBox.PAGE.UpdateData(Rec);

        FilterAllLines(TimeSheetLine, RefActionType::Submit);
        SubmitEnabled := not TimeSheetLine.IsEmpty();

        FilterAllLines(TimeSheetLine, RefActionType::ReopenSubmitted);
        ReopenSubmittedEnabled := not TimeSheetLine.IsEmpty();

        FilterAllLines(TimeSheetLine, RefActionType::Approve);
        ApproveEnabled := not TimeSheetLine.IsEmpty();

        FilterAllLines(TimeSheetLine, RefActionType::ReopenApproved);
        ReopenApprovedEnabled := not TimeSheetLine.IsEmpty();
    end;

    protected procedure Process(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetAction: Enum "Time Sheet Action";
    begin
        FilterAllLines(TimeSheetLine, ActionType);
        OnProcessOnAfterTimeSheetLinesFiltered(TimeSheetLine, ActionType);

        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.ProcessAction(TimeSheetLine, ActionType);
            until TimeSheetLine.Next() = 0
        else begin
            case ActionType of
                RefActionType::Submit:
                    TimeSheetAction := TimeSheetAction::Submit;
                RefActionType::ReopenSubmitted:
                    TimeSheetAction := TimeSheetAction::"Reopen Submitted";
                RefActionType::Approve:
                    TimeSheetAction := TimeSheetAction::Approve;
                RefActionType::ReopenApproved:
                    TimeSheetAction := TimeSheetAction::"Reopen Approved";
                RefActionType::Reject:
                    TimeSheetAction := TimeSheetAction::Reject;
            end;
            TimeSheetApprovalMgt.NoTimeSheetLinesToProcess(TimeSheetAction);
        end;
        CurrPage.Update(true);

        OnAfterProcess(Rec, ActionType);
    end;

    local procedure SubmitLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmitLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if not CheckResourceEmployment(RefActionType::Submit, Rec."Resource No.") then
            if TimeSheetApprovalMgt.ConfirmAction(RefActionType::Submit) then
                Process(RefActionType::Submit);
    end;

    local procedure ApproveLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApproveLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if not CheckResourceEmployment(RefActionType::Approve, Rec."Resource No.") then
            if TimeSheetApprovalMgt.ConfirmAction(RefActionType::Approve) then
                Process(RefActionType::Approve);
    end;

    local procedure RejectLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRejectLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::Reject) then
            Process(RefActionType::Reject);
    end;

    local procedure ReopenSubmittedLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::ReopenSubmitted) then
            Process(RefActionType::ReopenSubmitted);
    end;

    local procedure ReopenApprovedLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::ReopenApproved) then
            Process(RefActionType::ReopenApproved);
    end;

    local procedure CheckResourceEmployment(ActionType: Option Submit,Reopen,Approve,ReopenApproved,Reject; ResourceNo: Code[20]): Boolean
    var
        Resource: Record Resource;
    begin
        if Resource.Get(ResourceNo) then
            if Resource."Employment Date" <> 0D then
                if Resource."Employment Date" > Rec."Starting Date" then begin
                    if Confirm(EmploymentQst, false, Rec."No.", Resource."Employment Date") then
                        Process(ActionType);
                    exit(true);
                end;

        exit(false)
    end;

    protected procedure FilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
        TimeSheetLine.SetRange("Time Sheet No.", Rec."No.");
        TimeSheetMgt.FilterAllTimeSheetLines(TimeSheetLine, ActionType);
    end;

    local procedure RemoveFilterFromLinesExistField()
    begin
        if Rec.GetFilter("Lines Exist") <> '' then
            Rec.SetRange("Lines Exist");
    end;

    local procedure GetDataCaption(): Text
    begin
        exit(TimeSheetMgt.GetTimeSheetDataCaption(Rec));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessOnAfterTimeSheetLinesFiltered(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterProcess(var TimeSheetHeader: Record "Time Sheet Header"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenLines(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubmitLines(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApproveLines(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRejectLines(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;
}