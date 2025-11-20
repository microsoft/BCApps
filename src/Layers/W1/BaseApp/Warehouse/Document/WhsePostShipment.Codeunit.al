// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Tracking;
using System.Utilities;

codeunit 5763 "Whse.-Post Shipment"
{
    Permissions = TableData "Whse. Item Tracking Line" = r,
                  TableData "Posted Whse. Shipment Header" = rim,
                  TableData "Posted Whse. Shipment Line" = ri;
    TableNo = "Warehouse Shipment Line";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(WhsePostParameters."Preview Posting");
        OnBeforeRun(Rec, WhsePostParameters."Suppress Commit", WhsePostParameters."Preview Posting");

        WhseShptLine.Copy(Rec);
        Code();
        Rec := WhseShptLine;

        OnAfterRun(Rec, WhsePostParameters."Preview Posting");
    end;

    var
        WhseRqst: Record "Warehouse Request";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostParameters: Record "Whse. Post Parameters";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        DocumentEntryToPrint: Record "Document Entry";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        WMSMgt: Codeunit "WMS Management";
        GlobalSourceHeader: Variant;
        LastShptNo: Code[20];
        PostingDate: Date;
        CounterSourceDocOK: Integer;
        CounterSourceDocTotal: Integer;
        GenJnlTemplateName: Code[10];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The source document %1 %2 is not released.';
        Text003: Label 'Number of source documents posted: %1 out of a total of %2.';
#pragma warning restore AA0470
        Text004: Label 'Ship lines have been posted.';
        Text005: Label 'Some ship lines remain.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label '%1, %2 %3: you cannot ship more than have been picked for the item tracking lines.';
#pragma warning restore AA0470
        Text007: Label 'is not within your range of allowed posting dates';
#pragma warning restore AA0074
#pragma warning disable AA0470
        FullATONotPostedErr: Label 'Warehouse shipment %1, Line No. %2 cannot be posted, because the full assemble-to-order quantity on the source document line must be shipped first.';
#pragma warning restore AA0470

    local procedure "Code"()
    var
#if not CLEAN25
        SalesHeader: Record Microsoft.Sales.Document."Sales Header";
        PurchHeader: Record Microsoft.Purchases.Document."Purchase Header";
        TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header";
        ServiceHeader: Record Microsoft.Service.Document."Service Header";
#endif
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        NoSeries: Codeunit "No. Series";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
#if not CLEAN25
        SourceRecRef: RecordRef;
#endif
        IsHandled: Boolean;
    begin
        SequenceNoMgt.SetPreviewMode(WhsePostParameters."Preview Posting");
        WhseShptLine.SetCurrentKey(WhseShptLine."No.");
        WhseShptLine.SetRange("No.", WhseShptLine."No.");
        IsHandled := false;
        OnBeforeCheckWhseShptLines(WhseShptLine, WhseShptHeader, WhsePostParameters."Post Invoice", WhsePostParameters."Suppress Commit", IsHandled);
        if IsHandled then
            exit;
        WhseShptLine.SetFilter("Qty. to Ship", '>0');
        OnRunOnAfterWhseShptLineSetFilters(WhseShptLine);
        if WhseShptLine.Find('-') then
            repeat
                WhseShptLine.TestField("Unit of Measure Code");
                CheckShippingAdviceComplete();
                WhseRqst.Get(
                  WhseRqst.Type::Outbound, WhseShptLine."Location Code", WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                CheckDocumentStatus();
                GetLocation(WhseShptLine."Location Code");
                if Location."Require Pick" and (WhseShptLine."Shipping Advice" = WhseShptLine."Shipping Advice"::Complete) then
                    CheckItemTrkgPicked(WhseShptLine);
                if Location."Bin Mandatory" then
                    WhseShptLine.TestField("Bin Code");
                if not WhseShptLine."Assemble to Order" then begin
                    IsHandled := false;
                    OnCodeOnBeforeCheckFullATOPosted(WhseShptLine, IsHandled);
                    if not IsHandled then
                        if not WhseShptLine.FullATOPosted() then
                            Error(FullATONotPostedErr, WhseShptLine."No.", WhseShptLine."Line No.");
                end;

                OnAfterCheckWhseShptLine(WhseShptLine);
            until WhseShptLine.Next() = 0
        else
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        CounterSourceDocOK := 0;
        CounterSourceDocTotal := 0;

        GetLocation(WhseShptLine."Location Code");
        WhseShptHeader.Get(WhseShptLine."No.");
        OnCodeOnAfterGetWhseShptHeader(WhseShptHeader);
        WhseShptHeader.TestField("Posting Date");
        OnAfterCheckWhseShptLines(WhseShptHeader, WhseShptLine, WhsePostParameters."Post Invoice", WhsePostParameters."Suppress Commit");
        if WhseShptHeader."Shipping No." = '' then begin
            WhseShptHeader.TestField("Shipping No. Series");
            WhseShptHeader."Shipping No." :=
              NoSeries.GetNextNo(WhseShptHeader."Shipping No. Series", WhseShptHeader."Posting Date");
        end;

        if not (WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting") then
            Commit();

        WhseShptHeader."Create Posted Header" := true;
        WhseShptHeader.Modify();
        OnCodeOnAfterWhseShptHeaderModify(WhseShptHeader, WhsePostParameters."Print Documents");

        WhseShptLine.SetCurrentKey(WhseShptLine."No.", WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.");
        OnAfterSetCurrentKeyForWhseShptLine(WhseShptLine);
        WhseShptLine.FindSet(true);
        repeat
            WhseShptLine.SetSourceFilter(WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.", -1, false);
            IsHandled := false;
            OnAfterSetSourceFilterForWhseShptLine(WhseShptLine, IsHandled);
            if not IsHandled then begin
                GetSourceDocument(GlobalSourceHeader);
                MakePreliminaryChecks();

                InitSourceDocumentLines(WhseShptLine, GlobalSourceHeader);
                InitSourceDocumentHeader(GlobalSourceHeader);
                if not (WhsePostParameters."Suppress Commit" or WhsePostParameters."Preview Posting") then
                    Commit();

                CounterSourceDocTotal := CounterSourceDocTotal + 1;

#if not CLEAN25
                SourceRecRef.GetTable(GlobalSourceHeader);
                case SourceRecRef.Number of
                    Database::Microsoft.Sales.Document."Sales Header":
                        SalesHeader := GlobalSourceHeader;
                    Database::Microsoft.Purchases.Document."Purchase Header":
                        PurchHeader := GlobalSourceHeader;
                    Database::Microsoft.Inventory.Transfer."Transfer Header":
                        TransHeader := GlobalSourceHeader;
                    Database::Microsoft.Service.Document."Service Header":
                        ServiceHeader := GlobalSourceHeader;
                end;
                OnBeforePostSourceDocument(WhseShptLine, PurchHeader, SalesHeader, TransHeader, ServiceHeader, WhsePostParameters."Suppress Commit");
#endif
                OnBeforePostSourceHeader(WhseShptLine, GlobalSourceHeader, WhsePostParameters);
                PostSourceDocument(WhseShptLine, GlobalSourceHeader);

                if WhseShptLine.FindLast() then;
                WhseShptLine.SetRange(WhseShptLine."Source Type");
                WhseShptLine.SetRange(WhseShptLine."Source Subtype");
                WhseShptLine.SetRange(WhseShptLine."Source No.");
            end;
            OnAfterReleaseSourceForFilterWhseShptLine(WhseShptLine);
        until WhseShptLine.Next() = 0;

        if WhsePostParameters."Preview Posting" then
            GenJnlPostPreview.ThrowError();

        IsHandled := false;
        OnAfterPostWhseShipment(WhseShptHeader, WhsePostParameters."Suppress Commit", IsHandled);
        if not IsHandled then begin
            if not WhsePostParameters."Suppress Commit" or WhsePostParameters."Print Documents" then
                Commit();
            PrintDocuments(DocumentEntryToPrint);
        end;

        Clear(WMSMgt);
        Clear(WhseJnlRegisterLine);

        WhseShptLine.Reset();
    end;

    local procedure CheckDocumentStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentStatus(WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseRqst."Document Status" <> WhseRqst."Document Status"::Released then
            Error(Text000, WhseShptLine."Source Document", WhseShptLine."Source No.");
    end;

    local procedure GetSourceDocument(var SourceHeader: Variant)
    begin
        OnGetSourceDocumentOnElseCase(SourceHeader, WhseShptLine, GenJnlTemplateName);

        OnAfterGetSourceDocument(SourceHeader);
    end;

    local procedure MakePreliminaryChecks()
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(WhseShptHeader."Posting Date", GenJnlTemplateName) then
            WhseShptHeader.FieldError("Posting Date", Text007);
    end;

    local procedure InitSourceDocumentHeader(var SourceHeader: Variant)
    begin
        OnBeforeInitSourceDocumentHeader(WhseShptLine);

        OnInitSourceDocumentHeader(WhseShptHeader, WhseShptLine, SourceHeader, WhsePostParameters);

        OnAfterInitSourceDocumentHeader(WhseShptLine);
    end;

    local procedure InitSourceDocumentLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant)
    var
        WarehouseShipmentLine2: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine2.Copy(WarehouseShipmentLine);

        OnAfterInitSourceDocumentLines(WarehouseShipmentLine2, WhsePostParameters, SourceHeader, WhseShptHeader);

        WarehouseShipmentLine2.SetRange("Source Line No.");
    end;

    local procedure PostSourceDocument(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        OnPostSourceDocumentAfterGetWhseShptHeader(WarehouseShipmentLine, WarehouseShipmentHeader);

        OnPostSourceDocument(WarehouseShipmentHeader, WarehouseShipmentLine, CounterSourceDocOK, SourceHeader, WhsePostParameters, WhsePostParameters."Print Documents", DocumentEntryToPrint);

        OnAfterPostSourceDocument(WarehouseShipmentLine, WhsePostParameters."Print Documents");
    end;

    procedure SetPrint(Print2: Boolean)
    begin
        WhsePostParameters."Print Documents" := Print2;

        OnAfterSetPrint(WhsePostParameters."Print Documents");
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        WhsePostParameters."Preview Posting" := NewPreviewMode;
    end;

    local procedure PrintDocuments(var DocumentEntryToPrint2: Record "Document Entry")
    var
#if not CLEAN25
        SalesInvHeader: Record Microsoft.Sales.History."Sales Invoice Header";
        SalesShptHeader: Record Microsoft.Sales.History."Sales Shipment Header";
        PurchCrMemHeader: Record Microsoft.Purchases.History."Purch. Cr. Memo Hdr.";
        ReturnShptHeader: Record Microsoft.Purchases.History."Return Shipment Header";
        TransShptHeader: Record Microsoft.Inventory.Transfer."Transfer Shipment Header";
        ServiceInvHeader: Record Microsoft.Service.History."Service Invoice Header";
        ServiceShptHeader: Record Microsoft.Service.History."Service Shipment Header";
        IsHandled: Boolean;
#endif
    begin
#if not CLEAN25
        IsHandled := false;
        OnBeforePrintDocuments(SalesInvHeader, SalesShptHeader, PurchCrMemHeader, ReturnShptHeader, TransShptHeader, ServiceInvHeader, ServiceShptHeader, IsHandled);
        if IsHandled then
            exit;
#endif

        OnPrintDocuments(DocumentEntryToPrint2);
    end;

    procedure PostUpdateWhseDocuments(var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    var
        WhseShptLine2: Record "Warehouse Shipment Line";
        DeleteWhseShptLine: Boolean;
    begin
        OnBeforePostUpdateWhseDocuments(WhseShptHeaderParam, TempWarehouseShipmentLine);
        if TempWarehouseShipmentLine.Find('-') then begin
            repeat
                WhseShptLine2.Get(TempWarehouseShipmentLine."No.", TempWarehouseShipmentLine."Line No.");
                DeleteWhseShptLine := TempWarehouseShipmentLine."Qty. Outstanding" = TempWarehouseShipmentLine."Qty. to Ship";
                OnBeforeDeleteUpdateWhseShptLine(WhseShptLine2, DeleteWhseShptLine, TempWarehouseShipmentLine);
                if DeleteWhseShptLine then begin
                    ItemTrackingMgt.SetDeleteReservationEntries(true);
                    ItemTrackingMgt.DeleteWhseItemTrkgLines(
                      Database::"Warehouse Shipment Line", 0, TempWarehouseShipmentLine."No.", '', 0, TempWarehouseShipmentLine."Line No.", TempWarehouseShipmentLine."Location Code", true);
                    WhseShptLine2.Delete();
                    OnPostUpdateWhseDocumentsOnAfterWhseShptLine2Delete(WhseShptLine2);
                end else
                    UpdateWhseShptLine(WhseShptLine2, WhseShptHeaderParam);
            until TempWarehouseShipmentLine.Next() = 0;
            TempWarehouseShipmentLine.DeleteAll();

            OnPostUpdateWhseDocumentsOnAfterWhseShptLineBufLoop(WhseShptHeaderParam, WhseShptLine2, TempWarehouseShipmentLine);
        end;

        OnPostUpdateWhseDocumentsOnBeforeUpdateWhseShptHeader(WhseShptHeaderParam);

        WhseShptLine2.SetRange("No.", WhseShptHeaderParam."No.");
        if WhseShptLine2.IsEmpty() then begin
            WhseShptHeaderParam.DeleteRelatedLines();
            WhseShptHeaderParam.Delete();
        end else begin
            WhseShptHeaderParam."Document Status" := WhseShptHeaderParam.GetShipmentStatus(0);
            if WhseShptHeaderParam."Create Posted Header" then begin
                WhseShptHeaderParam."Last Shipping No." := WhseShptHeaderParam."Shipping No.";
                WhseShptHeaderParam."Shipping No." := '';
                WhseShptHeaderParam."Create Posted Header" := false;
            end;
            OnPostUpdateWhseDocumentsOnBeforeWhseShptHeaderParamModify(WhseShptHeaderParam, WhseShptHeader);
            WhseShptHeaderParam.Modify();
        end;

        OnAfterPostUpdateWhseDocuments(WhseShptHeaderParam);
    end;

    local procedure UpdateWhseShptLine(WhseShptLine2: Record "Warehouse Shipment Line"; var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostUpdateWhseShptLine(WhseShptLine2, TempWarehouseShipmentLine, WhseShptHeaderParam, IsHandled);
        if IsHandled then
            exit;

        WhseShptLine2.Validate("Qty. Shipped", TempWarehouseShipmentLine."Qty. Shipped" + TempWarehouseShipmentLine."Qty. to Ship");
        WhseShptLine2."Qty. Shipped (Base)" := TempWarehouseShipmentLine."Qty. Shipped (Base)" + TempWarehouseShipmentLine."Qty. to Ship (Base)";
        WhseShptLine2.Validate("Qty. Outstanding", TempWarehouseShipmentLine."Qty. Outstanding" - TempWarehouseShipmentLine."Qty. to Ship");
        WhseShptLine2."Qty. Outstanding (Base)" := TempWarehouseShipmentLine."Qty. Outstanding (Base)" - TempWarehouseShipmentLine."Qty. to Ship (Base)";
        WhseShptLine2.Status := WhseShptLine2.GetShipmentLineStatus();
        OnBeforePostUpdateWhseShptLineModify(WhseShptLine2, TempWarehouseShipmentLine);
        WhseShptLine2.Modify();
        OnAfterPostUpdateWhseShptLine(WhseShptLine2, TempWarehouseShipmentLine);
    end;

    procedure GetResultMessage()
    var
        MessageText: Text[250];
        IsHandled: Boolean;
    begin
        MessageText := Text003;
        if CounterSourceDocOK > 0 then
            MessageText := CopyStr(MessageText + '\\' + Text004, 1, MaxStrLen(MessageText));
        if CounterSourceDocOK < CounterSourceDocTotal then
            MessageText := CopyStr(MessageText + '\\' + Text005, 1, MaxStrLen(MessageText));
        IsHandled := false;
        OnGetResultMessageOnBeforeShowMessage(CounterSourceDocOK, CounterSourceDocTotal, IsHandled);
        if not IsHandled then
            Message(MessageText, CounterSourceDocOK, CounterSourceDocTotal);
    end;

    procedure SetPostingSettings(PostInvoice: Boolean)
    begin
        WhsePostParameters."Post Invoice" := PostInvoice;
    end;

    procedure CreatePostedShptHeader(var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var WhseShptHeader2: Record "Warehouse Shipment Header"; LastShptNo2: Code[20]; PostingDate2: Date)
    var
        WhseComment: Record "Warehouse Comment Line";
        WhseComment2: Record "Warehouse Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        LastShptNo := LastShptNo2;
        PostingDate := PostingDate2;

        if not WhseShptHeader2."Create Posted Header" then begin
            PostedWhseShptHeader.Get(WhseShptHeader2."Last Shipping No.");
            exit;
        end;

        if WhseShptHeader2."Shipping No." <> '' then
            if PostedWhseShptHeader.Get(WhseShptHeader2."Shipping No.") then
                exit;

        PostedWhseShptHeader.Init();
        PostedWhseShptHeader."No." := WhseShptHeader2."Shipping No.";
        PostedWhseShptHeader."Location Code" := WhseShptHeader2."Location Code";
        PostedWhseShptHeader."Assigned User ID" := WhseShptHeader2."Assigned User ID";
        PostedWhseShptHeader."Assignment Date" := WhseShptHeader2."Assignment Date";
        PostedWhseShptHeader."Assignment Time" := WhseShptHeader2."Assignment Time";
        PostedWhseShptHeader."No. Series" := WhseShptHeader2."Shipping No. Series";
        PostedWhseShptHeader."Bin Code" := WhseShptHeader2."Bin Code";
        PostedWhseShptHeader."Zone Code" := WhseShptHeader2."Zone Code";
        PostedWhseShptHeader."Posting Date" := WhseShptHeader2."Posting Date";
        PostedWhseShptHeader."Shipment Date" := WhseShptHeader2."Shipment Date";
        PostedWhseShptHeader."Shipping Agent Code" := WhseShptHeader2."Shipping Agent Code";
        PostedWhseShptHeader."Shipping Agent Service Code" := WhseShptHeader2."Shipping Agent Service Code";
        PostedWhseShptHeader."Shipment Method Code" := WhseShptHeader2."Shipment Method Code";
        PostedWhseShptHeader.Comment := WhseShptHeader2.Comment;
        PostedWhseShptHeader."Whse. Shipment No." := WhseShptHeader2."No.";
        PostedWhseShptHeader."External Document No." := WhseShptHeader2."External Document No.";
        OnBeforePostedWhseShptHeaderInsert(PostedWhseShptHeader, WhseShptHeader2);
        PostedWhseShptHeader.Insert();
        RecordLinkManagement.CopyLinks(WhseShptHeader2, PostedWhseShptHeader);
        OnAfterPostedWhseShptHeaderInsert(PostedWhseShptHeader, LastShptNo);

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Shipment");
        WhseComment.SetRange(Type, WhseComment.Type::" ");
        WhseComment.SetRange("No.", WhseShptHeader2."No.");
        if WhseComment.Find('-') then
            repeat
                WhseComment2.Init();
                WhseComment2 := WhseComment;
                WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Whse. Shipment";
                WhseComment2."No." := PostedWhseShptHeader."No.";
                WhseComment2.Insert();
            until WhseComment.Next() = 0;

        OnAfterCreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader2);
    end;

    procedure CreatePostedShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempHandlingSpecification: Record "Tracking Specification")
    begin
        UpdateWhseShptLineBuf(WarehouseShipmentLine);
        PostedWhseShipmentLine.Init();
        PostedWhseShipmentLine.TransferFields(WarehouseShipmentLine);
        PostedWhseShipmentLine."No." := PostedWhseShptHeader."No.";
        OnAfterInitPostedShptLine(WarehouseShipmentLine, PostedWhseShipmentLine);
        PostedWhseShipmentLine.Quantity := WarehouseShipmentLine."Qty. to Ship";
        PostedWhseShipmentLine."Qty. (Base)" := WarehouseShipmentLine."Qty. to Ship (Base)";
        if WhseShptHeader."Shipment Date" <> 0D then
            PostedWhseShipmentLine."Shipment Date" := PostedWhseShptHeader."Shipment Date";
        PostedWhseShipmentLine."Source Type" := WarehouseShipmentLine."Source Type";
        PostedWhseShipmentLine."Source Subtype" := WarehouseShipmentLine."Source Subtype";
        PostedWhseShipmentLine."Source No." := WarehouseShipmentLine."Source No.";
        PostedWhseShipmentLine."Source Line No." := WarehouseShipmentLine."Source Line No.";
        PostedWhseShipmentLine."Source Document" := WarehouseShipmentLine."Source Document";
        case PostedWhseShipmentLine."Source Document" of
            PostedWhseShipmentLine."Source Document"::"Purchase Order":
                PostedWhseShipmentLine."Posted Source Document" := PostedWhseShipmentLine."Posted Source Document"::"Posted Receipt";
            PostedWhseShipmentLine."Source Document"::"Sales Order":
                PostedWhseShipmentLine."Posted Source Document" := PostedWhseShipmentLine."Posted Source Document"::"Posted Shipment";
            PostedWhseShipmentLine."Source Document"::"Purchase Return Order":
                PostedWhseShipmentLine."Posted Source Document" := PostedWhseShipmentLine."Posted Source Document"::"Posted Return Shipment";
            PostedWhseShipmentLine."Source Document"::"Sales Return Order":
                PostedWhseShipmentLine."Posted Source Document" := PostedWhseShipmentLine."Posted Source Document"::"Posted Return Receipt";
            PostedWhseShipmentLine."Source Document"::"Outbound Transfer":
                PostedWhseShipmentLine."Posted Source Document" := PostedWhseShipmentLine."Posted Source Document"::"Posted Transfer Shipment";
        end;
        PostedWhseShipmentLine."Posted Source No." := LastShptNo;
        PostedWhseShipmentLine."Posting Date" := PostingDate;
        PostedWhseShipmentLine."Whse. Shipment No." := WarehouseShipmentLine."No.";
        PostedWhseShipmentLine."Whse Shipment Line No." := WarehouseShipmentLine."Line No.";
        OnCreatePostedShptLineOnBeforePostedWhseShptLineInsert(PostedWhseShipmentLine, WarehouseShipmentLine);
        PostedWhseShipmentLine.Insert();

        OnCreatePostedShptLineOnBeforePostWhseJnlLine(PostedWhseShipmentLine, TempHandlingSpecification, WarehouseShipmentLine);
        PostWhseJnlLine(PostedWhseShipmentLine, TempHandlingSpecification);
        OnAfterPostWhseJnlLine(WarehouseShipmentLine);
    end;

    local procedure UpdateWhseShptLineBuf(WhseShptLine2: Record "Warehouse Shipment Line")
    begin
        TempWarehouseShipmentLine."No." := WhseShptLine2."No.";
        TempWarehouseShipmentLine."Line No." := WhseShptLine2."Line No.";
        if not TempWarehouseShipmentLine.Find() then begin
            TempWarehouseShipmentLine.Init();
            TempWarehouseShipmentLine := WhseShptLine2;
            TempWarehouseShipmentLine.Insert();
        end;
    end;

    local procedure PostWhseJnlLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification")
    var
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(PostedWhseShptLine, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        GetLocation(PostedWhseShptLine."Location Code");
        if Location."Bin Mandatory" then begin
            CreateWhseJnlLine(TempWhseJnlLine, PostedWhseShptLine);
            CheckWhseJnlLine(TempWhseJnlLine);
            OnBeforeRegisterWhseJnlLines(TempWhseJnlLine, PostedWhseShptLine);
            ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
            OnPostWhseJnlLineOnAfterSplitWhseJnlLine(TempWhseJnlLine, PostedWhseShptLine, TempTrackingSpecification, TempWhseJnlLine2);
            if TempWhseJnlLine2.Find('-') then
                repeat
                    WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                until TempWhseJnlLine2.Next() = 0;
        end;

        OnAfterPostWhseJnlLines(TempWhseJnlLine, PostedWhseShptLine, TempTrackingSpecification, WhseJnlRegisterLine);
    end;

    local procedure CheckWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLine(TempWhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 0, 0, false);
    end;

    procedure CreateWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        WhseJnlLine.Init();
        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
        WhseJnlLine."Location Code" := PostedWhseShipmentLine."Location Code";
        WhseJnlLine."From Zone Code" := PostedWhseShipmentLine."Zone Code";
        WhseJnlLine."From Bin Code" := PostedWhseShipmentLine."Bin Code";
        WhseJnlLine."Item No." := PostedWhseShipmentLine."Item No.";
        WhseJnlLine.Description := PostedWhseShipmentLine.Description;
        WhseJnlLine."Qty. (Absolute)" := PostedWhseShipmentLine.Quantity;
        WhseJnlLine."Qty. (Absolute, Base)" := PostedWhseShipmentLine."Qty. (Base)";
        WhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseJnlLine."User ID"));
        WhseJnlLine."Variant Code" := PostedWhseShipmentLine."Variant Code";
        WhseJnlLine."Unit of Measure Code" := PostedWhseShipmentLine."Unit of Measure Code";
        WhseJnlLine."Qty. per Unit of Measure" := PostedWhseShipmentLine."Qty. per Unit of Measure";
        WhseJnlLine.SetSource(
            PostedWhseShipmentLine."Source Type", PostedWhseShipmentLine."Source Subtype", PostedWhseShipmentLine."Source No.",
            PostedWhseShipmentLine."Source Line No.", 0);
        WhseJnlLine."Source Document" := PostedWhseShipmentLine."Source Document";
        WhseJnlLine.SetWhseDocument(
            WhseJnlLine."Whse. Document Type"::Shipment, PostedWhseShipmentLine."No.", PostedWhseShipmentLine."Line No.");
        GetItemUnitOfMeasure2(PostedWhseShipmentLine."Item No.", PostedWhseShipmentLine."Unit of Measure Code");
        WhseJnlLine.Cubage := WhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Cubage;
        WhseJnlLine.Weight := WhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Weight;
        WhseJnlLine."Reference No." := LastShptNo;
        WhseJnlLine."Registering Date" := PostingDate;
        WhseJnlLine."Registering No. Series" := WhseShptHeader."Shipping No. Series";
        SourceCodeSetup.Get();
        case PostedWhseShipmentLine."Source Document" of
            PostedWhseShipmentLine."Source Document"::"Purchase Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rcpt.";
                end;
            PostedWhseShipmentLine."Source Document"::"Sales Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Shipment";
                end;
            PostedWhseShipmentLine."Source Document"::"Purchase Return Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                end;
            PostedWhseShipmentLine."Source Document"::"Sales Return Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                end;
            PostedWhseShipmentLine."Source Document"::"Outbound Transfer":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Shipment";
                end;
            else
                OnCreateWhseJnlLineOnSetSourceCode(WhseJnlLine, PostedWhseShipmentLine, SourceCodeSetup);
        end;

        OnAfterCreateWhseJnlLine(WhseJnlLine, PostedWhseShipmentLine);
    end;

    local procedure GetItemUnitOfMeasure2(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if LocationCode <> Location.Code then
                Location.Get(LocationCode);
    end;

    local procedure CheckItemTrkgPicked(WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        ReservationEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
        if WarehouseShipmentLine."Assemble to Order" then
            exit;

        IsHandled := false;
        OnCheckItemTrkgPickedOnBeforeGetWhseItemTrkgSetup(WarehouseShipmentLine, IsHandled);
        if IsHandled then
            exit;

        if not ItemTrackingMgt.GetWhseItemTrkgSetup(WarehouseShipmentLine."Item No.") then
            exit;

        ReservationEntry.SetSourceFilter(
          WarehouseShipmentLine."Source Type", WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.", true);
        if ReservationEntry.Find('-') then
            repeat
                if ReservationEntry.TrackingExists() then begin
                    QtyPickedBase := 0;
                    WhseItemTrkgLine.SetTrackingKey();
                    WhseItemTrkgLine.SetTrackingFilterFromReservEntry(ReservationEntry);
                    WhseItemTrkgLine.SetSourceFilter(Database::"Warehouse Shipment Line", -1, WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.", false);
                    if WhseItemTrkgLine.Find('-') then
                        repeat
                            QtyPickedBase := QtyPickedBase + WhseItemTrkgLine."Qty. Registered (Base)";
                        until WhseItemTrkgLine.Next() = 0;
                    if QtyPickedBase < Abs(ReservationEntry."Qty. to Handle (Base)") then
                        Error(Text006,
                          WarehouseShipmentLine."No.", WarehouseShipmentLine.FieldCaption("Line No."), WarehouseShipmentLine."Line No.");
                end;
            until ReservationEntry.Next() = 0;
    end;

    local procedure CheckShippingAdviceComplete()
    var
        IsHandled: Boolean;
    begin
        // shipping advice check is performed when posting a source document
        IsHandled := false;
        OnBeforeCheckShippingAdviceComplete(WhseShptLine, IsHandled);
        if IsHandled then
            exit;
    end;

    procedure SetWhseJnlRegisterCU(var NewWhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        WhseJnlRegisterLine := NewWhseJnlRegisterLine;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        WhsePostParameters."Suppress Commit" := NewSuppressCommit;
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
    local procedure OnAfterGetSourceDocument(SourceHeader: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceDocument(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Print: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SuppressCommit: Boolean; PreviewMode: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeValidateTransferLineQtyToShip(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
        OnBeforeValidateTransferLineQtyToShip(TransferLine, WarehouseShipmentLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferLineQtyToShip(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseShptLines(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedShptHeader(var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterFindWhseShptLineForSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterFindWhseShptLineForSalesLine(WarehouseShipmentLine, SalesLine);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterFindWhseShptLineForPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnAfterFindWhseShptLineForPurchLine(WarehouseShipmentLine, PurchaseLine);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterFindWhseShptLineForTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ModifyLine: Boolean)
    begin
        OnAfterFindWhseShptLineForTransLine(WarehouseShipmentLine, TransferLine, IsHandled, ModifyLine);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ModifyLine: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentHeader(var WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedShptLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterHandlePurchaseLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnAfterHandlePurchaseLine(WhseShipmentLine, PurchHeader, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterHandlePurchaseLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; var Invoice: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterHandleSalesLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnAfterHandleSalesLine(WhseShipmentLine, SalesHeader, WhsePostParameters2."Post Invoice", WarehouseShipmentHeader);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleSalesLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var Invoice: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseShptHeaderInsert(PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; LastShptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; WhseJnlRegisterLine: codeunit "Whse. Jnl.-Register Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentLineBuf: Record "Warehouse Shipment Line"; var WhseShptHeaderParam: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WhseShptLineBuf: Record "Warehouse Shipment Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TempWarehouseShipmentLineBuffer: Record "Warehouse Shipment Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseDocuments(var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterPurchPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; WhsePostParameters2: Record "Whse. Post Parameters"; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        OnAfterPurchPost(WarehouseShipmentLine, PurchaseHeader, WhsePostParameters2."Post Invoice", WhseShptHeader2);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; Invoice: Boolean; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterSalesPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnAfterSalesPost(WarehouseShipmentLine, SalesHeader, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header"; Invoice: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterServicePost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnAfterServicePost(WarehouseShipmentLine, ServiceHeader, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterServicePost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; Invoice: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferPostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnAfterTransferPostShipment(WarehouseShipmentLine, TransferHeader, WhsePostParameters2."Suppress Commit");
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; SuppressCommit: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShippingAdviceComplete(var WhseShptLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforePurchLineModify(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnBeforePurchLineModify(PurchaseLine, WarehouseShipmentLine, ModifyLine, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineModify(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeSalesLineModify(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; WhsePostParameters2: Record "Whse. Post Parameters"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        OnBeforeSalesLineModify(SalesLine, WarehouseShipmentLine, ModifyLine, WhsePostParameters2."Post Invoice", WarehouseShipmentHeader);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeTransLineModify(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
        OnBeforeTransLineModify(TransferLine, WarehouseShipmentLine, ModifyLine);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineModify(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforePurchHeaderModify(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
        OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(PurchaseHeader, WarehouseShipmentHeader, ModifyHeader);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean; WhsePostParameters2: Record "Whse. Post Parameters"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(SalesHeader, WarehouseShipmentHeader, ModifyHeader, WhsePostParameters2."Post Invoice", WarehouseShipmentLine);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean; Invoice: Boolean; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
        OnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(ServiceHeader, WarehouseShipmentHeader, ModifyHeader);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(var TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
        OnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(PurchaseHeader, WarehouseShipmentHeader, WarehouseShipmentLine, ModifyHeader, ValidatePostingDate, IsHandled);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransferHeaderUpdatePostingDate(var TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
        OnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(ServiceHeader, WarehouseShipmentHeader, WarehouseShipmentLine, ModifyHeader, ValidatePostingDate, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer; var SourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters"; Print: Boolean; var DocumentEntryToPrint: Record "Document Entry")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforeCaseTransferLine(TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        OnPostSourceDocumentOnBeforeCaseTransferLine(TransferHeader, WarehouseShipmentLine);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeCaseTransferLine(TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteUpdateWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line"; var DeleteWhseShptLine: Boolean; var WhseShptLineBuf: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSourceDocumentHeader(var WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseShptHeaderInsert(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentStatus(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Invoice: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeHandlePurchaseLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; WhseShptHeader2: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnBeforeHandlePurchaseLine(WarehouseShipmentLine, PurchLine, WhseShptHeader2, ModifyLine, IsHandled, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandlePurchaseLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; Invoice: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeHandleSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WhseShptHeader2: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnBeforeHandleSalesLine(WarehouseShipmentLine, SalesLine, SalesHeader, WhseShptHeader2, ModifyLine, IsHandled, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; Invoice: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeHandleTransferLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WhseShptHeader2: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeHandleTransferLine(WarehouseShipmentLine, TransLine, WhseShptHeader2, ModifyLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleTransferLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforePostSourceHeader', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; SuppressCommit: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceHeader(var WhseShptLine: Record "Warehouse Shipment Line"; GlobalSourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseDocuments(var WhseShptHeader: Record "Warehouse Shipment Header"; var TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforePostSourcePurchDocument(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
        OnBeforePostSourcePurchDocument(PurchPost, PurchHeader);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourcePurchDocument(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforePostSourceTransferDocument(var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var CounterSourceDocOK2: Integer; var IsHandled: Boolean)
    begin
        OnBeforePostSourceTransferDocument(TransferPostShipment, TransHeader, CounterSourceDocOK2, IsHandled);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceTransferDocument(var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeTryPostSourcePurchDocument(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
        OnBeforeTryPostSourcePurchDocument(PurchPost, PurchHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryPostSourcePurchDocument(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeTryPostSourceTransferDocument(var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var IsHandled: Boolean)
    begin
        OnBeforeTryPostSourceTransferDocument(TransferPostShipment, TransHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryPostSourceTransferDocument(var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeUpdateSaleslineQtyToShip(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var WhseShptLine2: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal; var IsHandled: Boolean)
    begin
        OnBeforeUpdateSaleslineQtyToShip(SalesLine, WhseShptLine2, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase, IsHandled);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSaleslineQtyToShip(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedShptLineOnBeforePostWhseJnlLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedShptLineOnBeforePostedWhseShptLineInsert(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGetWhseShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterWhseShptHeaderModify(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Print: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WhsePostParameters2: Record "Whse. Post Parameters"; var NewCalledFromWhseDoc: Boolean)
    begin
        OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(SalesHeader, WhsePostParameters2."Post Invoice", NewCalledFromWhseDoc);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; Invoice: Boolean; var NewCalledFromWhseDoc: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var WhseShptHeader2: Record "Warehouse Shipment Header"; var WhseShptLine2: Record "Warehouse Shipment Line")
    begin
        OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(SalesHeader, WhseShptHeader2, WhseShptLine2);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeValidatePostingDate(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ValidatePostingDate: Boolean; var IsHandled: Boolean; var ModifyHeader: Boolean; var WhseShptHeader2: Record "Warehouse Shipment Header");
    begin
        OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(SalesHeader, WarehouseShipmentLine, ValidatePostingDate, IsHandled, ModifyHeader, WhseShptHeader2);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ValidatePostingDate: Boolean; var IsHandled: Boolean; var ModifyHeader: Boolean; var WhseShptHeader: Record "Warehouse Shipment Header");
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleSalesLineOnAfterValidateRetQtytoReceive(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var WhseShptLine2: Record "Warehouse Shipment Line"; WhsePostParameters2: Record "Whse. Post Parameters");
    begin
        OnHandleSalesLineOnAfterValidateRetQtytoReceive(SalesLine, WhseShptLine2, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterValidateRetQtytoReceive(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean);
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ShouldModifyShipmentDate: Boolean)
    begin
        OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader, WarehouseShipmentLine, SalesLine, ShouldModifyShipmentDate);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ShouldModifyShipmentDate: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleSalesLineOnAfterSalesLineModify(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; ModifyLine: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        OnHandleSalesLineOnAfterSalesLineModify(SalesLine, ModifyLine, WarehouseShipmentHeader);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterSalesLineModify(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; ModifyLine: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var ModifyLine: Boolean);
    begin
        OnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(PurchLine, ModifyLine);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var ModifyLine: Boolean);
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandlePurchaseLineOnAfterValidateQtytoReceive(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var WhseShptLine2: Record "Warehouse Shipment Line");
    begin
        OnHandlePurchaseLineOnAfterValidateQtytoReceive(PurchLine, WhseShptLine2);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchaseLineOnAfterValidateQtytoReceive(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandlePurchaseLineOnAfterValidateRetQtytoShip(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var WhseShptLine2: Record "Warehouse Shipment Line");
    begin
        OnHandlePurchaseLineOnAfterValidateRetQtytoShip(PurchLine, WhseShptLine2);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchaseLineOnAfterValidateRetQtytoShip(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintSalesInvoice(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var IsHandled: Boolean; var WhseShptLine2: Record "Warehouse Shipment Line")
    begin
        OnPostSourceDocumentOnBeforePrintSalesInvoice(SalesHeader, IsHandled, WhseShptLine2);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesInvoice(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var IsHandled: Boolean; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintSalesShipment(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var IsHandled: Boolean; var SalesShptHeader: Record Microsoft.Sales.History."Sales Shipment Header"; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        OnPostSourceDocumentOnBeforePrintSalesShipment(SalesHeader, IsHandled, SalesShptHeader, WhseShptHeader2);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesShipment(var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var IsHandled: Boolean; var SalesShptHeader: Record Microsoft.Sales.History."Sales Shipment Header"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintPurchReturnShipment(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforePrintPurchReturnShipment(PurchaseHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchReturnShipment(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintPurchCreditMemo(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforePrintPurchCreditMemo(PurchaseHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchCreditMemo(var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintTransferShipment(var TransferShipmentHeader: Record Microsoft.Inventory.Transfer."Transfer Shipment Header"; var IsHandled: Boolean; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
        OnPostSourceDocumentOnBeforePrintTransferShipment(TransferShipmentHeader, IsHandled, TransHeader);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintTransferShipment(var Transfer: Record Microsoft.Inventory.Transfer."Transfer Shipment Header"; var IsHandled: Boolean; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintServiceInvoice(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforePrintServiceInvoice(ServiceHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintServiceInvoice(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintServiceShipment(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforePrintServiceShipment(ServiceHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintServiceShipment(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnAfterWhseShptLine2Delete(var WhseShptLine2: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeUpdateWhseShptHeader(var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrentKeyForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrint(var Print: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSourceForFilterWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnAfterSalesPost(var CounterDocOK: Integer; var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; Result: Boolean)
    begin
        OnPostSourceDocumentOnAfterSalesPost(CounterDocOK, SalesPost, SalesHeader, Result);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; Result: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforeSalesPost(var CounterDocOK: Integer; var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforeSalesPost(CounterDocOK, SalesPost, SalesHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePrintSalesDocuments(LastShippingNo: Code[20])
    begin
        OnPostSourceDocumentOnBeforePrintSalesDocuments(LastShippingNo);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesDocuments(LastShippingNo: Code[20])
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPrintDocumentsOnAfterPrintSalesShipment(ShipmentNo: Code[20])
    begin
        OnPrintDocumentsOnAfterPrintSalesShipment(ShipmentNo);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterPrintSalesShipment(ShipmentNo: Code[20])
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPrintDocumentsOnAfterPrintServiceShipment(ServiceShipmentNo: Code[20])
    begin
        OnPrintDocumentsOnAfterPrintServiceShipment(ServiceShipmentNo);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterPrintServiceShipment(ServiceShipmentNo: Code[20])
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(var WhseShptLine2: Record "Warehouse Shipment Line"; var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
        OnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(WhseShptLine2, PurchaseHeader);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePostSalesHeader(var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WhseShptHeader2: Record "Warehouse Shipment Header"; var CounterSourceDocOK2: Integer; var WhsePostParameters2: Record "Whse. Post Parameters"; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforePostSalesHeader(SalesPost, SalesHeader, WhseShptHeader2, CounterSourceDocOK2, WhsePostParameters2."Suppress Commit", IsHandled, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostSalesHeader(var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; SuppressCommit: Boolean; var IsHandled: Boolean; var Invoice: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeWhseShptHeaderParamModify(var WhseShptHeaderParam: Record "Warehouse Shipment Header"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResultMessageOnBeforeShowMessage(var CounterSourceDocOK: Integer; var CounterSourceDocTotal: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocumentOnElseCase(var SourceHeader: Variant; var WhseShptLine: Record "Warehouse Shipment Line"; var GenJnlTemplateName: Code[10])
    begin
    end;

#if not CLEAN25
    internal procedure RunOnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ModifyLine: Boolean; WhseShptLine2: Record "Warehouse Shipment Line")
    begin
        OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(SalesLine, ModifyLine, WhseShptLine2);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ModifyLine: Boolean; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleSalesLineOnBeforeSalesLineFind(var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnHandleSalesLineOnBeforeSalesLineFind(SalesLine);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnBeforeSalesLineFind(var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; WhseShptLine2: Record "Warehouse Shipment Line"; WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(SalesLine, WhseShptLine2, WhsePostParameters2."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters"; var SourceHeader: Variant; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentAfterGetWhseShptHeader(var WhseShptLine: Record "Warehouse Shipment Line"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforePostSourceSalesDocument(var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post")
    begin
        OnBeforePostSourceSalesDocument(SalesPost);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnAfterWhseShptLineBufLoop(var WhseShptHeaderParam: Record "Warehouse Shipment Header"; WhseShptLine2: Record "Warehouse Shipment Line"; WhseShptLineBuf: Record "Warehouse Shipment Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterPostSourceSalesDocument(var CounterDocOK: Integer; var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    begin
        OnAfterPostSourceSalesDocument(CounterDocOK, SalesPost, SalesHeader);
    end;

    [Obsolete('Moved to codeunit Sales Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceSalesDocument(var CounterSourceDocOK: Integer; var SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTryPostSourcePurchDocument(var CounterSourceDocOK2: Integer; var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; Result: Boolean)
    begin
        OnAfterTryPostSourcePurchDocument(CounterSourceDocOK2, PurchPost, PurchHeader, Result);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTryPostSourcePurchDocument(var CounterSourceDocOK: Integer; var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; Result: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterPostSourcePurchDocument(var CounterSourceDocOK2: Integer; var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
        OnAfterPostSourcePurchDocument(CounterSourceDocOK2, PurchPost, PurchHeader);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourcePurchDocument(var CounterSourceDocOK: Integer; var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTryPostSourceTransferDocument(var CounterSourceDocOK2: Integer; var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; Result: Boolean)
    begin
        OnAfterTryPostSourceTransferDocument(CounterSourceDocOK2, TransferPostShipment, TransHeader, Result);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTryPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header"; Result: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterPostSourceTransferDocument(var CounterSourceDocOK2: Integer; var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
        OnAfterPostSourceTransferDocument(CounterSourceDocOK2, TransferPostShipment, TransHeader);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit Microsoft.Inventory.Transfer."TransferOrder-Post Shipment"; var TransHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnAfterSplitWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification"; var TempWhseJnlLine2: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrkgPickedOnBeforeGetWhseItemTrkgSetup(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentOnBeforePostPurchHeader(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; WhsePostParameters2: Record "Whse. Post Parameters"; WhseShptHeader2: Record "Warehouse Shipment Header"; var CounterSourceDocOK2: Integer; var IsHandled: Boolean)
    begin
        OnPostSourceDocumentOnBeforePostPurchHeader(PurchPost, PurchHeader, WhseShptHeader2, CounterSourceDocOK2, IsHandled, WhsePostParameters2."Suppress Commit");
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostPurchHeader(var PurchPost: Codeunit Microsoft.Purchases.Posting."Purch.-Post"; var PurchHeader: Record Microsoft.Purchases.Document."Purchase Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean; SuppressCommit: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeServiceLineModify(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; var WhsePostParameters2: Record "Whse. Post Parameters")
    begin
        OnBeforeServiceLineModify(ServiceLine, WarehouseShipmentLine, ModifyLine, WhsePostParameters2."Post Invoice", WhsePostParameters."Post Invoice");
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineModify(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean; var InvoiceService: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentBeforeRunServicePost()
    begin
        OnPostSourceDocumentBeforeRunServicePost();
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentBeforeRunServicePost()
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnPostSourceDocumentAfterRunServicePost()
    begin
        OnPostSourceDocumentAfterRunServicePost();
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentAfterRunServicePost()
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ModifyLine: Boolean; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        OnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(ServiceLine, ModifyLine, WarehouseShipmentLine);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ModifyLine: Boolean; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Not used anymore.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocuments(var SalesInvoiceHeader: Record Microsoft.Sales.History."Sales Invoice Header"; var SalesShipmentHeader: Record Microsoft.Sales.History."Sales Shipment Header"; var PurchCrMemoHdr: Record Microsoft.Purchases.History."Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record Microsoft.Purchases.History."Return Shipment Header"; var TransferShipmentHeader: Record Microsoft.Inventory.Transfer."Transfer Shipment Header"; var ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header"; var ServiceShipmentHeader: Record Microsoft.Service.History."Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var InvoiceService: Boolean)
    begin
        OnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(ServiceLine, WarehouseShipmentLine, InvoiceService);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var InvoiceService: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterWhseShptLineSetFilters(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeHandleServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeHandleServiceLine(WarehouseShipmentLine, ServiceLine, ModifyLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandlePurchLineOnAfterCalcShouldModifyExpectedReceiptDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var ShouldModifyExpectedReceiptDate: Boolean)
    begin
        OnHandlePurchLineOnAfterCalcShouldModifyExpectedReceiptDate(WarehouseShipmentHeader, WarehouseShipmentLine, PurchaseLine, ShouldModifyExpectedReceiptDate);
    end;

    [Obsolete('Moved to codeunit Purch. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchLineOnAfterCalcShouldModifyExpectedReceiptDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var ShouldModifyExpectedReceiptDate: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnHandleTransferLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var ShouldModifyShipmentDate: Boolean)
    begin
        OnHandleTransferLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader, WarehouseShipmentLine, TransferLine, ShouldModifyShipmentDate);
    end;

    [Obsolete('Moved to codeunit Trans. Whse. Post Shipment', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnHandleTransferLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var ShouldModifyShipmentDate: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckFullATOPosted(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineOnSetSourceCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}

