// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.Resources.Setup;
using System.Security.User;
using System.Utilities;

codeunit 950 "Time Sheet Management"
{
    Permissions = TableData "Time Sheet Posting Entry" = ri,
                  TableData "Job Planning Line" = r,
                  TableData Employee = r;

    trigger OnRun()
    begin
    end;

    var
#if not CLEAN25
        ServTimeSheetMgt: Codeunit "Serv. Time Sheet Mgt.";
#endif
#pragma warning disable AA0074
        Text001: Label 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';
#pragma warning disable AA0470
        Text002: Label '%1 is already defined as Time Sheet Owner User ID for Resource No. %2 with type %3.', Comment = 'User1 is already defined as Resources for Resource No. LIFT with type Machine.';
        Text003: Label 'Time Sheet Header %1 is not found.', Comment = 'Time Sheet Header Archive 10 is not found.';
        Text005: Label 'Time Sheet Header Archive %1 is not found.', Comment = 'Time Sheet Header Archive 10 is not found.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotBeGreaterErr: Label 'cannot be greater than %1 %2.', Comment = '%1 - Quantity, %2 - Unit of measure. Example: Quantity cannot be greater than 8 HOUR.';
        NoLinesToCopyErr: Label 'There are no time sheet lines to copy.';
        CopyLinesQst: Label 'Do you want to copy lines from the previous time sheet (%1)?', Comment = '%1 - number';
        JobPlanningLinesNotFoundErr: Label 'Could not find project planning lines.';
        CreateLinesQst: Label 'Do you want to create lines from project planning (%1)?', Comment = '%1 - number';
        PageDataCaptionTxt: Label '%1 (%2)', Comment = '%1 - start date, %2 - Description,';

    procedure IsUserTimeSheetAdmin(UserId: Text): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then
            if UserSetup."Time Sheet Admin." then
                exit(true);
        exit(false);
    end;

    procedure FilterTimeSheets(var TimeSheetHeader: Record "Time Sheet Header"; FieldNo: Integer)
    begin
        FilterTimeSheets(TimeSheetHeader, FieldNo, false);
    end;

    procedure FilterTimeSheets(var TimeSheetHeader: Record "Time Sheet Header"; FieldNo: Integer; ApplyToAdmin: Boolean)
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFilterTimeSheets(TimeSheetHeader, FieldNo, ApplyToAdmin, IsHandled);
        if IsHandled then
            exit;

        if not ApplyToAdmin then begin
            UserSetup.SetLoadFields("Time Sheet Admin.");
            if UserSetup.Get(UserId) then;
        end;

        if ApplyToAdmin or (not UserSetup."Time Sheet Admin.") then begin
            TimeSheetHeader.FilterGroup(2);
            case FieldNo of
                TimeSheetHeader.FieldNo("Owner User ID"):
                    TimeSheetHeader.SetRange("Owner User ID", UserId);
                TimeSheetHeader.FieldNo("Approver User ID"):
                    TimeSheetHeader.SetRange("Approver User ID", UserId);
            end;
            TimeSheetHeader.FilterGroup(0);
        end;
    end;

    procedure FilterAllTimeSheetLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
        TimeSheetLine.FilterGroup(2);
        TimeSheetLine.SetFilter(Type, '<>%1', TimeSheetLine.Type::" ");
        TimeSheetLine.FilterGroup(0);
        case ActionType of
            ActionType::Submit:
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Open);
            ActionType::ReopenSubmitted:
                TimeSheetLine.SetFilter(Status, '%1|%2', TimeSheetLine.Status::Submitted, TimeSheetLine.Status::Rejected);
            ActionType::Reject,
            ActionType::Approve:
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
            ActionType::ReopenApproved:
                TimeSheetLine.SetFilter(Status, '%1|%2', TimeSheetLine.Status::Approved, TimeSheetLine.Status::Rejected);
        end;

        OnAfterFilterAllLines(TimeSheetLine, ActionType);
    end;

    procedure CheckTimeSheetNo(var TimeSheetHeader: Record "Time Sheet Header"; TimeSheetNo: Code[20])
    begin
        TimeSheetHeader.SetRange("No.", TimeSheetNo);
        if TimeSheetHeader.IsEmpty() then
            Error(Text003, TimeSheetNo);
    end;

    procedure SetTimeSheetNo(TimeSheetNo: Code[20]; var TimeSheetLine: Record "Time Sheet Line")
    begin
        TimeSheetLine.FilterGroup(2);
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        TimeSheetLine.FilterGroup(0);
        TimeSheetLine."Time Sheet No." := TimeSheetNo;
    end;

    procedure LookupOwnerTimeSheet(var TimeSheetNo: Code[20]; var TimeSheetLine: Record "Time Sheet Line"; var TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetList: Page "Time Sheet List";
    begin
        Commit();
        if TimeSheetNo <> '' then begin
            TimeSheetHeader.Get(TimeSheetNo);
            TimeSheetList.SetRecord(TimeSheetHeader);
        end;

        TimeSheetList.LookupMode := true;
        if TimeSheetList.RunModal() = ACTION::LookupOK then begin
            TimeSheetList.GetRecord(TimeSheetHeader);
            TimeSheetNo := TimeSheetHeader."No.";
            SetTimeSheetNo(TimeSheetNo, TimeSheetLine);
        end;
    end;

    procedure LookupApproverTimeSheet(var TimeSheetNo: Code[20]; var TimeSheetLine: Record "Time Sheet Line"; var TimeSheetHeader: Record "Time Sheet Header")
    var
        ManagerTimeSheetList: Page "Manager Time Sheet List";
    begin
        Commit();
        if TimeSheetNo <> '' then begin
            TimeSheetHeader.Get(TimeSheetNo);
            ManagerTimeSheetList.SetRecord(TimeSheetHeader);
        end;

        ManagerTimeSheetList.LookupMode := true;
        if ManagerTimeSheetList.RunModal() = ACTION::LookupOK then begin
            ManagerTimeSheetList.GetRecord(TimeSheetHeader);
            TimeSheetNo := TimeSheetHeader."No.";
            SetTimeSheetNo(TimeSheetNo, TimeSheetLine);
        end;
    end;

    procedure FormatDate(Date: Date; DOWFormatType: Option Full,Short): Text[30]
    begin
        case DOWFormatType of
            DOWFormatType::Full:
                exit(StrSubstNo('%1 %2', Date2DMY(Date, 1), Format(Date, 0, '<Weekday Text>')));
            DOWFormatType::Short:
                exit(StrSubstNo('%1 %2', Date2DMY(Date, 1), SelectStr(Date2DWY(Date, 1), Text001)));
        end;
    end;

    procedure CheckAccPeriod(Date: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        IsHandled: Boolean;
    begin
        OnBeforeCheckAccPeriod(Date, IsHandled);
        if IsHandled then
            exit;

        if AccountingPeriod.IsEmpty() then
            exit;
        AccountingPeriod.SetFilter("Starting Date", '..%1', Date);
        AccountingPeriod.FindLast();
        AccountingPeriod.TestField(Closed, false);
    end;

    procedure CheckResourceTimeSheetOwner(TimeSheetOwnerUserID: Code[50]; CurrResourceNo: Code[20])
    var
        Resource: Record Resource;
    begin
        Resource.Reset();
        Resource.SetFilter("No.", '<>%1', CurrResourceNo);
        Resource.SetRange(Type, Resource.Type::Person);
        Resource.SetRange("Time Sheet Owner User ID", TimeSheetOwnerUserID);
        if Resource.FindFirst() then
            Error(
              Text002,
              TimeSheetOwnerUserID,
              Resource."No.",
              Resource.Type);
    end;

    procedure CalcStatusFactBoxData(var TimeSheetHeader: Record "Time Sheet Header"; var OpenQty: Decimal; var SubmittedQty: Decimal; var RejectedQty: Decimal; var ApprovedQty: Decimal; var PostedQty: Decimal; var TotalQuantity: Decimal)
    var
        Status: Enum "Time Sheet Status";
    begin
        TotalQuantity := 0;
        TimeSheetHeader.SetRange("Date Filter", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
        OnCalcStatusFactBoxDataOnAfterTimeSheetHeaderSetFilters(TimeSheetHeader);
        OpenQty := TimeSheetHeader.CalcQtyWithStatus(Status::Open);

        SubmittedQty := TimeSheetHeader.CalcQtyWithStatus(Status::Submitted);

        RejectedQty := TimeSheetHeader.CalcQtyWithStatus(Status::Rejected);

        ApprovedQty := TimeSheetHeader.CalcQtyWithStatus(Status::Approved);

        TimeSheetHeader.SetRange("Status Filter");
        TimeSheetHeader.CalcFields(Quantity);
        TimeSheetHeader.CalcFields("Posted Quantity");
        TotalQuantity := TimeSheetHeader.Quantity;
        PostedQty := TimeSheetHeader."Posted Quantity";
    end;

    procedure CalcActSchedFactBoxData(TimeSheetHeader: Record "Time Sheet Header"; var DateDescription: array[7] of Text[30]; var DateQuantity: array[7] of Text[30]; var TotalQtyText: Text[30]; var TotalPresenceQty: Decimal; var AbsenceQty: Decimal)
    var
        TotalScheduledQty: Decimal;
    begin
        CalcActSchedFactBoxData(TimeSheetHeader, DateDescription, DateQuantity, TotalQtyText, TotalPresenceQty, AbsenceQty, TotalScheduledQty);
    end;

    procedure CalcActSchedFactBoxData(TimeSheetHeader: Record "Time Sheet Header"; var DateDescription: array[7] of Text[30]; var DateQuantity: array[7] of Text[30]; var TotalQtyText: Text[30]; var TotalPresenceQty: Decimal; var AbsenceQty: Decimal; var TotalScheduledQty: Decimal)
    var
        Resource: Record Resource;
        Calendar: Record Date;
        i: Integer;
    begin
        TotalPresenceQty := 0;
        TotalScheduledQty := 0;
        if Resource.Get(TimeSheetHeader."Resource No.") then begin
            Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
            Calendar.SetRange("Period Start", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
            if Calendar.FindSet() then
                repeat
                    i += 1;
                    DateDescription[i] := FormatDate(Calendar."Period Start", 0);
                    OnCalcActSchedFactBoxDataOnAfterSetDateDescription(TimeSheetHeader, Calendar, DateDescription[i]);
                    TimeSheetHeader.SetRange("Date Filter", Calendar."Period Start");
                    OnCalcActSchedFactBoxDataOnAfterTimeSheetHeaderSetFilters(TimeSheetHeader, Calendar);
                    TimeSheetHeader.CalcFields(Quantity);
                    Resource.SetRange("Date Filter", Calendar."Period Start");
                    OnCalcActSchedFactBoxDataOnBeforeResouceCalcFields(Resource, Calendar);
                    Resource.CalcFields(Capacity);
                    DateQuantity[i] := FormatActualSched(TimeSheetHeader.Quantity, Resource.Capacity);
                    TotalPresenceQty += TimeSheetHeader.Quantity;
                    TotalScheduledQty += Resource.Capacity;
                until Calendar.Next() = 0;
            TotalQtyText := FormatActualSched(TotalPresenceQty, TotalScheduledQty);
            TimeSheetHeader.SetRange("Type Filter", TimeSheetHeader."Type Filter"::Absence);
            TimeSheetHeader.SetRange("Date Filter", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
            TimeSheetHeader.CalcFields(Quantity);
            AbsenceQty := TimeSheetHeader.Quantity;
        end;

        OnAfterCalcActSchedFactBoxData(TimeSheetHeader, TotalQtyText, TotalPresenceQty, AbsenceQty);
    end;

    procedure FormatActualSched(ActualQty: Decimal; ScheduledQty: Decimal): Text[30]
    begin
        exit(
          Format(ActualQty, 0, '<Precision,2:2><Standard Format,0>') + '/' + Format(ScheduledQty, 0, '<Precision,2:2><Standard Format,0>'));
    end;

    procedure FilterTimeSheetsArchive(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive"; FieldNo: Integer)
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then;
        if not UserSetup."Time Sheet Admin." then begin
            TimeSheetHeaderArchive.FilterGroup(2);
            case FieldNo of
                TimeSheetHeaderArchive.FieldNo("Owner User ID"):
                    TimeSheetHeaderArchive.SetRange("Owner User ID", UserId);
                TimeSheetHeaderArchive.FieldNo("Approver User ID"):
                    TimeSheetHeaderArchive.SetRange("Approver User ID", UserId);
            end;
            TimeSheetHeaderArchive.FilterGroup(0);
        end;
    end;

    procedure CheckTimeSheetArchiveNo(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive"; TimeSheetNo: Code[20])
    begin
        TimeSheetHeaderArchive.SetRange("No.", TimeSheetNo);
        if TimeSheetHeaderArchive.IsEmpty() then
            Error(Text005, TimeSheetNo);
    end;

    procedure GetTimeSheetDataCaption(TimeSheetHeader: Record "Time Sheet Header"): Text
    begin
        if TimeSheetHeader.Description = '' then
            exit(Format(TimeSheetHeader."Starting Date", 0, 4));

        exit(StrSubstNo(PageDataCaptionTxt, Format(TimeSheetHeader."Starting Date", 0, 4), TimeSheetHeader.Description));
    end;

    procedure SetTimeSheetArchiveNo(TimeSheetNo: Code[20]; var TimeSheetLineArchive: Record "Time Sheet Line Archive")
    begin
        TimeSheetLineArchive.FilterGroup(2);
        TimeSheetLineArchive.SetRange("Time Sheet No.", TimeSheetNo);
        TimeSheetLineArchive.FilterGroup(0);
        TimeSheetLineArchive."Time Sheet No." := TimeSheetNo;
    end;

    procedure LookupOwnerTimeSheetArchive(var TimeSheetNo: Code[20]; var TimeSheetLineArchive: Record "Time Sheet Line Archive"; var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    var
        TimeSheetArchiveList: Page "Time Sheet Archive List";
    begin
        Commit();
        if TimeSheetNo <> '' then begin
            TimeSheetHeaderArchive.Get(TimeSheetNo);
            TimeSheetArchiveList.SetRecord(TimeSheetHeaderArchive);
        end;

        TimeSheetArchiveList.LookupMode := true;
        if TimeSheetArchiveList.RunModal() = ACTION::LookupOK then begin
            TimeSheetArchiveList.GetRecord(TimeSheetHeaderArchive);
            TimeSheetNo := TimeSheetHeaderArchive."No.";
            SetTimeSheetArchiveNo(TimeSheetNo, TimeSheetLineArchive);
        end;
    end;

    procedure LookupApproverTimeSheetArchive(var TimeSheetNo: Code[20]; var TimeSheetLineArchive: Record "Time Sheet Line Archive"; var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    var
        ManagerTimeSheetArcList: Page "Manager Time Sheet Arc. List";
    begin
        Commit();
        if TimeSheetNo <> '' then begin
            TimeSheetHeaderArchive.Get(TimeSheetNo);
            ManagerTimeSheetArcList.SetRecord(TimeSheetHeaderArchive);
        end;

        ManagerTimeSheetArcList.LookupMode := true;
        if ManagerTimeSheetArcList.RunModal() = ACTION::LookupOK then begin
            ManagerTimeSheetArcList.GetRecord(TimeSheetHeaderArchive);
            TimeSheetNo := TimeSheetHeaderArchive."No.";
            SetTimeSheetArchiveNo(TimeSheetNo, TimeSheetLineArchive);
        end;
    end;

    procedure CalcSummaryArcFactBoxData(TimeSheetHeaderArchive: Record "Time Sheet Header Archive"; var DateDescription: array[7] of Text[30]; var DateQuantity: array[7] of Decimal; var TotalQuantity: Decimal; var AbsenceQuantity: Decimal)
    var
        Calendar: Record Date;
        i: Integer;
    begin
        TotalQuantity := 0;
        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", TimeSheetHeaderArchive."Starting Date", TimeSheetHeaderArchive."Ending Date");
        if Calendar.FindSet() then
            repeat
                i += 1;
                DateDescription[i] := FormatDate(Calendar."Period Start", 0);
                TimeSheetHeaderArchive.SetRange("Date Filter", Calendar."Period Start");
                TimeSheetHeaderArchive.CalcFields(Quantity);
                DateQuantity[i] := TimeSheetHeaderArchive.Quantity;
                TotalQuantity += TimeSheetHeaderArchive.Quantity;
            until Calendar.Next() = 0;

        TimeSheetHeaderArchive.SetRange("Type Filter", TimeSheetHeaderArchive."Type Filter"::Absence);
        TimeSheetHeaderArchive.SetRange("Date Filter", TimeSheetHeaderArchive."Starting Date", TimeSheetHeaderArchive."Ending Date");
        TimeSheetHeaderArchive.CalcFields(Quantity);
        AbsenceQuantity := TimeSheetHeaderArchive.Quantity;
    end;

    procedure MoveTimeSheetToArchive(TimeSheetHeader: Record "Time Sheet Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
        TimeSheetDetailArchive: Record "Time Sheet Detail Archive";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
    begin
        TimeSheetHeader.Check();

        TimeSheetHeaderArchive.TransferFields(TimeSheetHeader);
        OnBeforeTimeSheetHeaderArchiveInsert(TimeSheetHeaderArchive, TimeSheetHeader);
        TimeSheetHeaderArchive.Insert();

        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        if TimeSheetLine.FindSet() then begin
            repeat
                TimeSheetLineArchive.TransferFields(TimeSheetLine);
                OnBeforeTimeSheetLineArchiveInsert(TimeSheetLineArchive, TimeSheetLine);
                TimeSheetLineArchive.Insert();
            until TimeSheetLine.Next() = 0;
            TimeSheetLine.DeleteAll();
        end;

        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        if TimeSheetDetail.FindSet() then begin
            repeat
                TimeSheetDetailArchive.TransferFields(TimeSheetDetail);
                OnBeforeTimeSheetDetailArchiveInsert(TimeSheetDetailArchive, TimeSheetDetail);
                TimeSheetDetailArchive.Insert();
            until TimeSheetDetail.Next() = 0;
            TimeSheetDetail.DeleteAll();
        end;

        TimeSheetCommentLine.SetRange("No.", TimeSheetHeader."No.");
        if TimeSheetCommentLine.FindSet() then begin
            repeat
                TimeSheetCmtLineArchive.TransferFields(TimeSheetCommentLine);
                OnBeforeTimeSheetCmtLineArchiveInsert(TimeSheetCmtLineArchive, TimeSheetCommentLine);
                TimeSheetCmtLineArchive.Insert();
            until TimeSheetCommentLine.Next() = 0;
            TimeSheetCommentLine.DeleteAll();
        end;

        TimeSheetHeader.Delete();
    end;

    procedure CheckTimeSheetLineFieldsVisible(var WorkTypeCodeVisible: Boolean; var JobFieldsVisible: Boolean; var ChargeableVisible: Boolean; var ServiceOrderNoVisible: Boolean; var AbsenceCauseVisible: Boolean; var AssemblyOrderNoVisible: Boolean)
    var
        Resource: Record Resource;
        CauseOfAbsence: Record "Cause of Absence";
        Job: Record Job;
    begin
        OnBeforeCheckTimeSheetLineFieldsVisible(ServiceOrderNoVisible);

        AssemblyOrderNoVisible := false;  //not in use for now.
        JobFieldsVisible := not Job.IsEmpty;
        AbsenceCauseVisible := not CauseOfAbsence.IsEmpty;
        ChargeableVisible := JobFieldsVisible or ServiceOrderNoVisible;
        WorkTypeCodeVisible := not Resource.IsEmpty or JobFieldsVisible or ServiceOrderNoVisible;

        OnAfterCheckTimeSheetLineFieldsVisible(WorkTypeCodeVisible, JobFieldsVisible, ChargeableVisible, ServiceOrderNoVisible, AbsenceCauseVisible, AssemblyOrderNoVisible);
    end;

    procedure SelectAndCopyTimeSheetLines(ToTimeSheetHeader: Record "Time Sheet Header"; CopyComments: Boolean)
    var
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
        TimeSheetLines: Page "Time Sheet Lines";
        NextLineNo: Integer;
        IsArchive: Boolean;
    begin
        TimeSheetLines.LookupMode := true;
        TimeSheetLines.Editable(false);
        TimeSheetLines.SetForTimeSheetHeader(ToTimeSheetHeader);
        TimeSheetLines.GetData(TempTimeSheetLine, ToTimeSheetHeader."Resource No.", 0D, true, true);
        TimeSheetLines.SetRec(TempTimeSheetLine);

        if TimeSheetLines.RunModal() <> ACTION::LookupOK then
            exit;
        TimeSheetLines.SetSelectionFilter(TempTimeSheetLine);
        if (TempTimeSheetLine.Count() = 0) then begin
            Message(NoLinesToCopyErr);
            exit;
        end;

        NextLineNo := ToTimeSheetHeader.GetLastLineNo();

        if TempTimeSheetLine.Count() = 1 then begin
            TempTimeSheetLine.FindFirst();
            if TempTimeSheetLine.Posted then begin
                TimeSheetLineArchive.SetLoadFields("Time Sheet No.", "Line No.");
                IsArchive := TimeSheetLineArchive.Get(TempTimeSheetLine."Time Sheet No.", TempTimeSheetLine."Line No.");
                if IsArchive then begin
                    if not CheckUserWantAllLinesFromOneTimeSheetHeaderArchive(TempTimeSheetLine) then
                        exit;
                end else
                    if not CheckUserWantAllLinesFromOneTimeSheetHeader(TempTimeSheetLine) then
                        exit;
            end else
                if not CheckUserWantAllLinesFromOneTimeSheetHeader(TempTimeSheetLine) then
                    exit;
        end;
        TimeSheetLineArchive.SetLoadFields();

        if TempTimeSheetLine.FindSet() then
            repeat
                if not TempTimeSheetLine.Posted then
                    CopyTimeSheetLine(ToTimeSheetHeader, TempTimeSheetLine, CopyComments, NextLineNo)
                else begin
                    IsArchive := TimeSheetLineArchive.Get(TempTimeSheetLine."Time Sheet No.", TempTimeSheetLine."Line No.");
                    if IsArchive then
                        CopyTimeSheetLineArchive(ToTimeSheetHeader, TimeSheetLineArchive, CopyComments, NextLineNo)
                    else
                        CopyTimeSheetLine(ToTimeSheetHeader, TempTimeSheetLine, CopyComments, NextLineNo)
                end;
            until TempTimeSheetLine.Next() = 0;
    end;

    local procedure CheckUserWantAllLinesFromOneTimeSheetHeader(var TempTimeSheetLine: Record "Time Sheet Line" temporary) ContinueProcessing: Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
        LinesToCopy: Integer;
        TimeSheetLineCount: Integer;
    begin
        ContinueProcessing := true;
        TimeSheetLine.SetRange("Time Sheet No.", TempTimeSheetLine."Time Sheet No.");
        TimeSheetLine.SetExclusionTypeFilter();
        TimeSheetLineCount := TimeSheetLine.Count;
        if TimeSheetLineCount > 1 then begin
            TimeSheetLine.FindLast();
            if TimeSheetLine."Line No." = TempTimeSheetLine."Line No." then begin
                LinesToCopy := ConfirmCopyTimeSheetLines(TimeSheetLineCount, TempTimeSheetLine."Time Sheet No.");
                if LinesToCopy < 1 then
                    exit(false);

                if LinesToCopy = 1 then begin //all lines
                    TempTimeSheetLine.Reset();
                    TempTimeSheetLine.DeleteAll();
                    if TimeSheetLine.FindSet() then
                        repeat
                            TempTimeSheetLine.Init();
                            TempTimeSheetLine := TimeSheetLine;
                            if TempTimeSheetLine.Insert() then;
                        until TimeSheetLine.Next() = 0;
                end;
            end;
        end;
    end;

    local procedure CheckUserWantAllLinesFromOneTimeSheetHeaderArchive(var TempTimeSheetLine: Record "Time Sheet Line" temporary) ContinueProcessing: Boolean
    var
        TimeSheetLineArchive: Record "Time Sheet Line Archive";

        LinesToCopy: Integer;
        TimeSheetLineCount: Integer;
    begin
        ContinueProcessing := true;
        TimeSheetLineArchive.SetRange("Time Sheet No.", TempTimeSheetLine."Time Sheet No.");
        TimeSheetLineArchive.SetExclusionTypeFilter();
        TimeSheetLineCount := TimeSheetLineArchive.Count;
        if TimeSheetLineCount > 1 then begin
            TimeSheetLineArchive.FindLast();
            if TimeSheetLineArchive."Line No." = TempTimeSheetLine."Line No." then begin
                LinesToCopy := ConfirmCopyTimeSheetLines(TimeSheetLineCount, TempTimeSheetLine."Time Sheet No.");
                if LinesToCopy < 1 then
                    exit(false);

                if LinesToCopy = 1 then begin //all lines
                    TempTimeSheetLine.Reset();
                    TempTimeSheetLine.DeleteAll();
                    if TimeSheetLineArchive.FindSet() then
                        repeat
                            TempTimeSheetLine.Init();
                            TempTimeSheetLine.TransferFields(TimeSheetLineArchive);
                            if TempTimeSheetLine.Insert() then;
                        until TimeSheetLineArchive.Next() = 0;
                end;
            end;
        end;
    end;

    local procedure ConfirmCopyTimeSheetLines(TimeSheetLineCount: Integer; TimeSheetNo: Code[20]): Integer
    var
        SelectLineConfirmTxt: Label 'All lines,Selected line';
        StrMenuInstructionTxt: Label 'You selected just 1 of %1 lines from Time Sheet %2. Do you want to copy:', Comment = '%1 - Lines count, %2 - Time Sheet No.';
    begin
        exit(Dialog.StrMenu(SelectLineConfirmTxt, 2, StrSubstNo(StrMenuInstructionTxt, TimeSheetLineCount, TimeSheetNo)));
    end;



    procedure CheckCopyPrevTimeSheetLines(TimeSheetHeader: Record "Time Sheet Header")
    var
        QtyToBeCopied: Integer;
    begin
        QtyToBeCopied := CalcPrevTimeSheetLines(TimeSheetHeader);
        if QtyToBeCopied = 0 then
            Message(NoLinesToCopyErr)
        else
            if Confirm(CopyLinesQst, true, QtyToBeCopied) then
                CopyPrevTimeSheetLines(TimeSheetHeader);
    end;

    procedure CopyPrevTimeSheetLines(ToTimeSheetHeader: Record "Time Sheet Header")
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        LineNo := ToTimeSheetHeader.GetLastLineNo();

        FromTimeSheetHeader.Get(ToTimeSheetHeader."No.");
        FromTimeSheetHeader.SetCurrentKey("Resource No.", "Starting Date");
        FromTimeSheetHeader.SetRange("Resource No.", ToTimeSheetHeader."Resource No.");
        if FromTimeSheetHeader.Next(-1) <> 0 then begin
            FromTimeSheetLine.SetRange("Time Sheet No.", FromTimeSheetHeader."No.");
            FromTimeSheetLine.SetExclusionTypeFilter();
            if FromTimeSheetLine.FindSet() then
                repeat
                    IsHandled := false;
                    OnCopyPrevTimeSheetLinesOnBeforeCopyLine(FromTimeSheetLine, IsHandled);
                    if not IsHandled then
                        CopyTimeSheetLine(ToTimeSheetHeader, FromTimeSheetLine, false, LineNo);
                until FromTimeSheetLine.Next() = 0;
        end;

        OnAfterCopyPrevTimeSheetLines();
    end;

    local procedure CopyTimeSheetLine(ToTimeSheetHeader: Record "Time Sheet Header"; FromTimeSheetLine: Record "Time Sheet Line"; CopyComments: Boolean; var NextLineNo: Integer)
    var
        ToTimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyTimeSheetLine(ToTimeSheetHeader, FromTimeSheetLine, CopyComments, NextLineNo, IsHandled);
        if not IsHandled then begin
            NextLineNo := NextLineNo + 10000;

            ToTimeSheetLine.Init();
            ToTimeSheetLine."Time Sheet No." := ToTimeSheetHeader."No.";
            ToTimeSheetLine."Line No." := NextLineNo;
            ToTimeSheetLine."Time Sheet Starting Date" := ToTimeSheetHeader."Starting Date";
            ToTimeSheetLine.Type := FromTimeSheetLine.Type;
            case ToTimeSheetLine.Type of
                ToTimeSheetLine.Type::Job:
                    begin
                        ToTimeSheetLine.Validate("Job No.", FromTimeSheetLine."Job No.");
                        ToTimeSheetLine.Validate("Job Task No.", FromTimeSheetLine."Job Task No.");
                    end;
                ToTimeSheetLine.Type::Absence:
                    ToTimeSheetLine.Validate("Cause of Absence Code", FromTimeSheetLine."Cause of Absence Code");
            end;
            ToTimeSheetLine.Description := FromTimeSheetLine.Description;
            ToTimeSheetLine.Chargeable := FromTimeSheetLine.Chargeable;
            ToTimeSheetLine."Work Type Code" := FromTimeSheetLine."Work Type Code";
            OnBeforeToTimeSheetLineInsert(ToTimeSheetLine, FromTimeSheetLine);
            ToTimeSheetLine.Insert();

            CopyTimeSheetLineDetails(ToTimeSheetLine, FromTimeSheetLine);

            if CopyComments then
                CopyTimeSheetLineComments(ToTimeSheetLine, FromTimeSheetLine);
        end;
    end;

    local procedure CopyTimeSheetLineDetails(ToTimeSheetLine: Record "Time Sheet Line"; FromTimeSheetLine: Record "Time Sheet Line")
    var
        ToTimeSheetDetail: Record "Time Sheet Detail";
        FromTimeSheetDetail: Record "Time Sheet Detail";
        IsHandled: Boolean;
    begin
        FromTimeSheetDetail.SetRange("Time Sheet No.", FromTimeSheetLine."Time Sheet No.");
        FromTimeSheetDetail.SetRange("Time Sheet Line No.", FromTimeSheetLine."Line No.");
        if FromTimeSheetDetail.FindSet() then
            repeat
                ToTimeSheetDetail.Init();
                ToTimeSheetDetail.TransferFields(FromTimeSheetDetail);
                ToTimeSheetDetail."Time Sheet No." := ToTimeSheetLine."Time Sheet No.";
                ToTimeSheetDetail."Time Sheet Line No." := ToTimeSheetLine."Line No.";
                ToTimeSheetDetail.Date := ToTimeSheetLine."Time Sheet Starting Date" + (FromTimeSheetDetail."Date" - FromTimeSheetLine."Time Sheet Starting Date");
                ToTimeSheetDetail.Status := "Time Sheet Status"::Open;
                ToTimeSheetDetail.Posted := false;
                ToTimeSheetDetail."Posted Quantity" := 0;
                IsHandled := false;
                OnBeforeTimeSheetDetailInsert(ToTimeSheetDetail, FromTimeSheetDetail, IsHandled);
                if not IsHandled then
                    ToTimeSheetDetail.Insert();
            until FromTimeSheetDetail.Next() = 0;
    end;

    local procedure CopyTimeSheetLineComments(ToTimeSheetLine: Record "Time Sheet Line"; FromTimeSheetLine: Record "Time Sheet Line")
    var
        ToTimeSheetCommentLine: Record "Time Sheet Comment Line";
        FromTimeSheetCommentLine: Record "Time Sheet Comment Line";
    begin
        FromTimeSheetCommentLine.SetRange("No.", FromTimeSheetLine."Time Sheet No.");
        FromTimeSheetCommentLine.SetRange("Time Sheet Line No.", FromTimeSheetLine."Line No.");
        if FromTimeSheetCommentLine.FindSet() then
            repeat
                ToTimeSheetCommentLine.Init();
                ToTimeSheetCommentLine.TransferFields(FromTimeSheetCommentLine);
                ToTimeSheetCommentLine."No." := ToTimeSheetLine."Time Sheet No.";
                ToTimeSheetCommentLine."Time Sheet Line No." := ToTimeSheetLine."Line No.";
                ToTimeSheetCommentLine.Insert();
            until FromTimeSheetCommentLine.Next() = 0;
    end;

    local procedure CopyTimeSheetLineArchive(ToTimeSheetHeader: Record "Time Sheet Header"; FromTimeSheetLineArchive: Record "Time Sheet Line Archive"; CopyComments: Boolean; var NextLineNo: Integer)
    var
        ToTimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyTimeSheetLineArchive(ToTimeSheetHeader, FromTimeSheetLineArchive, CopyComments, NextLineNo, IsHandled);
        if not IsHandled then begin
            NextLineNo := NextLineNo + 10000;

            ToTimeSheetLine.Init();
            ToTimeSheetLine."Time Sheet No." := ToTimeSheetHeader."No.";
            ToTimeSheetLine."Line No." := NextLineNo;
            ToTimeSheetLine."Time Sheet Starting Date" := ToTimeSheetHeader."Starting Date";
            ToTimeSheetLine.Type := FromTimeSheetLineArchive.Type;
            case ToTimeSheetLine.Type of
                ToTimeSheetLine.Type::Job:
                    begin
                        ToTimeSheetLine.Validate("Job No.", FromTimeSheetLineArchive."Job No.");
                        ToTimeSheetLine.Validate("Job Task No.", FromTimeSheetLineArchive."Job Task No.");
                    end;
                ToTimeSheetLine.Type::Absence:
                    ToTimeSheetLine.Validate("Cause of Absence Code", FromTimeSheetLineArchive."Cause of Absence Code");
            end;
            ToTimeSheetLine.Description := FromTimeSheetLineArchive.Description;
            ToTimeSheetLine.Chargeable := FromTimeSheetLineArchive.Chargeable;
            ToTimeSheetLine."Work Type Code" := FromTimeSheetLineArchive."Work Type Code";
            OnCopyTimeSheetLineArchiveOnBeforeToTimeSheetLineInsert(ToTimeSheetLine, FromTimeSheetLineArchive);
            ToTimeSheetLine.Insert();

            CopyTimeSheetLineArchiveDetails(ToTimeSheetLine, FromTimeSheetLineArchive);

            if CopyComments then
                CopyTimeSheetLineArchiveComments(ToTimeSheetLine, FromTimeSheetLineArchive);
        end;
    end;

    local procedure CopyTimeSheetLineArchiveDetails(ToTimeSheetLine: Record "Time Sheet Line"; FromTimeSheetLineArchive: Record "Time Sheet Line Archive")
    var
        ToTimeSheetDetail: Record "Time Sheet Detail";
        FromTimeSheetDetailArchive: Record "Time Sheet Detail Archive";
    begin
        FromTimeSheetDetailArchive.SetRange("Time Sheet No.", FromTimeSheetLineArchive."Time Sheet No.");
        FromTimeSheetDetailArchive.SetRange("Time Sheet Line No.", FromTimeSheetLineArchive."Line No.");
        if FromTimeSheetDetailArchive.FindSet() then
            repeat
                ToTimeSheetDetail.Init();
                ToTimeSheetDetail.TransferFields(FromTimeSheetDetailArchive);
                ToTimeSheetDetail."Time Sheet No." := ToTimeSheetLine."Time Sheet No.";
                ToTimeSheetDetail."Time Sheet Line No." := ToTimeSheetLine."Line No.";
                ToTimeSheetDetail.Date := ToTimeSheetLine."Time Sheet Starting Date" + (FromTimeSheetDetailArchive."Date" - FromTimeSheetLineArchive."Time Sheet Starting Date");
                ToTimeSheetDetail.Status := "Time Sheet Status"::Open;
                ToTimeSheetDetail.Posted := false;
                ToTimeSheetDetail."Posted Quantity" := 0;
                ToTimeSheetDetail.Insert();
            until FromTimeSheetDetailArchive.Next() = 0;
    end;

    local procedure CopyTimeSheetLineArchiveComments(ToTimeSheetLine: Record "Time Sheet Line"; FromTimeSheetLineArchive: Record "Time Sheet Line Archive")
    var
        ToTimeSheetCommentLine: Record "Time Sheet Comment Line";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
    begin
        TimeSheetCmtLineArchive.SetRange("No.", FromTimeSheetLineArchive."Time Sheet No.");
        TimeSheetCmtLineArchive.SetRange("Time Sheet Line No.", FromTimeSheetLineArchive."Line No.");
        if TimeSheetCmtLineArchive.FindSet() then
            repeat
                ToTimeSheetCommentLine.Init();
                ToTimeSheetCommentLine.TransferFields(TimeSheetCmtLineArchive);
                ToTimeSheetCommentLine."No." := ToTimeSheetLine."Time Sheet No.";
                ToTimeSheetCommentLine."Time Sheet Line No." := ToTimeSheetLine."Line No.";
                ToTimeSheetCommentLine.Insert();
            until TimeSheetCmtLineArchive.Next() = 0;
    end;

    procedure CalcPrevTimeSheetLines(ToTimeSheetHeader: Record "Time Sheet Header") LinesQty: Integer
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetHeader.Get(ToTimeSheetHeader."No.");
        TimeSheetHeader.SetCurrentKey("Resource No.", "Starting Date");
        TimeSheetHeader.SetRange("Resource No.", ToTimeSheetHeader."Resource No.");
        if TimeSheetHeader.Next(-1) <> 0 then begin
            TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
            TimeSheetLine.SetExclusionTypeFilter();
            LinesQty := TimeSheetLine.Count();
        end;
    end;

    procedure CheckCreateLinesFromJobPlanning(TimeSheetHeader: Record "Time Sheet Header"): Integer
    var
        QtyToBeCreated: Integer;
    begin
        QtyToBeCreated := CalcLinesFromJobPlanning(TimeSheetHeader);
        if QtyToBeCreated = 0 then
            Message(JobPlanningLinesNotFoundErr)
        else
            if Confirm(CreateLinesQst, true, QtyToBeCreated) then
                exit(CreateLinesFromJobPlanning(TimeSheetHeader));
    end;

    procedure CreateLinesFromJobPlanning(TimeSheetHeader: Record "Time Sheet Header") CreatedLinesQty: Integer
    var
        TimeSheetLine: Record "Time Sheet Line";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        LineNo: Integer;
    begin
        LineNo := TimeSheetHeader.GetLastLineNo();

        FillJobPlanningBuffer(TimeSheetHeader, TempJobPlanningLine);

        TempJobPlanningLine.Reset();
        if TempJobPlanningLine.FindSet() then
            repeat
                LineNo := LineNo + 10000;
                CreatedLinesQty := CreatedLinesQty + 1;
                TimeSheetLine.Init();
                TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
                TimeSheetLine."Line No." := LineNo;
                TimeSheetLine."Time Sheet Starting Date" := TimeSheetHeader."Starting Date";
                TimeSheetLine.Validate(Type, TimeSheetLine.Type::Job);
                TimeSheetLine.Validate("Job No.", TempJobPlanningLine."Job No.");
                TimeSheetLine.Validate("Job Task No.", TempJobPlanningLine."Job Task No.");
                OnCreateLinesFromJobPlanningOnBeforeTimeSheetLineInsert(TimeSheetLine, TempJobPlanningLine);
                TimeSheetLine.Insert();
            until TempJobPlanningLine.Next() = 0;
    end;

    procedure CalcLinesFromJobPlanning(TimeSheetHeader: Record "Time Sheet Header"): Integer
    var
        TempJobPlanningLine: Record "Job Planning Line" temporary;
    begin
        FillJobPlanningBuffer(TimeSheetHeader, TempJobPlanningLine);
        exit(TempJobPlanningLine.Count);
    end;

    local procedure FillJobPlanningBuffer(TimeSheetHeader: Record "Time Sheet Header"; var JobPlanningLineBuffer: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        SkipLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillJobPlanningBuffer(JobPlanningLine, JobPlanningLineBuffer, TimeSheetHeader, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("No.", TimeSheetHeader."Resource No.");
        JobPlanningLine.SetRange("Planning Date", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
        if JobPlanningLine.FindSet() then
            repeat
                SkipLine := TimesheetLineWithJobPlanningLineExists(TimeSheetHeader, JobPlanningLine);
                if not SkipLine then
                    SkipLine := JobPlanningLineIsNotValidForTimesheetLine(JobPlanningLine);
                OnCheckInsertJobPlanningLine(JobPlanningLine, JobPlanningLineBuffer, SkipLine);
                if not SkipLine then begin
                    JobPlanningLineBuffer.SetRange("Job No.", JobPlanningLine."Job No.");
                    JobPlanningLineBuffer.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                    if JobPlanningLineBuffer.IsEmpty() then begin
                        JobPlanningLineBuffer."Job No." := JobPlanningLine."Job No.";
                        JobPlanningLineBuffer."Job Task No." := JobPlanningLine."Job Task No.";
                        OnFillJobPlanningBufferOnBeforeJobPlanningLineBufferInsert(JobPlanningLine, JobPlanningLineBuffer);
                        JobPlanningLineBuffer.Insert();
                    end;
                end;
            until JobPlanningLine.Next() = 0;
        JobPlanningLineBuffer.Reset();
    end;

    local procedure TimesheetLineWithJobPlanningLineExists(TimeSheetHeader: Record "Time Sheet Header"; JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", JobPlanningLine."Job No.");
        TimeSheetLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        exit(not TimeSheetLine.IsEmpty());
    end;

    local procedure JobPlanningLineIsNotValidForTimesheetLine(JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        Job: Record Job;
    begin
        if JobPlanningLine."Job No." = '' then
            exit(true);

        if not Job.Get(JobPlanningLine."Job No.") then
            exit(true);

        if (Job.Blocked = Job.Blocked::All) or (Job.Status = Job.Status::Completed) then
            exit(true);

        exit(false);
    end;

    procedure FindTimeSheet(var TimeSheetHeader: Record "Time Sheet Header"; Which: Option Prev,Next): Code[20]
    begin
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetCurrentKey("Resource No.", "Starting Date");
        TimeSheetHeader.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        case Which of
            Which::Prev:
                TimeSheetHeader.Next(-1);
            Which::Next:
                TimeSheetHeader.Next(1);
        end;
        exit(TimeSheetHeader."No.");
    end;

    procedure FindTimeSheetArchive(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive"; Which: Option Prev,Next): Code[20]
    begin
        TimeSheetHeaderArchive.Reset();
        TimeSheetHeaderArchive.SetCurrentKey("Resource No.", "Starting Date");
        TimeSheetHeaderArchive.SetRange("Resource No.", TimeSheetHeaderArchive."Resource No.");
        OnFindTimeSheetArchiveOnAfterSetFilters(TimeSheetHeaderArchive);
        case Which of
            Which::Prev:
                TimeSheetHeaderArchive.Next(-1);
            Which::Next:
                TimeSheetHeaderArchive.Next(1);
        end;
        exit(TimeSheetHeaderArchive."No.");
    end;

    procedure GetDateFilter(StartingDate: Date; EndingDate: Date) DateFilter: Text[30]
    var
        Date: Record Date;
    begin
        if StartingDate = 0D then begin
            Date.FindFirst();
            StartingDate := Date."Period Start";
        end;
        if EndingDate = 0D then begin
            Date.FindLast();
            EndingDate := Date."Period Start";
        end;
        DateFilter := StrSubstNo('%1..%2', StartingDate, EndingDate);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServTimeSheetMgt', '25.0')]
    procedure CreateServDocLinesFromTS(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        ServTimeSheetMgt.CreateServLinesFromTS(ServiceHeader, TimeSheetLine, false);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServTimeSheetMgt', '25.0')]
    procedure CreateServDocLinesFromTSLine(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TimeSheetLine: Record "Time Sheet Line")
    begin
        ServTimeSheetMgt.CreateServLinesFromTS(ServiceHeader, TimeSheetLine, true);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServTimeSheetMgt', '25.0')]
    procedure CreateTSLineFromServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; DocumentNo: Code[20]; Chargeable: Boolean)
    begin
        ServTimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, DocumentNo, false);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServTimeSheetMgt', '25.0')]
    procedure CreateTSLineFromServiceShptLine(ServiceShipmentLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
        ServTimeSheetMgt.CreateTSLineFromServiceShptLine(ServiceShipmentLine);
    end;
#endif

    procedure CreateTSLineFromDocLine(TableID: Integer; ResourceNo: Code[20]; PostingDate: Date; DocumentNo: Code[20]; OrderNo: Code[20]; OrderLineNo: Integer; WorkTypeCode: Code[10]; Chargbl: Boolean; Desc: Text[100]; Quantity: Decimal)
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        LineNo: Integer;
    begin
        Resource.Get(ResourceNo);
        if not Resource."Use Time Sheet" then
            exit;

        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        TimeSheetHeader.SetFilter("Starting Date", '..%1', PostingDate);
        TimeSheetHeader.SetFilter("Ending Date", '%1..', PostingDate);
        TimeSheetHeader.FindFirst();

        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        if TimeSheetLine.FindLast() then;
        LineNo := TimeSheetLine."Line No." + 10000;

        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        TimeSheetLine."Line No." := LineNo;
        TimeSheetLine."Time Sheet Starting Date" := TimeSheetHeader."Starting Date";
        case TableID of
            DATABASE::"Assembly Line":
                begin
                    TimeSheetLine.Type := TimeSheetLine.Type::"Assembly Order";
                    TimeSheetLine."Assembly Order No." := OrderNo;
                    TimeSheetLine."Assembly Order Line No." := OrderLineNo;
                end;
        end;
        TimeSheetLine.Description := Desc;
        TimeSheetLine."Work Type Code" := WorkTypeCode;
        TimeSheetLine.Chargeable := Chargbl;
        TimeSheetLine."Approver ID" := TimeSheetHeader."Approver User ID";
        TimeSheetLine."Approved By" := CopyStr(UserId(), 1, MaxStrLen(TimeSheetLine."Approved By"));
        TimeSheetLine."Approval Date" := Today();
        TimeSheetLine.Status := TimeSheetLine.Status::Approved;
        TimeSheetLine.Posted := true;
        OnCreateTSLineFromDocLineOnBeforeTimeSheetLineInsert(TimeSheetLine, TableID, OrderNo, OrderLineNo);
        TimeSheetLine.Insert();

        TimeSheetDetail.Init();
        TimeSheetDetail.CopyFromTimeSheetLine(TimeSheetLine);
        TimeSheetDetail.Date := PostingDate;
        TimeSheetDetail.Quantity := Quantity;
        TimeSheetDetail."Posted Quantity" := Quantity;
        TimeSheetDetail.Posted := true;
        TimeSheetDetail.Insert();

        CreateTSPostingEntry(TimeSheetDetail, Quantity, PostingDate, DocumentNo, TimeSheetLine.Description);
    end;

    procedure CreateTSLineFromAssemblyLine(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; Qty: Decimal)
    begin
        AssemblyLine.TestField(Type, AssemblyLine.Type::Resource);

        CreateTSLineFromDocLine(
            DATABASE::"Assembly Line",
            AssemblyLine."No.",
            AssemblyHeader."Posting Date",
            AssemblyHeader."Posting No.",
            AssemblyLine."Document No.",
            AssemblyLine."Line No.",
            '',
            true,
            AssemblyLine.Description,
            Qty);
    end;

    procedure CreateTSPostingEntry(TimeSheetDetail: Record "Time Sheet Detail"; Qty: Decimal; PostingDate: Date; DocumentNo: Code[20]; Desc: Text[100])
    var
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
    begin
        TimeSheetPostingEntry.Init();
        TimeSheetPostingEntry."Time Sheet No." := TimeSheetDetail."Time Sheet No.";
        TimeSheetPostingEntry."Time Sheet Line No." := TimeSheetDetail."Time Sheet Line No.";
        TimeSheetPostingEntry."Time Sheet Date" := TimeSheetDetail.Date;
        TimeSheetPostingEntry.Quantity := Qty;
        TimeSheetPostingEntry."Document No." := DocumentNo;
        TimeSheetPostingEntry."Posting Date" := PostingDate;
        TimeSheetPostingEntry.Description := Desc;
        TimeSheetPostingEntry.Insert();

        OnAfterCreateTSPostingEntry(TimeSheetDetail, TimeSheetPostingEntry);
    end;

    procedure CheckTSLineDetailPosting(TimeSheetNo: Code[20]; TimeSheetLineNo: Integer; TimeSheetDate: Date; QtyToPost: Decimal; QtyPerUnitOfMeasure: Decimal; var MaxAvailableQty: Decimal): Boolean
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        MaxAvailableQtyBase: Decimal;
    begin
        TimeSheetDetail.Get(TimeSheetNo, TimeSheetLineNo, TimeSheetDate);
        TimeSheetDetail.TestField(Status, TimeSheetDetail.Status::Approved);
        TimeSheetDetail.TestField(Posted, false);

        MaxAvailableQtyBase := TimeSheetDetail.GetMaxQtyToPost();
        MaxAvailableQty := MaxAvailableQtyBase * QtyPerUnitOfMeasure;
        exit(QtyToPost <= MaxAvailableQty);
    end;

    procedure CheckResJnlLine(ResJnlLine: Record "Res. Journal Line")
    var
        MaxAvailableQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckResJnlLine(ResJnlLine, IsHandled);
        if IsHandled then
            exit;

        ResJnlLine.TestField("Qty. per Unit of Measure");
        if not CheckTSLineDetailPosting(
             ResJnlLine."Time Sheet No.",
             ResJnlLine."Time Sheet Line No.",
             ResJnlLine."Time Sheet Date",
             ResJnlLine.Quantity,
             ResJnlLine."Qty. per Unit of Measure",
             MaxAvailableQty)
        then
            ResJnlLine.FieldError(Quantity, StrSubstNo(CannotBeGreaterErr, MaxAvailableQty, ResJnlLine."Unit of Measure Code"));
    end;

    procedure CheckJobJnlLine(JobJnlLine: Record "Job Journal Line")
    var
        MaxAvailableQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJobJnlLine(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        JobJnlLine.TestField("Qty. per Unit of Measure");
        if not CheckTSLineDetailPosting(
             JobJnlLine."Time Sheet No.",
             JobJnlLine."Time Sheet Line No.",
             JobJnlLine."Time Sheet Date",
             JobJnlLine.Quantity,
             JobJnlLine."Qty. per Unit of Measure",
             MaxAvailableQty)
        then
            JobJnlLine.FieldError(Quantity, StrSubstNo(CannotBeGreaterErr, MaxAvailableQty, JobJnlLine."Unit of Measure Code"));
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServTimeSheetMgt', '25.0')]
    procedure CheckServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        ServTimeSheetMgt.CheckServiceLine(ServiceLine);
    end;
#endif

    procedure CopyFilteredTimeSheetLinesToBuffer(var TimeSheetLineFrom: Record "Time Sheet Line"; var TimeSheetLineTo: Record "Time Sheet Line")
    begin
        if TimeSheetLineFrom.FindSet() then
            repeat
                TimeSheetLineTo := TimeSheetLineFrom;
                TimeSheetLineTo.Insert();
            until TimeSheetLineFrom.Next() = 0;
    end;

    procedure UpdateTimeAllocation(TimeSheetLine: Record "Time Sheet Line"; AllocatedQty: array[7] of Decimal)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetDate: Date;
        i: Integer;
    begin
        TimeSheetHeader.Get(TimeSheetLine."Time Sheet No.");
        for i := 1 to 7 do begin
            TimeSheetDate := TimeSheetHeader."Starting Date" + i - 1;
            if AllocatedQty[i] <> 0 then begin
                if TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", TimeSheetDate) then begin
                    TimeSheetDetail.Quantity := AllocatedQty[i];
                    TimeSheetDetail."Posted Quantity" := TimeSheetDetail.Quantity;
                    TimeSheetDetail.Modify();
                end else begin
                    TimeSheetDetail.Init();
                    TimeSheetDetail.CopyFromTimeSheetLine(TimeSheetLine);
                    TimeSheetDetail.Posted := true;
                    TimeSheetDetail.Date := TimeSheetDate;
                    TimeSheetDetail.Quantity := AllocatedQty[i];
                    TimeSheetDetail."Posted Quantity" := TimeSheetDetail.Quantity;
                    TimeSheetDetail.Insert();
                end;
            end else
                if TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", TimeSheetDate) then
                    TimeSheetDetail.Delete();
        end;
    end;

    procedure GetActivityInfo(TimeSheetLine: Record "Time Sheet Line"; var ActivityCaption: Text[30]; var ActivityID: Code[20]; var ActivitySubCaption: Text[30]; var ActivitySubID: Code[20])
    begin
        ActivitySubCaption := '';
        ActivitySubID := '';
        ActivityCaption := '';
        ActivityID := '';
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Job:
                begin
                    ActivityCaption := CopyStr(TimeSheetLine.FieldCaption("Job No."), 1, 30);
                    ActivityID := TimeSheetLine."Job No.";
                    ActivitySubCaption := CopyStr(TimeSheetLine.FieldCaption("Job Task No."), 1, 30);
                    ActivitySubID := TimeSheetLine."Job Task No.";
                end;
            TimeSheetLine.Type::Absence:
                begin
                    ActivityCaption := CopyStr(TimeSheetLine.FieldCaption("Cause of Absence Code"), 1, 30);
                    ActivityID := TimeSheetLine."Cause of Absence Code";
                end;
            TimeSheetLine.Type::"Assembly Order":
                begin
                    ActivityCaption := CopyStr(TimeSheetLine.FieldCaption("Assembly Order No."), 1, 30);
                    ActivityID := TimeSheetLine."Assembly Order No.";
                end;
            else
                OnGetActivityInfoCaseTypeElse(TimeSheetLine, ActivitySubCaption, ActivitySubID, ActivityCaption, ActivityID);
        end;

        OnAfterGetActivityInfo(TimeSheetLine, ActivitySubCaption, ActivitySubID, ActivityCaption, ActivityID);
    end;

    procedure ShowPostingEntries(TimeSheetNo: Code[20]; TimeSheetLineNo: Integer)
    var
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
        TimeSheetPostingEntries: Page "Time Sheet Posting Entries";
    begin
        TimeSheetPostingEntry.FilterGroup(2);
        TimeSheetPostingEntry.SetRange("Time Sheet No.", TimeSheetNo);
        TimeSheetPostingEntry.SetRange("Time Sheet Line No.", TimeSheetLineNo);
        TimeSheetPostingEntry.FilterGroup(0);
        Clear(TimeSheetPostingEntries);
        TimeSheetPostingEntries.SetTableView(TimeSheetPostingEntry);
        TimeSheetPostingEntries.RunModal();
    end;

    procedure FindNearestTimeSheetStartDate(Date: Date): Date
    var
        ResourcesSetup: Record "Resources Setup";
    begin
        ResourcesSetup.Get();
        if Date2DWY(Date, 1) = ResourcesSetup."Time Sheet First Weekday" + 1 then
            exit(Date);

        exit(CalcDate(StrSubstNo('<WD%1>', ResourcesSetup."Time Sheet First Weekday" + 1), Date));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcActSchedFactBoxData(var TimeSheetHeader: Record "Time Sheet Header"; var TotalQtyText: Text; var TotalPresenceQty: Decimal; var AbsenceQty: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTSPostingEntry(TimeSheetDetail: Record "Time Sheet Detail"; var TimeSheetPostingEntry: Record "Time Sheet Posting Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPrevTimeSheetLines()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcStatusFactBoxDataOnAfterTimeSheetHeaderSetFilters(var TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActSchedFactBoxDataOnAfterTimeSheetHeaderSetFilters(var TimeSheetHeader: Record "Time Sheet Header"; Calendar: Record Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActSchedFactBoxDataOnBeforeResouceCalcFields(var Resource: Record Resource; Calendar: Record Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckInsertJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineBuffer: Record "Job Planning Line"; var SkipLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPrevTimeSheetLinesOnBeforeCopyLine(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobJnlLine(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckResJnlLine(ResJournalLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCreateTSLineFromServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnBeforeCreateTSLineFromServiceLine(ServiceLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServTimesheetMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTSLineFromServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeCreateTSLineFromServiceShptLine(var ServiceShipmentLine: Record Microsoft.Service.History."Service Shipment Line"; var IsHandled: Boolean)
    begin
        OnBeforeCreateTSLineFromServiceShptLine(ServiceShipmentLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServTimesheetMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTSLineFromServiceShptLine(var ServiceShipmentLine: Record Microsoft.Service.History."Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillJobPlanningBuffer(var JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineBuffer: Record "Job Planning Line"; TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterTimeSheets(var TimeSheetHeader: Record "Time Sheet Header"; FieldNo: Integer; ApplyToAdmin: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToTimeSheetLineInsert(var ToTimeSheetLine: Record "Time Sheet Line"; FromTimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLinesFromJobPlanningOnBeforeTimeSheetLineInsert(var TimeSheetLine: Record "Time Sheet Line"; var JobPlanningLine: Record "Job Planning Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetActivityInfo(var TimeSheetLine: Record "Time Sheet Line"; var ActivityCaption: Text[30]; var ActivityID: Code[20]; var ActivitySubCaption: Text[30]; var ActivitySubID: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillJobPlanningBufferOnBeforeJobPlanningLineBufferInsert(JobPlanningLine: Record "Job Planning Line"; var JobPlanningLineBuffer: Record "Job Planning Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTimeSheetArchiveOnAfterSetFilters(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetActivityInfoCaseTypeElse(var TimeSheetLine: Record "Time Sheet Line"; var ActivityCaption: Text[30]; var ActivityID: Code[20]; var ActivitySubCaption: Text[30]; var ActivitySubID: Code[20]);
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeAddServLinesFromTSDetail(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TimeSheetDetail: Record "Time Sheet Detail"; LineNo: Integer; var IsHandled: Boolean)
    begin
        OnBeforeAddServLinesFromTSDetail(ServiceHeader, TimeSheetDetail, LineNo, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServTimesheetMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddServLinesFromTSDetail(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TimeSheetDetail: Record "Time Sheet Detail"; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnAddServLinesFromTSDetailOnBeforeInsertServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var LineNo: Integer; ServiceHeader: Record Microsoft.Service.Document."Service Header"; TimeSheetDetail: Record "Time Sheet Detail")
    begin
        OnAddServLinesFromTSDetailOnBeforeInsertServiceLine(ServiceLine, LineNo, ServiceHeader, TimeSheetDetail);
    end;

    [Obsolete('Moved to codeunit ServTimesheetMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAddServLinesFromTSDetailOnBeforeInsertServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var LineNo: Integer; ServiceHeader: Record Microsoft.Service.Document."Service Header"; TimeSheetDetail: Record "Time Sheet Detail")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalcActSchedFactBoxDataOnAfterSetDateDescription(TimeSheetHeader: Record "Time Sheet Header"; Calendar: Record Date; var DateDescriptionForSpecificDate: Text[30]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeSheetHeaderArchiveInsert(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive"; TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeSheetLineArchiveInsert(var TimeSheetLineArchive: Record "Time Sheet Line Archive"; TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeSheetDetailArchiveInsert(var TimeSheetDetailArchive: Record "Time Sheet Detail Archive"; TimeSheetDetail: Record "Time Sheet Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeSheetCmtLineArchiveInsert(var TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive"; TimeSheetCommentLine: Record "Time Sheet Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyTimeSheetLine(var ToTimeSheetHeader: Record "Time Sheet Header"; var FromTimeSheetLine: Record "Time Sheet Line"; CopyComments: Boolean; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyTimeSheetLineArchive(var ToTimeSheetHeader: Record "Time Sheet Header"; var FromTimeSheetLineArchive: Record "Time Sheet Line Archive"; CopyComments: Boolean; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTimeSheetLineFieldsVisible(var WorkTypeCodeVisible: Boolean; var JobFieldsVisible: Boolean; var ChargeableVisible: Boolean; var ServiceOrderNoVisible: Boolean; var AbsenceCauseVisible: Boolean; var AssemblyOrderNoVisible: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTimeSheetLineFieldsVisible(var ServiceOrderNoVisible: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTSLineFromDocLineOnBeforeTimeSheetLineInsert(var TimeSheetLine: Record "Time Sheet Line"; TableID: Integer; OrderNo: Code[20]; OrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeSheetDetailInsert(var ToTimeSheetDetail: Record "Time Sheet Detail"; FromTimeSheetDetail: Record "Time Sheet Detail"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyTimeSheetLineArchiveOnBeforeToTimeSheetLineInsert(var ToTimeSheetLine: Record "Time Sheet Line"; FromTimeSheetLineArchive: Record "Time Sheet Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccPeriod(Date: Date; var IsHandled: Boolean)
    begin
    end;
}

