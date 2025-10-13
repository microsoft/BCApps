codeunit 6196 "E-Doc. PO Matching"
{
    Access = Internal;

    /// <summary>
    /// Loads all purchase order lines that can be linked to the specified E-Document line into the specified temporary Purchase Line record.
    /// A line can be linked if it belongs to an order for the same vendor as the E-Document line, and if it is not already linked to another E-Document line.
    /// Lines that are already linked to the specified E-Document line are included.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseLine"></param>
    procedure LoadAvailablePurchaseOrderLinesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        IncludePOLine: Boolean;
    begin
        TempPurchaseLine.DeleteAll();
        Vendor := EDocumentPurchaseLine.GetLinkedVendor();
        if Vendor."No." = '' then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Pay-to Vendor No.", Vendor."No.");
        if not PurchaseLine.FindSet() then
            exit;
        // We exclude lines that have already been matched
        repeat
            IncludePOLine := false;
            EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId);
            // Unless the line is matched to the current E-Document line
            if EDocPurchaseLinePOMatch.FindSet() then
                repeat
                    if EDocPurchaseLinePOMatch."E-Doc. Purchase Line SystemId" = EDocumentPurchaseLine.SystemId then
                        IncludePOLine := true;
                until (EDocPurchaseLinePOMatch.Next() = 0) or IncludePOLine
            else
                IncludePOLine := true;
            if IncludePOLine then begin
                Clear(TempPurchaseLine);
                TempPurchaseLine := PurchaseLine;
                TempPurchaseLine.Insert();
            end;
        until PurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Loads all purchase order lines that are linked to the specified E-Document line into the specified temporary Purchase Line record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseLine"></param>
    procedure LoadPOLinesLinkedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        PurchaseLine: Record "Purchase Line";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        TempPurchaseLine.DeleteAll();
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetRange("Receipt Line SystemId", NullGuid);
        if not EDocPurchaseLinePOMatch.FindSet() then
            exit;
        repeat
            if PurchaseLine.GetBySystemId(EDocPurchaseLinePOMatch."Purchase Line SystemId") then begin
                Clear(TempPurchaseLine);
                TempPurchaseLine := PurchaseLine;
                TempPurchaseLine.Insert();
            end;
        until EDocPurchaseLinePOMatch.Next() = 0;
    end;

    /// <summary>
    /// Loads all purchase orders that are linked to the specified E-Document line into the specified temporary Purchase Header record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseHeader"></param>
    procedure LoadPOsLinkedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseHeader: Record "Purchase Header" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        TempPurchaseHeader.DeleteAll();
        LoadPOLinesLinkedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);
        if not TempPurchaseLine.FindSet() then
            exit;
        repeat
            if PurchaseHeader.Get(Enum::"Purchase Document Type"::Order, TempPurchaseLine."Document No.") then begin
                Clear(TempPurchaseHeader);
                TempPurchaseHeader := PurchaseHeader;
                if TempPurchaseHeader.Insert() then;
            end;
        until TempPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Loads all purchase receipt lines that are linked to purchase order lines that are linked to the specified E-Document line into the specified temporary Purch. Rcpt. Line record.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="TempPurchaseReceiptLine"></param>
    procedure LoadAvailableReceiptLinesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary)
    var
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        LinkedPurchaseLines: Record "Purchase Line" temporary;
    begin
        TempPurchaseReceiptLine.DeleteAll();
        LoadPOLinesLinkedToEDocumentLine(EDocumentPurchaseLine, LinkedPurchaseLines);
        if not LinkedPurchaseLines.FindSet() then
            exit;
        repeat
            PurchaseReceiptLine.SetRange("Order No.", LinkedPurchaseLines."Document No.");
            PurchaseReceiptLine.SetRange("Order Line No.", LinkedPurchaseLines."Line No.");
            if not PurchaseReceiptLine.FindSet() then
                continue;
            repeat
                if PurchaseReceiptLine.Quantity <> 0 then begin
                    Clear(TempPurchaseReceiptLine);
                    TempPurchaseReceiptLine := PurchaseReceiptLine;
                    TempPurchaseReceiptLine.Insert();
                end;
            until PurchaseReceiptLine.Next() = 0;
        until LinkedPurchaseLines.Next() = 0;
    end;

    procedure LoadReceiptsLinkedToEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var TempPurchaseReceiptHeader: Record "Purch. Rcpt. Header" temporary)
    var
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        TempPurchaseReceiptHeader.DeleteAll();
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        if not EDocPurchaseLinePOMatch.FindSet() then
            exit;
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
    procedure CalculatePOMatchWarnings(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var POMatchWarnings: Record "E-Doc PO Match Warnings" temporary)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseLine: Record "Purchase Line" temporary;
        EDocLineQuantity: Decimal;
        PurchaseLinesQuantityInvoiced, PurchaseLinesQuantityReceived : Decimal;
        ItemFound, ItemUoMFound : Boolean;
    begin
        POMatchWarnings.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if not EDocumentPurchaseLine.FindSet() then
            exit;
        repeat
            LoadPOLinesLinkedToEDocumentLine(EDocumentPurchaseLine, PurchaseLine);
            PurchaseLinesQuantityInvoiced := 0;
            PurchaseLinesQuantityReceived := 0;
            if not PurchaseLine.FindSet() then
                continue;
            repeat
                PurchaseLinesQuantityInvoiced += PurchaseLine."Qty. Invoiced (Base)";
                PurchaseLinesQuantityReceived += PurchaseLine."Qty. Received (Base)";
            until PurchaseLine.Next() = 0;
            if EDocumentPurchaseLine."[BC] Purchase Line Type" = Enum::"Purchase Line Type"::Item then begin// TODO: I know this has to be done for Items, idk for other types.. there's probably already something in BaseApp for this - ask someone from SCM
                ItemFound := Item.Get(EDocumentPurchaseLine."[BC] Purchase Type No.");
                ItemUoMFound := ItemUnitOfMeasure.Get(Item."No.", EDocumentPurchaseLine."[BC] Unit of Measure");
                if not (ItemFound and ItemUoMFound) then begin
                    POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                    POMatchWarnings."Warning Type" := "E-Doc PO Match Warnings"::MissingInformationForMatch;
                    POMatchWarnings.Insert();
                    continue;
                end;
                EDocLineQuantity := EDocumentPurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure"
            end;
            if EDocLineQuantity <> EDocumentPurchaseLine.Quantity then begin
                POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                POMatchWarnings."Warning Type" := "E-Doc PO Match Warnings"::QuantityMismatch;
                POMatchWarnings.Insert();
            end;
            if (EDocLineQuantity + PurchaseLinesQuantityInvoiced) > PurchaseLinesQuantityReceived then begin
                POMatchWarnings."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
                POMatchWarnings."Warning Type" := "E-Doc PO Match Warnings"::NotYetReceived;
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
        if not EDocumentPurchaseLine.FindSet() then
            exit(true);
        repeat
            EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
            if not EDocPurchaseLinePOMatch.FindSet() then
                continue;
            repeat
                if not IsNullGuid(EDocPurchaseLinePOMatch."Receipt Line SystemId") then
                    if not PurchaseReceiptLine.GetBySystemId(EDocPurchaseLinePOMatch."Receipt Line SystemId") then
                        exit(false);
                if not PurchaseLine.GetBySystemId(EDocPurchaseLinePOMatch."Purchase Line SystemId") then
                    exit(false); // TODO: we probably need to do something for posted orders (different tbale)
            until EDocPurchaseLinePOMatch.Next() = 0;
        until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Returns true if the specified E-Document line is linked to any purchase order line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsEDocumentLineLinkedToAnyPOLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    /// <summary>
    /// Returns true if any line in the specified E-Document is linked to any purchase order line.
    /// </summary>
    /// <param name="EDocumentPurchaseHeader"></param>
    /// <returns></returns>
    procedure IsEDocumentLinkedToAnyPOLine(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        if IsNullGuid(EDocumentPurchaseHeader.SystemId) then
            exit(false);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if not EDocumentPurchaseLine.FindSet() then
            exit(false);
        repeat
            if IsEDocumentLineLinkedToAnyPOLine(EDocumentPurchaseLine) then
                exit(true);
        until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Returns true if the specified purchase order line is linked to the specified E-Document line.
    /// </summary>
    /// <param name="PurchaseLine"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsPurchaseOrderLineLinkedToEDocumentLine(PurchaseLine: Record "Purchase Line"; EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
    begin
        EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    procedure IsEDocumentLineLinkedToAnyReceiptLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        exit(not EDocPurchaseLinePOMatch.IsEmpty());
    end;

    /// <summary>
    /// Returns true if the specified receipt line is linked to the specified E-Document line.
    /// </summary>
    /// <param name="ReceiptLine"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <returns></returns>
    procedure IsReceiptLineLinkedToEDocumentLine(ReceiptLine: Record "Purch. Rcpt. Line"; EDocumentPurchaseLine: Record "E-Document Purchase Line"): Boolean
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
        if not EDocumentPurchaseLine.FindSet() then
            exit;
        repeat
            RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
        until EDocumentPurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Links the specified purchase order lines to the specified E-Document line.
    /// Each purchase order line must belong to an order for the same vendor as the E-Document line, and must not already be linked to another E-Document line.
    /// Existing links are removed, and the E-Document line's purchase type and number are set to match the linked lines.
    /// The procedure raises an error if any of the specified lines is invalid.
    /// </summary>
    /// <param name="SelectedPOLines"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    procedure LinkPOLinesToEDocumentLine(var SelectedPOLines: Record "Purchase Line" temporary; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        AlreadyLinkedErr: Label 'A selected purchase order line is already linked to another e-document line.';
        LinkedPOLineType: Enum "Purchase Line Type";
        LinkedPOLineVendorNo, LinkedPOLineTypeNo : Code[20];
        POLineTypeCollected: Boolean;
    begin
        if not SelectedPOLines.FindSet() then
            exit;
        RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);
        repeat
            // Create new links, if each line being linked is valid
            PurchaseLine.GetBySystemId(SelectedPOLines.SystemId);
            PurchaseLine.TestField("Document Type", PurchaseLine."Document Type"::Order);
            PurchaseLine.TestField("No."); // The line must have been assigned a number for it's purchase type
            Vendor := EDocumentPurchaseLine.GetLinkedVendor();
            Vendor.TestField("No.");
            PurchaseLine.TestField("Pay-to Vendor No.", Vendor."No."); // The line must belong to an order for the same vendor as the E-Document line
            EDocPurchaseLinePOMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId); // The PO Line must not already be linked to another E-Document line
            if not EDocPurchaseLinePOMatch.IsEmpty() then
                Error(AlreadyLinkedErr);

            // We ensure that all linked lines have the same Vendor, Type and No.
            if LinkedPOLineVendorNo = '' then
                LinkedPOLineVendorNo := PurchaseLine."Pay-to Vendor No."
            else
                PurchaseLine.TestField("Pay-to Vendor No.", LinkedPOLineVendorNo); // TODO: nicer errors

            if LinkedPOLineTypeNo = '' then
                LinkedPOLineTypeNo := PurchaseLine."No."
            else
                PurchaseLine.TestField("No.", LinkedPOLineTypeNo);

            if not POLineTypeCollected then begin
                POLineTypeCollected := true;
                LinkedPOLineType := PurchaseLine.Type;
            end
            else
                PurchaseLine.TestField(Type, LinkedPOLineType);

            Clear(EDocPurchaseLinePOMatch);
            EDocPurchaseLinePOMatch."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            EDocPurchaseLinePOMatch."Purchase Line SystemId" := PurchaseLine.SystemId;
            EDocPurchaseLinePOMatch.Insert();

        until SelectedPOLines.Next() = 0;
        // Set the E-Document Purchase Line properties to match the linked Purchase Line properties
        EDocumentPurchaseLine."[BC] Purchase Line Type" := LinkedPOLineType;
        EDocumentPurchaseLine."[BC] Purchase Type No." := LinkedPOLineTypeNo;
        EDocumentPurchaseLine.Modify();
    end;

    /// <summary>
    /// Links the specified purchase receipt lines to the specified E-Document line.
    /// Each receipt line must be linked to a purchase order line that is linked to the specified E-Document line.
    /// Existing links are removed.
    /// If the receipt lines can't cover the full quantity of the E-Document line, the procedure raises an error.
    /// </summary>
    /// <param name="SelectedReceiptLines"></param>
    /// <param name="EDocumentPurchaseLine"></param>
    procedure LinkReceiptLinesToEDocumentLine(var SelectedReceiptLines: Record "Purch. Rcpt. Line" temporary; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        LinkedPurchaseLines: Record "Purchase Line" temporary;
        NullGuid: Guid;
        ReceiptLineNotLinkedErr: Label 'A selected receipt line is not linked to any of the purchase order lines linked to the e-document line.';
        QuantityCovered: Decimal;
    begin
        if not SelectedReceiptLines.FindSet() then
            exit;
        // Remove existing receipt line links
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        EDocPurchaseLinePOMatch.DeleteAll();

        // Create new links
        LoadPOLinesLinkedToEDocumentLine(EDocumentPurchaseLine, LinkedPurchaseLines);
        repeat
            LinkedPurchaseLines.SetRange("Document No.", SelectedReceiptLines."Order No.");
            LinkedPurchaseLines.SetRange("Line No.", SelectedReceiptLines."Order Line No.");
            if not LinkedPurchaseLines.FindFirst() then
                Error(ReceiptLineNotLinkedErr);
            Clear(EDocPurchaseLinePOMatch);
            EDocPurchaseLinePOMatch."E-Doc. Purchase Line SystemId" := EDocumentPurchaseLine.SystemId;
            EDocPurchaseLinePOMatch."Purchase Line SystemId" := LinkedPurchaseLines.SystemId;
            EDocPurchaseLinePOMatch."Receipt Line SystemId" := SelectedReceiptLines.SystemId;
            EDocPurchaseLinePOMatch.Insert();
            QuantityCovered += SelectedReceiptLines.Quantity;
        until SelectedReceiptLines.Next() = 0;
        if QuantityCovered < EDocumentPurchaseLine.Quantity then
            Error('The selected receipt lines do not cover the full quantity of the e-document line.');
    end;
}