// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Reflection;

codeunit 20580 "Subc. Prod. Def. Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        SubcontractingPurchaseLine: Record "Purchase Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupRead: Boolean;

    /// <summary>
    /// Sets the purchase line for subcontracting context. Must be called before BindSubscription.
    /// </summary>
    internal procedure SetSubcontractingPurchaseLine(PurchLine: Record "Purchase Line")
    begin
        SubcontractingPurchaseLine := PurchLine;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Def. Source Initializer", 'OnBeforeInitializeFromSource', '', false, false)]
    local procedure OnBeforeInitializeFromSource(var TempData: Codeunit "Prod. Definition Temp Data"; Source: Variant; var IsHandled: Boolean)
    var
        PurchLine: Record "Purchase Line";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(Source, SourceRecRef) then
            exit;
        if SourceRecRef.Number <> Database::"Purchase Line" then
            exit;
        SourceRecRef.SetTable(PurchLine);
        TempData.SetGlobalSourceType("Prod. Definition Source"::PurchaseLine);
        ValidatePurchLineForWizard(PurchLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Def. Source Initializer", 'OnInitializeFromSource', '', false, false)]
    local procedure OnInitializeFromSource(var TempData: Codeunit "Prod. Definition Temp Data"; Source: Variant; var IsHandled: Boolean)
    var
        PurchLine: Record "Purchase Line";
        TempProdOrder: Record "Production Order" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecRef: RecordRef;
        TempProdOrderNoLbl: Label 'TEMP-%1', Locked = true, MaxLength = 20;
    begin
        if TempData.GetGlobalSourceType() <> "Prod. Definition Source"::PurchaseLine then
            exit;

        if not DataTypeManagement.GetRecordRef(Source, SourceRecRef) then
            exit;
        if SourceRecRef.Number <> Database::"Purchase Line" then
            exit;
        SourceRecRef.SetTable(PurchLine);
        SubcontractingPurchaseLine := PurchLine;

        TempData.SetGlobalItemInfo(PurchLine."No.", PurchLine.Description);
        TempData.SetNewPurchLine(PurchLine);

        TempProdOrder.Init();
        TempProdOrder.Status := "Production Order Status"::Released;
        TempProdOrder."No." := CopyStr(StrSubstNo(TempProdOrderNoLbl, CopyStr(Format(CreateGuid()), 2, 10)), 1, MaxStrLen(TempProdOrder."No."));
        TempProdOrder."Source Type" := "Prod. Order Source Type"::Item;
        TempProdOrder.Validate("Source No.", PurchLine."No.");
        if PurchLine."Variant Code" <> '' then
            TempProdOrder.Validate("Variant Code", PurchLine."Variant Code");
        TempProdOrder.Validate("Due Date", PurchLine."Expected Receipt Date");
        TempProdOrder.Validate("Quantity", PurchLine."Quantity (Base)");
        TempProdOrder.Validate("Location Code", PurchLine."Location Code");
        TempProdOrder."Created from Purch. Order" := true;
        TempProdOrder.Insert();
        TempData.SetNewProdOrder(TempProdOrder);

        TempData.CreateTemporaryProdOrderLine();
        TempData.ClearTemporaryProductionTables();

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Definition Manager", 'OnAfterPostWizardProcessing', '', false, false)]
    local procedure OnAfterPostWizardProcessing(var ProdOrder: Record "Production Order")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(SubcontractingPurchaseLine.RecordId());
        UpdatePurchaseLineWithProdOrder(PurchaseLine, ProdOrder);
        HandleSubcontractingAfterUpdate(PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Definition Temp Data", 'OnBeforeInsertDefaultTemporaryBOMLine', '', false, false)]
    local procedure OnBeforeInsertDefaultTemporaryBOMLine(var TempBOMLine: Record "Production BOM Line" temporary)
    begin
        GetManufacturingSetup();
        TempBOMLine."Component Supply Method" := "Component Supply Method"::"Consignment at Vendor";
        TempBOMLine."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
        if ManufacturingSetup."Def. Wiz. Comp Item No." <> '' then
            TempBOMLine."No." := ManufacturingSetup."Def. Wiz. Comp Item No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Definition Temp Data", 'OnAfterCreateTemporaryComponentFromBOMLine', '', false, false)]
    local procedure OnAfterCreateTemporaryComponentFromBOMLine(var TempProdOrderComponent: Record "Prod. Order Component" temporary; ProductionBOMLine: Record "Production BOM Line")
    var
        Vendor: Record Vendor;
        ProductionBOMHeader: Record "Production BOM Header";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        TempProdOrderComponent."Component Supply Method" := ProductionBOMLine."Component Supply Method";
        TempProdOrderComponent."Subc. Original Location Code" := TempProdOrderComponent."Location Code";
        TempProdOrderComponent."Subc. Orig. Bin Code" := TempProdOrderComponent."Bin Code";

        GetManufacturingSetup();
        if TempProdOrderComponent."Routing Link Code" = ManufacturingSetup."Subc. Rtng. Link Purch Prov" then
            case TempProdOrderComponent."Component Supply Method" of
                "Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied":
                    begin
                        TempProdOrderComponent."Subc. Original Location Code" := SubcontractingManagement.GetComponentsLocationCode(SubcontractingPurchaseLine);
                        if Vendor.Get(SubcontractingPurchaseLine."Buy-from Vendor No.") then
                            if Vendor."Subc. Location Code" <> '' then
                                TempProdOrderComponent.Validate("Location Code", Vendor."Subc. Location Code");
                    end;
            end;

        ProductionBOMHeader.SetLoadFields(SystemId);
        if not ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.") then
            TempProdOrderComponent."Flushing Method" := ManufacturingSetup."Def. Wiz. Flushing Method";

        TempProdOrderComponent.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Definition Temp Data", 'OnAfterCreateTemporaryProdOrderRoutingLineFromRouting', '', false, false)]
    local procedure OnAfterCreateTemporaryProdOrderRoutingLineFromRouting(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; RoutingLine: Record "Routing Line")
    begin
        TempProdOrderRoutingLine."Vendor No. Subc. Price" := SubcontractingPurchaseLine."Buy-from Vendor No.";
        TempProdOrderRoutingLine.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Direct Creator", 'OnBeforeInsertProdOrderComponentFromTemp', '', false, false)]
    local procedure OnBeforeInsertProdOrderComponentFromTemp(var ProdOrderComponent: Record "Prod. Order Component"; TempProdOrderComponent: Record "Prod. Order Component" temporary)
    begin
        ProdOrderComponent."Component Supply Method" := TempProdOrderComponent."Component Supply Method";
        ProdOrderComponent."Subc. Original Location Code" := TempProdOrderComponent."Subc. Original Location Code";
        ProdOrderComponent."Subc. Orig. Bin Code" := TempProdOrderComponent."Subc. Orig. Bin Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Direct Creator", 'OnBeforeModifyProdOrderRoutingLineFromTemp', '', false, false)]
    local procedure OnBeforeModifyProdOrderRoutingLineFromTemp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
        ProdOrderRoutingLine."Vendor No. Subc. Price" := TempProdOrderRoutingLine."Vendor No. Subc. Price";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Temp Prod. Order Comp. List", 'OnValidateOnAfterSubcontractingTypeChangedToNonTransfer', '', false, false)]
    local procedure OnValidateOnAfterSubcontractingTypeChangedToNonTransfer(var ProdOrderComponent: Record "Prod. Order Component")
    var
        Vendor: Record Vendor;
    begin
        if SubcontractingPurchaseLine."Buy-from Vendor No." = '' then
            exit;
        Vendor.SetLoadFields("Subc. Location Code");
        if Vendor.Get(SubcontractingPurchaseLine."Buy-from Vendor No.") then
            if Vendor."Subc. Location Code" <> '' then
                ProdOrderComponent.Validate("Location Code", Vendor."Subc. Location Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Definition Temp Data", 'OnBeforeInsertDefaultRoutingOperation', '', false, false)]
    local procedure OnBeforeInsertDefaultRoutingOperation(var TempRoutingLine: Record "Routing Line" temporary)
    var
        Vendor: Record Vendor;
    begin
        GetManufacturingSetup();
        if Vendor.Get(SubcontractingPurchaseLine."Buy-from Vendor No.") and (Vendor."Subc. Work Center No." <> '') then begin
            TempRoutingLine."No." := Vendor."Subc. Work Center No.";
            TempRoutingLine.Validate("No.");
            TempRoutingLine.Validate("Work Center No.", Vendor."Subc. Work Center No.");
        end;
        TempRoutingLine."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subcontracting Management", 'OnBeforeGetSubcontractor', '', false, false)]
    local procedure OnBeforeGetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
        GetSubcontractorForPurchaseProvision(Vendor, HasSubcontractor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subc. Calc. Prod. Order Ext.", 'OnAfterTransferSubcontractingFieldsBOMComponent', '', false, false)]
    local procedure OnAfterTransferSubcontractingFieldsBOMComponent(var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
        TransferSubcontractingFieldsBOMComponentForPurchaseProvision(ProdOrderComponent);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Direct Creator", OnConfigureProductionOrderFromTempOnBeforeModify, '', false, false)]
    local procedure OnConfigureProductionOrderFromTempOnBeforeModifySetCreatedFromPurch(var ProdOrder: Record "Production Order"; TempProdOrder: Record "Production Order" temporary)
    begin
        ProdOrder."Created from Purch. Order" := true;
    end;


    [EventSubscriber(ObjectType::Page, Page::"Temp Prod. Ord. Rtng List", OnNewRecordEvent, '', false, false)]
    local procedure OnNewRecordEventInitializeSubcSetupFields(var Rec: Record "Prod. Order Routing Line")
    begin
        GetManufacturingSetup();
        Rec."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Temp BOM Lines", OnNewRecordEvent, '', false, false)]
    local procedure OnNewRecordEventInitializeBOMLineSubcSetupFields(var Rec: Record "Production BOM Line")
    begin
        GetManufacturingSetup();
        Rec."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Temp Prod. Order Comp. List", OnNewRecordEvent, '', false, false)]
    local procedure OnNewRecordEventInitializeProdOrderCompSubcSetupFields(var Rec: Record "Prod. Order Component")
    begin
        GetManufacturingSetup();
        Rec."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Temp Routing Lines", OnNewRecordEvent, '', false, false)]
    local procedure OnNewRecordEventInitializeRoutingLineSubcSetupFields(var Rec: Record "Routing Line")
    begin
        GetManufacturingSetup();
        Rec."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
    end;

    local procedure GetSubcontractorForPurchaseProvision(var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
        if SubcontractingPurchaseLine."Buy-from Vendor No." = '' then
            exit;
        Vendor.Get(SubcontractingPurchaseLine."Buy-from Vendor No.");
        IsHandled := true;
        HasSubcontractor := true;
    end;

    local procedure TransferSubcontractingFieldsBOMComponentForPurchaseProvision(var ProdOrderComponent: Record "Prod. Order Component")
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
        ComponentsLocationCode: Code[10];
    begin
        GetManufacturingSetup();
        if (ProdOrderComponent."Routing Link Code" <> ManufacturingSetup."Subc. Rtng. Link Purch Prov") or
           (ProdOrderComponent."Component Supply Method" <> "Component Supply Method"::"Transfer to Vendor")
        then
            exit;

        ComponentsLocationCode := SubcontractingManagement.GetComponentsLocationCode(SubcontractingPurchaseLine);
        ProdOrderComponent.Validate("Location Code", ComponentsLocationCode);
        ProdOrderComponent."Subc. Original Location Code" := '';
    end;

    local procedure ValidatePurchLineForWizard(PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
    begin
        PurchaseLine.TestField(Type, "Purchase Line Type"::Item);
        PurchaseLine.TestField("Prod. Order No.", '');
        PurchaseLine.TestField("Prod. Order Line No.", 0);
        PurchaseLine.TestField("Qty. Assigned", 0);
        PurchaseLine.TestField("Qty. Rcd. Not Invoiced", 0);
        PurchaseLine.TestField(Quantity);
        PurchaseLine.TestField("Location Code");
        PurchaseLine.TestField("Expected Receipt Date");
        PurchaseLine.TestField("Drop Shipment", false);
        PurchaseLine.TestField("Special Order", false);

        PurchaseLine.TestStatusOpen();

        GetManufacturingSetup();
        ManufacturingSetup.TestField("Released Order Nos.");
        ManufacturingSetup.TestField("Production BOM Nos.");
        ManufacturingSetup.TestField("Routing Nos.");

        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        Vendor.TestField("Subc. Location Code");
    end;

    local procedure UpdatePurchaseLineWithProdOrder(var PurchLine: Record "Purchase Line"; ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        PurchLine."Prod. Order No." := ProdOrder."No.";
        PurchLine."Qty. per Unit of Measure" := 0;
        PurchLine."Quantity (Base)" := 0;
        PurchLine."Qty. to Invoice (Base)" := 0;
        PurchLine."Qty. to Receive (Base)" := 0;
        PurchLine."Outstanding Qty. (Base)" := 0;

        ProdOrderLine.SetLoadFields("Line No.");
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetRange("Item No.", PurchLine."No.");
        if ProdOrderLine.FindFirst() then
            PurchLine."Prod. Order Line No." := ProdOrderLine."Line No.";

        UpdatePurchLineWithRoutingInfo(PurchLine, ProdOrderLine);
        PurchLine.Modify(true);
    end;

    local procedure UpdatePurchLineWithRoutingInfo(var PurchLine: Record "Purchase Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if not FindRoutingLinesForProdOrderLine(ProdOrderRtngLine, ProdOrderLine) then
            exit;

        if FindMatchingWorkCenterForVendor(ProdOrderRtngLine, PurchLine."Buy-from Vendor No.") or
           FindAnySubcontractorWorkCenter(ProdOrderRtngLine)
        then begin
            UpdatePurchLineFromRoutingLine(PurchLine, ProdOrderRtngLine);
            exit;
        end;

        ProdOrderRtngLine.FindFirst();
        UpdatePurchLineFromRoutingLine(PurchLine, ProdOrderRtngLine);
    end;

    local procedure FindRoutingLinesForProdOrderLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        ProdOrderRtngLine.SetLoadFields("Work Center No.", "Operation No.", Description, "Routing No.", "Routing Reference No.", "Ending Date");
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRtngLine.SetRange(Type, "Capacity Type Routing"::"Work Center");
        exit(not ProdOrderRtngLine.IsEmpty());
    end;

    local procedure FindMatchingWorkCenterForVendor(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; VendorNo: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRtngLine.FindSet() then
            repeat
                WorkCenter.SetLoadFields("Gen. Prod. Posting Group");
                WorkCenter.SetRange("No.", ProdOrderRtngLine."Work Center No.");
                WorkCenter.SetRange("Subcontractor No.", VendorNo);
                if WorkCenter.FindFirst() then
                    exit(true);
            until ProdOrderRtngLine.Next() = 0;
        exit(false);
    end;

    local procedure FindAnySubcontractorWorkCenter(var ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        if not ProdOrderRtngLine.FindSet() then
            exit(false);
        repeat
            WorkCenter.SetLoadFields("Gen. Prod. Posting Group");
            WorkCenter.SetRange("No.", ProdOrderRtngLine."Work Center No.");
            WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
            if WorkCenter.FindFirst() then
                exit(true);
        until ProdOrderRtngLine.Next() = 0;
        exit(false);
    end;

    local procedure UpdatePurchLineFromRoutingLine(var PurchLine: Record "Purchase Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line")
    var
        SubPriceManagement: Codeunit "Subc. Price Management";
    begin
        PurchLine.Description := ProdOrderRtngLine.Description;
        PurchLine."Routing No." := ProdOrderRtngLine."Routing No.";
        PurchLine."Routing Reference No." := ProdOrderRtngLine."Routing Reference No.";
        PurchLine."Operation No." := ProdOrderRtngLine."Operation No.";
        PurchLine."Expected Receipt Date" := ProdOrderRtngLine."Ending Date";
        PurchLine.Validate("Work Center No.", ProdOrderRtngLine."Work Center No.");
        SubPriceManagement.GetSubcPriceForPurchLine(PurchLine);
        PurchLine.GetItemTranslation();
    end;

    local procedure HandleSubcontractingAfterUpdate(var PurchLine: Record "Purchase Line")
    var
        RequisitionLine: Record "Requisition Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        NextLineNo: Integer;
    begin
        RequisitionLine.Init();
        RequisitionLine."Prod. Order No." := PurchLine."Prod. Order No.";
        RequisitionLine."Prod. Order Line No." := PurchLine."Prod. Order Line No.";
        RequisitionLine."Operation No." := PurchLine."Operation No.";
        RequisitionLine."Routing No." := PurchLine."Routing No.";
        RequisitionLine."Routing Reference No." := PurchLine."Routing Reference No.";

        SubcPurchaseOrderCreator.InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchLine, RequisitionLine);

        NextLineNo := PurchLine."Line No." + 10000;
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderComp(PurchLine, RequisitionLine, NextLineNo);
    end;

    local procedure GetManufacturingSetup()
    begin
        if not ManufacturingSetupRead then begin
            ManufacturingSetup.SetLoadFields(
                "Subc. Rtng. Link Purch Prov",
                "Def. Wiz. Comp Item No.",
                "Def. Wiz. Flushing Method",
                "Released Order Nos.",
                "Production BOM Nos.",
                "Routing Nos.",
                "Def. Wiz. Work Center No.");
            ManufacturingSetup.Get();
            ManufacturingSetupRead := true;
        end;
    end;
}