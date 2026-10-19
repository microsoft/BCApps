namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.ReceivablesPayables;

codeunit 12285 "FatturaPA Preview Mgt."
{
    /// <summary>
    /// Prepares standard temporary FatturaPA buffers from an unposted sales document,
    /// using posting preview for VAT and receivables accounting without consuming
    /// the FatturaPA transmission number series.
    /// </summary>
    procedure PreparePreview(
        SalesHeader: Record "Sales Header";
        PreviewProgressiveNo: Code[20];
        var TempFatturaHeader: Record "Fattura Header" temporary;
        var TempFatturaLine: Record "Fattura Line" temporary)
    var
        PreviewCollector: Codeunit "FatturaPA Preview Collector";
        PreviewAccounting: Codeunit "FatturaPA Preview Accounting";
        TempVATEntry: Record "VAT Entry" temporary;
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
    begin
        ValidateSource(SalesHeader);
        if PreviewProgressiveNo = '' then
            Error('A preview progressive number must be supplied.');

        TempFatturaHeader.DeleteAll();
        TempFatturaLine.DeleteAll();

        BuildHeader(SalesHeader, PreviewProgressiveNo, TempFatturaHeader);
        BuildDocumentLines(SalesHeader, TempFatturaLine);

        // Use the real posting engine for accounting output.
        PreviewCollector.Collect(
            SalesHeader,
            TempVATEntry,
            TempCustLedgEntry,
            TempDtldCustLedgEntry);

        PreviewAccounting.AddVATRows(
            TempFatturaLine,
            TempVATEntry,
            SalesHeader."Bill-to Customer No.",
            SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo");
        if (SalesHeader."Payment Method Code" <> '') and (SalesHeader."Payment Terms Code" <> '') then
            PreviewAccounting.AddPaymentRows(
                TempFatturaLine,
                TempCustLedgEntry,
                TempDtldCustLedgEntry);

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SetPreviewDocumentTotal(TempFatturaHeader, TempDtldCustLedgEntry)
        else
            SetPreviewDocumentTotalFromSource(SalesHeader, TempFatturaHeader);
    end;

    local procedure BuildHeader(
        SalesHeader: Record "Sales Header";
        PreviewProgressiveNo: Code[20];
        var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        Customer.Get(SalesHeader."Bill-to Customer No.");

        TempFatturaHeader.Init();
        TempFatturaHeader."Customer No" := Customer."No.";
        TempFatturaHeader."Document No." := SalesHeader."No.";
        TempFatturaHeader."Posting Date" := ResolvePreviewDate(SalesHeader);
        TempFatturaHeader."Payment Method Code" := SalesHeader."Payment Method Code";
        TempFatturaHeader."Payment Terms Code" := SalesHeader."Payment Terms Code";
        TempFatturaHeader."Fattura Project Code" := SalesHeader."Fattura Project Code";
        TempFatturaHeader."Fattura Tender Code" := SalesHeader."Fattura Tender Code";
        TempFatturaHeader."Customer Purchase Order No." := SalesHeader."Customer Purchase Order No.";
        TempFatturaHeader."Currency Code" := SalesHeader."Currency Code";
        TempFatturaHeader."Currency Factor" := SalesHeader."Currency Factor";
        TempFatturaHeader."Total Inv. Discount" := ConvertToLCY(SalesHeader, SalesHeader."Invoice Discount Amount");
        TempFatturaHeader."Fattura Stamp" := SalesHeader."Fattura Stamp";
        TempFatturaHeader."Fattura Stamp Amount" := SalesHeader."Fattura Stamp Amount";
        TempFatturaHeader."Entry Type" := TempFatturaHeader."Entry Type"::Sales;
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::"Credit Memo":
                TempFatturaHeader."Document Type" := TempFatturaHeader."Document Type"::"Credit Memo";
            else
                TempFatturaHeader."Document Type" := TempFatturaHeader."Document Type"::Invoice;
        end;
        TempFatturaHeader."Progressive No." := PreviewProgressiveNo;

        FatturaDocHelper.PopulatePreviewHeaderFiscalIdentity(
            TempFatturaHeader, Customer, SalesHeader."Fattura Document Type");

        if PaymentMethod.Get(SalesHeader."Payment Method Code") then
            TempFatturaHeader."Fattura PA Payment Method" :=
                PaymentMethod."Fattura PA Payment Method";

        if PaymentTerms.Get(SalesHeader."Payment Terms Code") then
            TempFatturaHeader."Fattura Payment Terms Code" :=
                PaymentTerms."Fattura Payment Terms Code";

        TempFatturaHeader.Insert();
    end;

    local procedure BuildDocumentLines(
        SalesHeader: Record "Sales Header";
        var TempFatturaLine: Record "Fattura Line" temporary)
    var
        SalesLine: Record "Sales Line";
        DocumentLineNo: Integer;
        EffectiveQty: Decimal;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        TempFatturaHeader: Record "Fattura Header" temporary;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if not SalesLine.FindSet() then
            exit;

        repeat
            if SalesLine.Type <> SalesLine.Type::" " then begin
                EffectiveQty := GetEffectiveQtyToInvoice(SalesHeader, SalesLine);
                if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) or
                   (EffectiveQty <> 0)
                then begin
                    TempFatturaHeader."Customer No" := SalesHeader."Bill-to Customer No.";
                    TempFatturaHeader."Currency Code" := SalesHeader."Currency Code";
                    TempFatturaHeader."Currency Factor" := SalesHeader."Currency Factor";
                    TempFatturaHeader."Posting Date" := ResolvePreviewDate(SalesHeader);
                    FatturaDocHelper.InsertPreviewSalesLine(
                        TempFatturaLine, DocumentLineNo, TempFatturaHeader, SalesLine,
                        EffectiveQty, GetEffectiveLineAmount(SalesHeader, SalesLine, EffectiveQty),
                        SalesHeader."Prices Including VAT");
                end;
            end;
        until SalesLine.Next() = 0;
    end;

    local procedure GetEffectiveLineAmount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; EffectiveQty: Decimal): Decimal
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            exit(CalcOrderLineAmountToInvoice(SalesHeader, SalesLine, EffectiveQty));
        exit(SalesLine."Line Amount");
    end;

    local procedure GetEffectiveQtyToInvoice(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line"): Decimal
    var
        AllowedQtyToInvoice: Decimal;
    begin
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit(SalesLine.Quantity);

        AllowedQtyToInvoice :=
            SalesLine."Qty. Shipped Not Invoiced" +
            SalesLine."Qty. to Ship";

        if Abs(SalesLine."Qty. to Invoice") > Abs(AllowedQtyToInvoice) then
            exit(AllowedQtyToInvoice);

        exit(SalesLine."Qty. to Invoice");
    end;

    local procedure CalcOrderLineAmountToInvoice(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        EffectiveQty: Decimal): Decimal
    var
        Currency: Record Currency;
        Precision: Decimal;
    begin
        if (EffectiveQty = 0) or (SalesLine.Quantity = 0) then
            exit(0);

        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesHeader."Currency Code");

        Precision := Currency."Amount Rounding Precision";
        if Precision = 0 then
            Precision := 0.01;

        exit(
            Round(
                SalesLine.Amount * EffectiveQty / SalesLine.Quantity,
                Precision));
    end;

    local procedure SetPreviewDocumentTotalFromSource(
        SalesHeader: Record "Sales Header";
        var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        TempFatturaHeader.Reset();
        if TempFatturaHeader.FindFirst() then begin
            TempFatturaHeader."Total Amount" :=
                FatturaDocHelper.GetPreviewSalesDocumentTotal(SalesHeader, TempFatturaHeader);
            TempFatturaHeader.Modify();
        end;
    end;

    local procedure SetPreviewDocumentTotal(
        var TempFatturaHeader: Record "Fattura Header" temporary;
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary)
    var
        TotalAmount: Decimal;
    begin
        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.SetRange(
            "Entry Type",
            TempDtldCustLedgEntry."Entry Type"::"Initial Entry");

        if TempDtldCustLedgEntry.FindSet() then
            repeat
                TotalAmount += TempDtldCustLedgEntry.Amount;
            until TempDtldCustLedgEntry.Next() = 0;

        TempFatturaHeader.Reset();
        if TempFatturaHeader.FindFirst() then begin
            TempFatturaHeader."Total Amount" := Abs(TotalAmount);
            TempFatturaHeader.Modify();
        end;
    end;

    local procedure ConvertToLCY(SalesHeader: Record "Sales Header"; Amount: Decimal): Decimal
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        TempFatturaHeader: Record "Fattura Header" temporary;
    begin
        TempFatturaHeader."Currency Code" := SalesHeader."Currency Code";
        TempFatturaHeader."Currency Factor" := SalesHeader."Currency Factor";
        TempFatturaHeader."Posting Date" := ResolvePreviewDate(SalesHeader);
        exit(FatturaDocHelper.ExchangePreviewAmountToLCY(TempFatturaHeader, Amount));
    end;

    local procedure ResolvePreviewDate(SalesHeader: Record "Sales Header"): Date
    begin
        if SalesHeader."Posting Date" <> 0D then
            exit(SalesHeader."Posting Date");
        if SalesHeader."Document Date" <> 0D then
            exit(SalesHeader."Document Date");
        exit(WorkDate());
    end;

    local procedure ValidateSource(SalesHeader: Record "Sales Header")
    begin
        if not (SalesHeader."Document Type" in
            [SalesHeader."Document Type"::Order,
             SalesHeader."Document Type"::Invoice,
             SalesHeader."Document Type"::"Credit Memo"])
        then
            Error(UnsupportedDocumentTypeErr, SalesHeader."Document Type");

        SalesHeader.TestField("Bill-to Customer No.");
    end;

    var
        UnsupportedDocumentTypeErr: Label 'FatturaPA preview supports Sales Orders, Sales Invoices and Sales Credit Memos. Current document type: %1.';
}
