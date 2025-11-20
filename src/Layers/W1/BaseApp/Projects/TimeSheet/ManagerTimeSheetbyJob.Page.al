// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Projects.Resources.Setup;
using System.Utilities;

page 954 "Manager Time Sheet by Job"
{
    AdditionalSearchTerms = 'Manager Time Sheet by Job';
    ApplicationArea = Jobs;
    AutoSplitKey = true;
    Caption = 'Manager Time Sheet by Project';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Time Sheet Line";
    SourceTableView = where(Type = const(Job));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control10)
            {
                ShowCaption = false;
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which the report or batch job processes information.';
                }
                field(EndingDate; EndingDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ending Date';
                    Editable = false;
                    ToolTip = 'Specifies the date to which the report or batch job processes information.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number for the project that is associated with the time sheet line.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related project task.';
                    Visible = false;
                }
                field("Header Resource No."; TimeSheetHeader."Resource No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource No.';
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                    Editable = false;
                }
                field("Header Resource Name"; TimeSheetHeader."Resource Name")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Name';
                    ToolTip = 'Specifies the name of the resource for the time sheet.';
                    Editable = false;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies a description of the time sheet line.';

                    trigger OnAssistEdit()
                    begin
                        Rec.ShowLineDetails(true);
                        CurrPage.Update();
                    end;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Editable = WorkTypeCodeAllowEdit;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.TestField(Status, Rec.Status::Submitted);
                    end;
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    Editable = ChargeableAllowEdit;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.TestField(Status, Rec.Status::Submitted);
                    end;
                }
                field(Field1; CellData[1])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[1];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field2; CellData[2])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[2];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field3; CellData[3])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[3];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field4; CellData[4])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[4];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field5; CellData[5])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[5];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field6; CellData[6])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[6];
                    Editable = false;
                    Width = 6;
                }
                field(Field7; CellData[7])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[7];
                    Editable = false;
                    Width = 6;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information about the status of a time sheet line.';
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    Style = Strong;
                }
            }

        }
        area(factboxes)
        {
            part(TimeSheetComments; "Time Sheet Comments FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Time Sheet Comments';
                SubPageLink = "No." = field("Time Sheet No."), "Time Sheet Line No." = filter(0); //just header comments
                Editable = false;
            }
            part(TimeSheetLineDetailsFactBox; "TimeSheet Line Details FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "Time Sheet No." = field("Time Sheet No."), "Line No." = field("Line No.");
            }
            part(TimeSheetStatusFactBox; "Time Sheet Status FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Time Sheet Status';
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Time Sheet")
            {
                Caption = '&Time Sheet';
                action("&Previous Period")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Previous Period';
                    Image = PreviousSet;
                    ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                    trigger OnAction()
                    begin
                        FindPeriod(SetWanted::Previous);
                    end;
                }
                action("&Next Period")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Next Period';
                    Image = NextSet;
                    ToolTip = 'View information for the next period.';

                    trigger OnAction()
                    begin
                        FindPeriod(SetWanted::Next);
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Time Sheet Comment Sheet";
                    RunPageLink = "No." = field("Time Sheet No."),
                                  "Time Sheet Line No." = field("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posting E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posting E&ntries';
                    Image = PostingEntries;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the resource ledger entries that have been posted in connection with the.';

                    trigger OnAction()
                    begin
                        TimeSheetMgt.ShowPostingEntries(Rec."Time Sheet No.", Rec."Line No.");
                    end;
                }
                action("Activity &Details")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Activity &Details';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the quantity of hours for each time sheet status.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineDetails(true);
                    end;
                }
            }
            action(OpenTimeSheet)
            {
                ApplicationArea = Jobs;
                Scope = Repeater;
                Caption = 'Open Time Sheet Card';
                Image = OpenWorksheet;
                RunObject = Page "Time Sheet Card";
                RunPageLink = "No." = field("Time Sheet No.");
                ToolTip = 'Open Time Sheet Card for the record.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Approve)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Approve';
                    Image = Approve;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Approve the lines on the time sheet. Choose All to approve all lines. Choose Selected to approve only selected lines.';

                    trigger OnAction()
                    begin
                        ApproveLines();
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Reject';
                    Image = Reject;
                    ToolTip = 'Reject to approve the lines on the time sheet. Choose All to reject all lines. Choose Selected to reject only selected lines.';

                    trigger OnAction()
                    begin
                        RejectLines();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the time sheet to change it.';

                    trigger OnAction()
                    begin
                        ReopenLines();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
                actionref("&Previous Period_Promoted"; "&Previous Period")
                {
                }
                actionref("&Next Period_Promoted"; "&Next Period")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Show', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref("Posting E&ntries_Promoted"; "Posting E&ntries")
                {
                }
                actionref("Activity &Details_Promoted"; "Activity &Details")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
        GetLineAdditionalData();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        GetLineAdditionalData();
        CurrPage.TimeSheetComments.Page.UpdateData(Rec."Time Sheet No.", Rec."Line No.", true);
    end;

    trigger OnOpenPage()
    begin
        FindPeriod(SetWanted::Initial);
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        ColumnRecords: array[32] of Record Date;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        NoOfColumns: Integer;
        CellData: array[32] of Decimal;
        ColumnCaption: array[32] of Text[1024];
        SetWanted: Option Initial,Previous,Next;
        StartingDate: Date;
        EndingDate: Date;
        WorkTypeCodeAllowEdit: Boolean;
        ChargeableAllowEdit: Boolean;
        InitialStartingDateBase: Date;

    procedure SetColumns()
    var
        Calendar: Record Date;
    begin
        Clear(ColumnCaption);
        Clear(ColumnRecords);
        Clear(Calendar);
        Clear(NoOfColumns);

        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", StartingDate, EndingDate);
        if Calendar.FindSet() then
            repeat
                NoOfColumns += 1;
                ColumnRecords[NoOfColumns]."Period Start" := Calendar."Period Start";
                ColumnCaption[NoOfColumns] := TimeSheetMgt.FormatDate(Calendar."Period Start", 1);
            until Calendar.Next() = 0;
    end;

    local procedure GetLineAdditionalData()
    begin
        if TimeSheetHeader."No." <> Rec."Time Sheet No." then begin
            TimeSheetHeader.SetAutoCalcFields("Resource Name");
            if not TimeSheetHeader.Get(Rec."Time Sheet No.") then
                Clear(TimeSheetHeader);

            TimeSheetHeader.SetRange("Type Filter", TimeSheetHeader."Type Filter"::Job);
            CurrPage.TimeSheetStatusFactBox.PAGE.UpdateDataInclFilters(TimeSheetHeader);
        end;
    end;

    local procedure AfterGetCurrentRecord()
    var
        i: Integer;
    begin
        i := 0;
        while i < NoOfColumns do begin
            i := i + 1;
            if (Rec."Line No." <> 0) and TimeSheetDetail.Get(
                 Rec."Time Sheet No.",
                 Rec."Line No.",
                 ColumnRecords[i]."Period Start")
            then
                CellData[i] := TimeSheetDetail.Quantity
            else
                CellData[i] := 0;
        end;
        WorkTypeCodeAllowEdit := Rec.GetAllowEdit(Rec.FieldNo("Work Type Code"), true);
        ChargeableAllowEdit := Rec.GetAllowEdit(Rec.FieldNo(Chargeable), true);
    end;

    procedure SetInitialStartingDateBase(StartingDateBase: Date)
    begin
        InitialStartingDateBase := StartingDateBase;
    end;

    local procedure FindPeriod(Which: Option Initial,Previous,Next)
    begin
        if InitialStartingDateBase = 0D then
            InitialStartingDateBase := Workdate();
        CalcStartingDate(Which, InitialStartingDateBase, StartingDate);
        EndingDate := CalcDate('<1W>', StartingDate) - 1;
        Rec.FilterGroup(2);
        Rec.SetRange("Time Sheet Starting Date", StartingDate, EndingDate);
        Rec.SetRange("Approver ID", UserId);
        Rec.FilterGroup(0);
        SetColumns();
        CurrPage.Update(false);
    end;

    local procedure CalcStartingDate(Which: Option Initial,Previous,Next; InitialDate: Date; var StartingDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcStartingDate(Rec, Which, InitialDate, StartingDate, IsHandled);
        if IsHandled then
            exit;

        case Which of
            Which::Initial:
                if Date2DWY(InitialDate, 1) = GetTimeSheetFirstWeekday() then
                    StartingDate := InitialDate
                else
                    StartingDate := CalcDate(StrSubstNo('<WD%1-7D>', GetTimeSheetFirstWeekday()), InitialDate);
            Which::Previous:
                StartingDate := CalcDate('<-1W>', StartingDate);
            Which::Next:
                StartingDate := CalcDate('<1W>', StartingDate);
        end;
    end;

    local procedure GetTimeSheetFirstWeekday(): Integer
    begin
        ResourcesSetup.Get();
        exit(ResourcesSetup."Time Sheet First Weekday" + 1);
    end;

    local procedure Process("Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        ActionType: Option Approve,Reopen,Reject;
        TimeSheetAction: Enum "Time Sheet Action";
    begin
        CurrPage.SaveRecord();
        case Action of
            Action::"Approve All",
            Action::"Reject All":
                FilterAllLines(TimeSheetLine, ActionType::Approve);
            Action::"Reopen All":
                FilterAllLines(TimeSheetLine, ActionType::Reopen);
            Action::"Approve Selected",
            Action::"Reject Selected":
                begin
                    CurrPage.SetSelectionFilter(TimeSheetLine);
                    TimeSheetLine.FilterGroup(2);
                    TimeSheetLine.SetRange("Time Sheet Starting Date", StartingDate, EndingDate);
                    TimeSheetLine.SetRange("Approver ID", UserId);
                    TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
                    TimeSheetLine.FilterGroup(0);
                    TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
                end;
            Action::"Reopen Selected":
                begin
                    CurrPage.SetSelectionFilter(TimeSheetLine);
                    TimeSheetLine.FilterGroup(2);
                    TimeSheetLine.SetRange("Time Sheet Starting Date", StartingDate, EndingDate);
                    TimeSheetLine.SetRange("Approver ID", UserId);
                    TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
                    TimeSheetLine.FilterGroup(0);
                    TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Approved);
                end;
        end;
        OnProcessOnAfterTimeSheetLinesFiltered(TimeSheetLine, Action);
        TimeSheetMgt.CopyFilteredTimeSheetLinesToBuffer(TimeSheetLine, TempTimeSheetLine);
        if TimeSheetLine.FindSet() then
            repeat
                case Action of
                    Action::"Approve Selected",
                    Action::"Approve All":
                        TimeSheetApprovalMgt.Approve(TimeSheetLine);
                    Action::"Reopen Selected",
                    Action::"Reopen All":
                        TimeSheetApprovalMgt.ReopenApproved(TimeSheetLine);
                    Action::"Reject Selected",
                    Action::"Reject All":
                        TimeSheetApprovalMgt.Reject(TimeSheetLine);
                end;
            until TimeSheetLine.Next() = 0
        else begin
            case Action of
                Action::"Approve Selected",
                Action::"Approve All":
                    TimeSheetAction := TimeSheetAction::Approve;
                Action::"Reopen Selected",
                Action::"Reopen All":
                    TimeSheetAction := TimeSheetAction::"Reopen Approved";
                Action::"Reject Selected",
                Action::"Reject All":
                    TimeSheetAction := TimeSheetAction::Reject;
            end;
            TimeSheetApprovalMgt.NoTimeSheetLinesToProcess(TimeSheetAction);
        end;
        OnAfterProcess(TempTimeSheetLine, Action);
        CurrPage.Update(false);
    end;

    local procedure ApproveLines()
    var
        "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All";
        ActionType: Option Approve,Reopen,Reject;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApproveLines(Rec, IsHandled);
        if IsHandled then
            exit;

        case ShowDialog(ActionType::Approve) of
            1:
                Process(Action::"Approve All");
            2:
                Process(Action::"Approve Selected");
        end;
    end;

    local procedure ReopenLines()
    var
        ActionType: Option Approve,Reopen,Reject;
        "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All";
    begin
        case ShowDialog(ActionType::Reopen) of
            1:
                Process(Action::"Reopen All");
            2:
                Process(Action::"Reopen Selected");
        end;
    end;

    local procedure RejectLines()
    var
        ActionType: Option Approve,Reopen,Reject;
        "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All";
    begin
        case ShowDialog(ActionType::Reject) of
            1:
                Process(Action::"Reject All");
            2:
                Process(Action::"Reject Selected");
        end;
    end;

    local procedure GetDialogText(ActionType: Option Approve,Reopen,Reject): Text
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        FilterAllLines(TimeSheetLine, ActionType);
        exit(TimeSheetApprovalMgt.GetManagerTimeSheetActionDialogText(ActionType, TimeSheetLine.Count()));
    end;

    local procedure FilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Approve,Reopen,Reject)
    begin
        TimeSheetLine.CopyFilters(Rec);
        TimeSheetLine.FilterGroup(2);
        TimeSheetLine.SetRange("Time Sheet Starting Date", StartingDate, EndingDate);
        TimeSheetLine.SetRange("Approver ID", UserId);
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.FilterGroup(0);
        case ActionType of
            ActionType::Approve,
            ActionType::Reject:
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
            ActionType::Reopen:
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Approved);
        end;

        OnAfterFilterAllLines(TimeSheetLine, ActionType);
    end;

    local procedure ShowDialog(ActionType: Option Approve,Reopen,Reject): Integer
    var
        TimeSheetLine: Record "Time Sheet Line";
        DefaultValue: Integer;
        ConfirmSelectedLinesTxt: Label '%1\Do you want to process selected lines [%2]?', Comment = '%1 - activity type instruction, %2 - selected lines count';
    begin
        CurrPage.SetSelectionFilter(TimeSheetLine);
        if TimeSheetLine.Count() > 1 then begin
            if Confirm(ConfirmSelectedLinesTxt, false, TimeSheetApprovalMgt.GetManagerTimeSheetActionDialogInstruction(ActionType), TimeSheetLine.Count()) then
                exit(2);
            Error('');
        end;

        DefaultValue := 2;
        OnShowDialogOnAfterSetDefaultValue(ActionType, DefaultValue);

        exit(StrMenu(GetDialogText(ActionType), DefaultValue, TimeSheetApprovalMgt.GetManagerTimeSheetActionDialogInstruction(ActionType)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Approve,Reopen,Reject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessOnAfterTimeSheetLinesFiltered(var TimeSheetLine: Record "Time Sheet Line"; "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDialogOnAfterSetDefaultValue(ActionType: Option; var DefaultValue: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcess(var TimeSheetLine: Record "Time Sheet Line"; "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStartingDate(var TimeSheetLine: Record "Time Sheet Line"; Which: Option; InitialStartingDateBase: Date; var StartingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApproveLines(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean);
    begin
    end;
}

