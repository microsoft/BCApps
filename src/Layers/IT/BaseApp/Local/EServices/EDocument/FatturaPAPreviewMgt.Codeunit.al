namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.History;
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
        BuildSourceReferences(SalesHeader, TempFatturaHeader, TempFatturaLine);

        // Use the real posting engine for accounting output.
        PreviewCollector.Collect(
            SalesHeader,
            TempVATEntry,
            TempCustLedgEntry,
            TempDtldCustLedgEntry);

        PopulateTaxRepresentative(TempFatturaHeader, TempVATEntry);

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

    local procedure PopulateTaxRepresentative(
        var TempFatturaHeader: Record "Fattura Header" temporary;
        var TempVATEntry: Record "VAT Entry" temporary)
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        TempFatturaHeader.Reset();
        if TempFatturaHeader.FindFirst() then begin
            FatturaDocHelper.PopulatePreviewTaxRepresentative(TempFatturaHeader, TempVATEntry);
            TempFatturaHeader.Modify();
        end;
    end;

    local procedure BuildHeader(
        SalesHeader: Record "Sales Header";
        PreviewProgressiveNo: Code[20];
        var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        Customer.Get(SalesHeader."Bill-to Customer No.");
        SalesHeader.CalcFields("Invoice Discount Amount");

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
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            TempFatturaHeader."Total Inv. Discount" :=
                ConvertToLCY(SalesHeader, GetOrderInvoiceDiscountToInvoice(SalesHeader))
        else
            TempFatturaHeader."Total Inv. Discount" :=
                ConvertToLCY(SalesHeader, SalesHeader."Invoice Discount Amount");
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

        FatturaDocHelper.PopulateFatturaPaymentCodes(TempFatturaHeader, PaymentMethod);

        if (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") and
           (SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Invoice) and
           (SalesHeader."Applies-to Doc. No." <> '')
        then
            PopulateKnownApplication(SalesHeader, TempFatturaHeader);

        TempFatturaHeader.Insert();
    end;

    local procedure PopulateKnownApplication(
        SalesHeader: Record "Sales Header";
        var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        AppliedCustLedgerEntry: Record "Cust. Ledger Entry";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        AppliedCustLedgerEntry.SetRange("Customer No.", SalesHeader."Bill-to Customer No.");
        AppliedCustLedgerEntry.SetRange("Document Type", AppliedCustLedgerEntry."Document Type"::Invoice);
        AppliedCustLedgerEntry.SetRange("Document No.", SalesHeader."Applies-to Doc. No.");
        if not AppliedCustLedgerEntry.FindFirst() then
            exit;

        FatturaDocHelper.PopulateAppliedDocumentInformation(TempFatturaHeader, AppliedCustLedgerEntry);
    end;

    local procedure BuildSourceReferences(
        SalesHeader: Record "Sales Header";
        var TempFatturaHeader: Record "Fattura Header" temporary;
        var TempFatturaLine: Record "Fattura Line" temporary)
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TempShipmentBuffer: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        HasShipmentReference: Boolean;
        FatturaLineNo: Integer;
    begin
        TempFatturaHeader.Reset();
        if not TempFatturaHeader.FindFirst() then
            exit;

        // Direct invoices created with Get Shipment Lines already know their
        // shipment numbers. Posted export uses the same shipment-header mapper.
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            if SalesLine.FindSet() then
                repeat
                    // Posted Get Shipment Lines exports use the original source-line
                    // ordinal, including comment/split lines, for fiscal references.
                    FatturaLineNo += 1;
                    if FatturaDocHelper.ShouldIncludePreviewSalesLine(
                        SalesHeader, SalesLine, GetEffectiveQtyToInvoice(SalesHeader, SalesLine))
                    then begin
                        if (SalesLine.Type = SalesLine.Type::Item) and
                           (SalesLine."Shipment No." <> '')
                        then
                            if FatturaDocHelper.InsertSalesShipmentReference(
                                TempShipmentBuffer, SalesLine."Shipment No.", FatturaLineNo, false)
                            then
                                HasShipmentReference := true;
                    end;
                until SalesLine.Next() = 0;
        end;

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            // Keep DDT line references in the same commercial-line order as
            // BuildDocumentLines, including non-item lines preceding an item.
            if SalesLine.FindSet() then
                repeat
                    if FatturaDocHelper.ShouldIncludePreviewSalesLine(
                        SalesHeader, SalesLine, GetEffectiveQtyToInvoice(SalesHeader, SalesLine))
                    then begin
                        FatturaLineNo += 1;
                        if SalesLine.Type = SalesLine.Type::Item then
                            AddPendingShipmentReferences(
                                SalesHeader, SalesLine, TempShipmentBuffer, FatturaLineNo, HasShipmentReference);
                    end;
                until SalesLine.Next() = 0;
        end;

        // Standard export derives order metadata from shipment information.
        // A direct invoice with only a customer PO does not generate an Order row.
        // For sales orders, prepare known order metadata without inventing a DDT.
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) and
           (SalesHeader."Customer Purchase Order No." <> '') and not HasShipmentReference
        then begin
            TempFatturaLine.Reset();
            TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Order);
            TempFatturaLine.Init();
            TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Order;
            TempFatturaLine."Line No." := 1;
            TempFatturaLine."Document No." := SalesHeader."No.";
            TempFatturaLine."Customer Purchase Order No." := SalesHeader."Customer Purchase Order No.";
            TempFatturaLine."Fattura Project Code" := SalesHeader."Fattura Project Code";
            TempFatturaLine."Fattura Tender Code" := SalesHeader."Fattura Tender Code";
            TempFatturaLine.Insert();
            TempFatturaLine.Reset();
        end else
            if HasShipmentReference then
                FatturaDocHelper.BuildPreviewOrderShipmentBuffers(
                    TempFatturaLine, TempShipmentBuffer, TempFatturaHeader);
    end;

    local procedure AddPendingShipmentReferences(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        var TempShipmentBuffer: Record "Fattura Line" temporary;
        FatturaLineNo: Integer;
        var HasShipmentReference: Boolean)
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // Before posting the order line holds the cumulative quantity already invoiced.
        // The shared helper reconstructs the same shipment allocation for posted output.
        FatturaDocHelper.CollectOrderShipmentReferences(
            TempShipmentBuffer, SalesHeader."No.", SalesLine."Line No.", FatturaLineNo,
            Abs(SalesLine."Qty. to Invoice"), Abs(SalesLine."Quantity Invoiced"),
            HasShipmentReference);
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
            EffectiveQty := GetEffectiveQtyToInvoice(SalesHeader, SalesLine);
            if FatturaDocHelper.ShouldIncludePreviewSalesLine(SalesHeader, SalesLine, EffectiveQty) then begin
                    TempFatturaHeader."Customer No" := SalesHeader."Bill-to Customer No.";
                    TempFatturaHeader."Currency Code" := SalesHeader."Currency Code";
                    TempFatturaHeader."Currency Factor" := SalesHeader."Currency Factor";
                    TempFatturaHeader."Posting Date" := ResolvePreviewDate(SalesHeader);
                    FatturaDocHelper.InsertPreviewSalesLine(
                        TempFatturaLine, DocumentLineNo, TempFatturaHeader, SalesLine,
                        EffectiveQty, GetEffectiveLineAmount(SalesHeader, SalesLine, EffectiveQty),
                        SalesHeader."Prices Including VAT");
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

    local procedure GetOrderInvoiceDiscountToInvoice(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        EffectiveQuantity: Decimal;
        TotalDiscount: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                EffectiveQuantity := GetEffectiveQtyToInvoice(SalesHeader, SalesLine);
                if FatturaDocHelper.ShouldIncludePreviewSalesLine(SalesHeader, SalesLine, EffectiveQuantity) then
                    TotalDiscount += FatturaDocHelper.ProrateFatturaInvoiceDiscount(
                        SalesLine."Inv. Discount Amount", SalesLine.Quantity, EffectiveQuantity);
            until SalesLine.Next() = 0;
        exit(TotalDiscount);
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
                // Standard posted export uses "Line Amount" before separately
                // applying "Inv. Discount Amount" in PopulateFatturaLineAmounts.
                // SalesLine.Amount is already net of that invoice discount.
                SalesLine."Line Amount" * EffectiveQty / SalesLine.Quantity,
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
