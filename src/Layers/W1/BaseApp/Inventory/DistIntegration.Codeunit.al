// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

codeunit 5702 "Dist. Integration"
{

    trigger OnRun()
    begin
    end;

    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemReference: Record "Item Reference";

        ItemsNotFoundErr: Label 'There are no items with cross reference %1.', Comment = '%1=Cross-Reference No.';
#pragma warning disable AA0074
        Text001: Label 'The Quantity per Unit of Measure %1 has changed from %2 to %3 since the sales order was created. Adjust the quantity on the sales order or the unit of measure.', Comment = '%1=Unit of Measure Code,%2=Qty. per Unit of Measure in Sales Line,%3=Qty. per Unit of Measure in Item Unit of Measure';
#pragma warning restore AA0074

    procedure GetSpecialOrders(var PurchHeader: Record "Purchase Header")
    var
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSpecialOrders(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Order);

        IsHandled := false;
        OnGetSpecialOrdersOnBeforeSelectSalesHeader(PurchHeader, SalesHeader, IsHandled);
        if not IsHandled then begin
            SalesHeader.SetCurrentKey("Document Type", "Sell-to Customer No.");
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.SetRange("Sell-to Customer No.", PurchHeader."Sell-to Customer No.");
            if (PAGE.RunModal(PAGE::"Sales List", SalesHeader) <> ACTION::LookupOK) or
               (SalesHeader."No." = '')
            then
                exit;
        end;

        PurchHeader.LockTable();

        OnGetSpecialOrdersOnBeforeTestSalesHeader(SalesHeader);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
        PurchHeader.TestField(PurchHeader."Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        CheckShipToCode(PurchHeader, SalesHeader);
        CheckAddSpecialOrderToAddress(PurchHeader, SalesHeader);

        if Vendor.Get(PurchHeader."Buy-from Vendor No.") then
            PurchHeader.Validate(PurchHeader."Shipment Method Code", Vendor."Shipment Method Code");

        PurchLine.LockTable();
        SalesLine.LockTable();

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindLast() then
            NextLineNo := PurchLine."Line No." + 10000
        else
            NextLineNo := 10000;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Special Order", true);
        SalesLine.SetFilter("Outstanding Quantity", '<>0');
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetRange("Special Order Purch. Line No.", 0);
        OnGetSpecialOrdersOnAfterSalesLineSetFilters(SalesLine, SalesHeader, PurchHeader);
        if SalesLine.FindSet() then
            repeat
                IsHandled := false;
                OnGetSpecialOrdersOnBeforeTestSalesLine(SalesLine, PurchHeader, IsHandled);
                if not IsHandled then
                    if (SalesLine.Type = SalesLine.Type::Item) and
                       ItemUnitOfMeasure.Get(SalesLine."No.", SalesLine."Unit of Measure Code")
                    then
                        if SalesLine."Qty. per Unit of Measure" <> ItemUnitOfMeasure."Qty. per Unit of Measure" then
                            Error(Text001,
                              SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
                              ItemUnitOfMeasure."Qty. per Unit of Measure");

                ProcessSalesLine(SalesLine, PurchLine, NextLineNo, PurchHeader);
            until SalesLine.Next() = 0
        else
            Error(ItemsNotFoundErr, SalesHeader."No.");

        OnGetSpecialOrdersOnBeforeModifyPurchaseHeader(PurchHeader, SalesHeader);
        PurchHeader.Modify();
        // Only version check
        SalesHeader.Modify(); // Only version check
    end;

    local procedure CheckShipToCode(var PurchHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipToCode(PurchHeader, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Ship-to Code" <> '' then
            PurchHeader.TestField("Ship-to Code", SalesHeader."Ship-to Code");
    end;

    local procedure CheckAddSpecialOrderToAddress(var PurchHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAddSpecialOrderToAddress(PurchHeader, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader.SpecialOrderExists(SalesHeader) then begin
            PurchHeader.Validate("Location Code", SalesHeader."Location Code");
            PurchHeader.AddSpecialOrderToAddress(SalesHeader, true);
        end;
    end;

    local procedure ProcessSalesLine(var SalesLine: Record "Sales Line"; var PurchLine: Record "Purchase Line"; var NextLineNo: Integer; PurchHeader: Record "Purchase Header")
    var
        PurchLine2: Record "Purchase Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Init();
        PurchLine."Document Type" := PurchLine."Document Type"::Order;
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := NextLineNo;
        CopyDocMgt.TransfldsFromSalesToPurchLine(SalesLine, PurchLine);
        PurchLine.GetItemTranslation();
        PurchLine."Special Order" := true;
        PurchLine."Purchasing Code" := SalesLine."Purchasing Code";
        PurchLine."Special Order Sales No." := SalesLine."Document No.";
        PurchLine."Special Order Sales Line No." := SalesLine."Line No.";
        OnBeforeInsertPurchLine(PurchLine, SalesLine);
        PurchLine.Insert();
        OnAfterInsertPurchLine(PurchLine, SalesLine, NextLineNo);

        NextLineNo := NextLineNo + 10000;

        SalesLine."Unit Cost (LCY)" := PurchLine."Unit Cost (LCY)";
        SalesLine.Validate("Unit Cost (LCY)");
        SalesLine."Special Order Purchase No." := PurchLine."Document No.";
        SalesLine."Special Order Purch. Line No." := PurchLine."Line No.";
        OnBeforeSalesLineModify(SalesLine, PurchLine);
        SalesLine.Modify();
        OnAfterSalesLineModify(SalesLine, PurchLine);
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, false) then begin
            TransferExtendedText.InsertPurchExtText(PurchLine);
            PurchLine2.SetRange("Document Type", PurchHeader."Document Type");
            PurchLine2.SetRange("Document No.", PurchHeader."No.");
            if PurchLine2.FindLast() then
                NextLineNo := PurchLine2."Line No.";
            NextLineNo := NextLineNo + 10000;
        end;
        OnGetSpecialOrdersOnAfterTransferExtendedText(SalesLine, PurchHeader, NextLineNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterDeleteRelatedData', '', false, false)]
    local procedure ItemOnAfterDeleteRelatedData(Item: Record Item)
    begin
        if Item.IsTemporary() then
            exit;

        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteEvent', '', false, false)]
    local procedure CustomerOnAfterDelete(var Rec: Record Customer)
    begin
        if Rec.IsTemporary() then
            exit;

        ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Customer);
        ItemReference.SetRange("Reference Type No.", Rec."No.");
        ItemReference.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterDeleteEvent', '', false, false)]
    local procedure VendorOnAfterDelete(var Rec: Record Vendor)
    begin
        if Rec.IsTemporary() then
            exit;

        ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", Rec."No.");
        ItemReference.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipToCode(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAddSpecialOrderToAddress(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSpecialOrders(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnAfterTransferExtendedText(SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeSelectSalesHeader(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeTestSalesHeader(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeTestSalesLine(SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSpecialOrdersOnBeforeModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header")
    begin
    end;
}

