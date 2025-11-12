// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Posting;

using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.History;

codeunit 5747 "Purch. Whse. Post Shipment"
{
#if not CLEAN25
    var
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnGetSourceDocumentOnElseCase', '', false, false)]
    local procedure OnGetSourceDocument(var SourceHeader: Variant; var WhseShptLine: Record "Warehouse Shipment Line"; var GenJnlTemplateName: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case WhseShptLine."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchaseHeader.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                    SourceHeader := PurchaseHeader;
                    GenJnlTemplateName := PurchaseHeader."Journal Templ. Name";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnInitSourceDocumentHeader', '', false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant);
    var
        PurchHeader: Record "Purchase Header";
        PurchRelease: Codeunit "Release Purchase Document";
        ValidatePostingDate: Boolean;
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Purchase Line": // Return Order
                begin
                    PurchHeader := SourceHeader;
                    PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(PurchHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
#if not CLEAN25
                    WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(PurchHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
#endif
                    if not IsHandled then
                        if (PurchHeader."Posting Date" = 0D) or
                           (PurchHeader."Posting Date" <> WhseShptHeader."Posting Date")
                        then begin
                            OnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(WhseShptLine, PurchHeader);
#if not CLEAN25
                            WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(WhseShptLine, PurchHeader);
#endif
                            PurchRelease.SetSkipWhseRequestOperations(true);
                            PurchRelease.Reopen(PurchHeader);
                            PurchRelease.SetSkipCheckReleaseRestrictions();
                            PurchHeader.SetHideValidationDialog(true);
                            PurchHeader.SetCalledFromWhseDoc(true);
                            PurchHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            PurchRelease.Run(PurchHeader);
                            ModifyHeader := true;
                        end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (WhseShptHeader."Shipment Date" <> PurchHeader."Expected Receipt Date")
                    then begin
                        PurchHeader."Expected Receipt Date" := WhseShptHeader."Shipment Date";
                        ModifyHeader := true;
                    end;
                    if WhseShptHeader."External Document No." <> '' then begin
                        PurchHeader."Vendor Authorization No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> PurchHeader."Shipment Method Code")
                    then begin
                        PurchHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(PurchHeader, WhseShptHeader, ModifyHeader);
#if not CLEAN25
                    WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforePurchHeaderModify(PurchHeader, WhseShptHeader, ModifyHeader);
#endif
                    if ModifyHeader then
                        PurchHeader.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterInitSourceDocumentLines', '', false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line"; var SourceHeader: Variant; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters")
    var
        PurchHeader: Record "Purchase Header";
    begin
        case WhseShptLine2."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchHeader := SourceHeader;
                    PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
                    HandlePurchaseLine(WhseShptLine2, PurchHeader, WhseShptHeader, WhsePostParameters);
                end;
        end;
    end;

    local procedure HandlePurchaseLine(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchHeader: Record "Purchase Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters")
    var
        PurchLine: Record "Purchase Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
        ShouldModifyExpectedReceiptDate: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandlePurchaseLine(WhseShptLine, PurchLine, WhseShptHeader, ModifyLine, IsHandled, WhsePostParameters);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeHandlePurchaseLine(WhseShptLine, PurchLine, WhseShptHeader, ModifyLine, IsHandled, WhsePostParameters);
#endif
        if IsHandled then
            exit;

        PurchLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        PurchLine.SetRange("Document No.", WhseShptLine."Source No.");
        if PurchLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", PurchLine."Line No.");
                if WhseShptLine.Find('-') then begin
                    OnAfterFindWhseShptLineForPurchLine(WhseShptLine, PurchLine);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterFindWhseShptLineForPurchLine(WhseShptLine, PurchLine);
#endif
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Purchase Order" then begin
                        ModifyLine := PurchLine."Qty. to Receive" <> -WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            PurchLine.Validate("Qty. to Receive", -WhseShptLine."Qty. to Ship");
                            OnHandlePurchaseLineOnAfterValidateQtytoReceive(PurchLine, WhseShptLine);
#if not CLEAN25
                            WhsePostShipment.RunOnHandlePurchaseLineOnAfterValidateQtytoReceive(PurchLine, WhseShptLine);
#endif
                            if WhsePostParameters."Post Invoice" then
                                PurchLine.Validate(
                                  "Qty. to Invoice",
                                  -WhseShptLine."Qty. to Ship" + PurchLine."Quantity Received" - PurchLine."Quantity Invoiced");
                        end;
                    end else begin
                        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                        ModifyLine := PurchLine."Return Qty. to Ship" <> WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            PurchLine.Validate("Return Qty. to Ship", WhseShptLine."Qty. to Ship");
                            OnHandlePurchaseLineOnAfterValidateRetQtytoShip(PurchLine, WhseShptLine);
#if not CLEAN25
                            WhsePostShipment.RunOnHandlePurchaseLineOnAfterValidateRetQtytoShip(PurchLine, WhseShptLine);
#endif
                            if WhsePostParameters."Post Invoice" then
                                PurchLine.Validate(
                                  "Qty. to Invoice",
                                  WhseShptLine."Qty. to Ship" + PurchLine."Return Qty. Shipped" - PurchLine."Quantity Invoiced");
                        end;
                    end;

                    ShouldModifyExpectedReceiptDate :=
                      (WhseShptHeader."Shipment Date" <> 0D) and
                      (PurchLine."Expected Receipt Date" <> WhseShptHeader."Shipment Date") and
                      (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding");
                    OnHandlePurchLineOnAfterCalcShouldModifyExpectedReceiptDate(WhseShptHeader, WhseShptLine, PurchLine, ShouldModifyExpectedReceiptDate);
#if not CLEAN25
                    WhsePostShipment.RunOnHandlePurchLineOnAfterCalcShouldModifyExpectedReceiptDate(WhseShptHeader, WhseShptLine, PurchLine, ShouldModifyExpectedReceiptDate);
#endif
                    if ShouldModifyExpectedReceiptDate then begin
                        PurchLine."Expected Receipt Date" := WhseShptHeader."Shipment Date";
                        ModifyLine := true;
                    end;

                    if PurchLine."Bin Code" <> WhseShptLine."Bin Code" then begin
                        PurchLine."Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                    end;
                end else
                    if not UpdateAllNonInventoryLines(PurchLine, ModifyLine) then
                        if not UpdateAttachedLine(PurchLine, WhseShptLine, ModifyLine) then
                            ClearPurchLineQtyToShipReceive(PurchLine, WhseShptLine, ModifyLine);
                OnBeforePurchLineModify(PurchLine, WhseShptLine, ModifyLine, WhsePostParameters);
#if not CLEAN25
                WhsePostShipment.RunOnBeforePurchLineModify(PurchLine, WhseShptLine, ModifyLine, WhsePostParameters);
#endif
                if ModifyLine then
                    PurchLine.Modify();
            until PurchLine.Next() = 0;

        OnAfterHandlePurchaseLine(WhseShptLine, PurchHeader, WhsePostParameters);
#if not CLEAN25
        WhsePostShipment.RunOnAfterHandlePurchaseLine(WhseShptLine, PurchHeader, WhsePostParameters);
#endif
    end;

    local procedure ClearPurchLineQtyToShipReceive(var PurchLine: Record "Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
        ModifyLine :=
            (PurchLine."Qty. to Receive" <> 0) or
            (PurchLine."Return Qty. to Ship" <> 0) or
            (PurchLine."Qty. to Invoice" <> 0);
        OnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(PurchLine, ModifyLine);
#if not CLEAN25
        WhsePostShipment.RunOnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(PurchLine, ModifyLine);
#endif

        if ModifyLine then begin
            if WarehouseShipmentLine."Source Document" = WarehouseShipmentLine."Source Document"::"Purchase Order" then
                PurchLine.Validate("Qty. to Receive", 0)
            else
                PurchLine.Validate("Return Qty. to Ship", 0);
            PurchLine.Validate("Qty. to Invoice", 0);
        end;
    end;

    local procedure UpdateAttachedLine(var PurchLine: Record "Purchase Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        WhseShptLine2: Record "Warehouse Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        QtyToHandle: Decimal;
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit(false);

        if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
            ItemChargeAssignmentPurch.SetRange("Document Type", PurchLine."Document Type");
            ItemChargeAssignmentPurch.SetRange("Document No.", PurchLine."Document No.");
            ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchLine."Line No.");
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", PurchLine."Document Type");
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchLine."Document No.");
            ItemChargeAssignmentPurch.SetFilter("Qty. to Handle", '<>0');
            if not ItemChargeAssignmentPurch.FindSet() then
                exit(false);
            repeat
                WhseShptLine2.Copy(WarehouseShipmentLine);
                WhseShptLine2.SetRange("Source Line No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.");
                if not WhseShptLine2.IsEmpty() then
                    QtyToHandle += ItemChargeAssignmentPurch."Qty. to Handle";
            until ItemChargeAssignmentPurch.Next() = 0;
        end else begin
            if PurchLine."Attached to Line No." = 0 then
                exit(false);
            WhseShptLine2.Copy(WarehouseShipmentLine);
            WhseShptLine2.SetRange("Source Line No.", PurchLine."Attached to Line No.");
            if WhseShptLine2.IsEmpty() then
                exit(false);
            QtyToHandle := PurchLine."Outstanding Quantity";
        end;

        if PurchLine."Document Type" = PurchLine."Document Type"::Order then begin
            ModifyLine := PurchLine."Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                PurchLine.Validate("Qty. to Receive", QtyToHandle);
        end else begin
            ModifyLine := PurchLine."Return Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                PurchLine.Validate("Return Qty. to Ship", QtyToHandle);
        end;

        exit(true);
    end;

    local procedure UpdateAllNonInventoryLines(var PurchaseLine: Record "Purchase Line"; var ModifyLine: Boolean): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        if PurchaseLine.IsInventoriableItem() then
            exit(false);

        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::All then
            exit(false);

        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
            ModifyLine := PurchaseLine."Qty. to Receive" <> PurchaseLine."Outstanding Quantity";
            if ModifyLine then
                PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Outstanding Quantity");
        end else begin
            ModifyLine := PurchaseLine."Return Qty. to Ship" <> PurchaseLine."Outstanding Quantity";
            if ModifyLine then
                PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine."Outstanding Quantity");
        end;

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPostSourceDocument', '', false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer; var SourceHeader: Variant; var DocumentEntryToPrint: Record "Document Entry" temporary; WhsePostParameters: Record "Whse. Post Parameters" temporary)
    var
        PurchHeader: Record "Purchase Header";
        WarehouseSetup: Record "Warehouse Setup";
        PurchPost: Codeunit "Purch.-Post";
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Purchase Line":
                // Return Order
                begin
                    PurchHeader := SourceHeader;
                    PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Purchase Order" then
                        PurchHeader.Receive := true
                    else
                        PurchHeader.Ship := true;
                    PurchHeader.Invoice := WhsePostParameters."Post Invoice";

                    PurchPost.SetWhseShptHeader(WhseShptHeader);
                    PurchPost.SetPreviewMode(WhsePostParameters."Preview Posting");
                    PurchPost.SetSuppressCommit(WhsePostParameters."Suppress Commit");
                    PurchPost.SetCalledBy(Codeunit::"Whse.-Post Shipment");
                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostPurchHeader(PurchPost, PurchHeader, WhsePostParameters, WhseShptHeader, CounterDocOK, IsHandled);
#if not CLEAN25
                    WhsePostShipment.RunOnPostSourceDocumentOnBeforePostPurchHeader(PurchPost, PurchHeader, WhsePostParameters, WhseShptHeader, CounterDocOK, IsHandled);

#endif
                    if not IsHandled then
                        if WhsePostParameters."Preview Posting" then
                            PostSourcePurchDocument(PurchHeader, PurchPost, CounterDocOK)
                        else begin
                            WarehouseSetup.Get();
                            case WarehouseSetup."Shipment Posting Policy" of
                                WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                    TryPostSourcePurchDocument(PurchHeader, PurchPost, CounterDocOK);
                                WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                    PostSourcePurchDocument(PurchHeader, PurchPost, CounterDocOK);
                            end;
                        end;

                    if WhsePostParameters."Print Documents" then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Purchase Return Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintPurchReturnShipment(PurchHeader, IsHandled);
#if not CLEAN25
                            WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintPurchReturnShipment(PurchHeader, IsHandled);
#endif
                            if not IsHandled then
                                InsertDocumentEntryToPrint(
                                    DocumentEntryToPrint, Database::"Return Shipment Header", PurchHeader."Last Return Shipment No.");
                            if WhsePostParameters."Post Invoice" then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintPurchCreditMemo(PurchHeader, IsHandled);
#if not CLEAN25
                                WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintPurchCreditMemo(PurchHeader, IsHandled);
#endif
                                if not IsHandled then
                                    InsertDocumentEntryToPrint(
                                        DocumentEntryToPrint, Database::"Purch. Cr. Memo Hdr.", PurchHeader."Last Posting No.");
                            end;
                        end;

                    OnAfterPurchPost(WhseShptLine, PurchHeader, WhsePostParameters, WhseShptHeader);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterPurchPost(WhseShptLine, PurchHeader, WhsePostParameters, WhseShptHeader);
#endif
                    Clear(PurchPost);
                end;
        end;
    end;

    local procedure InsertDocumentEntryToPrint(var DocumentEntry: Record "Document Entry"; TableID: Integer; DocumentNo: Code[20])
    begin
        DocumentEntry.Init();
        DocumentEntry."Entry No." := DocumentEntry."Entry No." + 1;
        DocumentEntry."Table ID" := TableID;
        DocumentEntry."Document No." := DocumentNo;
        DocumentEntry.Insert();
    end;

    local procedure TryPostSourcePurchDocument(var PurchHeader: Record "Purchase Header"; var PurchPost: Codeunit "Purch.-Post"; var CounterSourceDocOK: Integer)
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTryPostSourcePurchDocument(PurchPost, PurchHeader, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeTryPostSourcePurchDocument(PurchPost, PurchHeader, IsHandled);
#endif
        if not IsHandled then
            if PurchPost.Run(PurchHeader) then begin
                CounterSourceDocOK := CounterSourceDocOK + 1;
                Result := true;
            end;

        OnAfterTryPostSourcePurchDocument(CounterSourceDocOK, PurchPost, PurchHeader, Result);
#if not CLEAN25
        WhsePostShipment.RunOnAfterTryPostSourcePurchDocument(CounterSourceDocOK, PurchPost, PurchHeader, Result);
#endif
    end;

    local procedure PostSourcePurchDocument(var PurchHeader: Record "Purchase Header"; var PurchPost: Codeunit "Purch.-Post"; var CounterSourceDocOK: Integer)
    begin
        OnBeforePostSourcePurchDocument(PurchPost, PurchHeader);
#if not CLEAN25
        WhsePostShipment.RunOnBeforePostSourcePurchDocument(PurchPost, PurchHeader);
#endif

        PurchPost.RunWithCheck(PurchHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;

        OnAfterPostSourcePurchDocument(CounterSourceDocOK, PurchPost, PurchHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPrintDocuments', '', false, false)]
    local procedure OnPrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
        PrintDocuments(DocumentEntryToPrint);
    end;

    local procedure PrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        DocumentEntryToPrint.SetRange("Table ID", Database::"Purch. Cr. Memo Hdr.");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    PurchCrMemoHdr.Get(DocumentEntryToPrint."Document No.");
                    PurchCrMemoHdr.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            PurchCrMemoHdr.MarkedOnly(true);
            PurchCrMemoHdr.PrintRecords(false);
        end;

        DocumentEntryToPrint.SetRange("Table ID", Database::"Return Shipment Header");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    ReturnShipmentHeader.Get(DocumentEntryToPrint."Document No.");
                    ReturnShipmentHeader.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            ReturnShipmentHeader.MarkedOnly(true);
            ReturnShipmentHeader.PrintRecords(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandlePurchaseLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchLine: Record "Purchase Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(var PurchaseHeader: Record "Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(var PurchLine: Record "Purchase Line"; var ModifyLine: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchaseLineOnAfterValidateQtytoReceive(var PurchLine: Record "Purchase Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchaseLineOnAfterValidateRetQtytoShip(var PurchLine: Record "Purchase Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(var PurchaseHeader: Record "Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchLineOnAfterCalcShouldModifyExpectedReceiptDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record "Purchase Line"; var ShouldModifyExpectedReceiptDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandlePurchaseLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; PurchHeader: Record "Purchase Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostPurchHeader(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record "Purchase Header"; var WhsePostParameters: Record "Whse. Post Parameters"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchReturnShipment(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchCreditMemo(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PurchaseHeader: Record "Purchase Header"; WhsePosrParameters: Record "Whse. Post Parameters"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryPostSourcePurchDocument(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTryPostSourcePurchDocument(var CounterSourceDocOK: Integer; var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourcePurchDocument(var CounterSourceDocOK: Integer; var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourcePurchDocument(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
    end;
}
