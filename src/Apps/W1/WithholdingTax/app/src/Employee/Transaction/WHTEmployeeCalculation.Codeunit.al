// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;

codeunit 6790 "WHT Employee Calculation"
{
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ThresholdApplied: Boolean;

    procedure IsEmployeeWHTApplicable(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        Employee: Record Employee;
    begin
        if not IsWithholdingTaxEnabled() then
            exit(false);

        if not GetEmployeeFromJnlLine(GenJnlLine, Employee) then
            exit(false);

        if Employee."Withholding Tax Exempt" then
            exit(false);

        if GenJnlLine."Wthldg. Tax Bus. Post. Group" = '' then
            exit(false);

        if GenJnlLine."Wthldg. Tax Prod. Post. Group" = '' then
            exit(false);

        exit(true);
    end;

    procedure CalcEmployeeWHT(var GenJnlLine: Record "Gen. Journal Line"; var WHTAmount: Decimal; var WHTBaseAmount: Decimal)
    var
        Employee: Record Employee;
        WHTGroupLine: Record "Withholding Tax Group Line";
        PostingSetup: Record "Withholding Tax Posting Setup";
        CalcBase: Enum "Withholding Calculation Base";
        CalcMethod: Enum "Withholding Calculation Method";
        WHTGroupCode: Code[20];
        LineAmount: Decimal;
        CompoundBase: Decimal;
        ComponentWHT: Decimal;
        TotalWHT: Decimal;
        HasGroup: Boolean;
        IsHandled: Boolean;
    begin
        WHTAmount := 0;
        WHTBaseAmount := 0;

        OnBeforeCalcEmployeeWHT(GenJnlLine, WHTAmount, WHTBaseAmount, IsHandled);
        if IsHandled then
            exit;

        if not IsEmployeeWHTApplicable(GenJnlLine) then
            exit;

        if not GetEmployeeFromJnlLine(GenJnlLine, Employee) then
            exit;

        OnBeforeCheckCalcEmployeeWHT(GenJnlLine, Employee, WHTAmount, WHTBaseAmount);

        LineAmount := Abs(GenJnlLine.Amount);
        if LineAmount = 0 then
            exit;

        PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group");

        CalcBase := PostingSetup."Calculation Base";
        CalcMethod := PostingSetup."Calculation Method";

        // Resolve WHT Group if applicable
        HasGroup := ResolveWHTGroupComponents(GenJnlLine, WHTGroupCode);

        // Apply calculation base: gross vs net (gross-up)
        if CalcBase = CalcBase::Net then begin
            LineAmount := CalcGrossUpAmount(LineAmount, PostingSetup, WHTGroupCode, HasGroup);
            if GenJnlLine.Amount < 0 then
                GenJnlLine.Validate(Amount, -LineAmount);
        end;

        WHTBaseAmount := LineAmount;

        // Evaluate threshold
        if not EvaluateThreshold(PostingSetup, Employee."No.", GenJnlLine."Posting Date", LineAmount) then
            exit;

        // Calculate WHT
        if HasGroup then begin
            // Multi-component calculation via WHT Group
            CompoundBase := LineAmount;
            WHTGroupLine.Reset();
            WHTGroupLine.SetCurrentKey("Group Code", "Component Order");
            WHTGroupLine.SetRange("Group Code", WHTGroupCode);
            if WHTGroupLine.FindSet() then
                repeat
                    if PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group") then begin
                        CalcMethod := PostingSetup."Calculation Method";
                        CalcBase := PostingSetup."Calculation Base";
                    end;

                    ComponentWHT := CalcComponentWHT(WHTGroupLine, CompoundBase, GenJnlLine);
                    TotalWHT += ComponentWHT;

                    if CalcMethod = CalcMethod::Compound then
                        CompoundBase := CompoundBase + ComponentWHT;
                until WHTGroupLine.Next() = 0;

            WHTAmount := Round(TotalWHT);
        end else
            // Single-component calculation
            if PostingSetup."Withholding Tax %" > 0 then
                WHTAmount := Round(LineAmount * PostingSetup."Withholding Tax %" / 100);
    end;

    procedure InsertEmployeeWithholdingTaxEntry(GenJnlLine: Record "Gen. Journal Line"; WHTAmount: Decimal; WHTBaseAmount: Decimal; TransactionNo: Integer; var NextEntryNo: Integer): Integer
    var
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        PostingSetup: Record "Withholding Tax Posting Setup";
        NoSeries: Codeunit "No. Series";
        EntryNo: Integer;
    begin
        if WHTAmount = 0 then
            exit(0);

        if not PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
            exit(0);

        WithholdingTaxEntry.Init();
        EntryNo := GetNextEntryNo();
        WithholdingTaxEntry."Entry No." := EntryNo;

        // Standard fields
        WithholdingTaxEntry."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        WithholdingTaxEntry."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group" := GenJnlLine."Wthldg. Tax Bus. Post. Group";
        WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group" := GenJnlLine."Wthldg. Tax Prod. Post. Group";
        WithholdingTaxEntry."Posting Date" := GenJnlLine."Posting Date";
        WithholdingTaxEntry."Document Date" := GenJnlLine."Document Date";
        WithholdingTaxEntry."Document No." := GenJnlLine."Document No.";
        WithholdingTaxEntry."Document Type" := GenJnlLine."Document Type";
        WithholdingTaxEntry."External Document No." := GenJnlLine."External Document No.";
        WithholdingTaxEntry."Source Code" := GenJnlLine."Source Code";
        WithholdingTaxEntry."Reason Code" := GenJnlLine."Reason Code";
        WithholdingTaxEntry."User ID" := UserId;
        WithholdingTaxEntry."Currency Code" := GenJnlLine."Currency Code";
        WithholdingTaxEntry."Transaction No." := TransactionNo;
        WithholdingTaxEntry."Original Document No." := GenJnlLine."Document No.";

        // Employee-specific fields
        WithholdingTaxEntry."Party Type" := "Withholding Party Type"::Employee;
        WithholdingTaxEntry."Employee No." := GetEmployeeNoFromJnlLine(GenJnlLine);
        WithholdingTaxEntry."Calculation Base" := PostingSetup."Calculation Base";
        WithholdingTaxEntry."Calculation Method" := PostingSetup."Calculation Method";
        WithholdingTaxEntry."Threshold Base" := PostingSetup."WHT Threshold Base";
        WithholdingTaxEntry."Taxable Base Amount" := WHTBaseAmount;

        // Amounts
        WithholdingTaxEntry.Base := WHTBaseAmount;
        WithholdingTaxEntry.Amount := -WHTAmount;
        WithholdingTaxEntry."Base (LCY)" := WHTBaseAmount;
        WithholdingTaxEntry."Amount (LCY)" := -WHTAmount;
        WithholdingTaxEntry."Rem Realized Amount" := -WHTAmount;
        WithholdingTaxEntry."Rem Realized Base" := WHTBaseAmount;
        WithholdingTaxEntry."Withholding Tax %" := PostingSetup."Withholding Tax %";
        WithholdingTaxEntry."Withholding Tax Revenue Type" := PostingSetup."Revenue Type";

        // Transaction type
        WithholdingTaxEntry."Transaction Type" := WithholdingTaxEntry."Transaction Type"::Purchase;

        // Certificate
        if PostingSetup."Wthldg. Tax Rep Line No Series" <> '' then
            WithholdingTaxEntry."Wthldg. Tax Report Line No" :=
                NoSeries.GetNextNo(PostingSetup."Wthldg. Tax Rep Line No Series", WithholdingTaxEntry."Posting Date");

        OnBeforeInsertEmployeeWHTEntry(WithholdingTaxEntry, GenJnlLine);
        WithholdingTaxEntry.Insert(true);
        OnAfterInsertEmployeeWHTEntry(WithholdingTaxEntry, GenJnlLine);

        // Update threshold accumulator
        UpdateThresholdAccumulator(WithholdingTaxEntry);

        NextEntryNo := EntryNo;
        exit(EntryNo);
    end;

    procedure InsertEmployeeWHTComponentEntry(GenJnlLine: Record "Gen. Journal Line"; WHTGroupLine: Record "Withholding Tax Group Line"; ComponentWHT: Decimal; WHTBaseAmount: Decimal; TransactionNo: Integer; var NextEntryNo: Integer): Integer
    var
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        ComponentSetup: Record "Withholding Tax Posting Setup";
        NoSeries: Codeunit "No. Series";
        EntryNo: Integer;
    begin
        if ComponentWHT = 0 then
            exit(0);

        if WHTGroupLine."Wthldg. Tax Prod. Post. Group" <> '' then begin
            if not ComponentSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group") then
                exit(0);
        end else
            if not ComponentSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
                exit(0);

        WithholdingTaxEntry.Init();
        EntryNo := GetNextEntryNo();
        WithholdingTaxEntry."Entry No." := EntryNo;

        WithholdingTaxEntry."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        WithholdingTaxEntry."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group" := GenJnlLine."Wthldg. Tax Bus. Post. Group";
        WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group" := ComponentSetup."Wthldg. Tax Prod. Post. Group";
        WithholdingTaxEntry."Posting Date" := GenJnlLine."Posting Date";
        WithholdingTaxEntry."Document Date" := GenJnlLine."Document Date";
        WithholdingTaxEntry."Document No." := GenJnlLine."Document No.";
        WithholdingTaxEntry."Document Type" := GenJnlLine."Document Type";
        WithholdingTaxEntry."External Document No." := GenJnlLine."External Document No.";
        WithholdingTaxEntry."Source Code" := GenJnlLine."Source Code";
        WithholdingTaxEntry."Reason Code" := GenJnlLine."Reason Code";
        WithholdingTaxEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(WithholdingTaxEntry."User ID"));
        WithholdingTaxEntry."Currency Code" := GenJnlLine."Currency Code";
        WithholdingTaxEntry."Transaction No." := TransactionNo;
        WithholdingTaxEntry."Original Document No." := GenJnlLine."Document No.";

        WithholdingTaxEntry."Party Type" := "Withholding Party Type"::Employee;
        WithholdingTaxEntry."Employee No." := GetEmployeeNoFromJnlLine(GenJnlLine);
        WithholdingTaxEntry."Calculation Base" := ComponentSetup."Calculation Base";
        WithholdingTaxEntry."Calculation Method" := ComponentSetup."Calculation Method";
        WithholdingTaxEntry."Threshold Base" := ComponentSetup."WHT Threshold Base";
        WithholdingTaxEntry."Taxable Base Amount" := WHTBaseAmount;

        WithholdingTaxEntry.Base := WHTBaseAmount;
        WithholdingTaxEntry.Amount := -ComponentWHT;
        WithholdingTaxEntry."Base (LCY)" := WHTBaseAmount;
        WithholdingTaxEntry."Amount (LCY)" := -ComponentWHT;
        WithholdingTaxEntry."Rem Realized Amount" := -ComponentWHT;
        WithholdingTaxEntry."Rem Realized Base" := WHTBaseAmount;
        WithholdingTaxEntry."Withholding Tax %" := ComponentSetup."Withholding Tax %";
        WithholdingTaxEntry."Withholding Tax Revenue Type" := ComponentSetup."Revenue Type";

        WithholdingTaxEntry."Transaction Type" := WithholdingTaxEntry."Transaction Type"::Purchase;

        if ComponentSetup."Wthldg. Tax Rep Line No Series" <> '' then
            WithholdingTaxEntry."Wthldg. Tax Report Line No" :=
                NoSeries.GetNextNo(ComponentSetup."Wthldg. Tax Rep Line No Series", WithholdingTaxEntry."Posting Date");

        OnBeforeInsertEmployeeWHTEntry(WithholdingTaxEntry, GenJnlLine);
        WithholdingTaxEntry.Insert(true);
        OnAfterInsertEmployeeWHTEntry(WithholdingTaxEntry, GenJnlLine);

        UpdateThresholdAccumulator(WithholdingTaxEntry);

        NextEntryNo := EntryNo;
        exit(EntryNo);
    end;

    procedure IsNetCalculationBase(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        PostingSetup: Record "Withholding Tax Posting Setup";
        WHTGroupLine: Record "Withholding Tax Group Line";
        WHTGroupCode: Code[20];
    begin
        // Direct lookup (works for single-tax and groups where prod. post. group is set)
        if PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
            exit(PostingSetup."Calculation Base" = PostingSetup."Calculation Base"::Net);

        // Group case where prod. post. group is empty: check via the first group line
        if ResolveWHTGroupComponents(GenJnlLine, WHTGroupCode) then begin
            WHTGroupLine.SetRange("Group Code", WHTGroupCode);
            if WHTGroupLine.FindFirst() then
                if PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group") then
                    exit(PostingSetup."Calculation Base" = PostingSetup."Calculation Base"::Net);
        end;

        exit(false);
    end;

    procedure AccumulateBaseForPeriodThreshold(GenJnlLine: Record "Gen. Journal Line"; BaseAmount: Decimal)
    var
        PostingSetup: Record "Withholding Tax Posting Setup";
        ThresholdAccumulator: Record "WHT Threshold Accumulator";
        WHTGroupLine: Record "Withholding Tax Group Line";
        WHTGroupCode: Code[20];
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        // Resolve posting setup — direct first, then via group
        if not PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
            if ResolveWHTGroupComponents(GenJnlLine, WHTGroupCode) then begin
                WHTGroupLine.SetRange("Group Code", WHTGroupCode);
                if WHTGroupLine.FindFirst() then
                    if not PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group") then
                        exit;
            end else
                exit;

        if not (PostingSetup."WHT Threshold Base" in
            ["Withholding Threshold Base"::"Category Period", "Withholding Threshold Base"::"Total Period"])
        then
            exit;

        GetPeriodBounds(PostingSetup."WHT Threshold Period", GenJnlLine."Posting Date", PeriodStartDate, PeriodEndDate);

        ThresholdAccumulator.Init();
        ThresholdAccumulator."Employee No." := GetEmployeeNoFromJnlLine(GenJnlLine);
        ThresholdAccumulator."Wthldg. Tax Bus. Post. Group" := GenJnlLine."Wthldg. Tax Bus. Post. Group";
        ThresholdAccumulator."Wthldg. Tax Prod. Post. Group" := PostingSetup."Wthldg. Tax Prod. Post. Group";
        ThresholdAccumulator."Threshold Base" := PostingSetup."WHT Threshold Base";
        ThresholdAccumulator."Period Start Date" := PeriodStartDate;
        ThresholdAccumulator."Period End Date" := PeriodEndDate;
        ThresholdAccumulator."Accumulated Base Amount" := BaseAmount;
        ThresholdAccumulator."Accumulated WHT Amount" := 0;
        OnBeforeInsertThresholdAccumulator(ThresholdAccumulator, GenJnlLine, PostingSetup, BaseAmount);
        ThresholdAccumulator.Insert(true);
    end;

    procedure ResolveWHTGroupComponents(GenJnlLine: Record "Gen. Journal Line"; var WHTGroupCode: Code[20]) Result: Boolean
    begin
        OnBeforeResolveWHTGroupComponents(GenJnlLine, WHTGroupCode, Result);
        exit(Result);
    end;

    local procedure CalcGrossUpAmount(NetAmount: Decimal; PostingSetup: Record "Withholding Tax Posting Setup"; WHTGroupCode: Code[20]; HasGroup: Boolean): Decimal
    var
        WHTGroupLine: Record "Withholding Tax Group Line";
        TotalTaxRate: Decimal;
    begin
        if HasGroup then begin
            WHTGroupLine.Reset();
            WHTGroupLine.SetRange("Group Code", WHTGroupCode);
            if WHTGroupLine.FindSet() then
                repeat
                    TotalTaxRate += GetComponentTaxRate(WHTGroupLine, PostingSetup);
                until WHTGroupLine.Next() = 0;
        end else
            TotalTaxRate := PostingSetup."Withholding Tax %";

        if TotalTaxRate >= 100 then
            exit(NetAmount);

        exit(Round(NetAmount / (1 - TotalTaxRate / 100)));
    end;

    local procedure GetComponentTaxRate(WHTGroupLine: Record "Withholding Tax Group Line"; ParentSetup: Record "Withholding Tax Posting Setup"): Decimal
    var
        ComponentSetup: Record "Withholding Tax Posting Setup";
    begin
        if WHTGroupLine."Wthldg. Tax Prod. Post. Group" <> '' then
            if ComponentSetup.Get(ParentSetup."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group") then
                exit(ComponentSetup."Withholding Tax %");

        exit(ParentSetup."Withholding Tax %");
    end;

    procedure CalcComponentWHT(WHTGroupLine: Record "Withholding Tax Group Line"; BaseAmount: Decimal; GenJnlLine: Record "Gen. Journal Line"): Decimal
    var
        ComponentSetup: Record "Withholding Tax Posting Setup";
        TaxRate: Decimal;
    begin
        if WHTGroupLine."Wthldg. Tax Prod. Post. Group" <> '' then
            if ComponentSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group") then
                TaxRate := ComponentSetup."Withholding Tax %";

        exit(BaseAmount * TaxRate / 100);
    end;

    procedure EvaluateThreshold(PostingSetup: Record "Withholding Tax Posting Setup"; EmployeeNo: Code[20]; PostingDate: Date; BaseAmount: Decimal): Boolean
    var
        ThresholdBase: Enum "Withholding Threshold Base";
        ThresholdAmount: Decimal;
        AccumulatedAmount: Decimal;
    begin
        ThresholdAmount := PostingSetup."Wthldg. Tax Min. Inv. Amount";
        if ThresholdAmount = 0 then
            exit(true); // No threshold configured, always apply

        ThresholdBase := PostingSetup."WHT Threshold Base";

        case ThresholdBase of
            ThresholdBase::Record:
                // Evaluate per individual record/line
                exit(BaseAmount >= ThresholdAmount);
            ThresholdBase::Document:
                // Document-level threshold evaluated at document posting level
                exit(BaseAmount >= ThresholdAmount);
            ThresholdBase::"Category Period":
                begin
                    AccumulatedAmount := GetAccumulatedAmount(
                        EmployeeNo,
                        PostingSetup."Wthldg. Tax Bus. Post. Group",
                        PostingSetup."Wthldg. Tax Prod. Post. Group",
                        PostingSetup."WHT Threshold Period",
                        PostingDate);
                    if ThresholdApplied then
                        exit(AccumulatedAmount >= ThresholdAmount)
                    else
                        exit((AccumulatedAmount + BaseAmount) >= ThresholdAmount);
                end;
            ThresholdBase::"Total Period":
                begin
                    AccumulatedAmount := GetTotalAccumulatedAmount(
                        EmployeeNo,
                        PostingSetup."WHT Threshold Period",
                        PostingDate);
                    exit((AccumulatedAmount + BaseAmount) >= ThresholdAmount);
                end;
            else
                exit(true);
        end;
    end;

    local procedure GetAccumulatedAmount(EmployeeNo: Code[20]; BusPostGroup: Code[20]; ProdPostGroup: Code[20]; ThresholdPeriod: Enum "WHT Threshold Period Type"; PostingDate: Date): Decimal
    var
        ThresholdAccumulator: Record "WHT Threshold Accumulator";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        GetPeriodBounds(ThresholdPeriod, PostingDate, PeriodStartDate, PeriodEndDate);

        ThresholdAccumulator.Reset();
        ThresholdAccumulator.SetRange("Employee No.", EmployeeNo);
        ThresholdAccumulator.SetRange("Wthldg. Tax Bus. Post. Group", BusPostGroup);
        ThresholdAccumulator.SetRange("Wthldg. Tax Prod. Post. Group", ProdPostGroup);
        ThresholdAccumulator.SetRange("Period Start Date", PeriodStartDate);
        ThresholdAccumulator.SetRange("Period End Date", PeriodEndDate);
        ThresholdAccumulator.CalcSums("Accumulated Base Amount");
        exit(ThresholdAccumulator."Accumulated Base Amount");
    end;

    local procedure GetTotalAccumulatedAmount(EmployeeNo: Code[20]; ThresholdPeriod: Enum "WHT Threshold Period Type"; PostingDate: Date): Decimal
    var
        ThresholdAccumulator: Record "WHT Threshold Accumulator";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        GetPeriodBounds(ThresholdPeriod, PostingDate, PeriodStartDate, PeriodEndDate);

        ThresholdAccumulator.Reset();
        ThresholdAccumulator.SetRange("Employee No.", EmployeeNo);
        ThresholdAccumulator.SetRange("Period Start Date", PeriodStartDate);
        ThresholdAccumulator.SetRange("Period End Date", PeriodEndDate);
        ThresholdAccumulator.CalcSums("Accumulated Base Amount");
        exit(ThresholdAccumulator."Accumulated Base Amount");
    end;

    procedure UpdateThresholdAccumulator(WithholdingTaxEntry: Record "Withholding Tax Entry")
    var
        ThresholdAccumulator: Record "WHT Threshold Accumulator";
        PostingSetup: Record "Withholding Tax Posting Setup";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        if WithholdingTaxEntry."Party Type" <> "Withholding Party Type"::Employee then
            exit;

        if not PostingSetup.Get(WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group", WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group") then
            exit;

        if not (PostingSetup."WHT Threshold Base" in
            ["Withholding Threshold Base"::"Category Period", "Withholding Threshold Base"::"Total Period"])
        then
            exit;

        GetPeriodBounds(PostingSetup."WHT Threshold Period", WithholdingTaxEntry."Posting Date", PeriodStartDate, PeriodEndDate);

        ThresholdAccumulator.Init();
        ThresholdAccumulator."Employee No." := WithholdingTaxEntry."Employee No.";
        ThresholdAccumulator."Wthldg. Tax Bus. Post. Group" := WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group";
        ThresholdAccumulator."Wthldg. Tax Prod. Post. Group" := WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group";
        ThresholdAccumulator."Threshold Base" := PostingSetup."WHT Threshold Base";
        ThresholdAccumulator."Period Start Date" := PeriodStartDate;
        ThresholdAccumulator."Period End Date" := PeriodEndDate;
        ThresholdAccumulator."Accumulated Base Amount" := WithholdingTaxEntry."Taxable Base Amount";
        ThresholdAccumulator."Accumulated WHT Amount" := Abs(WithholdingTaxEntry.Amount);
        OnBeforeUpdateThresholdAccumulator(ThresholdAccumulator, WithholdingTaxEntry, PostingSetup);
        ThresholdAccumulator.Insert(true);
    end;

    procedure ReverseThresholdAccumulator(WithholdingTaxEntry: Record "Withholding Tax Entry")
    var
        ThresholdAccumulator: Record "WHT Threshold Accumulator";
        PostingSetup: Record "Withholding Tax Posting Setup";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        if WithholdingTaxEntry."Party Type" <> "Withholding Party Type"::Employee then
            exit;

        if not PostingSetup.Get(WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group", WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group") then
            exit;

        if not (PostingSetup."WHT Threshold Base" in
            ["Withholding Threshold Base"::"Category Period", "Withholding Threshold Base"::"Total Period"])
        then
            exit;

        GetPeriodBounds(PostingSetup."WHT Threshold Period", WithholdingTaxEntry."Posting Date", PeriodStartDate, PeriodEndDate);

        // Insert a negative accumulator entry to reverse
        ThresholdAccumulator.Init();
        ThresholdAccumulator."Employee No." := WithholdingTaxEntry."Employee No.";
        ThresholdAccumulator."Wthldg. Tax Bus. Post. Group" := WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group";
        ThresholdAccumulator."Wthldg. Tax Prod. Post. Group" := WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group";
        ThresholdAccumulator."Threshold Base" := PostingSetup."WHT Threshold Base";
        ThresholdAccumulator."Period Start Date" := PeriodStartDate;
        ThresholdAccumulator."Period End Date" := PeriodEndDate;
        ThresholdAccumulator."Accumulated Base Amount" := -WithholdingTaxEntry."Taxable Base Amount";
        ThresholdAccumulator."Accumulated WHT Amount" := -Abs(WithholdingTaxEntry.Amount);
        OnBeforeReverseThresholdAccumulator(ThresholdAccumulator, WithholdingTaxEntry, PostingSetup);
        ThresholdAccumulator.Insert(true);
    end;

    procedure GetPeriodBounds(ThresholdPeriod: Enum "WHT Threshold Period Type"; PostingDate: Date; var PeriodStartDate: Date; var PeriodEndDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        case ThresholdPeriod of
            ThresholdPeriod::Month:
                begin
                    PeriodStartDate := CalcDate('<-CM>', PostingDate);
                    PeriodEndDate := CalcDate('<CM>', PostingDate);
                end;
            ThresholdPeriod::Quarter:
                begin
                    PeriodStartDate := CalcDate('<-CQ>', PostingDate);
                    PeriodEndDate := CalcDate('<CQ>', PostingDate);
                end;
            ThresholdPeriod::Year:
                begin
                    PeriodStartDate := CalcDate('<-CY>', PostingDate);
                    PeriodEndDate := CalcDate('<CY>', PostingDate);
                end;
            ThresholdPeriod::"Fiscal Period":
                begin
                    AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                    AccountingPeriod.SetRange("New Fiscal Year", true);
                    if AccountingPeriod.FindLast() then
                        PeriodStartDate := AccountingPeriod."Starting Date"
                    else
                        PeriodStartDate := CalcDate('<-CY>', PostingDate);

                    AccountingPeriod.SetRange("Starting Date", PostingDate + 1, DMY2Date(31, 12, 9999));
                    AccountingPeriod.SetRange("New Fiscal Year", true);
                    if AccountingPeriod.FindFirst() then
                        PeriodEndDate := AccountingPeriod."Starting Date" - 1
                    else
                        PeriodEndDate := CalcDate('<CY>', PostingDate);
                end;
            else begin
                PeriodStartDate := PostingDate;
                PeriodEndDate := PostingDate;
            end;
        end;
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WithholdingTaxEntry: Record "Withholding Tax Entry";
    begin
        if WithholdingTaxEntry.FindLast() then
            exit(WithholdingTaxEntry."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure GetEmployeeFromJnlLine(GenJnlLine: Record "Gen. Journal Line"; var Employee: Record Employee): Boolean
    var
        EmployeeNo: Code[20];
    begin
        EmployeeNo := GetEmployeeNoFromJnlLine(GenJnlLine);
        if EmployeeNo = '' then
            exit(false);

        exit(Employee.Get(EmployeeNo));
    end;

    procedure GetEmployeeNoFromJnlLine(GenJnlLine: Record "Gen. Journal Line"): Code[20]
    begin
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee then
            exit(GenJnlLine."Account No.");

        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then
            exit(GenJnlLine."Bal. Account No.");

        exit('');
    end;

    procedure IsWithholdingTaxEnabled(): Boolean
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Enable Withholding Tax");
    end;

    procedure IsThresholdIncludeded(ThresholdCalculated: Boolean)
    begin
        ThresholdApplied := ThresholdCalculated;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcEmployeeWHT(var GenJnlLine: Record "Gen. Journal Line"; var WHTAmount: Decimal; var WHTBaseAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCalcEmployeeWHT(var GenJnlLine: Record "Gen. Journal Line"; Employee: Record Employee; var WHTAmount: Decimal; var WHTBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertThresholdAccumulator(var ThresholdAccumulator: Record "WHT Threshold Accumulator"; GenJnlLine: Record "Gen. Journal Line"; PostingSetup: Record "Withholding Tax Posting Setup"; BaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateThresholdAccumulator(var ThresholdAccumulator: Record "WHT Threshold Accumulator"; WithholdingTaxEntry: Record "Withholding Tax Entry"; PostingSetup: Record "Withholding Tax Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReverseThresholdAccumulator(var ThresholdAccumulator: Record "WHT Threshold Accumulator"; WithholdingTaxEntry: Record "Withholding Tax Entry"; PostingSetup: Record "Withholding Tax Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResolveWHTGroupComponents(GenJnlLine: Record "Gen. Journal Line"; var WHTGroupCode: Code[20]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEmployeeWHTEntry(var WithholdingTaxEntry: Record "Withholding Tax Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertEmployeeWHTEntry(var WithholdingTaxEntry: Record "Withholding Tax Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}
