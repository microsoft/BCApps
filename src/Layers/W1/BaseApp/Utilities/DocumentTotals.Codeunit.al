// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;

codeunit 57 "Document Totals"
{
    trigger OnRun()
    begin
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PreviousTotalSalesHeader: Record "Sales Header";
        PreviousTotalPurchaseHeader: Record "Purchase Header";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        ForceTotalsRecalculation: Boolean;
        PreviousTotalSalesVATDifference: Decimal;
        PreviousTotalPurchVATDifference: Decimal;
        SalesLinesExist: Boolean;
        PurchaseLinesExist: Boolean;
        TotalsUpToDate: Boolean;
        NeedRefreshSalesLine: Boolean;
        NeedRefreshPurchaseLine: Boolean;

        TotalVATLbl: Label 'Total VAT';
        TotalAmountInclVatLbl: Label 'Total Incl. VAT';
        TotalAmountExclVATLbl: Label 'Total Excl. VAT';
        InvoiceDiscountAmountLbl: Label 'Invoice Discount Amount';
        RefreshMsgTxt: Label 'Totals or discounts may not be up-to-date. Choose the link to update.';
        TotalLineAmountLbl: Label 'Subtotal';
        InvoiceDiscountPerRoundingMsgTxt: Label 'The system has recalculated the discount percentage to align with the rounded discount amount.';

    procedure CalculateSalesPageTotals(var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var SalesLine: Record "Sales Line")
    var
        TotalSalesLine2: Record "Sales Line";
    begin
        TotalSalesLine2 := TotalSalesLine;
        TotalSalesLine2.ReadIsolation(IsolationLevel::ReadUncommitted);
        TotalSalesLine2.SetRange("Document Type", SalesLine."Document Type");
        TotalSalesLine2.SetRange("Document No.", SalesLine."Document No.");
        OnAfterSalesLineSetFilters(TotalSalesLine2, SalesLine);
        TotalSalesLine2.CalcSums("Line Amount", Amount, "Amount Including VAT", "Inv. Discount Amount");
        VATAmount := TotalSalesLine2."Amount Including VAT" - TotalSalesLine2.Amount;
        TotalSalesLine := TotalSalesLine2;
    end;

    procedure CalculateSalesTotals(var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var SalesLine: Record "Sales Line")
    begin
        OnBeforeCalculateSalesTotals(TotalSalesLine);
        CalculateSalesPageTotals(TotalSalesLine, VATAmount, SalesLine);
    end;

    procedure CalculateSalesSubPageTotals(var TotalSalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        TotalSalesLine2: Record "Sales Line";
        IsHandled: Boolean;
        OldInvoiceDiscountPct: Decimal;
        RoundingDiffDiscountPer: Decimal;
    begin
        IsHandled := false;
        OnBeforeCalculateSalesSubPageTotals(TotalSalesHeader, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        if TotalsUpToDate then
            exit;
        TotalsUpToDate := true;
        NeedRefreshSalesLine := false;

        SalesSetup.GetRecordOnce();
        TotalSalesLine2.Copy(TotalSalesLine);
        TotalSalesLine2.Reset();
        TotalSalesLine2.SetRange("Document Type", TotalSalesHeader."Document Type");
        TotalSalesLine2.SetRange("Document No.", TotalSalesHeader."No.");
        OnCalculateSalesSubPageTotalsOnAfterSetFilters(TotalSalesLine2, TotalSalesHeader);

        if SalesSetup."Calc. Inv. Discount" and (TotalSalesHeader."No." <> '') and
           (TotalSalesHeader."Customer Posting Group" <> '')
        then begin
            TotalSalesHeader.CalcFields("Recalculate Invoice Disc.");
            if TotalSalesHeader."Recalculate Invoice Disc." then
                if TotalSalesLine2.FindFirst() then begin
                    SalesCalcDiscount.CalculateInvoiceDiscountOnLine(TotalSalesLine2);
                    NeedRefreshSalesLine := true;
                end;
        end;

        TotalSalesLine2.CalcSums(Amount, "Amount Including VAT", "Line Amount", "Inv. Discount Amount");
        VATAmount := TotalSalesLine2."Amount Including VAT" - TotalSalesLine2.Amount;
        InvoiceDiscountAmount := TotalSalesLine2."Inv. Discount Amount";

        if (InvoiceDiscountAmount = 0) or (TotalSalesLine2."Line Amount" = 0) then begin
            InvoiceDiscountPct := 0;
            TotalSalesHeader."Invoice Discount Value" := 0;
        end else
            case TotalSalesHeader."Invoice Discount Calculation" of
                TotalSalesHeader."Invoice Discount Calculation"::"%":
                    begin
                        SalesHeader.Get(TotalSalesHeader."Document Type", TotalSalesHeader."No.");
                        TotalSalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
                        InvoiceDiscountPct := TotalSalesHeader."Invoice Discount Value";
                    end;
                TotalSalesHeader."Invoice Discount Calculation"::None,
                TotalSalesHeader."Invoice Discount Calculation"::Amount:
                    begin
                        OldInvoiceDiscountPct := InvoiceDiscountPct;
                        SalesLine2.CopyFilters(TotalSalesLine2);
                        SalesLine2.SetRange("Allow Invoice Disc.", true);
                        SalesLine2.CalcSums("Line Amount");
                        if SalesLine2."Line Amount" <> 0 then
                            InvoiceDiscountPct := Round(InvoiceDiscountAmount / SalesLine2."Line Amount" * 100, 0.00001);
                        TotalSalesHeader."Invoice Discount Value" := InvoiceDiscountAmount;
                        RoundingDiffDiscountPer := Abs(OldInvoiceDiscountPct - InvoiceDiscountPct);
                        if (RoundingDiffDiscountPer > 0) and (RoundingDiffDiscountPer <= 0.01) and (OldInvoiceDiscountPct <> 0) then
                            Message(InvoiceDiscountPerRoundingMsgTxt);
                    end;
            end;


        OnAfterCalculateSalesSubPageTotals(
          TotalSalesHeader, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, TotalSalesLine2);

        TotalSalesLine := TotalSalesLine2;
    end;

    procedure CalculatePostedSalesInvoiceTotals(var SalesInvoiceHeader: Record "Sales Invoice Header"; var VATAmount: Decimal; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePostedSalesInvoiceTotals(SalesInvoiceHeader, VATAmount, SalesInvoiceLine, IsHandled);
        if IsHandled then
            exit;

        if SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.") then begin
            SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            VATAmount := SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount;
        end;

        OnAfterCalculatePostedSalesInvoiceTotals(SalesInvoiceHeader, SalesInvoiceLine, VATAmount);
    end;

    procedure CalculatePostedSalesCreditMemoTotals(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var VATAmount: Decimal; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePostedSalesCreditMemoTotals(SalesCrMemoHeader, VATAmount, SalesCrMemoLine, IsHandled);
        if IsHandled then
            exit;

        if SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.") then begin
            SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            VATAmount := SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount;
        end;

        OnAfterCalculatePostedSalesCreditMemoTotals(SalesCrMemoHeader, SalesCrMemoLine, VATAmount);
    end;

    procedure CalcTotalPurchAmountOnlyDiscountAllowed(PurchLine: Record "Purchase Line"): Decimal
    var
        TotalPurchLine: Record "Purchase Line";
    begin
        TotalPurchLine.SetRange("Document Type", PurchLine."Document Type");
        TotalPurchLine.SetRange("Document No.", PurchLine."Document No.");
        TotalPurchLine.SetRange("Allow Invoice Disc.", true);
        TotalPurchLine.CalcSums("Line Amount");
        exit(TotalPurchLine."Line Amount");
    end;

    procedure CalcTotalSalesAmountOnlyDiscountAllowed(SalesLine: Record "Sales Line"): Decimal
    var
        TotalSalesLine: Record "Sales Line";
    begin
        OnBeforeCalcTotalSalesAmountOnlyDiscountAllowed(TotalSalesLine);
        TotalSalesLine.SetRange("Document Type", SalesLine."Document Type");
        TotalSalesLine.SetRange("Document No.", SalesLine."Document No.");
        TotalSalesLine.SetRange("Allow Invoice Disc.", true);
        TotalSalesLine.CalcSums("Line Amount");
        exit(TotalSalesLine."Line Amount");
    end;

    local procedure CalcTotalPurchVATDifference(PurchHeader: Record "Purchase Header"): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.CalcSums("VAT Difference");
        exit(PurchLine."VAT Difference");
    end;

    local procedure CalcTotalSalesVATDifference(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums("VAT Difference");
        exit(SalesLine."VAT Difference");
    end;

    local procedure CalculateTotalSalesLineAndVATAmount(SalesHeader: Record "Sales Header"; var VATAmount: Decimal; var TempTotalSalesLine: Record "Sales Line" temporary)
    var
        TempSalesLine: Record "Sales Line" temporary;
        TempTotalSalesLineLCY: Record "Sales Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
    begin
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 0);
        Clear(SalesPost);
        SalesPost.SumSalesLinesTemp(
          SalesHeader, TempSalesLine, 0, TempTotalSalesLine, TempTotalSalesLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    local procedure CalculateTotalPurchaseLineAndVATAmount(PurchaseHeader: Record "Purchase Header"; var VATAmount: Decimal; var TempTotalPurchaseLine: Record "Purchase Line" temporary)
    var
        TempTotalPurchaseLineLCY: Record "Purchase Line" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        VATAmountText: Text[30];
    begin
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        Clear(PurchPost);

        PurchPost.SumPurchLinesTemp(
          PurchaseHeader, TempPurchaseLine, 0, TempTotalPurchaseLine, TempTotalPurchaseLineLCY, VATAmount, VATAmountText);

        OnAfterCalculateTotalPurchaseLineAndVATAmount(PurchaseHeader, VATAmount, TempTotalPurchaseLine);
    end;

    procedure RefreshSalesLine(var SalesLine: Record "Sales Line")
    begin
        if NeedRefreshSalesLine and (SalesLine."Line No." <> 0) then
            if SalesLine.Find() then;
    end;

    procedure RefreshPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        if NeedRefreshPurchaseLine and (PurchaseLine."Line No." <> 0) then
            if PurchaseLine.Find() then;
    end;

    procedure SalesUpdateTotalsControls(CurrentSalesLine: Record "Sales Line"; var TotalSalesHeader: Record "Sales Header"; var TotalsSalesLine: Record "Sales Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; CurrPageEditable: Boolean; var VATAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSalesUpdateTotalsControlsOnBeforeCheckDocumentNo(CurrentSalesLine, TotalSalesHeader, TotalsSalesLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable, CurrPageEditable, VATAmount, IsHandled);
        if IsHandled then
            exit;

        if CurrentSalesLine."Document No." = '' then
            exit;

        TotalSalesHeader.Get(CurrentSalesLine."Document Type", CurrentSalesLine."Document No.");
        IsHandled := false;
        OnBeforeSalesUpdateTotalsControls(TotalSalesHeader, InvDiscAmountEditable, IsHandled);
        RefreshMessageEnabled := SalesCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(TotalSalesHeader);

        if not RefreshMessageEnabled then
            RefreshMessageEnabled := not SalesUpdateTotals(TotalSalesHeader, CurrentSalesLine, TotalsSalesLine, VATAmount);

        SalesLine.SetRange("Document Type", CurrentSalesLine."Document Type");
        SalesLine.SetRange("Document No.", CurrentSalesLine."Document No.");
        if not IsHandled then
            InvDiscAmountEditable := (not SalesLine.IsEmpty()) and
              SalesCalcDiscountByType.InvoiceDiscIsAllowed(TotalSalesHeader."Invoice Disc. Code") and
              (not RefreshMessageEnabled) and CurrPageEditable;

        TotalControlsUpdateStyle(RefreshMessageEnabled, ControlStyle, RefreshMessageText);

        if RefreshMessageEnabled then
            ClearSalesAmounts(TotalsSalesLine, VATAmount);
    end;

    local procedure SalesUpdateTotals(var SalesHeader: Record "Sales Header"; CurrentSalesLine: Record "Sales Line"; var TotalsSalesLine: Record "Sales Line"; var VATAmount: Decimal) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesUpdateTotals(SalesHeader, PreviousTotalSalesHeader, ForceTotalsRecalculation, PreviousTotalSalesVATDifference, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");

        if SalesHeader."No." <> PreviousTotalSalesHeader."No." then
            ForceTotalsRecalculation := true;

        if (not ForceTotalsRecalculation) and
           (PreviousTotalSalesHeader.Amount = SalesHeader.Amount) and
           (PreviousTotalSalesHeader."Amount Including VAT" = SalesHeader."Amount Including VAT") and
           (PreviousTotalSalesVATDifference = CalcTotalSalesVATDifference(SalesHeader))
        then
            exit(true);

        ForceTotalsRecalculation := false;

        if not SalesCheckNumberOfLinesLimit(SalesHeader) then
            exit(false);

        SalesCalculateTotalsWithInvoiceRounding(CurrentSalesLine, VATAmount, TotalsSalesLine);
        exit(true);
    end;

    local procedure SalesCalculateTotalsWithInvoiceRounding(var TempCurrentSalesLine: Record "Sales Line" temporary; var VATAmount: Decimal; var TempTotalSalesLine: Record "Sales Line" temporary)
    var
        SalesHeader: Record "Sales Header";
    begin
        Clear(TempTotalSalesLine);
        if SalesHeader.Get(TempCurrentSalesLine."Document Type", TempCurrentSalesLine."Document No.") then begin
            CalculateTotalSalesLineAndVATAmount(SalesHeader, VATAmount, TempTotalSalesLine);

            if PreviousTotalSalesHeader."No." <> TempCurrentSalesLine."Document No." then begin
                PreviousTotalSalesHeader.Get(TempCurrentSalesLine."Document Type", TempCurrentSalesLine."Document No.");
                ForceTotalsRecalculation := true;
            end;
            PreviousTotalSalesHeader.CalcFields(Amount, "Amount Including VAT");
            PreviousTotalSalesVATDifference := CalcTotalSalesVATDifference(PreviousTotalSalesHeader);
            OnAfterSalesCalculateTotalsWithInvoiceRounding(PreviousTotalSalesHeader);
        end;
    end;

    procedure SalesRedistributeInvoiceDiscountAmounts(var TempSalesLine: Record "Sales Line" temporary; var VATAmount: Decimal; var TempTotalSalesLine: Record "Sales Line" temporary)
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesRedistributeInvoiceDiscountAmounts(TempSalesLine, VATAmount, TempTotalSalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.") then begin
            SalesHeader.CalcFields("Recalculate Invoice Disc.");
            if SalesHeader."Recalculate Invoice Disc." then
                CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", TempSalesLine);

            SalesCalculateTotalsWithInvoiceRounding(TempSalesLine, VATAmount, TempTotalSalesLine);
        end;

        OnAfterSalesRedistributeInvoiceDiscountAmounts(TempSalesLine, TempTotalSalesLine, VATAmount);
    end;

    procedure SalesRedistributeInvoiceDiscountAmountsOnDocument(SalesHeader: Record "Sales Header")
    var
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLineTotal: Record "Sales Line" temporary;
        VATAmount: Decimal;
    begin
        TempSalesLine."Document Type" := SalesHeader."Document Type";
        TempSalesLine."Document No." := SalesHeader."No.";
        SalesRedistributeInvoiceDiscountAmounts(TempSalesLine, VATAmount, TempSalesLineTotal);
    end;

    procedure SalesDocTotalsNotUpToDate()
    begin
        TotalsUpToDate := false;
    end;

    procedure SalesCheckIfDocumentChanged(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line")
    begin
        if (SalesLine."Document No." <> xSalesLine."Document No.") or
           (SalesLine."Sell-to Customer No." <> xSalesLine."Sell-to Customer No.") or
           (SalesLine."Bill-to Customer No." <> xSalesLine."Bill-to Customer No.") or
           (SalesLine.Amount <> xSalesLine.Amount) or
           (SalesLine."Amount Including VAT" <> xSalesLine."Amount Including VAT") or
           (SalesLine."Inv. Discount Amount" <> xSalesLine."Inv. Discount Amount") or
           (SalesLine."Currency Code" <> xSalesLine."Currency Code")
        then
            TotalsUpToDate := false;

        OnAfterSalesCheckIfDocumentChanged(SalesLine, xSalesLine, TotalsUpToDate);
    end;

    procedure SalesCheckAndClearTotals(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
        SalesLine.FilterGroup(4);
        if SalesLine.GetFilter("Document No.") <> '' then
            if SalesLine.GetRangeMin("Document No.") <> xSalesLine."Document No." then begin
                TotalsUpToDate := false;
                Clear(TotalSalesLine);
                VATAmount := 0;
                InvoiceDiscountAmount := 0;
                InvoiceDiscountPct := 0;
            end;
        SalesLine.FilterGroup(0);
    end;

    procedure SalesDeltaUpdateTotals(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        InvDiscountBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesDeltaUpdateTotals(SalesLine, xSalesLine, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        TotalSalesLine."Line Amount" += SalesLine."Line Amount" - xSalesLine."Line Amount";
        TotalSalesLine."Amount Including VAT" += SalesLine."Amount Including VAT" - xSalesLine."Amount Including VAT";
        TotalSalesLine.Amount += SalesLine.Amount - xSalesLine.Amount;
        VATAmount := TotalSalesLine."Amount Including VAT" - TotalSalesLine.Amount;
        if SalesLine."Inv. Discount Amount" <> xSalesLine."Inv. Discount Amount" then begin
            if (InvoiceDiscountPct > -0.01) and (InvoiceDiscountPct < 0.01) then // To avoid decimal overflow later
                InvDiscountBaseAmount := 0
            else
                InvDiscountBaseAmount := InvoiceDiscountAmount / InvoiceDiscountPct * 100;
            InvoiceDiscountAmount += SalesLine."Inv. Discount Amount" - xSalesLine."Inv. Discount Amount";
            if (InvoiceDiscountAmount = 0) or (InvDiscountBaseAmount = 0) then
                InvoiceDiscountPct := 0
            else
                InvoiceDiscountPct := Round(100 * InvoiceDiscountAmount / InvDiscountBaseAmount, 0.00001);
        end;


        OnAfterSalesDeltaUpdateTotals(SalesLine, xSalesLine, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
    end;

    procedure PurchaseUpdateTotalsControls(CurrentPurchaseLine: Record "Purchase Line"; var TotalPurchaseHeader: Record "Purchase Header"; var TotalsPurchaseLine: Record "Purchase Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; var VATAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseUpdateTotalsControls(CurrentPurchaseLine, TotalPurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable, VATAmount, IsHandled);
        if IsHandled then
            exit;

        PurchaseUpdateTotalsControlsForceable(
          CurrentPurchaseLine, TotalPurchaseHeader, TotalsPurchaseLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText,
          InvDiscAmountEditable, VATAmount, false);
    end;

    procedure PurchaseUpdateTotalsControlsForceable(CurrentPurchaseLine: Record "Purchase Line"; var TotalPurchaseHeader: Record "Purchase Header"; var TotalsPurchaseLine: Record "Purchase Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; var VATAmount: Decimal; Force: Boolean)
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        IsHandled: Boolean;
    begin
        ClearPurchaseAmounts(TotalsPurchaseLine, VATAmount);

        if CurrentPurchaseLine."Document No." = '' then
            exit;

        TotalPurchaseHeader.Get(CurrentPurchaseLine."Document Type", CurrentPurchaseLine."Document No.");
        IsHandled := false;
        OnBeforePurchUpdateTotalsControls(TotalPurchaseHeader, InvDiscAmountEditable, IsHandled);
        RefreshMessageEnabled := PurchCalcDiscByType.ShouldRedistributeInvoiceDiscountAmount(TotalPurchaseHeader);

        if not RefreshMessageEnabled then
            RefreshMessageEnabled := not PurchaseUpdateTotals(TotalPurchaseHeader, CurrentPurchaseLine, TotalsPurchaseLine, VATAmount, Force);

        if not IsHandled then
            InvDiscAmountEditable :=
              PurchCalcDiscByType.InvoiceDiscIsAllowed(TotalPurchaseHeader."Invoice Disc. Code") and (not RefreshMessageEnabled);

        TotalControlsUpdateStyle(RefreshMessageEnabled, ControlStyle, RefreshMessageText);

        if RefreshMessageEnabled then
            ClearPurchaseAmounts(TotalsPurchaseLine, VATAmount);
    end;

    local procedure PurchaseUpdateTotals(var PurchaseHeader: Record "Purchase Header"; CurrentPurchaseLine: Record "Purchase Line"; var TotalsPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; Force: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseUpdateTotals(PurchaseHeader, PreviousTotalPurchaseHeader, CurrentPurchaseLine, TotalsPurchaseLine, VATAmount, Force, IsHandled, Result);
        if IsHandled then
            exit(Result);

        PurchaseHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");

        if (PreviousTotalPurchaseHeader.Amount = PurchaseHeader.Amount) and
           (PreviousTotalPurchaseHeader."Amount Including VAT" = PurchaseHeader."Amount Including VAT") and
           (PreviousTotalPurchVATDifference = CalcTotalPurchVATDifference(PurchaseHeader))
        then
            exit(true);

        if not Force then
            if not PurchaseCheckNumberOfLinesLimit(PurchaseHeader) then
                exit(false);

        PurchaseCalculateTotalsWithInvoiceRounding(CurrentPurchaseLine, VATAmount, TotalsPurchaseLine);
        exit(true);
    end;

    procedure PurchaseCalculateTotalsWithInvoiceRounding(var TempCurrentPurchaseLine: Record "Purchase Line" temporary; var VATAmount: Decimal; var TempTotalPurchaseLine: Record "Purchase Line" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Clear(TempTotalPurchaseLine);

        if PurchaseHeader.Get(TempCurrentPurchaseLine."Document Type", TempCurrentPurchaseLine."Document No.") then begin
            CalculateTotalPurchaseLineAndVATAmount(PurchaseHeader, VATAmount, TempTotalPurchaseLine);

            if PreviousTotalPurchaseHeader."No." <> TempCurrentPurchaseLine."Document No." then
                PreviousTotalPurchaseHeader.Get(TempCurrentPurchaseLine."Document Type", TempCurrentPurchaseLine."Document No.");
            PreviousTotalPurchaseHeader.CalcFields(Amount, "Amount Including VAT");
            PreviousTotalPurchVATDifference := CalcTotalPurchVATDifference(PreviousTotalPurchaseHeader);

            // calculate correct amount including vat if the VAT Calc type is Sales Tax
            if TempCurrentPurchaseLine."VAT Calculation Type" = TempCurrentPurchaseLine."VAT Calculation Type"::"Sales Tax" then
                CalculateSalesTaxForTempTotalPurchaseLine(PurchaseHeader, TempCurrentPurchaseLine, TempTotalPurchaseLine);
        end;
    end;

    procedure PurchaseRedistributeInvoiceDiscountAmounts(var TempPurchaseLine: Record "Purchase Line" temporary; var VATAmount: Decimal; var TempTotalPurchaseLine: Record "Purchase Line" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseRedistributeInvoiceDiscountAmounts(TempPurchaseLine, VATAmount, TempTotalPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseHeader.Get(TempPurchaseLine."Document Type", TempPurchaseLine."Document No.") then begin
            PurchaseHeader.CalcFields("Recalculate Invoice Disc.");
            if PurchaseHeader."Recalculate Invoice Disc." then
                CODEUNIT.Run(CODEUNIT::"Purch - Calc Disc. By Type", TempPurchaseLine);

            PurchaseCalculateTotalsWithInvoiceRounding(TempPurchaseLine, VATAmount, TempTotalPurchaseLine);
        end;

        OnAfterPurchaseRedistributeInvoiceDiscountAmounts(TempPurchaseLine, TempTotalPurchaseLine, VATAmount);
    end;

    procedure PurchaseRedistributeInvoiceDiscountAmountsOnDocument(PurchaseHeader: Record "Purchase Header")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPurchaseLineTotal: Record "Purchase Line" temporary;
        VATAmount: Decimal;
    begin
        TempPurchaseLine."Document Type" := PurchaseHeader."Document Type";
        TempPurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseRedistributeInvoiceDiscountAmounts(TempPurchaseLine, VATAmount, TempPurchaseLineTotal);
    end;

    procedure PurchaseDocTotalsNotUpToDate()
    begin
        TotalsUpToDate := false;
    end;

    procedure PurchaseCheckIfDocumentChanged(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line")
    begin
        if (PurchaseLine."Document No." <> xPurchaseLine."Document No.") or
           (PurchaseLine."Buy-from Vendor No." <> xPurchaseLine."Buy-from Vendor No.") or
           (PurchaseLine."Pay-to Vendor No." <> xPurchaseLine."Pay-to Vendor No.") or
           (PurchaseLine.Amount <> xPurchaseLine.Amount) or
           (PurchaseLine."Amount Including VAT" <> xPurchaseLine."Amount Including VAT") or
           (PurchaseLine."Inv. Discount Amount" <> xPurchaseLine."Inv. Discount Amount") or
           (PurchaseLine."Currency Code" <> xPurchaseLine."Currency Code")
        then
            TotalsUpToDate := false;

        OnAfterPurchaseCheckIfDocumentChanged(PurchaseLine, xPurchaseLine, TotalsUpToDate);
    end;

    procedure PurchaseCheckAndClearTotals(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
        PurchaseLine.FilterGroup(4);
        if PurchaseLine.GetFilter("Document No.") <> '' then
            if PurchaseLine.GetRangeMin("Document No.") <> xPurchaseLine."Document No." then begin
                TotalsUpToDate := false;
                Clear(TotalPurchaseLine);
                VATAmount := 0;
                InvoiceDiscountAmount := 0;
                InvoiceDiscountPct := 0;
            end;
        PurchaseLine.FilterGroup(0);
    end;

    procedure PurchaseDeltaUpdateTotals(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        InvDiscountBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseDeltaUpdateTotals(PurchaseLine, xPurchaseLine, TotalPurchaseLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        TotalPurchaseLine."Line Amount" += PurchaseLine."Line Amount" - xPurchaseLine."Line Amount";
        TotalPurchaseLine."Amount Including VAT" += PurchaseLine."Amount Including VAT" - xPurchaseLine."Amount Including VAT";
        TotalPurchaseLine.Amount += PurchaseLine.Amount - xPurchaseLine.Amount;
        VATAmount := TotalPurchaseLine."Amount Including VAT" - TotalPurchaseLine.Amount;
        if PurchaseLine."Inv. Discount Amount" <> xPurchaseLine."Inv. Discount Amount" then begin
            if (InvoiceDiscountPct > -0.01) and (InvoiceDiscountPct < 0.01) then // To avoid decimal overflow later
                InvDiscountBaseAmount := 0
            else
                InvDiscountBaseAmount := InvoiceDiscountAmount / InvoiceDiscountPct * 100;
            InvoiceDiscountAmount += PurchaseLine."Inv. Discount Amount" - xPurchaseLine."Inv. Discount Amount";
            if (InvoiceDiscountAmount = 0) or (InvDiscountBaseAmount = 0) then
                InvoiceDiscountPct := 0
            else
                InvoiceDiscountPct := Round(100 * InvoiceDiscountAmount / InvDiscountBaseAmount, 0.00001);
        end;

        OnAfterPurchDeltaUpdateTotals(PurchaseLine, xPurchaseLine, TotalPurchaseLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
    end;

    procedure CalculatePurchasePageTotals(var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var PurchaseLine: Record "Purchase Line")
    var
        TotalPurchaseLine2: Record "Purchase Line";
    begin
        TotalPurchaseLine2 := TotalPurchaseLine;
        TotalPurchaseLine2.ReadIsolation(IsolationLevel::ReadUncommitted);
        TotalPurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
        TotalPurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
        OnAfterPurchaseLineSetFilters(TotalPurchaseLine2, PurchaseLine);
        TotalPurchaseLine2.CalcSums("Line Amount", Amount, "Amount Including VAT", "Inv. Discount Amount");
        VATAmount := TotalPurchaseLine2."Amount Including VAT" - TotalPurchaseLine2.Amount;
        OnCalculatePurchasePageTotalsOnAfterCalculateVATAmount(TotalPurchaseLine, VATAmount, PurchaseLine, TotalPurchaseLine2);
        TotalPurchaseLine := TotalPurchaseLine2;
    end;

    procedure CalculatePurchaseTotals(var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var PurchaseLine: Record "Purchase Line")
    begin
        CalculatePurchasePageTotals(TotalPurchaseLine, VATAmount, PurchaseLine);
    end;

    procedure CalculatePurchaseSubPageTotals(var TotalPurchaseHeader: Record "Purchase Header"; var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        TotalPurchaseLine2: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePurchaseSubPageTotals(TotalPurchaseHeader, TotalPurchaseLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        if TotalsUpToDate then
            exit;
        TotalsUpToDate := true;
        NeedRefreshPurchaseLine := false;

        PurchasesPayablesSetup.GetRecordOnce();
        TotalPurchaseLine2.Copy(TotalPurchaseLine);
        TotalPurchaseLine2.Reset();
        TotalPurchaseLine2.SetRange("Document Type", TotalPurchaseHeader."Document Type");
        TotalPurchaseLine2.SetRange("Document No.", TotalPurchaseHeader."No.");
        OnCalculatePurchaseSubPageTotalsOnAfterSetFilter(TotalPurchaseLine2, TotalPurchaseHeader);
        if PurchasesPayablesSetup."Calc. Inv. Discount" and (TotalPurchaseHeader."No." <> '') and
           (TotalPurchaseHeader."Vendor Posting Group" <> '')
        then begin
            TotalPurchaseHeader.CalcFields("Recalculate Invoice Disc.");
            if TotalPurchaseHeader."Recalculate Invoice Disc." then
                if TotalPurchaseLine2.FindFirst() then begin
                    PurchCalcDiscount.CalculateInvoiceDiscountOnLine(TotalPurchaseLine2);
                    NeedRefreshPurchaseLine := true;
                end;
        end;

        TotalPurchaseLine2.CalcSums(Amount, "Amount Including VAT", "Line Amount", "Inv. Discount Amount");
        OnCalculatePurchaseSubPageTotalsOnAfterRecalculate(TotalPurchaseLine2);
        VATAmount := TotalPurchaseLine2."Amount Including VAT" - TotalPurchaseLine2.Amount;
        InvoiceDiscountAmount := TotalPurchaseLine2."Inv. Discount Amount";

        if (InvoiceDiscountAmount = 0) or (TotalPurchaseLine2."Line Amount" = 0) then begin
            InvoiceDiscountPct := 0;
            TotalPurchaseHeader."Invoice Discount Value" := 0;
        end else
            case TotalPurchaseHeader."Invoice Discount Calculation" of
                TotalPurchaseHeader."Invoice Discount Calculation"::"%":
                    begin
                        PurchaseHeader.Get(TotalPurchaseHeader."Document Type", TotalPurchaseHeader."No.");
                        TotalPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
                        InvoiceDiscountPct := TotalPurchaseHeader."Invoice Discount Value";
                    end;
                TotalPurchaseHeader."Invoice Discount Calculation"::None,
                TotalPurchaseHeader."Invoice Discount Calculation"::Amount:
                    begin
                        PurchaseLine2.CopyFilters(TotalPurchaseLine2);
                        PurchaseLine2.SetRange("Allow Invoice Disc.", true);
                        PurchaseLine2.CalcSums("Line Amount");
                        if PurchaseLine2."Line Amount" <> 0 then
                            InvoiceDiscountPct := Round(InvoiceDiscountAmount / PurchaseLine2."Line Amount" * 100, 0.00001);
                        TotalPurchaseHeader."Invoice Discount Value" := InvoiceDiscountAmount;
                    end;
            end;

        OnAfterCalculatePurchaseSubPageTotals(
          TotalPurchaseHeader, TotalPurchaseLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, TotalPurchaseLine2);

        TotalPurchaseLine := TotalPurchaseLine2;
    end;

    procedure CalculatePostedPurchInvoiceTotals(var PurchInvHeader: Record "Purch. Inv. Header"; var VATAmount: Decimal; PurchInvLine: Record "Purch. Inv. Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePostedPurchInvoiceTotals(PurchInvHeader, VATAmount, PurchInvLine, IsHandled);
        if IsHandled then
            exit;

        if PurchInvHeader.Get(PurchInvLine."Document No.") then begin
            PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            VATAmount := PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount;
        end;
        OnAfterCalculatePostedPurchInvoiceTotals(PurchInvHeader, VATAmount, PurchInvLine);
    end;

    procedure CalculatePostedPurchCreditMemoTotals(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var VATAmount: Decimal; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePostedPurchCreditMemoTotals(PurchCrMemoHdr, VATAmount, PurchCrMemoLine, IsHandled);
        if IsHandled then
            exit;
        if PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.") then begin
            PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            VATAmount := PurchCrMemoHdr."Amount Including VAT" - PurchCrMemoHdr.Amount;
        end;
        OnAfterCalculatePostedPurchCreditMemoTotals(PurchCrMemoHdr, VATAmount, PurchCrMemoLine);
    end;

    local procedure ClearSalesAmounts(var TotalsSalesLine: Record "Sales Line"; var VATAmount: Decimal)
    begin
        TotalsSalesLine.Amount := 0;
        TotalsSalesLine."Amount Including VAT" := 0;
        VATAmount := 0;
        Clear(PreviousTotalSalesHeader);
    end;

    local procedure ClearPurchaseAmounts(var TotalsPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal)
    begin
        TotalsPurchaseLine.Amount := 0;
        TotalsPurchaseLine."Amount Including VAT" := 0;
        VATAmount := 0;
        Clear(PreviousTotalPurchaseHeader);
    end;

    local procedure TotalControlsUpdateStyle(RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text)
    begin
        if RefreshMessageEnabled then begin
            ControlStyle := 'Subordinate';
            RefreshMessageText := RefreshMsgTxt;
        end else begin
            ControlStyle := 'Strong';
            RefreshMessageText := '';
        end;
    end;

    procedure GetTotalVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalVATLbl, CurrencyCode));
    end;

    procedure GetTotalInclVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalAmountInclVatLbl, CurrencyCode));
    end;

    procedure GetTotalExclVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalAmountExclVATLbl, CurrencyCode));
    end;

    local procedure GetCaptionClassWithCurrencyCode(CaptionWithoutCurrencyCode: Text; CurrencyCode: Code[10]): Text
    begin
        exit('3,' + GetCaptionWithCurrencyCode(CaptionWithoutCurrencyCode, CurrencyCode));
    end;

    local procedure GetCaptionWithCurrencyCode(CaptionWithoutCurrencyCode: Text; CurrencyCode: Code[10]): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup.GetCurrencyCode(CurrencyCode);
        end;

        if CurrencyCode <> '' then
            exit(CaptionWithoutCurrencyCode + StrSubstNo(' (%1)', CurrencyCode));

        exit(CaptionWithoutCurrencyCode);
    end;

    local procedure GetCaptionWithVATInfo(CaptionWithoutVATInfo: Text; IncludesVAT: Boolean): Text
    begin
        if IncludesVAT then
            exit('2,1,' + CaptionWithoutVATInfo);

        exit('2,0,' + CaptionWithoutVATInfo);
    end;

    procedure GetTotalSalesHeaderAndCurrency(var SalesLine: Record "Sales Line"; var TotalSalesHeader: Record "Sales Header"; var Currency: Record Currency)
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SalesLinesExist then
            SalesLinesExist := not SalesLine.IsEmpty();
        if not SalesLinesExist or
           (TotalSalesHeader."Document Type" <> SalesLine."Document Type") or (TotalSalesHeader."No." <> SalesLine."Document No.") or
           (TotalSalesHeader."Sell-to Customer No." <> SalesLine."Sell-to Customer No.") or
           (TotalSalesHeader."Currency Code" <> SalesLine."Currency Code")
        then begin
            Clear(TotalSalesHeader);
            if SalesLine."Document No." <> '' then
                if TotalSalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then;
        end;
        if Currency.Code <> TotalSalesHeader."Currency Code" then begin
            Clear(Currency);
            Currency.Initialize(TotalSalesHeader."Currency Code");
        end;
        if SalesHeader.Get(TotalSalesHeader."Document Type", TotalSalesHeader."No.") then
            if SalesHeader."Invoice Discount Value" <> TotalSalesHeader."Invoice Discount Value" then
                TotalsUpToDate := false;
    end;

    procedure GetTotalPurchaseHeaderAndCurrency(var PurchaseLine: Record "Purchase Line"; var TotalPurchaseHeader: Record "Purchase Header"; var Currency: Record Currency)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if not PurchaseLinesExist then
            PurchaseLinesExist := not PurchaseLine.IsEmpty();
        if not PurchaseLinesExist or
           (TotalPurchaseHeader."Document Type" <> PurchaseLine."Document Type") or
           (TotalPurchaseHeader."No." <> PurchaseLine."Document No.") or
           (TotalPurchaseHeader."Buy-from Vendor No." <> PurchaseLine."Buy-from Vendor No.") or
           (TotalPurchaseHeader."Currency Code" <> PurchaseLine."Currency Code")
        then begin
            Clear(TotalPurchaseHeader);
            if PurchaseLine."Document No." <> '' then
                if TotalPurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then;
        end;
        if Currency.Code <> TotalPurchaseHeader."Currency Code" then begin
            Clear(Currency);
            Currency.Initialize(TotalPurchaseHeader."Currency Code");
        end;
        if PurchaseHeader.Get(TotalPurchaseHeader."Document Type", TotalPurchaseHeader."No.") then
            if PurchaseHeader."Invoice Discount Value" <> TotalPurchaseHeader."Invoice Discount Value" then
                TotalsUpToDate := false;
    end;

    procedure GetInvoiceDiscAmountWithVATCaption(IncludesVAT: Boolean): Text
    begin
        exit(GetCaptionWithVATInfo(InvoiceDiscountAmountLbl, IncludesVAT));
    end;

    procedure GetInvoiceDiscAmountWithVATAndCurrencyCaption(InvDiscAmountCaptionClassWithVAT: Text; CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionWithCurrencyCode(InvDiscAmountCaptionClassWithVAT, CurrencyCode));
    end;

    procedure GetTotalLineAmountWithVATAndCurrencyCaption(CurrencyCode: Code[10]; IncludesVAT: Boolean): Text
    begin
        exit(GetCaptionWithCurrencyCode(CaptionClassTranslate(GetCaptionWithVATInfo(TotalLineAmountLbl, IncludesVAT)), CurrencyCode));
    end;

    procedure SalesCheckNumberOfLinesLimit(SalesHeader: Record "Sales Header") Result: Boolean
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCheckNumberOfLinesLimit(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("No.", '<>%1', '');

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            exit(SalesLine.Count <= 10);

        exit(SalesLine.Count <= 100);
    end;

    procedure PurchaseCheckNumberOfLinesLimit(PurchaseHeader: Record "Purchase Header") Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseCheckNumberOfLinesLimit(PurchaseHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("No.", '<>%1', '');

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            exit(PurchaseLine.Count <= 10);

        exit(PurchaseLine.Count <= 100);
    end;

    local procedure CalculateSalesTaxForTempTotalPurchaseLine(PurchaseHeader: Record "Purchase Header"; CurrentPurchaseLine: Record "Purchase Line"; var TempTotalPurchaseLine: Record "Purchase Line" temporary)
    var
        Currency: Record Currency;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        TotalVATAmount: Decimal;
    begin
        if PurchaseHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(PurchaseHeader."Currency Code");

        CurrentPurchaseLine.SetRange("Document No.", CurrentPurchaseLine."Document No.");
        CurrentPurchaseLine.SetRange("Document Type", CurrentPurchaseLine."Document Type");
        CurrentPurchaseLine.FindSet();
        TotalVATAmount := 0;

        // Loop through all purchase lines and calculate correct sales tax.
        repeat
            TotalVATAmount := TotalVATAmount + Round(
                SalesTaxCalculate.CalculateTax(
                  CurrentPurchaseLine."Tax Area Code", CurrentPurchaseLine."Tax Group Code", CurrentPurchaseLine."Tax Liable",
                  PurchaseHeader."Posting Date",
                  CurrentPurchaseLine."Line Amount" - CurrentPurchaseLine."Inv. Discount Amount",
                  CurrentPurchaseLine."Quantity (Base)", PurchaseHeader."Currency Factor"),
                Currency."Amount Rounding Precision");
        until CurrentPurchaseLine.Next() = 0;

        TempTotalPurchaseLine."Amount Including VAT" := TempTotalPurchaseLine."Line Amount" -
          TempTotalPurchaseLine."Inv. Discount Amount" + TotalVATAmount;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePostedSalesInvoiceTotals(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceLine: Record "Sales Invoice Line"; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePostedSalesCreditMemoTotals(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line"; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesSubPageTotals(var TotalSalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var TotalSalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePostedPurchCreditMemoTotals(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var VATAmount: Decimal; var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePostedPurchInvoiceTotals(var PurchInvHeader: Record "Purch. Inv. Header"; var VATAmount: Decimal; var PurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePurchaseSubPageTotals(var TotalPurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var TotalPurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTotalPurchaseLineAndVATAmount(PurchaseHeader: Record "Purchase Header"; var VATAmount: Decimal; var TempTotalPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCheckIfDocumentChanged(SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var TotalsUpToDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineSetFilters(var TotalSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesRedistributeInvoiceDiscountAmounts(var TempSalesLine: Record "Sales Line" temporary; var TempTotalSalesLine: Record "Sales Line" temporary; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseCheckIfDocumentChanged(PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var TotalsUpToDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineSetFilters(var TotalPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseRedistributeInvoiceDiscountAmounts(var TempPurchaseLine: Record "Purchase Line" temporary; var TempTotalPurchaseLine: Record "Purchase Line" temporary; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchDeltaUpdateTotals(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesDeltaUpdateTotals(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesDeltaUpdateTotals(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesUpdateTotals(var SalesHeader: Record "Sales Header"; PreviousTotalSalesHeader: Record "Sales Header"; var ForceTotalsRecalculation: Boolean; PreviousTotalSalesVATDifference: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePostedPurchCreditMemoTotals(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var VATAmount: Decimal; PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePostedPurchInvoiceTotals(var PurchInvHeader: Record "Purch. Inv. Header"; var VATAmount: Decimal; PurchInvLine: Record "Purch. Inv. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePostedSalesCreditMemoTotals(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var VATAmount: Decimal; SalesCrMemoLine: Record "Sales Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePostedSalesInvoiceTotals(var SalesInvoiceHeader: Record "Sales Invoice Header"; var VATAmount: Decimal; SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePurchaseSubPageTotals(var TotalPurchaseHeader: Record "Purchase Header"; var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesSubPageTotals(var TotalSalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesRedistributeInvoiceDiscountAmounts(var TempSalesLine: Record "Sales Line" temporary; var VATAmount: Decimal; var TempTotalSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesUpdateTotalsControls(var SalesHeader: Record "Sales Header"; var InvDiscAmountEditable: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseRedistributeInvoiceDiscountAmounts(var TempPurchaseLine: Record "Purchase Line" temporary; var VATAmount: Decimal; var TempTotalPurchaseLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchUpdateTotalsControls(var PurchaseHeader: Record "Purchase Header"; var InvDiscAmountEditable: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseDeltaUpdateTotals(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseUpdateTotalsControls(CurrentPurchaseLine: Record "Purchase Line"; var TotalPurchaseHeader: Record "Purchase Header"; var TotalsPurchaseLine: Record "Purchase Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; var VATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateSalesSubPageTotalsOnAfterSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePurchaseSubPageTotalsOnAfterRecalculate(var TotalPurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesUpdateTotalsControlsOnBeforeCheckDocumentNo(CurrentSalesLine: Record "Sales Line"; var TotalSalesHeader: Record "Sales Header"; var TotalsSalesLine: Record "Sales Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; CurrPageEditable: Boolean; var VATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePurchaseSubPageTotalsOnAfterSetFilter(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseCheckNumberOfLinesLimit(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCheckNumberOfLinesLimit(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePurchasePageTotalsOnAfterCalculateVATAmount(var TotalPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var PurchaseLine: Record "Purchase Line"; var TotalPurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCalculateTotalsWithInvoiceRounding(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseUpdateTotals(var PurchaseHeader: Record "Purchase Header"; var PreviousTotalPurchaseHeader: Record "Purchase Header"; CurrentPurchaseLine: Record "Purchase Line"; var TotalsPurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; Force: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTotals(var TotalSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalSalesAmountOnlyDiscountAllowed(var TotalSalesLine: Record "Sales Line")
    begin
    end;
}

