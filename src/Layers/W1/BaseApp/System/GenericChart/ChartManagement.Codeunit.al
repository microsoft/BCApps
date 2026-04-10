namespace System.Visualization;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Inventory.Analysis;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

codeunit 1315 "Chart Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        SalesByCustGrpChartSetup: Record "Sales by Cust. Grp.Chart Setup";
        AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
        TopTenCustomersChartMgt: Codeunit "Top Ten Customers Chart Mgt.";
        TopFiveCustomersChartMgt: Codeunit "Top Five Customers Chart Mgt.";
        AgedInventoryChartMgt: Codeunit "Aged Inventory Chart Mgt.";
        SalesByCustGrpChartMgt: Codeunit "Sales by Cust. Grp. Chart Mgt.";
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        AgedAccPayable: Codeunit "Aged Acc. Payable";
        Period: Option " ",Next,Previous;
        MediumStatusTxt: Label '%1 | View by %2', Comment = '%1 Account Schedule Chart Setup Name, %2 Period Length, %3 Current time';
        LongStatusTxt: Label '%1 | %2..%3 | %4', Comment = '%1 Account Schedule Chart Setup Name, %2 = Start Date, %3 = End Date, %4 Period Length, %5 Current time';
        TopTenCustomerChartNameTxt: Label 'Top Ten Customers by Sales Value';
        TopFiveCustomerChartNameTxt: Label 'Top Five Customers by Sales Value';
        SalesByCustomerGroupNameTxt: Label 'Sales Trends by Customer Groups';
        SalesByCustomerGroupDescriptionTxt: Label 'This chart shows sales trends by customer group in the selected period.';
        TopTenCustomersChartDescriptionTxt: Label 'This chart shows the ten customers with the highest total sales value. The last column shows the sum of sales values of all other customers.';
        TopFiveCustomersChartDescriptionTxt: Label 'This Pie chart shows the five customers with the highest total sales value.';
        AgedInventoryChartDescriptionTxt: Label 'This chart shows the total inventory value, grouped by the number of days that the items are on inventory.';
        AgedAccReceivableNameTxt: Label 'Aged Accounts Receivable';
        AgedAccPayableNameTxt: Label 'Aged Accounts Payable';
        XCashFlowChartNameTxt: Label 'Cash Flow';
        XIncomeAndExpenseChartNameTxt: Label 'Income & Expense';
        XCashCycleChartNameTxt: Label 'Cash Cycle';
        NoEnabledChartsFoundErr: Label 'There are no enabled charts. Choose Select Chart to see a list of charts that you can display.';
        ChartDefinitionMissingErr: Label 'There are no charts defined.';

    procedure AddinReady(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer")
    var
        LastUsedChart: Record "Last Used Chart";
        LastChartRecorded: Boolean;
        LastChartExists: Boolean;
        LastChartEnabled: Boolean;
    begin
        LastChartRecorded := LastUsedChart.Get(UserId);
        LastChartExists :=
          LastChartRecorded and ChartDefinition.Get(LastUsedChart."Code Unit ID", LastUsedChart."Chart Name");
        LastChartEnabled := LastChartExists and ChartDefinition.Enabled;
        if ChartDefinition.IsEmpty() then
            exit;
        if not LastChartEnabled then begin
            ChartDefinition.SetRange(Enabled, true);
            if not ChartDefinition.FindLast() then
                DIALOG.Error(NoEnabledChartsFoundErr);
        end;
        SetDefaultPeriodLength(ChartDefinition, BusinessChartBuffer);
        UpdateChart(ChartDefinition, BusinessChartBuffer, Period::" ");
    end;

    procedure ChartDescription(ChartDefinition: Record "Chart Definition"): Text
    var
        ChartDescription: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChartDescription(ChartDefinition, ChartDescription, IsHandled);
        if IsHandled then
            exit(ChartDescription);

        case ChartDefinition."Code Unit ID" of
            CODEUNIT::"Acc. Sched. Chart Management":
                exit(AccountSchedulesChartSetup.Description);
            CODEUNIT::"Top Ten Customers Chart Mgt.":
                exit(TopTenCustomersChartDescriptionTxt);
            CODEUNIT::"Aged Inventory Chart Mgt.":
                exit(AgedInventoryChartDescriptionTxt);
            CODEUNIT::"Sales by Cust. Grp. Chart Mgt.":
                exit(SalesByCustomerGroupDescriptionTxt);
            CODEUNIT::"Aged Acc. Receivable":
                exit(AgedAccReceivable.Description(false));
            CODEUNIT::"Aged Acc. Payable":
                exit(AgedAccPayable.Description(false));
            CODEUNIT::"Top Five Customers Chart Mgt.":
                exit(TopFiveCustomersChartDescriptionTxt);
        end;
    end;

    procedure CashFlowChartName(): Text[30]
    begin
        exit(XCashFlowChartNameTxt)
    end;

    procedure CashCycleChartName(): Text[30]
    begin
        exit(XCashCycleChartNameTxt)
    end;

    procedure IncomeAndExpenseChartName(): Text[30]
    begin
        exit(XIncomeAndExpenseChartNameTxt)
    end;

    procedure DataPointClicked(var BusinessChartBuffer: Record "Business Chart Buffer"; var ChartDefinition: Record "Chart Definition")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDataPointClicked(ChartDefinition, BusinessChartBuffer, IsHandled);
        if IsHandled then
            exit;

        case ChartDefinition."Code Unit ID" of
            CODEUNIT::"Acc. Sched. Chart Management":
                AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);
            CODEUNIT::"Top Ten Customers Chart Mgt.":
                TopTenCustomersChartMgt.DrillDown(BusinessChartBuffer);
            CODEUNIT::"Top Five Customers Chart Mgt.":
                TopFiveCustomersChartMgt.DrillDown(BusinessChartBuffer);
            CODEUNIT::"Aged Inventory Chart Mgt.":
                AgedInventoryChartMgt.DrillDown(BusinessChartBuffer);
            CODEUNIT::"Sales by Cust. Grp. Chart Mgt.":
                SalesByCustGrpChartMgt.DrillDown(BusinessChartBuffer);
            CODEUNIT::"Aged Acc. Receivable":
                AgedAccReceivable.DrillDownByGroup(BusinessChartBuffer, TempEntryNoAmountBuf);
            CODEUNIT::"Aged Acc. Payable":
                AgedAccPayable.DrillDownByGroup(BusinessChartBuffer, TempEntryNoAmountBuf);
        end;
    end;

    procedure PopulateChartDefinitionTable()
    begin
        InsertChartDefinition(CODEUNIT::"Top Five Customers Chart Mgt.", TopFiveCustomerChartNameTxt);
        InsertChartDefinition(CODEUNIT::"Top Ten Customers Chart Mgt.", TopTenCustomerChartNameTxt);
        InsertChartDefinition(CODEUNIT::"Sales by Cust. Grp. Chart Mgt.", SalesByCustomerGroupNameTxt);
        InsertChartDefinition(CODEUNIT::"Aged Acc. Receivable", AgedAccReceivableNameTxt);
        InsertChartDefinition(CODEUNIT::"Aged Acc. Payable", AgedAccPayableNameTxt);
        InsertChartDefinition(CODEUNIT::"Acc. Sched. Chart Management", XCashFlowChartNameTxt);
        InsertChartDefinition(CODEUNIT::"Acc. Sched. Chart Management", XIncomeAndExpenseChartNameTxt);
        InsertChartDefinition(CODEUNIT::"Acc. Sched. Chart Management", XCashCycleChartNameTxt);

        OnAfterPopulateChartDefinitionTable();
    end;

    procedure SelectChart(var BusinessChartBuffer: Record "Business Chart Buffer"; var ChartDefinition: Record "Chart Definition")
    var
        ChartList: Page "Chart List";
    begin
        if ChartDefinition.IsEmpty() then
            if ChartDefinition.WritePermission then begin
                PopulateChartDefinitionTable();
                Commit();
            end else
                Error(ChartDefinitionMissingErr);
        ChartList.LookupMode(true);

        if ChartList.RunModal() = ACTION::LookupOK then begin
            ChartList.GetRecord(ChartDefinition);
            SetDefaultPeriodLength(ChartDefinition, BusinessChartBuffer);
            UpdateChart(ChartDefinition, BusinessChartBuffer, Period::" ");
        end;
    end;

    procedure SetDefaultPeriodLength(ChartDefinition: Record "Chart Definition"; var BusChartBuf: Record "Business Chart Buffer")
    var
        BusChartUserSetup: Record "Business Chart User Setup";
    begin
        case ChartDefinition."Code Unit ID" of
            CODEUNIT::"Aged Inventory Chart Mgt.":
                SetPeriodLength(ChartDefinition, BusChartBuf, BusChartBuf."Period Length"::Month, true);
            CODEUNIT::"Aged Acc. Receivable":
                begin
                    BusChartUserSetup.InitSetupCU(CODEUNIT::"Aged Acc. Receivable");
                    SetPeriodLength(ChartDefinition, BusChartBuf, BusChartUserSetup."Period Length", true);
                end;
            CODEUNIT::"Aged Acc. Payable":
                begin
                    BusChartUserSetup.InitSetupCU(CODEUNIT::"Aged Acc. Payable");
                    SetPeriodLength(ChartDefinition, BusChartBuf, BusChartUserSetup."Period Length", true);
                end;
            CODEUNIT::"Acc. Sched. Chart Management":
                begin
                    AccountSchedulesChartSetup.Get('', ChartDefinition."Chart Name");
                    SetPeriodLength(ChartDefinition, BusChartBuf, AccountSchedulesChartSetup."Period Length", true);
                end;
        end;
    end;

    procedure SetPeriodLength(ChartDefinition: Record "Chart Definition"; var BusChartBuf: Record "Business Chart Buffer"; PeriodLength: Option; IsInitState: Boolean)
    var
        NewStartDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPeriodLength(ChartDefinition, PeriodLength, IsHandled);
        if IsHandled then
            exit;

        case ChartDefinition."Code Unit ID" of
            CODEUNIT::"Acc. Sched. Chart Management":
                begin
                    AccountSchedulesChartSetup.Get('', ChartDefinition."Chart Name");
                    AccountSchedulesChartSetup.SetPeriodLength(PeriodLength);
                    BusChartBuf."Period Length" := PeriodLength;
                    if AccountSchedulesChartSetup."Look Ahead" then
                        NewStartDate := GetBaseDate(BusChartBuf, IsInitState)
                    else
                        NewStartDate :=
                          CalcDate(
                            StrSubstNo(
                              '<-%1%2>', AccountSchedulesChartSetup."No. of Periods", BusChartBuf.GetPeriodLength()),
                            GetBaseDate(BusChartBuf, IsInitState));
                    if AccountSchedulesChartSetup."Start Date" <> NewStartDate then begin
                        AccountSchedulesChartSetup.Validate("Start Date", NewStartDate);
                        AccountSchedulesChartSetup.Modify(true);
                    end;
                end;
            CODEUNIT::"Sales by Cust. Grp. Chart Mgt.":
                SalesByCustGrpChartSetup.SetPeriodLength(PeriodLength);
            else
                BusChartBuf."Period Length" := PeriodLength;
        end;
    end;

    procedure UpdateChartSafe(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option; var ErrorMessage: Text): Boolean
    begin
        ClearLastError();
        OnUpdateChartSafe(ChartDefinition, BusinessChartBuffer, Period);
        ErrorMessage := GetLastErrorText();
        if ErrorMessage = '' then
            exit(true);

        ClearLastError();
        exit(false);
    end;

    procedure UpdateChart(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateChart(ChartDefinition, BusinessChartBuffer, Period, IsHandled);
        if IsHandled then
            exit;

        case ChartDefinition."Code Unit ID" of
            CODEUNIT::"Acc. Sched. Chart Management":
                begin
                    AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartDefinition."Chart Name", 0);
                    AccSchedChartManagement.UpdateData(BusinessChartBuffer, Period, AccountSchedulesChartSetup);
                end;
            CODEUNIT::"Aged Inventory Chart Mgt.":
                AgedInventoryChartMgt.UpdateChart(BusinessChartBuffer);
            CODEUNIT::"Sales by Cust. Grp. Chart Mgt.":
                begin
                    SalesByCustGrpChartSetup.SetPeriod(Period);
                    SalesByCustGrpChartMgt.UpdateChart(BusinessChartBuffer);
                end;
            CODEUNIT::"Aged Acc. Receivable":
                begin
                    BusinessChartBuffer."Period Filter Start Date" := WorkDate();
                    AgedAccReceivable.UpdateDataPerGroup(BusinessChartBuffer, TempEntryNoAmountBuf);
                    AgedAccReceivable.SaveSettings(BusinessChartBuffer);
                end;
            CODEUNIT::"Aged Acc. Payable":
                begin
                    BusinessChartBuffer."Period Filter Start Date" := WorkDate();
                    AgedAccPayable.UpdateData(BusinessChartBuffer, TempEntryNoAmountBuf);
                    AgedAccPayable.SaveSettings(BusinessChartBuffer)
                end;
            CODEUNIT::"Top Five Customers Chart Mgt.":
                TopFiveCustomersChartMgt.UpdateChart(BusinessChartBuffer);
            else
                TopTenCustomersChartMgt.UpdateChart(BusinessChartBuffer);
        end;
        UpdateLastUsedChart(ChartDefinition);
    end;

    procedure UpdateNextPrevious(var ChartDefinition: Record "Chart Definition"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateNextPrevious(ChartDefinition, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ChartDefinition."Code Unit ID" in
          [CODEUNIT::"Acc. Sched. Chart Management",
           CODEUNIT::"Sales by Cust. Grp. Chart Mgt."]);
    end;

    procedure UpdateStatusText(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; var StatusText: Text)
    var
        StartDate: Date;
        EndDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateStatusText(ChartDefinition, BusinessChartBuffer, StatusText, IsHandled);
        if IsHandled then
            exit;

        StartDate := BusinessChartBuffer."Period Filter Start Date";
        EndDate := BusinessChartBuffer."Period Filter End Date";
        case ChartDefinition."Code Unit ID" of
            CODEUNIT::"Acc. Sched. Chart Management":
                case AccountSchedulesChartSetup."Base X-Axis on" of
                    AccountSchedulesChartSetup."Base X-Axis on"::Period:
                        StatusText := StrSubstNo(MediumStatusTxt, ChartDefinition."Chart Name", AccountSchedulesChartSetup."Period Length");
                    AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
                      AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                        StatusText := StrSubstNo(LongStatusTxt, ChartDefinition."Chart Name", StartDate, EndDate, AccountSchedulesChartSetup."Period Length");
                end;
            CODEUNIT::"Sales by Cust. Grp. Chart Mgt.",
          CODEUNIT::"Aged Acc. Receivable",
          CODEUNIT::"Aged Acc. Payable",
          CODEUNIT::"Aged Inventory Chart Mgt.":
                StatusText := StrSubstNo(MediumStatusTxt, ChartDefinition."Chart Name", BusinessChartBuffer."Period Length");
            else
                StatusText := ChartDefinition."Chart Name";
        end;
    end;

    local procedure UpdateLastUsedChart(ChartDefinition: Record "Chart Definition")
    var
        LastUsedChart: Record "Last Used Chart";
    begin
        if LastUsedChart.Get(UserId) then begin
            if (LastUsedChart."Code Unit ID" <> ChartDefinition."Code Unit ID") or (LastUsedChart."Chart Name" <> ChartDefinition."Chart Name") then begin
                LastUsedChart.Validate("Code Unit ID", ChartDefinition."Code Unit ID");
                LastUsedChart.Validate("Chart Name", ChartDefinition."Chart Name");
                LastUsedChart.Modify();
            end;
        end else begin
            LastUsedChart.Validate(UID, UserId);
            LastUsedChart.Validate("Code Unit ID", ChartDefinition."Code Unit ID");
            LastUsedChart.Validate("Chart Name", ChartDefinition."Chart Name");
            LastUsedChart.Insert();
        end;
    end;

    local procedure InsertChartDefinition(ChartCodeunitId: Integer; ChartName: Text[60])
    var
        ChartDefinition: Record "Chart Definition";
    begin
        if not ChartDefinition.Get(ChartCodeunitId, ChartName) then begin
            ChartDefinition."Code Unit ID" := ChartCodeunitId;
            ChartDefinition."Chart Name" := ChartName;
            EnableChart(ChartDefinition);
            ChartDefinition.Insert();
        end;
    end;

    procedure EnableChart(var ChartDefinition: Record "Chart Definition")
    begin
        if ChartDefinition."Code Unit ID" = CODEUNIT::"Acc. Sched. Chart Management" then begin
            if not ChartDefinition.IsSetupComplete(ChartDefinition) then
                exit;
            ChartDefinition.Enabled := true;
        end else
            ChartDefinition.Enabled := true;
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

    procedure AgedAccReceivableName(): Text[60]
    begin
        exit(AgedAccReceivableNameTxt)
    end;

    procedure AgedAccPayableName(): Text[60]
    begin
        exit(AgedAccPayableNameTxt)
    end;

    [Scope('OnPrem')]
    procedure ScheduleTopCustomerListRefreshTask()
    var
        LastCustomerLedgerEntryNo: Integer;
    begin
        if TopCustomerListUpdatedRecently(LastCustomerLedgerEntryNo) then
            exit;
        if TaskScheduler.CanCreateTask() then
            TASKSCHEDULER.CreateTask(CODEUNIT::"Top Customers By Sales Job", 0, true, CompanyName, 0DT);
    end;

    [Scope('OnPrem')]
    procedure TopCustomerListUpdatedRecently(var LastCustomerLedgerEntryNo: Integer): Boolean
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        LastBufferUpdateDateTime: DateTime;
        TwelveHourDuration: Duration;
        ZeroDayTime: DateTime;
    begin
        if TopCustomersBySalesBuffer.FindFirst() then begin
            LastBufferUpdateDateTime := TopCustomersBySalesBuffer.DateTimeUpdated;
            ZeroDayTime := 0DT;
            TwelveHourDuration := 43200000;
            LastCustomerLedgerEntryNo := TopCustomersBySalesBuffer.LastCustLedgerEntryNo;
            if LastBufferUpdateDateTime = ZeroDayTime then
                exit(false);
            if CurrentDateTime - LastBufferUpdateDateTime < TwelveHourDuration then
                exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Chart Management", 'OnUpdateChartSafe', '', false, false)]
    local procedure HandleUpdateChartSafe(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option)
    begin
        UpdateChart(ChartDefinition, BusinessChartBuffer, Period);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateChartDefinitionTable()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChartDescription(ChartDefinition: Record "Chart Definition"; var ChartDescription: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDataPointClicked(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPeriodLength(ChartDefinition: Record "Chart Definition"; PeriodLength: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateChart(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateNextPrevious(var ChartDefinition: Record "Chart Definition"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateStatusText(ChartDefinition: Record "Chart Definition"; BusinessChartBuffer: Record "Business Chart Buffer"; var StatusText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnUpdateChartSafe(var ChartDefinition: Record "Chart Definition"; var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Option)
    begin
    end;
}

