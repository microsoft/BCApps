// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

codeunit 5760 "Whse.-Post Receipt"
{
    Permissions = TableData "Whse. Item Entry Relation" = ri,
                  TableData "Posted Whse. Receipt Header" = rim,
                  TableData "Posted Whse. Receipt Line" = ri;
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        OnBeforeRun(Rec, SuppressCommit, PreviewMode);

        WhseRcptLine.Copy(Rec);
        Code();
        Rec := WhseRcptLine;

        OnAfterRun(Rec);
    end;

    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary;
        TransHeader: Record "Transfer Header";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseRqst: Record "Warehouse Request";
        TempWhseItemEntryRelation: Record "Whse. Item Entry Relation" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgt: Codeunit "WMS Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        CreatePutAway: Codeunit "Create Put-away";
        PostingDate: Date;
        CounterSourceDocOK: Integer;
        CounterSourceDocTotal: Integer;
        CounterPutAways: Integer;
        PutAwayRequired: Boolean;
        ReceivingNo: Code[20];
        ItemEntryRelationCreated: Boolean;
#pragma warning disable AA0074
        Text004: Label 'is not within your range of allowed posting dates';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The source document %1 %2 is not released.';
        Text002: Label 'Number of source documents posted: %1 out of a total of %2.';
        Text003: Label 'Number of put-away activities created: %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SuppressCommit: Boolean;
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;

    local procedure "Code"()
    var
        WhseManagement: Codeunit "Whse. Management";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        NoSeries: Codeunit "No. Series";
        ShouldCreatePutAway: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseRcptLine, SuppressCommit, CounterSourceDocOK, CounterSourceDocTotal, IsHandled);
        if IsHandled then
            exit;

        WhseRcptLine.SetCurrentKey(WhseRcptLine."No.");
        WhseRcptLine.SetRange("No.", WhseRcptLine."No.");
        WhseRcptLine.SetFilter("Qty. to Receive", '>0');
        OnAfterWhseRcptLineSetFilters(WhseRcptLine);
        if WhseRcptLine.Find('-') then
            repeat
                CheckUnitOfMeasureCode(WhseRcptLine);
                WhseRqst.Get(
                  WhseRqst.Type::Inbound, WhseRcptLine."Location Code", WhseRcptLine."Source Type", WhseRcptLine."Source Subtype", WhseRcptLine."Source No.");
                CheckWhseRqstDocumentStatus();
                OnAfterCheckWhseRcptLine(WhseRcptLine);
            until WhseRcptLine.Next() = 0
        else
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        CounterSourceDocOK := 0;
        CounterSourceDocTotal := 0;
        CounterPutAways := 0;
        Clear(CreatePutAway);

        WhseRcptHeader.Get(WhseRcptLine."No.");
        OnCodeOnAfterGetWhseRcptHeader(WhseRcptHeader);
        WhseRcptHeader.TestField("Posting Date");
        OnAfterCheckWhseRcptLines(WhseRcptHeader, WhseRcptLine);
        if WhseRcptHeader."Receiving No." = '' then begin
            WhseRcptHeader.TestField("Receiving No. Series");
            WhseRcptHeader."Receiving No." :=
              NoSeries.GetNextNo(WhseRcptHeader."Receiving No. Series", WhseRcptHeader."Posting Date");
        end;
        WhseRcptHeader."Create Posted Header" := true;
        OnCodeOnBeforeWhseRcptHeaderModify(WhseRcptHeader, WhseRcptLine);
        WhseRcptHeader.Modify();
        if not (SuppressCommit or PreviewMode) then
            Commit();

        OnCodeOnAfterWhseRcptHeaderModify(WhseRcptHeader);
        WhseRcptLine.SetCurrentKey("No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WhseRcptLine.FindSet(true);
        repeat
            WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, WhseRcptLine."Source Type", WhseRcptLine."Source Subtype", WhseRcptLine."Source No.", -1, false);
            GetSourceDocument();
            MakePreliminaryChecks();
            InitSourceDocumentLines(WhseRcptLine);
            InitSourceDocumentHeader();
            if not (SuppressCommit or PreviewMode) then
                Commit();

            CounterSourceDocTotal := CounterSourceDocTotal + 1;

            IsHandled := false;
            OnBeforePostSourceDocument(
                WhseRcptLine, PurchHeader, SalesHeader, TransHeader, CounterSourceDocOK, HideValidationDialog, IsHandled);
            if not IsHandled then
                PostSourceDocument(WhseRcptLine);

            WhseRcptLine.ReadIsolation(IsolationLevel::ReadUnCommitted); // to avoid range lock with next batch
            if WhseRcptLine.FindLast() then;
            WhseRcptLine.ReadIsolation(IsolationLevel::UpdLock);
            WhseRcptLine.SetRange("Source Type");
            WhseRcptLine.SetRange("Source Subtype");
            WhseRcptLine.SetRange("Source No.");
            OnCodeOnAfterRemoveSourceFilterFromWhseRcptLine(WhseRcptLine, PurchHeader, SalesHeader, TransHeader);
        until WhseRcptLine.Next() = 0;

        OnCodeOnAfterPostSourceDocuments(WhseRcptHeader, WhseRcptLine);

        GetLocation(WhseRcptLine."Location Code");
        PutAwayRequired := Location.RequirePutaway(WhseRcptLine."Location Code");
        OnCodeOnAfterSetPutAwayRequired(WhseRcptHeader, PutAwayRequired);
        ShouldCreatePutAway := PutAwayRequired and not Location."Use Put-away Worksheet";
        OnCodeOnAfterCalcShouldCreatePutAway(WhseRcptHeader, Location, PutAwayRequired, SuppressCommit, HideValidationDialog, ShouldCreatePutAway, CounterPutAways);
        if ShouldCreatePutAway then begin
            CreatePutAwayDoc(WhseRcptHeader);
            if not (SuppressCommit or PreviewMode) then
                Commit();
        end;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        Clear(WMSMgt);
        Clear(WhseJnlRegisterLine);

        OnAfterCode(WhseRcptHeader, WhseRcptLine, CounterSourceDocTotal, CounterSourceDocOK);
    end;

    local procedure CheckUnitOfMeasureCode(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUnitOfMeasureCode(WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        WarehouseReceiptLine.TestField("Unit of Measure Code");
    end;

    local procedure CheckWhseRqstDocumentStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseRqstDocumentStatus(WhseRqst, WhseRcptLine, SalesHeader, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if WhseRqst."Document Status" <> WhseRqst."Document Status"::Released then
            Error(Text000, WhseRcptLine."Source Document", WhseRcptLine."Source No.");
    end;

    local procedure GetSourceDocument()
    var
        SourceHeader: Variant;
    begin
        case WhseRcptLine."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchHeader.Get(WhseRcptLine."Source Subtype", WhseRcptLine."Source No.");
                    SourceHeader := PurchHeader;
                end;
            Database::"Sales Line":
                begin
                    SalesHeader.Get(WhseRcptLine."Source Subtype", WhseRcptLine."Source No.");
                    SourceHeader := SalesHeader;
                end;
            Database::"Transfer Line":
                begin
                    TransHeader.Get(WhseRcptLine."Source No.");
                    SourceHeader := TransHeader;
                end;
            else
                OnGetSourceDocumentOnElseCase(SourceHeader);
        end;

        OnAfterGetSourceDocument(SourceHeader, WhseRcptLine, SuppressCommit);
    end;

    local procedure MakePreliminaryChecks()
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(WhseRcptHeader."Posting Date") then
            WhseRcptHeader.FieldError("Posting Date", Text004);
    end;

    local procedure InitSourceDocumentHeader()
    var
        SalesRelease: Codeunit "Release Sales Document";
        PurchRelease: Codeunit "Release Purchase Document";
        ModifyHeader: Boolean;
    begin
        OnBeforeInitSourceDocumentHeader(WhseRcptLine);
        case WhseRcptLine."Source Type" of
            Database::"Purchase Line":
                begin
                    OnInitSourceDocumentOnBeforePurchHeaderInit(PurchHeader, WhseRcptHeader, WhseRcptLine, ModifyHeader);
                    if (PurchHeader."Posting Date" = 0D) or
                       (PurchHeader."Posting Date" <> WhseRcptHeader."Posting Date")
                    then begin
                        OnInitSourceDocumentHeaderOnBeforePurchHeaderReopen(PurchHeader, WhseRcptHeader);
                        PurchRelease.SetSkipWhseRequestOperations(true);
                        PurchRelease.Reopen(PurchHeader);
                        PurchRelease.SetSkipCheckReleaseRestrictions();
                        PurchHeader.SetHideValidationDialog(true);
                        PurchHeader.SetCalledFromWhseDoc(true);
                        PurchHeader.Validate("Posting Date", WhseRcptHeader."Posting Date");
                        OnInitSourceDocumentHeaderOnBeforeRunPurchRelease(PurchHeader);
                        PurchRelease.ReleasePurchaseHeader(PurchHeader, PreviewMode);
                        ModifyHeader := true;
                    end;
                    if WhseRcptHeader."Vendor Shipment No." <> '' then begin
                        PurchHeader."Vendor Shipment No." := WhseRcptHeader."Vendor Shipment No.";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(PurchHeader, WhseRcptHeader, ModifyHeader);
                    if ModifyHeader then
                        PurchHeader.Modify();
                    OnInitSourceDocumentHeaderOnAfterPurchHeaderModify(PurchHeader, WhseRcptLine, ModifyHeader);
                end;
            Database::"Sales Line":
                begin
                    OnInitSourceDocumentOnBeforeSalesHeaderInit(SalesHeader, WhseRcptHeader, WhseRcptLine, ModifyHeader);
                    if (SalesHeader."Posting Date" = 0D) or
                       (SalesHeader."Posting Date" <> WhseRcptHeader."Posting Date")
                    then begin
                        SalesRelease.SetSkipWhseRequestOperations(true);
                        SalesRelease.Reopen(SalesHeader);
                        SalesRelease.SetSkipCheckReleaseRestrictions();
                        SalesHeader.SetHideValidationDialog(true);
                        SalesHeader.SetCalledFromWhseDoc(true);
                        SalesHeader.Validate("Posting Date", WhseRcptHeader."Posting Date");
                        SalesRelease.ReleaseSalesHeader(SalesHeader, PreviewMode);
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(SalesHeader, WhseRcptHeader, ModifyHeader);
                    if ModifyHeader then
                        SalesHeader.Modify();
                    OnInitSourceDocumentHeaderOnAfterSalesHeaderModify(SalesHeader, WhseRcptLine, ModifyHeader);
                end;
            Database::"Transfer Line":
                begin
                    OnInitSourceDocumentOnBeforeTransferHeaderInit(TransHeader, WhseRcptHeader, WhseRcptLine, ModifyHeader);
                    if (TransHeader."Posting Date" = 0D) or
                       (TransHeader."Posting Date" <> WhseRcptHeader."Posting Date")
                    then begin
                        TransHeader.CalledFromWarehouse(true);
                        TransHeader.Validate("Posting Date", WhseRcptHeader."Posting Date");
                        ModifyHeader := true;
                    end;
                    if WhseRcptHeader."Vendor Shipment No." <> '' then begin
                        TransHeader."External Document No." := WhseRcptHeader."Vendor Shipment No.";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(TransHeader, WhseRcptHeader, ModifyHeader);
                    if ModifyHeader then
                        TransHeader.Modify();
                    OnInitSourceDocumentHeaderOnAfterTransHeaderModify(TransHeader, WhseRcptLine, ModifyHeader);
                end;
            else
                OnInitSourceDocumentHeader(WhseRcptHeader, WhseRcptLine);
        end;
        OnAfterInitSourceDocumentHeader(WhseRcptLine);
    end;

    local procedure InitSourceDocumentLines(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        WarehouseReceiptLine2: Record "Warehouse Receipt Line";
        TransLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitSourceDocumentLines(WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        WarehouseReceiptLine2.Copy(WarehouseReceiptLine);
        case WarehouseReceiptLine2."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchaseLine.SetRange("Document Type", WarehouseReceiptLine2."Source Subtype");
                    PurchaseLine.SetRange("Document No.", WarehouseReceiptLine2."Source No.");
                    if PurchaseLine.Find('-') then
                        repeat
                            IsHandled := false;
                            OnInitSourceDocumentLinesOnBeforeProcessPurchLine(PurchaseLine, IsHandled);
                            if not IsHandled then begin
                                WarehouseReceiptLine2.SetRange("Source Line No.", PurchaseLine."Line No.");
                                if WarehouseReceiptLine2.FindFirst() then begin
                                    OnAfterFindWhseRcptLineForPurchLine(WarehouseReceiptLine2, PurchaseLine);
                                    if WarehouseReceiptLine2."Source Document" = WarehouseReceiptLine2."Source Document"::"Purchase Order" then begin
                                        ModifyLine := PurchaseLine."Qty. to Receive" <> WarehouseReceiptLine2."Qty. to Receive";
                                        if ModifyLine then
                                            ValidateQtyToReceiveOnPurchaseLine(PurchaseLine, WarehouseReceiptLine2)
                                    end else begin
                                        ModifyLine := PurchaseLine."Return Qty. to Ship" <> -WarehouseReceiptLine2."Qty. to Receive";
                                        if ModifyLine then
                                            PurchaseLine.Validate("Return Qty. to Ship", -WarehouseReceiptLine2."Qty. to Receive");
                                    end;
                                    if PurchaseLine."Bin Code" <> WarehouseReceiptLine2."Bin Code" then begin
                                        PurchaseLine."Bin Code" := WarehouseReceiptLine2."Bin Code";
                                        ModifyLine := true;
                                    end;
                                    OnInitSourceDocumentLinesOnAfterSourcePurchLineFound(PurchaseLine, WarehouseReceiptLine2, ModifyLine, WhseRcptHeader);
                                end else
                                    if not UpdateAllNonInventoryLines(PurchaseLine, ModifyLine) then
                                        if not UpdateAttachedLine(PurchaseLine, WarehouseReceiptLine2, ModifyLine) then
                                            ClearPurchLineQtyToShipReceive(PurchaseLine, WarehouseReceiptLine2, ModifyLine);
                                OnBeforePurchLineModify(PurchaseLine, WarehouseReceiptLine2, ModifyLine);
                                if ModifyLine then
                                    PurchaseLine.Modify();
                                OnInitSourceDocumentLinesOnAfterPurchLineModify(PurchaseLine, ModifyLine);
                            end;
                        until PurchaseLine.Next() = 0;
                    OnInitSourceDocumentLinesOnAfterModifyPurchLines(PurchHeader);
                end;
            Database::"Sales Line":
                begin
                    SalesLine.SetRange("Document Type", WarehouseReceiptLine2."Source Subtype");
                    SalesLine.SetRange("Document No.", WarehouseReceiptLine2."Source No.");
                    if SalesLine.Find('-') then
                        repeat
                            IsHandled := false;
                            OnInitSourceDocumentLinesOnBeforeProcessSalesLine(SalesLine, IsHandled);
                            if not IsHandled then begin
                                WarehouseReceiptLine2.SetRange("Source Line No.", SalesLine."Line No.");
                                if WarehouseReceiptLine2.FindFirst() then begin
                                    OnAfterFindWhseRcptLineForSalesLine(WarehouseReceiptLine2, SalesLine);
                                    if WarehouseReceiptLine2."Source Document" = WarehouseReceiptLine2."Source Document"::"Sales Order" then begin
                                        ModifyLine := SalesLine."Qty. to Ship" <> -WarehouseReceiptLine2."Qty. to Receive";
                                        if ModifyLine then
                                            SalesLine.Validate("Qty. to Ship", -WarehouseReceiptLine2."Qty. to Receive");
                                    end else begin
                                        ModifyLine := SalesLine."Return Qty. to Receive" <> WarehouseReceiptLine2."Qty. to Receive";
                                        if ModifyLine then
                                            ValidateReturnQtyToReceiveOnSalesLine(SalesLine, WarehouseReceiptLine2);
                                    end;
                                    CheckUpdateSalesLineBinCode(SalesLine, WarehouseReceiptLine2, ModifyLine);
                                    OnInitSourceDocumentLinesOnAfterSourceSalesLineFound(SalesLine, WarehouseReceiptLine2, ModifyLine, WhseRcptHeader, WarehouseReceiptLine);
                                end else
                                    if not UpdateAllNonInventoryLines(SalesLine, ModifyLine) then
                                        if not UpdateAttachedLine(SalesLine, WarehouseReceiptLine2, ModifyLine) then
                                            ClearSalesLineQtyToShipReceive(SalesLine, WarehouseReceiptLine2, ModifyLine);
                                OnBeforeSalesLineModify(SalesLine, WarehouseReceiptLine2, ModifyLine);
                                if ModifyLine then
                                    SalesLine.Modify();
                                OnInitSourceDocumentLinesOnAfterSalesLineModify(SalesLine, ModifyLine);
                            end;
                        until SalesLine.Next() = 0;
                    OnInitSourceDocumentLinesOnAfterModifySalesLines(SalesHeader);
                end;
            Database::"Transfer Line":
                begin
                    TransLine.SetRange("Document No.", WarehouseReceiptLine2."Source No.");
                    TransLine.SetRange("Derived From Line No.", 0);
                    if TransLine.Find('-') then
                        repeat
                            WarehouseReceiptLine2.SetRange("Source Line No.", TransLine."Line No.");
                            if WarehouseReceiptLine2.FindFirst() then begin
                                OnAfterFindWhseRcptLineForTransLine(WarehouseReceiptLine2, TransLine);
                                ModifyLine := TransLine."Qty. to Receive" <> WarehouseReceiptLine2."Qty. to Receive";
                                if ModifyLine then
                                    ValidateQtyToReceiveOnTransferLine(TransLine, WarehouseReceiptLine2);
                                if TransLine."Transfer-To Bin Code" <> WarehouseReceiptLine2."Bin Code" then begin
                                    TransLine."Transfer-To Bin Code" := WarehouseReceiptLine2."Bin Code";
                                    ModifyLine := true;
                                end;
                                OnInitSourceDocumentLinesOnAfterSourceTransLineFound(TransLine, WarehouseReceiptLine2, ModifyLine);
                            end else begin
                                ModifyLine := TransLine."Qty. to Receive" <> 0;
                                if ModifyLine then
                                    TransLine.Validate("Qty. to Receive", 0);
                                OnInitSourceDocumentLinesOnAfterClearTransLineQtyToReceive(TransLine, WarehouseReceiptLine2, ModifyLine);
                            end;
                            OnBeforeTransLineModify(TransLine, WarehouseReceiptLine2, ModifyLine, WhseRcptHeader);
                            if ModifyLine then
                                TransLine.Modify();
                        until TransLine.Next() = 0;
                end;
            else
                OnInitSourceDocumentLines(WarehouseReceiptLine2);
        end;
        WarehouseReceiptLine2.SetRange("Source Line No.");

        OnAfterInitSourceDocumentLines(WarehouseReceiptLine2);
    end;

    local procedure ValidateQtyToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQtyToReceiveOnPurchaseLine(PurchaseLine, WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.Validate("Qty. to Receive", WarehouseReceiptLine."Qty. to Receive")
    end;

    local procedure ValidateQtyToReceiveOnTransferLine(var TransferLine: Record "Transfer Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQtyToReceiveOnTransferLine(TransferLine, WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine.Validate("Qty. to Receive", WarehouseReceiptLine."Qty. to Receive")
    end;

    local procedure ValidateReturnQtyToReceiveOnSalesLine(var SalesLine: Record "Sales Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateReturnQtyToReceiveOnSalesLine(SalesLine, WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Return Qty. to Receive", WarehouseReceiptLine."Qty. to Receive");

    end;

    local procedure ClearSalesLineQtyToShipReceive(var SalesLine: Record "Sales Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearSalesLineQtyToShipReceive(SalesLine, WarehouseReceiptLine, ModifyLine, IsHandled);
        if not IsHandled then
            if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Sales Order" then begin
                ModifyLine := SalesLine."Qty. to Ship" <> 0;
                if ModifyLine then
                    SalesLine.Validate("Qty. to Ship", 0);
            end else begin
                ModifyLine := SalesLine."Return Qty. to Receive" <> 0;
                if ModifyLine then
                    SalesLine.Validate("Return Qty. to Receive", 0);
            end;
        OnAfterClearSalesLineQtyToShipReceive(SalesLine, WarehouseReceiptLine, ModifyLine);
    end;

    local procedure ClearPurchLineQtyToShipReceive(var PurchaseLine: Record "Purchase Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearPurchLineQtyToShipReceive(PurchaseLine, WarehouseReceiptLine, ModifyLine, IsHandled);
        if not IsHandled then
            if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Purchase Order" then begin
                ModifyLine := PurchaseLine."Qty. to Receive" <> 0;
                if ModifyLine then
                    PurchaseLine.Validate("Qty. to Receive", 0);
            end else begin
                ModifyLine := PurchaseLine."Return Qty. to Ship" <> 0;
                if ModifyLine then
                    PurchaseLine.Validate("Return Qty. to Ship", 0);
            end;
        OnAfterClearPurchLineQtyToShipReceive(PurchaseLine, WarehouseReceiptLine, ModifyLine);
    end;

    local procedure UpdateAttachedLine(var PurchaseLine: Record "Purchase Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        WarehouseReceiptLine2: Record "Warehouse Receipt Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        QtyToHandle: Decimal;
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit(false);

        if PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)" then begin
            ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
            ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
            ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", PurchaseLine."Document Type");
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchaseLine."Document No.");
            ItemChargeAssignmentPurch.SetFilter("Qty. to Handle", '<>0');
            if not ItemChargeAssignmentPurch.FindSet() then
                exit(false);
            repeat
                WarehouseReceiptLine2.Copy(WarehouseReceiptLine);
                WarehouseReceiptLine2.SetRange("Source Line No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.");
                if not WarehouseReceiptLine2.IsEmpty() then
                    QtyToHandle += ItemChargeAssignmentPurch."Qty. to Handle";
            until ItemChargeAssignmentPurch.Next() = 0;
        end else begin
            if PurchaseLine."Attached to Line No." = 0 then
                exit(false);
            WarehouseReceiptLine2.Copy(WarehouseReceiptLine);
            WarehouseReceiptLine2.SetRange("Source Line No.", PurchaseLine."Attached to Line No.");
            if WarehouseReceiptLine2.IsEmpty() then
                exit(false);
            QtyToHandle := PurchaseLine."Outstanding Quantity";
        end;

        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
            if PurchaseLine."Quantity Received" <> QtyToHandle then begin
                ModifyLine := PurchaseLine."Qty. to Receive" <> QtyToHandle;
                if ModifyLine then
                    PurchaseLine.Validate("Qty. to Receive", QtyToHandle);
            end;
        end else begin
            ModifyLine := PurchaseLine."Return Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                PurchaseLine.Validate("Return Qty. to Ship", QtyToHandle);
        end;

        exit(true);
    end;

    local procedure UpdateAttachedLine(var SalesLine: Record "Sales Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean) Result: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WarehouseReceiptLine2: Record "Warehouse Receipt Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        QtyToHandle: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAttachedLine(SalesLine, WarehouseReceiptLine, ModifyLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit(false);

        if SalesLine.Type = SalesLine.Type::"Charge (Item)" then begin
            ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
            ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
            ItemChargeAssignmentSales.SetRange("Document Line No.", SalesLine."Line No.");
            ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", SalesLine."Document Type");
            ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SalesLine."Document No.");
            ItemChargeAssignmentSales.SetFilter("Qty. to Handle", '<>0');
            if not ItemChargeAssignmentSales.FindSet() then
                exit(false);
            repeat
                WarehouseReceiptLine2.Copy(WarehouseReceiptLine);
                WarehouseReceiptLine2.SetRange("Source Line No.", ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                if not WarehouseReceiptLine2.IsEmpty() then
                    QtyToHandle += ItemChargeAssignmentSales."Qty. to Handle";
            until ItemChargeAssignmentSales.Next() = 0;
        end else begin
            if SalesLine."Attached to Line No." = 0 then
                exit(false);
            WarehouseReceiptLine2.Copy(WarehouseReceiptLine);
            WarehouseReceiptLine2.SetRange("Source Line No.", SalesLine."Attached to Line No.");
            if WarehouseReceiptLine2.IsEmpty() then
                exit(false);
            QtyToHandle := SalesLine."Outstanding Quantity";
        end;

        OnUpdateAttachedLineOnBeforeModifyLine(SalesLine, WarehouseReceiptLine, ModifyLine, QtyToHandle);
        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", QtyToHandle);
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", QtyToHandle);
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

    local procedure UpdateAllNonInventoryLines(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesLine.IsInventoriableItem() then
            exit(false);

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::All then
            exit(false);

        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> SalesLine."Outstanding Quantity";
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", SalesLine."Outstanding Quantity");
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> SalesLine."Outstanding Quantity";
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", SalesLine."Outstanding Quantity");
        end;

        exit(true);
    end;

    local procedure CheckUpdateSalesLineBinCode(var SalesLine: Record "Sales Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateSalesLineBinCode(SalesLine, WarehouseReceiptLine, ModifyLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."Bin Code" <> WarehouseReceiptLine."Bin Code" then begin
            SalesLine."Bin Code" := WarehouseReceiptLine."Bin Code";
            ModifyLine := true;
        end;
    end;

    local procedure PostSourceDocument(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        IsHandled: Boolean;
    begin
        WarehouseSetup.Get();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        OnPostSourceDocumentOnAfterGetWhseRcptHeader(WarehouseReceiptLine, WarehouseReceiptHeader, WarehouseSetup, SuppressCommit);
        case WarehouseReceiptLine."Source Type" of
            Database::"Purchase Line":
                begin
                    if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Purchase Order" then
                        PurchHeader.Receive := true
                    else
                        PurchHeader.Ship := true;
                    PurchHeader.Invoice := false;
                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostPurchaseHeader(PurchHeader, WarehouseReceiptHeader, SuppressCommit, CounterSourceDocOK, IsHandled);
                    if not IsHandled then begin
                        PurchPost.SetWhseRcptHeader(WarehouseReceiptHeader);
                        PurchPost.SetSuppressCommit(SuppressCommit);
                        PurchPost.SetPreviewMode(PreviewMode);
                        PurchPost.SetCalledBy(Codeunit::"Whse.-Post Receipt");
                        if PreviewMode then
                            PostSourcePurchDocument(PurchPost)
                        else
                            case WarehouseSetup."Receipt Posting Policy" of
                                WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed":
                                    PostPurchErrorsNotProcessed(PurchPost);
                                WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error":
                                    PostSourcePurchDocument(PurchPost);
                            end;
                    end;
                    OnPostSourceDocumentOnAfterPostPurchaseHeader(PurchHeader);
                    Clear(PurchPost);
                end;
            Database::"Sales Line":
                begin
                    if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Sales Order" then
                        SalesHeader.Ship := true
                    else
                        SalesHeader.Receive := true;
                    SalesHeader.Invoice := false;
                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostSalesHeader(SalesHeader, WarehouseReceiptHeader, SuppressCommit, CounterSourceDocOK, IsHandled);
                    if not IsHandled then begin
                        SalesPost.SetWhseRcptHeader(WarehouseReceiptHeader);
                        SalesPost.SetSuppressCommit(SuppressCommit);
                        SalesPost.SetPreviewMode(PreviewMode);
                        SalesPost.SetCalledBy(Codeunit::"Whse.-Post Receipt");
                        if PreviewMode then
                            PostSourceSalesDocument(SalesPost)
                        else
                            case WarehouseSetup."Receipt Posting Policy" of
                                WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed":
                                    PostSalesErrorsNotProcessed(SalesPost);
                                WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error":
                                    PostSourceSalesDocument(SalesPost);
                            end;
                    end;
                    OnPostSourceDocumentOnAfterPostSalesHeader(SalesHeader);
                    Clear(SalesPost);
                end;
            Database::"Transfer Line":
                begin
                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostTransferHeader(TransHeader, WarehouseReceiptHeader, SuppressCommit, CounterSourceDocOK, IsHandled);
                    if not IsHandled then begin
                        if HideValidationDialog then
                            TransferPostReceipt.SetHideValidationDialog(HideValidationDialog);
                        TransferPostReceipt.SetWhseRcptHeader(WarehouseReceiptHeader);
                        TransferPostReceipt.SetSuppressCommit(SuppressCommit or PreviewMode);
                        TransferPostReceipt.SetPreviewMode(PreviewMode);
                        TransferPostReceipt.SetCalledBy(Codeunit::"Whse.-Post Receipt");
                        if PreviewMode then
                            PostSourceTransferDocument(TransferPostReceipt)
                        else
                            case WarehouseSetup."Receipt Posting Policy" of
                                WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed":
                                    PostTransferErrorsNotProcessed(TransferPostReceipt);
                                WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error":
                                    PostSourceTransferDocument(TransferPostReceipt);
                            end;
                    end;
                    OnPostSourceDocumentOnAfterPostTransferHeader(TransHeader);
                    Clear(TransferPostReceipt);
                end;
            else
                OnPostSourceDocument(WarehouseReceiptHeader, WarehouseReceiptLine, CounterSourceDocOK);
        end;

        OnAfterPostSourceDocument(WarehouseReceiptLine);
    end;

    local procedure PostPurchErrorsNotProcessed(var PurchPost: Codeunit "Purch.-Post")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostPurchErrorsNotProcessed(PurchPost, PurchHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        if PurchPost.Run(PurchHeader) then
            CounterSourceDocOK := CounterSourceDocOK + 1;
    end;

    local procedure PostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostSourcePurchDocument(PurchPost, PurchHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        PurchPost.RunWithCheck(PurchHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;
    end;

    local procedure PostSalesErrorsNotProcessed(var SalesPost: Codeunit "Sales-Post")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostSalesErrorsNotProcessed(SalesPost, SalesHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        if SalesPost.Run(SalesHeader) then
            CounterSourceDocOK := CounterSourceDocOK + 1;
    end;

    local procedure PostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostSourceSalesDocument(SalesPost, SalesHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        SalesPost.RunWithCheck(SalesHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;
    end;

    local procedure PostTransferErrorsNotProcessed(var TransferPostReceipt: Codeunit "TransferOrder-Post Receipt")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostTransferErrorsNotProcessed(TransferPostReceipt, TransHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        if TransferPostReceipt.Run(TransHeader) then
            CounterSourceDocOK := CounterSourceDocOK + 1;
    end;

    local procedure PostSourceTransferDocument(var TransferPostReceipt: Codeunit "TransferOrder-Post Receipt")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostSourceTransferDocument(TransferPostReceipt, TransHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        TransferPostReceipt.RunWithCheck(TransHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;
    end;

    procedure GetResultMessage()
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetResultMessage(CounterPutAways, IsHandled);
        if IsHandled then
            exit;

        MessageText := Text002;
        if CounterPutAways > 0 then
            MessageText := MessageText + '\\' + Text003;

        OnGetResultMessageOnBeforeMessage(CounterPutAways, MessageText);
        Message(MessageText, CounterSourceDocOK, CounterSourceDocTotal, CounterPutAways);
    end;

    procedure PostUpdateWhseDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        PostedWhseReceiptHeaderNo: Code[20];
        DeleteWhseRcptLine: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforePostUpdateWhseDocuments(WarehouseReceiptHeader);
        if TempWarehouseReceiptLine.Find('-') then begin
            repeat
                WarehouseReceiptLine.Get(TempWarehouseReceiptLine."No.", TempWarehouseReceiptLine."Line No.");
                DeleteWhseRcptLine := TempWarehouseReceiptLine."Qty. Outstanding" = TempWarehouseReceiptLine."Qty. to Receive";
                OnBeforePostUpdateWhseRcptLine(WarehouseReceiptLine, TempWarehouseReceiptLine, DeleteWhseRcptLine, WarehouseReceiptHeader);
                if DeleteWhseRcptLine then
                    WarehouseReceiptLine.Delete()
                else
                    UpdateWhseRcptLine(WarehouseReceiptLine);
            until TempWarehouseReceiptLine.Next() = 0;
            OnPostUpdateWhseDocumentsOnBeforeDeleteAll(WarehouseReceiptHeader, TempWarehouseReceiptLine);
            TempWarehouseReceiptLine.DeleteAll();
        end;

        PostedWhseReceiptHeaderNo := WarehouseReceiptHeader."Receiving No.";
        if WarehouseReceiptHeader."Create Posted Header" then begin
            WarehouseReceiptHeader."Last Receiving No." := WarehouseReceiptHeader."Receiving No.";
            WarehouseReceiptHeader."Receiving No." := '';
            WarehouseReceiptHeader."Create Posted Header" := false;
        end;

        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        if not WarehouseReceiptLine.IsEmpty() then begin
            WarehouseReceiptHeader."Document Status" := WarehouseReceiptHeader.GetHeaderStatus(0);
            WarehouseReceiptHeader.Modify();
        end else begin
            IsHandled := false;
            OnPostUpdateWhseDocumentsOnBeforeWhseRcptHeaderDelete(WarehouseReceiptHeader, IsHandled);
            if not IsHandled then begin
                WarehouseReceiptHeader.DeleteRelatedLines(false);
                WarehouseReceiptHeader.Delete();
            end;
            OnPostUpdateWhseDocumentsOnAfterWhseRcptHeaderDelete(WarehouseReceiptHeader);
        end;

        if IsWarehousePutAwayIncomplete(PostedWhseReceiptHeaderNo) then begin
            OnPostUpdateWhseDocumentsOnBeforeGetLocation(WarehouseReceiptHeader);
            GetLocation(WarehouseReceiptHeader."Location Code");
            if Location."Require Put-away" then begin
                WhsePutAwayRequest."Document Type" := WhsePutAwayRequest."Document Type"::Receipt;
                WhsePutAwayRequest."Document No." := WarehouseReceiptHeader."Last Receiving No.";
                WhsePutAwayRequest."Location Code" := WarehouseReceiptHeader."Location Code";
                WhsePutAwayRequest."Zone Code" := WarehouseReceiptHeader."Zone Code";
                WhsePutAwayRequest."Bin Code" := WarehouseReceiptHeader."Bin Code";
                if WhsePutAwayRequest.Insert() then;
            end;
        end;

        OnAfterPostUpdateWhseDocuments(WarehouseReceiptHeader, WhsePutAwayRequest);
    end;

    local procedure IsWarehousePutAwayIncomplete(PostedWhseReceiptHeaderNo: Code[20]): Boolean
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        if PostedWhseReceiptHeaderNo = '' then
            exit(true);

        if not PostedWhseReceiptHeader.Get(PostedWhseReceiptHeaderNo) then
            exit(true);

        UpdateWarehousePutAwayStatus(PostedWhseReceiptHeader);

        exit(PostedWhseReceiptHeader."Document Status" <> PostedWhseReceiptHeader."Document Status"::"Completely Put Away");
    end;

    local procedure UpdateWarehousePutAwayStatus(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        xPostedWhseReceiptHeaderDocumentStatus: Option;
    begin
        xPostedWhseReceiptHeaderDocumentStatus := PostedWhseReceiptHeader."Document Status";
        PostedWhseReceiptHeader."Document Status" := PostedWhseReceiptHeader.GetHeaderStatus(0);
        if PostedWhseReceiptHeader."Document Status" <> xPostedWhseReceiptHeaderDocumentStatus then
            PostedWhseReceiptHeader.Modify(true);
    end;

    local procedure UpdateWhseRcptLine(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseRcptLine(WarehouseReceiptLine, TempWarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        WarehouseReceiptLine.Validate("Qty. Received", TempWarehouseReceiptLine."Qty. Received" + TempWarehouseReceiptLine."Qty. to Receive");
        WarehouseReceiptLine.Validate("Qty. Outstanding", TempWarehouseReceiptLine."Qty. Outstanding" - TempWarehouseReceiptLine."Qty. to Receive");
        WarehouseReceiptLine."Qty. to Cross-Dock" := 0;
        WarehouseReceiptLine."Qty. to Cross-Dock (Base)" := 0;
        WarehouseReceiptLine.Status := WarehouseReceiptLine.GetLineStatus();
        OnPostUpdateWhseDocumentsOnBeforeWhseRcptLineModify(WarehouseReceiptLine, TempWarehouseReceiptLine);
        WarehouseReceiptLine.Modify();
        OnAfterPostUpdateWhseRcptLine(WarehouseReceiptLine);
    end;

    procedure CreatePostedRcptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ReceivingNo2: Code[20]; PostingDate2: Date)
    var
        WarehouseCommentLine: Record "Warehouse Comment Line";
        PostedWarehouseCommentLine: Record "Warehouse Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        ReceivingNo := ReceivingNo2;
        PostingDate := PostingDate2;

        if not WarehouseReceiptHeader."Create Posted Header" then begin
            PostedWhseReceiptHeader.Get(WarehouseReceiptHeader."Last Receiving No.");
            exit;
        end;

        if WarehouseReceiptHeader."Receiving No." <> '' then
            if PostedWhseReceiptHeader.Get(WarehouseReceiptHeader."Receiving No.") then
                exit;

        PostedWhseReceiptHeader.Init();
        PostedWhseReceiptHeader.TransferFields(WarehouseReceiptHeader);
        PostedWhseReceiptHeader."No." := WarehouseReceiptHeader."Receiving No.";
        PostedWhseReceiptHeader."Whse. Receipt No." := WarehouseReceiptHeader."No.";
        PostedWhseReceiptHeader."No. Series" := WarehouseReceiptHeader."Receiving No. Series";

        GetLocation(PostedWhseReceiptHeader."Location Code");
        if not Location."Require Put-away" then
            PostedWhseReceiptHeader."Document Status" := PostedWhseReceiptHeader."Document Status"::"Completely Put Away";
        OnBeforePostedWhseRcptHeaderInsert(PostedWhseReceiptHeader, WarehouseReceiptHeader);
        PostedWhseReceiptHeader.Insert();
        RecordLinkManagement.CopyLinks(WarehouseReceiptHeader, PostedWhseReceiptHeader);
        OnAfterPostedWhseRcptHeaderInsert(PostedWhseReceiptHeader, WarehouseReceiptHeader);

        WarehouseCommentLine.SetRange("Table Name", WarehouseCommentLine."Table Name"::"Whse. Receipt");
        WarehouseCommentLine.SetRange(Type, WarehouseCommentLine.Type::" ");
        WarehouseCommentLine.SetRange("No.", WarehouseReceiptHeader."No.");
        if WarehouseCommentLine.Find('-') then
            repeat
                PostedWarehouseCommentLine.Init();
                PostedWarehouseCommentLine := WarehouseCommentLine;
                PostedWarehouseCommentLine."Table Name" := PostedWarehouseCommentLine."Table Name"::"Posted Whse. Receipt";
                PostedWarehouseCommentLine."No." := PostedWhseReceiptHeader."No.";
                PostedWarehouseCommentLine.Insert();
            until WarehouseCommentLine.Next() = 0;
    end;

    procedure CreatePostedRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var TempHandlingSpecification: Record "Tracking Specification")
    var
        SkipPutAwayProcessing, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostedRcptLine(WarehouseReceiptLine, PostedWhseReceiptHeader, PostedWhseReceiptLine, TempHandlingSpecification, IsHandled);
        if IsHandled then
            exit;

        UpdateWhseRcptLineBuf(WarehouseReceiptLine);
        PostedWhseReceiptLine.Init();
        PostedWhseReceiptLine.TransferFields(WarehouseReceiptLine);
        PostedWhseReceiptLine."No." := PostedWhseReceiptHeader."No.";
        OnAfterInitPostedRcptLine(WarehouseReceiptLine, PostedWhseReceiptLine);
        PostedWhseReceiptLine.Quantity := WarehouseReceiptLine."Qty. to Receive";
        PostedWhseReceiptLine."Qty. (Base)" := WarehouseReceiptLine."Qty. to Receive (Base)";
        OnCreatePostedRcptLineOnBeforeSetPostedSourceDocument(PostedWhseReceiptLine, WarehouseReceiptLine);
        case WarehouseReceiptLine."Source Document" of
            WarehouseReceiptLine."Source Document"::"Purchase Order":
                PostedWhseReceiptLine."Posted Source Document" := PostedWhseReceiptLine."Posted Source Document"::"Posted Receipt";
            WarehouseReceiptLine."Source Document"::"Sales Order":
                PostedWhseReceiptLine."Posted Source Document" := PostedWhseReceiptLine."Posted Source Document"::"Posted Shipment";
            WarehouseReceiptLine."Source Document"::"Purchase Return Order":
                PostedWhseReceiptLine."Posted Source Document" := PostedWhseReceiptLine."Posted Source Document"::"Posted Return Shipment";
            WarehouseReceiptLine."Source Document"::"Sales Return Order":
                PostedWhseReceiptLine."Posted Source Document" := PostedWhseReceiptLine."Posted Source Document"::"Posted Return Receipt";
            WarehouseReceiptLine."Source Document"::"Inbound Transfer":
                PostedWhseReceiptLine."Posted Source Document" := PostedWhseReceiptLine."Posted Source Document"::"Posted Transfer Receipt";
        end;

        GetLocation(PostedWhseReceiptLine."Location Code");
        SkipPutAwayProcessing := not Location."Require Put-away";
        if not SkipPutAwayProcessing then
            SkipPutAwayProcessing := IsReceiptForJob(PostedWhseReceiptLine);
        if SkipPutAwayProcessing then begin
            PostedWhseReceiptLine."Qty. Put Away" := PostedWhseReceiptLine.Quantity;
            PostedWhseReceiptLine."Qty. Put Away (Base)" := PostedWhseReceiptLine."Qty. (Base)";
            PostedWhseReceiptLine.Status := PostedWhseReceiptLine.Status::"Completely Put Away";
        end;
        PostedWhseReceiptLine."Posted Source No." := ReceivingNo;
        PostedWhseReceiptLine."Posting Date" := PostingDate;
        PostedWhseReceiptLine."Whse. Receipt No." := WarehouseReceiptLine."No.";
        PostedWhseReceiptLine."Whse Receipt Line No." := WarehouseReceiptLine."Line No.";
        OnBeforePostedWhseRcptLineInsert(PostedWhseReceiptLine, WarehouseReceiptLine);
        PostedWhseReceiptLine.Insert();
        OnAfterPostedWhseRcptLineInsert(PostedWhseReceiptLine, WarehouseReceiptLine);

        IsHandled := false;
        OnCreatePostedRcptLineOnBeforePostWhseJnlLine(WhseJnlRegisterLine, WarehouseReceiptLine, IsHandled, PostedWhseReceiptLine);
        if not IsHandled then
            PostWhseJnlLine(PostedWhseReceiptHeader, PostedWhseReceiptLine, TempHandlingSpecification);
    end;

    procedure UpdateWhseRcptLineBuf(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        TempWarehouseReceiptLine."No." := WarehouseReceiptLine."No.";
        TempWarehouseReceiptLine."Line No." := WarehouseReceiptLine."Line No.";
        if not TempWarehouseReceiptLine.Find() then begin
            TempWarehouseReceiptLine.Init();
            TempWarehouseReceiptLine := WarehouseReceiptLine;
            TempWarehouseReceiptLine.Insert();
        end;
    end;

    procedure PostWhseJnlLine(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(PostedWhseReceiptHeader, PostedWhseReceiptLine, WhseRcptLine, TempWhseSplitSpecification, IsHandled);
        if IsHandled then
            exit;

        GetLocation(PostedWhseReceiptLine."Location Code");
        InsertWhseItemEntryRelation(PostedWhseReceiptHeader, PostedWhseReceiptLine, TempWhseSplitSpecification);

        IsHandled := false;
        OnPostWhseJnlLineOnAfterInsertWhseItemEntryRelation(PostedWhseReceiptHeader, PostedWhseReceiptLine, TempWhseSplitSpecification, IsHandled, ReceivingNo, PostingDate, TempWhseJnlLine);
        if not IsHandled then
            if Location."Bin Mandatory" then begin
                InsertTempWhseJnlLine(PostedWhseReceiptLine);

                TempWhseJnlLine.Get('', '', PostedWhseReceiptLine."Location Code", PostedWhseReceiptLine."Line No.");
                TempWhseJnlLine."Line No." := 0;
                TempWhseJnlLine."Reference No." := ReceivingNo;
                TempWhseJnlLine."Registering Date" := PostingDate;
                TempWhseJnlLine."Whse. Document Type" := TempWhseJnlLine."Whse. Document Type"::Receipt;
                TempWhseJnlLine."Whse. Document No." := PostedWhseReceiptLine."No.";
                TempWhseJnlLine."Whse. Document Line No." := PostedWhseReceiptLine."Line No.";
                TempWhseJnlLine."Registering No. Series" := PostedWhseReceiptHeader."No. Series";
                OnBeforeRegisterWhseJnlLines(TempWhseJnlLine, PostedWhseReceiptHeader, PostedWhseReceiptLine);

                ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseSplitSpecification, false);
                if TempWhseJnlLine2.Find('-') then
                    repeat
                        OnPostWhseJnlLineOnBeforeWhseJnlRegisterLineRun(TempWhseJnlLine2, PostedWhseReceiptHeader);
                        WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                        if ConsumeWarehouseEntryForJobPurchase(TempWhseJnlLine2, PostedWhseReceiptLine) then
                            WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next() = 0;
            end;

        OnAfterPostWhseJnlLine(WhseRcptLine);
    end;

    local procedure InsertWhseItemEntryRelation(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary)
    var
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        IsHandled: Boolean;
    begin
        if ItemEntryRelationCreated then begin
            if TempWhseItemEntryRelation.Find('-') then begin
                repeat
                    WhseItemEntryRelation := TempWhseItemEntryRelation;
                    WhseItemEntryRelation.SetSource(
                      Database::"Posted Whse. Receipt Line", 0, PostedWhseReceiptHeader."No.", PostedWhseReceiptLine."Line No.");
                    IsHandled := false;
                    OnInsertWhseItemEntryRelationOnBeforeInsertFromTempWhseItemEntryRelation(WhseItemEntryRelation, IsHandled);
                    if not IsHandled then
                        WhseItemEntryRelation.Insert();
                until TempWhseItemEntryRelation.Next() = 0;
                ItemEntryRelationCreated := false;
            end;
            exit;
        end;
        TempWhseSplitSpecification.Reset();
        if TempWhseSplitSpecification.Find('-') then
            repeat
                WhseItemEntryRelation.InitFromTrackingSpec(TempWhseSplitSpecification);
                WhseItemEntryRelation.SetSource(
                  Database::"Posted Whse. Receipt Line", 0, PostedWhseReceiptHeader."No.", PostedWhseReceiptLine."Line No.");
                IsHandled := false;
                OnInsertWhseItemEntryRelationOnBeforeInsertFromTempWhseSplitSpecification(WhseItemEntryRelation, TempWhseSplitSpecification, IsHandled);
                if not IsHandled then
                    WhseItemEntryRelation.Insert();
            until TempWhseSplitSpecification.Next() = 0;
    end;

    local procedure ConsumeWarehouseEntryForJobPurchase(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line") Result: Boolean
    var
        Bin: Record Bin;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConsumeWarehouseEntryForJobPurchase(TempWarehouseJournalLine, PostedWhseReceiptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PostedWhseReceiptLine."Source Document" <> PostedWhseReceiptLine."Source Document"::"Purchase Order" then
            exit(false);

        if not IsReceiptForJob(PostedWhseReceiptLine) then
            exit(false);

        case TempWarehouseJournalLine."Entry Type" of
            TempWarehouseJournalLine."Entry Type"::"Positive Adjmt.":
                begin
                    TempWarehouseJournalLine."Entry Type" := TempWarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                    TempWarehouseJournalLine."From Bin Code" := TempWarehouseJournalLine."To Bin Code";
                    Bin.SetLoadFields("Zone Code", "Bin Type Code");
                    Bin.Get(TempWarehouseJournalLine."Location Code", TempWarehouseJournalLine."From Bin Code");
                    TempWarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                    TempWarehouseJournalLine."From Bin Type Code" := Bin."Bin Type Code";

                    TempWarehouseJournalLine."To Bin Code" := '';
                    TempWarehouseJournalLine."To Zone Code" := '';
                end;
            TempWarehouseJournalLine."Entry Type"::"Negative Adjmt.":
                begin
                    TempWarehouseJournalLine."Entry Type" := TempWarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                    TempWarehouseJournalLine."To Bin Code" := TempWarehouseJournalLine."From Bin Code";
                    Bin.SetLoadFields("Zone Code");
                    Bin.Get(TempWarehouseJournalLine."Location Code", TempWarehouseJournalLine."From Bin Code");
                    TempWarehouseJournalLine."To Zone Code" := Bin."Zone Code";

                    TempWarehouseJournalLine."From Bin Code" := '';
                    TempWarehouseJournalLine."From Zone Code" := '';
                    TempWarehouseJournalLine."From Bin Type Code" := '';
                end;
        end;
        TempWarehouseJournalLine.Quantity := -TempWarehouseJournalLine.Quantity;
        TempWarehouseJournalLine."Qty. (Base)" := -TempWarehouseJournalLine."Qty. (Base)";

        exit(true);
    end;

    procedure GetFirstPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header") Result: Boolean
    var
        IsHandled: boolean;
    begin
        IsHandled := false;
        OnBeforeGetFirstPutAwayDocument(WhseActivHeader, Result, IsHandled, WhseRcptHeader);
        if IsHandled then
            exit(Result);

        exit(CreatePutAway.GetFirstPutAwayDocument(WhseActivHeader));
    end;

    procedure GetNextPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextPutAwayDocument(WhseRcptHeader, WhseActivHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(CreatePutAway.GetNextPutAwayDocument(WhseActivHeader));
    end;

    procedure InsertTempWhseJnlLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        BaseUnitOfMeasureCode: Code[10];
    begin
        TempWhseJnlLine.Init();
        TempWhseJnlLine."Entry Type" := TempWhseJnlLine."Entry Type"::"Positive Adjmt.";
        TempWhseJnlLine."Line No." := PostedWhseReceiptLine."Line No.";
        TempWhseJnlLine."Location Code" := PostedWhseReceiptLine."Location Code";
        TempWhseJnlLine."To Zone Code" := PostedWhseReceiptLine."Zone Code";
        TempWhseJnlLine."To Bin Code" := PostedWhseReceiptLine."Bin Code";
        TempWhseJnlLine."Item No." := PostedWhseReceiptLine."Item No.";
        TempWhseJnlLine.Description := PostedWhseReceiptLine.Description;
        GetLocation(PostedWhseReceiptLine."Location Code");
        if Location."Directed Put-away and Pick" then begin
            TempWhseJnlLine."Qty. (Absolute)" := PostedWhseReceiptLine.Quantity;
            TempWhseJnlLine."Unit of Measure Code" := PostedWhseReceiptLine."Unit of Measure Code";
            TempWhseJnlLine."Qty. per Unit of Measure" := PostedWhseReceiptLine."Qty. per Unit of Measure";
            GetItemUnitOfMeasure2(PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Unit of Measure Code");
            TempWhseJnlLine.Cubage := Abs(TempWhseJnlLine."Qty. (Absolute)") * ItemUnitOfMeasure.Cubage;
            TempWhseJnlLine.Weight := Abs(TempWhseJnlLine."Qty. (Absolute)") * ItemUnitOfMeasure.Weight;
        end else begin
            TempWhseJnlLine."Qty. (Absolute)" := PostedWhseReceiptLine."Qty. (Base)";
            BaseUnitOfMeasureCode := WMSMgt.GetBaseUOM(PostedWhseReceiptLine."Item No.");
            TempWhseJnlLine."Unit of Measure Code" := BaseUnitOfMeasureCode;
            TempWhseJnlLine."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Get(PostedWhseReceiptLine."Item No.", BaseUnitOfMeasureCode);
            TempWhseJnlLine.Cubage := Abs(TempWhseJnlLine."Qty. (Absolute)") * ItemUnitOfMeasure.Cubage;
            TempWhseJnlLine.Weight := Abs(TempWhseJnlLine."Qty. (Absolute)") * ItemUnitOfMeasure.Weight;
        end;

        TempWhseJnlLine."Qty. (Absolute, Base)" := PostedWhseReceiptLine."Qty. (Base)";
        TempWhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(TempWhseJnlLine."User ID"));
        TempWhseJnlLine."Variant Code" := PostedWhseReceiptLine."Variant Code";
        TempWhseJnlLine.SetSource(PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype", PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.", 0);
        TempWhseJnlLine."Source Document" := PostedWhseReceiptLine."Source Document";
        SourceCodeSetup.Get();
        case PostedWhseReceiptLine."Source Document" of
            PostedWhseReceiptLine."Source Document"::"Purchase Order":
                begin
                    TempWhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rcpt.";
                end;
            PostedWhseReceiptLine."Source Document"::"Sales Order":
                begin
                    TempWhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Shipment";
                end;
            PostedWhseReceiptLine."Source Document"::"Purchase Return Order":
                begin
                    TempWhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                end;
            PostedWhseReceiptLine."Source Document"::"Sales Return Order":
                begin
                    TempWhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                end;
            PostedWhseReceiptLine."Source Document"::"Inbound Transfer":
                begin
                    TempWhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted T. Receipt";
                end;
        end;

        OnBeforeInsertTempWhseJnlLine(TempWhseJnlLine, PostedWhseReceiptLine);

        CheckWhseItemTrackingSetupSNRequired(TempWhseJnlLine, PostedWhseReceiptLine);

        CheckWhseJnlLine(TempWhseJnlLine);
        TempWhseJnlLine.Insert();
    end;

    local procedure CheckWhseItemTrackingSetupSNRequired(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseItemTrackingSetupSNRequired(TempWarehouseJournalLine, PostedWhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingMgt.GetWhseItemTrkgSetup(PostedWhseReceiptLine."Item No.", WhseItemTrackingSetup);
    end;

    local procedure CheckWhseJnlLine(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLine(TempWarehouseJournalLine, IsHandled, WMSMgt);
        if IsHandled then
            exit;

        WMSMgt.CheckWhseJnlLine(TempWarehouseJournalLine, 0, 0, false);
    end;

    local procedure CreatePutAwayDoc(WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TempPostedWhseReceiptLine: Record "Posted Whse. Receipt Line" temporary;
        TempPostedWhseReceiptLine2: Record "Posted Whse. Receipt Line" temporary;
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        RemQtyToHandleBase: Decimal;
        IsHandled: Boolean;
        DoCheckIsReceiptForJob, ReceiptIsForJob : Boolean;
    begin
        DoCheckIsReceiptForJob := true;
        OnBeforeCreatePutAwayDocProcedure(PostedWhseReceiptLine, WarehouseReceiptHeader, RemQtyToHandleBase, CreatePutAway, ItemTrackingManagement, TempPostedWhseReceiptLine, TempPostedWhseReceiptLine2, WarehouseActivityHeader, CounterPutAways, DoCheckIsReceiptForJob);

        PostedWhseReceiptLine.SetRange("No.", WarehouseReceiptHeader."Receiving No.");
        if not PostedWhseReceiptLine.Find('-') then
            exit;

        repeat
            if DoCheckIsReceiptForJob then
                ReceiptIsForJob := IsReceiptForJob(PostedWhseReceiptLine)
            else
                ReceiptIsForJob := false;

            if not ReceiptIsForJob then begin
                RemQtyToHandleBase := PostedWhseReceiptLine."Qty. (Base)";
                IsHandled := false;
                OnBeforeCreatePutAwayDoc(WarehouseReceiptHeader, PostedWhseReceiptLine, IsHandled);
                if not IsHandled then begin
                    CreatePutAway.SetValues('', Enum::"Whse. Activity Sorting Method"::None, false, false);
                    CreatePutAway.SetCrossDockValues(true);

                    OnCreatePutAwayDocOnBeforeItemTrackingMgtGetWhseItemTrkgSetup(ItemTrackingManagement);
                    if ItemTrackingManagement.GetWhseItemTrkgSetup(PostedWhseReceiptLine."Item No.") then
                        ItemTrackingManagement.InitItemTrackingForTempWhseWorksheetLine(
                              Enum::"Warehouse Worksheet Document Type"::Receipt,
                              PostedWhseReceiptLine."No.", PostedWhseReceiptLine."Line No.",
                              PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype",
                              PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.", 0);

                    ItemTrackingManagement.SplitPostedWhseRcptLine(PostedWhseReceiptLine, TempPostedWhseReceiptLine);

                    TempPostedWhseReceiptLine.Reset();
                    if TempPostedWhseReceiptLine.Find('-') then
                        repeat
                            TempPostedWhseReceiptLine2 := TempPostedWhseReceiptLine;
                            TempPostedWhseReceiptLine2."Line No." := PostedWhseReceiptLine."Line No.";
                            WhseSourceCreateDocument.SetQuantity(TempPostedWhseReceiptLine2, Database::"Posted Whse. Receipt Line", RemQtyToHandleBase);
                            IsHandled := false;
                            OnCreatePutAwayDocOnBeforeCreatePutAwayRun(TempPostedWhseReceiptLine2, CreatePutAway, WarehouseReceiptHeader, IsHandled);
                            if not IsHandled then
                                CreatePutAway.Run(TempPostedWhseReceiptLine2);
                        until TempPostedWhseReceiptLine.Next() = 0;
                end;
            end;
        until PostedWhseReceiptLine.Next() = 0;

        if GetFirstPutAwayDocument(WarehouseActivityHeader) then
            repeat
                CreatePutAway.DeleteBlankBinContent(WarehouseActivityHeader);
                OnAfterCreatePutAwayDeleteBlankBinContent(WarehouseActivityHeader);
                CounterPutAways := CounterPutAways + 1;
            until not GetNextPutAwayDocument(WarehouseActivityHeader);

        OnAfterCreatePutAwayDoc(WarehouseReceiptHeader, CounterPutAways, WarehouseActivityHeader);
    end;

    internal procedure IsReceiptForJob(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
        IsForJob: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsReceiptForJob(PostedWhseReceiptLine, IsForJob, IsHandled);
        if IsHandled then
            exit(IsForJob);

        PurchaseLine.SetLoadFields("Job No.");
        if not PurchaseLine.Get(PostedWhseReceiptLine."Source Subtype", PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.") then
            exit(false);

        exit(PurchaseLine."Job No." <> '');
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if not Location.Get(LocationCode) then;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetItemUnitOfMeasure2(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    procedure SetItemEntryRelation(PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var ItemEntryRelation: Record "Item Entry Relation")
    begin
        if ItemEntryRelation.Find('-') then begin
            TempWhseItemEntryRelation.DeleteAll();
            repeat
                TempWhseItemEntryRelation.Init();
                TempWhseItemEntryRelation.TransferFields(ItemEntryRelation);
                TempWhseItemEntryRelation.SetSource(
                  Database::"Posted Whse. Receipt Line", 0, PostedWhseReceiptHeader."No.", PostedWhseReceiptLine."Line No.");
                TempWhseItemEntryRelation.Insert();
            until ItemEntryRelation.Next() = 0;
            ItemEntryRelationCreated := true;
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure GetCounterSourceDocTotal(): Integer;
    begin
        exit(CounterSourceDocTotal);
    end;

    procedure GetCounterSourceDocOK(): Integer;
    begin
        exit(CounterSourceDocOK);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentHeader(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSourceDocumentHeader(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var SuppressCommit: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayDocProcedure(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var RemQtyToHandleBase: Decimal; var CreatePutAway: Codeunit "Create Put-away"; var ItemTrackingManagement: Codeunit "Item Tracking Management"; var TempPostedWhseReceiptLine: Record "Posted Whse. Receipt Line" temporary; var TempPostedWhseReceiptLine2: Record "Posted Whse. Receipt Line" temporary; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var CounterPutAways: Integer; var DoCheckIsReceiptForJob: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetResultMessage(CounterPutAways: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; CounterSourceDocTotal: Integer; CounterSourceDocOK: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearPurchLineQtyToShipReceive(var PurchaseLine: Record "Purchase Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearSalesLineQtyToShipReceive(var SalesLine: Record "Sales Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var CounterPutAways: Integer; var WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayDeleteBlankBinContent(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseRcptLineForPurchLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseRcptLineForSalesLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseRcptLineForTransLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhsePutAwayRequest: Record "Whse. Put-away Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceDocument(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptLineBuf: Record "Warehouse Receipt Line"; var DeleteWhseRcptLine: Boolean; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseReceiptLine: Record "Warehouse Receipt Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseJnlLines(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseRqstDocumentStatus(WhseRqst: Record "Warehouse Request"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SalesHeader: Record "Sales Header"; PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceiveOnTransferLine(var TransferLine: Record "Transfer Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnQtyToReceiveOnSalesLine(var SalesLine: Record "Sales Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUnitOfMeasureCode(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostSourceDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldCreatePutAway(WhseRcptHeader: Record "Warehouse Receipt Header"; Location: Record Location; PutAwayRequired: Boolean; SuppressCommit: Boolean; HideValidationDialog: Boolean; var ShouldCreatePutAway: Boolean; var CounterPutAways: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSetPutAwayRequired(WhseRcptHeader: Record "Warehouse Receipt Header"; var PutAwayRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterWhseRcptHeaderModify(WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGetWhseRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceDocument(SourceHeader: Variant; WhseRcptLine: Record "Warehouse Receipt Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseRcptLineInsert(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRcptLines(var WhseRcptHeader: Record "Warehouse Receipt Header"; var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseRcptHeaderInsert(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseItemTrackingSetupSNRequired(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateSalesLineBinCode(var SalesLine: Record "Sales Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearSalesLineQtyToShipReceive(var SalesLine: Record "Sales Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearPurchLineQtyToShipReceive(var PurchLine: Record "Purchase Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean; var WMSMgt: Codeunit "WMS Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempHandlingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFirstPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"; var Result: Boolean; var IsHandled: Boolean; var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextPutAwayDocument(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseActivHeader: Record "Warehouse Activity Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSourceDocumentLines(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempWhseJnlLine(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPurchErrorsNotProcessed(var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSalesErrorsNotProcessed(var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostTransferErrorsNotProcessed(var TransferPostReceipt: Codeunit "TransferOrder-Post Receipt"; var TransHeader: Record "Transfer Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceTransferDocument(var TransferPostReceipt: Codeunit "TransferOrder-Post Receipt"; var TransHeader: Record "Transfer Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WhseRcptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; TransferHeader: Record "Transfer Header"; var CounterSourceDocOK: Integer; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseDocuments(var WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptHeaderInsert(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptLineInsert(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptLineBuf: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWhseRcptHeaderModify(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedRcptLineOnBeforePostWhseJnlLine(var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedRcptLineOnBeforeSetPostedSourceDocument(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayDocOnBeforeCreatePutAwayRun(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var CreatePutAway: Codeunit "Create Put-away"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayDocOnBeforeItemTrackingMgtGetWhseItemTrkgSetup(var ItemTrackingMgt: Codeunit "Item Tracking Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnAfterPurchHeaderModify(var PurchaseHeader: Record "Purchase Header"; WhseReceiptLine: Record "Warehouse Receipt Line"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforePurchHeaderInit(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchHeaderReopen(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnAfterSalesHeaderModify(var SalesHeader: Record "Sales Header"; WhseReceiptLine: Record "Warehouse Receipt Line"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforeSalesHeaderInit(var SalesHeader: Record "Sales Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnAfterTransHeaderModify(var TransferHeader: Record "Transfer Header"; WhseReceiptLine: Record "Warehouse Receipt Line"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforeTransferHeaderInit(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLines(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSourceSalesLineFound(var SalesLine: Record "Sales Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; WhseRcptHeader: Record "Warehouse Receipt Header"; OldWhseRcptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSourcePurchLineFound(var PurchaseLine: Record "Purchase Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterModifySalesLines(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterPurchLineModify(var PurchaseLine: Record "Purchase Line"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterModifyPurchLines(PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSourceTransLineFound(var TransferLine: Record "Transfer Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterClearTransLineQtyToReceive(var TransferLine: Record "Transfer Line"; var WhseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseItemEntryRelationOnBeforeInsertFromTempWhseItemEntryRelation(var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseItemEntryRelationOnBeforeInsertFromTempWhseSplitSpecification(var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocument(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseReceiptLine: Record "Warehouse Receipt Line"; var CounterSourceDocOK: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterPostPurchaseHeader(PurchaseHeader: record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterPostSalesHeader(SalesHeader: record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeGetLocation(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeDeleteAll(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeWhseRcptLineModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WhseRcptLineBuf: Record "Warehouse Receipt Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeWhseRcptHeaderDelete(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnAfterWhseRcptHeaderDelete(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnAfterInsertWhseItemEntryRelation(var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean; ReceivingNo: code[20]; PostingDate: date; var TempWhseJnlLine: record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeWhseJnlRegisterLineRun(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseRcptLineSetFilters(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResultMessageOnBeforeMessage(var CounterPutAways: Integer; var MessageText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocumentOnElseCase(var SourceHeader: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostPurchaseHeader(var PurchHeader: Record "Purchase Header"; WhseRcptHeader: Record "Warehouse Receipt Header"; SuppressCommit: Boolean; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnBeforeProcessPurchLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostSalesHeader(var SalesHeader: Record "Sales Header"; WhseRcptHeader: Record "Warehouse Receipt Header"; SuppressCommit: Boolean; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(WhseRcptLine: Record "Warehouse Receipt Line"; var SuppressCommit: Boolean; CounterSourceDocOK: Integer; CounterSourceDocTotal: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnBeforeProcessSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostTransferHeader(var TransferHeader: Record "Transfer Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SuppressCommit: Boolean; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterPostTransferHeader(TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterGetWhseRcptHeader(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseSetup: Record "Warehouse Setup"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeRunPurchRelease(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterRemoveSourceFilterFromWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAttachedLine(var SalesLine: Record "Sales Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAttachedLineOnBeforeModifyLine(var SalesLine: Record "Sales Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean; var QtyToHandle: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConsumeWarehouseEntryForJobPurchase(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsReceiptForJob(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsReceiptForJob: Boolean; var IsHandled: Boolean)
    begin
    end;
}
