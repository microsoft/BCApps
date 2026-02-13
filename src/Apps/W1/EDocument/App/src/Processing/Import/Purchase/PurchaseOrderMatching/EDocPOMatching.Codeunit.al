// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
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
        if EDocLineQuantity <> PurchaseLinesQuantity - PurchaseLinesQuantityInvoiced then begin
            POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::QuantityMismatch;
            POMatchWarnings.Insert();
        end;
        if (EDocLineQuantity + PurchaseLinesQuantityInvoiced) > PurchaseLinesQuantityReceived then
            if ShouldWarnIfNotYetReceived(EDocumentPurchaseLine.GetBCVendor()."No.") then begin
                POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                POMatchWarnings."Warning Type" := "E-Doc PO Match Warning"::NotYetReceived;
                POMatchWarnings.Insert();
            end;
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
        TempMatchWarnings: Record "E-Doc PO Match Warning" temporary;
        MatchesToMultiplePOLinesNotSupportedErr: Label 'Matching an e-document line to multiple purchase order lines is not currently supported.';
        NotLinkedToVendorErr: Label 'The selected purchase order line is not linked to the same vendor as the e-document line.';
        AlreadyMatchedErr: Label 'A selected purchase order line is already matched to another e-document line. E-Document: %1, Purchase document: %2 %3.', Comment = '%1 - E-Document No., %2 - Purchase Document Type, %3 - Purchase Document No.';
        OrderLineAndEDocFromDifferentVendorsErr: Label 'All selected purchase order lines must belong to orders for the same vendor as the e-document line.';
        OrderLinesMustBeOfSameTypeAndNoErr: Label 'All selected purchase order lines must be of the same type and number.';
        NotYetReceivedErr: Label 'The selected purchase order lines are not yet received with the quantity of the invoice. You must first receive them before matching them.';
        OrderLinesMustHaveSameUoMErr: Label 'All selected purchase order lines must have the same unit of measure.';
        MatchedPOLineType: Enum "Purchase Line Type";
        MatchedPOLineVendorNo, MatchedPOLineTypeNo, MatchedUnitOfMeasure : Code[20];
        FirstOfLinesBeingMatched: Boolean;
    begin
        if SelectedPOLines.IsEmpty() then
            exit;
        if SelectedPOLines.Count() > 1 then
            Error(MatchesToMultiplePOLinesNotSupportedErr);
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
        AppendPOMatchWarnings(EDocumentPurchaseLine, TempMatchWarnings);
        TempMatchWarnings.SetRange("Warning Type", "E-Doc PO Match Warning"::NotYetReceived);
        if (not TempMatchWarnings.IsEmpty) and (not CanMatchInvoiceLineToPOLineWithoutReceipt(EDocumentPurchaseLine, PurchaseLine)) then
            Error(NotYetReceivedErr);
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
        MatchesToMultipleReceiptLinesNotSupportedErr: Label 'Matching an e-document line to multiple receipt lines is not currently supported.';
        QuantityCovered: Decimal;
    begin
        if SelectedReceiptLines.IsEmpty() then
            exit;
        if SelectedReceiptLines.Count() > 1 then
            Error(MatchesToMultipleReceiptLinesNotSupportedErr);

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

    procedure ConfigureDefaultPOMatchingSettings()
    var
        DefaultSetup: Record "E-Doc. PO Matching Setup";
        DefaultConfiguration: Enum "E-Doc. PO M. Configuration";
        VendorNos: List of [Code[20]];
    begin
        DefaultSetup."PO Matching Config. Receipt" := Enum::"E-Doc. PO M. Config. Receipt"::"Always ask";
        DefaultSetup."Receive G/L Account Lines" := false;
        DefaultConfiguration := Enum::"E-Doc. PO M. Configuration"::"Always ask";
        ConfigurePOMatchingSettings(DefaultSetup, DefaultConfiguration, VendorNos);
    end;

    /// <summary>
    /// Stores the configuration selected by the user.
    /// </summary>
    /// <param name="DesiredGlobalSetup">The global setup, applicable if no vendor specific override has been configured.</param>
    /// <param name="Configuration">The configuration selected by the user.</param>
    /// <param name="VendorNos">If the configuration is vendor specific, this will contain the vendor numbers affected by such.</param>
    procedure ConfigurePOMatchingSettings(DesiredGlobalSetup: Record "E-Doc. PO Matching Setup"; Configuration: Enum "E-Doc. PO M. Configuration"; VendorNos: List of [Code[20]])
    var
        GlobalSetup: Record "E-Doc. PO Matching Setup";
        EDocPOMatchingSetup: Record "E-Doc. PO Matching Setup";
        VendorNo: Code[20];
    begin
        // We delete all existing settings and recreate them based on the desired global setup, configuration and vendor list
        EDocPOMatchingSetup.DeleteAll();
        // We first prepare the global setup record, used as fallback if there's no vendor-specific setting
        EDocPOMatchingSetup.Copy(DesiredGlobalSetup);
        Clear(EDocPOMatchingSetup.Id);
        EDocPOMatchingSetup."Vendor No." := '';
        case Configuration of
            Configuration::"Always ask":
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always ask";
            Configuration::"Never receive at posting":
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Never receive at posting";
            Configuration::"Always receive at posting":
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always receive at posting";
            Configuration::"Receive at posting except for certain vendors": // The default for a vendor that is not specified is to always receive at posting
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always receive at posting";
            Configuration::"Receive at posting only for certain vendors": // The default for a vendor that is not specified is to always ask
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always ask";
        end;
        EDocPOMatchingSetup.Insert();
        // Now we create vendor-specific settings, if any
        // By default, we copy the global setup values to each vendor-specific setting, and then we adjust only the receipt configuration
        if not (Configuration in [Configuration::"Receive at posting except for certain vendors", Configuration::"Receive at posting only for certain vendors"]) then
            exit;
        GlobalSetup.Copy(EDocPOMatchingSetup);
        foreach VendorNo in VendorNos do begin
            EDocPOMatchingSetup.Copy(GlobalSetup);
            Clear(EDocPOMatchingSetup.Id);
            EDocPOMatchingSetup."Vendor No." := VendorNo;
            if Configuration = Configuration::"Receive at posting only for certain vendors" then
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always receive at posting"
            else
                EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Never receive at posting";
            EDocPOMatchingSetup.Insert();
        end;
    end;

    /// <summary>
    /// If the E-Document has been matched to an order line without specifying receipts, we match with receipt lines for that order line that can cover the E-Document line quantity.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    procedure SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
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
        PurchaseLine: Record "Purchase Line";
        TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                LoadReceiptLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptLine);
                if not TempPurchaseReceiptLine.FindFirst() then // We only support a single receipt line match in BaseApp
                    continue;
                PurchaseLine := EDocumentPurchaseLine.GetLinkedPurchaseLine();
                if IsNullGuid(PurchaseLine.SystemId) then
                    continue;
                PurchaseLine."Receipt No." := TempPurchaseReceiptLine."Document No.";
                PurchaseLine."Receipt Line No." := TempPurchaseReceiptLine."Line No.";
                PurchaseLine.Modify();
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
        PurchaseInvoiceLine: Record "Purchase Line";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempPOLineToMatch: Record "Purchase Line" temporary;
        TempReceiptLineToMatch: Record "Purch. Rcpt. Line" temporary;
    begin
        PurchaseInvoiceLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseInvoiceLine.SetFilter("Receipt No.", '<>%1', '');
        PurchaseInvoiceLine.SetFilter("Receipt Line No.", '<>%1', 0);
        if PurchaseInvoiceLine.IsEmpty() then
            exit;
        PurchaseInvoiceLine.FindSet();
        repeat
            if not EDocumentPurchaseLine.GetFromLinkedPurchaseLine(PurchaseInvoiceLine) then
                continue;
            if not PurchaseReceiptLine.Get(PurchaseInvoiceLine."Receipt No.", PurchaseInvoiceLine."Receipt Line No.") then
                continue;
            if not PurchaseOrderLine.Get(Enum::"Purchase Document Type"::Order, PurchaseReceiptLine."Order No.", PurchaseReceiptLine."Order Line No.") then
                continue;
            TempPOLineToMatch.DeleteAll();
            TempPOLineToMatch.Copy(PurchaseOrderLine);
            TempPOLineToMatch.Insert();
            MatchPOLinesToEDocumentLine(TempPOLineToMatch, EDocumentPurchaseLine);

            TempReceiptLineToMatch.DeleteAll();
            TempReceiptLineToMatch.Copy(PurchaseReceiptLine);
            TempReceiptLineToMatch.Insert();
            MatchReceiptLinesToEDocumentLine(TempReceiptLineToMatch, EDocumentPurchaseLine);
        until PurchaseInvoiceLine.Next() = 0;
        PurchaseInvoiceLine.SetRange("Receipt No.");
        PurchaseInvoiceLine.SetRange("Receipt Line No.");
        PurchaseInvoiceLine.ModifyAll("Receipt No.", '');
        PurchaseInvoiceLine.ModifyAll("Receipt Line No.", 0);
    end;

    /// <summary>
    /// Loads the settings for purchase order matching.
    /// </summary>
    /// <param name="GlobalSetup">The global setup, applicable if no vendor specific override has been configured.</param>
    /// <param name="Configuration">The configuration selected by the user.</param>
    /// <param name="VendorNos">If the configuration is vendor specific, this will contain the vendor numbers affected by such.</param>
    procedure GetPOMatchingSettings(var GlobalSetup: Record "E-Doc. PO Matching Setup"; var Configuration: Enum "E-Doc. PO M. Configuration"; var VendorNos: List of [Code[20]])
    var
        EDocPOMatchingSetup: Record "E-Doc. PO Matching Setup";
    begin
        GlobalSetup.GetSetup();
        Configuration := Enum::"E-Doc. PO M. Configuration".FromInteger(GlobalSetup."PO Matching Config. Receipt".AsInteger());
        EDocPOMatchingSetup.SetFilter("Vendor No.", '<> %1', '');
        if EDocPOMatchingSetup.FindSet() then begin
            // If there are vendor-specific settings, we need to adjust the configuration value
            if Configuration = Configuration::"Always ask" then // Always ask is the default for non specified vendors when "Receive at posting only for certain vendors" is selected
                Configuration := Configuration::"Receive at posting only for certain vendors";
            if Configuration = Configuration::"Always receive at posting" then // Always receive at posting is the default for non specified vendors when "Receive at posting except for certain vendors" is selected
                Configuration := Configuration::"Receive at posting except for certain vendors";
            repeat
                VendorNos.Add(EDocPOMatchingSetup."Vendor No.");
            until EDocPOMatchingSetup.Next() = 0;
        end;
    end;

    /// <summary>
    /// Verifies that all E-Document lines that have a Not Yet Received warning can be validly matched without receipt.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    /// <returns></returns>
    procedure VerifyEDocumentMatchedLinesAreValidMatches(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);
        TempPOMatchWarnings.SetRange("Warning Type", "E-Doc PO Match Warning"::NotYetReceived);
        // For each line that has a Not Yet Received warning, we check if it can be matched without receipt
        if TempPOMatchWarnings.FindSet() then
            repeat
                EDocumentPurchaseLine.GetBySystemId(TempPOMatchWarnings."E-Doc. Purchase Line SystemId");
                LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);
                if not TempPurchaseLine.FindFirst() then
                    continue;
                if not CanMatchInvoiceLineToPOLineWithoutReceipt(EDocumentPurchaseLine, TempPurchaseLine) then
                    exit(false);
            until TempPOMatchWarnings.Next() = 0;
        exit(true);
    end;

    /// <summary>
    /// Returns whether an invoice line can be matched against a PO line provided that the PO line has not yet been received. If it can be matched it does not imply that we will not warn the user, but if it cannot be matched we will warn the user.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="PurchaseLine"></param>
    /// <returns></returns>
    local procedure CanMatchInvoiceLineToPOLineWithoutReceipt(EDocumentPurchaseLine: Record "E-Document Purchase Line"; PurchaseLine: Record "Purchase Line"): Boolean
    var
        EDocPOMatchingSetup: Record "E-Doc. PO Matching Setup";
        Vendor: Record Vendor;
    begin
        // Lines without a vendor assigned can't be matched in general
        Vendor := EDocumentPurchaseLine.GetBCVendor();
        if Vendor."No." = '' then
            exit(false);

        EDocPOMatchingSetup.GetSetup(Vendor."No.");
        if EDocPOMatchingSetup."Receive G/L Account Lines" and (PurchaseLine.Type = "Purchase Line Type"::"G/L Account") then
            exit(true);

        case EDocPOMatchingSetup."PO Matching Config. Receipt" of
            "E-Doc. PO M. Config. Receipt"::"Always receive at posting",
            "E-Doc. PO M. Config. Receipt"::"Always ask":
                exit(true);
            "E-Doc. PO M. Config. Receipt"::"Never receive at posting":
                exit(false);
        end;
    end;

    /// <summary>
    /// Returns whether we should warn the user if the specified vendor's purchase order lines are not yet received and they are matched to an invoice line.
    /// </summary>
    /// <param name="VendorNo"></param>
    /// <returns></returns>
    procedure ShouldWarnIfNotYetReceived(VendorNo: Code[20]): Boolean
    var
        EDocPOMatchingSetup: Record "E-Doc. PO Matching Setup";
    begin
        EDocPOMatchingSetup.GetSetup(VendorNo);
        case EDocPOMatchingSetup."PO Matching Config. Receipt" of
            "E-Doc. PO M. Config. Receipt"::"Always receive at posting":
                exit(false);
            "E-Doc. PO M. Config. Receipt"::"Always ask",
            "E-Doc. PO M. Config. Receipt"::"Never receive at posting":
                exit(true);
        end;
    end;

}
