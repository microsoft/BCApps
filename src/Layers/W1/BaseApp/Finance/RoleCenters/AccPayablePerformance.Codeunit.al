// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Analysis;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Visualization;

codeunit 9059 "Acc. Payable Performance"
{
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        PurchbyVendGrpChartSetup: Record "Purch. by Vend.Grp.Chart Setup";
        TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        AgedAccPayable: Codeunit "Aged Acc. Payable";
        TopFiveVendorsChart: Codeunit "Top Five Vendors Chart";
        AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
        PurchByVendGrpChartMgt: Codeunit "Purch. by Vend.Grp. Chart Mgt.";
        Period: Option " ",Next,Previous;
        TopFiveVendorChartNameTxt: Label 'Top 5 Vendors Chart';
        AgedAccPayableNameTxt: Label 'Aged Accounts Payable';
        XIncomeAndExpenseChartNameTxt: Label 'Income & Expense';
        PurchasesByVendorGroupNameTxt: Label 'Purchases Trends by Vendor Groups';
        TopFiveVendorsChartDescriptionTxt: Label 'This Pie chart shows the five vendors with the highest purchases value.';
        NoEnabledChartsFoundErr: Label 'There are no enabled charts. Choose Select Chart to see a list of charts that you can display.';
        ChartDefinitionMissingErr: Label 'There are no charts defined.';
        MediumStatusTxt: Label '%1 | View by %2', Comment = '%1 - Account Schedule Chart Setup Name, %2 - Period Length';

    procedure AddinReady(var PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusinessChartBuffer: Record "Business Chart Buffer")
    var
        LastUsedChart: Record "Last Used Chart";
        LastChartRecorded: Boolean;
        LastChartExists: Boolean;
        LastChartEnabled: Boolean;
    begin
        LastChartRecorded := LastUsedChart.Get(UserId);
        LastChartExists :=
          LastChartRecorded and PayablePerformanceChart.Get(LastUsedChart."Code Unit ID", LastUsedChart."Chart Name");
        LastChartEnabled := LastChartExists and PayablePerformanceChart.Enabled;
        if PayablePerformanceChart.IsEmpty() then
            exit;
        if not LastChartEnabled then begin
            PayablePerformanceChart.SetRange(Enabled, true);
            if not PayablePerformanceChart.FindLast() then
                Dialog.Error(NoEnabledChartsFoundErr);
        end;
        SetDefaultPeriodLength(PayablePerformanceChart, BusinessChartBuffer);
        UpdateChart(PayablePerformanceChart, BusinessChartBuffer, Period::" ");
    end;

    internal procedure ChartDescription(PayablePerformanceChart: Record "Acc. Payable Performance Chart"): Text
    begin
        case PayablePerformanceChart."Code Unit ID" of
            Codeunit::"Acc. Sched. Chart Management":
                exit(AccountSchedulesChartSetup.Description);
            Codeunit::"Aged Acc. Payable":
                exit(AgedAccPayable.Description(false));
            Codeunit::"Top Five Vendors Chart":
                exit(TopFiveVendorsChartDescriptionTxt);
        end;
    end;

    internal procedure DataPointClicked(var BusinessChartBuffer: Record "Business Chart Buffer"; var PayablePerformanceChart: Record "Acc. Payable Performance Chart")
    begin
        case PayablePerformanceChart."Code Unit ID" of
            Codeunit::"Acc. Sched. Chart Management":
                AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);
            Codeunit::"Top Five Vendors Chart":
                TopFiveVendorsChart.DrillDown(BusinessChartBuffer);
            Codeunit::"Aged Acc. Payable":
                AgedAccPayable.DrillDownByGroup(BusinessChartBuffer, TempEntryNoAmountBuf);
            Codeunit::"Purch. by Vend.Grp. Chart Mgt.":
                PurchByVendGrpChartMgt.DrillDown(BusinessChartBuffer);
        end;
    end;

    internal procedure PopulateChartDefinitionTable()
    begin
        InsertChartDefinition(Codeunit::"Top Five Vendors Chart", TopFiveVendorChartNameTxt);
        InsertChartDefinition(Codeunit::"Aged Acc. Payable", AgedAccPayableNameTxt);
        InsertChartDefinition(Codeunit::"Acc. Sched. Chart Management", XIncomeAndExpenseChartNameTxt);
        InsertChartDefinition(Codeunit::"Purch. by Vend.Grp. Chart Mgt.", PurchasesByVendorGroupNameTxt);
    end;

    internal procedure SelectChart(var BusinessChartBuffer: Record "Business Chart Buffer"; var PayablePerformanceChart: Record "Acc. Payable Performance Chart")
    var
        PayablePerformanceCharts: Page "Acc. Payable Perf. Charts";
    begin
        if PayablePerformanceChart.IsEmpty() then
            if PayablePerformanceChart.WritePermission then begin
                PopulateChartDefinitionTable();
                Commit(); // Commit needed to pevent transaction error when inserting chart definition
            end else
                Error(ChartDefinitionMissingErr);
        PayablePerformanceCharts.LookupMode(true);

        if PayablePerformanceCharts.RunModal() = ACTION::LookupOK then begin
            PayablePerformanceCharts.GetRecord(PayablePerformanceChart);
            SetDefaultPeriodLength(PayablePerformanceChart, BusinessChartBuffer);
            UpdateChart(PayablePerformanceChart, BusinessChartBuffer, Period::" ");
        end;
    end;

    internal procedure SetDefaultPeriodLength(PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusChartBuf: Record "Business Chart Buffer")
    var
        BusChartUserSetup: Record "Business Chart User Setup";
    begin
        case PayablePerformanceChart."Code Unit ID" of
            Codeunit::"Aged Acc. Payable":
                begin
                    BusChartUserSetup.InitSetupCU(Codeunit::"Aged Acc. Payable");

                    SetPeriodLength(
                        PayablePerformanceChart,
                        BusChartBuf,
                        BusChartUserSetup."Period Length",
                        true
                    );
                end;
            Codeunit::"Acc. Sched. Chart Management":
                begin
                    AccountSchedulesChartSetup.Get('', PayablePerformanceChart."Chart Name");

                    SetPeriodLength(
                        PayablePerformanceChart,
                        BusChartBuf,
                        AccountSchedulesChartSetup."Period Length",
                        true
                    );
                end;
        end;
    end;

    internal procedure SetPeriodLength(
        PayablePerformanceChart: Record "Acc. Payable Performance Chart";
        var BusChartBuf: Record "Business Chart Buffer";
        PeriodLength: Option;
        IsInitState: Boolean)
    var
        NewStartDate: Date;
    begin
        case PayablePerformanceChart."Code Unit ID" of
            Codeunit::"Acc. Sched. Chart Management":
                begin
                    AccountSchedulesChartSetup.Get('', PayablePerformanceChart."Chart Name");
                    AccountSchedulesChartSetup.SetPeriodLength(PeriodLength);
                    BusChartBuf."Period Length" := PeriodLength;
                    if AccountSchedulesChartSetup."Look Ahead" then
                        NewStartDate := GetBaseDate(BusChartBuf, IsInitState)
                    else
                        NewStartDate :=
                            CalcDate(
                                StrSubstNo(
                                    '<-%1%2>',
                                    AccountSchedulesChartSetup."No. of Periods",
                                    BusChartBuf.GetPeriodLength()),
                                GetBaseDate(BusChartBuf, IsInitState)
                            );
                    if AccountSchedulesChartSetup."Start Date" <> NewStartDate then begin
                        AccountSchedulesChartSetup.Validate("Start Date", NewStartDate);
                        AccountSchedulesChartSetup.Modify(true);
                    end;
                end;
            Codeunit::"Purch. by Vend.Grp. Chart Mgt.":
                PurchbyVendGrpChartSetup.SetPeriodLength(PeriodLength);
            else
                BusChartBuf."Period Length" := PeriodLength;
        end;
    end;

    internal procedure UpdateChartSafe(var PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option; var ErrorMessage: Text): Boolean
    begin
        ClearLastError();
        OnUpdateChartSafe(PayablePerformanceChart, BusinessChartBuffer, Period);
        ErrorMessage := GetLastErrorText();
        if ErrorMessage = '' then
            exit(true);

        ClearLastError();

        exit(false);
    end;

    internal procedure UpdateChart(var PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option)
    begin
        case PayablePerformanceChart."Code Unit ID" of
            Codeunit::"Acc. Sched. Chart Management":
                begin
                    AccSchedChartManagement.GetSetupRecordset(
                        AccountSchedulesChartSetup,
                        PayablePerformanceChart."Chart Name",
                        0
                    );

                    AccSchedChartManagement.UpdateData(BusinessChartBuffer, Period, AccountSchedulesChartSetup);
                end;
            Codeunit::"Aged Acc. Payable":
                begin
                    BusinessChartBuffer."Period Filter Start Date" := WorkDate();
                    AgedAccPayable.UpdateData(BusinessChartBuffer, TempEntryNoAmountBuf);
                    AgedAccPayable.SaveSettings(BusinessChartBuffer)
                end;
            Codeunit::"Purch. by Vend.Grp. Chart Mgt.":
                begin
                    PurchbyVendGrpChartSetup.SetPeriod(Period);
                    PurchByVendGrpChartMgt.UpdateChart(BusinessChartBuffer);
                end;
            else
                TopFiveVendorsChart.UpdateChart(BusinessChartBuffer);
        end;

        UpdateLastUsedChart(PayablePerformanceChart);
    end;

    internal procedure UpdateStatusText(var PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusinessChartBuffer: Record "Business Chart Buffer"; var StatusText: Text)
    begin
        case PayablePerformanceChart."Code Unit ID" of
            Codeunit::"Aged Acc. Payable":
                StatusText := StrSubstNo(MediumStatusTxt, PayablePerformanceChart."Chart Name", BusinessChartBuffer."Period Length");
            else
                StatusText := PayablePerformanceChart."Chart Name";
        end;
    end;

    local procedure UpdateLastUsedChart(PayablePerformanceChart: Record "Acc. Payable Performance Chart")
    var
        LastUsedChart: Record "Last Used Chart";
    begin
        if LastUsedChart.Get(UserId) then begin
            if (LastUsedChart."Code Unit ID" <> PayablePerformanceChart."Code Unit ID") or (LastUsedChart."Chart Name" <> PayablePerformanceChart."Chart Name") then begin
                LastUsedChart.Validate("Code Unit ID", PayablePerformanceChart."Code Unit ID");
                LastUsedChart.Validate("Chart Name", PayablePerformanceChart."Chart Name");
                LastUsedChart.Modify(false);
            end;
        end else begin
            LastUsedChart.Validate(UID, UserId);
            LastUsedChart.Validate("Code Unit ID", PayablePerformanceChart."Code Unit ID");
            LastUsedChart.Validate("Chart Name", PayablePerformanceChart."Chart Name");
            LastUsedChart.Insert(false);
        end;
    end;

    local procedure InsertChartDefinition(ChartCodeunitId: Integer; ChartName: Text[60])
    var
        PayablePerformanceChart: Record "Acc. Payable Performance Chart";
    begin
        if PayablePerformanceChart.Get(ChartCodeunitId, ChartName) then
            exit;

        PayablePerformanceChart."Code Unit ID" := ChartCodeunitId;
        PayablePerformanceChart."Chart Name" := ChartName;
        EnableChart(PayablePerformanceChart);
        PayablePerformanceChart.Insert(false);
    end;

    internal procedure EnableChart(var PayablePerformanceChart: Record "Acc. Payable Performance Chart")
    begin
        PayablePerformanceChart.Enabled := true;
    end;

    local procedure GetPeriodLength(): Text[1]
    begin
        case AccountSchedulesChartSetup."Period Length" of
            AccountSchedulesChartSetup."Period Length"::Day:
                exit('D');
            AccountSchedulesChartSetup."Period Length"::Week:
                exit('W');
            AccountSchedulesChartSetup."Period Length"::Month:
                exit('M');
            AccountSchedulesChartSetup."Period Length"::Quarter:
                exit('Q');
            AccountSchedulesChartSetup."Period Length"::Year:
                exit('Y');
        end;
    end;

    local procedure GetBaseDate(var BusChartBuf: Record "Business Chart Buffer"; IsInitState: Boolean): Date
    var
        ColumnIndex: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        if AccountSchedulesChartSetup."Look Ahead" then
            ColumnIndex := 0
        else
            ColumnIndex := AccountSchedulesChartSetup."No. of Periods" - 1;

        if IsInitState then
            exit(WorkDate());

        BusChartBuf.GetPeriodFromMapColumn(ColumnIndex, StartDate, EndDate);

        if AccountSchedulesChartSetup."Look Ahead" then
            exit(StartDate);

        exit(CalcDate(StrSubstNo('<1%1>', GetPeriodLength()), EndDate));
    end;

    internal procedure TopVendorListUpdatedRecently(var LastVendorLedgerEntryNo: Integer): Boolean
    var
        TopVendorsByPurch: Record "Top Vendors By Purchase";
        LastBufferUpdateDateTime: DateTime;
        TwelveHourDuration: Duration;
        ZeroDayTime: DateTime;
    begin
        if TopVendorsByPurch.FindFirst() then begin
            LastBufferUpdateDateTime := TopVendorsByPurch.DateTimeUpdated;
            ZeroDayTime := 0DT;
            TwelveHourDuration := 43200000;
            LastVendorLedgerEntryNo := TopVendorsByPurch.LastVendLedgerEntryNo;

            if LastBufferUpdateDateTime = ZeroDayTime then
                exit(false);

            if CurrentDateTime - LastBufferUpdateDateTime < TwelveHourDuration then
                exit(true);
        end;
    end;

    internal procedure ScheduleTopVendorListRefreshTask()
    var
        LastVendorLedgerEntryNo: Integer;
    begin
        if TopVendorListUpdatedRecently(LastVendorLedgerEntryNo) then
            exit;

        if TaskScheduler.CanCreateTask() then
            TaskScheduler.CreateTask(Codeunit::"Top Vendors By Purchases Job", 0, true, CompanyName(), 0DT);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Acc. Payable Performance", OnUpdateChartSafe, '', false, false)]
    local procedure HandleUpdateChartSafe(var PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option)
    begin
        UpdateChart(PayablePerformanceChart, BusinessChartBuffer, Period);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateChartSafe(var PayablePerformanceChart: Record "Acc. Payable Performance Chart"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option)
    begin
    end;
}
