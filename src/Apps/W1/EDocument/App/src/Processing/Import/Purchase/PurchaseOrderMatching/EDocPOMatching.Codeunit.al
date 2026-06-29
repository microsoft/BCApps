// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

codeunit 6196 "E-Doc. PO Matching"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Loads all purchase order lines that can be matched to the specified E-Document line into the specified temporary Purchase Line record.
    /// A line can be matched if it belongs to an order for the same vendor as the E-Document line, and if it is not already matched to another E-Document line.
    /// Lines that are already matched to the specified E-Document line are included.
    /// By default if the e-document has an order number specified, the results are filtered to only include lines from such order, unless the resulting set is empty.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseLine"></param>
    procedure LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        IncludePOLine: Boolean;
    begin
        Clear(TempPurchaseLine);
        TempPurchaseLine.DeleteAll();
        Vendor := EDocumentPurchaseLine.GetBCVendor();
        if Vendor."No." = '' then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Pay-to Vendor No.", Vendor."No.");
        if EDocumentPurchaseLine."[BC] Unit of Measure" <> '' then
            PurchaseLine.SetRange("Unit of Measure Code", EDocumentPurchaseLine."[BC] Unit of Measure");
        PurchaseLine.SetLoadFields("Document No.", "Line No.", Description, Quantity, "Qty. Invoiced (Base)", "Qty. Received (Base)", Type, "No.", "Quantity Received", "Quantity Invoiced");
        if PurchaseLine.FindSet() then
            repeat
                // We exclude lines that have already been matched unless they were matched to the current line
                EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId);
                EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
                IncludePOLine := not EDocPurchaseLinePOMatch.IsEmpty();
                if not IncludePOLine then begin
                    EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId");
                    IncludePOLine := EDocPurchaseLinePOMatch.IsEmpty();
                end;
                if IncludePOLine then begin
                    Clear(TempPurchaseLine);
                    TempPurchaseLine := PurchaseLine;
                    TempPurchaseLine.Insert();
                end;
            until PurchaseLine.Next() = 0;
        if EDocumentPurchaseHeader.Get(EDocumentPurchaseLine."E-Document Entry No.") then
            if EDocumentPurchaseHeader."[BC] Purchase Order No." <> '' then begin
                TempPurchaseLine.SetRange("Document No.", EDocumentPurchaseHeader."[BC] Purchase Order No.");
                if TempPurchaseLine.IsEmpty() then
                    TempPurchaseLine.SetRange("Document No.")
            end;
    end;

    /// <summary>
    /// Loads all purchase order lines that are matched to the specified E-Document line into the specified temporary Purchase Line record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseLine"></param>
    procedure LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        PurchaseLine: Record "Purchase Line";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        Clear(TempPurchaseLine);
        TempPurchaseLine.DeleteAll();
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetRange("Receipt Line SystemId", NullGuid);
        if EDocPurchaseLinePOMatch.FindSet() then
            repeat
                if PurchaseLine.GetBySystemId(EDocPurchaseLinePOMatch."Purchase Line SystemId") then begin
                    Clear(TempPurchaseLine);
                    TempPurchaseLine := PurchaseLine;
                    TempPurchaseLine.Insert();
                end;
            until EDocPurchaseLinePOMatch.Next() = 0;
    end;

    /// <summary>
    /// Loads all purchase orders that are matched to the specified E-Document line into the specified temporary Purchase Header record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseHeader"></param>
    procedure LoadPOsMatchedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseHeader: Record "Purchase Header" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Clear(TempPurchaseHeader);
        TempPurchaseHeader.DeleteAll();
        LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);
        if TempPurchaseLine.FindSet() then
            repeat
                if PurchaseHeader.Get(Enum::"Purchase Document Type"::Order, TempPurchaseLine."Document No.") then begin
                    Clear(TempPurchaseHeader);
                    TempPurchaseHeader := PurchaseHeader;
                    if TempPurchaseHeader.Insert() then;
                end;
            until TempPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Loads all purchase receipt lines that are matched to purchase order lines that are matched to the specified E-Document line into the specified temporary Purch. Rcpt. Line record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseReceiptLine"></param>
    procedure LoadAvailableReceiptLinesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary)
    var
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempMatchedPurchaseLines: Record "Purchase Line" temporary;
    begin
        Clear(TempPurchaseReceiptLine);
        TempPurchaseReceiptLine.DeleteAll();
        LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempMatchedPurchaseLines);
        if TempMatchedPurchaseLines.FindSet() then
            repeat
                PurchaseReceiptLine.SetRange("Order No.", TempMatchedPurchaseLines."Document No.");
                PurchaseReceiptLine.SetRange("Order Line No.", TempMatchedPurchaseLines."Line No.");
                if PurchaseReceiptLine.FindSet() then
                    repeat
                        if PurchaseReceiptLine.Quantity <> 0 then begin
                            Clear(TempPurchaseReceiptLine);
                            TempPurchaseReceiptLine := PurchaseReceiptLine;
                            TempPurchaseReceiptLine.Insert();
                        end;
                    until PurchaseReceiptLine.Next() = 0;
            until TempMatchedPurchaseLines.Next() = 0;
    end;

    /// <summary>
    /// Loads all purchase receipt headers that are matched to the specified E-Document line into the specified temporary Purch. Rcpt. Header record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseReceiptHeader"></param>
    procedure LoadReceiptsMatchedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseReceiptHeader: Record "Purch. Rcpt. Header" temporary)
    var
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        Clear(TempPurchaseReceiptHeader);
        TempPurchaseReceiptHeader.DeleteAll();
        LoadReceiptLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptLine);
        if TempPurchaseReceiptLine.FindSet() then
            repeat
                if PurchaseReceiptHeader.Get(TempPurchaseReceiptLine."Document No.") then begin
                    Clear(TempPurchaseReceiptHeader);
                    TempPurchaseReceiptHeader := PurchaseReceiptHeader;
                    if TempPurchaseReceiptHeader.Insert() then;
                end;
            until TempPurchaseReceiptLine.Next() = 0;
    end;

    procedure LoadReceiptLinesMatchedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary)
    var
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        Clear(TempPurchaseReceiptLine);
        TempPurchaseReceiptLine.DeleteAll();
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        if EDocPurchaseLinePOMatch.FindSet() then
            repeat
                if PurchaseReceiptLine.GetBySystemId(EDocPurchaseLinePOMatch."Receipt Line SystemId") then begin
                    Clear(TempPurchaseReceiptLine);
                    TempPurchaseReceiptLine := PurchaseReceiptLine;
                    TempPurchaseReceiptLine.Insert();
                end;
            until EDocPurchaseLinePOMatch.Next() = 0;
    end;

    /// <summary>
    /// Calculates warnings for the specified E-Document, and loads them into the specified temporary "E-Doc PO Match Warnings" record.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    /// <param name="POMatchWarnings"></param>
    procedure CalculatePOMatchWarnings(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var POMatchWarnings: Record "E-Doc PO Match Warning" temporary)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        Clear(POMatchWarnings);
        POMatchWarnings.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                AppendPOMatchWarnings(EDocumentPurchaseLine, POMatchWarnings);
            until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Appends the warnings for the given invoice line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="POMatchWarnings"></param>
    local procedure AppendPOMatchWarnings(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var POMatchWarnings: Record "E-Doc PO Match Warning" temporary)
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        EDocLineQuantity: Decimal;
        PurchaseLinesQuantity, PurchaseLinesQuantityInvoiced, PurchaseLinesQuantityReceived : Decimal;
        RemainingToInvoice, InvoiceableQty : Decimal;
        EDocNetUnitCost, ExpectedPONetUnitCost, AmountPctDiff, AmountThreshold : Decimal;
        ExceedsInvoiceableQtyLbl: Label 'Invoice quantity (%1) exceeds what can be invoiced according to what has been received (%2) by %3. The order line has to be received before invoicing.', Comment = '%1 = Invoice qty, %2 = Invoiceable qty, %3 = Difference';
        ExceedsRemainingToInvoiceLbl: Label 'Invoice quantity (%1) exceeds what is missing to invoice from the order (%2) by %3.', Comment = '%1 = Invoice qty, %2 = Remaining to invoice, %3 = Difference';
        OverReceiptLbl: Label 'Invoice will close out order but there is an over-receipt of %1 units.', Comment = '%1 = Over-receipt quantity';
        AmountMismatchLbl: Label 'Invoiced unit cost (%1) differs from the order''s unit cost (%2) by %3%, which exceeds the allowed %4%.', Comment = '%1 = Invoiced net unit cost, %2 = Order net unit cost, %3 = Actual % difference, %4 = Allowed % tolerance';
    begin
        LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);
        PurchaseLinesQuantityInvoiced := 0;
        PurchaseLinesQuantityReceived := 0;
        PurchaseLinesQuantity := 0;
        if not TempPurchaseLine.FindSet() then
            exit;
        repeat
            PurchaseLinesQuantityInvoiced += TempPurchaseLine."Qty. Invoiced (Base)";
            PurchaseLinesQuantityReceived += TempPurchaseLine."Qty. Received (Base)";
            PurchaseLinesQuantity += TempPurchaseLine.Quantity;
        until TempPurchaseLine.Next() = 0;

        if not GetEDocumentLineQuantityInBaseUoM(EDocumentPurchaseLine, EDocLineQuantity) then begin
            POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::MissingInformationForMatch;
            POMatchWarnings.Insert();
            exit;
        end;

        //   I = Invoice quantity (from the e-document line)
        //   R = Remaining to invoice on the PO (Ordered - Previously Invoiced)
        //   J = Invoiceable quantity (Received - Previously Invoiced)
        RemainingToInvoice := PurchaseLinesQuantity - PurchaseLinesQuantityInvoiced;
        InvoiceableQty := PurchaseLinesQuantityReceived - PurchaseLinesQuantityInvoiced;

        // I > J: Invoice exceeds what has been received and not yet invoiced 
        if EDocLineQuantity > InvoiceableQty then
            if ShouldWarnIfNotYetReceived(TempPurchaseLine) then begin
                POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::ExceedsInvoiceableQty;
                POMatchWarnings."Warning Message" := CopyStr(StrSubstNo(ExceedsInvoiceableQtyLbl, EDocLineQuantity, InvoiceableQty, EDocLineQuantity - InvoiceableQty), 1, MaxStrLen(POMatchWarnings."Warning Message"));
                POMatchWarnings.Insert();
            end;

        // I > R: Invoice exceeds what remains on the order 
        if EDocLineQuantity > RemainingToInvoice then begin
            POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::ExceedsRemainingToInvoice;
            POMatchWarnings."Warning Message" := CopyStr(StrSubstNo(ExceedsRemainingToInvoiceLbl, EDocLineQuantity, RemainingToInvoice, EDocLineQuantity - RemainingToInvoice), 1, MaxStrLen(POMatchWarnings."Warning Message"));
            POMatchWarnings.Insert();
        end;

        // I = R and I < J: Order will be closed but there is an over-receipt
        if (EDocLineQuantity = RemainingToInvoice) and (EDocLineQuantity < InvoiceableQty) then begin
            POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::OverReceipt;
            POMatchWarnings."Warning Message" := CopyStr(StrSubstNo(OverReceiptLbl, InvoiceableQty - RemainingToInvoice), 1, MaxStrLen(POMatchWarnings."Warning Message"));
            POMatchWarnings.Insert();
        end;

        // Invoiced unit cost differs from the order's unit cost beyond the allowed tolerance
        if ShouldWarnAmountMismatch(EDocumentPurchaseLine, TempPurchaseLine, EDocNetUnitCost, ExpectedPONetUnitCost, AmountPctDiff, AmountThreshold) then begin
            POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::AmountMismatch;
            POMatchWarnings."Warning Message" := CopyStr(StrSubstNo(AmountMismatchLbl, EDocNetUnitCost, ExpectedPONetUnitCost, Round(AmountPctDiff, 0.1), AmountThreshold), 1, MaxStrLen(POMatchWarnings."Warning Message"));
            POMatchWarnings.Insert();
        end;
    end;

    /// <summary>
    /// Determines whether the invoiced net unit cost of the e-document line differs from the matched purchase order lines' net unit cost
    /// by more than the percentage configured in "E-Document Matching Difference" on Purchases Payables Setup.
    /// Differences within the currency rounding precision, or when currencies don't match, never warn.
    /// </summary>
    /// <param name="EDocumentPurchaseLine">The e-document invoice draft line.</param>
    /// <param name="TempPurchaseLine">Purchase order lines matched to the e-document line.</param>
    /// <param name="EDocNetUnitCost">Out: the invoiced net unit cost (Unit Price less per-unit discount).</param>
    /// <param name="ExpectedPONetUnitCost">Out: the quantity-weighted net unit cost of the matched order lines.</param>
    /// <param name="PctDiff">Out: the actual percentage difference between the two unit costs.</param>
    /// <param name="Threshold">Out: the allowed percentage difference read from setup.</param>
    /// <returns>True if a warning should be raised.</returns>
    local procedure ShouldWarnAmountMismatch(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; var EDocNetUnitCost: Decimal; var ExpectedPONetUnitCost: Decimal; var PctDiff: Decimal; var Threshold: Decimal): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        WeightedNetCostNumerator, TotalPOQuantity, AbsDiff, RoundingFloor : Decimal;
        EDocCurrencyCode: Code[10];
    begin
        Clear(EDocNetUnitCost);
        Clear(ExpectedPONetUnitCost);
        Clear(PctDiff);
        Clear(Threshold);

        // Without a quantity we can't derive a unit cost from the line amount.
        if EDocumentPurchaseLine.Quantity = 0 then
            exit(false);

        if not TempPurchaseLine.FindSet() then
            exit(false);
        // A blank currency code means the local currency, so normalize both sides before comparing.
        GeneralLedgerSetup.Get();
        EDocCurrencyCode := NormalizeEmptyCurrencyCode(EDocumentPurchaseLine."Currency Code", GeneralLedgerSetup);
        repeat
            // The unit cost comparison is only meaningful within a single currency; we don't convert across currencies.
            if EDocCurrencyCode <> NormalizeEmptyCurrencyCode(TempPurchaseLine."Currency Code", GeneralLedgerSetup) then
                exit(false);
            WeightedNetCostNumerator += TempPurchaseLine."Direct Unit Cost" * (1 - TempPurchaseLine."Line Discount %" / 100) * TempPurchaseLine.Quantity;
            TotalPOQuantity += TempPurchaseLine.Quantity;
        until TempPurchaseLine.Next() = 0;

        if TotalPOQuantity = 0 then
            exit(false);

        // The draft line's discount is an absolute amount, so we net it out of the line total before dividing by quantity.
        EDocNetUnitCost := (EDocumentPurchaseLine.Quantity * EDocumentPurchaseLine."Unit Price" - EDocumentPurchaseLine."Total Discount") / EDocumentPurchaseLine.Quantity;
        // A non-positive invoiced unit cost means the line carries no usable price to compare; that's a missing-price situation, not a price mismatch.
        if EDocNetUnitCost <= 0 then
            exit(false);
        ExpectedPONetUnitCost := WeightedNetCostNumerator / TotalPOQuantity;
        if ExpectedPONetUnitCost <= 0 then
            exit(false);

        if PurchasesPayablesSetup.Get() then
            Threshold := PurchasesPayablesSetup."E-Document Matching Difference";

        // Differences within the currency rounding precision are noise and never warn, even when the tolerance is 0.
        AbsDiff := Abs(ExpectedPONetUnitCost - EDocNetUnitCost);
        RoundingFloor := EDocumentImportHelper.GetCurrencyRoundingPrecision(EDocumentPurchaseLine."Currency Code");
        if AbsDiff <= RoundingFloor then
            exit(false);

        PctDiff := AbsDiff * 100 / ExpectedPONetUnitCost;
        exit(PctDiff > Threshold);
    end;

    local procedure NormalizeEmptyCurrencyCode(CurrencyCode: Code[10]; GeneralLedgerSetup: Record "General Ledger Setup"): Code[10]
    begin
        if CurrencyCode = '' then
            exit(GeneralLedgerSetup."LCY Code");
        exit(CurrencyCode);
    end;

    /// <summary>
    /// Validates that the matches between the E-Document, PO lines and receipt lines are still valid.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    /// <returns>True if the matches are consistent, false otherwise.</returns>
    procedure IsPOMatchConsistent(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
    begin
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit(true);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
                if EDocPurchaseLinePOMatch.FindSet() then
                    repeat
                        if not IsNullGuid(EDocPurchaseLinePOMatch."Receipt Line SystemId") then
                            if not PurchaseReceiptLine.GetBySystemId(EDocPurchaseLinePOMatch."Receipt Line SystemId") then
                                exit(false);
                        if not PurchaseLine.GetBySystemId(EDocPurchaseLinePOMatch."Purchase Line SystemId") then
                            exit(false);
                    until EDocPurchaseLinePOMatch.Next() = 0;
            until EDocumentPurchaseLine.Next() = 0;
        exit(true);
    end;

    /// <summary>
    /// Returns true if the specified E-Document line is matched to any purchase order line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    /// <summary>
    /// Returns true if any line in the specified E-Document is matched to any purchase order line.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    /// <returns></returns>
    procedure IsEDocumentMatchedToAnyPOLine(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        if IsNullGuid(EDocumentPurchaseHeader.SystemId) then
            exit(false);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if not EDocumentPurchaseLine.FindSet() then
            exit(false);
        repeat
            if IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine) then
                exit(true);
        until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Returns true if the specified purchase order line is matched to the specified E-Document line.
    /// </summary>
    /// <param name="PurchaseLine"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsPOLineMatchedToEDocumentLine(PurchaseLine: Record "Purchase Line"; EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
    begin
        EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    /// <summary>
    /// Checks if the specified E-Document line is matched to any receipt line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    /// <summary>
    /// Returns true if the specified receipt line is matched to the specified E-Document line.
    /// </summary>
    /// <param name="ReceiptLine"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsReceiptLineMatchedToEDocumentLine(ReceiptLine: Record "Purch. Rcpt. Line"; EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
    begin
        EDocPurchaseLinePOMatch.SetRange("Receipt Line SystemId", ReceiptLine.SystemId);
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    /// <summary>
    /// Removes all receipt line matches for the specified E-Document line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    procedure RemoveAllReceiptMatchesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        EDocPurchaseLinePOMatch.DeleteAll();
    end;

    /// <summary>
    /// Removes all matches for the specified E-Document line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    procedure RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.DeleteAll();
    end;

    /// <summary>
    /// Removes all matches for all lines in the specified E-Document.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    procedure RemoveAllMatchesForEDocument(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
            until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Matches the specified purchase order lines to the specified E-Document line.
    /// Each purchase order line must belong to an order for the same vendor as the E-Document line, and must not already be matched to another E-Document line.
    /// Existing matches are removed, and the E-Document line's purchase type and number are set to match the matched lines.
    /// The procedure raises an error if any of the specified lines is invalid.
    /// </summary>
    /// <param name="SelectedPOLines"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    procedure MatchPOLinesToEDocumentLine(var SelectedPOLines: Record "Purchase Line" temporary; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NotLinkedToVendorErr: Label 'The selected purchase order line is not linked to the same vendor as the e-document line.';
        AlreadyMatchedErr: Label 'A selected purchase order line is already matched to another e-document line. E-Document: %1, Purchase document: %2 %3.', Comment = '%1 - E-Document No., %2 - Purchase Document Type, %3 - Purchase Document No.';
        OrderLineAndEDocFromDifferentVendorsErr: Label 'All selected purchase order lines must belong to orders for the same vendor as the e-document line.';
        OrderLinesMustBeOfSameTypeAndNoErr: Label 'All selected purchase order lines must be of the same type and number.';
        OrderLinesMustHaveSameUoMErr: Label 'All selected purchase order lines must have the same unit of measure.';
        MatchedPOLineType: Enum "Purchase Line Type";
        MatchedPOLineVendorNo, MatchedPOLineTypeNo, MatchedUnitOfMeasure : Code[20];
        FirstOfLinesBeingMatched: Boolean;
    begin
        if SelectedPOLines.IsEmpty() then
            exit;
        RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
        FirstOfLinesBeingMatched := true;
        MatchedPOLineVendorNo := '';
        MatchedPOLineTypeNo := '';
        MatchedUnitOfMeasure := '';
        if SelectedPOLines.FindSet() then
            repeat
                // Create new matches, if each line being matched is valid
                PurchaseLine.SetLoadFields("Document Type", "No.", "Line No.", "Pay-to Vendor No.", Type);
                PurchaseLine.GetBySystemId(SelectedPOLines.SystemId);
                PurchaseLine.TestField("Document Type", PurchaseLine."Document Type"::Order);
                PurchaseLine.TestField("No."); // The line must have been assigned a number for it's purchase type
                Vendor := EDocumentPurchaseLine.GetBCVendor();
                if Vendor."No." = '' then
                    Error(NotLinkedToVendorErr);
                if PurchaseLine."Pay-to Vendor No." <> Vendor."No." then // The line must belong to an order for the same vendor as the E-Document line
                    Error(NotLinkedToVendorErr);
                EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId); // The PO Line must not already be matched to another E-Document line
                if not EDocPurchaseLinePOMatch.IsEmpty() then
                    Error(AlreadyMatchedErr, EDocumentPurchaseLine."E-Document Entry No.", SelectedPOLines."Document Type", SelectedPOLines."Document No.");
                if EDocumentPurchaseLine."[BC] Unit of Measure" <> '' then
                    PurchaseLine.TestField("Unit of Measure Code", EDocumentPurchaseLine."[BC] Unit of Measure");

                // We ensure that all matched lines have the same Vendor, Type, No. and Unit of Measure
                if FirstOfLinesBeingMatched then begin
                    MatchedPOLineType := PurchaseLine.Type;
                    MatchedPOLineTypeNo := PurchaseLine."No.";
                    MatchedPOLineVendorNo := PurchaseLine."Pay-to Vendor No.";
                    MatchedUnitOfMeasure := PurchaseLine."Unit of Measure Code";
                    FirstOfLinesBeingMatched := false;
                end else begin
                    if PurchaseLine.Type <> MatchedPOLineType then
                        Error(OrderLinesMustBeOfSameTypeAndNoErr);
                    if PurchaseLine."No." <> MatchedPOLineTypeNo then
                        Error(OrderLinesMustBeOfSameTypeAndNoErr);
                    if PurchaseLine."Pay-to Vendor No." <> MatchedPOLineVendorNo then
                        Error(OrderLineAndEDocFromDifferentVendorsErr);
                    if PurchaseLine."Unit of Measure Code" <> MatchedUnitOfMeasure then
                        Error(OrderLinesMustHaveSameUoMErr);
                end;
                Clear(EDocPurchaseLinePOMatch);
                EDocPurchaseLinePOMatch."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                EDocPurchaseLinePOMatch."Purchase Line SystemId" := PurchaseLine.SystemId;
                EDocPurchaseLinePOMatch.Insert();

            until SelectedPOLines.Next() = 0;
        // Set the E-Document Purchase Line properties to match the matched Purchase Line properties
        EDocumentPurchaseLine."[BC] Purchase Line Type" := MatchedPOLineType;
        EDocumentPurchaseLine."[BC] Purchase Type No." := MatchedPOLineTypeNo;
        EDocumentPurchaseLine."[BC] Unit of Measure" := MatchedUnitOfMeasure;
        EDocumentPurchaseLine.Modify();
    end;

    /// <summary>
    /// Matches the specified purchase receipt lines to the specified E-Document line.
    /// Each receipt line must be matched to a purchase order line that is matched to the specified E-Document line.
    /// Existing matches are removed.
    /// If the receipt lines can't cover the full quantity of the E-Document line, the procedure raises an error.
    /// </summary>
    /// <param name="SelectedReceiptLines"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    procedure MatchReceiptLinesToEDocumentLine(var SelectedReceiptLines: Record "Purch. Rcpt. Line" temporary; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        TempMatchedPurchaseLines: Record "Purchase Line" temporary;
        NullGuid: Guid;
        ReceiptLineNotMatchedErr: Label 'A selected receipt line is not matched to any of the purchase order lines matched to the e-document line.';
        ReceiptLinesDontCoverErr: Label 'The selected receipt lines do not cover the full quantity of the e-document line.';
        QuantityCovered: Decimal;
    begin
        if SelectedReceiptLines.IsEmpty() then
            exit;

        // Remove existing receipt line matches
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        EDocPurchaseLinePOMatch.DeleteAll();

        // Create new matches
        LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempMatchedPurchaseLines);
        SelectedReceiptLines.FindSet();
        repeat
            TempMatchedPurchaseLines.SetRange("Document No.", SelectedReceiptLines."Order No.");
            TempMatchedPurchaseLines.SetRange("Line No.", SelectedReceiptLines."Order Line No.");
            if not TempMatchedPurchaseLines.FindFirst() then
                Error(ReceiptLineNotMatchedErr);
            Clear(EDocPurchaseLinePOMatch);
            EDocPurchaseLinePOMatch."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            EDocPurchaseLinePOMatch."Purchase Line SystemId" := TempMatchedPurchaseLines.SystemId;
            EDocPurchaseLinePOMatch."Receipt Line SystemId" := SelectedReceiptLines.SystemId;
            EDocPurchaseLinePOMatch.Insert();
            QuantityCovered += SelectedReceiptLines.Quantity;
        until SelectedReceiptLines.Next() = 0;
        if QuantityCovered < EDocumentPurchaseLine.Quantity then
            Error(ReceiptLinesDontCoverErr);
    end;

    /// <summary>
    /// If the E-Document has been matched to an order line without specifying receipts, we match with receipt lines for that order line that can cover the E-Document line quantity.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    procedure SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader: Record "E-Document Purchase Header") // TODO: I think this is no longer needed? wdyt if instead of suggesting a receipt, we rely on the create invoice and the default functionality? now that we can have in baseapp PO-line level-only matches
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary;
        EDocLineQuantity: Decimal;
        NullGuid: Guid;
    begin
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                Clear(EDocPurchaseLinePOMatch);
                EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
                EDocPurchaseLinePOMatch.SetRange("Receipt Line SystemId", NullGuid);
                if not EDocPurchaseLinePOMatch.FindFirst() then
                    continue; // No PO lines matched, so no receipt can be suggested
                if not PurchaseOrderLine.GetBySystemId(EDocPurchaseLinePOMatch."Purchase Line SystemId") then
                    continue; // Should not happen, but we skip in case it does, this procedure doesn't error out
                EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseOrderLine.SystemId);
                EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<> %1', NullGuid);
                if not EDocPurchaseLinePOMatch.IsEmpty() then
                    continue; // There's already at least one receipt line matched, so no suggestion is needed
                Session.LogMessage('0000QQI', 'Suggesting receipt line for draft line matched to PO line', Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
                PurchaseReceiptLine.SetRange("Order No.", PurchaseOrderLine."Document No.");
                PurchaseReceiptLine.SetRange("Order Line No.", PurchaseOrderLine."Line No.");
                PurchaseReceiptLine.SetFilter(Quantity, '> 0');
                if PurchaseReceiptLine.FindSet() then
                    repeat
                        if GetEDocumentLineQuantityInBaseUoM(EDocumentPurchaseLine, EDocLineQuantity) then
                            if PurchaseReceiptLine.Quantity >= EDocLineQuantity then begin
                                // We suggest the first receipt line that can cover the full quantity of the E-Document line 
                                Session.LogMessage('0000QQJ', 'Suggested covering receipt line for draft line matched to PO line', Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
                                Clear(TempPurchaseReceiptLine);
                                TempPurchaseReceiptLine.DeleteAll();
                                TempPurchaseReceiptLine.Copy(PurchaseReceiptLine);
                                TempPurchaseReceiptLine.Insert();
                                MatchReceiptLinesToEDocumentLine(TempPurchaseReceiptLine, EDocumentPurchaseLine);
                                break; // We only suggest a single receipt line
                            end;
                    until PurchaseReceiptLine.Next() = 0;
            until EDocumentPurchaseLine.Next() = 0;
    end;

    local procedure GetEDocumentLineQuantityInBaseUoM(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var Quantity: Decimal): Boolean
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemFound, ItemUoMFound : Boolean;
    begin
        Clear(Quantity);
        if EDocumentPurchaseLine."[BC] Purchase Line Type" <> Enum::"Purchase Line Type"::Item then begin
            Quantity := EDocumentPurchaseLine.Quantity;
            exit(true);
        end;
        Item.SetLoadFields("No.");
        ItemFound := Item.Get(EDocumentPurchaseLine."[BC] Purchase Type No.");
        ItemUnitOfMeasure.SetLoadFields("Item No.", Code, "Qty. per Unit of Measure");
        ItemUoMFound := ItemUnitOfMeasure.Get(Item."No.", EDocumentPurchaseLine."[BC] Unit of Measure");
        if not (ItemFound and ItemUoMFound) then
            exit(false);
        Quantity := EDocumentPurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure";
        exit(true);
    end;

    /// <summary>
    /// Transfer PO matches defined in the e-document to the created purchase invoice
    /// </summary>
    /// <param name="EDocument"></param>
    procedure TransferPOMatchesFromEDocumentToInvoice(EDocument: Record "E-Document")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocPurchaseLinePOMatch, ReceiptPOMatches : Record "E-Doc. Purchase Line PO Match";
        InvoicePurchaseLine: Record "Purchase Line";
        OrderPurchaseLine: Record "Purchase Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
        UnitOfMeasureMgt: Codeunit "Unit of Measure Management";
        QtyToInvoice, QtyToInvoiceBase, RemainingBaseToDistribute, AutoReceive, AutoReceiveBase, QtyPerUoM : Decimal;
        NullGuid: Guid;
        CantDetermineEDocLineBaseQtyErr: Label 'Could not determine the quantity in base unit of measure for line %1.', Comment = '%1 = E-Document Line No.';
    begin
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                InvoicePurchaseLine := EDocumentPurchaseLine.GetLinkedPurchaseLine();
                if not IsNullGuid(InvoicePurchaseLine.SystemId) then begin
                    // The e-document line quantity is the total to invoice; we distribute it (in base UoM) across the matched order lines.
                    if not GetEDocumentLineQuantityInBaseUoM(EDocumentPurchaseLine, RemainingBaseToDistribute) then
                        Error(CantDetermineEDocLineBaseQtyErr, EDocumentPurchaseLine."Line No.");

                    // The matches without a receipt are the per-order-line rows: one for each purchase order line matched to the e-document line.
                    EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
                    EDocPurchaseLinePOMatch.SetRange("Receipt Line SystemId", NullGuid);
                    if EDocPurchaseLinePOMatch.FindSet() then
                        repeat
                            if OrderPurchaseLine.GetBySystemId(EDocPurchaseLinePOMatch."Purchase Line SystemId") then begin
                                // First we transfer the receipts specified for this order line: each one invoices its received-not-invoiced quantity, which we take out of what is left to distribute.
                                ReceiptPOMatches.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
                                ReceiptPOMatches.SetRange("Purchase Line SystemId", OrderPurchaseLine.SystemId);
                                ReceiptPOMatches.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
                                if ReceiptPOMatches.FindSet() then
                                    repeat
                                        if PurchaseReceiptLine.GetBySystemId(ReceiptPOMatches."Receipt Line SystemId") then begin
                                            // For each matched receipt, we assign the received-not-invoice quantity to be assigned as quantity to invoice
                                            QtyToInvoice := PurchaseReceiptLine."Qty. Rcd. Not Invoiced";
                                            QtyToInvoiceBase := OrderPurchaseLine.CalcBaseQty(QtyToInvoice, OrderPurchaseLine.FieldCaption("Qty. to Invoice"), OrderPurchaseLine.FieldCaption("Qty. to Invoice (Base)"));
                                            MatchedOrderLineMgmt.CreateMatchedOrderLine(InvoicePurchaseLine.SystemId, OrderPurchaseLine.SystemId, PurchaseReceiptLine.SystemId, QtyToInvoice, QtyToInvoiceBase, false);
                                            // From the remaining quantity to distribute, we take out the quantity that is now assigned to be invoiced for this order line
                                            RemainingBaseToDistribute -= QtyToInvoiceBase;
                                        end;
                                    until ReceiptPOMatches.Next() = 0;

                                // What is left of the e-document quantity is received on invoice for this order line, capped at what is still outstanding on it.
                                AutoReceiveBase := RemainingBaseToDistribute;
                                if AutoReceiveBase > OrderPurchaseLine."Outstanding Qty. (Base)" then
                                    AutoReceiveBase := OrderPurchaseLine."Outstanding Qty. (Base)";
                                if AutoReceiveBase < 0 then
                                    AutoReceiveBase := 0;
                                RemainingBaseToDistribute -= AutoReceiveBase;

                                QtyPerUoM := OrderPurchaseLine."Qty. per Unit of Measure";
                                if QtyPerUoM = 0 then
                                    QtyPerUoM := 1;
                                AutoReceive := UnitOfMeasureMgt.CalcQtyFromBase(AutoReceiveBase, QtyPerUoM);
                                MatchedOrderLineMgmt.CreateMatchedOrderLine(InvoicePurchaseLine.SystemId, OrderPurchaseLine.SystemId, NullGuid, AutoReceive, AutoReceiveBase, OrderPurchaseLine."Receipt on Invoice");
                            end;
                        until EDocPurchaseLinePOMatch.Next() = 0;
                end;
                RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
            until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Transfer PO matches defined in the purchase invoice to the linked e-document
    /// </summary>
    /// <param name="PurchaseHeader"></param>
    procedure TransferPOMatchesFromInvoiceToEDocument(PurchaseHeader: Record "Purchase Header")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        PurchaseInvoiceLine: Record "Purchase Line";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempPOLinesToMatch: Record "Purchase Line" temporary;
        TempReceiptLinesToMatch: Record "Purch. Rcpt. Line" temporary;
    begin
        PurchaseInvoiceLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseInvoiceLine.FindSet() then
            exit;
        repeat
            if EDocumentPurchaseLine.GetFromLinkedPurchaseLine(PurchaseInvoiceLine) then begin
                TempPOLinesToMatch.Reset();
                TempPOLinesToMatch.DeleteAll();
                TempReceiptLinesToMatch.Reset();
                TempReceiptLinesToMatch.DeleteAll();

                // Matches created when the draft was applied are stored as matched order lines.
                MatchedOrderLine.SetRange("Document Line SystemId", PurchaseInvoiceLine.SystemId);
                if MatchedOrderLine.FindSet() then
                    repeat
                        if PurchaseOrderLine.GetBySystemId(MatchedOrderLine."Matched Order Line SystemId") then
                            CollectPOLineToMatch(PurchaseOrderLine, TempPOLinesToMatch);
                        if not IsNullGuid(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then
                            if PurchaseReceiptLine.GetBySystemId(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then
                                CollectReceiptLineToMatch(PurchaseReceiptLine, TempReceiptLinesToMatch);
                    until MatchedOrderLine.Next() = 0;

                // An invoice line created from a posted receipt (the classic "Get Receipt Lines" flow) is linked to
                // it through the Receipt No. / Receipt Line No. fields rather than a matched order line.
                if (PurchaseInvoiceLine."Receipt No." <> '') and (PurchaseInvoiceLine."Receipt Line No." <> 0) then
                    if PurchaseReceiptLine.Get(PurchaseInvoiceLine."Receipt No.", PurchaseInvoiceLine."Receipt Line No.") then
                        if PurchaseOrderLine.Get(PurchaseOrderLine."Document Type"::Order, PurchaseReceiptLine."Order No.", PurchaseReceiptLine."Order Line No.") then begin
                            CollectPOLineToMatch(PurchaseOrderLine, TempPOLinesToMatch);
                            CollectReceiptLineToMatch(PurchaseReceiptLine, TempReceiptLinesToMatch);
                        end;

                if not TempPOLinesToMatch.IsEmpty() then
                    MatchPOLinesToEDocumentLine(TempPOLinesToMatch, EDocumentPurchaseLine);
                if not TempReceiptLinesToMatch.IsEmpty() then
                    MatchReceiptLinesToEDocumentLine(TempReceiptLinesToMatch, EDocumentPurchaseLine);
            end;
        until PurchaseInvoiceLine.Next() = 0;
    end;

    local procedure CollectPOLineToMatch(PurchaseOrderLine: Record "Purchase Line"; var TempPOLinesToMatch: Record "Purchase Line" temporary)
    begin
        if TempPOLinesToMatch.Get(PurchaseOrderLine."Document Type", PurchaseOrderLine."Document No.", PurchaseOrderLine."Line No.") then
            exit;
        TempPOLinesToMatch := PurchaseOrderLine;
        TempPOLinesToMatch.Insert();
    end;

    local procedure CollectReceiptLineToMatch(PurchaseReceiptLine: Record "Purch. Rcpt. Line"; var TempReceiptLinesToMatch: Record "Purch. Rcpt. Line" temporary)
    begin
        if TempReceiptLinesToMatch.Get(PurchaseReceiptLine."Document No.", PurchaseReceiptLine."Line No.") then
            exit;
        TempReceiptLinesToMatch := PurchaseReceiptLine;
        TempReceiptLinesToMatch.Insert();
    end;

    /// <summary>
    /// Returns whether we should warn the user that the specified vendor's purchase order lines are not yet received when they are matched to an invoice line.
    /// </summary>
    /// <param name="TempPurchaseLine">Purchase order lines matched to a single e-document invoice draft line.</param>
    /// <returns>Whether a warning should be shown if any of the purchase order lines are not marked as possible to be received at invoice.</returns>
    procedure ShouldWarnIfNotYetReceived(var TempPurchaseLine: Record "Purchase Line" temporary): Boolean
    begin
        if TempPurchaseLine.IsEmpty() then
            exit(false);
        TempPurchaseLine.FindSet();
        repeat
            if not TempPurchaseLine."Receipt on Invoice" then
                exit(true);
        until TempPurchaseLine.Next() = 0;
        exit(false);
    end;

}
