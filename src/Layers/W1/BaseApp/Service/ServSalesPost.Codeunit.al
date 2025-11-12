// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Service.Item;

codeunit 6455 "Serv. Sales-Post"
{
    Permissions = TableData "Service Item" = rimd;
    SingleInstance = true;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        TempServiceItem2: Record "Service Item" temporary;
        TempServiceItemComp2: Record "Service Item Component" temporary;
        ServItemManagement: Codeunit ServItemManagement;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnRunOnBeforeCheckAndUpdate', '', false, false)]
    local procedure OnRunOnBeforeCheckAndUpdate()
    begin
        TempServiceItem2.DeleteAll();
        TempServiceItemComp2.DeleteAll();
        Clear(ServItemManagement);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertShipmentLine', '', false, false)]
    local procedure OnAfterInsertShipmentLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line"; xSalesLine: Record "Sales Line")
    var
        TempServiceItem1: Record "Service Item" temporary;
        TempServiceItemComp1: Record "Service Item Component" temporary;
    begin
        ServItemManagement.CreateServItemOnSalesLineShpt(SalesHeader, xSalesLine, SalesShptLine);
        if SalesLine."BOM Item No." <> '' then begin
            ServItemManagement.ReturnServItemComp(TempServiceItem1, TempServiceItemComp1);
            if TempServiceItem1.FindSet() then
                repeat
                    TempServiceItem2 := TempServiceItem1;
                    if TempServiceItem2.Insert() then;
                until TempServiceItem1.Next() = 0;
            if TempServiceItemComp1.FindSet() then
                repeat
                    TempServiceItemComp2 := TempServiceItemComp1;
                    if TempServiceItemComp2.Insert() then;
                until TempServiceItemComp1.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnInsertPostedHeadersDeleteServItemOnSaleCreditMemo', '', false, false)]
    local procedure OnInsertPostedHeadersDeleteServItemOnSaleCreditMemo(var SalesHeader: Record "Sales Header")
    begin
        ServItemManagement.DeleteServItemOnSaleCreditMemo(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnInsertPostedHeadersOnAfterInsertShipmentHeader', '', false, false)]
    local procedure OnInsertPostedHeadersOnAfterInsertShipmentHeader(var SalesHeader: Record "Sales Header");
    begin
        CreateServItemOnSalesInvoice(SalesHeader);
    end;

    local procedure CreateServItemOnSalesInvoice(var SalesHeader: Record "Sales Header")
    var
#if not CLEAN25
        SalesPost: Codeunit Microsoft.Sales.Posting."Sales-Post";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateServItemOnSalesInvoice(SalesHeader, IsHandled);
#if not CLEAN25
        SalesPost.RunOnBeforeCreateServItemOnSalesInvoice(SalesHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        ServItemManagement.CopyReservationEntry(SalesHeader);
        SalesSetup.Get();
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice) and
           (not SalesSetup."Shipment on Invoice")
        then
            ServItemManagement.CreateServItemOnSalesInvoice(SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServItemOnSalesInvoice(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterFinalizePostingOnBeforeCommit', '', false, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit()
    begin
        SynchBOMSerialNo(TempServiceItem2, TempServiceItemComp2);
    end;

    local procedure SynchBOMSerialNo(var TempServiceItem3: Record "Service Item" temporary; var TempServiceItemComp3: Record "Service Item Component" temporary)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        TempSalesShipMntLine: Record "Sales Shipment Line" temporary;
        TempServiceItemComp4: Record "Service Item Component" temporary;
        ServItemCompLocal: Record "Service Item Component";
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
        ChildCount: Integer;
        EndLoop: Boolean;
    begin
        if not TempServiceItemComp3.Find('-') then
            exit;

        if not TempServiceItem3.Find('-') then
            exit;

        TempSalesShipMntLine.DeleteAll();
        repeat
            Clear(TempSalesShipMntLine);
            TempSalesShipMntLine."Document No." := TempServiceItem3."Sales/Serv. Shpt. Document No.";
            TempSalesShipMntLine."Line No." := TempServiceItem3."Sales/Serv. Shpt. Line No.";
            if TempSalesShipMntLine.Insert() then;
        until TempServiceItem3.Next() = 0;

        if not TempSalesShipMntLine.Find('-') then
            exit;

        TempServiceItem3.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        Clear(ItemLedgEntry);
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");

        repeat
            ChildCount := 0;
            TempServiceItemComp4.DeleteAll();
            TempServiceItem3.SetRange("Sales/Serv. Shpt. Document No.", TempSalesShipMntLine."Document No.");
            TempServiceItem3.SetRange("Sales/Serv. Shpt. Line No.", TempSalesShipMntLine."Line No.");
            if TempServiceItem3.Find('-') then
                repeat
                    TempServiceItemComp3.SetRange(Active, true);
                    TempServiceItemComp3.SetRange("Parent Service Item No.", TempServiceItem3."No.");
                    if TempServiceItemComp3.Find('-') then
                        repeat
                            ChildCount += 1;
                            TempServiceItemComp4 := TempServiceItemComp3;
                            TempServiceItemComp4.Insert();
                        until TempServiceItemComp3.Next() = 0;
                until TempServiceItem3.Next() = 0;
            ItemLedgEntry.SetRange("Document No.", TempSalesShipMntLine."Document No.");
            ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
            ItemLedgEntry.SetRange("Document Line No.", TempSalesShipMntLine."Line No.");
            if ItemLedgEntry.FindFirst() and TempServiceItemComp4.Find('-') then begin
                Clear(ItemLedgEntry2);
                ItemLedgEntry2.Get(ItemLedgEntry."Entry No.");
                EndLoop := false;
                repeat
                    if ItemLedgEntry2."Item No." = TempServiceItemComp4."No." then
                        EndLoop := true
                    else
                        if ItemLedgEntry2.Next() = 0 then
                            EndLoop := true;
                until EndLoop;
                ItemLedgEntry2.SetRange("Entry No.", ItemLedgEntry2."Entry No.", ItemLedgEntry2."Entry No." + ChildCount - 1);
                if ItemLedgEntry2.FindSet() then
                    repeat
                        TempItemLedgEntry2 := ItemLedgEntry2;
                        TempItemLedgEntry2.Insert();
                    until ItemLedgEntry2.Next() = 0;
                repeat
                    if ServItemCompLocal.Get(
                         TempServiceItemComp4.Active,
                         TempServiceItemComp4."Parent Service Item No.",
                         TempServiceItemComp4."Line No.")
                    then begin
                        TempItemLedgEntry2.SetRange("Item No.", ServItemCompLocal."No.");
                        if TempItemLedgEntry2.FindFirst() then begin
                            ServItemCompLocal."Serial No." := TempItemLedgEntry2."Serial No.";
                            ServItemCompLocal.Modify();
                            TempItemLedgEntry2.Delete();
                        end;
                    end;
                until TempServiceItemComp4.Next() = 0;
            end;
        until TempSalesShipMntLine.Next() = 0;
    end;
}