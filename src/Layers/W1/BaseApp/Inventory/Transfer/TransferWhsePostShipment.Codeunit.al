// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Posting;

using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Document;
using Microsoft.Foundation.Navigate;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Setup;

codeunit 5748 "Transfer Whse. Post Shipment"
{
    var
        InventorySetup: Record "Inventory Setup";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
#if not CLEAN25
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnGetSourceDocumentOnElseCase', '', false, false)]
    local procedure OnGetSourceDocument(var SourceHeader: Variant; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        TransferHeader: Record "Transfer Header";
    begin
        case WhseShptLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransferHeader.Get(WhseShptLine."Source No.");
                    SourceHeader := TransferHeader;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnInitSourceDocumentHeader', '', false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant);
    var
        TransHeader: Record "Transfer Header";
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransHeader := SourceHeader;
                    TransHeader.Get(TransHeader."No.");
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforeTransferHeaderUpdatePostingDate(TransHeader, WhseShptHeader, WhseShptLine, ModifyHeader, IsHandled);
                    if not IsHandled then
                        if (TransHeader."Posting Date" = 0D) or
                           (TransHeader."Posting Date" <> WhseShptHeader."Posting Date")
                        then begin
                            TransHeader.CalledFromWarehouse(true);
                            TransHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            ModifyHeader := true;
                        end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (TransHeader."Shipment Date" <> WhseShptHeader."Shipment Date")
                    then begin
                        TransHeader."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyHeader := true;
                    end;
                    if WhseShptHeader."External Document No." <> '' then begin
                        TransHeader."External Document No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Code" <> '') and
                       (WhseShptHeader."Shipping Agent Code" <> TransHeader."Shipping Agent Code")
                    then begin
                        TransHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
                        TransHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Service Code" <> '') and
                       (WhseShptHeader."Shipping Agent Service Code" <>
                        TransHeader."Shipping Agent Service Code")
                    then begin
                        TransHeader."Shipping Agent Service Code" :=
                          WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> TransHeader."Shipment Method Code")
                    then begin
                        TransHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(TransHeader, WhseShptHeader, ModifyHeader);
                    if ModifyHeader then
                        TransHeader.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterInitSourceDocumentLines', '', false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
        case WhseShptLine2."Source Type" of
            Database::"Transfer Line":
                HandleTransferLine(WhseShptLine2, WhseShptHeader);
        end;
    end;

    local procedure HandleTransferLine(var WhseShptLine: Record "Warehouse Shipment Line"; var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        TransLine: Record "Transfer Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
        ShouldModifyShipmentDate: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleTransferLine(WhseShptLine, TransLine, WhseShptHeader, ModifyLine, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeHandleTransferLine(WhseShptLine, TransLine, WhseShptHeader, ModifyLine, IsHandled);
#endif
        if IsHandled then
            exit;

        TransLine.SetRange("Document No.", WhseShptLine."Source No.");
        TransLine.SetRange("Derived From Line No.", 0);
        if TransLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", TransLine."Line No.");
                if WhseShptLine.Find('-') then begin
                    IsHandled := false;
                    OnAfterFindWhseShptLineForTransLine(WhseShptLine, TransLine, IsHandled, ModifyLine);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterFindWhseShptLineForTransLine(WhseShptLine, TransLine, IsHandled, ModifyLine);
#endif
                    if not IsHandled then begin
                        ModifyLine := TransLine."Qty. to Ship" <> WhseShptLine."Qty. to Ship";
                        if ModifyLine then
                            ValidateTransferLineQtyToShip(TransLine, WhseShptLine);
                    end;

                    ShouldModifyShipmentDate :=
                      (WhseShptHeader."Shipment Date" <> 0D) and
                      (TransLine."Shipment Date" <> WhseShptHeader."Shipment Date") and
                      (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding");
                    OnHandleTransferLineOnAfterCalcShouldModifyShipmentDate(WhseShptHeader, WhseShptLine, TransLine, ShouldModifyShipmentDate);
#if not CLEAN25
                    WhsePostShipment.RunOnHandleTransferLineOnAfterCalcShouldModifyShipmentDate(WhseShptHeader, WhseShptLine, TransLine, ShouldModifyShipmentDate);
#endif
                    if ShouldModifyShipmentDate then begin
                        TransLine."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyLine := true;
                    end;

                    if TransLine."Transfer-from Bin Code" <> WhseShptLine."Bin Code" then begin
                        TransLine."Transfer-from Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                    end;
                end else begin
                    ModifyLine := TransLine."Qty. to Ship" <> 0;
                    if ModifyLine then begin
                        TransLine.Validate("Qty. to Ship", 0);
                        TransLine.Validate("Qty. to Receive", 0);
                    end;
                end;
                OnBeforeTransLineModify(TransLine, WhseShptLine, ModifyLine);
#if not CLEAN25
                WhsePostShipment.RunOnBeforeTransLineModify(TransLine, WhseShptLine, ModifyLine);
#endif
                if ModifyLine then
                    TransLine.Modify();
            until TransLine.Next() = 0;
    end;

    local procedure ValidateTransferLineQtyToShip(var TransferLine: Record "Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateTransferLineQtyToShip(TransferLine, WarehouseShipmentLine, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeValidateTransferLineQtyToShip(TransferLine, WarehouseShipmentLine, IsHandled);
#endif
        if IsHandled then
            exit;

        TransferLine.Validate("Qty. to Ship", WarehouseShipmentLine."Qty. to Ship");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPostSourceDocument', '', false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer; var SourceHeader: Variant; var DocumentEntryToPrint: Record "Document Entry" temporary; WhsePostParameters: Record "Whse. Post Parameters" temporary)
    var
        TransHeader: Record "Transfer Header";
        WarehouseSetup: Record "Warehouse Setup";
#if not CLEAN25
        DummyTransferShipmentHeader: Record "Transfer Shipment Header";
#endif        
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransHeader := SourceHeader;
                    TransHeader.Get(TransHeader."No.");
                    OnPostSourceDocumentOnBeforeCaseTransferLine(TransHeader, WhseShptLine);
#if not CLEAN25
                    WhsePostShipment.RunOnPostSourceDocumentOnBeforeCaseTransferLine(TransHeader, WhseShptLine);
#endif
                    if WhsePostParameters."Preview Posting" then
                        PostSourceTransferDocument(TransHeader, WhseShptHeader, WhsePostParameters, CounterDocOK)
                    else begin
                        ;
                        WarehouseSetup.Get();
                        case WarehouseSetup."Shipment Posting Policy" of
                            WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                TryPostSourceTransferDocument(TransHeader, WhseShptHeader, WhsePostParameters, CounterDocOK);
                            WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                PostSourceTransferDocument(TransHeader, WhseShptHeader, WhsePostParameters, CounterDocOK);
                        end;
                    end;

                    if WhsePostParameters."Print Documents" then begin
                        IsHandled := false;
                        OnPostSourceDocumentOnBeforePrintTransferShipment(TransHeader, IsHandled);
#if not CLEAN25
                        WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintTransferShipment(DummyTransferShipmentHeader, IsHandled, TransHeader);
#endif                        
                        if not IsHandled then
                            InsertDocumentEntryToPrint(
                                DocumentEntryToPrint, Database::"Transfer Shipment Header", TransHeader."Last Shipment No.");
                    end;

                    OnAfterTransferPostShipment(WhseShptLine, TransHeader, WhsePostParameters);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterTransferPostShipment(WhseShptLine, TransHeader, WhsePostParameters);
#endif
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

    local procedure TryPostSourceTransferDocument(var TransHeader: Record "Transfer Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters"; var CounterSourceDocOK: Integer)
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Clear(TransferOrderPostShipment);
        IsHandled := false;
        OnBeforeTryPostSourceTransferDocument(TransferOrderPostShipment, TransHeader, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeTryPostSourceTransferDocument(TransferOrderPostShipment, TransHeader, IsHandled);
#endif
        if not IsHandled then begin
            Result := false;
            InventorySetup.Get();
            if TransHeader."Direct Transfer" then
                Result := TryPostDirectTransferDocument(TransHeader, WhseShptHeader, WhsePostParameters, CounterSourceDocOK)
            else begin
                TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
                TransferOrderPostShipment.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                if TransferOrderPostShipment.Run(TransHeader) then begin
                    CounterSourceDocOK := CounterSourceDocOK + 1;
                    Result := true;
                end;
            end;
        end;

        OnAfterTryPostSourceTransferDocument(CounterSourceDocOK, TransferOrderPostShipment, TransHeader, Result);
#if not CLEAN25
        WhsePostShipment.RunOnAfterTryPostSourceTransferDocument(CounterSourceDocOK, TransferOrderPostShipment, TransHeader, Result);
#endif
    end;

    local procedure TryPostDirectTransferDocument(var TransHeader: Record "Transfer Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters"; var CounterSourceDocOK: Integer) Posted: Boolean
    begin
        Posted := false;
        case InventorySetup."Direct Transfer Posting" of
            InventorySetup."Direct Transfer Posting"::"Direct Transfer":
                begin
                    Clear(TransferOrderPostTransfer);
                    TransferOrderPostTransfer.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostTransfer.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                    if TransferOrderPostTransfer.Run(TransHeader) then begin
                        CounterSourceDocOK := CounterSourceDocOK + 1;
                        Posted := true;
                    end;
                end;
            InventorySetup."Direct Transfer Posting"::"Receipt and Shipment":
                begin
                    Clear(TransferOrderPostShipment);
                    TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostShipment.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                    if TransferOrderPostShipment.Run(TransHeader) then begin
                        Clear(TransferOrderPostReceipt);
                        TransferOrderPostReceipt.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                        if TransferOrderPostReceipt.Run(TransHeader) then begin
                            CounterSourceDocOK := CounterSourceDocOK + 1;
                            Posted := true;
                        end;
                    end;
                end;
        end;
    end;

    local procedure PostSourceTransferDocument(var TransHeader: Record "Transfer Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters"; var CounterSourceDocOK: Integer)
    var
        IsHandled: Boolean;
    begin
        Clear(TransferOrderPostShipment);
        IsHandled := false;
        OnBeforePostSourceTransferDocument(TransferOrderPostShipment, TransHeader, CounterSourceDocOK, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforePostSourceTransferDocument(TransferOrderPostShipment, TransHeader, CounterSourceDocOK, IsHandled);
#endif
        if IsHandled then
            exit;

        InventorySetup.Get();
        if TransHeader."Direct Transfer" then
            PostSourceDirectTransferDocument(TransHeader, WhseShptHeader, WhsePostParameters, CounterSourceDocOK)
        else begin
            TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
            TransferOrderPostShipment.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
            TransferOrderPostShipment.SetPreviewMode(WhsePostParameters."Preview Posting");
            TransferOrderPostShipment.RunWithCheck(TransHeader);
            CounterSourceDocOK := CounterSourceDocOK + 1;
        end;

        OnAfterPostSourceTransferDocument(CounterSourceDocOK, TransferOrderPostShipment, TransHeader);
#if not CLEAN25
        WhsePostShipment.RunOnAfterPostSourceTransferDocument(CounterSourceDocOK, TransferOrderPostShipment, TransHeader);
#endif
    end;

    local procedure PostSourceDirectTransferDocument(var TransHeader: Record "Transfer Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters"; var CounterSourceDocOK: Integer)
    begin
        case InventorySetup."Direct Transfer Posting" of
            InventorySetup."Direct Transfer Posting"::"Direct Transfer":
                begin
                    Clear(TransferOrderPostTransfer);
                    TransferOrderPostTransfer.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostTransfer.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                    TransferOrderPostTransfer.RunWithCheck(TransHeader);
                    CounterSourceDocOK := CounterSourceDocOK + 1;
                end;
            InventorySetup."Direct Transfer Posting"::"Receipt and Shipment":
                begin
                    Clear(TransferOrderPostShipment);
                    TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostShipment.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                    TransferOrderPostShipment.RunWithCheck(TransHeader);
                    Clear(TransferOrderPostReceipt);
                    TransferOrderPostReceipt.SetSuppressCommit(WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting");
                    TransferOrderPostReceipt.Run(TransHeader);
                    CounterSourceDocOK := CounterSourceDocOK + 1;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPrintDocuments', '', false, false)]
    local procedure OnPrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
        PrintDocuments(DocumentEntryToPrint);
    end;

    local procedure PrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        DocumentEntryToPrint.SetRange("Table ID", Database::"Transfer Shipment Header");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    TransferShipmentHeader.Get(DocumentEntryToPrint."Document No.");
                    TransferShipmentHeader.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            TransferShipmentHeader.MarkedOnly(true);
            TransferShipmentHeader.PrintRecords(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleTransferLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleTransferLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var ShouldModifyShipmentDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineModify(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferLineQtyToShip(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeCaseTransferLine(var TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryPostSourceTransferDocument(var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTryPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceTransferDocument(var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransferHeaderUpdatePostingDate(var TransferHeader: Record "Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(var TransferHeader: Record "Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintTransferShipment(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}
