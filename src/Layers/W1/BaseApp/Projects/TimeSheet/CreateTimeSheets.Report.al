// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using System.Security.User;
using System.Utilities;

report 950 "Create Time Sheets"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create Time Sheets';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem(Resource; Resource)
            {
                DataItemTableView = where("Use Time Sheet" = const(true));
                RequestFilterFields = "No.", Type;

                trigger OnAfterGetRecord()
                var
                    TimeSheetMgt: Codeunit "Time Sheet Management";
                    NoSeries: Codeunit "No. Series";
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnBeforeResourceOnAfterGerRecord(Resource, IsHandled, StartingDate, EndingDate);
                    if IsHandled then
                        CurrReport.Skip();

                    if CheckExistingPeriods() then begin
                        TimeSheetHeader.Init();
                        TimeSheetHeader."No." := NoSeries.GetNextNo(ResourcesSetup."Time Sheet Nos.", Today());
                        TimeSheetHeader."Starting Date" := StartingDate;
                        TimeSheetHeader."Ending Date" := EndingDate;
                        TimeSheetHeader.Validate("Resource No.", "No.");
                        TimeSheetHeader.Description := StrSubstNo(DescriptionTxt, GetWeekNumber(StartingDate));
                        OnResourceOnAfterGerRecordOnBeforeTimeSheetHeaderInsert(TimeSheetHeader, Resource);
                        TimeSheetHeader.Insert(true);
                        TimeSheetCounter += 1;

                        if CreateLinesFromJobPlanning then
                            TimeSheetMgt.CreateLinesFromJobPlanning(TimeSheetHeader);
                        OnResourceOnAfterGerRecordOnAfterTimeSheetHeaderInserted(TimeSheetHeader, Resource);
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    StartingDate := CalcDate('<1W>', StartingDate);
                end;

                trigger OnPreDataItem()
                begin
                    if HidResourceFilter <> '' then
                        SetFilter("No.", HidResourceFilter);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                EndingDate := CalcDate('<1W>', StartingDate) - 1;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, NoOfPeriods);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date of the time sheet.';

                        trigger OnValidate()
                        begin
                            ValidateStartingDate();
                        end;
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'No. of Weeks';
                        MinValue = 1;
                        ToolTip = 'Specifies the number of weeks that the time sheet covers, such as 1 or 4.';
                    }
                    field(CreateLinesFromJobPlanning; CreateLinesFromJobPlanning)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create Lines From Project Planning';
                        ToolTip = 'Specifies if you want to create time sheet lines that are based on project planning lines.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            TimeSheetMgt: Codeunit "Time Sheet Management";
        begin
            if NoOfPeriods = 0 then
                NoOfPeriods := 1;

            if TimeSheetHeader.FindLast() then
                StartingDate := TimeSheetHeader."Ending Date" + 1
            else
                StartingDate := TimeSheetMgt.FindNearestTimeSheetStartDate(WorkDate());
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ResourcesSetup.Get();
    end;

    trigger OnPostReport()
    begin
        if not HideDialog then
            Message(Text003, TimeSheetCounter);
    end;

    trigger OnPreReport()
    var
        i: Integer;
        LastDate: Date;
        FirstAccPeriodStartingDate: Date;
        LastAccPeriodStartingDate: Date;
    begin
        CheckUserSetup();

        if StartingDate = 0D then
            Error(Text004, Text005);

        if NoOfPeriods = 0 then
            Error(Text004, Text006);

        ResourcesSetup.TestField("Time Sheet Nos.");

        EndingDate := CalcDate('<1W>', StartingDate);

        LastDate := StartingDate;
        for i := 1 to NoOfPeriods do
            LastDate := CalcDate('<1W>', LastDate);

        if AccountingPeriod.IsEmpty() then begin
            FirstAccPeriodStartingDate := CalcDate('<-CM>', StartingDate);
            LastAccPeriodStartingDate := CalcDate('<CM>', StartingDate);
        end else begin
            AccountingPeriod.SetFilter("Starting Date", '..%1', StartingDate);
            AccountingPeriod.FindLast();
            FirstAccPeriodStartingDate := AccountingPeriod."Starting Date";

            AccountingPeriod.SetFilter("Starting Date", '..%1', LastDate);
            AccountingPeriod.FindLast();
            LastAccPeriodStartingDate := AccountingPeriod."Starting Date";

            AccountingPeriod.SetRange("Starting Date", FirstAccPeriodStartingDate, LastAccPeriodStartingDate);
            AccountingPeriod.FindSet();
            repeat
                AccountingPeriod.TestField(Closed, false);
            until AccountingPeriod.Next() = 0;
        end;
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        HidResourceFilter: Code[250];
        StartingDate: Date;
        EndingDate: Date;
        TimeSheetCounter: Integer;
        NoOfPeriods: Integer;
        CreateLinesFromJobPlanning: Boolean;
