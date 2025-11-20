// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
#if not CLEAN27
using Microsoft.Inventory.Journal;
#endif
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Telemetry;
using System.Utilities;

codeunit 7324 "Whse.-Activity-Post"
{
    Permissions = TableData "Warehouse Setup" = rm,
                  TableData "Warehouse Journal Batch" = rimd,
                  TableData "Posted Invt. Put-away Header" = ri,
                  TableData "Posted Invt. Put-away Line" = ri,
                  TableData "Posted Invt. Pick Header" = ri,
                  TableData "Posted Invt. Pick Line" = ri;
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        Code();
        Rec := WhseActivLine;

        OnAfterOnRun(Rec);
    end;

    var
        Location: Record Location;
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        TempWarehouseActivityLineForItemTrackingChecking: Record "Warehouse Activity Line" temporary;
        WhseSetup: Record "Warehouse Setup";
        WhseRequest: Record "Warehouse Request";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        SourceCodeSetup: Record "Source Code Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        PurchPostPrint: Codeunit "Purch.-Post + Print";
        SalesPostPrint: Codeunit "Sales-Post + Print";
        Window: Dialog;
        PostedSourceNo: Code[20];
        PostedSourceType: Integer;
        PostedSourceSubType: Integer;
        NoOfRecords: Integer;
        LineCount: Integer;
        PostingReference: Integer;
        HideDialog: Boolean;
        InvoiceSourceDoc: Boolean;
        PrintDoc: Boolean;
        SuppressCommit: Boolean;
        IsPreview: Boolean;
        PostingDateErr: Label 'is before the posting date';
        InventoryNotAvailableErr: Label '%1 %2 is not available on inventory or it has already been reserved for another document.', Comment = '%1 = Item Tracking ID, %2 = Item Tracking No."';
#pragma warning disable AA0074, AA0470
        Text005: Label 'The source document %1 %2 is not released.';
        Text000: Label 'Warehouse Activity    #1##########\\';
        Text001: Label 'Checking lines        #2######\';
        Text002: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0074, AA0470

    local procedure "Code"()
    var
        TransferOrderPostPrint: Codeunit "TransferOrder-Post + Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ItemTrackingRequired: Boolean;
        Selection: Option " ",Shipment,Receipt;
        ForceDelete: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseActivLine, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        GetPostingReference();

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        WhseActivLine.SetFilter("Qty. to Handle", '<>0');
        if not WhseActivLine.Find('-') then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        WhseActivHeader.Get(WhseActivLine."Activity Type", WhseActivLine."No.");
        GetLocation(WhseActivHeader."Location Code");

        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then
            WhseRequest.Get(
              WhseRequest.Type::Inbound, WhseActivHeader."Location Code",
              WhseActivHeader."Source Type", WhseActivHeader."Source Subtype", WhseActivHeader."Source No.")
        else
            WhseRequest.Get(
              WhseRequest.Type::Outbound, WhseActivHeader."Location Code",
              WhseActivHeader."Source Type", WhseActivHeader."Source Subtype", WhseActivHeader."Source No.");
        if WhseRequest."Document Status" <> WhseRequest."Document Status"::Released then
            Error(Text005, WhseActivHeader."Source Document", WhseActivHeader."Source No.");

        if not HideDialog then begin
            Window.Open(
              Text000 +
              Text001 +
              Text002);
            Window.Update(1, WhseActivHeader."No.");
        end;
        // Check Lines
        OnBeforeCheckLines(WhseActivHeader);

        CheckQuantityInBinContentForTracking(WhseActivLine);

        LineCount := 0;
        if WhseActivLine.Find('-') then begin
            TempWhseActivLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
            repeat
                LineCount := LineCount + 1;
                if not HideDialog then
                    Window.Update(2, LineCount);

                CheckWarehouseActivityLine(WhseActivLine, WhseActivHeader, Location);

                ItemTrackingRequired := CheckItemTracking(WhseActivLine);
                if ItemTrackingRequired then
                    CheckAvailability(WhseActivLine);
                InsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);
                InsertTempWhseActivLineForChecking(WhseActivLine, ItemTrackingRequired);
            until WhseActivLine.Next() = 0;
            CheckWhseItemTrackingAgainstSource();
            TempWarehouseActivityLineForItemTrackingChecking.DeleteAll();
        end;
        NoOfRecords := LineCount;
        // Posting lines
        SourceCodeSetup.Get();
        LineCount := 0;
        WhseActivLine.LockTable();
        if WhseActivLine.Find('-') then begin
            LockPostedTables(WhseActivHeader);

            PostWhseActivityLine(WhseActivHeader, WhseActivLine);

            OnCodeOnAfterCreatePostedWhseActivDocument(WhseActivHeader);
        end;

        if IsPreview then
            GenJnlPostPreview.ThrowError();
        // Modify/delete activity header and activity lines
        TempWhseActivLine.DeleteAll();

        WhseActivLine.SetCurrentKey(
          "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");
        if WhseActivLine.Find('-') then
            repeat
                ForceDelete := false;
                OnBeforeWhseActivLineDelete(WhseActivLine, ForceDelete, HideDialog);
                if (WhseActivLine."Qty. Outstanding" = WhseActivLine."Qty. to Handle") or ForceDelete then
                    WhseActivLine.Delete()
                else begin
                    WhseActivLine.Validate(
                      "Qty. Outstanding", WhseActivLine."Qty. Outstanding" - WhseActivLine."Qty. to Handle");
                    if HideDialog then
                        WhseActivLine.Validate("Qty. to Handle", 0);
                    WhseActivLine.Validate(
                      "Qty. Handled", WhseActivLine.Quantity - WhseActivLine."Qty. Outstanding");
                    WhseActivLine.Modify();
                    OnAfterWhseActivLineModify(WhseActivLine);
                end;
            until WhseActivLine.Next() = 0;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
        WhseActivLine.SetRange("No.", WhseActivHeader."No.");
        WhseActivLine.SetFilter("Qty. Outstanding", '<>%1', 0);
        IsHandled := false;
        OnCodeOnAfterWhseActivLineSetFilters(WhseActivHeader, WhseActivLine, IsHandled);
        if not IsHandled then
            if not WhseActivLine.Find('-') then
                WhseActivHeader.Delete(true);

        if not HideDialog then
            Window.Close();

        if PrintDoc then
            case WhseActivHeader."Source Document" of
                WhseActivHeader."Source Document"::"Purchase Order",
              WhseActivHeader."Source Document"::"Purchase Return Order":
                    PurchPostPrint.GetReport(PurchHeader);
                WhseActivHeader."Source Document"::"Sales Order",
              WhseActivHeader."Source Document"::"Sales Return Order":
                    SalesPostPrint.GetReport(SalesHeader);
                WhseActivHeader."Source Document"::"Inbound Transfer":
                    if PostedSourceType <> Database::"Direct Trans. Header" then
                        TransferOrderPostPrint.PrintReport(TransHeader, Selection::Receipt)
                    else
                        if PostedSourceNo <> '' then
                            TransferOrderPostPrint.PrintDirectTransfer(PostedSourceNo);
                WhseActivHeader."Source Document"::"Outbound Transfer":
                    if PostedSourceType <> Database::"Direct Trans. Header" then
                        TransferOrderPostPrint.PrintReport(TransHeader, Selection::Shipment)
                    else
                        if PostedSourceNo <> '' then
                            TransferOrderPostPrint.PrintDirectTransfer(PostedSourceNo);
            end;

        OnAfterCode(WhseActivLine, SuppressCommit, PrintDoc);
        if not SuppressCommit then
            Commit();
        OnAfterPostWhseActivHeader(WhseActivHeader, PurchHeader, SalesHeader, TransHeader);

        Clear(WhseJnlRegisterLine);
    end;

    local procedure CheckQuantityInBinContentForTracking(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Item: Record Item;
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        WMSMgt: Codeunit "WMS Management";
    begin
        if not (Location."Require Pick" and Location."Require Receive") then
            exit;

        Item.SetLoadFields("Order Tracking Policy");
        Item.Get(WarehouseActivityLine."Item No.");
        if (Item."Order Tracking Policy" = Item."Order Tracking Policy"::None) then
            exit;

        WarehouseActivityLine2.CopyFilters(WarehouseActivityLine);
        WarehouseActivityLine2.SetFilter("Activity Type", '%1|%2', WarehouseActivityLine2."Activity Type"::"Invt. Pick", WarehouseActivityLine2."Activity Type"::"Invt. Put-away");
        if WarehouseActivityLine2.FindSet() then
            repeat
                if CheckItemTracking(WarehouseActivityLine2) then begin
                    CreateWhseJnlLine(TempWhseJnlLine, WarehouseActivityLine2);
                    if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then
                        WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 4, TempWhseJnlLine."Qty. (Base)", false); // 4 = Whse. Journal
                end;
            until WarehouseActivityLine2.Next() = 0;
    end;

    local procedure CheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
        WarehouseActivityLine.TestField("Item No.");
        if Location."Bin Mandatory" then begin
            WarehouseActivityLine.TestField("Unit of Measure Code");
            WarehouseActivityLine.TestField("Bin Code");
            if WarehouseActivityLine."Activity Type" in [WarehouseActivityLine."Activity Type"::"Invt. Movement", WarehouseActivityLine."Activity Type"::"Invt. Put-away", WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Activity Type"::"Put-away"] then
                WarehouseActivityLine.CheckIncreaseCapacity(false, true);
        end;

        OnAfterCheckWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, Location);
    end;

    local procedure InsertTempWhseActivLine(WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
        OnBeforeInsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);

        TempWhseActivLine.SetSourceFilter(
            WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", false);
        if WhseActivLine."Source Document" = WhseActivLine."Source Document"::"Job Usage" then
            TempWhseActivLine.SetRange("Bin Code", WhseActivLine."Bin Code");
        // Split the lines based on bin for jobs.
        if TempWhseActivLine.Find('-') then begin
            TempWhseActivLine."Qty. to Handle" += WhseActivLine."Qty. to Handle";
            TempWhseActivLine."Qty. to Handle (Base)" += WhseActivLine."Qty. to Handle (Base)";
            OnBeforeTempWhseActivLineModify(TempWhseActivLine, WhseActivLine);
            TempWhseActivLine.Modify();
        end else begin
            TempWhseActivLine.Init();
            TempWhseActivLine := WhseActivLine;
            OnBeforeTempWhseActivLineInsert(TempWhseActivLine, WhseActivLine);
            TempWhseActivLine.Insert();
            if ItemTrackingRequired and
               (WhseActivLine."Activity Type" in [WhseActivLine."Activity Type"::"Invt. Pick", WhseActivLine."Activity Type"::"Invt. Put-away"])
            then
                ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WhseActivLine, IsPreview);
        end;
    end;

    local procedure InsertTempWhseActivLineForChecking(WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
        TempWarehouseActivityLineForItemTrackingChecking.SetSourceFilter(
            WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", false);

        if TempWarehouseActivityLineForItemTrackingChecking.Find('-') then begin
            TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle" += WhseActivLine."Qty. to Handle";
            TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)" += WhseActivLine."Qty. to Handle (Base)";
            TempWarehouseActivityLineForItemTrackingChecking.Modify();
        end else begin
            TempWarehouseActivityLineForItemTrackingChecking.Init();
            TempWarehouseActivityLineForItemTrackingChecking := WhseActivLine;

            TempWarehouseActivityLineForItemTrackingChecking.Insert();
            if ItemTrackingRequired and
               (WhseActivLine."Activity Type" in [WhseActivLine."Activity Type"::"Invt. Pick", WhseActivLine."Activity Type"::"Invt. Put-away"])
            then
                ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WhseActivLine, IsPreview);
        end;
    end;

    local procedure GetPostingReference()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPostingReference(PostingReference, IsHandled);
        if IsHandled then
            exit;

        PostingReference := WhseSetup.GetNextReference();
    end;

    local procedure InitSourceDocument()
    var
        SalesLine: Record "Sales Line";
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeInitSourceDocument(WhseActivHeader);

        case WhseActivHeader."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchHeader.Get(WhseActivHeader."Source Subtype", WhseActivHeader."Source No.");
                    PurchLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    PurchLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    OnInitSourceDocumentOnAfterSetPurchaseLineFilters(PurchLine, PurchHeader, WhseActivHeader);
                    if PurchLine.Find('-') then
                        repeat
                            IsHandled := false;
                            OnInitSourceDocumentOnBeforePurchLineLoopIteration(PurchHeader, PurchLine, WhseActivHeader, IsHandled);
                            if not IsHandled then begin
                                if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Purchase Order" then
                                    PurchLine.Validate("Qty. to Receive", 0)
                                else
                                    PurchLine.Validate("Return Qty. to Ship", 0);
                                PurchLine.Validate("Qty. to Invoice", 0);
                                ModifyPurchaseLine(PurchLine);
                                OnAfterPurchLineModify(PurchLine);
                            end;
                        until PurchLine.Next() = 0;

                    ReleasePurchDocument(ModifyHeader);

                    if WhseActivHeader."External Document No." <> '' then begin
                        PurchHeader."Vendor Shipment No." := WhseActivHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if WhseActivHeader."External Document No.2" <> '' then begin
                        if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Purchase Order" then
                            PurchHeader."Vendor Invoice No." := WhseActivHeader."External Document No.2"
                        else
                            PurchHeader."Vendor Cr. Memo No." := WhseActivHeader."External Document No.2";
                        ModifyHeader := true;
                    end;
                    ModifyPurchaseHeader(PurchHeader, WhseActivHeader, ModifyHeader);
                end;
            Database::"Sales Line":
                begin
                    SalesHeader.Get(WhseActivHeader."Source Subtype", WhseActivHeader."Source No.");
                    SalesLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    SalesLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then
                        SalesLine.SetRange(Type, SalesLine.Type::Item);
                    OnInitSourceDocumentOnAfterSetSalesLineFilters(SalesLine, SalesHeader, WhseActivHeader);
                    if SalesLine.Find('-') then
                        repeat
                            IsHandled := false;
                            OnInitSourceDocumentOnBeforeSalesLineLoopIteration(SalesHeader, SalesLine, WhseActivHeader, IsHandled);
                            if not IsHandled then begin
                                if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Sales Order" then
                                    SalesLine.Validate("Qty. to Ship", 0)
                                else
                                    SalesLine.Validate("Return Qty. to Receive", 0);
                                SalesLine.Validate("Qty. to Invoice", 0);
                                ModifySalesLine(SalesLine);
                                OnAfterSalesLineModify(SalesLine);
                            end;
                        until SalesLine.Next() = 0;

                    ReleaseSalesDocument(ModifyHeader);

                    if WhseActivHeader."External Document No." <> '' then begin
                        SalesHeader."External Document No." := WhseActivHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    ModifySalesHeader(SalesHeader, WhseActivHeader, ModifyHeader);
                end;
            Database::"Transfer Line":
                begin
                    TransHeader.Get(WhseActivHeader."Source No.");
                    TransLine.SetRange("Document No.", TransHeader."No.");
                    TransLine.SetRange("Derived From Line No.", 0);
                    TransLine.SetFilter("Item No.", '<>%1', '');
                    OnInitSourceDocumentOnAfterTransLineSetFilters(TransLine, TransHeader, WhseActivHeader);
                    if TransLine.Find('-') then
                        repeat
                            IsHandled := false;
                            OnInitSourceDocumentOnBeforeTransLineLoopIteration(TransHeader, TransLine, WhseActivHeader, IsHandled);
                            if not IsHandled then begin
                                TransLine.Validate("Qty. to Ship", 0);
                                TransLine.Validate("Qty. to Receive", 0);
                                ModifyTransferLine(TransLine);
                                OnAfterTransLineModify(TransLine);
                            end;
                        until TransLine.Next() = 0;

                    OnInitSourceDocumentOnAfterTransferLineLoopIteration(TransLine, TransHeader, WhseActivHeader, ModifyHeader);

                    if (TransHeader."Posting Date" <> WhseActivHeader."Posting Date") and (WhseActivHeader."Posting Date" <> 0D) then begin
                        TransHeader.CalledFromWarehouse(true);
                        TransHeader.Validate("Posting Date", WhseActivHeader."Posting Date");
                        ModifyHeader := true;
                    end;
                    if WhseActivHeader."External Document No." <> '' then begin
                        TransHeader."External Document No." := WhseActivHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    ModifyTransferHeader(TransHeader, WhseActivHeader, ModifyHeader);
                end;
        end;

        OnAfterInitSourceDocument(WhseActivHeader);
    end;

    local procedure ReleasePurchDocument(var ModifyHeader: Boolean)
    var
        PurchRelease: Codeunit "Release Purchase Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReleasePurchDocument(PurchHeader, WhseActivHeader, ModifyHeader, IsHandled);
        if IsHandled then
            exit;

        if (PurchHeader."Posting Date" <> WhseActivHeader."Posting Date") and (WhseActivHeader."Posting Date" <> 0D) then begin
            PurchRelease.SetSkipWhseRequestOperations(true);
            PurchRelease.Reopen(PurchHeader);
            PurchRelease.SetSkipCheckReleaseRestrictions();
            PurchHeader.SetHideValidationDialog(true);
            PurchHeader.Validate("Posting Date", WhseActivHeader."Posting Date");
            OnReleasePurchDocumentOnBeforePurchReleaseRun(PurchHeader, WhseActivHeader);
            PurchRelease.Run(PurchHeader);
            OnReleasePurchDocumentOnAfterPurchReleaseRun(PurchHeader, WhseActivHeader);
            ModifyHeader := true;
        end;
    end;

    local procedure ReleaseSalesDocument(var ModifyHeader: Boolean)
    var
        SalesRelease: Codeunit "Release Sales Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReleaseSalesDocument(SalesHeader, WhseActivHeader, ModifyHeader, IsHandled);
        if not IsHandled then
            if (SalesHeader."Posting Date" <> WhseActivHeader."Posting Date") and (WhseActivHeader."Posting Date" <> 0D) then begin
                SalesRelease.SetSkipWhseRequestOperations(true);
                SalesRelease.Reopen(SalesHeader);
                SalesRelease.SetSkipCheckReleaseRestrictions();
                SalesHeader.SetHideValidationDialog(true);
                SalesHeader.Validate("Posting Date", WhseActivHeader."Posting Date");
                OnReleaseSalesDocumentOnBeforeSalesReleaseRun(SalesHeader, WhseActivHeader);
                SalesRelease.Run(SalesHeader);
                OnReleaseSalesDocumentOnAfterSalesReleaseRun(SalesHeader, WhseActivHeader);
                ModifyHeader := true;
            end;
        OnAfterReleaseSalesDocument(SalesHeader, WhseActivHeader, ModifyHeader);
    end;

    local procedure ModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ModifyHeader: Boolean)
    begin
        OnBeforeModifyPurchaseHeader(PurchaseHeader, WarehouseActivityHeader, ModifyHeader);
        if ModifyHeader then
            PurchaseHeader.Modify();
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        OnBeforeModifyPurchaseLine(PurchaseLine);
        PurchaseLine.Modify();
    end;

    local procedure ModifySalesHeader(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ModifyHeader: Boolean)
    begin
        OnBeforeModifySalesHeader(SalesHeader, WarehouseActivityHeader, ModifyHeader);
        if ModifyHeader then
            SalesHeader.Modify();
    end;

    local procedure ModifySalesLine(var SalesLine: Record "Sales Line")
    begin
        OnBeforeModifySalesLine(SalesLine);
        SalesLine.Modify();
    end;

    local procedure ModifyTransferHeader(var TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ModifyHeader: Boolean)
    begin
        OnBeforeModifyTransferHeader(TransferHeader, WarehouseActivityHeader, ModifyHeader);
        if ModifyHeader then
            TransferHeader.Modify();
    end;

    local procedure ModifyTransferLine(var TransferLine: Record "Transfer Line")
    begin
        OnBeforeModifyTransferLine(TransferLine);
        TransferLine.Modify();
    end;

    local procedure UpdateSourceDocument()
    var
        SalesLine: Record "Sales Line";
    begin
        OnBeforeUpdateSourceDocument(TempWhseActivLine);

        case TempWhseActivLine."Source Type" of
            Database::"Purchase Line":
                begin
                    if TempWhseActivLine."Activity Type" = TempWhseActivLine."Activity Type"::"Invt. Pick" then begin
                        TempWhseActivLine."Qty. to Handle" := -TempWhseActivLine."Qty. to Handle";
                        TempWhseActivLine."Qty. to Handle (Base)" := -TempWhseActivLine."Qty. to Handle (Base)";
                    end;
                    PurchLine.Get(TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.", TempWhseActivLine."Source Line No.");
                    OnUpdateSourceDocumentOnAfterGetPurchLine(PurchLine, TempWhseActivLine);
                    if TempWhseActivLine."Source Document" = TempWhseActivLine."Source Document"::"Purchase Order" then begin
                        OnUpdateSourceDocumentOnSourceDocumentIsPurchaseOrder(PurchLine, TempWhseActivLine);
                        if (PurchLine."Outstanding Quantity" <> 0) and (TempWhseActivLine."Qty. to Handle" > PurchLine."Outstanding Quantity") then
                            TempWhseActivLine."Qty. to Handle" := PurchLine."Outstanding Quantity";
                        PurchLine.Validate("Qty. to Receive", TempWhseActivLine."Qty. to Handle");
                        PurchLine."Qty. to Receive (Base)" := TempWhseActivLine."Qty. to Handle (Base)";
                        if InvoiceSourceDoc then
                            PurchLine.Validate("Qty. to Invoice", TempWhseActivLine."Qty. to Handle");
                    end else begin
                        if (PurchLine."Outstanding Quantity" <> 0) and (-TempWhseActivLine."Qty. to Handle" = PurchLine."Outstanding Quantity") then
                            TempWhseActivLine."Qty. to Handle" := -PurchLine."Outstanding Quantity";
                        PurchLine.Validate("Return Qty. to Ship", -TempWhseActivLine."Qty. to Handle");
                        PurchLine."Return Qty. to Ship (Base)" := -TempWhseActivLine."Qty. to Handle (Base)";
                        if InvoiceSourceDoc then
                            PurchLine.Validate("Qty. to Invoice", -TempWhseActivLine."Qty. to Handle");
                    end;
                    PurchLine."Bin Code" := TempWhseActivLine."Bin Code";
                    OnUpdateSourceDocumentOnBeforePurchLineModify(PurchLine, TempWhseActivLine);
                    PurchLine.Modify();
                    OnAfterPurchLineModify(PurchLine);
                    OnUpdateSourceDocumentOnAfterPurchLineModify(PurchLine, TempWhseActivLine);
                    UpdateAttachedLines(PurchLine);
                end;
            Database::"Sales Line":
                begin
                    if TempWhseActivLine."Activity Type" = TempWhseActivLine."Activity Type"::"Invt. Pick" then begin
                        TempWhseActivLine."Qty. to Handle" := -TempWhseActivLine."Qty. to Handle";
                        TempWhseActivLine."Qty. to Handle (Base)" := -TempWhseActivLine."Qty. to Handle (Base)";
                    end;
                    SalesLine.Get(TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.", TempWhseActivLine."Source Line No.");
                    OnUpdateSourceDocumentOnAfterGetSalesLine(SalesLine, TempWhseActivLine);
                    if TempWhseActivLine."Source Document" = TempWhseActivLine."Source Document"::"Sales Order" then begin
                        SalesLine.Validate("Qty. to Ship", -TempWhseActivLine."Qty. to Handle");
                        SalesLine."Qty. to Ship (Base)" := -TempWhseActivLine."Qty. to Handle (Base)";
                        if InvoiceSourceDoc then
                            SalesLine.Validate("Qty. to Invoice", -TempWhseActivLine."Qty. to Handle");
                    end else begin
                        SalesLine.Validate("Return Qty. to Receive", TempWhseActivLine."Qty. to Handle");
                        SalesLine."Return Qty. to Receive (Base)" := TempWhseActivLine."Qty. to Handle (Base)";
                        if InvoiceSourceDoc then
                            SalesLine.Validate("Qty. to Invoice", TempWhseActivLine."Qty. to Handle");
                    end;
                    SalesLine."Bin Code" := TempWhseActivLine."Bin Code";
                    OnUpdateSourceDocumentOnBeforeModifySalesLine(SalesLine, TempWhseActivLine, WhseActivHeader);
                    SalesLine.Modify();
                    OnUpdateSourceDocumentOnBeforeSalesLineModify(SalesLine, TempWhseActivLine);
                    OnAfterSalesLineModify(SalesLine);
                    OnUpdateSourceDocumentOnAfterSalesLineModify(SalesLine, TempWhseActivLine);
                    UpdateAttachedLines(SalesLine);
                end;
            Database::"Transfer Line":
                begin
                    TransHeader.Get(TempWhseActivLine."Source No.");
                    TransLine.Get(TempWhseActivLine."Source No.", TempWhseActivLine."Source Line No.");
                    OnUpdateSourceDocumentOnAfterGetTransLine(TransLine, TempWhseActivLine);
                    case TempWhseActivLine."Activity Type" of
                        TempWhseActivLine."Activity Type"::"Invt. Put-away":
                            begin
                                if TransHeader."Direct Transfer" then begin
                                    TransLine.Validate("Qty. to Ship", TempWhseActivLine."Qty. to Handle");
                                    TransLine."Qty. to Ship (Base)" := TempWhseActivLine."Qty. to Handle (Base)";
                                end;
                                TransLine."Transfer-To Bin Code" := TempWhseActivLine."Bin Code";
                                TransLine.Validate("Qty. to Receive", TempWhseActivLine."Qty. to Handle");
                                TransLine."Qty. to Receive (Base)" := TempWhseActivLine."Qty. to Handle (Base)";
                            end;
                        else begin
                            TransLine."Transfer-from Bin Code" := TempWhseActivLine."Bin Code";
                            TransLine.Validate("Qty. to Ship", TempWhseActivLine."Qty. to Handle");
                            TransLine."Qty. to Ship (Base)" := TempWhseActivLine."Qty. to Handle (Base)";
                            if TransHeader."Direct Transfer" then begin
                                TransLine.Validate("Qty. to Receive", TempWhseActivLine."Qty. to Handle");
                                TransLine."Qty. to Receive (Base)" := TempWhseActivLine."Qty. to Handle (Base)";
                            end;
                        end;
                    end;
                    OnUpdateSourceDocumentOnBeforeTransLineModify(TransLine, TempWhseActivLine);
                    TransLine.Modify();
                    OnUpdateSourceDocumentOnAfterTransLineModify(TransLine, TempWhseActivLine);
                end;
        end;
    end;

    local procedure UpdateUnhandledTransLine(TransHeaderNo: Code[20])
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.SetRange("Document No.", TransHeaderNo);
        TransLine.SetRange("Derived From Line No.", 0);
        TransLine.SetRange("Qty. to Ship", 0);
        TransLine.SetRange("Qty. to Receive", 0);
        if TransLine.FindSet() then
            repeat
                if TransLine."Qty. in Transit" <> 0 then
                    TransLine.Validate(TransLine."Qty. to Receive", TransLine."Qty. in Transit");
                if TransLine."Outstanding Quantity" <> 0 then
                    TransLine.Validate(TransLine."Qty. to Ship", TransLine."Outstanding Quantity");
                OnBeforeUnhandledTransLineModify(TransLine);
                TransLine.Modify();
            until TransLine.Next() = 0;
    end;

    local procedure PostSourceDocument(WhseActivHeader: Record "Warehouse Activity Header")
    var
        InventorySetup: Record "Inventory Setup";
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferPostShip: Codeunit "TransferOrder-Post Shipment";
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        OnBeforePostSourceDocument(WhseActivHeader, PostedSourceType, PostedSourceNo, PostedSourceSubType, HideDialog, SuppressCommit);

        case WhseActivHeader."Source Type" of
            Database::"Purchase Line":
                begin
                    Clear(PurchPost);
                    if not (SuppressCommit or IsPreview) then
                        Commit();
                    if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Purchase Order" then
                        PurchHeader.Receive := true
                    else
                        PurchHeader.Ship := true;
                    PurchHeader.Invoice := InvoiceSourceDoc;
                    PurchHeader."Posting from Whse. Ref." := PostingReference;
                    OnPostSourceDocumentOnBeforePurchPostRun(WhseActivHeader, PurchHeader);
                    PurchPost.SetSuppressCommit(IsPreview or SuppressCommit);
                    PurchPost.Run(PurchHeader);
                    if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Purchase Order" then begin
                        PostedSourceType := Database::"Purch. Rcpt. Header";
                        PostedSourceNo := PurchHeader."Last Receiving No.";
                    end else begin
                        PostedSourceType := Database::"Return Shipment Header";
                        PostedSourceNo := PurchHeader."Last Return Shipment No.";
                    end;
                    PostedSourceSubType := 0;
                end;
            Database::"Sales Line":
                begin
                    Clear(SalesPost);
                    if not (SuppressCommit or IsPreview) then
                        Commit();
                    if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Sales Order" then
                        SalesHeader.Ship := true
                    else
                        SalesHeader.Receive := true;
                    SalesHeader.Invoice := InvoiceSourceDoc;
                    SalesHeader."Posting from Whse. Ref." := PostingReference;
                    SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
                    OnPostSourceDocumentOnBeforeSalesPostRun(WhseActivHeader, SalesHeader);
                    SalesPost.SetSuppressCommit(SuppressCommit or IsPreview);
                    SalesPost.Run(SalesHeader);
                    if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Sales Order" then begin
                        PostedSourceType := Database::"Sales Shipment Header";
                        PostedSourceNo := SalesHeader."Last Shipping No.";
                    end else begin
                        PostedSourceType := Database::"Return Receipt Header";
                        PostedSourceNo := SalesHeader."Last Return Receipt No.";
                    end;
                    PostedSourceSubType := 0;
                end;
            Database::"Transfer Line":
                begin
                    Clear(TransferPostReceipt);
                    if not (SuppressCommit or IsPreview) then
                        Commit();
                    case WhseActivHeader.Type of
                        WhseActivHeader.Type::"Invt. Put-away":
                            begin
                                TransHeader."Posting from Whse. Ref." := PostingReference;
                                OnPostSourceDocumentOnBeforeTransferPostReceiptRun(TransHeader, WhseActivHeader);
                                if not TransHeader."Direct Transfer" then begin
                                    if HideDialog then
                                        TransferPostReceipt.SetHideValidationDialog(HideDialog);
                                    TransferPostReceipt.SetPreviewMode(IsPreview);
                                    TransferPostReceipt.Run(TransHeader);
                                    PostedSourceType := Database::"Transfer Receipt Header";
                                    PostedSourceNo := TransHeader."Last Receipt No.";
                                end else begin
                                    InventorySetup.Get();
                                    InventorySetup.TestField("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
                                    if HideDialog then
                                        TransferPostTransfer.SetHideValidationDialog(HideDialog);
                                    TransferPostTransfer.SetPreviewMode(IsPreview);
                                    TransferPostTransfer.Run(TransHeader);
                                    PostedSourceType := Database::"Direct Trans. Header";
                                    PostedSourceNo := TransHeader."Last Receipt No.";
                                end;
                            end
                        else begin
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            if not TransHeader."Direct Transfer" then begin
                                if HideDialog then
                                    TransferPostShip.SetHideValidationDialog(HideDialog);
                                TransferPostShip.SetPreviewMode(IsPreview);
                                TransferPostShip.Run(TransHeader);
                                PostedSourceType := Database::"Transfer Shipment Header";
                                PostedSourceNo := TransHeader."Last Shipment No.";
                            end else begin
                                InventorySetup.Get();
                                InventorySetup.TestField("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
                                if HideDialog then
                                    TransferPostTransfer.SetHideValidationDialog(HideDialog);
                                TransferPostTransfer.SetPreviewMode(IsPreview);
                                TransferPostTransfer.Run(TransHeader);
                                PostedSourceType := Database::"Direct Trans. Header";
                                PostedSourceNo := TransHeader."Last Shipment No.";
                            end;
                        end;
                    end;

                    OnPostSourceDocumentOnBeforeUpdateUnhandledTransLine(TransHeader, WhseActivHeader, PostingReference, HideDialog);
                    UpdateUnhandledTransLine(TransHeader."No.");
                    PostedSourceSubType := 0;
                end;
        end;

        OnAfterPostSourceDocument(WhseActivHeader, PurchHeader, SalesHeader, TransHeader, PostingReference, HideDialog);
    end;

    local procedure PostJobUsage(PostingDate: Date)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJnlLine: Record "Job Journal Line";
        JobJnlLineReservationEntry: Record "Reservation Entry";
        JobTransferLine: Codeunit "Job Transfer Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000GQT', 'Picks on jobs', 'post picks');
        TempWhseActivLine.Reset();
        if TempWhseActivLine.FindSet() then begin
            repeat
                JobPlanningLine.SetRange("Job Contract Entry No.", TempWhseActivLine."Source Line No.");
                JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);

                if JobPlanningLine.FindFirst() then begin
                    JobPlanningLine.Validate("Qty. to Transfer to Journal", TempWhseActivLine."Qty. to Handle");

                    JobTransferLine.FromWarehouseActivityLineToJnlLine(TempWhseActivLine, PostingDate, '', '', JobJnlLine);
                end;

                JobJnlPostLine.SetCalledFromInvtPutawayPick(true);
                JobJnlPostLine.RunWithCheck(JobJnlLine);

                //Delete the temporary job journal line and the linked item tracking after posting.
                JobJnlLineReservationEntry.SetSourceFilter(Database::"Job Journal Line", JobJnlLine."Entry Type".AsInteger(), JobJnlLine."Journal Template Name", JobJnlLine."Line No.", true);
                JobJnlLineReservationEntry.SetRange("Source Batch Name", JobJnlLine."Journal Batch Name");
                JobJnlLineReservationEntry.DeleteAll();
                JobJnlLine.Delete();
            until TempWhseActivLine.Next() = 0;

            PostedSourceType := TempWhseActivLine."Source Type";
            PostedSourceSubType := TempWhseActivLine."Source Subtype";
            PostedSourceNo := TempWhseActivLine."Source No.";
        end;
    end;

    local procedure PostWhseActivityLine(WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line")
    var
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PurchaseForJob: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseActivLine(WhseActivHeader, WhseActivLine, PostedSourceNo, PostedSourceType, PostedSourceSubType, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnPostWhseActivityLineOnBeforePosting(WhseActivHeader, WhseActivLine, PostedSourceNo, PostedSourceType, PostedSourceSubType, IsHandled);
        if not IsHandled then
            if WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Prod. Consumption" then
                PostProdConsumption(WhseActivHeader)
            else
                if (WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away") and (WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Prod. Output") then
                    PostProdOutput(WhseActivHeader)
                else
                    if (WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Pick") and (WhseActivHeader."Source Document" = WhseActivHeader."Source Document"::"Job Usage") then
                        PostJobUsage(WhseActivHeader."Posting Date")
                    else begin
                        PurchaseForJob := IsActivityForJobPurchase(WhseActivLine);
                        IsHandled := false;
                        OnPostWhseActivityLineOnBeforePostDoc(TempWhseActivLine, WhseActivHeader, PostedSourceType, PostedSourceSubType, PostedSourceNo, IsHandled);
                        if not IsHandled then
                            PostSourceDoc();
                    end;

        OnPostWhseActivityLineOnBeforeCreatePostedActivHeader(WhseActivHeader);
        CreatePostedActivHeader(WhseActivHeader, PostedInvtPutAwayHeader, PostedInvtPickHeader);

        repeat
            LineCount := LineCount + 1;
            if not HideDialog then begin
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            end;

            UpdateWhseActivityLine(WhseActivLine);

            if Location."Bin Mandatory" and (WhseActivHeader."Source Document" <> WhseActivHeader."Source Document"::"Job Usage") then
                PostWhseJnlLine(WhseActivLine, PurchaseForJob);

            CreatePostedActivLine(WhseActivLine, PostedInvtPutAwayHeader, PostedInvtPickHeader);
        until WhseActivLine.Next() = 0;

        OnAfterPostWhseActivityLine(WhseActivHeader, WhseActivLine, PostedSourceNo, PostedSourceType, PostedSourceSubType);
    end;

    local procedure UpdateWhseActivityLine(var WhseActivLine: Record "Warehouse Activity Line")
    var
        EntriesExist: Boolean;
    begin
        if CheckItemTracking(WhseActivLine) and (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Put-away") then
            WhseActivLine."Expiration Date" := ItemTrackingMgt.ExistingExpirationDate(WhseActivLine, false, EntriesExist);
    end;

    local procedure PostWhseJnlLine(WhseActivLine: Record "Warehouse Activity Line"; PurchaseForJob: Boolean)
    var
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        WMSMgt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        OnBeforePostWhseJnlLine(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        CreateWhseJnlLine(TempWhseJnlLine, WhseActivLine);
        if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then
            WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 4, TempWhseJnlLine."Qty. (Base)", false); // 4 = Whse. Journal
        WhseJnlRegisterLine.Run(TempWhseJnlLine);
        if PurchaseForJob then
            if ConsumeWarehouseEntryForJobPurchase(TempWhseJnlLine, WhseActivLine) then
                WhseJnlRegisterLine.Run(TempWhseJnlLine);
    end;

    procedure CreateWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; WhseActivLine: Record "Warehouse Activity Line")
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        WhseJnlLine.Init();
        WhseJnlLine."Location Code" := WhseActivLine."Location Code";
        WhseJnlLine."Item No." := WhseActivLine."Item No.";
        WhseJnlLine."Registering Date" := WhseActivHeader."Posting Date";
        WhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseJnlLine."User ID"));
        WhseJnlLine."Variant Code" := WhseActivLine."Variant Code";
        if WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take then begin
            WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
            WhseJnlLine."From Bin Code" := WhseActivLine."Bin Code";
            WhseJnlLine."From Zone Code" := WhseActivLine."Zone Code";
            WhseJnlLine.Quantity := WhseActivLine."Qty. to Handle (Base)";
            WhseJnlLine."Qty. (Base)" := WhseActivLine."Qty. to Handle (Base)";
        end else begin
            WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
            WhseJnlLine."To Bin Code" := WhseActivLine."Bin Code";
            WhseJnlLine."To Zone Code" := WhseActivLine."Zone Code";
            WhseJnlLine.Quantity := -WhseActivLine."Qty. to Handle (Base)";
            WhseJnlLine."Qty. (Base)" := -WhseActivLine."Qty. to Handle (Base)";
        end;
        WhseJnlLine."Qty. (Absolute)" := WhseActivLine."Qty. to Handle (Base)";
        WhseJnlLine."Qty. (Absolute, Base)" := WhseActivLine."Qty. to Handle (Base)";
        WhseJnlLine."Unit of Measure Code" := WMSMgt.GetBaseUOM(WhseActivLine."Item No.");
        WhseJnlLine."Qty. per Unit of Measure" := 1;
        WhseJnlLine."Source Type" := PostedSourceType;
        WhseJnlLine."Source Subtype" := PostedSourceSubType;
        WhseJnlLine."Source No." := PostedSourceNo;
        WhseJnlLine."Reference No." := PostedSourceNo;
        case WhseActivLine."Source Document" of
            WhseActivLine."Source Document"::"Purchase Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rcpt.";
                end;
            WhseActivLine."Source Document"::"Sales Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Shipment";
                end;
            WhseActivLine."Source Document"::"Purchase Return Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                end;
            WhseActivLine."Source Document"::"Sales Return Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                end;
            WhseActivLine."Source Document"::"Outbound Transfer":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Shipment";
                end;
            WhseActivLine."Source Document"::"Inbound Transfer":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Receipt";
                end;
            else
                OnCreateWhseJnlLineOnSetReferenceDocument(WhseActivLine, WhseJnlLine, SourceCodeSetup);
        end;

        if WhseActivLine."Activity Type" in [WhseActivLine."Activity Type"::"Invt. Put-away", WhseActivLine."Activity Type"::"Invt. Pick",
                               WhseActivLine."Activity Type"::"Invt. Movement"]
        then
            WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";

        WhseJnlLine.CopyTrackingFromWhseActivityLine(WhseActivLine);
        WhseJnlLine."Warranty Date" := WhseActivLine."Warranty Date";
        WhseJnlLine."Expiration Date" := WhseActivLine."Expiration Date";

        OnAfterCreateWhseJnlLine(WhseJnlLine, WhseActivLine, SourceCodeSetup);
    end;

    local procedure ConsumeWarehouseEntryForJobPurchase(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        Bin: Record Bin;
    begin
        if WarehouseActivityLine."Source Document" <> WarehouseActivityLine."Source Document"::"Purchase Order" then
            exit(false);

        if WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::"Invt. Put-away" then
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

    local procedure IsActivityForJobPurchase(WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if WarehouseActivityLine."Source Document" <> WarehouseActivityLine."Source Document"::"Purchase Order" then
            exit(false);

        if WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::"Invt. Put-away" then
            exit(false);

        PurchaseLine.SetLoadFields("Job No.");
        case WarehouseActivityLine."Source Document" of
            WarehouseActivityLine."Source Document"::"Purchase Order":
                if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then
                    exit(false);
        end;

        exit(PurchaseLine."Job No." <> '');
    end;

    local procedure CreatePostedActivHeader(WhseActivHeader: Record "Warehouse Activity Header"; var PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header"; var PostedInvtPickHeader: Record "Posted Invt. Pick Header")
    var
        WhseComment: Record "Warehouse Comment Line";
        WhseComment2: Record "Warehouse Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then begin
            PostedInvtPutAwayHeader.Init();
            PostedInvtPutAwayHeader.TransferFields(WhseActivHeader);
            PostedInvtPutAwayHeader."No." := '';
            PostedInvtPutAwayHeader."Invt. Put-away No." := WhseActivHeader."No.";
            PostedInvtPutAwayHeader."Source No." := PostedSourceNo;
            PostedInvtPutAwayHeader."Source Type" := PostedSourceType;
            OnBeforePostedInvtPutAwayHeaderInsert(PostedInvtPutAwayHeader, WhseActivHeader);
            PostedInvtPutAwayHeader.Insert(true);
            RecordLinkManagement.CopyLinks(WhseActivHeader, PostedInvtPutAwayHeader);
            OnAfterPostedInvtPutAwayHeaderInsert(PostedInvtPutAwayHeader, WhseActivHeader);
        end else begin
            PostedInvtPickHeader.Init();
            PostedInvtPickHeader.TransferFields(WhseActivHeader);
            PostedInvtPickHeader."No." := '';
            PostedInvtPickHeader."Invt Pick No." := WhseActivHeader."No.";
            PostedInvtPickHeader."Source No." := PostedSourceNo;
            PostedInvtPickHeader."Source Type" := PostedSourceType;
            OnBeforePostedInvtPickHeaderInsert(PostedInvtPickHeader, WhseActivHeader);
            PostedInvtPickHeader.Insert(true);
            RecordLinkManagement.CopyLinks(WhseActivHeader, PostedInvtPickHeader);
            OnAfterPostedInvtPickHeaderInsert(PostedInvtPickHeader, WhseActivHeader);
        end;

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Activity Header");
        WhseComment.SetRange(Type, WhseActivHeader.Type);
        WhseComment.SetRange("No.", WhseActivHeader."No.");
        WhseComment.LockTable();
        if WhseComment.Find('-') then
            repeat
                WhseComment2.Init();
                WhseComment2 := WhseComment;
                if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then begin
                    WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Invt. Put-Away";
                    WhseComment2."No." := PostedInvtPutAwayHeader."No.";
                end else begin
                    WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Invt. Pick";
                    WhseComment2."No." := PostedInvtPickHeader."No.";
                end;
                WhseComment2.Type := WhseComment2.Type::" ";
                WhseComment2.Insert();
            until WhseComment.Next() = 0;
    end;

    local procedure CreatePostedActivLine(WhseActivLine: Record "Warehouse Activity Line"; PostedInvtPutAwayHdr: Record "Posted Invt. Put-away Header"; PostedInvtPickHeader: Record "Posted Invt. Pick Header")
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then begin
            PostedInvtPutAwayLine.Init();
            PostedInvtPutAwayLine.TransferFields(WhseActivLine);
            PostedInvtPutAwayLine."No." := PostedInvtPutAwayHdr."No.";
            PostedInvtPutAwayLine.Validate(Quantity, WhseActivLine."Qty. to Handle");
            OnBeforePostedInvtPutAwayLineInsert(PostedInvtPutAwayLine, WhseActivLine);
            PostedInvtPutAwayLine.Insert();
        end else begin
            PostedInvtPickLine.Init();
            PostedInvtPickLine.TransferFields(WhseActivLine);
            PostedInvtPickLine."No." := PostedInvtPickHeader."No.";
            PostedInvtPickLine.Validate(Quantity, WhseActivLine."Qty. to Handle");
            OnBeforePostedInvtPickLineInsert(PostedInvtPickLine, WhseActivLine);
            PostedInvtPickLine.Insert();
        end;
    end;

    local procedure PostSourceDoc()
    begin
        OnBeforePostSourceDoc(WhseActivHeader, HideDialog, SuppressCommit);

        TempWhseActivLine.Reset();
        TempWhseActivLine.Find('-');
        InitSourceDocument();
        repeat
            UpdateSourceDocument();
        until TempWhseActivLine.Next() = 0;
        UpdateItemChargeLines();
        UpdateNonInventoryLines();

        PostSourceDocument(WhseActivHeader);
    end;

    local procedure PostProdConsumption(WhseActivityHeader: Record "Warehouse Activity Header")
    begin
        OnPostProdConsumption(WhseActivityHeader, TempWhseActivLine, PostedSourceType, PostedSourceSubType, PostedSourceNo);
    end;

    local procedure PostProdOutput(WhseActivityHeader: Record "Warehouse Activity Header")
    begin
        OnPostProdOutput(WhseActivityHeader, TempWhseActivLine, PostedSourceType, PostedSourceSubType, PostedSourceNo);
    end;

    procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure LockPostedTables(WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        if WarehouseActivityHeader.Type = WarehouseActivityHeader.Type::"Invt. Put-away" then begin
            PostedInvtPutAwayHeader.LockTable();
            PostedInvtPutAwayLine.LockTable();
        end else begin
            PostedInvtPickHeader.LockTable();
            PostedInvtPickLine.LockTable();
        end;
    end;

    procedure ShowHideDialog(HideDialog2: Boolean)
    begin
        HideDialog := HideDialog2;
    end;

    procedure SetInvoiceSourceDoc(Invoice: Boolean)
    begin
        InvoiceSourceDoc := Invoice;
        OnAfterSetInvoiceSourceDoc(InvoiceSourceDoc);
    end;

    procedure PrintDocument(SetPrint: Boolean)
    begin
        PrintDoc := SetPrint;
    end;

    local procedure CheckItemTracking(WhseActivLine2: Record "Warehouse Activity Line"): Boolean
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemTracking(WhseActivLine2, Result, IsHandled, WhseActivHeader);
        if IsHandled then
            exit(Result);

        ItemTrackingMgt.GetWhseItemTrkgSetup(WhseActivLine2."Item No.", WhseItemTrackingSetup);
        WhseActivLine2.TestTrackingIfRequired(WhseItemTrackingSetup);
        if (WhseActivLine2."Expiration Date" <> 0D) and ItemTrackingMgt.StrictExpirationPosting(WhseActivLine2."Item No.") then
            if WhseActivHeader."Posting Date" > WhseActivLine2."Expiration Date" then
                WhseActivLine2.FieldError(WhseActivLine2."Expiration Date", PostingDateErr);

        exit(WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetIsPreview(NewIsPreview: Boolean)
    begin
        IsPreview := NewIsPreview;
    end;

    local procedure CheckWhseItemTrackingAgainstSource()
    var
        TrackingSpecification: Record "Tracking Specification";
        JobPlanningLine: Record "Job Planning Line";
    begin
        TempWarehouseActivityLineForItemTrackingChecking.Reset();
        if TempWarehouseActivityLineForItemTrackingChecking.FindSet() then
            repeat
                case TempWarehouseActivityLineForItemTrackingChecking."Source Type" of
                    5407: // Database::"Prod. Order Component"
                        TrackingSpecification.CheckItemTrackingQuantity(
                            TempWarehouseActivityLineForItemTrackingChecking."Source Type",
                            TempWarehouseActivityLineForItemTrackingChecking."Source Subtype",
                            TempWarehouseActivityLineForItemTrackingChecking."Source No.",
                            TempWarehouseActivityLineForItemTrackingChecking."Source Subline No.",
                            TempWarehouseActivityLineForItemTrackingChecking."Source Line No.",
                            TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)",
                            TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)", true, InvoiceSourceDoc);
                    Database::Job:
                        begin
                            // Checking tracking specification for Job by mapping Temporary warehouse activity line to Job planning line item tracking.
                            JobPlanningLine.SetLoadFields(Status);
                            JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
                            JobPlanningLine.SetRange("Job Contract Entry No.", TempWarehouseActivityLineForItemTrackingChecking."Source Line No.");
                            JobPlanningLine.FindFirst();
                            TrackingSpecification.CheckItemTrackingQuantity(
                                Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(),
                                TempWarehouseActivityLineForItemTrackingChecking."Source No.",
                                TempWarehouseActivityLineForItemTrackingChecking."Source Line No.",
                                TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)",
                                TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)", true, InvoiceSourceDoc);
                        end;
                    else
                        TrackingSpecification.CheckItemTrackingQuantity(TempWarehouseActivityLineForItemTrackingChecking."Source Type", TempWarehouseActivityLineForItemTrackingChecking."Source Subtype", TempWarehouseActivityLineForItemTrackingChecking."Source No.", TempWarehouseActivityLineForItemTrackingChecking."Source Line No.", TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)", TempWarehouseActivityLineForItemTrackingChecking."Qty. to Handle (Base)", true, InvoiceSourceDoc);
                end;
            until TempWarehouseActivityLineForItemTrackingChecking.Next() = 0;
    end;

    local procedure CheckAvailability(WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAvailability(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        if WhseActivLine."Activity Type" <> WhseActivLine."Activity Type"::"Invt. Pick" then
            exit;

        if WhseActivLine."Assemble to Order" and not WhseActivLine."ATO Component" then
            exit;

        if not WhseActivLine.CheckItemTrackingAvailability() then
            AvailabilityError(WhseActivLine);
    end;

    local procedure AvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Serial No." <> '' then
            Error(InventoryNotAvailableErr, WhseActivLine.FieldCaption("Serial No."), WhseActivLine."Serial No.");
        if WhseActivLine."Lot No." <> '' then
            Error(InventoryNotAvailableErr, WhseActivLine.FieldCaption("Lot No."), WhseActivLine."Lot No.");

        OnAfterAvailabilityError(WhseActivLine);
    end;

    local procedure UpdateAttachedLines(PurchaseLine: Record "Purchase Line")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        AttachedPurchLine: Record "Purchase Line";
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit;

        AttachedPurchLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        AttachedPurchLine.SetFilter(Type, '<>%1', AttachedPurchLine.Type::"Charge (Item)");
        if AttachedPurchLine.FindSet() then
            repeat
                UpdateQtyToHandleOnPurchaseLine(AttachedPurchLine, AttachedPurchLine."Outstanding Quantity");
            until AttachedPurchLine.Next() = 0;
    end;

    local procedure UpdateAttachedLines(SalesLine: Record "Sales Line")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        AttachedSalesLine: Record "Sales Line";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit;

        AttachedSalesLine.SetRange("Document Type", SalesLine."Document Type");
        AttachedSalesLine.SetRange("Document No.", SalesLine."Document No.");
        AttachedSalesLine.SetRange("Attached to Line No.", SalesLine."Line No.");
        AttachedSalesLine.SetFilter(Type, '<>%1', AttachedSalesLine.Type::"Charge (Item)");
        if AttachedSalesLine.FindSet() then
            repeat
                UpdateQtyToHandleOnSalesLine(AttachedSalesLine, AttachedSalesLine."Outstanding Quantity");
            until AttachedSalesLine.Next() = 0;
    end;

    local procedure UpdateItemChargeLines()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemChargePurchLine: Record "Purchase Line";
        ItemChargeSalesLine: Record "Sales Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        QtyToHandle: Decimal;
    begin
        case WhseActivHeader."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchasesPayablesSetup.Get();
                    if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
                        exit;
                    ItemChargePurchLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    ItemChargePurchLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    ItemChargePurchLine.SetRange(Type, ItemChargePurchLine.Type::"Charge (Item)");
                    if not ItemChargePurchLine.FindSet() then
                        exit;
                    repeat
                        QtyToHandle := 0;
                        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargePurchLine."Document Type");
                        ItemChargeAssignmentPurch.SetRange("Document No.", ItemChargePurchLine."Document No.");
                        ItemChargeAssignmentPurch.SetRange("Document Line No.", ItemChargePurchLine."Line No.");
                        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", ItemChargePurchLine."Document Type");
                        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", ItemChargePurchLine."Document No.");
                        ItemChargeAssignmentPurch.SetFilter("Qty. to Handle", '<>0');
                        if ItemChargeAssignmentPurch.FindSet() then
                            repeat
                                TempWhseActivLine.SetRange("Source Line No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.");
                                if not TempWhseActivLine.IsEmpty() then
                                    QtyToHandle += ItemChargeAssignmentPurch."Qty. to Handle";
                            until ItemChargeAssignmentPurch.Next() = 0;

                        UpdateQtyToHandleOnPurchaseLine(ItemChargePurchLine, QtyToHandle);
                    until ItemChargePurchLine.Next() = 0;
                end;
            Database::"Sales Line":
                begin
                    SalesReceivablesSetup.Get();
                    if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
                        exit;
                    ItemChargeSalesLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    ItemChargeSalesLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    ItemChargeSalesLine.SetRange(Type, ItemChargeSalesLine.Type::"Charge (Item)");
                    if not ItemChargeSalesLine.FindSet() then
                        exit;
                    repeat
                        QtyToHandle := 0;
                        ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeSalesLine."Document Type");
                        ItemChargeAssignmentSales.SetRange("Document No.", ItemChargeSalesLine."Document No.");
                        ItemChargeAssignmentSales.SetRange("Document Line No.", ItemChargeSalesLine."Line No.");
                        ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", ItemChargeSalesLine."Document Type");
                        ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", ItemChargeSalesLine."Document No.");
                        ItemChargeAssignmentSales.SetFilter("Qty. to Handle", '<>0');
                        if ItemChargeAssignmentSales.FindSet() then
                            repeat
                                TempWhseActivLine.SetRange("Source Line No.", ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                                if not TempWhseActivLine.IsEmpty() then
                                    QtyToHandle += ItemChargeAssignmentSales."Qty. to Handle";
                            until ItemChargeAssignmentSales.Next() = 0;

                        UpdateQtyToHandleOnSalesLine(ItemChargeSalesLine, QtyToHandle);
                    until ItemChargeSalesLine.Next() = 0;
                end;
        end;
    end;

    local procedure UpdateNonInventoryLines()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        case WhseActivHeader."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchasesPayablesSetup.Get();
                    if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::All then
                        exit;

                    PurchaseLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    PurchaseLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    if PurchaseLine.FindSet() then
                        repeat
                            if not PurchaseLine.IsInventoriableItem() then
                                UpdateQtyToHandleOnPurchaseLine(PurchaseLine, PurchaseLine."Outstanding Quantity");
                        until PurchaseLine.Next() = 0;
                end;
            Database::"Sales Line":
                begin
                    SalesReceivablesSetup.Get();
                    if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::All then
                        exit;

                    SalesLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    SalesLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    if SalesLine.FindSet() then
                        repeat
                            if not SalesLine.IsInventoriableItem() then
                                UpdateQtyToHandleOnSalesLine(SalesLine, SalesLine."Outstanding Quantity");
                        until SalesLine.Next() = 0;
                end;
        end;
    end;

    local procedure UpdateQtyToHandleOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToHandle: Decimal)
    var
        ModifyLine: Boolean;
    begin
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
            ModifyLine := PurchaseLine."Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                PurchaseLine.Validate("Qty. to Receive", QtyToHandle);
        end else begin
            ModifyLine := PurchaseLine."Return Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                PurchaseLine.Validate("Return Qty. to Ship", QtyToHandle);
        end;
        OnUpdateQtyToHandleOnPurchaseLineOnBeforePurchLineModify(PurchaseLine, ModifyLine);
        if ModifyLine then
            ModifyPurchaseLine(PurchaseLine);
    end;

    local procedure UpdateQtyToHandleOnSalesLine(var SalesLine: Record "Sales Line"; QtyToHandle: Decimal)
    var
        ModifyLine: Boolean;
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", QtyToHandle);
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", QtyToHandle);
        end;
        OnUpdateQtyToHandleOnSalesLineOnBeforeSalesLineModify(SalesLine, ModifyLine);
        if ModifyLine then
            ModifySalesLine(SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean; PrintDoc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocument(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSalesDocument(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInvoiceSourceDoc(var InvoiceSourceDocument: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceDocument(WarehouseActivityHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header"; PostingReference: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedInvtPickHeaderInsert(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedInvtPutAwayHeaderInsert(var PostedInvtPutAwayHeader: Record "Posted Invt. Put-Away Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseActivityLine(WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line"; PostedSourceNo: Code[20]; PostedSourceType: Integer; PostedSourceSubType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineModify(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineModify(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseActivLineModify(var WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreatePostedWhseActivDocument(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempWhseActivLine(var WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSourceDocument(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailability(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean; WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingReference(var PostReference: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTransferHeader(var TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTransferLine(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPickHeaderInsert(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPickLineInsert(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPutAwayHeaderInsert(var PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPutAwayLineInsert(var PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var PostedSourceType: Integer; var PostedSourceNo: Code[20]; var PostedSourceSubType: Integer; HideDialog: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseActivLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var PostedSourceNo: Code[20]; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDoc(WhseActivHeader: Record "Warehouse Activity Header"; HideDialog: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchDocument(var PurchaseHeader: Record "Purchase Header"; WhseActivHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesDocument(var SalesHeader: Record "Sales Header"; WhseActivHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSourceDocument(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseActivLineInsert(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseActivLineModify(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnhandledTransLineModify(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineDelete(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ForceDelete: Boolean; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterWhseActivLineSetFilters(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforeSalesLineLoopIteration(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforePurchLineLoopIteration(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseActivHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforeTransLineLoopIteration(TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterSetPurchaseLineFilters(var PurchaseLine: record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostConsumptionLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
        OnPostConsumptionLineOnAfterCreateItemJnlLine(ItemJournalLine, ProdOrderLine, WarehouseActivityLine, SourceCodeSetup);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityPost', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeTransferPostReceiptRun(var TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterTransLineSetFilters(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterTransferLineLoopIteration(var TransLine: Record "Transfer Line"; TransHeader: Record "Transfer Header"; WhseActivHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostConsumptionLineOnAfterInitItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
        OnPostConsumptionLineOnAfterInitItemJournalLine(ItemJournalLine, SourceCodeSetup);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityPost', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterInitItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
        OnPostOutputLineOnAfterCreateItemJnlLine(ItemJournalLine, ProdOrderLine, WarehouseActivityLine, SourceCodeSetup);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityPost', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePurchPostRun(WarehouseActivityHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeSalesPostRun(WarehouseActivityHeader: Record "Warehouse Activity Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeUpdateUnhandledTransLine(var TransHeader: Record "Transfer Header"; WhseActivHeader: Record "Warehouse Activity Header"; PostingReference: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseActivityLineOnBeforePosting(var WhseActivityHeader: Record "Warehouse Activity Header"; var WhseActivityLine: Record "Warehouse Activity Line"; var PostedSourceNo: Code[20]; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnAfterPurchReleaseRun(PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnBeforePurchReleaseRun(var PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseSalesDocumentOnAfterSalesReleaseRun(SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseSalesDocumentOnBeforeSalesReleaseRun(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterGetPurchLine(var PurchaseLine: Record "Purchase Line"; TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterPurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterTransLineModify(var TransferLine: Record "Transfer Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterGetSalesLine(var SalesLine: Record "Sales Line"; TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostOutputLineOnAfterItemJournalLineInit(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup2: Record "Source Code Setup")
    begin
        OnPostOutputLineOnAfterItemJournalLineInit(ItemJournalLine, SourceCodeSetup2);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityPost', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterItemJournalLineInit(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToHandleOnPurchaseLineOnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToHandleOnSalesLineOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterGetTransLine(var TransferLine: Record "Transfer Line"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnSourceDocumentIsPurchaseOrder(var PurchaseLine: Record "Purchase Line"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseActivityLineOnBeforePostDoc(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WhseActivHeader: Record "Warehouse Activity Header"; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeCheckProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
        OnBeforeCheckProdOrderLine(ProdOrderLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityPost', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnPostWhseActivityLineOnBeforeCreatePostedActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostProdConsumption(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostProdOutput(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineOnSetReferenceDocument(WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseJnlLine: Record "Warehouse Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}
