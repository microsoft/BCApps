// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Projects.Resources.Setup;

page 949 "Time Sheet Lines"
{
    Caption = 'Time Sheet Lines';
    ApplicationArea = Jobs;
    UsageCategory = Tasks;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Time Sheet Line";
    SourceTableTemporary = true;
    SourceTableView = sorting("Time Sheet No.", "Line No.") order(descending);
    AnalysisModeEnabled = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                FreezeColumn = "Header Ending Date";
                Editable = false;

                field("Time Sheet No."; Rec."Time Sheet No.")
                {
                    ApplicationArea = Suite;
                    HideValue = TimeSheetNoHideValue;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Header Resource No."; TempTimeSheetHeader."Resource No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource No.';
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                    Editable = false;
                }
                field("Header Starting Date"; Rec."Time Sheet Starting Date")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date for a time sheet.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Header Ending Date"; TempTimeSheetHeader."Ending Date")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the ending date for a time sheet.';
                    Editable = false;
                    Importance = Additional;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of time sheet line.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information about the status of a time sheet line.';
                    Width = 4;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the time sheet line.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number for the project that is associated with the time sheet line.';
                    Visible = JobFieldsVisible;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';
                    Visible = JobFieldsVisible;
                }
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a list of standard absence codes, from which you may select one.';
                    Visible = AbsenceCauseVisible;
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                    Visible = ChargeableVisible;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = WorkTypeCodeVisible;
                }
                field("Assembly Order No."; Rec."Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the assembly order number that is associated with the time sheet line.';
                    Visible = false;
                }
                field(Archived; Rec.Posted) //used field to mark from archive
                {
                    Caption = 'Archived';
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the time sheet line has been archived.';
                }
                field(Field1; CellData[1])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[1];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field2; CellData[2])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[2];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field3; CellData[3])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[3];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field4; CellData[4])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[4];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field5; CellData[5])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[5];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field6; CellData[6])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[6];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field(Field7; CellData[7])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[7];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
                field("Total Quantity"; LineTotal)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    DecimalPlaces = 0 : 2;
                    Width = 6;
                }
            }
        }
        area(factboxes)
        {
            part(TimeSheetLineDetailsFactBox; "TimeSheet Line Details FactBox")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewAll)
            {
                ApplicationArea = Jobs;
                Caption = 'View All';
                ToolTip = 'Use this action to reset Status filter.';
                Image = ViewCheck;

                trigger OnAction()
                begin
                    FilterLinesByStatus(-1);
                end;
            }
            action(ViewOpen)
            {
                ApplicationArea = Jobs;
                Caption = 'View Open';
                ToolTip = 'Use this action to set filter Status = Open.';
                Image = ViewCheck;

                trigger OnAction()
                begin
                    FilterLinesByStatus(Enum::"Time Sheet Status"::Open.AsInteger());
                end;
            }
            action(ViewSubmitted)
            {
                ApplicationArea = Jobs;
                Caption = 'View Submitted';
                ToolTip = 'Use this action to set filter Status = Submitted.';
                Image = ViewCheck;

                trigger OnAction()
                begin
                    FilterLinesByStatus(Enum::"Time Sheet Status"::Submitted.AsInteger());
                end;
            }
        }
        area(Navigation)
        {
            action(OpenTimeSheet)
            {
                ApplicationArea = Jobs;
                Scope = Repeater;
                Caption = 'Open Time Sheet Card';
                Image = OpenWorksheet;
                ToolTip = 'Open Time Sheet Card for the record.';

                trigger OnAction()
                var
                    TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
                    TimeSheetHeader: Record "Time Sheet Header";
                    TimeSheetCard: Page "Time Sheet Card";
                    TimeSheetArchiveCard: Page "Time Sheet Archive Card";
                begin
                    if Rec.Posted then begin
                        TimeSheetHeaderArchive.Get(Rec."Time Sheet No.");
                        TimeSheetHeaderArchive.SetRecFilter();
                        TimeSheetArchiveCard.SetTableView(TimeSheetHeaderArchive);
                        TimeSheetArchiveCard.Run();
                    end
                    else begin
                        TimeSheetHeader.Get(Rec."Time Sheet No.");
                        TimeSheetHeader.SetRecFilter();
                        TimeSheetCard.SetTableView(TimeSheetHeader);
                        TimeSheetCard.Run();
                    end;

                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(OpenTimeSheet_Promoted; OpenTimeSheet)
                {
                }
                group(Category_FilterLines)
                {
                    Caption = 'View All';
                    ShowAs = SplitButton;

                    actionref(ViewAll_Promoted; ViewAll)
                    {
                    }
                    actionref(ViewOpen_Promoted; ViewOpen)
                    {
                    }
                    actionref(ViewSubmitted_Promoted; ViewSubmitted)
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if TempTimeSheetHeader."No." <> Rec."Time Sheet No." then
            TempTimeSheetHeader.Get(Rec."Time Sheet No.");
        TimeSheetNoHideValue := false;
        TimeSheetNoOnFormat();
        UpdateValuesPerDays();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.TimeSheetLineDetailsFactBox.Page.SetSource(Rec, Rec.Posted);
    end;

    trigger OnOpenPage()
    begin
        if not LookupMode then
            GetData(Rec, '', 0D, true, true);

        TimeSheetManagement.CheckTimeSheetLineFieldsVisible(WorkTypeCodeVisible, JobFieldsVisible, ChargeableVisible, ServiceOrderNoVisible, AbsenceCauseVisible, AssemblyOrderNoVisible);
        if Rec.FindFirst() then;
        NoOfColumns := 7;
        SetWeekDaysOrder();
    end;

    var
        GlobalTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
        CellData: array[32] of Decimal;
        LineTotal: Decimal;
        ColumnCaption: array[7] of Text[30];
        NoOfColumns: Integer;
        LoadEntriesForPeriod: Option Month,Year,All;
        WorkTypeCodeVisible, JobFieldsVisible, ChargeableVisible, AbsenceCauseVisible, AssemblyOrderNoVisible : Boolean;
        TimeSheetNoHideValue: Boolean;
        LastStartDate: Date;

    protected var
        TempTimeSheetHeader: Record "Time Sheet Header" temporary;
        ServiceOrderNoVisible: Boolean;

    local procedure UpdateValuesPerDays()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetDetailArchive: Record "Time Sheet Detail Archive";
        i: Integer;
    begin
        i := 0;
        LineTotal := 0;

        if Rec.Posted then
            while i < NoOfColumns do begin
                i := i + 1;
                if (Rec."Line No." <> 0) and TimeSheetDetailArchive.Get(
                     Rec."Time Sheet No.",
                     Rec."Line No.",
                     Rec."Time Sheet Starting Date" + i - 1)
                then
                    CellData[i] := TimeSheetDetailArchive.Quantity
                else
                    CellData[i] := 0;

                LineTotal += CellData[i];
            end
        else
            while i < NoOfColumns do begin
                i := i + 1;
                if (Rec."Line No." <> 0) and TimeSheetDetail.Get(
                     Rec."Time Sheet No.",
                     Rec."Line No.",
                     Rec."Time Sheet Starting Date" + i - 1)
                then
                    CellData[i] := TimeSheetDetail.Quantity
                else
                    CellData[i] := 0;

                LineTotal += CellData[i];
            end;
    end;

    local procedure FilterLinesByStatus(TimeSheetStatusAsInt: Integer)
    begin
        case TimeSheetStatusAsInt of
            -1: //all lines
                Rec.SetRange(Status);
            Enum::"Time Sheet Status"::Open.AsInteger():
                Rec.SetRange(Status, Enum::"Time Sheet Status"::Open);
            Enum::"Time Sheet Status"::Submitted.AsInteger():
                Rec.SetRange(Status, Enum::"Time Sheet Status"::Submitted);
            Enum::"Time Sheet Status"::Rejected.AsInteger():
                Rec.SetRange(Status, Enum::"Time Sheet Status"::Rejected);
            Enum::"Time Sheet Status"::Approved.AsInteger():
                Rec.SetRange(Status, Enum::"Time Sheet Status"::Approved);
        end;

        CurrPage.Update(false);
    end;

    local procedure SetWeekDaysOrder()
    var
        ResourceSetup: Record "Resources Setup";
        DaysInWeek: Dictionary of [Integer, Text[30]];
        i: Integer;
        FirsDay: Integer;
        MondayLbl: Label 'Mon';
        TuesdayLbl: Label 'Tue';
        WednesdayLbl: Label 'Wed';
        ThursdayLbl: Label 'Thu';
        FridayLbl: Label 'Fri';
        SaturdayLbl: Label 'Sat';
        SundayLbl: Label 'Sun';

    begin
        DaysInWeek.Add(1, MondayLbl);
        DaysInWeek.Add(2, TuesdayLbl);
        DaysInWeek.Add(3, WednesdayLbl);
        DaysInWeek.Add(4, ThursdayLbl);
        DaysInWeek.Add(5, FridayLbl);
        DaysInWeek.Add(6, SaturdayLbl);
        DaysInWeek.Add(0, SundayLbl);

        ResourceSetup.Get();
        FirsDay := ResourceSetup."Time Sheet First Weekday";

        for i := 1 to 7 do
            ColumnCaption[i] := DaysInWeek.Get((FirsDay + i) mod 7);

        OnAfterSetWeekDaysOrder(ColumnCaption);
    end;

    procedure SetForTimeSheetHeader(ForTimeSheetHeader: Record "Time Sheet Header")
    begin
        GlobalTimeSheetHeader := ForTimeSheetHeader;
        LoadEntriesForPeriod := LoadEntriesForPeriod::All;

        GlobalTimeSheetHeader.TestField("No.");
        GlobalTimeSheetHeader.TestField("Resource No.");
    end;

    local procedure TimeSheetNoOnFormat()
    begin
        if not IsFirstDocLine() then
            TimeSheetNoHideValue := true;
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
    begin
        TempTimeSheetLine.Reset();
        TempTimeSheetLine.CopyFilters(Rec);
        TempTimeSheetLine.SetRange("Time Sheet No.", Rec."Time Sheet No.");
        if not TempTimeSheetLine.FindFirst() then
            if Rec.Posted then begin
                TimeSheetLineArchive.SetRange("Time Sheet No.", Rec."Time Sheet No.");
                TimeSheetLineArchive.SetExclusionTypeFilter();
                if TimeSheetLineArchive.FindLast() then begin
                    TempTimeSheetLine.TransferFields(TimeSheetLineArchive);
                    TempTimeSheetLine.Insert();
                end;
            end
            else begin
                TimeSheetLine.CopyFilters(Rec);
                TimeSheetLine.SetRange("Time Sheet No.", Rec."Time Sheet No.");
                TimeSheetLine.SetExclusionTypeFilter();
                if TimeSheetLine.FindLast() then begin
                    TempTimeSheetLine := TimeSheetLine;
                    TempTimeSheetLine.Insert();
                end;
            end;

        if Rec."Line No." = TempTimeSheetLine."Line No." then
            exit(true);
    end;

    local procedure GetFromDate(ForDate: Date) FromDate: Date
    begin
        if ForDate = 0D then
            FromDate := 0D
        else
            case LoadEntriesForPeriod of
                LoadEntriesForPeriod::Month:
                    FromDate := CalcDate('<-4W>', ForDate);
                LoadEntriesForPeriod::Year:
                    FromDate := CalcDate('<-52W>', ForDate);
                LoadEntriesForPeriod::All:
                    FromDate := 0D;
            end;

        OnAfterGetFromDate(ForDate, LoadEntriesForPeriod, FromDate);
    end;

    procedure SetRec(var TimeSheetLine: Record "Time Sheet Line")
    begin
        if TimeSheetLine.FindSet() then
            repeat
                Rec.Init();
                Rec := TimeSheetLine;
                if Rec.Insert() then;
            until TimeSheetLine.Next() = 0;
    end;

    procedure GetData(var TimeSheetLine: Record "Time Sheet Line"; ForResourceCode: Code[20]; ProcessingDate: Date; OnPageOpen: Boolean; IncludeArchive: Boolean)
    var
        FromDate: Date;
        ToDate: Date;
        NoLinesToShowErr: Label 'There are no time sheet lines to show.';
    begin
        if ProcessingDate = 0D then
            LoadEntriesForPeriod := LoadEntriesForPeriod::All;

        if LastStartDate = 0D then
            ToDate := ProcessingDate
        else
            ToDate := LastStartDate - 1;

        FromDate := GetFromDate(ProcessingDate);
        LastStartDate := FromDate;

        GetDataFromTimeSheetQuery(TimeSheetLine, ForResourceCode, FromDate, ToDate);

        if IncludeArchive then
            GetDataFromTimeSheetArchiveQuery(TimeSheetLine, ForResourceCode, FromDate, ToDate);

        if (TimeSheetLine.Count = 0) and (OnPageOpen) then begin
            if LoadEntriesForPeriod = LoadEntriesForPeriod::All then
                Error(NoLinesToShowErr);
            LoadEntriesForPeriod += 1;
            GetData(TimeSheetLine, ForResourceCode, ProcessingDate, OnPageOpen, IncludeArchive);
        end;
    end;

    local procedure GetDataFromTimeSheetQuery(var TimeSheetLine: Record "Time Sheet Line"; ForResourceCode: Code[20]; FromDate: Date; ToDate: Date)
    var
        GetTimeSheetLines: Query "Get Time Sheet Lines";
    begin
        if ForResourceCode <> '' then
            GetTimeSheetLines.SetRange(Filter_Resource_No_, ForResourceCode);
        if ToDate <> 0D then
            GetTimeSheetLines.SetRange(Filter_Starting_Date, FromDate, ToDate);

        if TimeSheetManagement.IsUserTimeSheetAdmin(UserId()) then
            SetLinesFromGetTimeSheetLinesQuery(TimeSheetLine, GetTimeSheetLines)
        else begin
            GetTimeSheetLines.SetRange(Filter_Owner_User, UserId());
            SetLinesFromGetTimeSheetLinesQuery(TimeSheetLine, GetTimeSheetLines);

            GetTimeSheetLines.SetRange(Filter_Owner_User);
            GetTimeSheetLines.SetRange(Filter_Approver_User, UserId());
            SetLinesFromGetTimeSheetLinesQuery(TimeSheetLine, GetTimeSheetLines);
        end;
    end;

    local procedure GetDataFromTimeSheetArchiveQuery(var TimeSheetLine: Record "Time Sheet Line"; ForResourceCode: Code[20]; FromDate: Date; ToDate: Date)
    var
        GetTimeSheetArchiveLines: Query "Get Time Sheet Archive Lines";
    begin
        if ForResourceCode <> '' then
            GetTimeSheetArchiveLines.SetRange(Filter_Resource_No_, ForResourceCode);
        if ToDate <> 0D then
            GetTimeSheetArchiveLines.SetRange(Filter_Starting_Date, FromDate, ToDate);

        if TimeSheetManagement.IsUserTimeSheetAdmin(UserId()) then
            SetLinesFromGetTimeSheetArchiveLinesQuery(TimeSheetLine, GetTimeSheetArchiveLines)
        else begin
            GetTimeSheetArchiveLines.SetRange(Filter_Owner_User, UserId());
            SetLinesFromGetTimeSheetArchiveLinesQuery(TimeSheetLine, GetTimeSheetArchiveLines);

            GetTimeSheetArchiveLines.SetRange(Filter_Owner_User);
            GetTimeSheetArchiveLines.SetRange(Filter_Approver_User, UserId());
            SetLinesFromGetTimeSheetArchiveLinesQuery(TimeSheetLine, GetTimeSheetArchiveLines);
        end;
    end;

    local procedure SetLinesFromGetTimeSheetLinesQuery(var TimeSheetLine: Record "Time Sheet Line"; var GetTimeSheetLines: Query "Get Time Sheet Lines")
    begin
        if GetTimeSheetLines.Open() then
            while GetTimeSheetLines.Read() do
                if (not (GetTimeSheetLines.Type in [GetTimeSheetLines.Type::"Assembly Order", GetTimeSheetLines.Type::Service])) and
                (GetTimeSheetLines.Time_Sheet_No_ <> GlobalTimeSheetHeader."No.") then begin
                    TimeSheetLine.Init();
                    TimeSheetLine."Time Sheet No." := GetTimeSheetLines.Time_Sheet_No_;
                    TimeSheetLine."Line No." := GetTimeSheetLines.Line_No_;
                    TimeSheetLine."Time Sheet Starting Date" := GetTimeSheetLines.Starting_Date;
                    TimeSheetLine.Type := GetTimeSheetLines.Type;
                    TimeSheetLine.Status := GetTimeSheetLines.Status;
                    TimeSheetLine.Description := GetTimeSheetLines.Description;
                    TimeSheetLine."Job No." := GetTimeSheetLines.Job_No_;
                    TimeSheetLine."Job Task No." := GetTimeSheetLines.Job_Task_No_;
                    TimeSheetLine."Cause of Absence Code" := GetTimeSheetLines.Cause_of_Absence_Code;
                    TimeSheetLine.Chargeable := GetTimeSheetLines.Chargeable;
                    TimeSheetLine."Work Type Code" := GetTimeSheetLines.Work_Type_Code;
                    TimeSheetLine."Service Order No." := GetTimeSheetLines.Service_Order_No_;
                    TimeSheetLine."Assembly Order No." := GetTimeSheetLines.Assembly_Order_No_;
                    if TimeSheetLine.Insert() then;

                    if TempTimeSheetHeader."No." <> GetTimeSheetLines.Time_Sheet_No_ then begin
                        TempTimeSheetHeader.Init();
                        TempTimeSheetHeader."No." := GetTimeSheetLines.Time_Sheet_No_;
                        TempTimeSheetHeader."Resource No." := GetTimeSheetLines.Resource_No_;
                        TempTimeSheetHeader."Starting Date" := GetTimeSheetLines.Starting_Date;
                        TempTimeSheetHeader."Ending Date" := GetTimeSheetLines.Ending_Date;
                        if TempTimeSheetHeader.Insert() then;
                    end;
                end;

        GetTimeSheetLines.Close();
    end;

    local procedure SetLinesFromGetTimeSheetArchiveLinesQuery(var TimeSheetLine: Record "Time Sheet Line"; var GetTimeSheetArchiveLines: Query "Get Time Sheet Archive Lines")
    begin
        if GetTimeSheetArchiveLines.Open() then
            while GetTimeSheetArchiveLines.Read() do
                if not (GetTimeSheetArchiveLines.Type in [GetTimeSheetArchiveLines.Type::"Assembly Order", GetTimeSheetArchiveLines.Type::Service]) then begin
                    TimeSheetLine.Init();
                    TimeSheetLine."Time Sheet No." := GetTimeSheetArchiveLines.Time_Sheet_No_;
                    TimeSheetLine."Line No." := GetTimeSheetArchiveLines.Line_No_;
                    TimeSheetLine."Time Sheet Starting Date" := GetTimeSheetArchiveLines.Starting_Date;
                    TimeSheetLine.Type := GetTimeSheetArchiveLines.Type;
                    TimeSheetLine.Status := GetTimeSheetArchiveLines.Status;
                    TimeSheetLine.Description := GetTimeSheetArchiveLines.Description;
                    TimeSheetLine."Job No." := GetTimeSheetArchiveLines.Job_No_;
                    TimeSheetLine."Job Task No." := GetTimeSheetArchiveLines.Job_Task_No_;
                    TimeSheetLine."Cause of Absence Code" := GetTimeSheetArchiveLines.Cause_of_Absence_Code;
                    TimeSheetLine.Chargeable := GetTimeSheetArchiveLines.Chargeable;
                    TimeSheetLine."Work Type Code" := GetTimeSheetArchiveLines.Work_Type_Code;
                    TimeSheetLine."Service Order No." := GetTimeSheetArchiveLines.Service_Order_No_;
                    TimeSheetLine."Assembly Order No." := GetTimeSheetArchiveLines.Assembly_Order_No_;
                    TimeSheetLine.Posted := true; //to mark from archive
                    if TimeSheetLine.Insert() then;

                    if TempTimeSheetHeader."No." <> GetTimeSheetArchiveLines.Time_Sheet_No_ then begin
                        TempTimeSheetHeader.Init();
                        TempTimeSheetHeader."No." := GetTimeSheetArchiveLines.Time_Sheet_No_;
                        TempTimeSheetHeader."Resource No." := GetTimeSheetArchiveLines.Resource_No_;
                        TempTimeSheetHeader."Starting Date" := GetTimeSheetArchiveLines.Starting_Date;
                        TempTimeSheetHeader."Ending Date" := GetTimeSheetArchiveLines.Ending_Date;
                        if TempTimeSheetHeader.Insert() then;
                    end;
                end;

        GetTimeSheetArchiveLines.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFromDate(ForDate: Date; LoadEntriesForPeriod: Option Month,Year,All; var FromDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWeekDaysOrder(var ColumnCaption: array[7] of Text[30])
    begin
    end;
}