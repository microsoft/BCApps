namespace System.Test.Tooling;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using System.Tooling;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Activity;

codeunit 149202 "BCPT Warehouse Receipt"
{
    SingleInstance = true;

    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        GlobalLastItemNo: Code[20];

    trigger OnRun()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        BCPTTestContext: Codeunit "BCPT Test Context";
        WarehouseReceiptNo: Code[20];
    begin
        BCPTTestContext.StartScenario('Init');
        if not Location.Get('WHITE') then
            Location.FindFirst();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        BCPTTestContext.EndScenario('Init');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('CreatePurchaseOrder');
        CreatePurchaseOrder(PurchaseHeader, Location.Code, 10, GlobalLastItemNo);
        BCPTTestContext.EndScenario('CreatePurchaseOrder');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('CreateWarehouseReceipt');
        WarehouseReceiptNo := CreateWarehouseReceipt(PurchaseHeader);
        BCPTTestContext.EndScenario('CreateWarehouseReceipt');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('PostWarehouseReceipt');
        PostWarehouseReceipt(WarehouseReceiptNo);
        BCPTTestContext.EndScenario('PostWarehouseReceipt');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('RegisterPutAway');
        RegisterPutAway(PurchaseHeader."No.");
        BCPTTestContext.EndScenario('RegisterPutAway');
        BCPTTestContext.UserWait();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; NoOfLines: Integer; var LastItemNo: Code[20])
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        i: integer;
    begin
        if not Vendor.Get('10000') then
            Vendor.FindFirst();
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);
        Commit();
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader."Location Code" := LocationCode;
        PurchaseHeader.Modify();
        Item.SetRange(Type, Item.Type::Inventory);
        Item.FilterGroup(2);
        Item.SetFilter("No.", '<>%1', 'GL0*'); // omit the test items
        Item.FilterGroup(2);
        //      Item.SetFilter("Item Tracking Code", '%1', '');  // not recognized by the compiler????
        Item.SetLoadFields("No.", "Item Tracking Code");
        if LastItemNo <> '' then
            Item.SetFilter("No.", '>%1', LastItemNo);
        Item.FindSet();
        i := 0;
        while i < NoOfLines do begin
            if Item."Item Tracking Code" = '' then begin  // workaround
                i += 1;
                PurchaseLine.init();
                PurchaseLine."Document No." := PurchaseHeader."No.";
                PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                PurchaseLine."Line No." := i * 10000;
                PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
                PurchaseLine.Validate("No.", Item."No.");
                PurchaseLine.Validate("Location Code", LocationCode);
                PurchaseLine.Validate(Quantity, 1);
                PurchaseLine.Validate("Direct Unit Cost", 1);
                PurchaseLine.Insert(true);
            end;
            if i < NoOfLines then
                if Item.Next() = 0 then begin
                    Item.SetRange("No.");
                    Item.FindSet();
                end;
        end;
        if i = 0 then
            if Item.Next() = 0 then; // to make codecop happy
        LastItemNo := Item."No.";
    end;

    local procedure CreateWarehouseReceipt(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        PurchaseHeader.PerformManualRelease();
        GetSourceDocInbound.CreateFromPurchOrderHideDialog(PurchaseHeader);
        Commit();
        WhseReceiptLine.ReadIsolation(IsolationLevel::ReadCommitted);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.SetLoadFields("No.");
        WhseReceiptLine.FindFirst();
        exit(WhseReceiptLine."No.");
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WhseReceiptLine.SetRange("No.", WarehouseReceiptNo);
        WhseReceiptLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt", WhseReceiptLine);
    end;


    local procedure RegisterPutAway(PurchaseOrderNo: Code[20])
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActRegister: Codeunit "Whse.-Activity-Register";
    begin
        WhseActivLine.SetRange("Activity Type", "Warehouse Activity Type"::"Put-away");
        WhseActivLine.SetRange("Source Document", WhseActivLine."Source Document"::"Purchase Order");
        WhseActivLine.SetRange("Source No.", PurchaseOrderNo);
        if WhseActivLine.FindFirst() then
            WhseActRegister.Run(WhseActivLine);
    end;
}