#pragma warning disable AA0074
        Text002: Label 'Time sheet administrator only is allowed to create time sheets.';
#pragma warning disable AA0470
        Text003: Label '%1 time sheets have been created.';
        Text004: Label '%1 must be filled in.';
#pragma warning restore AA0470
        Text005: Label 'Starting Date';
        Text006: Label 'No. of Weeks';
#pragma warning disable AA0470
        Text010: Label 'Starting Date must be %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        HideDialog: Boolean;
        OpenUserSetupQst: Label 'You aren''t allowed to run this report. If you want, you can give yourself the Time Sheet Admin. rights, and then try again.\\ Do you want to do that now?';
        DescriptionTxt: Label 'Week %1', Comment = '%1 - week number';

    procedure InitParameters(NewStartingDate: Date; NewNoOfPeriods: Integer; NewResourceFilter: Code[250]; NewCreateLinesFromJobPlanning: Boolean; NewHideDialog: Boolean)
    begin
        ClearAll();
        ResourcesSetup.Get();
        StartingDate := NewStartingDate;
        NoOfPeriods := NewNoOfPeriods;
        HidResourceFilter := NewResourceFilter;
        CreateLinesFromJobPlanning := NewCreateLinesFromJobPlanning;
        HideDialog := NewHideDialog;
    end;

    local procedure CheckUserSetup()
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUserSetup(IsHandled);
        if IsHandled then
            exit;

        if (not UserSetup.Get(UserId) or not UserSetup."Time Sheet Admin.") and UserSetup.WritePermission then
            if Confirm(OpenUserSetupQst, true) then
                PAGE.RunModal(PAGE::"User Setup");

        if not UserSetup.Get(UserId) or not UserSetup."Time Sheet Admin." then
            Error(Text002);
    end;

    local procedure CheckExistingPeriods(): Boolean
    begin
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        TimeSheetHeader.SetRange("Starting Date", StartingDate);
        TimeSheetHeader.SetRange("Ending Date", EndingDate);
        if TimeSheetHeader.FindFirst() then
            exit(false);

        exit(true);
    end;

    local procedure GetWeekNumber(StartingDate: Date): Integer
    var
        DateRec: Record Date;
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Week);
        DateRec.SetFilter("Period Start", '%1..', StartingDate);
        if DateRec.FindFirst() then
            exit(DateRec."Period No.");
    end;

    local procedure ValidateStartingDate()
    begin
        if Date2DWY(StartingDate, 1) <> ResourcesSetup."Time Sheet First Weekday" + 1 then
            Error(Text010, ResourcesSetup."Time Sheet First Weekday");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUserSetup(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceOnAfterGerRecord(var Resource: Record Resource; var IsHandled: Boolean; var StartingDate: Date; var EndingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResourceOnAfterGerRecordOnBeforeTimeSheetHeaderInsert(var TimeSheetHeader: Record "Time Sheet Header"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResourceOnAfterGerRecordOnAfterTimeSheetHeaderInserted(TimeSheetHeader: Record "Time Sheet Header"; Resource: Record Resource)
    begin
    end;
}

