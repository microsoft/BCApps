// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Posting;

using Microsoft.Foundation.Navigate;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Foundation.AuditCodes;

codeunit 5749 "Serv. Whse Post-Shipment"
{
#if not CLEAN25
    var
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnGetSourceDocumentOnElseCase', '', false, false)]
    local procedure OnGetSourceDocument(var SourceHeader: Variant; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        case WhseShptLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceHeader.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                    SourceHeader := ServiceHeader;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnInitSourceDocumentHeader', '', false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant);
    var
        ServiceHeader: Record "Service Header";
        ReleaseServiceDocument: Codeunit "Release Service Document";
        ValidatePostingDate: Boolean;
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceHeader := SourceHeader;
                    ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(ServiceHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
#if not CLEAN25
                    WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(ServiceHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
#endif
                    if not IsHandled then
                        if (ServiceHeader."Posting Date" = 0D) or (ServiceHeader."Posting Date" <> WhseShptHeader."Posting Date") then begin
                            ReleaseServiceDocument.SetSkipWhseRequestOperations(true);
                            ReleaseServiceDocument.Reopen(ServiceHeader);
                            ServiceHeader.SetHideValidationDialog(true);
                            ServiceHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            ReleaseServiceDocument.Run(ServiceHeader);
                            ServiceHeader.Modify();
                        end;
                    if (WhseShptHeader."Shipping Agent Code" <> '') and
                       (WhseShptHeader."Shipping Agent Code" <> ServiceHeader."Shipping Agent Code")
                    then begin
                        ServiceHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
                        ServiceHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Service Code" <> '') and
                       (WhseShptHeader."Shipping Agent Service Code" <> ServiceHeader."Shipping Agent Service Code")
                    then begin
                        ServiceHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> ServiceHeader."Shipment Method Code")
                    then begin
                        ServiceHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."External Document No." <> '') and
                       (WhseShptHeader."External Document No." <> ServiceHeader."External Document No.")
                    then begin
                        ServiceHeader."External Document No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(ServiceHeader, WhseShptHeader, ModifyHeader);
#if not CLEAN25
                    WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(ServiceHeader, WhseShptHeader, ModifyHeader);
#endif
                    if ModifyHeader then
                        ServiceHeader.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterInitSourceDocumentLines', '', false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters" temporary)
    begin
        case WhseShptLine2."Source Type" of
            Database::"Service Line":
                HandleServiceLine(WhseShptLine2, WhsePostParameters);
        end;
    end;

    local procedure HandleServiceLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters" temporary)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleServiceLine(WhseShptLine, ServiceLine, ModifyLine, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeHandleServiceLine(WhseShptLine, ServiceLine, ModifyLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        ServiceLine.SetRange("Document No.", WhseShptLine."Source No.");
        if ServiceLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", ServiceLine."Line No.");
                if WhseShptLine.Find('-') then begin
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Service Order" then begin
                        ModifyLine := ServiceLine."Qty. to Ship" <> WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            ServiceLine.Validate("Qty. to Ship", WhseShptLine."Qty. to Ship");
                            ServiceLine."Qty. to Ship (Base)" := WhseShptLine."Qty. to Ship (Base)";
                            OnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(ServiceLine, WhseShptLine, WhsePostParameters);
#if not CLEAN25
                            WhsePostShipment.RunOnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(ServiceLine, WhseShptLine, WhsePostParameters."Post Invoice");
#endif
                            if WhsePostParameters."Post Invoice" then begin
                                ServiceLine.Validate("Qty. to Consume", 0);
                                ServiceLine.Validate(
                                  "Qty. to Invoice",
                                  WhseShptLine."Qty. to Ship" + ServiceLine."Quantity Shipped" - ServiceLine."Quantity Invoiced" -
                                  ServiceLine."Quantity Consumed");
                            end;
                        end;
                    end;
                    if ServiceLine."Bin Code" <> WhseShptLine."Bin Code" then begin
                        ServiceLine."Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                    end;
                end else begin
                    ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
                    ModifyLine :=
                      ((ServiceHeader."Shipping Advice" = ServiceHeader."Shipping Advice"::Partial) or
                       (ServiceLine.Type = ServiceLine.Type::Item)) and
                      ((ServiceLine."Qty. to Ship" <> 0) or
                       (ServiceLine."Qty. to Consume" <> 0) or
                       (ServiceLine."Qty. to Invoice" <> 0));
                    OnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(ServiceLine, ModifyLine, WhseShptLine);
#if not CLEAN25
                    WhsePostShipment.RunOnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(ServiceLine, ModifyLine, WhseShptLine);
#endif
                    if ModifyLine then begin
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Service Order" then
                            ServiceLine.Validate("Qty. to Ship", 0);
                        ServiceLine.Validate("Qty. to Invoice", 0);
                        ServiceLine.Validate("Qty. to Consume", 0);
                    end;
                end;
                OnBeforeServiceLineModify(ServiceLine, WhseShptLine, ModifyLine, WhsePostParameters);
#if not CLEAN25
                WhsePostShipment.RunOnBeforeServiceLineModify(ServiceLine, WhseShptLine, ModifyLine, WhsePostParameters);
#endif
                if ModifyLine then
                    ServiceLine.Modify();
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPostSourceDocument', '', false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer; var SourceHeader: Variant; var DocumentEntryToPrint: Record "Document Entry" temporary; WhsePostParameters: Record "Whse. Post Parameters" temporary)
    var
        ServiceHeader: Record "Service Header";
        WarehouseSetup: Record "Warehouse Setup";
        ServicePost: Codeunit "Service-Post";
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceHeader := SourceHeader;
                    ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
                    ServicePost.SetPostingOptions(true, false, WhsePostParameters."Post Invoice");
                    ServicePost.SetSuppressCommit(WhsePostParameters."Suppress Commit");
                    OnPostSourceDocumentBeforeRunServicePost(ServiceHeader);
#if not CLEAN25
                    WhsePostShipment.RunOnPostSourceDocumentBeforeRunServicePost();
#endif
                    WarehouseSetup.Get();
                    case WarehouseSetup."Shipment Posting Policy" of
                        WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                            if ServicePost.Run(ServiceHeader) then
                                CounterDocOK := CounterDocOK + 1;
                        WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                            begin
                                ServicePost.Run(ServiceHeader);
                                CounterDocOK := CounterDocOK + 1;
                            end;
                    end;
                    OnPostSourceDocumentAfterRunServicePost(ServiceHeader);
#if not CLEAN25
                    WhsePostShipment.RunOnPostSourceDocumentAfterRunServicePost();
#endif
                    if WhsePostParameters."Print Documents" then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Service Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintServiceShipment(ServiceHeader, IsHandled);
#if not CLEAN25
                            WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintServiceShipment(ServiceHeader, IsHandled);
#endif
                            if not IsHandled then
                                InsertDocumentEntryToPrint(
                                    DocumentEntryToPrint,
                                    Database::Microsoft.Service.History."Service Shipment Header", ServiceHeader."Last Shipping No.");
                            if WhsePostParameters."Post Invoice" then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintServiceInvoice(ServiceHeader, IsHandled);
#if not CLEAN25
                                WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintServiceInvoice(ServiceHeader, IsHandled);
#endif
                                if not IsHandled then
                                    InsertDocumentEntryToPrint(
                                        DocumentEntryToPrint,
                                        Database::Microsoft.Service.History."Service Invoice Header", ServiceHeader."Last Posting No.");
                            end;
                        end;

                    OnAfterServicePost(WhseShptLine, ServiceHeader, WhsePostParameters);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterServicePost(WhseShptLine, ServiceHeader, WhsePostParameters);
#endif
                    Clear(ServicePost);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPrintDocuments', '', false, false)]
    local procedure OnPrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
        PrintDocuments(DocumentEntryToPrint);
    end;

    local procedure PrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        DocumentEntryToPrint.SetRange("Table ID", Database::"Service Invoice Header");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    ServiceInvoiceHeader.Get(DocumentEntryToPrint."Document No.");
                    ServiceInvoiceHeader.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            ServiceInvoiceHeader.MarkedOnly(true);
            ServiceInvoiceHeader.PrintRecords(false);
        end;

        DocumentEntryToPrint.SetRange("Table ID", Database::"Service Shipment Header");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    ServiceShipmentHeader.Get(DocumentEntryToPrint."Document No.");
                    ServiceShipmentHeader.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            ServiceShipmentHeader.MarkedOnly(true);
            ServiceShipmentHeader.PrintRecords(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentBeforeRunServicePost(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentAfterRunServicePost(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintServiceShipment(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintServiceInvoice(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServicePost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ServiceHeader: Record "Service Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineModify(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ModifyLine: Boolean; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; WhsePosrParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnCreatePostedShptLineOnBeforePostedWhseShptLineInsert', '', false, false)]
    local procedure OnCreatePostedShptLineOnBeforePostedWhseShptLineInsert(var PostedWhseShptLine: Record "Posted Whse. Shipment Line");
    begin
        case PostedWhseShptLine."Source Document" of
            PostedWhseShptLine."Source Document"::"Service Order":
                PostedWhseShptLine."Posted Source Document" := PostedWhseShptLine."Posted Source Document"::"Posted Shipment";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnCreateWhseJnlLineOnSetSourceCode', '', false, false)]
    local procedure OnCreateWhseJnlLineOnSetSourceCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
        case PostedWhseShipmentLine."Source Document" of
            PostedWhseShipmentLine."Source Document"::"Service Order":
                begin
                    WarehouseJournalLine."Source Code" := SourceCodeSetup."Service Management";
                    WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Posted Shipment";
                end;
        end;
    end;
}
