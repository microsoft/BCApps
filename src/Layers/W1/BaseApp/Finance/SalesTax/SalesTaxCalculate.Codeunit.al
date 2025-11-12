// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 398 "Sales Tax Calculate"
{

    trigger OnRun()
    begin
    end;

    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TempTaxDetail: Record "Tax Detail" temporary;
        ExchangeFactor: Decimal;
        TotalTaxAmountRounding: Decimal;
        TotalForAllocation: Decimal;
        RemainingTaxDetails: Integer;
        LastCalculationOrder: Integer;
        Initialised: Boolean;
        FirstLine: Boolean;
        TaxOnTaxCalculated: Boolean;
        CalculationOrderViolation: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 in %2 %3 must be filled in with unique values when %4 is %5.';
        Text001: Label 'The sales tax amount for the %1 %2 and the %3 %4 is incorrect. ';
#pragma warning restore AA0470
        Text003: Label 'Lines is not initialized';
#pragma warning disable AA0470
        Text004: Label 'The calculated sales tax amount is %5, but was supposed to be %6.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CalculateTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) TaxAmount: Decimal
    var
        MaxAmount: Decimal;
        TaxBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        TaxAmount := 0;
        IsHandled := false;
        OnBeforeCalculateTaxProcedure(TaxAreaCode, TaxGroupCode, TaxLiable, Date, Amount, Quantity, ExchangeRate, TaxAmount, IsHandled);
        if IsHandled then
            exit;

        if not TaxLiable or (TaxAreaCode = '') or (TaxGroupCode = '') or
           ((Amount = 0) and (Quantity = 0))
        then
            exit;

        if ExchangeRate = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ExchangeRate;

        Amount := Amount / ExchangeFactor;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                TaxDetail.Reset();
                TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if TaxGroupCode = '' then
                    TaxDetail.SetFilter("Tax Group Code", '%1', TaxGroupCode)
                else
                    TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', TaxGroupCode);
                if Date = 0D then
                    TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate())
                else
                    TaxDetail.SetFilter("Effective Date", '<=%1', Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales Tax");
                if TaxDetail.FindLast() then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100
                    else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() then
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum"
                    else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                    end;
            until TaxAreaLine.Next(-1) = 0;
            TaxAmount := TaxAmount * ExchangeFactor;

            if TaxOnTaxCalculated and CalculationOrderViolation then
                Error(
                  Text000,
                  TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
                  TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
        end;
    end;

    procedure ReverseCalculateTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; TotalAmount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) Amount: Decimal
    var
        Inclination: array[10] of Decimal;
        Constant: array[10] of Decimal;
        MaxRangeAmount: array[10] of Decimal;
        MaxTaxAmount: Decimal;
        i: Integer;
        j: Integer;
        Steps: Integer;
        InclinationLess: Decimal;
        InclinationHigher: Decimal;
        ConstantHigher: Decimal;
        SplitAmount: Decimal;
        MaxAmount: Decimal;
        Inserted: Boolean;
        Found: Boolean;
    begin
        Amount := TotalAmount;

        if not TaxLiable or (TaxAreaCode = '') or (TaxGroupCode = '') or
           ((Amount = 0) and (Quantity = 0))
        then
            exit;

        if ExchangeRate = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ExchangeRate;

        TotalAmount := TotalAmount / ExchangeFactor;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        Steps := 1;
        Clear(Inclination);
        Clear(Constant);
        Clear(MaxRangeAmount);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                TaxDetail.Reset();
                TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if TaxGroupCode = '' then
                    TaxDetail.SetFilter("Tax Group Code", '%1', TaxGroupCode)
                else
                    TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', TaxGroupCode);
                if Date = 0D then
                    TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate())
                else
                    TaxDetail.SetFilter("Effective Date", '<=%1', Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales Tax");
                if TaxDetail.FindLast() then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    InclinationLess := TaxDetail."Tax Below Maximum" / 100;
                    InclinationHigher := TaxDetail."Tax Above Maximum" / 100;

                    if TaxDetail."Maximum Amount/Qty." = 0 then
                        for i := 1 to Steps do
                            if TaxDetail."Calculate Tax on Tax" then begin
                                Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                Constant[i] := (1 + InclinationLess) * Constant[i];
                            end else
                                Inclination[i] := Inclination[i] + InclinationLess
                    else begin
                        if TaxDetail."Calculate Tax on Tax" then begin
                            ConstantHigher :=
                              (TaxDetail."Tax Below Maximum" - TaxDetail."Tax Above Maximum") / 100 *
                              TaxDetail."Maximum Amount/Qty.";
                            i := 1;
                            Found := false;
                            while i < Steps do begin
                                MaxTaxAmount := (1 + Inclination[i]) * MaxRangeAmount[i] + Constant[i];
                                if Abs(TaxDetail."Maximum Amount/Qty.") < MaxTaxAmount then begin
                                    SplitAmount :=
                                      (Abs(TaxDetail."Maximum Amount/Qty.") / TaxDetail."Maximum Amount/Qty.") *
                                      ((Abs(TaxDetail."Maximum Amount/Qty.") - Constant[i]) / (1 + Inclination[i]));
                                    i := Steps;
                                    Found := true;
                                end;
                                i := i + 1;
                            end;
                            if not Found then
                                SplitAmount :=
                                  (Abs(TaxDetail."Maximum Amount/Qty.") / TaxDetail."Maximum Amount/Qty.") *
                                  (Abs(TaxDetail."Maximum Amount/Qty.") - Constant[Steps]) / (1 + Inclination[Steps]);
                        end else begin
                            ConstantHigher :=
                              (TaxDetail."Tax Below Maximum" - TaxDetail."Tax Above Maximum") / 100 *
                              TaxDetail."Maximum Amount/Qty.";
                            SplitAmount := TaxDetail."Maximum Amount/Qty.";
                        end;
                        i := 1;
                        Inserted := false;
                        while i <= Steps do begin
                            case true of
                                (MaxRangeAmount[i] < SplitAmount) and (MaxRangeAmount[i] > 0):
                                    if TaxDetail."Calculate Tax on Tax" then begin
                                        Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                        Constant[i] := (1 + InclinationLess) * Constant[i];
                                    end else
                                        Inclination[i] := Inclination[i] + InclinationLess;
                                MaxRangeAmount[i] = SplitAmount:
                                    begin
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                            Constant[i] := (1 + InclinationLess) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationLess;
                                        Inserted := true;
                                    end;
                                (MaxRangeAmount[i] > SplitAmount) or (MaxRangeAmount[i] = 0):
                                    if Inserted then begin
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationHigher;
                                            Constant[i] := (1 + InclinationHigher) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationHigher;
                                        Constant[i] := Constant[i] + ConstantHigher;
                                    end else begin
                                        Steps := Steps + 1;
                                        for j := Steps downto i + 1 do begin
                                            Inclination[j] := Inclination[j - 1];
                                            Constant[j] := Constant[j - 1];
                                            MaxRangeAmount[j] := MaxRangeAmount[j - 1];
                                        end;
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                            Constant[i] := (1 + InclinationLess) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationLess;
                                        MaxRangeAmount[i] := SplitAmount;
                                        Inserted := true;
                                    end;
                            end;
                            i := i + 1;
                        end;
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() then begin
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then
                        ConstantHigher := Quantity * TaxDetail."Tax Below Maximum"
                    else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        ConstantHigher :=
                          (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                    end;
                    ConstantHigher := Abs(ConstantHigher);

                    for i := 1 to Steps do
                        Constant[i] := Constant[i] + ConstantHigher;
                end;
            until TaxAreaLine.Next(-1) = 0;

            if TaxOnTaxCalculated and CalculationOrderViolation then
                Error(
                  Text000,
                  TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
                  TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
        end;

        i := 1;
        Found := false;
        while i < Steps do begin
            MaxTaxAmount := (1 + Inclination[i]) * MaxRangeAmount[i] + Constant[i];
            if Abs(TotalAmount) < MaxTaxAmount then begin
                if TotalAmount = 0 then
                    Amount := 0
                else
                    Amount :=
                      (Abs(TotalAmount) / TotalAmount) *
                      ((Abs(TotalAmount) - Constant[i]) / (1 + Inclination[i]));
                i := Steps;
                Found := true;
            end;
            i := i + 1;
        end;

        if not Found then
            if TotalAmount = 0 then
                Amount := 0
            else
                Amount :=
                  (Abs(TotalAmount) / TotalAmount) *
                  (Abs(TotalAmount) - Constant[Steps]) / (1 + Inclination[Steps]);

        Amount := Amount * ExchangeFactor;
    end;

    procedure InitSalesTaxLines(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Amount: Decimal; Quantity: Decimal; Date: Date; DesiredTaxAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        MaxAmount: Decimal;
        TaxAmount: Decimal;
        AddedTaxAmount: Decimal;
        TaxBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitSalesTaxLines(TaxAreaCode, TaxGroupCode, TaxLiable, Amount, Quantity, Date, DesiredTaxAmount, TempTaxDetail, IsHandled, Initialised, FirstLine, TotalForAllocation);
        if IsHandled then
            exit;

        TaxAmount := 0;

        Initialised := true;
        FirstLine := true;
        TempTaxDetail.DeleteAll();

        RemainingTaxDetails := 0;

        if (TaxAreaCode = '') or (TaxGroupCode = '') then
            exit;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                TaxDetail.Reset();
                TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if TaxGroupCode = '' then
                    TaxDetail.SetFilter("Tax Group Code", '%1', TaxGroupCode)
                else
                    TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', TaxGroupCode);
                if Date = 0D then
                    TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate())
                else
                    TaxDetail.SetFilter("Effective Date", '<=%1', Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales Tax");
                if TaxDetail.FindLast() and ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    if TaxLiable then begin
                        if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then
                            AddedTaxAmount := TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100
                        else begin
                            MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              ((MaxAmount * TaxDetail."Tax Below Maximum") +
                               ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        end;
                    end else
                        AddedTaxAmount := 0;
                    TaxAmount := TaxAmount + AddedTaxAmount;
                    TempTaxDetail := TaxDetail;
                    TempTaxDetail."Tax Below Maximum" := AddedTaxAmount;
                    TempTaxDetail."Tax Above Maximum" := TaxBaseAmount;
                    TempTaxDetail.Insert();
                    RemainingTaxDetails := RemainingTaxDetails + 1;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) then begin
                    if TaxLiable then begin
                        if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then
                            AddedTaxAmount := Quantity * TaxDetail."Tax Below Maximum"
                        else begin
                            MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              (MaxAmount * TaxDetail."Tax Below Maximum") +
                              ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        end;
                    end else
                        AddedTaxAmount := 0;
                    TaxAmount := TaxAmount + AddedTaxAmount;
                    TempTaxDetail := TaxDetail;
                    TempTaxDetail."Tax Below Maximum" := AddedTaxAmount;
                    TempTaxDetail."Tax Above Maximum" := TaxBaseAmount;
                    TempTaxDetail.Insert();
                    RemainingTaxDetails := RemainingTaxDetails + 1;
                end;
            until TaxAreaLine.Next(-1) = 0;

            TaxAmount := Round(TaxAmount);

            if (TaxAmount <> DesiredTaxAmount) and (Abs(TaxAmount - DesiredTaxAmount) <= 0.01) then
                if TempTaxDetail.Find('-') then begin
                    TempTaxDetail."Tax Below Maximum" :=
                      TempTaxDetail."Tax Below Maximum" - TaxAmount + DesiredTaxAmount;
                    TempTaxDetail.Modify();
                    TaxAmount := DesiredTaxAmount;
                end;

            if TaxOnTaxCalculated and CalculationOrderViolation then
                Error(
                  Text000,
                  TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
                  TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
        end;

        if TaxAmount <> DesiredTaxAmount then
            Error(
              Text001 +
              Text004,
              TaxAreaCode, GenJnlLine.FieldCaption("Tax Area Code"),
              TaxGroupCode, GenJnlLine.FieldCaption("Tax Group Code"),
              TaxAmount, DesiredTaxAmount);

        TotalForAllocation := DesiredTaxAmount;
    end;

    procedure GetSalesTaxLine(var TaxDetail2: Record "Tax Detail"; var ReturnTaxAmount: Decimal; var ReturnTaxBaseAmount: Decimal): Boolean
    var
        TaxAmount: Decimal;
    begin
        ReturnTaxAmount := 0;

        if not Initialised then
            Error(Text003);

        if FirstLine then begin
            if not TempTaxDetail.Find('-') then begin
                Initialised := false;
                exit(false);
            end;
            TotalTaxAmountRounding := 0;
            FirstLine := false;
        end else
            if TempTaxDetail.Next() = 0 then begin
                Initialised := false;
                exit(false);
            end;

        ReturnTaxBaseAmount := Round(TempTaxDetail."Tax Above Maximum");

        TaxAmount := TempTaxDetail."Tax Below Maximum";
        ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding);
        TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;

        if RemainingTaxDetails = 0 then
            TaxAmount := TotalForAllocation
        else
            if Abs(TaxAmount) > Abs(TotalForAllocation) then
                TaxAmount := TotalForAllocation;

        TotalForAllocation := TotalForAllocation - TaxAmount;

        TaxDetail2 := TempTaxDetail;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTaxProcedure(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal; var TaxAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSalesTaxLines(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; TaxLiable: Boolean; Amount: Decimal; Quantity: Decimal; Date: Date; DesiredTaxAmount: Decimal; var TMPTaxDetail: Record "Tax Detail"; var IsHandled: Boolean; var Initialised: Boolean; var FirstLine: Boolean; var TotalForAllocation: Decimal)
    begin
    end;
}

