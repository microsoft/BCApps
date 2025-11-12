// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Environment;

page 198 "Acc. Sched. KPI WS Dimensions"
{
    Caption = 'Account Schedule KPI WS Dimensions';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Sched. KPI Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Number; Number)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the number of the dimension.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the date on which the KPI figures are calculated.';
                }
                field("Closed Period"; Rec."Closed Period")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies if the accounting period is closed or locked. KPI data for periods that are not closed or locked will be forecasted values from the general ledger budget.';
                }
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of the account schedule that the KPI web service is based on.';
                }
                field("KPI Code"; Rec."KPI Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a code for the account-schedule KPI web service.';
                }
                field("KPI Name"; Rec."KPI Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a name of the account-schedule KPI web service.';
                }
                field("Net Change Actual"; Rec."Net Change Actual")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies changes in the actual general ledger amount, for closed accounting periods, up until the date in the Date field.';
                }
                field("Balance at Date Actual"; Rec."Balance at Date Actual")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the actual general ledger balance, based on closed accounting periods, on the date in the Date field.';
                }
                field("Net Change Budget"; Rec."Net Change Budget")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies changes in the budgeted general ledger amount, based on the general ledger budget, up until the date in the Date field.';
                }
                field("Balance at Date Budget"; Rec."Balance at Date Budget")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the budgeted general ledger balance, based on the general ledger budget, on the date in the Date field.';
                }
                field("Net Change Actual Last Year"; Rec."Net Change Actual Last Year")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies actual changes in the general ledger amount, based on closed accounting periods, up until the date in the Date field in the previous accounting year.';
                }
                field("Balance at Date Actual Last Year"; Rec."Balance at Date Act. Last Year")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the actual general ledger balance, based on closed accounting periods, on the date in the Date field in the previous accounting year.';
                }
                field("Net Change Budget Last Year"; Rec."Net Change Budget Last Year")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies budgeted changes in the general ledger amount, based on the general ledger budget, up until the date in the Date field in the previous year.';
                }
                field("Balance at Date Budget Last Year"; Rec."Balance at Date Bud. Last Year")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the budgeted general ledger balance, based on the general ledger budget, on the date in the Date field in the previous accounting year.';
                }
                field("Net Change Forecast"; Rec."Net Change Forecast")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies forecasted changes in the general ledger amount, based on open accounting periods, up until the date in the Date field.';
                }
                field("Balance at Date Forecast"; Rec."Balance at Date Forecast")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the forecasted general ledger balance, based on open accounting periods, on the date in the Date field.';
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Number := Rec."No.";
    end;

    trigger OnOpenPage()
    var
        ViewTxt: Text;
    begin
        ViewTxt := Rec.GetView();
        Initialize();
        PrecalculateData();
        Rec.SetView(ViewTxt);
    end;

    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        TempAccScheduleLine: Record "Acc. Schedule Line" temporary;
        AccSchedKPIDimensions: Codeunit "Acc. Sched. KPI Dimensions";
        Number: Integer;

    local procedure Initialize()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        if not GuiAllowed then
            WorkDate := LogInManagement.GetDefaultWorkDate();

        SetupActiveAccSchedLines();
    end;

    local procedure SetupColumnLayout(var TempColumnLayout: Record "Column Layout" temporary)
    begin
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Net Change", TempColumnLayout."Ledger Entry Type"::Entries, false);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Balance at Date", TempColumnLayout."Ledger Entry Type"::Entries, false);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Net Change", TempColumnLayout."Ledger Entry Type"::"Budget Entries", false);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Balance at Date", TempColumnLayout."Ledger Entry Type"::"Budget Entries", false);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Net Change", TempColumnLayout."Ledger Entry Type"::Entries, true);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Balance at Date", TempColumnLayout."Ledger Entry Type"::Entries, true);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Net Change", TempColumnLayout."Ledger Entry Type"::"Budget Entries", true);
        InsertTempColumn(TempColumnLayout, TempColumnLayout."Column Type"::"Balance at Date", TempColumnLayout."Ledger Entry Type"::"Budget Entries", true);
    end;

    local procedure SetupActiveAccSchedLines()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
        LineNo: Integer;
    begin
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvLine.FindSet();
        AccScheduleLine.SetFilter(Totaling, '<>%1', '');
        repeat
            AccScheduleLine.SetRange("Schedule Name", AccSchedKPIWebSrvLine."Acc. Schedule Name");
            AccScheduleLine.FindSet();
            repeat
                LineNo += 1;
                TempAccScheduleLine := AccScheduleLine;
                TempAccScheduleLine."Line No." := LineNo;
                TempAccScheduleLine.Insert();
            until AccScheduleLine.Next() = 0;
        until AccSchedKPIWebSrvLine.Next() = 0;
    end;

    local procedure InsertTempColumn(var TempColumnLayout: Record "Column Layout" temporary; ColumnType: Enum "Column Layout Type"; EntryType: Enum "Column Layout Entry Type"; LastYear: Boolean)
    begin
        if TempColumnLayout.FindLast() then;
        TempColumnLayout.Init();
        TempColumnLayout."Line No." += 10000;
        TempColumnLayout."Column Type" := ColumnType;
        TempColumnLayout."Ledger Entry Type" := EntryType;
        if LastYear then
            Evaluate(TempColumnLayout."Comparison Date Formula", '<-1Y>');
        TempColumnLayout.Insert();
    end;

    local procedure PrecalculateData()
    var
        TempAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer" temporary;
        TempColumnLayout: Record "Column Layout" temporary;
        StartDate: Date;
        EndDate: Date;
        FromDate: Date;
        ToDate: Date;
        LastClosedDate: Date;
        C: Integer;
        NoOfPeriods: Integer;
        ForecastFromBudget: Boolean;
    begin
        SetupColumnLayout(TempColumnLayout);

        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfPeriods, StartDate, EndDate);
        LastClosedDate := AccSchedKPIWebSrvSetup.GetLastClosedAccDate();

        for C := 1 to NoOfPeriods do begin
            FromDate := AccSchedKPIWebSrvSetup.CalcNextStartDate(StartDate, C - 1);
            ToDate := AccSchedKPIWebSrvSetup.CalcNextStartDate(FromDate, 1) - 1;
            TempAccSchedKPIBuffer.Init();
            TempAccSchedKPIBuffer.Date := FromDate;
            TempAccSchedKPIBuffer."Closed Period" := (FromDate <= LastClosedDate);
            ForecastFromBudget :=
              ((AccSchedKPIWebSrvSetup."Forecasted Values Start" =
                AccSchedKPIWebSrvSetup."Forecasted Values Start"::"After Latest Closed Period") and
               not TempAccSchedKPIBuffer."Closed Period") or
              ((AccSchedKPIWebSrvSetup."Forecasted Values Start" =
                AccSchedKPIWebSrvSetup."Forecasted Values Start"::"After Current Date") and
               (TempAccSchedKPIBuffer.Date > WorkDate()));

            TempAccScheduleLine.FindSet();
            repeat
                if TempAccSchedKPIBuffer."Account Schedule Name" <> TempAccScheduleLine."Schedule Name" then begin
                    InsertAccSchedulePeriod(TempAccSchedKPIBuffer, ForecastFromBudget);
                    TempAccSchedKPIBuffer."Account Schedule Name" := TempAccScheduleLine."Schedule Name";
                end;
                TempAccSchedKPIBuffer."KPI Code" := TempAccScheduleLine."Row No.";
                TempAccSchedKPIBuffer."KPI Name" :=
                  CopyStr(TempAccScheduleLine.Description, 1, MaxStrLen(TempAccSchedKPIBuffer."KPI Name"));
                TempAccScheduleLine.SetRange(TempAccScheduleLine."Date Filter", FromDate, ToDate);
                TempAccScheduleLine.SetRange(TempAccScheduleLine."G/L Budget Filter", AccSchedKPIWebSrvSetup."G/L Budget Name");
                AccSchedKPIDimensions.GetCellDataWithDimensions(TempAccScheduleLine, TempColumnLayout, TempAccSchedKPIBuffer);
            until TempAccScheduleLine.Next() = 0;
            InsertAccSchedulePeriod(TempAccSchedKPIBuffer, ForecastFromBudget);
        end;
        Rec.Reset();
        Rec.FindFirst();
    end;

    local procedure InsertAccSchedulePeriod(var TempAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer" temporary; ForecastFromBudget: Boolean)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        TempAccSchedKPIBuffer.Reset();
        if TempAccSchedKPIBuffer.FindSet() then
            repeat
                AccScheduleLine.SetRange("Schedule Name", TempAccSchedKPIBuffer."Account Schedule Name");
                AccScheduleLine.SetRange("Row No.", TempAccSchedKPIBuffer."KPI Code");
                if AccScheduleLine.FindFirst() then;
                if AccScheduleLine.Show = "Acc. Schedule Line Show"::Yes then
                    InsertData(TempAccSchedKPIBuffer, ForecastFromBudget);
            until TempAccSchedKPIBuffer.Next() = 0;
        TempAccSchedKPIBuffer.DeleteAll();
    end;

    local procedure InsertData(AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer"; ForecastFromBudget: Boolean)
    var
        TempAccScheduleLine2: Record "Acc. Schedule Line" temporary;
    begin
        Rec.Init();
        Rec."No." += 1;
        Rec.TransferFields(AccSchedKPIBuffer, false);

        TempAccScheduleLine2.Copy(TempAccScheduleLine, true);
        TempAccScheduleLine2.SetRange(TempAccScheduleLine2."Schedule Name", AccSchedKPIBuffer."Account Schedule Name");
        TempAccScheduleLine2.SetRange(TempAccScheduleLine2."Row No.", AccSchedKPIBuffer."KPI Code");
        TempAccScheduleLine2.FindFirst();

        Rec."Net Change Actual" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Net Change Actual");
        Rec."Balance at Date Actual" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Balance at Date Actual");
        Rec."Net Change Budget" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Net Change Budget");
        Rec."Balance at Date Budget" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Balance at Date Budget");
        Rec."Net Change Actual Last Year" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Net Change Actual Last Year");
        Rec."Balance at Date Act. Last Year" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Balance at Date Act. Last Year");
        Rec."Net Change Budget Last Year" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Net Change Budget Last Year");
        Rec."Balance at Date Bud. Last Year" :=
          AccSchedKPIDimensions.PostProcessAmount(TempAccScheduleLine2, Rec."Balance at Date Bud. Last Year");

        if ForecastFromBudget then begin
            Rec."Net Change Forecast" := Rec."Net Change Budget";
            Rec."Balance at Date Forecast" := Rec."Balance at Date Budget";
        end else begin
            Rec."Net Change Forecast" := Rec."Net Change Actual";
            Rec."Balance at Date Forecast" := Rec."Balance at Date Actual";
        end;
        Rec.Insert();
    end;
}

