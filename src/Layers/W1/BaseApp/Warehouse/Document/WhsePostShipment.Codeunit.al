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

        OnAfterRun(Rec, WhsePostParameters."Preview Posting", WhsePostParameters."Suppress Commit");
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
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        NoSeries: Codeunit "No. Series";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        IsHandled: Boolean;
    begin
        SequenceNoMgt.SetPreviewMode(WhsePostParameters."Preview Posting");
        WhseShptLine.SetCurrentKey(WhseShptLine."No.");
        WhseShptLine.SetRange("No.", WhseShptLine."No.");
        IsHandled := false;
        OnBeforeCheckWhseShptLines(WhseShptLine, WhseShptHeader, WhsePostParameters."Post Invoice", WhsePostParameters."Suppress Commit", IsHandled, WhsePostParameters."Preview Posting");
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
    begin

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
    local procedure OnAfterRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
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




    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentHeader(var WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedShptLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;



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





    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShippingAdviceComplete(var WhseShptLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;




    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;








    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer; var SourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters"; Print: Boolean; var DocumentEntryToPrint: Record "Document Entry")
    begin
    end;


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
    local procedure OnBeforeCheckWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Invoice: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean; PreviewPosting: Boolean)
    begin
    end;

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



    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
    end;




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




    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters"; var SourceHeader: Variant; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentAfterGetWhseShptHeader(var WhseShptLine: Record "Warehouse Shipment Line"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnAfterWhseShptLineBufLoop(var WhseShptHeaderParam: Record "Warehouse Shipment Header"; WhseShptLine2: Record "Warehouse Shipment Line"; WhseShptLineBuf: Record "Warehouse Shipment Line")
    begin
    end;






    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnAfterSplitWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification"; var TempWhseJnlLine2: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrkgPickedOnBeforeGetWhseItemTrkgSetup(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;








    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterWhseShptLineSetFilters(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;




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
