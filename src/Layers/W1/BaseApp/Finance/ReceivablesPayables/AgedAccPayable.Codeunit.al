// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Purchases.Payables;
using Microsoft.Utilities;
using System.Visualization;

codeunit 764 "Aged Acc. Payable"
{

    trigger OnRun()
    begin
    end;

    var
        ChartDescriptionMsg: Label 'Shows pending payment amounts to vendors summed for a period that you select.\\The first column shows the amount on pending payments that are not past the due date. The following column or columns show overdue amounts within the selected period from the payment due date. The chart shows overdue payment amounts going back up to five years from today''s date depending on the period that you select.';
        ChartPerVendorDescriptionMsg: Label 'Shows pending payment amount to the vendor summed for a period that you select.\The first column shows the amount on pending payments that are not past the due date. The following column or columns show overdue amounts within the selected period from the payment due date. The chart shows overdue payment amounts going back up to five years from today''s date depending on the period that you select.';

    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer"; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    var
        PeriodIndex: Integer;
        PeriodLength: Text[1];
        NoOfPeriods: Integer;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.SetXAxis(OverDueText(), BusChartBuf."Data Type"::String);
        BusChartBuf.AddDecimalMeasure(AmountText(), 1, BusChartBuf."Chart Type"::Column);

        InitParameters(BusChartBuf, PeriodLength, NoOfPeriods, TempEntryNoAmountBuf);
        CalculateAgedAccPayable(
          BusChartBuf."Period Filter Start Date", PeriodLength, NoOfPeriods,
          TempEntryNoAmountBuf);

        if TempEntryNoAmountBuf.FindSet() then
            repeat
                PeriodIndex := TempEntryNoAmountBuf."Entry No.";
                BusChartBuf.AddColumn(FormatColumnName(PeriodIndex, PeriodLength, NoOfPeriods, BusChartBuf."Period Length"));
                BusChartBuf.SetValueByIndex(0, PeriodIndex, RoundAmount(TempEntryNoAmountBuf.Amount));
            until TempEntryNoAmountBuf.Next() = 0
    end;

    [Scope('OnPrem')]
    procedure UpdateDataPerVendor(var BusChartBuf: Record "Business Chart Buffer"; VendorNo: Code[20]; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    var
        PeriodIndex: Integer;
        PeriodLength: Text[1];
        NoOfPeriods: Integer;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.SetXAxis(OverDueText(), BusChartBuf."Data Type"::String);
        BusChartBuf.AddDecimalMeasure(AmountText(), 1, BusChartBuf."Chart Type"::Column);

        InitParameters(BusChartBuf, PeriodLength, NoOfPeriods, TempEntryNoAmountBuf);
        CalculateAgedAccPayablePerVendor(
          VendorNo, '', BusChartBuf."Period Filter Start Date", PeriodLength, NoOfPeriods,
          TempEntryNoAmountBuf);

        if TempEntryNoAmountBuf.FindSet() then
            repeat
                PeriodIndex := TempEntryNoAmountBuf."Entry No.";
                BusChartBuf.AddColumn(FormatColumnName(PeriodIndex, PeriodLength, NoOfPeriods, BusChartBuf."Period Length"));
                BusChartBuf.SetValueByIndex(0, PeriodIndex, RoundAmount(TempEntryNoAmountBuf.Amount));
            until TempEntryNoAmountBuf.Next() = 0
    end;

    local procedure CalculateAgedAccPayable(StartDate: Date; PeriodLength: Text[1]; NoOfPeriods: Integer; var TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        RemainingAmountLCY: Decimal;
        EndDate: Date;
        Index: Integer;
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
        OnCalculateAgedAccPayableOnAfterFilterVendLedgEntry(VendLedgEntry);

        for Index := 0 to NoOfPeriods - 1 do begin
            RemainingAmountLCY := 0;
            VendLedgEntry.SetFilter(
              "Due Date",
              DateFilterByAge(Index, StartDate, PeriodLength, NoOfPeriods, EndDate));
            if VendLedgEntry.FindSet() then
                repeat
                    RemainingAmountLCY += VendLedgEntry."Remaining Amt. (LCY)";
                until VendLedgEntry.Next() = 0;

            InsertAmountBuffer(Index, '', -RemainingAmountLCY, StartDate, EndDate, TempEntryNoAmountBuffer)
        end;
    end;

    local procedure CalculateAgedAccPayablePerVendor(VendorNo: Code[20]; VendorGroupCode: Code[20]; StartDate: Date; PeriodLength: Text[1]; NoOfPeriods: Integer; var TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary)
    var
        VendLedgEntryRemainAmt: Query "Vend. Ledg. Entry Remain. Amt.";
        RemainingAmountLCY: Decimal;
        EndDate: Date;
        Index: Integer;
    begin
        if VendorNo <> '' then
            VendLedgEntryRemainAmt.SetRange(Vendor_No, VendorNo);
        if VendorGroupCode <> '' then
            VendLedgEntryRemainAmt.SetRange(Vendor_Posting_Group, VendorGroupCode);
        VendLedgEntryRemainAmt.SetRange(IsOpen, true);

        for Index := 0 to NoOfPeriods - 1 do begin
            RemainingAmountLCY := 0;
            VendLedgEntryRemainAmt.SetFilter(
              Due_Date,
              DateFilterByAge(Index, StartDate, PeriodLength, NoOfPeriods, EndDate));
            VendLedgEntryRemainAmt.Open();
            if VendLedgEntryRemainAmt.Read() then
                RemainingAmountLCY := VendLedgEntryRemainAmt.Sum_Remaining_Amt_LCY;

            InsertAmountBuffer(Index, VendorGroupCode, RemainingAmountLCY, StartDate, EndDate, TempEntryNoAmountBuffer)
        end;
    end;

    local procedure DateFilterByAge(Index: Integer; var StartDate: Date; PeriodLength: Text[1]; NoOfPeriods: Integer; var EndDate: Date): Text
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        exit(AgedAccReceivable.DateFilterByAge(Index, StartDate, PeriodLength, NoOfPeriods, EndDate));
    end;

    local procedure InsertAmountBuffer(Index: Integer; BussUnitCode: Code[20]; AmountLCY: Decimal; StartDate: Date; EndDate: Date; var TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary)
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        AgedAccReceivable.InsertAmountBuffer(
          Index, BussUnitCode, AmountLCY, StartDate, EndDate, TempEntryNoAmountBuffer);
    end;

    local procedure InitParameters(BusChartBuf: Record "Business Chart Buffer"; var PeriodLength: Text[1]; var NoOfPeriods: Integer; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        AgedAccReceivable.InitParameters(BusChartBuf, PeriodLength, NoOfPeriods, TempEntryNoAmountBuf);
    end;

    local procedure FormatColumnName(Index: Integer; PeriodLength: Text[1]; NoOfColumns: Integer; Period: Option): Text
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        exit(AgedAccReceivable.FormatColumnName(Index, PeriodLength, NoOfColumns, Period));
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer"; VendorNo: Code[20]; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    var
        MeasureName: Text;
        VendorGroupCode: Code[10];
    begin
        if VendorNo <> '' then
            VendorGroupCode := ''
        else begin
            MeasureName := BusChartBuf.GetMeasureName(BusChartBuf."Drill-Down Measure Index");
            VendorGroupCode := CopyStr(MeasureName, 1, MaxStrLen(VendorGroupCode));
        end;
        if TempEntryNoAmountBuf.Get('', BusChartBuf."Drill-Down X Index") then
            DrillDownVendLedgEntries(VendorNo, TempEntryNoAmountBuf."Start Date", TempEntryNoAmountBuf."End Date");
    end;

    procedure DrillDownByGroup(var BusChartBuf: Record "Business Chart Buffer"; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    begin
        DrillDown(BusChartBuf, '', TempEntryNoAmountBuf);
    end;

    local procedure DrillDownVendLedgEntries(VendorNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        if VendorNo <> '' then
            VendLedgEntry.SetRange("Vendor No.", VendorNo);
        if EndDate = 0D then
            VendLedgEntry.SetFilter("Due Date", '>=%1', StartDate)
        else
            VendLedgEntry.SetRange("Due Date", StartDate, EndDate);
        VendLedgEntry.SetRange(Open, true);
        if VendLedgEntry.IsEmpty() then
            exit;
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
    end;

    procedure Description(PerVendor: Boolean): Text
    begin
        if PerVendor then
            exit(ChartPerVendorDescriptionMsg);
        exit(ChartDescriptionMsg);
    end;

    procedure UpdateStatusText(BusChartBuf: Record "Business Chart Buffer"): Text
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        exit(AgedAccReceivable.UpdateStatusText(BusChartBuf));
    end;

    procedure SaveSettings(BusChartBuf: Record "Business Chart Buffer")
    var
        BusChartUserSetup: Record "Business Chart User Setup";
    begin
        BusChartUserSetup."Period Length" := BusChartBuf."Period Length";
        BusChartUserSetup.SaveSetupCU(BusChartUserSetup, CODEUNIT::"Aged Acc. Payable");
    end;

    local procedure RoundAmount(Amount: Decimal): Decimal
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        exit(AgedAccReceivable.RoundAmount(Amount));
    end;

    local procedure OverDueText(): Text
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        exit(AgedAccReceivable.OverDueText());
    end;

    local procedure AmountText(): Text
    var
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
    begin
        exit(AgedAccReceivable.AmountText());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateAgedAccPayableOnAfterFilterVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

