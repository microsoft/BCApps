// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

codeunit 139983 "Subc. Management Library"
{
    procedure Initialize()
    begin
        CreateSubcontractingManagementSetup();
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BatchNameLbl: Label 'DEFAULT', Comment = 'Default Batch';

    procedure CreateSubcontractingManagementSetup()
    var
        SubcontractingManagementSetup: Record "Subc. Management Setup";
    begin
        SubcontractingManagementSetup.Reset();
        if not SubcontractingManagementSetup.Get() then begin
            SubcontractingManagementSetup.Init();
            SubcontractingManagementSetup.Insert(true);
        end;
    end;

    procedure CreateSubcontractorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Create a Subcontractor Vendor.
        CreateSubcontractor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateSubcontractor(var Vendor: Record Vendor)
    var
        Location: Record Location;
    begin
        LibraryPurchase.CreateSubcontractor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor.Modify();
    end;

    procedure CreateSubContractingPrice(var SubcontractorPrices: Record "Subcontractor Price"; WorkCenterNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; StandardTaskCode: Code[10]; VariantCode: Code[10]; StartDate: Date; UnitOfMeasureCode: Code[10]; MinimumQuantity: Decimal; CurrencyCode: Code[10])
    begin
        SubcontractorPrices.Init();
        SubcontractorPrices.Validate("Work Center No.", WorkCenterNo);
        SubcontractorPrices.Validate("Vendor No.", VendorNo);
        SubcontractorPrices.Validate("Item No.", ItemNo);
        SubcontractorPrices.Validate("Standard Task Code", StandardTaskCode);
        SubcontractorPrices.Validate("Variant Code", VariantCode);
        SubcontractorPrices.Validate("Starting Date", StartDate);
        SubcontractorPrices.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SubcontractorPrices.Validate("Minimum Quantity", MinimumQuantity);
        SubcontractorPrices.Validate("Currency Code", CurrencyCode);
        SubcontractorPrices.Insert(true);
    end;

    procedure CreateSubcontractorPrice(Item: Record Item; WorkCenterNo: Code[20]; var SubcontractorPrice: Record "Subcontractor Price")
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        LibraryRandom: Codeunit "Library - Random";
        i: Integer;
        NoOfLoops: Integer;
    begin
        SubcontractorPrice.DeleteAll();
        NoOfLoops := LibraryRandom.RandInt(20);

        WorkCenter.Get(WorkCenterNo);
        Vendor.Get(WorkCenter."Subcontractor No.");
        for i := 1 to NoOfLoops do begin
            SubcontractorPrice.Init();
            SubcontractorPrice."Vendor No." := Vendor."No.";
            SubcontractorPrice."Item No." := Item."No.";
            SubcontractorPrice."Work Center No." := WorkCenter."No.";
            SubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
            SubcontractorPrice."Currency Code" := Vendor."Currency Code";
            SubcontractorPrice."Minimum Quantity" := i;
            SubcontractorPrice."Direct Unit Cost" := LibraryRandom.RandInt(100);
            SubcontractorPrice.Insert();
        end;
    end;

    procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    var
        RequisitionLine: Record "Requisition Line";
        SubcCalculateSubcontracts: Report "Subc. Calculate Subcontracts";
    begin
        RequisitionLineForSubcontractOrder(RequisitionLine);
        SubcCalculateSubcontracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubcontracts.SetTableView(WorkCenter);
        SubcCalculateSubcontracts.UseRequestPage(false);
        SubcCalculateSubcontracts.RunModal();
    end;

    procedure CalculateSubcontractOrderWithProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        RequisitionLine: Record "Requisition Line";
        TmpProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcCalculateSubcontracts: Report "Subc. Calculate Subcontracts";
    begin
        if ProdOrderRoutingLine.HasFilter then
            TmpProdOrderRoutingLine.CopyFilters(ProdOrderRoutingLine)
        else begin
            ProdOrderRoutingLine.Get(ProdOrderRoutingLine."No.");
            TmpProdOrderRoutingLine.SetRange("No.", ProdOrderRoutingLine."No.");
        end;

        RequisitionLineForSubcontractOrder(RequisitionLine);
        SubcCalculateSubcontracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubcontracts.SetTableView(TmpProdOrderRoutingLine);
        SubcCalculateSubcontracts.UseRequestPage(false);
        SubcCalculateSubcontracts.RunModal();
    end;

    local procedure RequisitionLineForSubcontractOrder(var RequisitionLine: Record "Requisition Line")
    var
        ReqJnlManagement: Codeunit ReqJnlManagement;
        JnlSelected: Boolean;
        Handled: Boolean;
    begin
        ReqJnlManagement.WkshTemplateSelection(Page::"Subc. Subcontracting Worksheet", false, "Req. Worksheet Template Type"::Subcontracting, RequisitionLine, JnlSelected);
        if not JnlSelected then
            Error('');
        RequisitionLine."Worksheet Template Name" := CopyStr(Format("Req. Worksheet Template Type"::Subcontracting), 1, MaxStrLen(RequisitionLine."Worksheet Template Name"));
        RequisitionLine."Journal Batch Name" := BatchNameLbl;
        OnBeforeOpenJournal(RequisitionLine, Handled);
        if Handled then
            exit;
        ReqJnlManagement.OpenJnl(RequisitionLine."Journal Batch Name", RequisitionLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJournal(var RequisitionLine: Record "Requisition Line"; var Handled: Boolean)
    begin
    end;
}