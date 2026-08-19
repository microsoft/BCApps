// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.TimeSheet;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using System.Utilities;

codeunit 5818 "Undo Service Shipment Line"
{
    Permissions = TableData "Item Application Entry" = rmd,
                  TableData "Service Line" = rimd,
                  TableData "Service Ledger Entry" = ri,
                  TableData "Warranty Ledger Entry" = rim,
                  TableData "Service Shipment Line" = rimd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Service Shipment Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        ConfMessage: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Rec.Find('-') then
            exit;

        ConfMessage := Text000;

        if CheckComponentsAdjusted(Rec) then
            ConfMessage :=
              StrSubstNo(Text004, Rec.FieldCaption("Service Item No."), Format(Rec."Service Item No.")) +
              Text000;

        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(ConfMessage, true) then
                exit;

        Rec.LockTable();
        ServShptLine.Copy(Rec);
        Code();
        Rec := ServShptLine;
    end;

    var
        ServShptLine: Record "Service Shipment Line";
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ServUndoPostingMgt: Codeunit "Serv. Undo Posting Mgt.";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
#pragma warning disable AA0074
        Text000: Label 'Do you want to undo the selected shipment line(s)?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
#pragma warning restore AA0074
        NextLineNo: Integer;
        HideDialog: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'The component list for %1 %2 was changed. You may need to adjust the list manually.\';
#pragma warning restore AA0470
        Text005: Label 'Some shipment lines may have unused service items. Do you want to delete them?';
#pragma warning restore AA0074
        AlreadyReversedErr: Label 'This service shipment has already been reversed.';

    local procedure CheckComponentsAdjusted(var ServiceShptLine: Record "Service Shipment Line"): Boolean
    var
        LocalServShptLine: Record "Service Shipment Line";
    begin
        LocalServShptLine.Copy(ServiceShptLine);
        LocalServShptLine.SetFilter("Spare Part Action", '%1|%2',
            LocalServShptLine."Spare Part Action"::"Component Replaced", LocalServShptLine."Spare Part Action"::"Component Installed");
        LocalServShptLine.SetFilter(LocalServShptLine."Service Item No.", '<>%1', '');
        OnCheckComponentsAdjustedOnAfterLocalServShptLineSetFilters(LocalServShptLine);
        exit(not LocalServShptLine.IsEmpty);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        ServiceLine: Record "Service Line";
        ServItem: Record "Service Item";
        ServLedgEntriesPost: Codeunit "ServLedgEntries-Post";
        ConfirmManagement: Codeunit "Confirm Management";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        ServLedgEntryNo: Integer;
        WarrantyLedgEntryNo: Integer;
        DeleteServItems: Boolean;
        PostedWhseShptLineFound: Boolean;
    begin
        Clear(ItemJnlPostLine);
        ServShptLine.SetRange(Correction, false);
        ServShptLine.FindFirst();
        repeat
            if not HideDialog then
                Window.Open(Text003);
            CheckServShptLine(ServShptLine);
        until ServShptLine.Next() = 0;

        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", ServShptLine."Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Line No.", ServShptLine."Line No.");
        ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Service);
        if not ServItem.IsEmpty() then
            if not HideDialog then
                DeleteServItems := ConfirmManagement.GetResponseOrDefault(Text005, true)
            else
                DeleteServItems := true;

        ServLedgEntriesPost.InitServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);
        ServShptLine.Find('-');
        repeat
            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty() then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(Text001);

            PostedWhseShptLineFound :=
                WhseUndoQty.FindPostedWhseShptLine(
                    PostedWhseShptLine, DATABASE::"Service Shipment Line", ServShptLine."Document No.",
                    DATABASE::"Service Line", ServiceLine."Document Type"::Order.AsInteger(), ServShptLine."Order No.", ServShptLine."Order Line No.");

            if ServShptLine.Type = ServShptLine.Type::Item then
                ItemShptEntryNo := PostItemJnlLine(ServShptLine)
            else
                ItemShptEntryNo := GetCorrectionLineNo(ServShptLine);

            if ServShptLine.Type = ServShptLine.Type::Resource then
                PostResJnlLine(ServShptLine);

            InsertNewShipmentLine(ServShptLine, ItemShptEntryNo);
            OnAfterInsertNewShipmentLine(ServShptLine, PostedWhseShptLine, PostedWhseShptLineFound);

            if PostedWhseShptLineFound then
                WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

            ServLedgEntriesPost.ReverseServLedgEntry(ServShptLine);
            if ServShptLine.Type in [ServShptLine.Type::Item, ServShptLine.Type::Resource] then
                ServLedgEntriesPost.ReverseWarrantyEntry(ServShptLine);

            UpdateOrderLine(ServShptLine);
            if PostedWhseShptLineFound then
                WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

            if DeleteServItems then
                DeleteServShptLineServItems(ServShptLine);

            ServShptLine."Quantity Invoiced" := ServShptLine.Quantity;
            ServShptLine."Qty. Invoiced (Base)" := ServShptLine."Quantity (Base)";
            ServShptLine."Qty. Shipped Not Invoiced" := 0;
            ServShptLine."Qty. Shipped Not Invd. (Base)" := 0;
            ServShptLine.Correction := true;
            OnCodeOnBeforeServShptLineModify(ServShptLine, TempWhseJnlLine);
            ServShptLine.Modify();
            OnCodeOnAfterServShptLineModify(ServShptLine, TempWhseJnlLine);
        until ServShptLine.Next() = 0;
        ServLedgEntriesPost.FinishServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);

        MakeInventoryAdjustment();

        WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);

        OnAfterCode(ServShptLine);
    end;

    local procedure GetCorrectiveShptLineNoStep(DocumentNo: Code[20]; LineNo: Integer) LineSpacing: Integer
    var
        TestServShptLine: Record "Service Shipment Line";
    begin
        TestServShptLine.SetRange("Document No.", DocumentNo);
        TestServShptLine."Document No." := DocumentNo;
        TestServShptLine."Line No." := LineNo;
        TestServShptLine.Find('=');

        if TestServShptLine.Find('>') then begin
            LineSpacing := (TestServShptLine."Line No." - LineNo) div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;
    end;

    local procedure CheckServShptLine(var ServShptLine: Record "Service Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServShptLine(ServShptLine, IsHandled);
        if IsHandled then
            exit;

        ServShptLine.TestField(Quantity);
        ServShptLine.TestField("Qty. Shipped Not Invoiced", ServShptLine.Quantity);
        if ServShptLine.Correction then
            Error(AlreadyReversedErr);
        ServUndoPostingMgt.TestServShptLine(ServShptLine);
        if ServShptLine.Type = ServShptLine.Type::Item then begin
            UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Service Shipment Line",
              ServShptLine."Document No.", ServShptLine."Line No.", ServShptLine."Quantity (Base)", ServShptLine."Item Shpt. Entry No.");
            UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, ServShptLine."Line No.");
        end;
    end;

    procedure GetCorrectionLineNo(ServiceShipmentLine2: Record "Service Shipment Line") Result: Integer;
    var
        ServiceShipmentLine3: Record "Service Shipment Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(ServiceShipmentLine2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ServiceShipmentLine3.SetRange("Document No.", ServiceShipmentLine2."Document No.");
        ServiceShipmentLine3."Document No." := ServiceShipmentLine2."Document No.";
        ServiceShipmentLine3."Line No." := ServiceShipmentLine2."Line No.";
        ServiceShipmentLine3.Find('=');
        if ServiceShipmentLine3.Next() <> 0 then begin
            LineSpacing := (ServiceShipmentLine3."Line No." - ServiceShipmentLine2."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        Result := ServiceShipmentLine2."Line No." + LineSpacing;
        OnAfterGetCorrectionLineNo(ServiceShipmentLine2, Result);
    end;

    local procedure PostItemJnlLine(ServShptLine: Record "Service Shipment Line"): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        ServLine: Record "Service Line";
        ServShptHeader: Record "Service Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
    begin
        SourceCodeSetup.Get();
        ServShptHeader.Get(ServShptLine."Document No.");
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Service Shipment";
        ItemJnlLine."Document No." := ServShptHeader."No.";
        ItemJnlLine."Document Line No." := ServShptLine."Line No." + GetCorrectiveShptLineNoStep(ServShptLine."Document No.", ServShptLine."Line No.");
        ItemJnlLine."Item No." := ServShptLine."No.";
        ItemJnlLine."Posting Date" := ServShptLine."Posting Date";
        ItemJnlLine."Document No." := ServShptLine."Document No.";
        ItemJnlLine."Gen. Bus. Posting Group" := ServShptLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := ServShptLine."Gen. Prod. Posting Group";
        ItemJnlLine."Source Posting Group" := ServShptHeader."Customer Posting Group";
        ItemJnlLine."Salespers./Purch. Code" := ServShptHeader."Salesperson Code";
        ItemJnlLine."Country/Region Code" := ServShptHeader."Country/Region Code";
        ItemJnlLine."Posting No. Series" := ServShptHeader."No. Series";
        ItemJnlLine."Unit of Measure Code" := ServShptLine."Unit of Measure Code";
        ItemJnlLine."Location Code" := ServShptLine."Location Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Sales;
        ItemJnlLine."Applies-to Entry" := ServShptLine."Item Shpt. Entry No.";
        ItemJnlLine.Correction := true;
        ItemJnlLine."Variant Code" := ServShptLine."Variant Code";
        ItemJnlLine."Bin Code" := ServShptLine."Bin Code";
        ItemJnlLine.Quantity := -ServShptLine."Quantity (Base)";
        ItemJnlLine."Quantity (Base)" := -ServShptLine."Quantity (Base)";
        ItemJnlLine."Document Date" := ServShptHeader."Document Date";

        OnAfterCopyItemJnlLineFromServShpt(ItemJnlLine, ServShptHeader, ServShptLine);

        WhseUndoQty.InsertTempWhseJnlLine(
            ItemJnlLine,
            DATABASE::"Service Line", ServLine."Document Type"::Order.AsInteger(), ServShptLine."Order No.", ServShptLine."Order Line No.",
            TempWhseJnlLine."Reference Document"::"Posted Shipment".AsInteger(), TempWhseJnlLine, NextLineNo);

        if ServShptLine."Item Shpt. Entry No." <> 0 then begin
            ItemJnlPostLine.Run(ItemJnlLine);
            OnItemJnlPostLineOnAfterItemShptEntryNoOnBeforeExit(ItemJnlLine, ServShptLine);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;
        UndoPostingMgt.CollectItemLedgEntries(TempApplyToEntryList, DATABASE::"Service Shipment Line",
          ServShptLine."Document No.", ServShptLine."Line No.", ServShptLine."Quantity (Base)", ServShptLine."Item Shpt. Entry No.");

        UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToEntryList,
          ServShptLine.Quantity, ServShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

        OnAfterPostItemJnlLine(ItemJnlLine, ServShptLine);
        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure InsertNewShipmentLine(OldServShptLine: Record "Service Shipment Line"; ItemShptEntryNo: Integer)
    var
        NewServShptLine: Record "Service Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewShipmentLine(OldServShptLine, ItemShptEntryNo, TempGlobalItemEntryRelation, IsHandled);
        if IsHandled then
            exit;

        NewServShptLine.Reset();
        NewServShptLine.Init();
        NewServShptLine.Copy(OldServShptLine);
        NewServShptLine."Line No." := OldServShptLine."Line No." + GetCorrectiveShptLineNoStep(OldServShptLine."Document No.", OldServShptLine."Line No.");
        NewServShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewServShptLine."Appl.-to Service Entry" := OldServShptLine."Appl.-to Service Entry";
        NewServShptLine.Quantity := -OldServShptLine.Quantity;
        NewServShptLine."Qty. Shipped Not Invoiced" := 0;
        NewServShptLine."Qty. Shipped Not Invd. (Base)" := 0;
        NewServShptLine."Quantity (Base)" := -OldServShptLine."Quantity (Base)";
        NewServShptLine."Quantity Invoiced" := NewServShptLine.Quantity;
        NewServShptLine."Qty. Invoiced (Base)" := NewServShptLine."Quantity (Base)";
        NewServShptLine.Correction := true;
        NewServShptLine."Dimension Set ID" := OldServShptLine."Dimension Set ID";
        OnBeforeNewServiceShptLineInsert(NewServShptLine, OldServShptLine);
        NewServShptLine.Insert();

        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewServShptLine);
    end;

    local procedure UpdateOrderLine(ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Get(ServLine."Document Type"::Order, ServShptLine."Order No.", ServShptLine."Order Line No.");
        ServUndoPostingMgt.UpdateServLine(ServLine, ServShptLine.Quantity, ServShptLine."Quantity (Base)", TempGlobalItemLedgEntry);
        OnAfterUpdateOrderLine(ServLine, ServShptLine);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewServShptLine: Record "Service Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                NewServShptLine.TransferToItemEntryRelation(ItemEntryRelation);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure PostResJnlLine(var ServiceShptLine: Record "Service Shipment Line")
    var
        ResJnlLine: Record "Res. Journal Line";
        SrcCodeSetup: Record "Source Code Setup";
        ServiceShptHeader: Record "Service Shipment Header";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        ServTimeSheetMgt: Codeunit "Serv. Time Sheet Mgt.";
        IsHandled: Boolean;
    begin
        ResJnlLine.Init();
        SrcCodeSetup.Get();
        ServiceShptHeader.Get(ServiceShptLine."Document No.");
        ResJnlLine."Entry Type" := ResJnlLine."Entry Type"::Usage;
        ResJnlLine."Document No." := ServiceShptLine."Document No.";
        ResJnlLine."Posting Date" := ServiceShptLine."Posting Date";
        ResJnlLine."Document Date" := ServiceShptHeader."Document Date";
        ResJnlLine."Resource No." := ServiceShptLine."No.";
        ResJnlLine.Description := ServiceShptLine.Description;
        ResJnlLine."Work Type Code" := ServiceShptLine."Work Type Code";
        ResJnlLine.Quantity := -ServiceShptLine."Qty. Shipped Not Invoiced";
        ResJnlLine."Unit Cost" := ServiceShptLine."Unit Cost (LCY)";
        ResJnlLine."Total Cost" := ServiceShptLine."Unit Cost (LCY)" * ResJnlLine.Quantity;
        ResJnlLine."Unit Price" := ServiceShptLine."Unit Price";
        ResJnlLine."Total Price" := ResJnlLine."Unit Price" * ResJnlLine.Quantity;
        ResJnlLine."Shortcut Dimension 1 Code" := ServiceShptHeader."Shortcut Dimension 1 Code";
        ResJnlLine."Shortcut Dimension 2 Code" := ServiceShptHeader."Shortcut Dimension 2 Code";
        ResJnlLine."Dimension Set ID" := ServiceShptLine."Dimension Set ID";
        ResJnlLine."Unit of Measure Code" := ServiceShptLine."Unit of Measure Code";
        ResJnlLine."Qty. per Unit of Measure" := ServiceShptLine."Qty. per Unit of Measure";
        ResJnlLine."Source Code" := SrcCodeSetup."Service Management";
        ResJnlLine."Gen. Bus. Posting Group" := ServiceShptLine."Gen. Bus. Posting Group";
        ResJnlLine."Gen. Prod. Posting Group" := ServiceShptLine."Gen. Prod. Posting Group";
        ResJnlLine."Posting No. Series" := ServiceShptHeader."No. Series";
        ResJnlLine."Reason Code" := ServiceShptHeader."Reason Code";
        ResJnlLine."Source Type" := ResJnlLine."Source Type"::Customer;
        ResJnlLine."Source No." := ServiceShptLine."Bill-to Customer No.";
        ResJnlLine."Qty. per Unit of Measure" := ServiceShptLine."Qty. per Unit of Measure";
        IsHandled := false;
        OnBeforePostResJnlLine(ResJnlLine, ServiceShptLine, IsHandled);
        if not IsHandled then
            ResJnlPostLine.RunWithCheck(ResJnlLine);
        OnPostResJnlLineOnAfterRunWithCheck(ResJnlLine, ServiceShptLine);

        ServTimeSheetMgt.CreateTSLineFromServiceShptLine(ServiceShptLine);
    end;

    local procedure DeleteServShptLineServItems(ServShptLine: Record "Service Shipment Line")
    var
        ServItem: Record "Service Item";
    begin
        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", ServShptLine."Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Line No.", ServShptLine."Line No.");
        ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Service);
        if ServItem.Find('-') then
            repeat
                if ServItem.CheckIfCanBeDeleted() = '' then
                    if ServItem.Delete(true) then;
            until ServItem.Next() = 0;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then begin
            InvtAdjmtHandler.SetJobUpdateProperties(true);
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShpt(var ItemJournalLine: Record "Item Journal Line"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line"; PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCorrectionLineNo(ServiceShipmentLine: Record "Service Shipment Line"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderLine(var ServiceLine: Record "Service Line"; var ServiceShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServShptLine(var ServiceShptLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(ServiceShipmentLine: Record "Service Shipment Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewShipmentLine(var ServiceShptLine: Record "Service Shipment Line"; ItemShptEntryNo: Integer; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewServiceShptLineInsert(var NewServiceShipmentLine: Record "Service Shipment Line"; OldServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLine(var ResJournalLine: Record "Res. Journal Line"; var ServiceShptLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterServShptLineModify(var ServShptLine: Record "Service Shipment Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeServShptLineModify(var ServShptLine: Record "Service Shipment Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckComponentsAdjustedOnAfterLocalServShptLineSetFilters(var ServiceShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostLineOnAfterItemShptEntryNoOnBeforeExit(var ItemJournalLine: Record "Item Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostResJnlLineOnAfterRunWithCheck(var ResJournalLine: Record "Res. Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;
}

