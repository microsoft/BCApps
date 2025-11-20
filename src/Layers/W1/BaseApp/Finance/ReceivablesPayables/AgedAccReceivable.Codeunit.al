// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.CRM.Outlook;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Visualization;

codeunit 763 "Aged Acc. Receivable"
{

    trigger OnRun()
    begin
        BackgroundUpdateDataPerCustomer();
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLSetupLoaded: Boolean;

        OverdueTxt: Label 'Overdue';
        AmountTxt: Label 'Amount';
        NotDueTxt: Label 'Not Overdue';
        OlderTxt: Label 'Older';
        StatusNonPeriodicTxt: Label 'All receivables, not overdue and overdue';
        StatusPeriodLengthTxt: Label 'Period Length: ';
        Status2WeekOverdueTxt: Label '2 weeks overdue';
        Status3MonthsOverdueTxt: Label '3 months overdue';
        Status1YearOverdueTxt: Label '1 year overdue';
        Status3YearsOverdueTxt: Label '3 years overdue';
        Status5YearsOverdueTxt: Label '5 years overdue';
        ChartDescriptionMsg: Label 'Shows customers'' pending payment amounts summed for a period that you select.\\The first column shows the amount on pending payments that are not past the due date. The following column or columns show overdue amounts within the selected period from the payment due date. The chart shows overdue payment amounts going back up to five years from today''s date depending on the period that you select.';
        ChartPerCustomerDescriptionMsg: Label 'Shows the customer''s pending payment amount summed for a period that you select.\\The first column shows the amount on pending payments that are not past the due date. The following column or columns show overdue amounts within the selected period from the payment due date. The chart shows overdue payment amounts going back up to five years from today''s date depending on the period that you select.';
        Status1MonthOverdueTxt: Label '1 month overdue';
        Status1QuarterOverdueTxt: Label '1 quarter overdue';

    local procedure BackgroundUpdateDataPerCustomer()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        CustomerNo: Code[20];
        PeriodLength: Text[1];
        NoOfPeriods: Integer;
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        RowNo: Integer;
    begin
        Params := Page.GetBackgroundParameters();
        CustomerNo := CopyStr(Params.Get('CustomerNo'), 1, MaxStrLen(CustomerNo));
        if CustomerNo = '' then
            exit;
        if not evaluate(BusinessChartBuffer."Period Filter Start Date", Params.Get('StartDate'), 9) then
            exit;
        if not evaluate(BusinessChartBuffer."Period Length", Params.Get('PeriodLength'), 9) then
            exit;

        InitParameters(BusinessChartBuffer, PeriodLength, NoOfPeriods, TempEntryNoAmountBuf);
        CalculateAgedAccReceivable(
            CustomerNo, '', BusinessChartBuffer."Period Filter Start Date", PeriodLength, NoOfPeriods,
            TempEntryNoAmountBuf);

        if TempEntryNoAmountBuf.FindSet() then
            repeat
                RowNo += 1;
                Results.Add('EntryNo¤%1' + Format(RowNo), Format(TempEntryNoAmountBuf."Entry No.", 0, 9));
                Results.Add('Amount¤%1' + Format(RowNo), Format(TempEntryNoAmountBuf.Amount, 0, 9));
                Results.Add('Amount2¤%1' + Format(RowNo), Format(TempEntryNoAmountBuf.Amount2, 0, 9));
                Results.Add('EndDate¤%1' + Format(RowNo), Format(TempEntryNoAmountBuf."End Date", 0, 9));
                Results.Add('StartDate¤%1' + Format(RowNo), Format(TempEntryNoAmountBuf."Start Date", 0, 9));
            until TempEntryNoAmountBuf.Next() = 0;

        Page.SetBackgroundTaskResult(Results);
    end;


    [Scope('OnPrem')]
    procedure UpdateDataPerCustomer(var BusChartBuf: Record "Business Chart Buffer"; CustomerNo: Code[20]; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    begin
        UpdateDataPerCustomer(BusChartBuf, CustomerNo, TempEntryNoAmountBuf, false);
    end;

    [Scope('OnPrem')]
    procedure UpdateDataPerCustomer(var BusChartBuf: Record "Business Chart Buffer"; CustomerNo: Code[20]; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary; AlreadyInitialized: Boolean)
    var
        PeriodIndex: Integer;
        PeriodLength: Text[1];
        NoOfPeriods: Integer;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.SetXAxis(OverDueText(), BusChartBuf."Data Type"::String);
        BusChartBuf.AddDecimalMeasure(AmountText(), 1, BusChartBuf."Chart Type"::Column);
        if AlreadyInitialized then
            InitParameters(BusChartBuf, PeriodLength, NoOfPeriods)
        else begin
            InitParameters(BusChartBuf, PeriodLength, NoOfPeriods, TempEntryNoAmountBuf);
            CalculateAgedAccReceivable(
                CustomerNo, '', BusChartBuf."Period Filter Start Date", PeriodLength, NoOfPeriods,
                TempEntryNoAmountBuf);
        end;
        if TempEntryNoAmountBuf.FindSet() then
            repeat
                PeriodIndex := TempEntryNoAmountBuf."Entry No.";
                BusChartBuf.AddColumn(FormatColumnName(PeriodIndex, PeriodLength, NoOfPeriods, BusChartBuf."Period Length"));
                BusChartBuf.SetValueByIndex(0, PeriodIndex, RoundAmount(TempEntryNoAmountBuf.Amount));
            until TempEntryNoAmountBuf.Next() = 0
    end;

    procedure UpdateDataPerGroup(var BusChartBuf: Record "Business Chart Buffer"; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    var
        CustPostingGroup: Record "Customer Posting Group";
        PeriodIndex: Integer;
        GroupIndex: Integer;
        PeriodLength: Text[1];
        NoOfPeriods: Integer;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.SetXAxis(OverdueTxt, BusChartBuf."Data Type"::String);

        InitParameters(BusChartBuf, PeriodLength, NoOfPeriods, TempEntryNoAmountBuf);
        CalculateAgedAccReceivablePerGroup(
          BusChartBuf."Period Filter Start Date", PeriodLength, NoOfPeriods,
          TempEntryNoAmountBuf);

        if CustPostingGroup.FindSet() then
            repeat
                BusChartBuf.AddDecimalMeasure(CustPostingGroup.Code, GroupIndex, BusChartBuf."Chart Type"::StackedColumn);

                TempEntryNoAmountBuf.Reset();
                TempEntryNoAmountBuf.SetRange("Business Unit Code", CustPostingGroup.Code);
                if TempEntryNoAmountBuf.FindSet() then
                    repeat
                        PeriodIndex := TempEntryNoAmountBuf."Entry No.";
                        if GroupIndex = 0 then
                            BusChartBuf.AddColumn(FormatColumnName(PeriodIndex, PeriodLength, NoOfPeriods, BusChartBuf."Period Length"));
                        BusChartBuf.SetValueByIndex(GroupIndex, PeriodIndex, RoundAmount(TempEntryNoAmountBuf.Amount));
                    until TempEntryNoAmountBuf.Next() = 0;
                GroupIndex += 1;
            until CustPostingGroup.Next() = 0;
        TempEntryNoAmountBuf.Reset();
    end;

    local procedure CalculateAgedAccReceivable(CustomerNo: Code[20]; CustomerGroupCode: Code[20]; StartDate: Date; PeriodLength: Text[1]; NoOfPeriods: Integer; var TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary)
    var
        CustLedgEntryRemainAmt: Query "Cust. Ledg. Entry Remain. Amt.";
        RemainingAmountLCY: Decimal;
        EndDate: Date;
        Index: Integer;
    begin
        if CustomerNo <> '' then
            CustLedgEntryRemainAmt.SetRange(Customer_No, CustomerNo);
        if CustomerGroupCode <> '' then
            CustLedgEntryRemainAmt.SetRange(Customer_Posting_Group, CustomerGroupCode);
        CustLedgEntryRemainAmt.SetRange(IsOpen, true);

        for Index := 0 to NoOfPeriods - 1 do begin
            RemainingAmountLCY := 0;
            CustLedgEntryRemainAmt.SetFilter(
              Due_Date,
              DateFilterByAge(Index, StartDate, PeriodLength, NoOfPeriods, EndDate));
            CustLedgEntryRemainAmt.Open();
            if CustLedgEntryRemainAmt.Read() then
                RemainingAmountLCY := CustLedgEntryRemainAmt.Sum_Remaining_Amt_LCY;

            InsertAmountBuffer(Index, CustomerGroupCode, RemainingAmountLCY, StartDate, EndDate, TempEntryNoAmountBuffer)
        end;
    end;

    local procedure CalculateAgedAccReceivablePerGroup(StartDate: Date; PeriodLength: Text[1]; NoOfPeriods: Integer; var TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary)
    var
        CustPostingGroup: Record "Customer Posting Group";
        TempEntryNoAmtBuf: Record "Entry No. Amount Buffer" temporary;
        CustRemainAmtByDueDate: Query "Cust. Remain. Amt. By Due Date";
        EntryNo: Integer;
        Index: Integer;
        RemainingAmountLCY: Decimal;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        CustRemainAmtByDueDate.SetRange(IsOpen, true);
        CustRemainAmtByDueDate.Open();
        while CustRemainAmtByDueDate.Read() do begin
            EntryNo += 1;
            TempEntryNoAmtBuf."Entry No." := EntryNo;
            TempEntryNoAmtBuf."Business Unit Code" := CustRemainAmtByDueDate.Customer_Posting_Group;
            TempEntryNoAmtBuf.Amount := CustRemainAmtByDueDate.Sum_Remaining_Amt_LCY;
            TempEntryNoAmtBuf."Start Date" := CustRemainAmtByDueDate.Due_Date;
            TempEntryNoAmtBuf.Insert();
        end;

        if CustPostingGroup.FindSet() then
            repeat
                PeriodStartDate := StartDate;
                TempEntryNoAmtBuf.SetRange("Business Unit Code", CustPostingGroup.Code);

                for Index := 0 to NoOfPeriods - 1 do begin
                    RemainingAmountLCY := 0;
                    TempEntryNoAmtBuf.SetFilter("Start Date", DateFilterByAge(Index, PeriodStartDate, PeriodLength, NoOfPeriods, PeriodEndDate));
                    if TempEntryNoAmtBuf.FindSet() then
                        repeat
                            RemainingAmountLCY += TempEntryNoAmtBuf.Amount;
                        until TempEntryNoAmtBuf.Next() = 0;

                    InsertAmountBuffer(Index, CustPostingGroup.Code, RemainingAmountLCY, PeriodStartDate, PeriodEndDate, TempEntryNoAmountBuffer)
                end;
            until CustPostingGroup.Next() = 0;
    end;

    procedure DateFilterByAge(Index: Integer; var StartDate: Date; PeriodLength: Text[1]; NoOfPeriods: Integer; var EndDate: Date): Text
    begin
        if Index = 0 then // First period - Not due remaining amounts
            exit(StrSubstNo('>=%1', StartDate));

        EndDate := CalcDate('<-1D>', StartDate);
        if Index = NoOfPeriods - 1 then // Last period - Older remaining amounts
            StartDate := 0D
        else
            StartDate := CalcDate(StrSubstNo('<-1%1>', PeriodLength), StartDate);

        exit(StrSubstNo('%1..%2', StartDate, EndDate));
    end;

    procedure InsertAmountBuffer(Index: Integer; BussUnitCode: Code[20]; AmountLCY: Decimal; StartDate: Date; EndDate: Date; var TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary)
    begin
        TempEntryNoAmountBuffer.Init();
        TempEntryNoAmountBuffer."Entry No." := Index;
        TempEntryNoAmountBuffer."Business Unit Code" := BussUnitCode;
        TempEntryNoAmountBuffer.Amount := AmountLCY;
        TempEntryNoAmountBuffer."Start Date" := StartDate;
        TempEntryNoAmountBuffer."End Date" := EndDate;
        TempEntryNoAmountBuffer.Insert();
    end;

    procedure InitParameters(BusChartBuf: Record "Business Chart Buffer"; var PeriodLength: Text[1]; var NoOfPeriods: Integer)
    begin
        PeriodLength := GetPeriod(BusChartBuf);
        NoOfPeriods := GetNoOfPeriods(BusChartBuf);
    end;

    procedure InitParameters(BusChartBuf: Record "Business Chart Buffer"; var PeriodLength: Text[1]; var NoOfPeriods: Integer; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    begin
        TempEntryNoAmountBuf.DeleteAll();
        PeriodLength := GetPeriod(BusChartBuf);
        NoOfPeriods := GetNoOfPeriods(BusChartBuf);
    end;

    local procedure GetPeriod(BusChartBuf: Record "Business Chart Buffer"): Text[1]
    begin
        if BusChartBuf."Period Length" = BusChartBuf."Period Length"::None then
            exit('W');
        exit(BusChartBuf.GetPeriodLength());
    end;

    local procedure GetNoOfPeriods(BusChartBuf: Record "Business Chart Buffer"): Integer
    var
        NoOfPeriods: Integer;
    begin
        NoOfPeriods := 14;
        case BusChartBuf."Period Length" of
            BusChartBuf."Period Length"::Day:
                NoOfPeriods := 16;
            BusChartBuf."Period Length"::Week,
            BusChartBuf."Period Length"::Quarter,
            BusChartBuf."Period Length"::Month:
                NoOfPeriods := 14;
            BusChartBuf."Period Length"::Year:
                NoOfPeriods := 7;
            BusChartBuf."Period Length"::None:
                NoOfPeriods := 2;
        end;
        exit(NoOfPeriods);
    end;

    procedure FormatColumnName(Index: Integer; PeriodLength: Text[1]; NoOfColumns: Integer; Period: Option): Text
    var
        BusChartBuf: Record "Business Chart Buffer";
        PeriodDateFormula: DateFormula;
    begin
        if Index = 0 then
            exit(NotDueTxt);

        if Index = NoOfColumns - 1 then begin
            if Period = BusChartBuf."Period Length"::None then
                exit(OverdueTxt);
            exit(OlderTxt);
        end;

        // Period length text localized by date formula
        Evaluate(PeriodDateFormula, StrSubstNo('<1%1>', PeriodLength));
        exit(StrSubstNo('%1%2', Index, DelChr(Format(PeriodDateFormula), '=', '1')));
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer"; CustomerNo: Code[20]; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    var
        MeasureName: Text;
        CustomerGroupCode: Code[20];
    begin
        if CustomerNo <> '' then
            CustomerGroupCode := ''
        else begin
            MeasureName := BusChartBuf.GetMeasureName(BusChartBuf."Drill-Down Measure Index");
            CustomerGroupCode := CopyStr(MeasureName, 1, MaxStrLen(CustomerGroupCode));
        end;
        if TempEntryNoAmountBuf.Get(CustomerGroupCode, BusChartBuf."Drill-Down X Index") then
            DrillDownCustLedgEntries(CustomerNo, CustomerGroupCode, TempEntryNoAmountBuf."Start Date", TempEntryNoAmountBuf."End Date");
    end;

    procedure DrillDownByGroup(var BusChartBuf: Record "Business Chart Buffer"; var TempEntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary)
    begin
        DrillDown(BusChartBuf, '', TempEntryNoAmountBuf);
    end;

    procedure DrillDownCustLedgEntries(CustomerNo: Code[20]; CustomerGroupCode: Code[20]; StartDate: Date; EndDate: Date)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        if CustomerNo <> '' then
            CustLedgEntry.SetRange("Customer No.", CustomerNo);
        if EndDate = 0D then
            CustLedgEntry.SetFilter("Due Date", '>=%1', StartDate)
        else
            CustLedgEntry.SetRange("Due Date", StartDate, EndDate);
        CustLedgEntry.SetRange(Open, true);
        if CustomerGroupCode <> '' then
            CustLedgEntry.SetRange("Customer Posting Group", CustomerGroupCode);
        if CustLedgEntry.IsEmpty() then
            exit;
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    procedure Description(PerCustomer: Boolean): Text
    begin
        if PerCustomer then
            exit(ChartPerCustomerDescriptionMsg);
        exit(ChartDescriptionMsg);
    end;

    procedure UpdateStatusText(BusChartBuf: Record "Business Chart Buffer"): Text
    var
        OfficeMgt: Codeunit "Office Management";
        StatusText: Text;
    begin
        StatusText := StatusPeriodLengthTxt + Format(BusChartBuf."Period Length");

        case BusChartBuf."Period Length" of
            BusChartBuf."Period Length"::Day:
                StatusText := StatusText + ' | ' + Status2WeekOverdueTxt;
            BusChartBuf."Period Length"::Week:
                if OfficeMgt.IsAvailable() then
                    StatusText := StatusText + ' | ' + Status1MonthOverdueTxt
                else
                    StatusText := StatusText + ' | ' + Status3MonthsOverdueTxt;
            BusChartBuf."Period Length"::Month:
                if OfficeMgt.IsAvailable() then
                    StatusText := StatusText + ' | ' + Status1QuarterOverdueTxt
                else
                    StatusText := StatusText + ' | ' + Status1YearOverdueTxt;
            BusChartBuf."Period Length"::Quarter:
                if OfficeMgt.IsAvailable() then
                    StatusText := StatusText + ' | ' + Status1YearOverdueTxt
                else
                    StatusText := StatusText + ' | ' + Status3YearsOverdueTxt;
            BusChartBuf."Period Length"::Year:
                if OfficeMgt.IsAvailable() then
                    StatusText := StatusText + ' | ' + Status3YearsOverdueTxt
                else
                    StatusText := StatusText + ' | ' + Status5YearsOverdueTxt;
            BusChartBuf."Period Length"::None:
                StatusText := StatusNonPeriodicTxt;
        end;

        exit(StatusText);
    end;

    procedure SaveSettings(BusChartBuf: Record "Business Chart Buffer")
    var
        BusChartUserSetup: Record "Business Chart User Setup";
    begin
        BusChartUserSetup."Period Length" := BusChartBuf."Period Length";
        BusChartUserSetup.SaveSetupCU(BusChartUserSetup, CODEUNIT::"Aged Acc. Receivable");
    end;

    procedure InvoicePaymentDaysAverage(CustomerNo: Code[20]): Decimal
    begin
        exit(Round(CalcInvPmtDaysAverage(CustomerNo), 1));
    end;

    local procedure CalcInvPmtDaysAverage(CustomerNo: Code[20]): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentDays: Integer;
        InvoiceCount: Integer;
    begin
        CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", Open);
        if CustomerNo <> '' then
            CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange(Open, false);
        CustLedgEntry.SetFilter("Due Date", '<>%1', 0D);
        if not CustLedgEntry.FindSet() then
            exit(0);

        repeat
            DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
            if DetailedCustLedgEntry.FindLast() then begin
                PaymentDays += DetailedCustLedgEntry."Posting Date" - CustLedgEntry."Due Date";
                InvoiceCount += 1;
            end;
        until CustLedgEntry.Next() = 0;

        if InvoiceCount = 0 then
            exit(0);

        exit(PaymentDays / InvoiceCount);
    end;

    procedure RoundAmount(Amount: Decimal): Decimal
    begin
        if not GLSetupLoaded then begin
            GeneralLedgerSetup.Get();
            GLSetupLoaded := true;
        end;

        exit(Round(Amount, GeneralLedgerSetup."Amount Rounding Precision"));
    end;

    procedure OverDueText(): Text
    begin
        exit(OverdueTxt);
    end;

    procedure AmountText(): Text
    begin
        exit(AmountTxt);
    end;
}

