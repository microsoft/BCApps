// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Provides comprehensive sales tax calculation functionality for transactions.
/// Handles complex tax scenarios including tax-on-tax calculations and multi-jurisdictional rates.
/// </summary>
codeunit 398 "Sales Tax Calculate"
{
    Permissions = TableData "Sales Header" = rim,
                  TableData "Sales Line" = rim,
                  TableData "Purchase Header" = rim,
                  TableData "Purchase Line" = rim;

    trigger OnRun()
    begin
    end;

    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TempTaxDetail: Record "Tax Detail" temporary;
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        TempSalesHeader: Record "Sales Header" temporary;
        PurchHeader: Record "Purchase Header";
#if not CLEAN28
        ServiceHeader: Record Microsoft.Service.Document."Service Header";
#endif
        TaxAmountDifference: Record "Sales Tax Amount Difference";
        TempTaxAmountDifference: Record "Sales Tax Amount Difference" temporary;
        TempTaxDetailMaximums: Record "Tax Detail" temporary;
        ExchangeFactor: Decimal;
        TotalTaxAmountRounding: Decimal;
        TotalForAllocation: Decimal;
        RemainingTaxDetails: Integer;
        LastCalculationOrder: Integer;
        Initialised: Boolean;
        FirstLine: Boolean;
        TaxOnTaxCalculated: Boolean;
        CalculationOrderViolation: Boolean;
        SalesHeaderRead: Boolean;
        PurchHeaderRead: Boolean;
        ServHeaderRead: Boolean;
        TaxAreaRead: Boolean;
        RoundByJurisdiction: Boolean;
        TaxCountry: Enum "Sales Tax Country";
        IsTotalTaxAmountRoundingSpecified: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        MissingTaxAreaValuesErr: Label '%1 in %2 %3 must be filled in with unique values when %4 is %5.';
        SalesTaxAmountIncorrectErr: Label 'The sales tax amount for the %1 %2 and the %3 %4 is incorrect. The calculated sales tax amount is %5, but was supposed to be %6.';
        Text003: Label 'Lines is not initialized';
        Text1020000: Label 'Tax country/region %1 is being used.  You must use %2.';
        Text1020001: Label 'Note to Programmers: The function "CopyTaxDifferences" must not be called unless the function "EndSalesTaxCalculation", or the function "PutSalesTaxAmountLineTable", is called first.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ExternalTaxEngine: Interface "External Tax Engine";
        ExternalTaxEngineInitialized: Boolean;

    procedure InitializeExternalTaxEngine()
    begin
        ExternalTaxEngine := "External Tax Engine"::Default;
        ExternalTaxEngineInitialized := true;
        OnAfterInitializeExternalTaxEngine(ExternalTaxEngine);
    end;

    procedure CallExternalTaxEngineForDoc(DocTable: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]) STETransactionID: Text[20]
    begin
        if not ExternalTaxEngineInitialized then
            InitializeExternalTaxEngine();
        STETransactionID := ExternalTaxEngine.CallExternalTaxEngineForDoc(DocTable, DocType, DocNo);
    end;

    procedure CallExternalTaxEngineForJnl(var GenJnlLine: Record "Gen. Journal Line"; CalculationType: Option Normal,Reverse,Expense): Decimal
    begin
        if not ExternalTaxEngineInitialized then
            InitializeExternalTaxEngine();
        exit(ExternalTaxEngine.CallExternalTaxEngineForJnl(GenJnlLine, CalculationType));
    end;

    procedure CallExternalTaxEngineForSales(var SalesHeader2: Record "Sales Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        OldTransactionID := SalesHeader2."STE Transaction ID";
        SalesHeader2."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Sales Header", SalesHeader2."Document Type".AsInteger(), SalesHeader2."No.");
        STETransactionIDChanged := (SalesHeader2."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            SalesHeader2.Modify();
    end;

    procedure CallExternalTaxEngineForPurch(var PurchHeader2: Record "Purchase Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        OldTransactionID := PurchHeader2."STE Transaction ID";
        PurchHeader2."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Purchase Header", PurchHeader2."Document Type".AsInteger(), PurchHeader2."No.");
        STETransactionIDChanged := (PurchHeader2."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            PurchHeader2.Modify();
    end;

#if not CLEAN28
    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    procedure CallExternalTaxEngineForServ(var ServiceHeader2: Record Microsoft.Service.Document."Service Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        OldTransactionID := ServiceHeader2."STE Transaction ID";
        ServiceHeader2."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::Microsoft.Service.Document."Service Header", ServiceHeader2."Document Type".AsInteger(), ServiceHeader2."No.");
        STETransactionIDChanged := (ServiceHeader2."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            ServiceHeader2.Modify();
    end;
#endif

    procedure FinalizeExternalTaxCalcForDoc(DocTable: Integer; DocNo: Code[20])
    begin
        if not ExternalTaxEngineInitialized then
            InitializeExternalTaxEngine();
        ExternalTaxEngine.FinalizeExternalTaxCalcForDoc(DocTable, DocNo);
    end;

    procedure FinalizeExternalTaxCalcForJnl(var GLEntry: Record "G/L Entry")
    begin
        if not ExternalTaxEngineInitialized then
            InitializeExternalTaxEngine();
        ExternalTaxEngine.FinalizeExternalTaxCalcForJnl(GLEntry);
    end;

    procedure CalcSalesTaxAmountLine(
        var SalesTaxAmountLine: Record "Sales Tax Amount Line"; TaxCountry2: Enum "Sales Tax Country"; ExchangeFactor2: Decimal;
        TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; LineType: Integer; LineAmount: Decimal; VATBaseAmount: Decimal; LineQuantity: Decimal; PostingDate: Date; TaxLiable: Boolean; UseTax: Boolean;
        DocumentArea: Enum "Sales Tax Document Area")
    var
        TaxArea2: Record "Tax Area";
        TaxAreaLine2: Record "Tax Area Line";
        TaxJurisdiction2: Record "Tax Jurisdiction";
    begin
        SalesTaxAmountLine.Reset();
        if (LineType <> 0) and (TaxAreaCode <> '') then begin
            TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
            TaxAreaLine2.SetRange("Tax Area", TaxAreaCode);
            TaxAreaLine2.FindSet();
            repeat
                case TaxCountry2 of
                    TaxCountry2::US:
                        SalesTaxAmountLine.SetRange("Tax Area Code for Key", TaxAreaCode); // Area Code
                    TaxCountry2::CA:
                        SalesTaxAmountLine.SetRange("Tax Area Code for Key", ''); // Jurisdictions
                end;
                SalesTaxAmountLine.SetRange("Tax Group Code", TaxGroupCode);
                SalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine2."Tax Jurisdiction Code");
                if DocumentArea = DocumentArea::"Posted Purchase" then
                    SalesTaxAmountLine.SetRange("Use Tax", UseTax);
                if not SalesTaxAmountLine.FindFirst() then begin
                    SalesTaxAmountLine.Init();
                    case TaxCountry2 of
                        TaxCountry2::US:
                            SalesTaxAmountLine."Tax Area Code for Key" := TaxAreaCode; // Area Code
                        TaxCountry2::CA:
                            SalesTaxAmountLine."Tax Area Code for Key" := ''; // Jurisdictions
                    end;
                    SalesTaxAmountLine."Tax Group Code" := TaxGroupCode;
                    SalesTaxAmountLine."Tax Area Code" := TaxAreaCode;
                    SalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine2."Tax Jurisdiction Code";
                    if TaxCountry2 = TaxCountry2::US then begin
                        if SalesTaxAmountLine."Tax Area Code" <> TaxArea2.Code then
                            TaxArea2.Get(SalesTaxAmountLine."Tax Area Code");
                        SalesTaxAmountLine."Round Tax" := TaxArea2."Round Tax";
                        if SalesTaxAmountLine."Tax Jurisdiction Code" <> TaxJurisdiction2.Code then
                            TaxJurisdiction2.Get(SalesTaxAmountLine."Tax Jurisdiction Code");
                        SalesTaxAmountLine."Is Report-to Jurisdiction" :=
                          (SalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction2."Report-to Jurisdiction");
                    end;
                    SalesTaxAmountLine."Line Amount" := LineAmount / ExchangeFactor2;
                    SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor2, false);
                    SalesTaxAmountLine.Quantity := LineQuantity;
                    SalesTaxAmountLine."Tax Liable" := TaxLiable;

                    case DocumentArea of
                        DocumentArea::"Posted Sale",
                        DocumentArea::"Posted Service":
                            SalesTaxAmountLine.Positive := LineAmount > 0;
                        DocumentArea::"Posted Purchase":
                            begin
                                SalesTaxAmountLine."Use Tax" := UseTax;
                                TaxDetail.Reset();
                                TaxDetail.SetRange("Tax Jurisdiction Code", SalesTaxAmountLine."Tax Jurisdiction Code");
                                if SalesTaxAmountLine."Tax Group Code" = '' then
                                    TaxDetail.SetFilter("Tax Group Code", '%1', SalesTaxAmountLine."Tax Group Code")
                                else
                                    TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', SalesTaxAmountLine."Tax Group Code");
                                if PostingDate = 0D then
                                    TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate())
                                else
                                    TaxDetail.SetFilter("Effective Date", '<=%1', PostingDate);
                                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                                TaxDetail."Tax Type"::"Sales Tax Only");
                                if TaxDetail.FindLast() then
                                    SalesTaxAmountLine."Expense/Capitalize" := TaxDetail."Expense/Capitalize";
                            end;
                    end;

                    SalesTaxAmountLine."Calculation Order" := TaxAreaLine2."Calculation Order";
                    SalesTaxAmountLine.Insert();
                end else begin
                    SalesTaxAmountLine."Line Amount" := SalesTaxAmountLine."Line Amount" + (LineAmount / ExchangeFactor2);
                    SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor2, true);
                    SalesTaxAmountLine.Quantity := SalesTaxAmountLine.Quantity + LineQuantity;
                    if TaxLiable then
                        SalesTaxAmountLine."Tax Liable" := TaxLiable;
                    SalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine2.Next() = 0;
        end;
    end;

    local procedure SetTaxBaseAmount(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; Value: Decimal; ExchangeFactor2: Decimal; Increment: Boolean)
    begin
        if Increment then
            SalesTaxAmountLine."Tax Base Amount FCY" += Value
        else
            SalesTaxAmountLine."Tax Base Amount FCY" := Value;
        SalesTaxAmountLine."Tax Base Amount" := SalesTaxAmountLine."Tax Base Amount FCY" / ExchangeFactor2;
    end;

    /// <summary>
    /// Calculates total sales tax amount for a transaction based on tax area and group codes.
    /// Handles multiple jurisdictions, tax-on-tax scenarios, and currency conversion.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code determining applicable jurisdictions</param>
    /// <param name="TaxGroupCode">Tax group code for item classification</param>
    /// <param name="TaxLiable">Whether the transaction is subject to tax</param>
    /// <param name="Date">Transaction date for tax rate lookup</param>
    /// <param name="Amount">Transaction amount for tax calculation</param>
    /// <param name="Quantity">Transaction quantity for quantity-based taxes</param>
    /// <param name="ExchangeRate">Currency exchange rate for foreign transactions</param>
    /// <returns>Total calculated tax amount</returns>
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
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                  TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast() and not TaxDetail."Expense/Capitalize" then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    // This code uses a temporary table to keep track of Maximums.
                    // This temporary table should be cleared before the first call
                    // to this routine.  All subsequent calls will use the values in
                    // that get put into this temporary table.
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - TaxBaseAmount;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and not TaxDetail."Expense/Capitalize" then begin
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum";
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;
        TaxAmount := TaxAmount * ExchangeFactor;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            ShowMissingTaxAreaValuesErr(TaxAreaLine, CalculationOrderViolation);
    end;

    /// <summary>
    /// Reverse calculates the net amount from a total amount including tax.
    /// Determines the base amount when given an amount that includes sales tax.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code for jurisdiction determination</param>
    /// <param name="TaxGroupCode">Tax group code for item classification</param>
    /// <param name="TaxLiable">Whether the transaction is subject to tax</param>
    /// <param name="Date">Transaction date for tax rate lookup</param>
    /// <param name="TotalAmount">Total amount including tax</param>
    /// <param name="Quantity">Transaction quantity for quantity-based taxes</param>
    /// <param name="ExchangeRate">Currency exchange rate for foreign transactions</param>
    /// <returns>Net amount excluding tax</returns>
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
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                  TaxDetail."Tax Type"::"Sales Tax Only");
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
        end;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            ShowMissingTaxAreaValuesErr(TaxAreaLine, CalculationOrderViolation);

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

    /// <summary>
    /// Initializes detailed sales tax lines for allocation across multiple tax jurisdictions.
    /// Prepares temporary tax detail records for posting and distribution calculations.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code determining jurisdictions</param>
    /// <param name="TaxGroupCode">Tax group code for item classification</param>
    /// <param name="TaxLiable">Whether the transaction is subject to tax</param>
    /// <param name="Amount">Transaction amount for tax calculation</param>
    /// <param name="Quantity">Transaction quantity for quantity-based taxes</param>
    /// <param name="Date">Transaction date for tax rate lookup</param>
    /// <param name="DesiredTaxAmount">Target tax amount for reconciliation</param>
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
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                  TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast() and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    if TaxLiable then begin
                        // This code uses a temporary table to keep track of Maximums.
                        // This temporary table should be cleared before the first call
                        // to this routine.  All subsequent calls will use the values in
                        // that get put into this temporary table.

                        TempTaxDetailMaximums := TaxDetail;
                        if not TempTaxDetailMaximums.Find() then
                            TempTaxDetailMaximums.Insert();

                        if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            AddedTaxAmount := TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                            TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                            TempTaxDetailMaximums.Modify();
                        end else begin
                            MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              ((MaxAmount * TaxDetail."Tax Below Maximum") +
                               ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                            TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                            TempTaxDetailMaximums.Modify();
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
                if TaxDetail.FindLast() and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then begin
                    if TaxLiable then begin
                        TempTaxDetailMaximums := TaxDetail;
                        if not TempTaxDetailMaximums.Find() then
                            TempTaxDetailMaximums.Insert();
                        if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            AddedTaxAmount := Quantity * TaxDetail."Tax Below Maximum";
                            TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                            TempTaxDetailMaximums.Modify();
                        end else begin
                            MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              (MaxAmount * TaxDetail."Tax Below Maximum") +
                              ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                            TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                            TempTaxDetailMaximums.Modify();
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
        end;

        TaxAmount := Round(TaxAmount);

        if (TaxAmount <> DesiredTaxAmount) and (Abs(TaxAmount - DesiredTaxAmount) <= 0.01) then
            if TempTaxDetail.FindSet(true) then begin
                TempTaxDetail."Tax Below Maximum" :=
                  TempTaxDetail."Tax Below Maximum" - TaxAmount + DesiredTaxAmount;
                TempTaxDetail.Modify();
                TaxAmount := DesiredTaxAmount;
            end;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            ShowMissingTaxAreaValuesErr(TaxAreaLine, CalculationOrderViolation);

        if TaxAmount <> DesiredTaxAmount then
            Error(
              SalesTaxAmountIncorrectErr,
              TaxAreaCode, GenJnlLine.FieldCaption("Tax Area Code"),
              TaxGroupCode, GenJnlLine.FieldCaption("Tax Group Code"),
              TaxAmount, DesiredTaxAmount);

        TotalForAllocation := DesiredTaxAmount;
    end;

    procedure HasExciseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Quantity: Decimal; Date: Date): Boolean
    begin
        if (TaxAreaCode = '') or (TaxGroupCode = '') or not TaxLiable then
            exit(false);

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then
            repeat
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then
                        exit(true);
            until TaxAreaLine.Next(-1) = 0;

        exit(false);
    end;

    /// <summary>
    /// Retrieves the next sales tax line from initialized tax details for posting allocation.
    /// Returns individual tax jurisdiction amounts with proper rounding adjustments.
    /// </summary>
    /// <param name="TaxDetail2">Tax detail record to populate with current line</param>
    /// <param name="ReturnTaxAmount">Calculated tax amount for this jurisdiction</param>
    /// <param name="ReturnTaxBaseAmount">Base amount for tax calculation</param>
    /// <returns>True if a tax line was retrieved, false if no more lines</returns>
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
        if TaxAmount <> 0 then begin
            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding);
            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
        end;

        if RemainingTaxDetails = 0 then
            TaxAmount := TotalForAllocation
        else
            if Abs(TaxAmount) > Abs(TotalForAllocation) then
                TaxAmount := TotalForAllocation;

        TotalForAllocation := TotalForAllocation - TaxAmount;
        if TempTaxDetail."Tax Below Maximum" = 0 then
            ReturnTaxAmount := 0;

        TaxDetail2 := TempTaxDetail;

        exit(true);
    end;

    procedure ClearMaximums()
    begin
        TempTaxDetailMaximums.DeleteAll();
    end;

    procedure StartSalesTaxCalculation()
    begin
        OnBeforeStartSalestaxCalculation();

        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.DeleteAll();
        TempTaxAmountDifference.Reset();
        TempTaxAmountDifference.DeleteAll();
        ClearAll();
    end;

    internal procedure SetTmpSalesHeader(SalesHeader2: Record "Sales Header")
    begin
        TempSalesHeader.DeleteAll();
        TempSalesHeader.Copy(SalesHeader2);
        TempSalesHeader.Insert();
    end;

    procedure AddSalesLine(SalesLine: Record "Sales Line")
    var
        TotalPositive: Boolean;
        SalesLinePositive: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if not SalesHeaderRead then begin
            if TempSalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                SalesHeader := TempSalesHeader
            else
                SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            SalesHeaderRead := true;
            SalesHeader.TestField("Prices Including VAT", false);
            if not GetSalesTaxCountry(SalesHeader."Tax Area Code") then
                exit;
            SetUpCurrency(SalesHeader."Currency Code");
            if SalesHeader."Currency Code" <> '' then
                SalesHeader.TestField("Currency Factor");
            if SalesHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := SalesHeader."Currency Factor";
            CopyTaxDifferencesToTemp(
                Enum::"Sales Tax Document Area"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.");
            SalesHeader.CalcFields(Amount);
        end;
        if not GetSalesTaxCountry(SalesLine."Tax Area Code") then
            exit;

        SalesLine.TestField("Tax Group Code");
        TempSalesTaxAmountLine.Reset();
        case TaxCountry of
            TaxCountry::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", SalesLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := SalesLine."Tax Area Code";
                end;
            TaxCountry::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", SalesLine."Tax Group Code");
        OnAddSalesLineOnAfterTempSalesTaxAmountLineSetFilters(TempSalesTaxAmountLine);

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", SalesLine."Tax Area Code");

        TotalPositive := SalesHeader.Amount > 0;
        SalesLinePositive := SalesLine."Line Amount" > 0;
        TaxDetail.SetRange("Tax Group Code", SalesLine."Tax Group Code");
        TaxDetail.SetFilter("Effective Date", '<=%1', SalesHeader."Posting Date");

        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";

                TempSalesTaxAmountLine.SetRange(Positive, SalesLinePositive);
                TempSalesTaxAmountLine.Positive := SalesLinePositive;
                TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if (TotalPositive <> SalesLinePositive) and (SalesHeader.Amount <> 0) then
                    if TaxDetail.FindLast() then
                        if TaxDetail."Maximum Amount/Qty." <> 0 then begin
                            TempSalesTaxAmountLine.SetRange(Positive, TotalPositive);
                            TempSalesTaxAmountLine.Positive := TotalPositive;
                        end;

                OnAddSalesLineOnAfterSetSalesTaxAmountLineFilter(TempSalesTaxAmountLine, SalesLine, TaxAreaLine);
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := SalesLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := SalesLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := SalesLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := SalesLine."Tax Liable";
                    TempSalesTaxAmountLine.Quantity := SalesLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := SalesLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    OnAddSalesLineOnBeforeTempSalesTaxAmountLineInsert(TempSalesTaxAmountLine, SalesLine);
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (SalesLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := SalesLine."Tax Liable";
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + SalesLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + SalesLine."Inv. Discount Amount";
                    OnAddSalesLineOnBeforeModifySalesTaxAmountLine(TempSalesTaxAmountLine, SalesLine);
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;

        OnAfterAddSalesLine(TempSalesTaxAmountLine, SalesLine, SalesHeader, ExchangeFactor);
    end;

    procedure AddSalesInvoiceLines(DocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(SalesInvoiceHeader."Tax Area Code") then
            exit;
        SetUpCurrency(SalesInvoiceHeader."Currency Code");
        if SalesInvoiceHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := SalesInvoiceHeader."Currency Factor";

        SalesInvoiceLine.SetRange("Document No.", DocNo);
        SalesInvoiceLine.SetFilter("Tax Group Code", '<>%1', '');
        if SalesInvoiceLine.FindSet() then
            repeat
                SalesInvoiceLine.TestField("Tax Group Code");
                CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, TaxCountry, ExchangeFactor,
                    SalesInvoiceLine."Tax Area Code", SalesInvoiceLine."Tax Group Code", SalesInvoiceLine.Type.AsInteger(),
                    SalesInvoiceLine."Line Amount", SalesInvoiceLine."VAT Base Amount", SalesInvoiceLine."Quantity (Base)",
                    SalesInvoiceLine."Posting Date", SalesInvoiceLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Sale");
            until SalesInvoiceLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Sale", TaxAmountDifference."Document Type"::Invoice, SalesInvoiceHeader."No.");
    end;

    procedure AddSalesCrMemoLines(DocNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.Get(DocNo);
        SalesCrMemoHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(SalesCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(SalesCrMemoHeader."Currency Code");
        if SalesCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := SalesCrMemoHeader."Currency Factor";

        SalesCrMemoLine.SetRange("Document No.", DocNo);
        SalesCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesCrMemoLine.TestField("Tax Group Code");
                CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, TaxCountry, ExchangeFactor,
                    SalesCrMemoLine."Tax Area Code", SalesCrMemoLine."Tax Group Code", SalesCrMemoLine.Type.AsInteger(),
                    SalesCrMemoLine."Line Amount", SalesCrMemoLine."VAT Base Amount", SalesCrMemoLine."Quantity (Base)",
                    SalesCrMemoLine."Posting Date", SalesCrMemoLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Sale");
            until SalesCrMemoLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Sale", TaxAmountDifference."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
    end;

    procedure AddPurchLine(PurchLine: Record "Purchase Line")
    var
        TaxDetail2: Record "Tax Detail";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddPurchLine(PurchLine, IsHandled);
        if IsHandled then
            exit;

        if not PurchHeaderRead then begin
            PurchLine.GetPurchHeader();
            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
            PurchHeaderRead := true;
            PurchHeader.TestField("Prices Including VAT", false);
            if not GetSalesTaxCountry(PurchHeader."Tax Area Code") then
                exit;
            SetUpCurrency(PurchHeader."Currency Code");
            if PurchHeader."Currency Code" <> '' then
                PurchHeader.TestField("Currency Factor");
            if PurchHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := PurchHeader."Currency Factor";
            CopyTaxDifferencesToTemp(Enum::"Sales Tax Document Area"::Purchase, PurchLine."Document Type".AsInteger(), PurchLine."Document No.");
        end;
        if not GetSalesTaxCountry(PurchLine."Tax Area Code") then
            exit;

        PurchLine.TestField("Tax Group Code");

        TempSalesTaxAmountLine.Reset();
        case TaxCountry of
            TaxCountry::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", PurchLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := PurchLine."Tax Area Code";
                end;
            TaxCountry::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", PurchLine."Tax Group Code");
        TempSalesTaxAmountLine.SetRange("Use Tax", PurchLine."Use Tax");
        OnAddPurchLineOnAfterTempSalesTaxAmountLineSetFilters(TempSalesTaxAmountLine);

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", PurchLine."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := PurchLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := PurchLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := PurchLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := PurchLine."Tax Liable";
                    TempSalesTaxAmountLine."Use Tax" := PurchLine."Use Tax";
                    SetTaxDetailFilter(TaxDetail2, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", PurchHeader."Posting Date");
                    if TempSalesTaxAmountLine."Use Tax" then
                        TaxDetail2.SetFilter("Tax Type", '%1|%2', TaxDetail2."Tax Type"::"Sales and Use Tax",
                          TaxDetail2."Tax Type"::"Use Tax Only")
                    else
                        TaxDetail2.SetFilter("Tax Type", '%1|%2', TaxDetail2."Tax Type"::"Sales and Use Tax",
                          TaxDetail2."Tax Type"::"Sales Tax Only");

                    if TaxDetail2.FindLast() then
                        TempSalesTaxAmountLine."Expense/Capitalize" := TaxDetail2."Expense/Capitalize";

                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    TempSalesTaxAmountLine.Quantity := PurchLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := PurchLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (PurchLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := PurchLine."Tax Liable";
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + PurchLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + PurchLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;

        OnAfterAddPurchLine(TempSalesTaxAmountLine, PurchLine, PurchHeader, ExchangeFactor);
    end;

    procedure AddPurchInvoiceLines(DocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.Get(DocNo);
        PurchInvHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(PurchInvHeader."Tax Area Code") then
            exit;
        SetUpCurrency(PurchInvHeader."Currency Code");
        if PurchInvHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchInvHeader."Currency Factor";

        PurchInvLine.SetRange("Document No.", DocNo);
        PurchInvLine.SetFilter("Tax Group Code", '<>%1', '');
        if PurchInvLine.FindSet() then
            repeat
                PurchInvLine.TestField("Tax Group Code");
                CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, TaxCountry, ExchangeFactor,
                    PurchInvLine."Tax Area Code", PurchInvLine."Tax Group Code", PurchInvLine.Type.AsInteger(),
                    PurchInvLine."Line Amount", PurchInvLine."VAT Base Amount", PurchInvLine."Quantity (Base)",
                    PurchInvLine."Posting Date", PurchInvLine."Tax Liable", PurchInvLine."Use Tax", "Sales Tax Document Area"::"Posted Purchase");
                OnAddPurchInvoiceLinesOnAfterCalcPurchLineSalesTaxAmountLine(TempSalesTaxAmountLine, PurchInvLine, PurchInvHeader, ExchangeFactor);
            until PurchInvLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Purchase", TaxAmountDifference."Document Type"::Invoice, PurchInvHeader."No.");
    end;

    procedure AddPurchCrMemoLines(DocNo: Code[20])
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHeader.Get(DocNo);
        PurchCrMemoHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(PurchCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(PurchCrMemoHeader."Currency Code");
        if PurchCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchCrMemoHeader."Currency Factor";

        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if PurchCrMemoLine.FindSet() then
            repeat
                PurchCrMemoLine.TestField("Tax Group Code");
                CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, TaxCountry, ExchangeFactor,
                    PurchCrMemoLine."Tax Area Code", PurchCrMemoLine."Tax Group Code", PurchCrMemoLine.Type.AsInteger(),
                    PurchCrMemoLine."Line Amount", PurchCrMemoLine."VAT Base Amount", PurchCrMemoLine."Quantity (Base)",
                    PurchCrMemoLine."Posting Date", PurchCrMemoLine."Tax Liable", PurchCrMemoLine."Use Tax", "Sales Tax Document Area"::"Posted Purchase");
            until PurchCrMemoLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Purchase", TaxAmountDifference."Document Type"::"Credit Memo", PurchCrMemoHeader."No.");
    end;

#if not CLEAN28
    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    procedure AddServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        if not ServHeaderRead then begin
            ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            ServHeaderRead := true;
            ServiceHeader.TestField("Prices Including VAT", false);
            if not GetSalesTaxCountry(ServiceHeader."Tax Area Code") then
                exit;
            SetUpCurrency(ServiceHeader."Currency Code");
            if ServiceHeader."Currency Code" <> '' then
                ServiceHeader.TestField("Currency Factor");
            if ServiceHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := ServiceHeader."Currency Factor";
            CopyTaxDifferencesToTemp(
                Enum::"Sales Tax Document Area"::Service, ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.");
        end;
        if not GetSalesTaxCountry(ServiceLine."Tax Area Code") then
            exit;

        ServiceLine.TestField("Tax Group Code");

        TempSalesTaxAmountLine.Reset();
        case TaxCountry of
            TaxCountry::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", ServiceLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := ServiceLine."Tax Area Code";
                end;
            TaxCountry::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", ServiceLine."Tax Group Code");
        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", ServiceLine."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := ServiceLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := ServiceLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := ServiceLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := ServiceLine."Tax Liable";
                    TempSalesTaxAmountLine.Quantity := ServiceLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := ServiceLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (ServiceLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := ServiceLine."Tax Liable";
                    SetTaxBaseAmount(
                        TempSalesTaxAmountLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + ServiceLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + ServiceLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;
    end;
#endif

#if not CLEAN28
    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    procedure AddServInvoiceLines(DocNo: Code[20])
    var
        ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header";
        ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line";
    begin
        ServiceInvoiceHeader.Get(DocNo);
        ServiceInvoiceHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(ServiceInvoiceHeader."Tax Area Code") then
            exit;
        SetUpCurrency(ServiceInvoiceHeader."Currency Code");
        if ServiceInvoiceHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ServiceInvoiceHeader."Currency Factor";

        ServiceInvoiceLine.SetRange("Document No.", DocNo);
        ServiceInvoiceLine.SetFilter("Tax Group Code", '<>%1', '');
        if ServiceInvoiceLine.FindSet() then
            repeat
                ServiceInvoiceLine.TestField("Tax Group Code");
                CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, TaxCountry, ExchangeFactor,
                    ServiceInvoiceLine."Tax Area Code", ServiceInvoiceLine."Tax Group Code", ServiceInvoiceLine.Type.AsInteger(),
                    ServiceInvoiceLine."Line Amount", ServiceInvoiceLine."VAT Base Amount", ServiceInvoiceLine."Quantity (Base)",
                    ServiceInvoiceLine."Posting Date", ServiceInvoiceLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Service");
            until ServiceInvoiceLine.Next() = 0;

        CopyTaxDifferencesToTemp(
          Enum::"Sales Tax Document Area"::"Posted Service", TaxAmountDifference."Document Type"::Invoice, ServiceInvoiceHeader."No.");
    end;
#endif

#if not CLEAN28
    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    procedure AddServCrMemoLines(DocNo: Code[20])
    var
        ServiceCrMemoHeader: Record Microsoft.Service.History."Service Cr.Memo Header";
        ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line";
    begin
        ServiceCrMemoHeader.Get(DocNo);
        ServiceCrMemoHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(ServiceCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(ServiceCrMemoHeader."Currency Code");
        if ServiceCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ServiceCrMemoHeader."Currency Factor";

        ServiceCrMemoLine.SetRange("Document No.", DocNo);
        ServiceCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if ServiceCrMemoLine.FindSet() then
            repeat
                ServiceCrMemoLine.TestField("Tax Group Code");
                CalcSalesTaxAmountLine(
                    TempSalesTaxAmountLine, TaxCountry, ExchangeFactor,
                    ServiceCrMemoLine."Tax Area Code", ServiceCrMemoLine."Tax Group Code", ServiceCrMemoLine.Type.AsInteger(),
                    ServiceCrMemoLine."Line Amount", ServiceCrMemoLine."VAT Base Amount", ServiceCrMemoLine."Quantity (Base)",
                    ServiceCrMemoLine."Posting Date", ServiceCrMemoLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Service");
            until ServiceCrMemoLine.Next() = 0;

        CopyTaxDifferencesToTemp(
          Enum::"Sales Tax Document Area"::"Posted Service", TaxAmountDifference."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");
    end;
#endif

    procedure EndSalesTaxCalculation(Date: Date)
    var
        TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary;
        TaxDetail2: Record "Tax Detail";
        AddedTaxAmount: Decimal;
        TotalTaxAmount: Decimal;
        MaxAmount: Decimal;
        TaxBaseAmt: Decimal;
        LastTaxAreaCode: Code[20];
        LastTaxType: Integer;
        LastTaxGroupCode: Code[20];
        LastPositive: Boolean;
        RoundTax: Option "To Nearest",Up,Down;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        case true of
            SalesHeaderRead:
                OnBeforeEndSalesTaxCalculationSales(SalesHeader, TempSalesTaxAmountLine, IsHandled);
            PurchHeaderRead:
                OnBeforeEndSalesTaxCalculationPurchase(PurchHeader, TempSalesTaxAmountLine, IsHandled);
#if not CLEAN28
            ServHeaderRead:
                OnBeforeEndSalesTaxCalculationService(ServiceHeader, TempSalesTaxAmountLine, IsHandled);
#endif
        end;
        if IsHandled then
            exit;

        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax");
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                SetTaxDetailFilter(TaxDetail, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
                if TempSalesTaxAmountLine."Use Tax" then
                    TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                      TaxDetail."Tax Type"::"Use Tax Only")
                else
                    TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                      TaxDetail."Tax Type"::"Sales Tax Only");
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() then begin
                    TempSalesTaxAmountLine."Tax Type" := TempSalesTaxAmountLine."Tax Type"::"Excise Tax";
                    TempSalesTaxAmountLine.Insert();
                    TempSalesTaxAmountLine."Tax Type" := TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax";
                end;
            until TempSalesTaxAmountLine.Next() = 0;
        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet(true) then
            repeat
                TempTaxAmountDifference.Reset();
                TempTaxAmountDifference.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code for Key");
                TempTaxAmountDifference.SetRange("Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Jurisdiction Code");
                TempTaxAmountDifference.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                TempTaxAmountDifference.SetRange("Expense/Capitalize", TempSalesTaxAmountLine."Expense/Capitalize");
                TempTaxAmountDifference.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type");
                TempTaxAmountDifference.SetRange("Use Tax", TempSalesTaxAmountLine."Use Tax");
                TempTaxAmountDifference.SetRange(Positive, TempSalesTaxAmountLine.Positive);
                if TempTaxAmountDifference.FindFirst() then begin
                    TempSalesTaxAmountLine."Tax Difference" := TempTaxAmountDifference."Tax Difference";
                    OnEndSalesTaxCalculationOnBeforeTempSalesTaxLineModify(TempSalesTaxAmountLine);
                    TempSalesTaxAmountLine.Modify();
                end;
            until TempSalesTaxAmountLine.Next() = 0;
        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.SetCurrentKey("Tax Area Code for Key", "Tax Group Code", "Tax Type", "Calculation Order");
        if TempSalesTaxAmountLine.FindLast() then begin
            LastTaxAreaCode := TempSalesTaxAmountLine."Tax Area Code for Key";
            LastCalculationOrder := -9999;
            LastTaxType := TempSalesTaxAmountLine."Tax Type";
            LastTaxGroupCode := TempSalesTaxAmountLine."Tax Group Code";
            RoundTax := TempSalesTaxAmountLine."Round Tax";
            repeat
                if (LastTaxAreaCode <> TempSalesTaxAmountLine."Tax Area Code for Key") or
                   (LastTaxGroupCode <> TempSalesTaxAmountLine."Tax Group Code")
                then begin
                    HandleRoundTaxUpOrDown(TempSalesTaxAmountLine2, RoundTax, TotalTaxAmount, LastTaxAreaCode, LastTaxGroupCode);
                    LastTaxAreaCode := TempSalesTaxAmountLine."Tax Area Code for Key";
                    LastTaxType := TempSalesTaxAmountLine."Tax Type";
                    LastTaxGroupCode := TempSalesTaxAmountLine."Tax Group Code";
                    TaxOnTaxCalculated := false;
                    LastCalculationOrder := -9999;
                    CalculationOrderViolation := false;
                    TotalTaxAmount := 0;
                    RoundTax := TempSalesTaxAmountLine."Round Tax";
                end;
                if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                    TaxBaseAmt := TempSalesTaxAmountLine."Tax Base Amount"
                else
                    TaxBaseAmt := TempSalesTaxAmountLine.Quantity;
                if (LastCalculationOrder = TempSalesTaxAmountLine."Calculation Order") and (LastPositive = TempSalesTaxAmountLine.Positive) then
                    CalculationOrderViolation := true;
                LastCalculationOrder := TempSalesTaxAmountLine."Calculation Order";
                LastPositive := TempSalesTaxAmountLine.Positive;

                SetTaxDetailFilter(TaxDetail2, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", Date);
                TaxDetail2.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type");
                if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                    if TempSalesTaxAmountLine."Use Tax" then
                        TaxDetail2.SetFilter("Tax Type", '%1|%2', TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax",
                          TempSalesTaxAmountLine."Tax Type"::"Use Tax Only")
                    else
                        TaxDetail2.SetFilter("Tax Type", '%1|%2', TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax",
                          TempSalesTaxAmountLine."Tax Type"::"Sales Tax Only");
                if TaxDetail2.FindLast() then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail2."Calculate Tax on Tax";
                    if TaxDetail2."Calculate Tax on Tax" and (TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax") then
                        TaxBaseAmt := TempSalesTaxAmountLine."Tax Base Amount" + TotalTaxAmount;
                    if TempSalesTaxAmountLine."Tax Liable" then begin
                        if (Abs(TaxBaseAmt) <= TaxDetail2."Maximum Amount/Qty.") or
                           (TaxDetail2."Maximum Amount/Qty." = 0)
                        then begin
                            if TempSalesTaxAmountLine."Tax Base Amount FCY" <> TempSalesTaxAmountLine."Tax Base Amount" then begin
                                AddedTaxAmount := Round((TempSalesTaxAmountLine."Tax Base Amount FCY" * TaxDetail2."Tax Below Maximum") / 100, Currency."Amount Rounding Precision");
                                AddedTaxAmount := 100 * AddedTaxAmount / ExchangeFactor;
                            end else
                                AddedTaxAmount := TaxBaseAmt * TaxDetail2."Tax Below Maximum"
                        end
                        else begin
                            if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                                MaxAmount := TaxBaseAmt / Abs(TempSalesTaxAmountLine."Tax Base Amount") * TaxDetail2."Maximum Amount/Qty."
                            else
                                MaxAmount := TempSalesTaxAmountLine.Quantity / Abs(TempSalesTaxAmountLine.Quantity) * TaxDetail2."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              (MaxAmount * TaxDetail2."Tax Below Maximum") +
                              ((TaxBaseAmt - MaxAmount) * TaxDetail2."Tax Above Maximum");
                            OnEndSalesTaxCalculationOnAfterCalculateMaxAmount(TempSalesTaxAmountLine, TaxDetail2, MaxAmount, AddedTaxAmount, TaxBaseAmt);
                        end;
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                            AddedTaxAmount := AddedTaxAmount / 100.0;
                    end else
                        AddedTaxAmount := 0;
                    TempSalesTaxAmountLine."Tax Amount" := TempSalesTaxAmountLine."Tax Amount" + AddedTaxAmount;
                    TotalTaxAmount := TotalTaxAmount + AddedTaxAmount;
                end;
                ApplyTaxDifference(TempSalesTaxAmountLine, TotalTaxAmount);
                TempSalesTaxAmountLine."Amount Including Tax" := TempSalesTaxAmountLine."Tax Amount" + TempSalesTaxAmountLine."Tax Base Amount";
                if TaxOnTaxCalculated and CalculationOrderViolation then
                    ShowMissingTaxAreaValuesErr(TaxAreaLine, CalculationOrderViolation);
                OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Copy(TempSalesTaxAmountLine, TaxBaseAmt, AddedTaxAmount, TotalTaxAmount);
                TempSalesTaxAmountLine2.Copy(TempSalesTaxAmountLine);
                if (TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Excise Tax") and not TaxDetail2."Calculate Tax on Tax" then
                    TempSalesTaxAmountLine2."Tax %" := 0
                else
                    if TempSalesTaxAmountLine."Tax Base Amount" <> 0 then
                        TempSalesTaxAmountLine2."Tax %" := 100 * (TempSalesTaxAmountLine."Amount Including Tax" - TempSalesTaxAmountLine."Tax Base Amount") / TempSalesTaxAmountLine."Tax Base Amount"
                    else
                        if (TempSalesTaxAmountLine."Tax %" = 0) and TempSalesTaxAmountLine."Tax Liable" then
                            TempSalesTaxAmountLine2."Tax %" := TaxDetail2."Tax Below Maximum"
                        else
                            TempSalesTaxAmountLine2."Tax %" := TempSalesTaxAmountLine."Tax %";
                OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Insert(TempSalesTaxAmountLine2, TempSalesTaxAmountLine);
                TempSalesTaxAmountLine2.Insert();
            until TempSalesTaxAmountLine.Next(-1) = 0;
            HandleRoundTaxUpOrDown(TempSalesTaxAmountLine2, RoundTax, TotalTaxAmount, LastTaxAreaCode, LastTaxGroupCode);
        end;
        TempSalesTaxAmountLine.DeleteAll();
        TempSalesTaxAmountLine2.Reset();
        if TempSalesTaxAmountLine2.FindSet() then
            repeat
                TempSalesTaxAmountLine.Copy(TempSalesTaxAmountLine2);
                TempSalesTaxAmountLine.Insert();
            until TempSalesTaxAmountLine2.Next() = 0;

        OnAfterEndSalesTaxCalulation(TempSalesTaxAmountLine, SalesHeaderRead, PurchHeaderRead, ServHeaderRead, Date);
    end;

    local procedure ApplyTaxDifference(var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line"; var TotalTaxAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyTaxDifference(TempSalesTaxAmountLine2, IsHandled);
        if IsHandled then
            exit;

        TempSalesTaxAmountLine2."Tax Amount" := TempSalesTaxAmountLine2."Tax Amount" + TempSalesTaxAmountLine2."Tax Difference";
        TotalTaxAmount := TotalTaxAmount + TempSalesTaxAmountLine2."Tax Difference";
    end;

    procedure GetSummarizedSalesTaxTable(var SummarizedSalesTaxAmtLine: Record "Sales Tax Amount Line")
    var
        TaxJurisdiction2: Record "Tax Jurisdiction";
        RemTaxAmt: Decimal;
        PrevTaxJurisdictionCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        case true of
            SalesHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", IsHandled);
            PurchHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.", IsHandled);
#if not CLEAN28
            ServHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::Microsoft.Service.Document."Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", IsHandled);
#endif
        end;
        if IsHandled then
            exit;

        IsHandled := false;
        OnBeforeGetPostedSummarizedSalesTaxTable(SummarizedSalesTaxAmtLine, TempTaxAmountDifference, IsHandled);
        if IsHandled then
            exit;

        Clear(TaxJurisdiction2);
        TempSalesTaxAmountLine.Reset();

        SummarizedSalesTaxAmtLine.DeleteAll();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                Clear(SummarizedSalesTaxAmtLine);
                case TaxCountry of
                    TaxCountry::US:
                        begin
                            SummarizedSalesTaxAmtLine."Tax Area Code for Key" := TempSalesTaxAmountLine."Tax Area Code for Key";
                            if TaxArea.Code <> SummarizedSalesTaxAmtLine."Tax Area Code for Key" then
                                TaxArea.Get(SummarizedSalesTaxAmtLine."Tax Area Code for Key");
                            SummarizedSalesTaxAmtLine."Print Description" := TaxArea.Description;
                        end;
                    TaxCountry::CA:
                        begin
                            SummarizedSalesTaxAmtLine."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                            if TaxJurisdiction2.Code <> SummarizedSalesTaxAmtLine."Tax Jurisdiction Code" then
                                TaxJurisdiction2.Get(SummarizedSalesTaxAmtLine."Tax Jurisdiction Code");
                            SummarizedSalesTaxAmtLine."Print Order" := TaxJurisdiction2."Print Order";
                            SummarizedSalesTaxAmtLine."Print Description" := TaxJurisdiction2."Print Description";
                            if StrPos(SummarizedSalesTaxAmtLine."Print Description", '%1') <> 0 then
                                SummarizedSalesTaxAmtLine."Tax %" := TempSalesTaxAmountLine."Tax %";
                        end;
                end;
                if not SummarizedSalesTaxAmtLine.Find('=') then
                    SummarizedSalesTaxAmtLine.Insert();
                if (TempSalesTaxAmountLine."Tax Difference" <> 0) or
                   (TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Excise Tax")
                then
                    SummarizedSalesTaxAmtLine."Tax Amount" += TempSalesTaxAmountLine."Tax Amount"
                else
                    SummarizedSalesTaxAmtLine."Tax Amount" += TempSalesTaxAmountLine."Tax Base Amount FCY" * TempSalesTaxAmountLine."Tax %" / 100;
                SummarizedSalesTaxAmtLine.Modify();
            until TempSalesTaxAmountLine.Next() = 0;

        SummarizedSalesTaxAmtLine.SetRange("Tax Amount", 0);
        SummarizedSalesTaxAmtLine.DeleteAll();
        SummarizedSalesTaxAmtLine.SetRange("Tax Amount");

        if SummarizedSalesTaxAmtLine.FindSet() then
            repeat
                if (SummarizedSalesTaxAmtLine."Tax Jurisdiction Code" <> PrevTaxJurisdictionCode) and RoundByJurisdiction then begin
                    PrevTaxJurisdictionCode := SummarizedSalesTaxAmtLine."Tax Jurisdiction Code";
                    RemTaxAmt := 0;
                end;
                if TaxCountry = TaxCountry::CA then
                    SummarizedSalesTaxAmtLine."Tax Amount" := Round(SummarizedSalesTaxAmtLine."Tax Amount", Currency."Amount Rounding Precision")
                else begin
                    SummarizedSalesTaxAmtLine."Tax Amount" += RemTaxAmt;
                    RemTaxAmt := SummarizedSalesTaxAmtLine."Tax Amount" - Round(SummarizedSalesTaxAmtLine."Tax Amount", Currency."Amount Rounding Precision");
                    SummarizedSalesTaxAmtLine."Tax Amount" -= RemTaxAmt;
                end;
                SummarizedSalesTaxAmtLine.Modify();
            until SummarizedSalesTaxAmtLine.Next() = 0;

        SummarizedSalesTaxAmtLine.SetRange("Tax Amount", 0);
        SummarizedSalesTaxAmtLine.DeleteAll();
        SummarizedSalesTaxAmtLine.SetRange("Tax Amount");
    end;

    procedure GetSalesTaxAmountLineTable(var TempSalesTaxAmountLineTo: Record "Sales Tax Amount Line" temporary)
    begin
        TempSalesTaxAmountLineTo.DeleteAll();
        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                TempSalesTaxAmountLineTo.Copy(TempSalesTaxAmountLine);
                TempSalesTaxAmountLineTo.Insert();
            until TempSalesTaxAmountLine.Next() = 0;

        OnAfterGetSalesTaxAmountLineTable(TempSalesTaxAmountLineTo);
    end;

    procedure SetSalesTaxAmountLineTable(var TempSalesTaxAmountLineFrom: Record "Sales Tax Amount Line" temporary)
    begin
        TempSalesTaxAmountLine.DeleteAll();
        TempSalesTaxAmountLineFrom.Reset();
        if TempSalesTaxAmountLineFrom.FindSet() then
            repeat
                TempSalesTaxAmountLine.Copy(TempSalesTaxAmountLineFrom);
                TempSalesTaxAmountLine.Insert();
            until TempSalesTaxAmountLineFrom.Next() = 0;
    end;

    procedure PutSalesTaxAmountLineTable(var SalesTaxLine2: Record "Sales Tax Amount Line" temporary; ProductArea: Integer; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.DeleteAll();
        if SalesTaxLine2.FindSet() then
            repeat
                TempSalesTaxAmountLine.Copy(SalesTaxLine2);
                TempSalesTaxAmountLine.Insert();
            until SalesTaxLine2.Next() = 0;

        CreateSingleTaxDifference(
            Enum::"Sales Tax Document Area".FromInteger(ProductArea), DocumentType, DocumentNo);
    end;

    procedure DistTaxOverSalesLines(var SalesLine: Record "Sales Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
        TaxAmount: Decimal;
        Amount: Decimal;
        ReturnTaxAmount: Decimal;
        IsHandled: Boolean;
        SkipCheckTaxAmtLinePos: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverSalesLines(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if not IsTotalTaxAmountRoundingSpecified then
            TotalTaxAmountRounding := 0;

        if not SalesHeaderRead then begin
            if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                exit;
            SalesHeaderRead := true;
            SetUpCurrency(SalesHeader."Currency Code");
            if SalesHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := SalesHeader."Currency Factor";
            if not GetSalesTaxCountry(SalesHeader."Tax Area Code") then
                exit;
        end;
        SalesLine.ModifyAll("VAT %", 0);

        ResetTaxAmountsInSalesLines(SalesLine, SalesHeader."Tax Area Code");

        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                SkipCheckTaxAmtLinePos := false;
                SetTaxDetailFilter(TaxDetail, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", SalesHeader."Posting Date");
                TaxDetail.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type");
                if TaxDetail.FindLast() then
                    if TaxDetail."Maximum Amount/Qty." <> 0 then
                        SkipCheckTaxAmtLinePos := true;

                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                end;
                if TaxCountry = TaxCountry::US then
                    SalesLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                SalesLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                SalesLine.SetCurrentKey(Amount);
                OnDistTaxOverSalesLinesOnAfterSetSalesLineFilters(SalesLine, TempSalesTaxAmountLine);
                SalesLine.FindSet(true);
                repeat
                    if ((TaxCountry = TaxCountry::US) or
                        ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(SalesLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))) and
                       (CheckTaxAmtLinePos(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount",
                          TempSalesTaxAmountLine.Positive) or SkipCheckTaxAmtLinePos)
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount");
                            OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(TempSalesTaxAmountLine, SalesLine, SalesHeader, Amount);
                            if TempSalesTaxAmountLine."Tax Difference" <> 0 then
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax Amount" / TempSalesTaxAmountLine."Tax Base Amount"
                            else
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (SalesLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * SalesLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
                        if TaxAmount = 0 then
                            ReturnTaxAmount := 0
                        else begin
                            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                        end;
                        SalesLine.Amount :=
                          SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
                        SalesLine."VAT Base Amount" := SalesLine.Amount;
                        OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetSalesLineVATBaseAmount(SalesLine, SalesHeader);
                        if TempSalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then begin
                            TempSalesLine2."Amount Including VAT" := TempSalesLine2."Amount Including VAT" + ReturnTaxAmount;
                            TempSalesLine2.Modify();
                        end else begin
                            TempSalesLine2.Copy(SalesLine);
                            TempSalesLine2."Amount Including VAT" := SalesLine.Amount + ReturnTaxAmount;
                            TempSalesLine2.Insert();
                        end;
                        if SalesLine."Tax Liable" then
                            SalesLine."Amount Including VAT" := TempSalesLine2."Amount Including VAT"
                        else
                            SalesLine."Amount Including VAT" := SalesLine.Amount;
                        if SalesLine.Amount <> 0 then
                            SalesLine."VAT %" += TempSalesTaxAmountLine."Tax %"
                        else
                            SalesLine."VAT %" := 0;
                        SalesLine.Modify();
                    end;
                until SalesLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;
        SalesLine.SetRange("Tax Area Code");
        SalesLine.SetRange("Tax Group Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        OnDistTaxOverSalesLinesOnBeforeFindSalesLineAmounts(SalesLine, TempSalesTaxAmountLine);
        if SalesLine.FindSet(true) then
            repeat
                SalesLine."Amount Including VAT" := Round(SalesLine."Amount Including VAT", Currency."Amount Rounding Precision");
                SalesLine.Amount :=
                  Round(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                SalesLine."VAT Base Amount" := SalesLine.Amount;
                OnDistTaxOverSalesLinesOnSalesLineLoopOnAfterSetSalesLineVATBaseAmount(SalesLine, SalesHeader);
                if SalesLine.Quantity = 0 then
                    SalesLine.Validate("Outstanding Amount", SalesLine."Amount Including VAT")
                else
                    SalesLine.Validate(
                      "Outstanding Amount",
                      Round(
                        SalesLine."Amount Including VAT" * SalesLine."Outstanding Quantity" / SalesLine.Quantity,
                        Currency."Amount Rounding Precision"));
                if ((SalesLine."Tax Area Code" = '') and (TempSalesTaxAmountLine."Tax Area Code" <> '')) or (SalesLine."Tax Group Code" = '') then
                    SalesLine."Amount Including VAT" := SalesLine.Amount;
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    procedure DistTaxOverPurchLines(var PurchLine: Record "Purchase Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        TempPurchaseLine2: Record "Purchase Line" temporary;
        TempPurchaseLine3: Record "Purchase Line" temporary;
        TaxAmount: Decimal;
        ReturnTaxAmount: Decimal;
        Amount: Decimal;
        ExpenseTaxAmountRounding: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverPurchLines(PurchLine, IsHandled);
        if IsHandled then
            exit;

        TotalTaxAmountRounding := 0;
        ExpenseTaxAmountRounding := 0;
        if not PurchHeaderRead then begin
            if not PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.") then
                exit;
            PurchHeaderRead := true;
            SetUpCurrency(PurchHeader."Currency Code");
            if PurchHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := PurchHeader."Currency Factor";
            if not GetSalesTaxCountry(PurchHeader."Tax Area Code") then
                exit;
        end;

        ResetTaxAmountsInPurchLines(PurchLine, PurchHeader."Tax Area Code");
        PurchLine.SetPurchHeader(PurchHeader);

        TempSalesTaxAmountLine.Reset();
        // LOCKING
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                    ExpenseTaxAmountRounding := 0;
                end;
                if TaxCountry = TaxCountry::US then
                    PurchLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                PurchLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                PurchLine.SetRange("Use Tax", TempSalesTaxAmountLine."Use Tax");
                PurchLine.SetCurrentKey(Amount);
                OnDistTaxOverPurchLinesOnBeforeFindPurchLineSetTempSalesTaxLineAmount(PurchLine, TempSalesTaxAmountLine);
                PurchLine.FindSet(true);
                repeat
                    if (TaxCountry = TaxCountry::US) or
                       ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(PurchLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (PurchLine."Line Amount" - PurchLine."Inv. Discount Amount");
                            OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(TempSalesTaxAmountLine, PurchLine, PurchHeader, Amount);
                            if (TempSalesTaxAmountLine."Tax Difference" <> 0) and (PurchLine."Selected Alloc. Account No." = '') then
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax Amount" / TempSalesTaxAmountLine."Tax Base Amount"
                            else
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (PurchLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * PurchLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
                        if (PurchLine."Use Tax" or TempSalesTaxAmountLine."Expense/Capitalize") and (TaxAmount <> 0) then begin
                            ExpenseTaxAmountRounding := ExpenseTaxAmountRounding + TaxAmount;
                            if TempPurchaseLine3.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                                TempPurchaseLine3."Tax To Be Expensed" :=
                                  Round(
                                    TempPurchaseLine3."Tax To Be Expensed" + ExpenseTaxAmountRounding,
                                    Currency."Amount Rounding Precision");
                                TempPurchaseLine3.Modify();
                            end else begin
                                TempPurchaseLine3.Copy(PurchLine);
                                TempPurchaseLine3."Tax To Be Expensed" :=
                                   Round(
                                    ExpenseTaxAmountRounding,
                                    Currency."Amount Rounding Precision");
                                TempPurchaseLine3.Insert();
                            end;
                            PurchLine."Tax To Be Expensed" := TempPurchaseLine3."Tax To Be Expensed";
                            ExpenseTaxAmountRounding :=
                              ExpenseTaxAmountRounding -
                              Round(
                                ExpenseTaxAmountRounding,
                                Currency."Amount Rounding Precision");
                        end else begin
                            if not TempPurchaseLine3.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                                TempPurchaseLine3.Copy(PurchLine);
                                TempPurchaseLine3."Tax To Be Expensed" := 0;
                                TempPurchaseLine3.Insert();
                            end;
                            PurchLine."Tax To Be Expensed" := TempPurchaseLine3."Tax To Be Expensed";
                        end;
                        if PurchLine."Use Tax" then
                            TaxAmount := 0;
                        if TaxAmount = 0 then
                            ReturnTaxAmount := 0
                        else begin
                            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                        end;
                        PurchLine.Amount := PurchLine."Line Amount" - PurchLine."Inv. Discount Amount";
                        PurchLine."VAT Base Amount" := PurchLine.Amount;
                        OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetPurchLineVATBaseAmount(PurchLine, PurchHeader);
                        if TempPurchaseLine2.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                            TempPurchaseLine2."Amount Including VAT" := TempPurchaseLine2."Amount Including VAT" + ReturnTaxAmount;
                            TempPurchaseLine2.Modify();
                        end else begin
                            TempPurchaseLine2.Copy(PurchLine);
                            TempPurchaseLine2."Amount Including VAT" := PurchLine.Amount + ReturnTaxAmount;
                            TempPurchaseLine2.Insert();
                        end;
                        if PurchLine."Tax Liable" then
                            PurchLine."Amount Including VAT" := TempPurchaseLine2."Amount Including VAT"
                        else
                            PurchLine."Amount Including VAT" := PurchLine.Amount;
                        UpdatePurchaseLineVatPct(PurchLine);
                        PurchLine.Modify();
                    end;
                until PurchLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;
        PurchLine.SetRange("Tax Area Code");
        PurchLine.SetRange("Tax Group Code");
        PurchLine.SetRange("Use Tax");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnDistTaxOverPurchLinesOnBeforeFindPurchLineAmounts(PurchLine, TempSalesTaxAmountLine);
        if PurchLine.FindSet(true) then
            repeat
                PurchLine."Amount Including VAT" := Round(PurchLine."Amount Including VAT", Currency."Amount Rounding Precision");
                PurchLine.Amount :=
                  Round(PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                PurchLine."VAT Base Amount" := PurchLine.Amount;
                OnDistTaxOverPurchLinesOnPurchLineLoopOnAfterSetPurchLineVATBaseAmount(PurchLine, PurchHeader);
                if PurchLine.Quantity = 0 then
                    PurchLine.Validate("Outstanding Amount", PurchLine."Amount Including VAT")
                else
                    PurchLine.Validate(
                      "Outstanding Amount",
                      Round(
                        PurchLine."Amount Including VAT" * PurchLine."Outstanding Quantity" / PurchLine.Quantity,
                        Currency."Amount Rounding Precision"));
                if ((PurchLine."Tax Area Code" = '') and (TempSalesTaxAmountLine."Tax Area Code" <> '')) or (PurchLine."Tax Group Code" = '') then
                    PurchLine."Amount Including VAT" := PurchLine.Amount;
                if PurchLine.Amount <> 0 then
                    PurchLine.Modify();
            until PurchLine.Next() = 0;
    end;

#if not CLEAN28
    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    procedure DistTaxOverServLines(var ServLine: Record Microsoft.Service.Document."Service Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        TempServiceLine2: Record Microsoft.Service.Document."Service Line" temporary;
        TaxAmount: Decimal;
        Amount: Decimal;
        ReturnTaxAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverServLines(ServLine, IsHandled);
        if IsHandled then
            exit;

        TotalTaxAmountRounding := 0;
        if not ServHeaderRead then begin
            if not ServiceHeader.Get(ServLine."Document Type", ServLine."Document No.") then
                exit;
            ServHeaderRead := true;
            SetUpCurrency(ServiceHeader."Currency Code");
            if ServiceHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := ServiceHeader."Currency Factor";
            if not GetSalesTaxCountry(ServiceHeader."Tax Area Code") then
                exit;
        end;

        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                end;
                if TaxCountry = TaxCountry::US then
                    ServLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                ServLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                ServLine.SetCurrentKey(Amount);
                ServLine.FindSet(true);
                repeat
                    if (TaxCountry = TaxCountry::US) or
                       ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(ServLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (ServLine."Line Amount" - ServLine."Inv. Discount Amount");
                            TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (ServLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * ServLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
                        if TaxAmount = 0 then
                            ReturnTaxAmount := 0
                        else begin
                            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                        end;
                        ServLine.Amount :=
                          ServLine."Line Amount" - ServLine."Inv. Discount Amount";
                        ServLine."VAT Base Amount" := ServLine.Amount;
                        if TempServiceLine2.Get(ServLine."Document Type", ServLine."Document No.", ServLine."Line No.") then begin
                            TempServiceLine2."Amount Including VAT" := TempServiceLine2."Amount Including VAT" + ReturnTaxAmount;
                            TempServiceLine2.Modify();
                        end else begin
                            TempServiceLine2.Copy(ServLine);
                            TempServiceLine2."Amount Including VAT" := ServLine.Amount + ReturnTaxAmount;
                            TempServiceLine2.Insert();
                        end;
                        if ServLine."Tax Liable" then
                            ServLine."Amount Including VAT" := TempServiceLine2."Amount Including VAT"
                        else
                            ServLine."Amount Including VAT" := ServLine.Amount;
                        if ServLine.Amount <> 0 then
                            ServLine."VAT %" :=
                              Round(100 * (ServLine."Amount Including VAT" - ServLine.Amount) / ServLine.Amount, 0.00001)
                        else
                            ServLine."VAT %" := 0;
                        ServLine.Modify();
                    end;
                until ServLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;
        ServLine.SetRange("Tax Area Code");
        ServLine.SetRange("Tax Group Code");
        ServLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServLine.SetRange("Document No.", ServiceHeader."No.");
        if ServLine.FindSet(true) then
            repeat
                ServLine."Amount Including VAT" := Round(ServLine."Amount Including VAT", Currency."Amount Rounding Precision");
                ServLine.Amount :=
                  Round(ServLine."Line Amount" - ServLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                ServLine."VAT Base Amount" := ServLine.Amount;
                ServLine.Modify();
            until ServLine.Next() = 0;
    end;
#endif

    procedure GetSalesTaxCountry(TaxAreaCode: Code[20]): Boolean
    begin
        if TaxAreaCode = '' then
            exit(false);

        if TaxAreaRead then begin
            if TaxAreaCode = TaxArea.Code then
                exit(true);
            if TaxArea.Get(TaxAreaCode) then
                if TaxCountry.AsInteger() <> TaxArea."Country/Region" then  // make sure countries match
                    Error(Text1020000, TaxArea."Country/Region", TaxCountry)
                else
                    exit(true);
        end else
            if TaxArea.Get(TaxAreaCode) then begin
                TaxAreaRead := true;
                TaxCountry := "Sales Tax Country".FromInteger(TaxArea."Country/Region");
                RoundByJurisdiction := TaxArea."Country/Region" = TaxArea."Country/Region"::CA;
                exit(true);
            end;

        exit(false);
    end;

    procedure GetTaxCountry(): Enum "Sales Tax Country"
    begin
        exit(TaxCountry);
    end;

    procedure GetRoundByJurisdiction(): Boolean
    begin
        exit(RoundByJurisdiction);
    end;

    local procedure SetUpCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure ReadTempPurchHeader(TempPurchHeader: Record "Purchase Header" temporary)
    begin
        PurchHeader.Copy(TempPurchHeader);
        if PurchHeader."Tax Area Code" = '' then
            exit;
        PurchHeaderRead := true;
        SetUpCurrency(TempPurchHeader."Currency Code");
        if TempPurchHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchHeader."Currency Factor";
        TempPurchHeader.DeleteAll();

        CreateSingleTaxDifference(
            Enum::"Sales tax Document Area"::Purchase, PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
    end;

    procedure ReadTempSalesHeader(TempSalesHeader2: Record "Sales Header" temporary)
    begin
        SalesHeader.Copy(TempSalesHeader2);
        if SalesHeader."Tax Area Code" = '' then
            exit;
        SalesHeaderRead := true;
        SetUpCurrency(TempSalesHeader2."Currency Code");
        if TempSalesHeader2."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := TempSalesHeader."Currency Factor";
        TempSalesHeader2.DeleteAll();

        CreateSingleTaxDifference(
            Enum::"Sales Tax Document Area"::Sales, SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    procedure CopyTaxDifferencesToTemp(ProductArea: Enum "Sales Tax Document Area"; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TaxAmountDifference.Reset();
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocumentType);
        TaxAmountDifference.SetRange("Document No.", DocumentNo);
        if TaxAmountDifference.FindSet() then
            repeat
                TempTaxAmountDifference := TaxAmountDifference;
                TempTaxAmountDifference.Insert();
            until TaxAmountDifference.Next() = 0
        else
            CreateSingleTaxDifference(ProductArea, DocumentType, DocumentNo);
    end;

    local procedure CreateSingleTaxDifference(ProductArea: Enum "Sales Tax Document Area"; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempTaxAmountDifference.Reset();
        TempTaxAmountDifference.DeleteAll();
        TempTaxAmountDifference.Init();
        TempTaxAmountDifference."Document Product Area" := ProductArea;
        TempTaxAmountDifference."Document Type" := DocumentType;
        TempTaxAmountDifference."Document No." := DocumentNo;
        TempTaxAmountDifference.Insert();
    end;

    procedure SaveTaxDifferences()
    begin
        TempTaxAmountDifference.Reset();
        if not TempTaxAmountDifference.FindFirst() then
            Error(Text1020001);

        TaxAmountDifference.Reset();
        TaxAmountDifference.SetRange("Document Product Area", TempTaxAmountDifference."Document Product Area");
        TaxAmountDifference.SetRange("Document Type", TempTaxAmountDifference."Document Type");
        TaxAmountDifference.SetRange("Document No.", TempTaxAmountDifference."Document No.");
        TaxAmountDifference.DeleteAll();

        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.SetFilter("Tax Difference", '<>0');
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                TaxAmountDifference.Init();
                TaxAmountDifference."Document Product Area" := TempTaxAmountDifference."Document Product Area";
                TaxAmountDifference."Document Type" := TempTaxAmountDifference."Document Type";
                TaxAmountDifference."Document No." := TempTaxAmountDifference."Document No.";
                TaxAmountDifference."Tax Area Code" := TempSalesTaxAmountLine."Tax Area Code for Key";
                TaxAmountDifference."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                if TempSalesTaxAmountLine.Positive then
                    TaxAmountDifference."Tax %" := TempSalesTaxAmountLine."Tax %"
                else
                    TaxAmountDifference."Tax %" := -TempSalesTaxAmountLine."Tax %";
                TaxAmountDifference."Tax Group Code" := TempSalesTaxAmountLine."Tax Group Code";
                TaxAmountDifference."Expense/Capitalize" := TempSalesTaxAmountLine."Expense/Capitalize";
                TaxAmountDifference."Tax Type" := TempSalesTaxAmountLine."Tax Type";
                TaxAmountDifference."Use Tax" := TempSalesTaxAmountLine."Use Tax";
                TaxAmountDifference."Tax Difference" := TempSalesTaxAmountLine."Tax Difference";
                TaxAmountDifference.Positive := TempSalesTaxAmountLine.Positive;
                TaxAmountDifference.Insert();
            until TempSalesTaxAmountLine.Next() = 0;
    end;

    procedure SetPurchHeader(NewPurchHeader: Record "Purchase Header")
    begin
        PurchHeader := NewPurchHeader;

        SetUpCurrency(PurchHeader."Currency Code");
        if PurchHeader."Currency Code" <> '' then
            PurchHeader.TestField("Currency Factor");
        if PurchHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchHeader."Currency Factor";
        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::Purchase, PurchHeader."Document Type".AsInteger(), PurchHeader."No.");

        PurchHeaderRead := true;
    end;

    procedure SetRoundByJurisdiction(NewRoundByJurisdiction: Boolean)
    begin
        RoundByJurisdiction := NewRoundByJurisdiction;
    end;

    procedure CalculateExpenseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) TaxAmount: Decimal
    var
        MaxAmount: Decimal;
        TaxBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateExpenseTax(
            TaxAreaCode, TaxGroupCode, TaxLiable, Date, Amount, Quantity, ExchangeRate, TaxAmount,
            TempTaxDetailMaximums, TaxDetail, TaxAreaLine, IsHandled);
        if IsHandled then
            exit;

        TaxAmount := 0;

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
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax", TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast() and TaxDetail."Expense/Capitalize" then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - TaxBaseAmount;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and TaxDetail."Expense/Capitalize" then begin
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum";
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;

        TaxAmount := TaxAmount * ExchangeFactor;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            ShowMissingTaxAreaValuesErr(TaxAreaLine, CalculationOrderViolation);
    end;

    procedure HandleRoundTaxUpOrDown(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; RoundTax: Option "To Nearest",Up,Down; TotalTaxAmount: Decimal; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        RoundedAmount: Decimal;
        RoundingError: Decimal;
    begin
        if (RoundTax = RoundTax::"To Nearest") or (TotalTaxAmount = 0) then
            exit;
        case RoundTax of
            RoundTax::Up:
                RoundedAmount := Round(TotalTaxAmount, 0.01, '>');
            RoundTax::Down:
                RoundedAmount := Round(TotalTaxAmount, 0.01, '<');
        end;
        RoundingError := RoundedAmount - TotalTaxAmount;
        SalesTaxAmountLine.Reset();
        SalesTaxAmountLine.SetRange("Tax Area Code for Key", TaxAreaCode);
        SalesTaxAmountLine.SetRange("Tax Group Code", TaxGroupCode);
        SalesTaxAmountLine.SetRange("Is Report-to Jurisdiction", true);
        if SalesTaxAmountLine.FindFirst() then begin
            SalesTaxAmountLine.Delete();
            SalesTaxAmountLine."Tax Amount" := SalesTaxAmountLine."Tax Amount" + RoundingError;
            SalesTaxAmountLine."Amount Including Tax" := SalesTaxAmountLine."Tax Amount" + SalesTaxAmountLine."Tax Base Amount";
            if SalesTaxAmountLine."Tax Type" = SalesTaxAmountLine."Tax Type"::"Excise Tax" then
                SalesTaxAmountLine."Tax %" := 0
            else
                if SalesTaxAmountLine."Tax Base Amount" <> 0 then
                    SalesTaxAmountLine."Tax %" := 100 * (SalesTaxAmountLine."Amount Including Tax" - SalesTaxAmountLine."Tax Base Amount") / SalesTaxAmountLine."Tax Base Amount";
            SalesTaxAmountLine.Insert();
        end;
    end;

    local procedure CheckTaxAmtLinePos(SalesLineAmt: Decimal; TaxAmtLinePos: Boolean): Boolean
    begin
        exit(
          ((SalesLineAmt > 0) and TaxAmtLinePos) or
          ((SalesLineAmt <= 0) and not TaxAmtLinePos)
          );
    end;

    local procedure ResetTaxAmountsInPurchLines(var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20])
    begin
        if TaxCountry = TaxCountry::US then
            PurchaseLine.SetRange("Tax Area Code", TaxAreaCode);
        if PurchaseLine.FindSet(true) then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Area Code", TaxAreaCode);
                TempSalesTaxAmountLine.SetRange("Tax Group Code", PurchaseLine."Tax Group Code");
                TempSalesTaxAmountLine.SetRange("Use Tax", PurchaseLine."Use Tax");
                if TempSalesTaxAmountLine.IsEmpty() then begin
                    PurchaseLine.Amount := PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount";
                    PurchaseLine."Amount Including VAT" := PurchaseLine.Amount;
                    PurchaseLine."VAT Base Amount" := PurchaseLine.Amount;
                    PurchaseLine."VAT %" := 0;
                    PurchaseLine."Tax To Be Expensed" := 0;
                    PurchaseLine.Modify();
                end;
            until PurchaseLine.Next() = 0;
    end;

    local procedure ResetTaxAmountsInSalesLines(var SalesLine: Record "Sales Line"; TaxAreaCode: Code[20])
    begin
        if TaxCountry = TaxCountry::US then
            SalesLine.SetRange("Tax Area Code", TaxAreaCode);
        if SalesLine.FindSet(true) then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Area Code", TaxAreaCode);
                TempSalesTaxAmountLine.SetRange("Tax Group Code", SalesLine."Tax Group Code");
                if TempSalesTaxAmountLine.IsEmpty() then begin
                    SalesLine.Amount := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
                    SalesLine."Amount Including VAT" := SalesLine.Amount;
                    SalesLine."VAT Base Amount" := SalesLine.Amount;
                    SalesLine."VAT %" := 0;
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
    end;

    internal procedure SetTotalTaxAmountRounding(NewTotalTaxAmountRounding: Decimal)
    begin
        TotalTaxAmountRounding := NewTotalTaxAmountRounding;
        IsTotalTaxAmountRoundingSpecified := true;
    end;

    internal procedure GetTotalTaxAmountRounding(): Decimal
    begin
        exit(TotalTaxAmountRounding);
    end;

    local procedure SetTaxDetailFilter(var TaxDetail2: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; Date: Date)
    begin
        TaxDetail2.Reset();
        TaxDetail2.SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        if TaxGroupCode = '' then
            TaxDetail2.SetFilter("Tax Group Code", '%1', TaxGroupCode)
        else
            TaxDetail2.SetFilter("Tax Group Code", '%1|%2', '', TaxGroupCode);
        if Date = 0D then
            TaxDetail2.SetFilter("Effective Date", '<=%1', WorkDate())
        else
            TaxDetail2.SetFilter("Effective Date", '<=%1', Date);
    end;

    local procedure UpdatePurchaseLineVatPct(var PurchLine: Record "Purchase Line")
    begin
        if PurchLine.Amount <> 0 then
            PurchLine."VAT %" := Round(100 * (PurchLine."Amount Including VAT" - PurchLine.Amount) / PurchLine.Amount, 0.00001)
        else
            PurchLine."VAT %" := 0;

        OnAfterUpdatePurchaseLineVatPct(PurchLine, PurchHeader);
    end;

    local procedure ShowMissingTaxAreaValuesErr(TaxAreaLine2: Record "Tax Area Line"; CalculationOrderViolation2: Boolean)
    begin
        Error(
            MissingTaxAreaValuesErr,
            TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine2."Tax Area",
            TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation2);
    end;

    procedure SetExchangeFactor(NewExchangeFactor: Decimal)
    begin
        ExchangeFactor := NewExchangeFactor;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPurchLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before starting the main tax calculation procedure.
    /// Enables custom tax calculation logic or external tax service integration.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code determining jurisdictions</param>
    /// <param name="TaxGroupCode">Tax group code for item classification</param>
    /// <param name="TaxLiable">Whether the transaction is subject to tax</param>
    /// <param name="Date">Transaction date for tax rate lookup</param>
    /// <param name="Amount">Transaction amount for tax calculation</param>
    /// <param name="Quantity">Transaction quantity for quantity-based taxes</param>
    /// <param name="ExchangeRate">Currency exchange rate for foreign transactions</param>
    /// <param name="TaxAmount">Calculated tax amount (can be modified by subscribers)</param>
    /// <param name="IsHandled">Set to true to skip standard calculation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTaxProcedure(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal; var TaxAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before initializing sales tax lines for detailed calculations.
    /// Enables custom tax line initialization or external tax service integration.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code determining jurisdictions</param>
    /// <param name="TaxGroupCode">Tax group code for item classification</param>
    /// <param name="TaxLiable">Whether the transaction is subject to tax</param>
    /// <param name="Amount">Transaction amount for tax calculation</param>
    /// <param name="Quantity">Transaction quantity for quantity-based taxes</param>
    /// <param name="Date">Transaction date for tax rate lookup</param>
    /// <param name="DesiredTaxAmount">Target tax amount for reconciliation</param>
    /// <param name="TMPTaxDetail">Temporary tax detail record for line processing</param>
    /// <param name="IsHandled">Set to true to skip standard initialization</param>
    /// <param name="Initialised">Initialization status flag</param>
    /// <param name="FirstLine">First line processing flag</param>
    /// <param name="TotalForAllocation">Total amount available for allocation</param>    [IntegrationEvent(false, false)]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSalesTaxLines(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; TaxLiable: Boolean; Amount: Decimal; Quantity: Decimal; Date: Date; DesiredTaxAmount: Decimal; var TMPTaxDetail: Record "Tax Detail"; var IsHandled: Boolean; var Initialised: Boolean; var FirstLine: Boolean; var TotalForAllocation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverPurchLines(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverSalesLines(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN28
    internal procedure RunOnBeforeDistTaxOverServLines(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnBeforeDistTaxOverServLines(ServiceLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverServLines(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndSalesTaxCalculationSales(SalesHeader: Record "Sales Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndSalesTaxCalculationPurchase(PurchaseHeader: Record "Purchase Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN28
    internal procedure RunOnBeforeEndSalesTaxCalculationService(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
        OnBeforeEndSalesTaxCalculationService(ServiceHeader, TempSalesTaxAmountLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Sales Tax Calculate', '28.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndSalesTaxCalculationService(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSummarizedSalesTaxTable(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostedSummarizedSalesTaxTable(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TempSalesTaxAmountDifference: Record "Sales Tax Amount Difference" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTaxDifference(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchaseLineVatPct(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnPurchLineLoopOnAfterSetPurchLineVATBaseAmount(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetPurchLineVATBaseAmount(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddPurchInvoiceLinesOnAfterCalcPurchLineSalesTaxAmountLine(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; ExchangeFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSalesLine(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ExchangeFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnSalesLineLoopOnAfterSetSalesLineVATBaseAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetSalesLineVATBaseAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnBeforeFindPurchLineSetTempSalesTaxLineAmount(var PurchLine: Record "Purchase Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnBeforeFindPurchLineAmounts(var PurchLine: Record "Purchase Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnBeforeFindSalesLineAmounts(var SalesLine: Record "Sales Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Insert(var SalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnBeforeTempSalesTaxLineModify(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnAfterCalculateMaxAmount(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; TaxDetail: Record "Tax Detail"; var MaxAmount: Decimal; var AddedTaxAmount: Decimal; TaxBaseAmt: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddPurchLine(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; ExchangeFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartSalestaxCalculation()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnAfterTempSalesTaxAmountLineSetFilters(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddPurchLineOnAfterTempSalesTaxAmountLineSetFilters(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesTaxAmountLineTable(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateExpenseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal; var TaxAmount: Decimal; var TempTaxDetailMaximums: Record "Tax Detail" temporary; var TaxDetail: Record "Tax Detail"; var TaxAreaLine: Record "Tax Area Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnBeforeTempSalesTaxAmountLineInsert(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEndSalesTaxCalulation(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; SalesHeaderRead: Boolean; PurchHeaderRead: Boolean; ServHeaderRead: Boolean; ProcessDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnAfterSetSalesTaxAmountLineFilter(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line"; TaxAreaLine: Record "Tax Area Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnBeforeModifySalesTaxAmountLine(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Copy(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var TaxBaseAmt: Decimal; var AddedTaxAmount: Decimal; var TotalTaxAmount: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeExternalTaxEngine(var ExternalTaxEngineImplementation: Interface "External Tax Engine")
    begin
    end;

}

