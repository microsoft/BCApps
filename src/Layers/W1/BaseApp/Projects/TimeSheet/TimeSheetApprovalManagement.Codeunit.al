// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;

codeunit 951 "Time Sheet Approval Management"
{
    Permissions = TableData Employee = r;

    trigger OnRun()
    begin
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        ResourceSetupRead: Boolean;
        NothingToSubmitErr: Label 'There is nothing to submit for line with %1=%2, %3=%4.', Comment = '%1 = Time Sheet No. caption; %2 = Time Sheet No. value; %3 = Line No. caption; %4 = Line No. value; Example = There is nothing to submit for line with Time Sheet No.=10, Line No.=10000.';
#pragma warning disable AA0074
        Text002: Label 'You are not authorized to approve time sheet lines. Contact your time sheet administrator.';
#pragma warning restore AA0074
        ProcessOpenLinesQst: Label '&All open lines with %2 defined [%1 line(s)],&Selected line(s) with %2 defined only', Comment = '%1 = Lines count, %2 = Type caption';
        ProcessSubmittedLinesQst: Label '&All submitted lines with %2 defined [%1 line(s)],&Selected line(s) with %2 defined only', Comment = '%1 = Lines count, %2 = Type caption';
        ProcessApprovedLinesQst: Label '&All approved lines with %2 defined [%1 line(s)],&Selected line(s) with %2 defined only', Comment = '%1 = Lines count, %2 = Type caption';
#pragma warning disable AA0074
        Text007: Label 'Submit for approval';
        Text008: Label 'Reopen for editing';
        Text009: Label 'Approve for posting';
        Text010: Label 'Reject for correction';
#pragma warning restore AA0074
        SubmitConfirmQst: Label 'Do you want to submit open lines?';
        ReopenConfirmQst: Label 'Do you want to reopen submitted lines?';
        ApproveConfirmQst: Label 'Do you want to approve submitted lines?';
        RejectConfirmQst: Label 'Do you want to reject submitted lines?';
        ReopenApprovedConfirmQst: Label 'Do you want to reopen approved lines?';
        SubmitLineQst: Label 'Do you want to submit line?';
        ReopenLineQst: Label 'Do you want to reopen line?';
        ApproveLineQst: Label 'Do you want to approve line?';
        RejectLineQst: Label 'Do you want to reject line?';
        NoTimeSheetLinesToProcessErr: Label 'There are no time sheet lines to process in %1 action.', Comment = '%1 = Action';

    procedure ProcessAction(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    var
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
    begin
        case ActionType of
            ActionType::Submit:
                Submit(TimeSheetLine);
            ActionType::ReopenSubmitted:
                ReopenSubmitted(TimeSheetLine);
            ActionType::Approve:
                Approve(TimeSheetLine);
            ActionType::ReopenApproved:
                ReopenApproved(TimeSheetLine);
            ActionType::Reject:
                Reject(TimeSheetLine);
        end;
        FeatureTelemetry.LogUsage('0000JQU', 'NewTimeSheetExperience', 'Time Sheet action processed');
    end;

    procedure Submit(var TimeSheetLine: Record "Time Sheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmit(TimeSheetLine, IsHandled);
        if isHandled then
            exit;

        if TimeSheetLine.Status = TimeSheetLine.Status::Submitted then
            exit;
        if TimeSheetLine.Type = TimeSheetLine.Type::" " then
            TimeSheetLine.FieldError(Type);
        TimeSheetLine.TestStatus();
        TimeSheetLine.CalcFields("Total Quantity");

        if CheckEmptyLineNotRequireSubmit(TimeSheetLine) then
            exit;

        if TimeSheetLine."Total Quantity" = 0 then
            Error(
              NothingToSubmitErr, TimeSheetLine.FieldCaption("Time Sheet No."), TimeSheetLine."Time Sheet No.", TimeSheetLine.FieldCaption("Line No."), TimeSheetLine."Line No.");
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Job:
                begin
                    TimeSheetLine.TestField("Job No.");
                    TimeSheetLine.TestField("Job Task No.");
                end;
            TimeSheetLine.Type::Absence:
                TimeSheetLine.TestField("Cause of Absence Code");
        end;
        OnSubmitOnAfterCheck(TimeSheetLine);
        TimeSheetLine.UpdateApproverID();
        TimeSheetLine.Status := TimeSheetLine.Status::Submitted;
        OnSubmitOnBeforeTimeSheetLineModify(TimeSheetLine);
        TimeSheetLine.Modify(true);
        OnAfterSubmit(TimeSheetLine);
    end;

    local procedure CheckEmptyLineNotRequireSubmit(var TimeSheetLine: Record "Time Sheet Line"): Boolean
    begin
        GetResourceSetup();

        if ResourcesSetup."Time Sheet Submission Policy" = ResourcesSetup."Time Sheet Submission Policy"::"Stop and Show Empty Line Error" then
            exit(false);

        exit(TimeSheetLine."Total Quantity" = 0);
    end;

    procedure SubmitIfConfirmed(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if Confirm(SubmitLineQst) then
            Submit(TimeSheetLine);
    end;

    procedure ReopenSubmitted(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if TimeSheetLine.Status = TimeSheetLine.Status::Open then
            exit;
        TimeSheetLine.Status := TimeSheetLine.Status::Open;
        OnReopenSubmittedOnBeforeModify(TimeSheetLine);
        TimeSheetLine.Modify(true);
        OnReopenSubmittedOnAfterModify(TimeSheetLine);

        OnAfterReopenSubmitted(TimeSheetLine);
    end;

    procedure ReopenSubmittedIfConfirmed(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if Confirm(ReopenLineQst) then
            ReopenSubmitted(TimeSheetLine);
    end;

    procedure ReopenApproved(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if TimeSheetLine.Status = TimeSheetLine.Status::Submitted then
            exit;
        TimeSheetLine.TestField(Posted, false);
        CheckApproverPermissions(TimeSheetLine);
        OnReopenApprovedOnBeforeCheckLinkedDoc(TimeSheetLine);
        TimeSheetLine.UpdateApproverID();
        TimeSheetLine.Status := TimeSheetLine.Status::Submitted;
        OnReopenApprovedOnBeforeTimeSheetLineModify(TimeSheetLine);
        TimeSheetLine.Modify(true);

        OnAfterReopenApproved(TimeSheetLine);
    end;

    procedure ReopenApprovedIfConfirmed(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if Confirm(ReopenLineQst) then
            ReopenApproved(TimeSheetLine);
    end;

    procedure Reject(var TimeSheetLine: Record "Time Sheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReject(TimeSheetLine, IsHandled);
        if not IsHandled then begin
            if TimeSheetLine.Status = TimeSheetLine.Status::Rejected then
                exit;
            TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);
            CheckApproverPermissions(TimeSheetLine);
            TimeSheetLine.Status := TimeSheetLine.Status::Rejected;
            OnRejectOnBeforeTimeSheetLineModify(TimeSheetLine);
            TimeSheetLine.Modify(true);
        end;

        OnAfterReject(TimeSheetLine);
    end;

    procedure RejectIfConfirmed(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if Confirm(RejectLineQst) then
            Reject(TimeSheetLine);
    end;

    procedure Approve(var TimeSheetLine: Record "Time Sheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApprove(TimeSheetLine, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetLine.Status = TimeSheetLine.Status::Approved then
            exit;
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);
        CheckApproverPermissions(TimeSheetLine);
        TimeSheetLine.Status := TimeSheetLine.Status::Approved;
        TimeSheetLine."Approved By" := CopyStr(UserId(), 1, MaxStrLen(TimeSheetLine."Approved By"));
        TimeSheetLine."Approval Date" := Today();
        OnApproveOnBeforeTimeSheetLineModify(TimeSheetLine);
        TimeSheetLine.Modify(true);
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Absence:
                PostAbsence(TimeSheetLine);
        end;

        OnAfterApprove(TimeSheetLine);
    end;

    procedure ApproveIfConfirmed(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if Confirm(ApproveLineQst) then
            Approve(TimeSheetLine);
    end;

    internal procedure NoTimeSheetLinesToProcess(TimeSheetAction: Enum "Time Sheet Action")
    begin
        if not GuiAllowed() then
            exit;

        Error(NoTimeSheetLinesToProcessErr, TimeSheetAction);
    end;

    procedure PostAbsence(var TimeSheetLine: Record "Time Sheet Line")
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostAbsence(TimeSheetLine, IsHandled);
        if IsHandled then
            exit;

        TimeSheetHeader.Get(TimeSheetLine."Time Sheet No.");
        Resource.Get(TimeSheetHeader."Resource No.");
        Employee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        Employee.FindFirst();
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        if TimeSheetDetail.FindSet(true) then
            repeat
                EmployeeAbsence.Init();
                EmployeeAbsence.Validate("Employee No.", Employee."No.");
                EmployeeAbsence.Validate("From Date", TimeSheetDetail.Date);
                EmployeeAbsence.Validate("Cause of Absence Code", TimeSheetDetail."Cause of Absence Code");
                EmployeeAbsence.Validate("Unit of Measure Code", Resource."Base Unit of Measure");
                EmployeeAbsence.Validate(Quantity, TimeSheetDetail.Quantity);
                OnBeforeInsertEmployeeAbsence(EmployeeAbsence, TimeSheetLine, TimeSheetDetail);
                EmployeeAbsence.Insert(true);

                TimeSheetDetail.Posted := true;
                TimeSheetDetail.Modify();
                TimeSheetMgt.CreateTSPostingEntry(
                  TimeSheetDetail,
                  TimeSheetDetail.Quantity,
                  TimeSheetDetail.Date,
                  '',
                  TimeSheetLine.Description);
            until TimeSheetDetail.Next() = 0;

        TimeSheetLine.Posted := true;
        TimeSheetLine.Modify();
    end;

    local procedure CheckApproverPermissions(TimeSheetLine: Record "Time Sheet Line")
    var
        UserSetup: Record System.Security.User."User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApproverPermissions(TimeSheetLine, IsHandled);
        if IsHandled then
            exit;

        UserSetup.Get(UserId);
        if not UserSetup."Time Sheet Admin." then
            if TimeSheetLine."Approver ID" <> UpperCase(UserId) then
                Error(Text002);
    end;

#if not CLEAN25
    [Obsolete('Replaced with GetTimeSheetActionDialogText to remove 100 characters limitation.', '25.0')]
    procedure GetTimeSheetDialogText(ActionType: Option Submit,Reopen; LinesQty: Integer): Text[100]
    begin
        exit(CopyStr(GetTimeSheetActionDialogText(ActionType, LinesQty), 1, 100));
    end;
#endif

    procedure GetTimeSheetActionDialogText(ActionType: Option Submit,Reopen; LinesQty: Integer): Text
    var
        TimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
#if not CLEAN25
        ReturnText: Text[100];
#endif
        ReturnActionText: Text;
    begin
#if not CLEAN25
        IsHandled := false;
        OnBeforeGetTimeSheetDialogText(ActionType, LinesQty, ReturnText, IsHandled);
        if IsHandled then
            exit(ReturnText);
#endif
        IsHandled := false;
        OnBeforeGetTimeSheetActionDialogText(ActionType, LinesQty, ReturnActionText, IsHandled);
        if IsHandled then
            exit(ReturnActionText);

        case ActionType of
            ActionType::Submit:
                exit(StrSubstNo(ProcessOpenLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
            ActionType::Reopen:
                exit(StrSubstNo(ProcessSubmittedLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced with GetManagerTimeSheetActionDialogText to remove 100 characters limitation.', '25.0')]
    procedure GetManagerTimeSheetDialogText(ActionType: Option Approve,Reopen,Reject; LinesQty: Integer): Text[100]
    begin
        exit(CopyStr(GetManagerTimeSheetActionDialogText(ActionType, LinesQty), 1, 100));
    end;
#endif

    procedure GetManagerTimeSheetActionDialogText(ActionType: Option Approve,Reopen,Reject; LinesQty: Integer): Text
    var
        TimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
#if not CLEAN25
        ReturnText: Text[100];
#endif
        ReturnActionText: Text;
    begin
#if not CLEAN25
        IsHandled := false;
        OnBeforeGetManagerTimeSheetDialogText(ActionType, LinesQty, ReturnText, IsHandled);
        if IsHandled then
            exit(ReturnText);
#endif
        IsHandled := false;
        OnBeforeGetManagerTimeSheetActionDialogText(ActionType, LinesQty, ReturnActionText, IsHandled);
        if IsHandled then
            exit(ReturnActionText);

        case ActionType of
            ActionType::Approve,
            ActionType::Reject:
                exit(StrSubstNo(ProcessSubmittedLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
            ActionType::Reopen:
                exit(StrSubstNo(ProcessApprovedLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced with GetCommonTimeSheetActionDialogText to remove 100 characters limitation.', '25.0')]
    procedure GetCommonTimeSheetDialogText(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject; LinesQty: Integer): Text[100]
    begin
        exit(CopyStr(GetCommonTimeSheetActionDialogText(ActionType, LinesQty), 1, 100));
    end;
#endif

    procedure GetCommonTimeSheetActionDialogText(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject; LinesQty: Integer): Text
    var
        TimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
#if not CLEAN25
        ReturnText: Text[100];
#endif
        ReturnActionText: Text;
    begin
#if not CLEAN25
        IsHandled := false;
        OnBeforeGetTimeSheetDialogText(ActionType, LinesQty, ReturnText, IsHandled);
        if IsHandled then
            exit(ReturnText);
#endif
        IsHandled := false;
        OnBeforeGetCommonTimeSheetActionDialogText(ActionType, LinesQty, ReturnActionText, IsHandled);
        if IsHandled then
            exit(ReturnActionText);

        case ActionType of
            ActionType::Submit:
                exit(StrSubstNo(ProcessOpenLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
            ActionType::ReopenSubmitted,
            ActionType::Approve,
            ActionType::Reject:
                exit(StrSubstNo(ProcessSubmittedLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
            ActionType::ReopenApproved:
                exit(StrSubstNo(ProcessApprovedLinesQst, LinesQty, TimeSheetLine.FieldCaption(Type)));
        end;
    end;

    procedure ConfirmAction(ActionType: Option Submit,Reopen,Approve,ReopenApproved,Reject): Boolean
    begin
        exit(Confirm(GetConfirmInstructions(ActionType)));
    end;

    local procedure GetConfirmInstructions(ActionType: Option Submit,Reopen,Approve,ReopenApproved,Reject): Text
    begin
        case ActionType of
            ActionType::Submit:
                exit(SubmitConfirmQst);
            ActionType::Reopen:
                exit(ReopenConfirmQst);
            ActionType::ReopenApproved:
                exit(ReopenApprovedConfirmQst);
            ActionType::Approve:
                exit(ApproveConfirmQst);
            ActionType::Reject:
                exit(RejectConfirmQst);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced with GetTimeSheetActionDialogInstruction to remove 100 characters limitation.', '25.0')]
    procedure GetTimeSheetDialogInstruction(ActionType: Option Submit,Reopen): Text[100]
    begin
        exit(CopyStr(GetTimeSheetActionDialogInstruction(ActionType), 1, 100));
    end;
#endif

    procedure GetTimeSheetActionDialogInstruction(ActionType: Option Submit,Reopen): Text
    begin
        case ActionType of
            ActionType::Submit:
                exit(Text007);
            ActionType::Reopen:
                exit(Text008);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced with GetManagerTimeSheetActionDialogInstruction to remove 100 characters limitation.', '25.0')]
    procedure GetManagerTimeSheetDialogInstruction(ActionType: Option Approve,Reopen,Reject): Text[100]
    begin
        exit(CopyStr(GetManagerTimeSheetActionDialogInstruction(ActionType), 1, 100));
    end;
#endif

    procedure GetManagerTimeSheetActionDialogInstruction(ActionType: Option Approve,Reopen,Reject): Text
    begin
        case ActionType of
            ActionType::Approve:
                exit(Text009);
            ActionType::Reject:
                exit(Text010);
            ActionType::Reopen:
                exit(Text008);
        end;
    end;

    procedure GetCommonTimeSheetDialogInstruction(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject): Text
    begin
        case ActionType of
            ActionType::Submit:
                exit(Text007);
            ActionType::ReopenSubmitted,
            ActionType::ReopenApproved:
                exit(Text008);
            ActionType::Approve:
                exit(Text009);
            ActionType::Reject:
                exit(Text010);
        end;
    end;

    local procedure GetResourceSetup()
    begin
        if not ResourceSetupRead then begin
            ResourcesSetup.Get();
            ResourceSetupRead := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEmployeeAbsence(var EmployeeAbsence: Record "Employee Absence"; TimeSheetLine: Record "Time Sheet Line"; var TimeSheetDetail: Record "Time Sheet Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAbsence(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubmit(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenSubmitted(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenApproved(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReject(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApprove(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApproveOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenApprovedOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenApprovedOnBeforeCheckLinkedDoc(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenSubmittedOnAfterModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenSubmittedOnBeforeModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSubmitOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApprove(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApproverPermissions(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubmit(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced with OnBeforeGetTimeSheetActionDialogText and OnBeforeGetCommonTimeSheetActionDialogText to remove 100 characters limitation.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTimeSheetDialogText(ActionType: Option; LinesQty: Decimal; var ReturnText: Text[100]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTimeSheetActionDialogText(ActionType: Option; LinesQty: Decimal; var ReturnActionText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCommonTimeSheetActionDialogText(ActionType: Option; LinesQty: Decimal; var ReturnActionText: Text; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced with OnBeforeGetManagerTimeSheetActionDialogText to remove 100 characters limitation.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetManagerTimeSheetDialogText(ActionType: Option; LinesQty: Decimal; var ReturnText: Text[100]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetManagerTimeSheetActionDialogText(ActionType: Option; LinesQty: Decimal; var ReturnActionText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReject(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSubmitOnAfterCheck(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;
}

