// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Entity;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System;

codeunit 5488 "Graph Mgt - Reports"
{

    trigger OnRun()
    begin
    end;

    var
        BalanceColumnNameTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        NetChangeColumnNameTxt: Label 'M-NETCHANG', Comment = 'Max 10 char';
        RecordNotProvidedErr: Label 'A record must be provided for this report API.';
        HeaderLineTypeTxt: Label 'header', Locked = true;
        DetailLineTypeTxt: Label 'detail', Locked = true;
        FooterLineTypeTxt: Label 'total', Locked = true;
        SpacerLineTypeTxt: Label 'spacer', Locked = true;

    local procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        exit(CopyStr(DelChr(Format(Amount, 0, FormatStr(1)), '<', ' '), 1, 30));
    end;

    procedure SetUpTrialBalanceAPIData(var TrialBalanceEntityBuffer: Record "Trial Balance Entity Buffer")
    var
        GLAccount: Record "G/L Account";
        NewTrialBalanceEntityBuffer: Record "Trial Balance Entity Buffer";
        DateFilter: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUpTrialBalanceAPIData(TrialBalanceEntityBuffer, IsHandled);
        if IsHandled then
            exit;

        DateFilter := StrSubstNo('%1', DelChr(TrialBalanceEntityBuffer.GetFilter("Date Filter"), '<>', ''''));
        if DateFilter = '' then
            DateFilter := Format(Today);

        GLAccount.SetFilter("Date Filter", DateFilter);
        if GLAccount.FindSet() then begin
            repeat
                GLAccount.CalcFields("Debit Amount", "Balance at Date");
                GLAccount.CalcFields("Credit Amount", "Balance at Date");
                TrialBalanceEntityBuffer.Init();
                TrialBalanceEntityBuffer."No." := GLAccount."No.";
                TrialBalanceEntityBuffer.Name := GLAccount.Name;
                TrialBalanceEntityBuffer."Account Type" := GLAccount."Account Type";
                TrialBalanceEntityBuffer."Account Id" := GLAccount.SystemId;
                if GLAccount."Account Type" in
                   [GLAccount."Account Type"::Posting]
                then begin
                    TrialBalanceEntityBuffer."Total Debit" := TransformAmount(GLAccount."Debit Amount");
                    TrialBalanceEntityBuffer."Total Credit" := TransformAmount(GLAccount."Credit Amount");
                    if GLAccount."Balance at Date" < 0 then begin
                        TrialBalanceEntityBuffer."Balance at Date Credit" := TransformAmount(GLAccount."Balance at Date");
                        TrialBalanceEntityBuffer."Balance at Date Debit" := FormatAmount(0.0);
                    end else begin
                        TrialBalanceEntityBuffer."Balance at Date Debit" := TransformAmount(GLAccount."Balance at Date");
                        TrialBalanceEntityBuffer."Balance at Date Credit" := FormatAmount(0.0);
                    end;
                end;
                TrialBalanceEntityBuffer."Date Filter" := GetDateRangeMax(DateFilter);
                TrialBalanceEntityBuffer.Insert();
            until GLAccount.Next() = 0;
            NewTrialBalanceEntityBuffer.TransferFields(TrialBalanceEntityBuffer);
            TrialBalanceEntityBuffer.Copy(NewTrialBalanceEntityBuffer);
        end;
    end;

    local procedure SetUpAccountScheduleBaseAPIData(var BalanceSheetBuffer: Record "Balance Sheet Buffer"; var AccScheduleLineEntity: Record "Acc. Schedule Line Entity"; ReportType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings"; DateFilter: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        TempColumnLayout: Record "Column Layout" temporary;
        FinancialReport: Record "Financial Report";
        AccSchedName: Record "Acc. Schedule Name";
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
        MatrixMgt: Codeunit "Matrix Management";
        CurrentFinRepName: Code[10];
        CurrentSchedName: Code[10];
        CurrentColumnName: Code[10];
        ColumnNo: Integer;
        DummyColumnOffset: Integer;
        ColumnValues: array[12] of Decimal;
        DummyUseAmtsInAddCurr: Boolean;
    begin
        GeneralLedgerSetup.Get();
        case ReportType of
            ReportType::"Balance Sheet":
                begin
                    GeneralLedgerSetup.TestField("Fin. Rep. for Balance Sheet");
                    CurrentFinRepName := GeneralLedgerSetup."Fin. Rep. for Balance Sheet";
                    FinancialReport.Get(CurrentFinRepName);
                    CurrentSchedName := FinancialReport."Financial Report Row Group";
                    CurrentColumnName := BalanceColumnNameTxt;
                end;
            ReportType::"CashFlow Statement":
                begin
                    GeneralLedgerSetup.TestField("Fin. Rep. for Cash Flow Stmt");
                    CurrentFinRepName := GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt";
                    FinancialReport.Get(CurrentFinRepName);
                    CurrentSchedName := FinancialReport."Financial Report Row Group";
                    CurrentColumnName := NetChangeColumnNameTxt;
                end;
            ReportType::"Income Statement":
                begin
                    GeneralLedgerSetup.TestField("Fin. Rep. for Income Stmt.");
                    CurrentFinRepName := GeneralLedgerSetup."Fin. Rep. for Income Stmt.";
                    FinancialReport.Get(CurrentFinRepName);
                    CurrentSchedName := FinancialReport."Financial Report Row Group";
                    CurrentColumnName := NetChangeColumnNameTxt;
                end;
            ReportType::"Retained Earnings":
                begin
                    GeneralLedgerSetup.TestField("Fin. Rep. for Retained Earn.");
                    CurrentFinRepName := GeneralLedgerSetup."Fin. Rep. for Retained Earn.";
                    FinancialReport.Get(CurrentFinRepName);
                    CurrentSchedName := FinancialReport."Financial Report Row Group";
                    CurrentColumnName := NetChangeColumnNameTxt;
                end;
        end;

        if DateFilter = '' then
            DateFilter := Format(Today);

        AccScheduleLine.SetFilter("Date Filter", DateFilter);
        AccScheduleLine.SetRange("Schedule Name", CurrentSchedName);
        if AccScheduleLine.FindSet() then begin
            AccSchedManagement.CopyColumnsToTemp(CurrentColumnName, TempColumnLayout);
            AccSchedManagement.OpenSchedule(CurrentSchedName, AccScheduleLine);
            AccSchedManagement.OpenColumns(CurrentColumnName, TempColumnLayout);
            AccSchedManagement.CheckAnalysisView(CurrentSchedName, CurrentColumnName, true);

            if AccSchedName.Get(CurrentSchedName) then begin
                Clear(AnalysisView);
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

            DummyColumnOffset := 0;
            repeat
                ColumnNo := 0;
                if not (AccScheduleLine.Totaling = '') and TempColumnLayout.FindSet() then
                    repeat
                        Evaluate(AccScheduleLineEntity."Net Change", DelChr(Format(0.0, 15, FormatStr(1)), '<', ' '));
                        ColumnNo := ColumnNo + 1;
                        if (ColumnNo > DummyColumnOffset) and (ColumnNo - DummyColumnOffset <= ArrayLen(ColumnValues)) then
                            ColumnValues[ColumnNo - DummyColumnOffset] :=
                              MatrixMgt.RoundAmount(
                                AccSchedManagement.CalcCell(AccScheduleLine, TempColumnLayout, DummyUseAmtsInAddCurr),
                                TempColumnLayout."Rounding Factor")
                    until TempColumnLayout.Next() = 0;

                case ReportType of
                    ReportType::"Balance Sheet":
                        begin
                            BalanceSheetBuffer.Init();
                            BalanceSheetBuffer.Id := AccScheduleLine.SystemId;
                            BalanceSheetBuffer."Line No." := AccScheduleLine."Line No.";
                            BalanceSheetBuffer.Description := AccScheduleLine.Description;
                            if not (AccScheduleLine.Totaling = '') and TempColumnLayout.FindSet() then
                                Evaluate(BalanceSheetBuffer.Balance, DelChr(Format(ColumnValues[1], 15, FormatStr(ColumnNo)), '<', ' '));
                            Evaluate(BalanceSheetBuffer."Date Filter", DateFilter);
                            if (AccScheduleLine.Description = '') and (AccScheduleLine.Totaling = '') then
                                BalanceSheetBuffer."Line Type" := SpacerLineTypeTxt
                            else
                                if AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::"Posting Accounts" then begin
                                    if AccScheduleLine.Bold then
                                        BalanceSheetBuffer."Line Type" := HeaderLineTypeTxt
                                    else
                                        BalanceSheetBuffer."Line Type" := DetailLineTypeTxt
                                end else
                                    BalanceSheetBuffer."Line Type" := FooterLineTypeTxt;
                            BalanceSheetBuffer.Indentation := AccScheduleLine.Indentation;
                            BalanceSheetBuffer.Insert();
                        end;
                    ReportType::"Income Statement",
                    ReportType::"CashFlow Statement",
                    ReportType::"Retained Earnings":
                        begin
                            AccScheduleLineEntity.Init();
                            AccScheduleLineEntity.Id := AccScheduleLine.SystemId;
                            AccScheduleLineEntity."Line No." := AccScheduleLine."Line No.";
                            AccScheduleLineEntity.Description := AccScheduleLine.Description;
                            if not (AccScheduleLine.Totaling = '') and TempColumnLayout.FindSet() then
                                Evaluate(AccScheduleLineEntity."Net Change", DelChr(Format(ColumnValues[1], 15, FormatStr(ColumnNo)), '<', ' '));
                            AccScheduleLineEntity."Date Filter" := GetDateRangeMax(DateFilter);
                            if ReportType = ReportType::"Income Statement" then
                                AccScheduleLineEntity.SetFilter("Date Filter", DateFilter);
                            if (AccScheduleLine.Description = '') and (AccScheduleLine.Totaling = '') then
                                AccScheduleLineEntity."Line Type" := SpacerLineTypeTxt
                            else
                                if AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::"Posting Accounts" then begin
                                    if AccScheduleLine.Bold then
                                        AccScheduleLineEntity."Line Type" := HeaderLineTypeTxt
                                    else
                                        AccScheduleLineEntity."Line Type" := DetailLineTypeTxt
                                end else
                                    AccScheduleLineEntity."Line Type" := FooterLineTypeTxt;
                            AccScheduleLineEntity.Indentation := AccScheduleLine.Indentation;
                            AccScheduleLineEntity.Insert();
                        end;
                end;
                AccSchedManagement.ForceRecalculate(false);
            until AccScheduleLine.Next() = 0;
        end;
    end;

    procedure SetUpBalanceSheetAPIData(var BalanceSheetBuffer: Record "Balance Sheet Buffer")
    var
        TempAccScheduleLineEntity: Record "Acc. Schedule Line Entity" temporary;
        ReportAPIType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings";
        DateFilter: Text;
    begin
        Evaluate(DateFilter, BalanceSheetBuffer.GetFilter("Date Filter"));
        if DateFilter = '' then
            DateFilter := Format(Today);

        SetUpAccountScheduleBaseAPIData(BalanceSheetBuffer, TempAccScheduleLineEntity,
          ReportAPIType::"Balance Sheet", DateFilter);
    end;

    procedure SetUpAccountScheduleBaseAPIDataWrapper(var AccScheduleLineEntity: Record "Acc. Schedule Line Entity"; ReportType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings")
    var
        TempBalanceSheetBuffer: Record "Balance Sheet Buffer" temporary;
        DateFilter: Text;
    begin
        DateFilter := StrSubstNo('%1', DelChr(AccScheduleLineEntity.GetFilter("Date Filter"), '<>', ''''));
        if DateFilter = '' then
            DateFilter := Format(DMY2Date(1, 1, Date2DMY(Today, 3))) + '..' + Format(Today);

        SetUpAccountScheduleBaseAPIData(TempBalanceSheetBuffer,
          AccScheduleLineEntity, ReportType, DateFilter);
    end;

    procedure SetUpAgedReportAPIData(var AgedReportEntity: Record "Aged Report Entity"; ReportType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DummyGuid: Guid;
        PeriodLengthFilter: Text[10];
        PeriodStartDate: Date;
        DisplayOrder: Integer;
    begin
        GeneralLedgerSetup.Get();
        DisplayOrder := 1;
        case ReportType of
            ReportType::"Aged Accounts Receivable":
                if Customer.FindSet() then
                    repeat
                        CustLedgerEntry.Reset();
                        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                        CustLedgerEntry.SetRange(Open, true);

                        AgedReportEntity.Init();
                        SetPeriodLengthAndStartDateOnAgedRep(AgedReportEntity);
                        if not CustLedgerEntry.IsEmpty() then
                            GetAgedAmounts(AgedReportEntity, Customer);

                        if IsNullGuid(Customer.SystemId) then
                            AgedReportEntity.AccountId := CreateGuid()
                        else
                            AgedReportEntity.AccountId := Customer.SystemId;

                        AgedReportEntity."No." := Customer."No.";
                        AgedReportEntity.Name := Customer.Name;
                        AgedReportEntity."Currency Code" := Customer."Currency Code";
                        if AgedReportEntity."Currency Code" = '' then
                            AgedReportEntity."Currency Code" := GeneralLedgerSetup."LCY Code";
                        if PeriodLengthFilter = '' then
                            PeriodLengthFilter := AgedReportEntity."Period Length";
                        PeriodStartDate := AgedReportEntity."Period Start Date";
                        AgedReportEntity."Display Order" := DisplayOrder;
                        DisplayOrder += 1;
                        if AgedReportEntity.Insert() then;
                    until Customer.Next() = 0;
            ReportType::"Aged Accounts Payable":
                if Vendor.FindSet() then
                    repeat
                        VendorLedgerEntry.Reset();
                        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
                        VendorLedgerEntry.SetRange(Open, true);
                        AgedReportEntity.Init();
                        if not VendorLedgerEntry.IsEmpty() then
                            GetAgedAmounts(AgedReportEntity, Vendor)
                        else
                            SetPeriodLengthAndStartDateOnAgedRep(AgedReportEntity);

                        if IsNullGuid(Vendor.SystemId) then
                            AgedReportEntity.AccountId := CreateGuid()
                        else
                            AgedReportEntity.AccountId := Vendor.SystemId;

                        AgedReportEntity."No." := Vendor."No.";
                        AgedReportEntity.Name := Vendor.Name;
                        AgedReportEntity."Currency Code" := Vendor."Currency Code";
                        if PeriodLengthFilter = '' then
                            PeriodLengthFilter := AgedReportEntity."Period Length";
                        PeriodStartDate := AgedReportEntity."Period Start Date";
                        AgedReportEntity."Display Order" := DisplayOrder;
                        DisplayOrder += 1;
                        if AgedReportEntity.Insert() then;
                    until Vendor.Next() = 0;
        end;

        AgedReportEntity.Init();
        AgedReportEntity.AccountId := DummyGuid;
        AgedReportEntity.Name := 'Total';
        AgedReportEntity.CalcSums(Before);
        AgedReportEntity.Before := AgedReportEntity.Before;
        AgedReportEntity.CalcSums("Period 1");
        AgedReportEntity."Period 1" := AgedReportEntity."Period 1";
        AgedReportEntity.CalcSums("Period 2");
        AgedReportEntity."Period 2" := AgedReportEntity."Period 2";
        AgedReportEntity.CalcSums("Period 3");
        AgedReportEntity."Period 3" := AgedReportEntity."Period 3";
        AgedReportEntity.CalcSums(After);
        AgedReportEntity.After := AgedReportEntity.After;
        AgedReportEntity.CalcSums(Balance);
        AgedReportEntity.Balance := AgedReportEntity.Balance;
        AgedReportEntity."Period Length" := Format(PeriodLengthFilter);
        AgedReportEntity."Period Start Date" := PeriodStartDate;
        AgedReportEntity."Display Order" := DisplayOrder;
        DisplayOrder += 1;
        if AgedReportEntity.Insert() then;
    end;

    local procedure SetPeriodLengthAndStartDateOnAgedRep(var AgedReportEntity: Record "Aged Report Entity")
    var
        PeriodLength: DateFormula;
        PeriodStartDate: array[5] of Date;
        PeriodStartFilter: Text;
        PeriodLengthFilter: Text[10];
        FilterPeriodStart: Date;
        I: Integer;
    begin
        PeriodStartFilter := Format(AgedReportEntity.GetFilter("Period Start Date"));
        PeriodLengthFilter := Format(AgedReportEntity.GetFilter("Period Length"));

        if PeriodStartFilter = '' then
            AgedReportEntity."Period Start Date" := Today
        else begin
            Evaluate(FilterPeriodStart, PeriodStartFilter);
            AgedReportEntity."Period Start Date" := FilterPeriodStart;
        end;

        if PeriodLengthFilter = '' then
            Evaluate(PeriodLengthFilter, '<30D>');

        Evaluate(PeriodLength, '<->' + Format(PeriodLengthFilter));
        AgedReportEntity."Period Length" := DelChr(Format(PeriodLengthFilter), '<>', '<>');

        PeriodStartDate[1] := DMY2Date(31, 12, 9999);
        PeriodStartDate[2] := AgedReportEntity."Period Start Date";

        for I := 3 to 4 do
            PeriodStartDate[I] := CalcDate(PeriodLength, PeriodStartDate[I - 1]);
        PeriodStartDate[5] := DMY2Date(1, 1, 1753);

        AgedReportEntity."Period 1 Label" := Format(PeriodStartDate[3]) + '-' + Format(PeriodStartDate[2]);
        AgedReportEntity."Period 2 Label" := Format(PeriodStartDate[4]) + '-' + Format(PeriodStartDate[3]);
        AgedReportEntity."Period 3 Label" := '-' + Format(PeriodStartDate[4]);
    end;

    local procedure GetAgedAmounts(var AgedReportEntity: Record "Aged Report Entity"; CurrentAccount: Variant)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecRef: RecordRef;
        PeriodLength: DateFormula;
        PeriodStartDate: array[5] of Date;
        FilterPeriodStart: Date;
        PeriodStartFilter: Text;
        PeriodLengthFilter: Text[10];
        I: Integer;
        LineTotalAmountDue: Decimal;
        IsVendor: Boolean;
    begin
        PeriodStartFilter := Format(AgedReportEntity.GetFilter("Period Start Date"));
        PeriodLengthFilter := Format(AgedReportEntity.GetFilter("Period Length"));
        if not CurrentAccount.IsRecord then
            Error(RecordNotProvidedErr);
        RecRef.GetTable(CurrentAccount);

        if PeriodStartFilter = '' then
            AgedReportEntity."Period Start Date" := Today
        else begin
            Evaluate(FilterPeriodStart, PeriodStartFilter);
            AgedReportEntity."Period Start Date" := FilterPeriodStart;
        end;

        if PeriodLengthFilter = '' then
            Evaluate(PeriodLengthFilter, '<30D>');

        Evaluate(PeriodLength, '<->' + Format(PeriodLengthFilter));
        AgedReportEntity."Period Length" := DelChr(Format(PeriodLengthFilter), '<>', '<>');

        PeriodStartDate[1] := DMY2Date(31, 12, 9999);
        PeriodStartDate[2] := AgedReportEntity."Period Start Date";

        for I := 3 to 4 do
            PeriodStartDate[I] := CalcDate(PeriodLength, PeriodStartDate[I - 1]);
        PeriodStartDate[5] := DMY2Date(1, 1, 1753);

        LineTotalAmountDue := 0;
        for I := 1 to 4 do
            case RecRef.Number of
                DATABASE::Customer:
                    begin
                        RecRef.SetTable(Customer);
                        DetailedCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date");
                        DetailedCustLedgEntry.SetRange("Customer No.", Customer."No.");
                        DetailedCustLedgEntry.SetRange("Initial Entry Due Date", PeriodStartDate[I + 1], PeriodStartDate[I] - 1);

                        if DetailedCustLedgEntry.FindFirst() then
                            CalculateLineTotalAmount(AgedReportEntity, LineTotalAmountDue, DetailedCustLedgEntry, I);
                    end;
                DATABASE::Vendor:
                    begin
                        RecRef.SetTable(Vendor);
                        IsVendor := true;
                        DetailedVendorLedgEntry.SetCurrentKey("Vendor No.", "Initial Entry Due Date");
                        DetailedVendorLedgEntry.SetRange("Vendor No.", Vendor."No.");
                        DetailedVendorLedgEntry.SetRange("Initial Entry Due Date", PeriodStartDate[I + 1], PeriodStartDate[I] - 1);

                        if DetailedVendorLedgEntry.FindFirst() then
                            CalculateLineTotalAmount(AgedReportEntity, LineTotalAmountDue, DetailedVendorLedgEntry, I);
                    end;
            end;

        if IsVendor then
            LineTotalAmountDue := -LineTotalAmountDue;
        AgedReportEntity.Balance := LineTotalAmountDue;
    end;

    local procedure CalculateLineTotalAmount(var AgedReportEntity: Record "Aged Report Entity"; var LineTotalAmountDue: Decimal; DetailLedgEntryVariant: Variant; PeriodCount: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecRef: RecordRef;
    begin
        if not DetailLedgEntryVariant.IsRecord then
            Error(RecordNotProvidedErr);
        RecRef.GetTable(DetailLedgEntryVariant);

        case RecRef.Number of
            DATABASE::"Detailed Cust. Ledg. Entry":
                begin
                    RecRef.SetTable(DetailedCustLedgEntry);
                    DetailedCustLedgEntry.CalcSums("Amount (LCY)");
                    case PeriodCount of
                        4:
                            AgedReportEntity."Period 3" := DetailedCustLedgEntry."Amount (LCY)";
                        3:
                            AgedReportEntity."Period 2" := DetailedCustLedgEntry."Amount (LCY)";
                        2:
                            AgedReportEntity."Period 1" := DetailedCustLedgEntry."Amount (LCY)";
                        1:
                            AgedReportEntity.Before := DetailedCustLedgEntry."Amount (LCY)";
                    end;
                    LineTotalAmountDue := LineTotalAmountDue + DetailedCustLedgEntry."Amount (LCY)";
                end;
            DATABASE::"Detailed Vendor Ledg. Entry":
                begin
                    RecRef.SetTable(DetailedVendorLedgEntry);
                    DetailedVendorLedgEntry.CalcSums("Amount (LCY)");
                    case PeriodCount of
                        4:
                            AgedReportEntity."Period 3" := -DetailedVendorLedgEntry."Amount (LCY)";
                        3:
                            AgedReportEntity."Period 2" := -DetailedVendorLedgEntry."Amount (LCY)";
                        2:
                            AgedReportEntity."Period 1" := -DetailedVendorLedgEntry."Amount (LCY)";
                        1:
                            AgedReportEntity.Before := -DetailedVendorLedgEntry."Amount (LCY)";
                    end;
                    LineTotalAmountDue := LineTotalAmountDue + DetailedVendorLedgEntry."Amount (LCY)";
                end;
        end;
    end;

    local procedure FormatStr(ColumnNo: Integer): Text
    var
        ColumnLayoutArr: array[12] of Record "Column Layout";
        MatrixMgt: Codeunit "Matrix Management";
        DummyUseAmtsInAddCurr: Boolean;
    begin
        exit(MatrixMgt.FormatRoundingFactor(ColumnLayoutArr[ColumnNo]."Rounding Factor", DummyUseAmtsInAddCurr));
    end;

    local procedure GetDateRangeMax(DateFilter: Text) RangeMax: Date
    var
        RegularExpression: DotNet Regex;
        RegExMatches: DotNet MatchCollection;
        Match: DotNet Match;
        TempDate: Date;
    begin
        RegularExpression := RegularExpression.Regex('(\d{1,2})\/(\d{1,2})\/(\d{2})');
        RegExMatches := RegularExpression.Matches(DateFilter);

        if RegExMatches.Count <= 0 then begin
            RangeMax := Today;
            exit;
        end;

        foreach Match in RegExMatches do begin
            Evaluate(TempDate, Match.Value);
            if TempDate > RangeMax then
                RangeMax := TempDate;
        end;
    end;

    local procedure TransformAmount(Amount: Decimal) NewAmount: Text[30]
    begin
        if Amount < 0 then
            NewAmount := FormatAmount(Amount * -1)
        else
            NewAmount := FormatAmount(Amount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpTrialBalanceAPIData(var TrialBalanceEntityBuffer: Record "Trial Balance Entity Buffer"; var IsHandled: Boolean)
    begin
    end;
}

