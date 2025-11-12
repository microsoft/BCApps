// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Period;
using System.Environment;

page 1393 "Trial Balance"
{
    Caption = 'Trial Balance';
    LinksAllowed = false;
    PageType = CardPart;
    SaveValues = true;

    layout
    {
        area(content)
        {
            grid(Control234)
            {
                ShowCaption = false;
                group(Control3)
                {
                    ShowCaption = false;
                    Visible = IsError;
                    field(GETLASTERRORTEXT; GetLastErrorText)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                    }
                }
            }
            grid(Control45)
            {
                Editable = false;
                GridLayout = Columns;
                ShowCaption = false;
                group(Control44)
                {
                    ShowCaption = false;
                    Visible = not IsError;
                    field(DescriptionCap; DescriptionCap)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                    }
                    field(Description1; Descriptions[1])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                    }
                    field(Description2; Descriptions[2])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                    }
                    field(Description3; Descriptions[3])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                    }
                    field(Description4; Descriptions[4])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Style = Strong;
                        StyleExpr = true;
                    }
                    field(Description5; Descriptions[5])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                    }
                    field(Description6; Descriptions[6])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                    }
                    field(Description7; Descriptions[7])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Style = Strong;
                        StyleExpr = true;
                    }
                    field(Description8; Descriptions[8])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        StyleExpr = true;
                    }
                    field(Description9; Descriptions[9])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Style = Strong;
                        StyleExpr = true;
                    }
                }
                group(Control33)
                {
                    ShowCaption = false;
                    Visible = not IsError;
                    field("PeriodCaptionTxt[1]"; PeriodCaptionTxt[1])
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                    }
                    field(CurrentPeriodValues1; Values[1, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[1], PeriodCaptionTxt[1]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(1, 1);
                        end;
                    }
                    field(CurrentPeriodValues2; Values[2, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[2], PeriodCaptionTxt[1]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(2, 1);
                        end;
                    }
                    field(CurrentPeriodValues3; Values[3, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[3], PeriodCaptionTxt[1]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(3, 1);
                        end;
                    }
                    field(CurrentPeriodValues4; Values[4, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[4], PeriodCaptionTxt[1]);
                        ShowCaption = false;
                        StyleExpr = GrossMarginPct1;

                        trigger OnDrillDown()
                        begin
                            DrillDown(4, 1);
                        end;
                    }
                    field(CurrentPeriodValues5; Values[5, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[5], PeriodCaptionTxt[1]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(5, 1);
                        end;
                    }
                    field(CurrentPeriodValues6; Values[6, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[6], PeriodCaptionTxt[1]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(6, 1);
                        end;
                    }
                    field(CurrentPeriodValues7; Values[7, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[7], PeriodCaptionTxt[1]);
                        ShowCaption = false;
                        StyleExpr = OperatingMarginPct1;

                        trigger OnDrillDown()
                        begin
                            DrillDown(7, 1);
                        end;
                    }
                    field(CurrentPeriodValues8; Values[8, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[8], PeriodCaptionTxt[1]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(8, 1);
                        end;
                    }
                    field(CurrentPeriodValues9; Values[9, 1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[9], PeriodCaptionTxt[1]);
                        ShowCaption = false;
                        StyleExpr = IncomeBeforeInterestAndTax1;

                        trigger OnDrillDown()
                        begin
                            DrillDown(9, 1);
                        end;
                    }
                }
                group(Control22)
                {
                    ShowCaption = false;
                    Visible = PeriodVisible and (not IsError);
                    field("PeriodCaptionTxt[2]"; PeriodCaptionTxt[2])
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                    }
                    field(CurrentPeriodMinusOneValues1; Values[1, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[1], PeriodCaptionTxt[2]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(1, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues2; Values[2, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[2], PeriodCaptionTxt[2]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(2, 2)
                        end;
                    }
                    field(CurrentPeriodMinusOneValues3; Values[3, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[3], PeriodCaptionTxt[2]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(3, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues4; Values[4, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[4], PeriodCaptionTxt[2]);
                        ShowCaption = false;
                        StyleExpr = GrossMarginPct2;

                        trigger OnDrillDown()
                        begin
                            DrillDown(4, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues5; Values[5, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[5], PeriodCaptionTxt[2]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(5, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues6; Values[6, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[6], PeriodCaptionTxt[2]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(6, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues7; Values[7, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[7], PeriodCaptionTxt[2]);
                        ShowCaption = false;
                        StyleExpr = OperatingMarginPct2;

                        trigger OnDrillDown()
                        begin
                            DrillDown(7, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues8; Values[8, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[8], PeriodCaptionTxt[2]);
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            DrillDown(8, 2);
                        end;
                    }
                    field(CurrentPeriodMinusOneValues9; Values[9, 2])
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        CaptionClass = GetCaptionForDrillDownTooltip(Descriptions[9], PeriodCaptionTxt[2]);
                        ShowCaption = false;
                        StyleExpr = IncomeBeforeInterestAndTax2;

                        trigger OnDrillDown()
                        begin
                            DrillDown(9, 2);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';
                Visible = not IsError;

                trigger OnAction()
                begin
                    if LoadedFromCache then begin
                        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
                        LoadedFromCache := false;
                    end;
                    TrialBalanceMgt.PreviousPeriod(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);

                    SetStyles();
                    CurrPage.Update();
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';
                Visible = not IsError;

                trigger OnAction()
                begin
                    if LoadedFromCache then begin
                        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
                        LoadedFromCache := false;
                    end;

                    TrialBalanceMgt.NextPeriod(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
                    SetStyles();
                    CurrPage.Update();
                end;
            }
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Image = Setup;

                trigger OnAction()
                var
                    TrialBalanceSetup: Page "Trial Balance Setup";
                begin
                    if TrialBalanceSetup.RunModal() <> Action::Cancel then begin
                        IsError := false;
                        LoadTrialBalanceData(false);
                        CurrPage.Update();
                    end;
                end;
            }
            action(Information)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart Information';
                Image = AboutNav;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                var
                    ChartInfo: Text;
                begin
                    if PeriodVisible then
                        ChartInfo := StrSubstNo(InstructionMsg, PeriodsMsg)
                    else
                        ChartInfo := StrSubstNo(InstructionMsg, '');
                    Message(ChartInfo);
                end;
            }
        }
    }

    trigger OnInit()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        PeriodVisible := true;
        NoOfColumns := 2;

        if (ClientTypeManagement.GetCurrentClientType() = ClientType::Phone) or AccountingPeriod.IsEmpty() then begin
            NoOfColumns := 1;
            PeriodVisible := false;
        end;
    end;

    trigger OnOpenPage()
    begin
        LoadTrialBalanceData(true);
    end;

    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        TrialBalanceCacheMgt: Codeunit "Trial Balance Cache Mgt.";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
        GrossMarginPct1: Text;
        GrossMarginPct2: Text;
        OperatingMarginPct1: Text;
        OperatingMarginPct2: Text;
        IncomeBeforeInterestAndTax1: Text;
        IncomeBeforeInterestAndTax2: Text;
#pragma warning disable AA0074
        DescriptionCap: Label 'Description';
#pragma warning restore AA0074
        PeriodVisible: Boolean;
        InstructionMsg: Label 'This chart provides a quick overview of the financial performance of your company%1. The chart is a simplified version of the G/L Trial Balance chart. The Total Revenue figure corresponds to the total in your chart of accounts.', Comment = '%1=message about the number of periods displayed, if not running on phone client';
        PeriodsMsg: Label ', displayed in two periods';
        TrialBalanceTelemetryCategoryTok: Label 'Trial Balance', Locked = true;
        PBTSuccessTelemetryMsg: Label 'Page Background Task successfully calculated values and saved to cache.', Locked = true;
        PBTFailed1TelemetryMsg: Label 'Page Background Task failed. Task scheduled to update values.', Locked = true;
        NoOfColumns: Integer;
        IsError: Boolean;
        LoadedFromCache: Boolean;
        BackgroundTaskId: Integer;

    local procedure SetStyles()
    begin
        SetRedForNegativeBoldForPositiveStyle(4, 1, GrossMarginPct1);
        SetRedForNegativeBoldForPositiveStyle(4, 2, GrossMarginPct2);

        SetRedForNegativeBoldForPositiveStyle(7, 1, OperatingMarginPct1);
        SetRedForNegativeBoldForPositiveStyle(7, 2, OperatingMarginPct2);

        SetRedForNegativeBoldForPositiveStyle(9, 1, IncomeBeforeInterestAndTax1);
        SetRedForNegativeBoldForPositiveStyle(9, 2, IncomeBeforeInterestAndTax2);
    end;

    local procedure SetRedForNegativeBoldForPositiveStyle(RowNo: Integer; ColumnNo: Integer; var StyleText: Text)
    begin
        if Values[RowNo, ColumnNo] < 0 then
            StyleText := 'Unfavorable'
        else
            StyleText := 'Strong';
    end;

    local procedure GetCaptionForDrillDownTooltip(Description: Text; DatePeriod: Text): Text
    begin
        exit('3,' + StrSubstNo('%1 (%2)', Description, DatePeriod));
    end;

    [TryFunction]
    local procedure TryLoadTrialBalanceData(UsePBT: Boolean; var DataLoaded: Boolean)
    begin
        if UsePBT and (NoOfColumns <> 1) then begin
            SchedulePBT();
            DataLoaded := false;
        end else begin
            TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            DataLoaded := true;
        end;
    end;

    local procedure SchedulePBT()
    var
        CalculateTrialBalance: Codeunit "Calculate Trial Balance";
        Input: Dictionary of [Text, Text];
        TimeoutinMs: Integer;
    begin
        TimeoutinMs := 2000; // Default timeout;
        Clear(Input);
        Input.Add(CalculateTrialBalance.GetNoOfColumnsLabel(), Format(NoOfColumns));
        CurrPage.EnqueueBackgroundTask(BackgroundTaskId, Codeunit::"Calculate Trial Balance", Input, TimeoutInMs);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalculateTrialBalance: Codeunit "Calculate Trial Balance";
    begin
        // As PBT runs synchronously when running in test, the task is called even before PBTList is updated.
        // So, we use (TaskIdCalculateCue = TaskId) to check if the task is the one we are interested in.
        if BackgroundTaskId = TaskId then begin
            CalculateTrialBalance.TransformDictionaryToValues(Descriptions, Values, PeriodCaptionTxt, NoOfColumns, Results);
            TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
            LoadedFromCache := true;
            Session.LogMessage('0000ODU', PBTSuccessTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TrialBalanceTelemetryCategoryTok);
        end
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        ScheduledTask: Record "Scheduled Task";
        DataLoaded: Boolean;
    begin
        if BackgroundTaskId = TaskId then
            if not TaskScheduler.CanCreateTask() then begin // Users like Team Members and Delegated Admins cannot create tasks
                if TryLoadTrialBalanceData(false, DataLoaded) then
                    if DataLoaded then
                        TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
            end else begin
                ScheduledTask.SetRange("Run Codeunit", Codeunit::"Calculate Trial Balance");
                ScheduledTask.SetRange(Company, CompanyName());
                ScheduledTask.SetRange("Is Ready", true);
                if ScheduledTask.IsEmpty() then begin
                    TaskScheduler.CreateTask(Codeunit::"Calculate Trial Balance", 0, true, CompanyName(), CurrentDateTime());
                    Session.LogMessage('0000ODV', PBTFailed1TelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TrialBalanceTelemetryCategoryTok);
                end;
            end;
        IsHandled := true;
    end;

    local procedure LoadTrialBalanceData(LoadFromCache: Boolean)
    var
        DataLoaded: Boolean;
    begin
        if not TrialBalanceMgt.SetupIsInPlace() then
            exit;

        if LoadFromCache then
            if (not TrialBalanceCacheMgt.IsCacheStale()) and (NoOfColumns <> 1) then begin
                DataLoaded := TrialBalanceCacheMgt.LoadFromCache(Descriptions, Values, PeriodCaptionTxt);
                LoadedFromCache := true;
            end;

        if not DataLoaded then
            if TryLoadTrialBalanceData(LoadFromCache, DataLoaded) then // LoadFromCache is true when called from OnOpenPage
                if DataLoaded and (NoOfColumns <> 1) then
                    TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);

        if DataLoaded then
            SetStyles()
        else
            IsError := true;
    end;

    local procedure DrillDown(RowNo: Integer; ColumnNo: Integer)
    begin
        if LoadedFromCache then begin
            TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            LoadedFromCache := false;
        end;

        TrialBalanceMgt.DrillDown(RowNo, ColumnNo);
    end;
}

