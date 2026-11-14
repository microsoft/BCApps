// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.WithholdingTax;

codeunit 6790 "WHT Employee Calculation"
{
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ThresholdApplied: Boolean;
        PendingThresholdBase: Dictionary of [Text, Decimal];
        NetThresholdModeNotSupportedErr: Label 'The %1 option is not supported for %2 calculation with %3 threshold base.', Comment = '%1 = Tax Amount Above Threshold field caption, %2 = Calculation Base option value, %3 = WHT Threshold Base option value';

    procedure IsEmployeeWHTApplicable(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        Employee: Record Employee;
        IsApplicable: Boolean;
    begin
        if not IsWithholdingTaxEnabled() then
            exit(false);

        if not GetEmployeeFromJnlLine(GenJnlLine, Employee) then
            exit(false);

        if Employee."Withholding Tax Exempt" then
            exit(false);

        if GenJnlLine."Wthldg. Tax Bus. Post. Group" = '' then
            exit(false);

        IsApplicable := true;

        OnAfterIsEmployeeWHTApplicable(GenJnlLine, Employee, IsApplicable);
        exit(IsApplicable);
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
        TaxableBaseAmount: Decimal;
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

        HasGroup := ResolveWHTGroupComponents(GenJnlLine, WHTGroupCode);

        if not HasGroup then
            PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group");

        CalcBase := PostingSetup."Calculation Base";
        CalcMethod := PostingSetup."Calculation Method";

        if CalcBase = CalcBase::Net then begin
            if PostingSetup."Tax Amount Above Threshold" then
                case PostingSetup."WHT Threshold Base" of
                    PostingSetup."WHT Threshold Base"::Record,
                    PostingSetup."WHT Threshold Base"::Document:
                        LineAmount := CalcGrossUpAmount(LineAmount, PostingSetup, WHTGroupCode, HasGroup, PostingSetup."Wthldg. Tax Min. Inv. Amount");
                    else
                        Error(
                            NetThresholdModeNotSupportedErr,
                            PostingSetup.FieldCaption("Tax Amount Above Threshold"),
                            Format(PostingSetup."Calculation Base"::Net),
                            Format(PostingSetup."WHT Threshold Base"));
                end
            else
                LineAmount := CalcGrossUpAmount(LineAmount, PostingSetup, WHTGroupCode, HasGroup, 0);

            if GenJnlLine.Amount < 0 then
                GenJnlLine.Validate(Amount, -LineAmount);
        end;

        WHTBaseAmount := LineAmount;
        TaxableBaseAmount := LineAmount;

        if not EvaluateThresholdWithTaxableBase(PostingSetup, Employee."No.", GenJnlLine."Posting Date", LineAmount, TaxableBaseAmount) then
            exit;

        WHTBaseAmount := TaxableBaseAmount;

        if HasGroup then begin
            CompoundBase := TaxableBaseAmount;
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
            if PostingSetup."Withholding Tax %" > 0 then
                WHTAmount := Round(TaxableBaseAmount * PostingSetup."Withholding Tax %" / 100);
    end;

    procedure InsertEmployeeWithholdingTaxEntry(GenJnlLine: Record "Gen. Journal Line"; WHTAmount: Decimal; WHTBaseAmount: Decimal; TransactionNo: Integer; var NextEntryNo: Integer): Integer
    begin
        exit(InsertEmployeeWithholdingTaxEntry(GenJnlLine, WHTAmount, WHTBaseAmount, Abs(GenJnlLine.Amount), TransactionNo, NextEntryNo));
    end;

    /// <summary>
    /// Inserts an employee withholding tax entry and records <paramref name="ThresholdAccumBaseAmount"/> as the amount that counts towards the period threshold.
    /// Use this overload when the journal line amount is not the original base of the withheld transaction, for example when one employee entry carries several expense lines.
    /// </summary>
    procedure InsertEmployeeWithholdingTaxEntry(GenJnlLine: Record "Gen. Journal Line"; WHTAmount: Decimal; WHTBaseAmount: Decimal; ThresholdAccumBaseAmount: Decimal; TransactionNo: Integer; var NextEntryNo: Integer): Integer
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
        WithholdingTaxEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(WithholdingTaxEntry."User ID"));
        WithholdingTaxEntry."Currency Code" := GenJnlLine."Currency Code";
        WithholdingTaxEntry."Transaction No." := TransactionNo;
        WithholdingTaxEntry."Original Document No." := GenJnlLine."Document No.";
        WithholdingTaxEntry."Party Type" := "Withholding Party Type"::Employee;
        WithholdingTaxEntry."Employee No." := GetEmployeeNoFromJnlLine(GenJnlLine);
        WithholdingTaxEntry."Calculation Base" := PostingSetup."Calculation Base";
        WithholdingTaxEntry."Calculation Method" := PostingSetup."Calculation Method";
        WithholdingTaxEntry."Threshold Base" := PostingSetup."WHT Threshold Base";

        WithholdingTaxEntry."Taxable Base Amount" := WHTBaseAmount;
        WithholdingTaxEntry."Threshold Accum. Base Amt." := Abs(ThresholdAccumBaseAmount);
        WithholdingTaxEntry.Base := WHTBaseAmount;
        WithholdingTaxEntry.Amount := -WHTAmount;
        WithholdingTaxEntry."Base (LCY)" := WHTBaseAmount;
        WithholdingTaxEntry."Amount (LCY)" := -WHTAmount;
        WithholdingTaxEntry."Rem Realized Amount" := -WHTAmount;
        WithholdingTaxEntry."Rem Realized Base" := WHTBaseAmount;
        WithholdingTaxEntry."Withholding Tax %" := PostingSetup."Withholding Tax %";
        WithholdingTaxEntry."Withholding Tax Revenue Type" := PostingSetup."Revenue Type";
        WithholdingTaxEntry."Transaction Type" := WithholdingTaxEntry."Transaction Type"::Purchase;

        if PostingSetup."Wthldg. Tax Rep Line No Series" <> '' then
            WithholdingTaxEntry."Wthldg. Tax Report Line No" :=
                NoSeries.GetNextNo(PostingSetup."Wthldg. Tax Rep Line No Series", WithholdingTaxEntry."Posting Date");

        OnBeforeInsertEmployeeWHTEntry(WithholdingTaxEntry, GenJnlLine);
        WithholdingTaxEntry.Insert(true);
        OnAfterInsertEmployeeWHTEntry(WithholdingTaxEntry, GenJnlLine);

        UpdateThresholdAccumulator(WithholdingTaxEntry);

        NextEntryNo := EntryNo;
        exit(EntryNo);
    end;

    procedure InsertEmployeeWHTComponentEntry(GenJnlLine: Record "Gen. Journal Line"; WHTGroupLine: Record "Withholding Tax Group Line"; ComponentWHT: Decimal; WHTBaseAmount: Decimal; TransactionNo: Integer; var NextEntryNo: Integer): Integer
    begin
        exit(InsertEmployeeWHTComponentEntry(GenJnlLine, WHTGroupLine, ComponentWHT, WHTBaseAmount, Abs(GenJnlLine.Amount), TransactionNo, NextEntryNo));
    end;

    /// <summary>
    /// Inserts an employee withholding tax component entry and records <paramref name="ThresholdAccumBaseAmount"/> as the amount that counts towards the period threshold.
    /// </summary>
    procedure InsertEmployeeWHTComponentEntry(GenJnlLine: Record "Gen. Journal Line"; WHTGroupLine: Record "Withholding Tax Group Line"; ComponentWHT: Decimal; WHTBaseAmount: Decimal; ThresholdAccumBaseAmount: Decimal; TransactionNo: Integer; var NextEntryNo: Integer): Integer
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
        WithholdingTaxEntry."Threshold Accum. Base Amt." := Abs(ThresholdAccumBaseAmount);

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
        if PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
            exit(PostingSetup."Calculation Base" = PostingSetup."Calculation Base"::Net);

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

    local procedure CalcGrossUpAmount(NetAmount: Decimal; PostingSetup: Record "Withholding Tax Posting Setup"; WHTGroupCode: Code[20]; HasGroup: Boolean; ThresholdAmount: Decimal): Decimal
    var
        WHTGroupLine: Record "Withholding Tax Group Line";
        TotalTaxRate: Decimal;
        TaxRate: Decimal;
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

        TaxRate := TotalTaxRate / 100;
        if ThresholdAmount > 0 then begin
            if NetAmount <= ThresholdAmount then
                exit(NetAmount);

            exit(Round((NetAmount - (ThresholdAmount * TaxRate)) / (1 - TaxRate)));
        end;

        exit(Round(NetAmount / (1 - TaxRate)));
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
        TaxableBaseAmount: Decimal;
    begin
        exit(EvaluateThresholdWithTaxableBase(PostingSetup, EmployeeNo, PostingDate, BaseAmount, TaxableBaseAmount));
    end;

    local procedure EvaluateThresholdWithTaxableBase(PostingSetup: Record "Withholding Tax Posting Setup"; EmployeeNo: Code[20]; PostingDate: Date; BaseAmount: Decimal; var TaxableBaseAmount: Decimal): Boolean
    var
        ThresholdBase: Enum "Withholding Threshold Base";
        ThresholdAmount: Decimal;
        AccumulatedAmount: Decimal;
        PreviousAccumulatedAmount: Decimal;
        AmountIncludingCurrent: Decimal;
    begin
        TaxableBaseAmount := BaseAmount;

        ThresholdAmount := PostingSetup."Wthldg. Tax Min. Inv. Amount";
        if ThresholdAmount = 0 then
            exit(true);

        ThresholdBase := PostingSetup."WHT Threshold Base";

        case ThresholdBase of
            ThresholdBase::Record:
                begin
                    if BaseAmount < ThresholdAmount then begin
                        TaxableBaseAmount := 0;
                        exit(false);
                    end;

                    if PostingSetup."Tax Amount Above Threshold" then
                        TaxableBaseAmount := BaseAmount - ThresholdAmount;

                    exit(TaxableBaseAmount > 0);
                end;
            ThresholdBase::Document:
                begin
                    if BaseAmount < ThresholdAmount then begin
                        TaxableBaseAmount := 0;
                        exit(false);
                    end;

                    if PostingSetup."Tax Amount Above Threshold" then
                        TaxableBaseAmount := BaseAmount - ThresholdAmount;

                    exit(TaxableBaseAmount > 0);
                end;
            ThresholdBase::"Category Period":
                begin
                    AccumulatedAmount := GetAccumulatedAmount(
                        EmployeeNo,
                        PostingSetup."Wthldg. Tax Bus. Post. Group",
                        PostingSetup."Wthldg. Tax Prod. Post. Group",
                        PostingSetup."WHT Threshold Period",
                        PostingDate);

                    PreviousAccumulatedAmount := AccumulatedAmount;
                    if ThresholdApplied then
                        PreviousAccumulatedAmount := PreviousAccumulatedAmount - BaseAmount;
                    if PreviousAccumulatedAmount < 0 then
                        PreviousAccumulatedAmount := 0;

                    AmountIncludingCurrent := PreviousAccumulatedAmount + BaseAmount;

                    if AmountIncludingCurrent < ThresholdAmount then begin
                        TaxableBaseAmount := 0;
                        exit(false);
                    end;

                    if PostingSetup."Tax Amount Above Threshold" then
                        if PreviousAccumulatedAmount >= ThresholdAmount then
                            TaxableBaseAmount := BaseAmount
                        else
                            TaxableBaseAmount := AmountIncludingCurrent - ThresholdAmount;

                    exit(TaxableBaseAmount > 0);
                end;
            ThresholdBase::"Total Period":
                begin
                    AccumulatedAmount := GetTotalAccumulatedAmount(
                        EmployeeNo,
                        PostingSetup."WHT Threshold Period",
                        PostingDate);

                    PreviousAccumulatedAmount := AccumulatedAmount;
                    if ThresholdApplied then
                        PreviousAccumulatedAmount := PreviousAccumulatedAmount - BaseAmount;
                    if PreviousAccumulatedAmount < 0 then
                        PreviousAccumulatedAmount := 0;

                    AmountIncludingCurrent := PreviousAccumulatedAmount + BaseAmount;
                    if AmountIncludingCurrent < ThresholdAmount then begin
                        TaxableBaseAmount := 0;
                        exit(false);
                    end;

                    if PostingSetup."Tax Amount Above Threshold" then
                        if PreviousAccumulatedAmount >= ThresholdAmount then
                            TaxableBaseAmount := BaseAmount
                        else
                            TaxableBaseAmount := AmountIncludingCurrent - ThresholdAmount;

                    exit(TaxableBaseAmount > 0);
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
        PendingAmount: Decimal;
    begin
        GetPeriodBounds(ThresholdPeriod, PostingDate, PeriodStartDate, PeriodEndDate);

        ThresholdAccumulator.Reset();
        ThresholdAccumulator.SetRange("Employee No.", EmployeeNo);
        ThresholdAccumulator.SetRange("Wthldg. Tax Bus. Post. Group", BusPostGroup);
        ThresholdAccumulator.SetRange("Wthldg. Tax Prod. Post. Group", ProdPostGroup);
        ThresholdAccumulator.SetRange("Period Start Date", PeriodStartDate);
        ThresholdAccumulator.SetRange("Period End Date", PeriodEndDate);
        ThresholdAccumulator.CalcSums("Accumulated Base Amount");

        PendingAmount := GetPendingThresholdBase(EmployeeNo, BusPostGroup, ProdPostGroup, PeriodStartDate, PeriodEndDate);
        exit(ThresholdAccumulator."Accumulated Base Amount" + PendingAmount);
    end;

    local procedure GetTotalAccumulatedAmount(EmployeeNo: Code[20]; ThresholdPeriod: Enum "WHT Threshold Period Type"; PostingDate: Date): Decimal
    var
        ThresholdAccumulator: Record "WHT Threshold Accumulator";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        PendingAmount: Decimal;
    begin
        GetPeriodBounds(ThresholdPeriod, PostingDate, PeriodStartDate, PeriodEndDate);

        ThresholdAccumulator.Reset();
        ThresholdAccumulator.SetRange("Employee No.", EmployeeNo);
        ThresholdAccumulator.SetRange("Period Start Date", PeriodStartDate);
        ThresholdAccumulator.SetRange("Period End Date", PeriodEndDate);
        ThresholdAccumulator.CalcSums("Accumulated Base Amount");

        PendingAmount := GetPendingThresholdBase(EmployeeNo, '', '', PeriodStartDate, PeriodEndDate);
        exit(ThresholdAccumulator."Accumulated Base Amount" + PendingAmount);
    end;

    /// <summary>
    /// Registers a base amount that belongs to the current period but has not been posted to the threshold accumulator yet.
    /// Subsequent calculations on the same codeunit instance include this amount in the period total, for example when several expense lines are calculated before the employee entry is posted.
    /// </summary>
    procedure AddPendingThresholdBase(GenJnlLine: Record "Gen. Journal Line"; BaseAmount: Decimal)
    var
        PostingSetup: Record "Withholding Tax Posting Setup";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        PendingKey: Text;
        PendingAmount: Decimal;
    begin
        if BaseAmount = 0 then
            exit;

        if not PostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
            exit;

        if not (PostingSetup."WHT Threshold Base" in ["Withholding Threshold Base"::"Category Period", "Withholding Threshold Base"::"Total Period"]) then
            exit;

        GetPeriodBounds(PostingSetup."WHT Threshold Period", GenJnlLine."Posting Date", PeriodStartDate, PeriodEndDate);
        PendingKey := GetPendingThresholdKey(GetEmployeeNoFromJnlLine(GenJnlLine), PostingSetup."Wthldg. Tax Bus. Post. Group", PostingSetup."Wthldg. Tax Prod. Post. Group", PeriodStartDate, PeriodEndDate);

        if PendingThresholdBase.Get(PendingKey, PendingAmount) then
            PendingThresholdBase.Set(PendingKey, PendingAmount + Abs(BaseAmount))
        else
            PendingThresholdBase.Add(PendingKey, Abs(BaseAmount));
    end;

    local procedure GetPendingThresholdBase(EmployeeNo: Code[20]; BusPostGroup: Code[20]; ProdPostGroup: Code[20]; PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        PendingKey: Text;
        PendingAmount: Decimal;
        TotalPending: Decimal;
        DictKey: Text;
    begin
        if (BusPostGroup <> '') or (ProdPostGroup <> '') then begin
            PendingKey := GetPendingThresholdKey(EmployeeNo, BusPostGroup, ProdPostGroup, PeriodStartDate, PeriodEndDate);
            if PendingThresholdBase.Get(PendingKey, PendingAmount) then
                exit(PendingAmount);

            exit(0);
        end;

        foreach DictKey in PendingThresholdBase.Keys() do
            if DictKey.StartsWith(GetPendingThresholdTotalPrefix(EmployeeNo, PeriodStartDate, PeriodEndDate)) then begin
                PendingThresholdBase.Get(DictKey, PendingAmount);
                TotalPending += PendingAmount;
            end;

        exit(TotalPending);
    end;

    local procedure GetPendingThresholdKey(EmployeeNo: Code[20]; BusPostGroup: Code[20]; ProdPostGroup: Code[20]; PeriodStartDate: Date; PeriodEndDate: Date): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5', EmployeeNo, PeriodStartDate, PeriodEndDate, BusPostGroup, ProdPostGroup));
    end;

    local procedure GetPendingThresholdTotalPrefix(EmployeeNo: Code[20]; PeriodStartDate: Date; PeriodEndDate: Date): Text
    begin
        exit(StrSubstNo('%1|%2|%3|', EmployeeNo, PeriodStartDate, PeriodEndDate));
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
        ThresholdAccumulator."Accumulated Base Amount" := WithholdingTaxEntry."Threshold Accum. Base Amt.";
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

        ThresholdAccumulator.Init();
        ThresholdAccumulator."Employee No." := WithholdingTaxEntry."Employee No.";
        ThresholdAccumulator."Wthldg. Tax Bus. Post. Group" := WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group";
        ThresholdAccumulator."Wthldg. Tax Prod. Post. Group" := WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group";
        ThresholdAccumulator."Threshold Base" := PostingSetup."WHT Threshold Base";
        ThresholdAccumulator."Period Start Date" := PeriodStartDate;
        ThresholdAccumulator."Period End Date" := PeriodEndDate;
        ThresholdAccumulator."Accumulated Base Amount" := -WithholdingTaxEntry."Threshold Accum. Base Amt.";
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
    local procedure OnAfterIsEmployeeWHTApplicable(GenJnlLine: Record "Gen. Journal Line"; Employee: Record Employee; var IsApplicable: Boolean)
    begin
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
