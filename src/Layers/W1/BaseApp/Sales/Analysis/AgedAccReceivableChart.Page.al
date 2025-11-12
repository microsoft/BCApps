// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Finance.ReceivablesPayables;
using System.Integration;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Visualization;

page 768 "Aged Acc. Receivable Chart"
{
    Caption = 'Aged Accounts Receivable';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field(StatusText; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies the status of the chart.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(Point);
                    AgedAccReceivable.DrillDown(BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuf);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    Initialize();
                end;

                trigger Refresh()
                begin
                    UpdatePage();
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DayPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Day';
                Enabled = DayEnabled;
                ToolTip = 'View pending payments summed for one day. Overdue payments are shown as amounts on specific days from the due date going back two weeks from today''s date.';

                trigger OnAction()
                begin
                    BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Day;
                    Clear(UpdatedCustomerNo);
                    UpdatePage();
                end;
            }
            action(WeekPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Week';
                Enabled = WeekEnabled;
                ToolTip = 'Show pending payments summed for one week. Overdue payments are shown as amounts within specific weeks from the due date going back three months from today''s date.';

                trigger OnAction()
                begin
                    BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;
                    Clear(UpdatedCustomerNo);
                    UpdatePage();
                end;
            }
            action(MonthPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Month';
                Enabled = MonthEnabled;
                ToolTip = 'View pending payments summed for one month. Overdue payments are shown as amounts within specific months from the due date going back one year from today''s date.';

                trigger OnAction()
                begin
                    BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Month;
                    Clear(UpdatedCustomerNo);
                    UpdatePage();
                end;
            }
            action(QuarterPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Quarter';
                Enabled = QuarterEnabled;
                ToolTip = 'Show pending payments summed for one quarter. Overdue payments are shown as amounts within specific quarters from the due date going back three years from today''s date.';

                trigger OnAction()
                begin
                    BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Quarter;
                    Clear(UpdatedCustomerNo);
                    UpdatePage();
                end;
            }
            action(YearPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Year';
                Enabled = YearEnabled;
                ToolTip = 'Show pending payments summed for one year. Overdue payments are shown as amounts within specific years from the due date going back five years from today''s date.';

                trigger OnAction()
                begin
                    BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Year;
                    Clear(UpdatedCustomerNo);
                    UpdatePage();
                end;
            }
            action(All)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All';
                Enabled = AllEnabled;
                ToolTip = 'Show all accounts receivable in two columns, one with amounts not overdue and one with all overdue amounts.';

                trigger OnAction()
                begin
                    BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::None;
                    Clear(UpdatedCustomerNo);
                    UpdatePage();
                end;
            }
            separator(Action5)
            {
            }
            action(ChartInformation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart Information';
                Image = Info;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                begin
                    Message(AgedAccReceivable.Description(true));
                end;
            }
        }
    }

    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        isInitialized: Boolean;
        StatusText: Text;
        DayEnabled: Boolean;
        WeekEnabled: Boolean;
        MonthEnabled: Boolean;
        QuarterEnabled: Boolean;
        YearEnabled: Boolean;
        AllEnabled: Boolean;
        CustomerNo: Code[20];
        UpdatedCustomerNo: Code[20];
        BackgroundTaskId: Integer;
        UpdatePending: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        CustomerNo := Rec."No.";
        if UpdatedCustomerNo <> CustomerNo then
            if isInitialized then
                BusinessChartBuffer.Initialize();
        if UpdatePending then begin
            BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
            UpdatePending := false;
        end else
            UpdateChart();
    end;

    trigger OnOpenPage()
    var
        BusChartUserSetup: Record "Business Chart User Setup";
    begin
        BusChartUserSetup.InitSetupPage(PAGE::"Aged Acc. Receivable Chart");
        BusinessChartBuffer."Period Length" := BusChartUserSetup."Period Length";
    end;

    local procedure Initialize()
    begin
        isInitialized := true;

        BusinessChartBuffer.Initialize();
        BusinessChartBuffer."Period Filter Start Date" := WorkDate();
        BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);

        UpdatePage();
    end;

    local procedure UpdatePage()
    begin
        EnableActions();
        UpdateStatusText();
        UpdateChart();
        SavePeriodSelection();
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        RowNo: Integer;
    begin
        if TaskId <> BackgroundTaskId then
            exit;
        if Results.Count() = 0 then
            exit;
        TempEntryNoAmountBuf.DeleteAll();
        clear(TempEntryNoAmountBuf);
        for RowNo := 1 to Results.Count() div 5 do begin
            TempEntryNoAmountBuf.Init();
            if evaluate(TempEntryNoAmountBuf."Entry No.", GetDictValue(Results, 'EntryNo¤%1' + Format(RowNo)), 9) then;
            if evaluate(TempEntryNoAmountBuf.Amount, GetDictValue(Results, 'Amount¤%1' + Format(RowNo)), 9) then;
            if evaluate(TempEntryNoAmountBuf.Amount2, GetDictValue(Results, 'Amount2¤%1' + Format(RowNo)), 9) then;
            if evaluate(TempEntryNoAmountBuf."End Date", GetDictValue(Results, 'EndDate¤%1' + Format(RowNo)), 9) then;
            if evaluate(TempEntryNoAmountBuf."Start Date", GetDictValue(Results, 'StartDate¤%1' + Format(RowNo)), 9) then;
            TempEntryNoAmountBuf.Insert();
        end;
        AgedAccReceivable.UpdateDataPerCustomer(BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuf, true);
        UpdatedCustomerNo := CustomerNo;
        BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
        UpdatePending := false;
    end;

    local procedure GetDictValue(var Results: Dictionary of [Text, Text]; keyVal: Text): Text
    var
        t: Text;
    begin
        if not TryGetDictValue(Results, keyVal, t) then
            exit('');
        exit(t);
    end;

    [TryFunction]
    local procedure TryGetDictValue(var Results: Dictionary of [Text, Text]; keyVal: Text; var Result: Text)
    begin
        Result := Results.Get(keyVal);
    end;

    local procedure UpdateChart()
    var
        Args: Dictionary of [Text, Text];
    begin
        if not isInitialized then
            exit;

        if CustomerNo = '' then
            exit;

        if UpdatedCustomerNo = CustomerNo then
            exit;

        if UpdatedCustomerNo <> '' then begin
            BusinessChartBuffer.Initialize();
            BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
        end;
        BusinessChartBuffer."Period Filter Start Date" := WorkDate();

        Args.Add('CustomerNo', CustomerNo);
        Args.Add('StartDate', format(BusinessChartBuffer."Period Filter Start Date", 0, 9));
        Args.Add('PeriodLength', format(BusinessChartBuffer."Period Length", 0, 9));

        CurrPage.EnqueueBackgroundTask(BackgroundTaskId, Codeunit::"Aged Acc. Receivable", Args);
    end;

    local procedure SavePeriodSelection()
    var
        BusChartUserSetup: Record "Business Chart User Setup";
    begin
        BusChartUserSetup."Period Length" := BusinessChartBuffer."Period Length";
        BusChartUserSetup.SaveSetupPage(BusChartUserSetup, PAGE::"Aged Acc. Receivable Chart");
    end;

    local procedure EnableActions()
    var
        IsDay: Boolean;
        IsWeek: Boolean;
        IsMonth: Boolean;
        IsQuarter: Boolean;
        IsYear: Boolean;
        IsAnyPeriod: Boolean;
    begin
        IsAnyPeriod := BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::None;
        IsDay := BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Day;
        IsWeek := BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Week;
        IsMonth := BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Month;
        IsQuarter := BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Quarter;
        IsYear := BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Year;

        DayEnabled := (not IsDay and isInitialized) or IsAnyPeriod;
        WeekEnabled := (not IsWeek and isInitialized) or IsAnyPeriod;
        MonthEnabled := (not IsMonth and isInitialized) or IsAnyPeriod;
        QuarterEnabled := (not IsQuarter and isInitialized) or IsAnyPeriod;
        YearEnabled := (not IsYear and isInitialized) or IsAnyPeriod;
        AllEnabled := (not IsAnyPeriod) and isInitialized;
    end;

    local procedure UpdateStatusText()
    begin
        StatusText := AgedAccReceivable.UpdateStatusText(BusinessChartBuffer);
    end;

    procedure UpdateChartForCustomer(NewCustomerNo: Code[20])
    begin
        CustomerNo := NewCustomerNo;
        UpdateChart();
    end;
}

