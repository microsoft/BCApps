// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Inventory.Item;

codeunit 6196 "E-Doc. PO Matching"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Loads all purchase order lines that can be matched to the specified E-Document line into the specified temporary Purchase Line record.
    /// A line can be matched if it belongs to an order for the same vendor as the E-Document line, and if it is not already matched to another E-Document line.
    /// Lines that are already matched to the specified E-Document line are included.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseLine"></param>
    procedure LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
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
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        Clear(TempPurchaseReceiptHeader);
        TempPurchaseReceiptHeader.DeleteAll();
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        if EDocPurchaseLinePOMatch.FindSet() then
            repeat
                if PurchaseReceiptLine.GetBySystemId(EDocPurchaseLinePOMatch."Receipt Line SystemId") then
                    if PurchaseReceiptHeader.Get(PurchaseReceiptLine."Document No.") then begin
                        Clear(TempPurchaseReceiptHeader);
                        TempPurchaseReceiptHeader := PurchaseReceiptHeader;
                        if TempPurchaseReceiptHeader.Insert() then;
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
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempPurchaseLine: Record "Purchase Line" temporary;
        EDocLineQuantity: Decimal;
        PurchaseLinesQuantityInvoiced, PurchaseLinesQuantityReceived : Decimal;
        ItemFound, ItemUoMFound : Boolean;
    begin
        Clear(POMatchWarnings);
        POMatchWarnings.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);
                PurchaseLinesQuantityInvoiced := 0;
                PurchaseLinesQuantityReceived := 0;
                if not TempPurchaseLine.FindSet() then
                    continue;
                repeat
                    PurchaseLinesQuantityInvoiced += TempPurchaseLine."Qty. Invoiced (Base)";
                    PurchaseLinesQuantityReceived += TempPurchaseLine."Qty. Received (Base)";
                until TempPurchaseLine.Next() = 0;
                if EDocumentPurchaseLine."[BC] Purchase Line Type" = Enum::"Purchase Line Type"::Item then begin
                    Item.SetLoadFields("No.");
                    ItemFound := Item.Get(EDocumentPurchaseLine."[BC] Purchase Type No.");
                    ItemUnitOfMeasure.SetLoadFields("Item No.", Code, "Qty. per Unit of Measure");
                    ItemUoMFound := ItemUnitOfMeasure.Get(Item."No.", EDocumentPurchaseLine."[BC] Unit of Measure");
                    if not (ItemFound and ItemUoMFound) then begin
                        POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                        POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::MissingInformationForMatch;
                        POMatchWarnings.Insert();
                        continue;
                    end;
                    EDocLineQuantity := EDocumentPurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure"
                end;
                if EDocLineQuantity <> EDocumentPurchaseLine.Quantity then begin
                    POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                    POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::QuantityMismatch;
                    POMatchWarnings.Insert();
                end;
                if (EDocLineQuantity + PurchaseLinesQuantityInvoiced) > PurchaseLinesQuantityReceived then begin
                    POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                    POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::NotYetReceived;
                    POMatchWarnings.Insert();
                end;
            until EDocumentPurchaseLine.Next() = 0;
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
        NotLinkedToVendorErr: Label 'The e-document line is not matched to any vendor.';
        AlreadyMatchedErr: Label 'A selected purchase order line is already matched to another e-document line. E-Document: %1, Purchase document: %2 %3.', Comment = '%1 - E-Document No., %2 - Purchase Document Type, %3 - Purchase Document No.';
        OrderLineAndEDocFromDifferentVendorsErr: Label 'All selected purchase order lines must belong to orders for the same vendor as the e-document line.';
        OrderLinesMustBeOfSameTypeAndNoErr: Label 'All selected purchase order lines must be of the same type and number.';
        MatchedPOLineType: Enum "Purchase Line Type";
        MatchedPOLineVendorNo, MatchedPOLineTypeNo : Code[20];
        POLineTypeCollected: Boolean;
    begin
        if SelectedPOLines.IsEmpty() then
            exit;
        RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
        MatchedPOLineVendorNo := '';
        MatchedPOLineTypeNo := '';
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

                // We ensure that all matched lines have the same Vendor, Type and No.
                if MatchedPOLineVendorNo = '' then
                    MatchedPOLineVendorNo := PurchaseLine."Pay-to Vendor No."
                else
                    if PurchaseLine."Pay-to Vendor No." <> MatchedPOLineVendorNo then
                        Error(OrderLineAndEDocFromDifferentVendorsErr);

                if MatchedPOLineTypeNo = '' then
                    MatchedPOLineTypeNo := PurchaseLine."No."
                else
                    if PurchaseLine."No." <> MatchedPOLineTypeNo then
                        Error(OrderLinesMustBeOfSameTypeAndNoErr);

                if not POLineTypeCollected then begin
                    POLineTypeCollected := true;
                    MatchedPOLineType := PurchaseLine.Type;
                end
                else
                    if PurchaseLine.Type <> MatchedPOLineType then
                        Error(OrderLinesMustBeOfSameTypeAndNoErr);

                Clear(EDocPurchaseLinePOMatch);
                EDocPurchaseLinePOMatch."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                EDocPurchaseLinePOMatch."Purchase Line SystemId" := PurchaseLine.SystemId;
                EDocPurchaseLinePOMatch.Insert();

            until SelectedPOLines.Next() = 0;
        // Set the E-Document Purchase Line properties to match the matched Purchase Line properties
        EDocumentPurchaseLine."[BC] Purchase Line Type" := MatchedPOLineType;
        EDocumentPurchaseLine."[BC] Purchase Type No." := MatchedPOLineTypeNo;
        EDocumentPurchaseLine.Modify();
    end;

    /// <summary>
    /// matches the specified purchase receipt lines to the specified E-Document line.
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
        if not SelectedReceiptLines.FindSet() then
            exit;
        // Remove existing receipt line matches
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        EDocPurchaseLinePOMatch.DeleteAll();

        // Create new matches
        LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempMatchedPurchaseLines);
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
}