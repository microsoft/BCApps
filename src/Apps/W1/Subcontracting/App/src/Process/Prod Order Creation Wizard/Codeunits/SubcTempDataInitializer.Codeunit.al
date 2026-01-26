// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 99001552 "Subc. Temp Data Initializer"
{
    var
        TempGlobalProdOrderComponent: Record "Prod. Order Component" temporary;
        TempGlobalProdOrderLine: Record "Prod. Order Line" temporary;
        TempGlobalProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempGlobalProductionBOMHeader: Record "Production BOM Header" temporary;
        TempGlobalProductionBOMLine: Record "Production BOM Line" temporary;
        TempGlobalProductionOrder: Record "Production Order" temporary;
        TempGlobalPurchaseLine: Record "Purchase Line" temporary;
        TempGlobalRoutingHeader: Record "Routing Header" temporary;
        TempGlobalRoutingLine: Record "Routing Line" temporary;
        TempGlobalVendor: Record Vendor temporary;
        SubcManagementSetup: Record "Subc. Management Setup";
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
        SubcVersionMgmt: Codeunit "Subc. Version Mgmt.";
        HasSubManagementSetup: Boolean;
        SubcRtngBOMSourceType: Enum "Subc. RtngBOMSourceType";

    /// <summary>
    /// Initializes the temporary structure for production order processing based on a purchase line.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line to base the temporary structure on.</param>
    procedure InitializeTemporaryProdOrder(PurchaseLine: Record "Purchase Line")
    begin
        InitGlobalPurchLine(PurchaseLine);
        CreateTemporaryProductionOrder();
        CreateTemporaryProdOrderLine();
        ClearTemporaryProductionTables();
    end;

    /// <summary>
    /// Initializes the temporary structure for production order processing based on a purchase line.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line to base the temporary structure on.</param>
    procedure InitGlobalPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
        TempGlobalPurchaseLine.Reset();
        TempGlobalPurchaseLine.DeleteAll();
        TempGlobalPurchaseLine := PurchaseLine;
        TempGlobalPurchaseLine.Insert();
    end;

    local procedure CreateTemporaryProductionOrder()
    var
        TempProdOrderNoLbl: Label 'TEMP-%1', Locked = true, MaxLength = 20;
    begin
        TempGlobalProductionBOMLine.Reset();
        TempGlobalProductionBOMLine.DeleteAll();
        TempGlobalProductionOrder.Init();
        TempGlobalProductionOrder.Status := "Production Order Status"::Released;
        TempGlobalProductionOrder."No." := StrSubstNo(TempProdOrderNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempGlobalProductionOrder."Source Type" := "Prod. Order Source Type"::Item;
        TempGlobalProductionOrder."Source No." := TempGlobalPurchaseLine."No.";
        if TempGlobalPurchaseLine."Variant Code" <> '' then
            TempGlobalProductionOrder."Variant Code" := TempGlobalPurchaseLine."Variant Code";
        TempGlobalProductionOrder."Due Date" := TempGlobalPurchaseLine."Expected Receipt Date";
        TempGlobalProductionOrder.Quantity := TempGlobalPurchaseLine."Quantity (Base)";
        TempGlobalProductionOrder."Location Code" := TempGlobalPurchaseLine."Location Code";
        TempGlobalProductionOrder."Created from Purch. Order" := true;
        TempGlobalProductionOrder.Insert();
    end;

    local procedure CreateTemporaryProdOrderLine()
    var
        Item: Record Item;
    begin
        TempGlobalProdOrderLine.Init();
        TempGlobalProdOrderLine.Status := TempGlobalProductionOrder.Status;
        TempGlobalProdOrderLine."Prod. Order No." := TempGlobalProductionOrder."No.";
        TempGlobalProdOrderLine."Line No." := 10000;
        TempGlobalProdOrderLine."Routing Reference No." := TempGlobalProdOrderLine."Line No.";
        TempGlobalProdOrderLine."Item No." := TempGlobalProductionOrder."Source No.";
        TempGlobalProdOrderLine."Location Code" := TempGlobalProductionOrder."Location Code";
        TempGlobalProdOrderLine."Variant Code" := TempGlobalProductionOrder."Variant Code";
        TempGlobalProdOrderLine.Description := TempGlobalProductionOrder.Description;
        TempGlobalProdOrderLine."Description 2" := TempGlobalProductionOrder."Description 2";
        TempGlobalProdOrderLine.Quantity := TempGlobalProductionOrder.Quantity;
        TempGlobalProdOrderLine."Due Date" := TempGlobalProductionOrder."Due Date";
        TempGlobalProdOrderLine."Starting Date-Time" := TempGlobalProductionOrder."Starting Date-Time";
        TempGlobalProdOrderLine."Ending Date-Time" := TempGlobalProductionOrder."Ending Date-Time";

        Item.SetLoadFields("Scrap %", "Inventory Posting Group");
        Item.Get(TempGlobalProductionOrder."Source No.");
        TempGlobalProdOrderLine."Scrap %" := Item."Scrap %";
        TempGlobalProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";

        GetSubmanagementSetup();

        TempGlobalProdOrderLine.Insert();
    end;

    local procedure ClearTemporaryProductionTables()
    begin
        TempGlobalProdOrderComponent.Reset();
        TempGlobalProdOrderComponent.DeleteAll();
        TempGlobalProdOrderRoutingLine.Reset();
        TempGlobalProdOrderRoutingLine.DeleteAll();
    end;

    /// <summary>
    /// Initializes new temporary BOM information for items without existing BOM.
    /// </summary>
    procedure InitializeNewTemporaryBOMInformation()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        BOMNo: Code[20];
    begin
        ClearBOMTables();
        GetSubmanagementSetup();

        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Production BOM Nos.");

        Item.SetLoadFields(Description, "Base Unit of Measure", "No.");
        if not Item.Get(TempGlobalPurchaseLine."No.") then
            exit;

        BOMNo := InitializeTemporaryBOMHeaderFromSetup(Item);

        InitializeTemporaryBOMLineFromSetup(BOMNo);
    end;

    local procedure InitializeTemporaryBOMHeaderFromSetup(Item: Record Item): Code[20]
    var
        BOMNo: Code[20];
        BOMForLbl: Label 'BOM for %1', Comment = '%1 = Item description';
        TempBOMNoLbl: Label 'TEMP-BOM-%1', Locked = true, MaxLength = 20;
    begin
        TempGlobalProductionBOMHeader.Init();
        BOMNo := StrSubstNo(TempBOMNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempGlobalProductionBOMHeader."No." := BOMNo;
        TempGlobalProductionBOMHeader.Description := CopyStr(StrSubstNo(BOMForLbl, Item.Description), 1, MaxStrLen(TempGlobalProductionBOMHeader.Description));
        TempGlobalProductionBOMHeader."Unit of Measure Code" := Item."Base Unit of Measure";
        TempGlobalProductionBOMHeader.Insert();
        exit(BOMNo);
    end;

    local procedure InitializeTemporaryBOMLineFromSetup(BOMNo: Code[20])
    begin
        GetSubmanagementSetup();
        TempGlobalProductionBOMLine.Init();
        TempGlobalProductionBOMLine."Production BOM No." := BOMNo;
        TempGlobalProductionBOMLine."Line No." := 10000;
        TempGlobalProductionBOMLine."Type" := "Production BOM Line Type"::Item;
        TempGlobalProductionBOMLine.Validate("No.", SubcManagementSetup."Preset Component Item No.");
        TempGlobalProductionBOMLine."Quantity per" := 1;
        TempGlobalProductionBOMLine."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
        TempGlobalProductionBOMLine."Subcontracting Type" := "Subcontracting Type"::InventoryByVendor;
        TempGlobalProductionBOMLine.Insert();
    end;

    /// <summary>
    /// Initializes new temporary routing information for items without existing routing.
    /// </summary>
    procedure InitializeNewTemporaryRoutingInformation()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        RoutingNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        ClearRoutingTables();
        GetSubmanagementSetup();

        ManufacturingSetup.SetLoadFields("Routing Nos.");
        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Routing Nos.");

        Item.SetLoadFields(Description, "Base Unit of Measure", "No.");
        Item.Get(TempGlobalPurchaseLine."No.");

        RoutingNo := InitializeTemporaryRoutingHeaderFromSetup(Item);
        WorkCenterNo := DetermineWorkCenter();
        InitializeTemporaryRoutingLinesFromSetup(RoutingNo, WorkCenterNo);
        TempGlobalProdOrderLine."Routing No." := RoutingNo;
        TempGlobalProdOrderLine.Modify();
    end;

    local procedure InitializeTemporaryRoutingHeaderFromSetup(Item: Record Item): Code[20]
    var
        RoutingNo: Code[20];
        RoutingForLbl: Label 'Routing for %1', Comment = '%1 = Item description';
        TempRoutingNoLbl: Label 'TEMP-RTNG-%1', Locked = true, MaxLength = 20;
    begin
        TempGlobalRoutingHeader.Init();
        RoutingNo := StrSubstNo(TempRoutingNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempGlobalRoutingHeader."No." := RoutingNo;
        TempGlobalRoutingHeader.Description := CopyStr(StrSubstNo(RoutingForLbl, Item.Description), 1, MaxStrLen(TempGlobalRoutingHeader.Description));
        TempGlobalRoutingHeader.Insert();
        exit(RoutingNo);
    end;

    local procedure DetermineWorkCenter(): Code[20]
    var
        Vendor: Record Vendor;
        WorkCenterNo: Code[20];
    begin
        GetSubmanagementSetup();
        Vendor.SetLoadFields("Work Center No.");
        Vendor.Get(TempGlobalPurchaseLine."Buy-from Vendor No.");
        WorkCenterNo := Vendor."Work Center No.";
        if WorkCenterNo = '' then begin
            SubcManagementSetup.TestField("Common Work Center No.");
            WorkCenterNo := SubcManagementSetup."Common Work Center No.";
        end;
        exit(WorkCenterNo);
    end;

    local procedure InitializeTemporaryRoutingLinesFromSetup(RoutingNo: Code[20]; WorkCenterNo: Code[20])
    var
        Location: Record Location;
        PutAwayOperationLbl: Label 'Put-Away Operation';
        SubcontractingOperationLbl: Label 'Subcontracting Operation';
    begin
        TempGlobalRoutingLine.Init();
        TempGlobalRoutingLine."Routing No." := RoutingNo;
        TempGlobalRoutingLine."Operation No." := '10';
        TempGlobalRoutingLine.Type := "Capacity Type Routing"::"Work Center";
        TempGlobalRoutingLine."No." := WorkCenterNo;
        TempGlobalRoutingLine."Work Center No." := WorkCenterNo;
        TempGlobalRoutingLine.Description := CopyStr(SubcontractingOperationLbl, 1, MaxStrLen(TempGlobalRoutingLine.Description));
        TempGlobalRoutingLine."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
        TempGlobalRoutingLine.Insert();

        Location.SetLoadFields("Prod. Output Whse. Handling");
        Location.Get(TempGlobalPurchaseLine."Location Code");
        if Location."Prod. Output Whse. Handling" <> "Prod. Output Whse. Handling"::"No Warehouse Handling" then
            if SubcManagementSetup."Put-Away Work Center No." <> '' then begin
                TempGlobalRoutingLine.Init();
                TempGlobalRoutingLine."Routing No." := RoutingNo;
                TempGlobalRoutingLine."Operation No." := '20';
                TempGlobalRoutingLine.Type := "Capacity Type Routing"::"Work Center";
                TempGlobalRoutingLine."No." := SubcManagementSetup."Put-Away Work Center No.";
                TempGlobalRoutingLine."Work Center No." := SubcManagementSetup."Put-Away Work Center No.";
                TempGlobalRoutingLine.Description := CopyStr(PutAwayOperationLbl, 1, MaxStrLen(TempGlobalRoutingLine.Description));
                TempGlobalRoutingLine."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
                TempGlobalRoutingLine.Insert();
            end;
    end;

    /// <summary>
    /// Builds the temporary structure for production order processing based on the BOM and routing of the purchase line.
    /// Components and Prod. Order Routing Lines were created.
    /// </summary>
    procedure BuildTemporaryStructureFromBOMRouting()
    begin
        OnBeforeBuildTemporaryStructureFromBOMRouting(this);

        BuildTemporaryRoutingLines();

        BuildTemporaryComponents();

        GetVendor();
        SingleInstanceDictionary.SetCode('SetSubcontractingLocationCodeFromVendor', TempGlobalVendor."Subcontr. Location Code");
    end;

    local procedure BuildTemporaryComponents()
    var
        TempProductionBOMLine: Record "Production BOM Line" temporary;
        LineNo: Integer;
    begin
        TempGlobalProdOrderComponent.Reset();
        TempGlobalProdOrderComponent.DeleteAll();
        GetGlobalBOMLines(TempProductionBOMLine);
        if TempProductionBOMLine.FindSet() then begin
            LineNo := 0;
            repeat
                CreateTemporaryComponentFromBOMLine(TempProductionBOMLine, 1, LineNo);
            until TempProductionBOMLine.Next() = 0;
        end;
    end;

    local procedure BuildTemporaryRoutingLines()
    var
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        TempGlobalProdOrderRoutingLine.Reset();
        TempGlobalProdOrderRoutingLine.DeleteAll();
        GetGlobalRoutingLines(TempRoutingLine);
        if TempRoutingLine.FindSet() then
            repeat
                CreateTemporaryProdOrderRoutingLineFromRouting(TempRoutingLine);
            until TempRoutingLine.Next() = 0;
    end;

    local procedure CreateTemporaryComponentFromBOMLine(ProductionBOMLine: Record "Production BOM Line"; BOMQuantity: Decimal; var LineNo: Integer)
    var
        ProductionBOMLine_NextLevel: Record "Production BOM Line";
    begin

        GetSubmanagementSetup();

        case ProductionBOMLine.Type of
            "Production BOM Line Type"::Item:
                begin
                    LineNo += 10000;
                    TempGlobalProdOrderComponent.Init();
                    TempGlobalProdOrderComponent.Status := TempGlobalProdOrderLine.Status;
                    TempGlobalProdOrderComponent."Prod. Order No." := TempGlobalProdOrderLine."Prod. Order No.";
                    TempGlobalProdOrderComponent.Validate("Prod. Order Line No.", TempGlobalProdOrderLine."Line No.");
                    TempGlobalProdOrderComponent."Line No." := LineNo;
                    TempGlobalProdOrderComponent."Qty. per Unit of Measure" := 1;
                    TempGlobalProdOrderComponent.Validate("Item No.", ProductionBOMLine."No.");
                    TempGlobalProdOrderComponent.Description := ProductionBOMLine.Description;
                    TempGlobalProdOrderComponent.Validate("Quantity per", ProductionBOMLine."Quantity per" * BOMQuantity);
                    if ProductionBOMLine."Unit of Measure Code" <> '' then
                        TempGlobalProdOrderComponent.Validate("Unit of Measure Code", ProductionBOMLine."Unit of Measure Code");
                    TempGlobalProdOrderComponent.Validate("Routing Link Code", ProductionBOMLine."Routing Link Code");

                    TempGlobalProdOrderComponent."Subcontracting Type" := ProductionBOMLine."Subcontracting Type";
                    PresetComponentLocationCode();

                    if not SubcVersionMgmt.CheckBOMExists(ProductionBOMLine."Production BOM No.", '') then
                        TempGlobalProdOrderComponent.Validate("Flushing Method", SubcManagementSetup."Def. provision flushing method");

                    FillProdOrderComponentDefaultBin();
                    TempGlobalProdOrderComponent.Insert();
                end;
            "Production BOM Line Type"::"Production BOM":
                begin
                    ProductionBOMLine_NextLevel.SetRange("Production BOM No.", ProductionBOMLine."No.");
                    ProductionBOMLine_NextLevel.SetRange("Version Code", SubcVersionMgmt.GetDefaultBOMVersion(ProductionBOMLine."No."));
                    if ProductionBOMLine_NextLevel.FindSet() then
                        repeat
                            CreateTemporaryComponentFromBOMLine(ProductionBOMLine_NextLevel, ProductionBOMLine_NextLevel."Quantity per", LineNo);
                        until ProductionBOMLine_NextLevel.Next() = 0;
                end;
        end;
    end;

    local procedure CreateTemporaryProdOrderRoutingLineFromRouting(RoutingLine: Record "Routing Line")
    begin
        GetSubmanagementSetup();
        GetVendor();

        TempGlobalProdOrderRoutingLine.Init();
        TempGlobalProdOrderRoutingLine.Status := TempGlobalProdOrderLine.Status;
        TempGlobalProdOrderRoutingLine."Prod. Order No." := TempGlobalProdOrderLine."Prod. Order No.";
        TempGlobalProdOrderRoutingLine."Routing No." := RoutingLine."Routing No.";
        TempGlobalProdOrderRoutingLine.Validate("Routing Reference No.", TempGlobalProdOrderLine."Line No.");
        TempGlobalProdOrderRoutingLine.Validate("Operation No.", RoutingLine."Operation No.");
        TempGlobalProdOrderRoutingLine.Validate(Type, RoutingLine.Type);
        TempGlobalProdOrderRoutingLine.Validate("No.", RoutingLine."No.");
        TempGlobalProdOrderRoutingLine.Validate("Work Center No.", RoutingLine."Work Center No.");
        TempGlobalProdOrderRoutingLine.Description := RoutingLine.Description;
        TempGlobalProdOrderRoutingLine.Validate("Setup Time", RoutingLine."Setup Time");
        TempGlobalProdOrderRoutingLine.Validate("Run Time", RoutingLine."Run Time");
        TempGlobalProdOrderRoutingLine.Validate("Wait Time", RoutingLine."Wait Time");
        TempGlobalProdOrderRoutingLine.Validate("Move Time", RoutingLine."Move Time");
        TempGlobalProdOrderRoutingLine.Validate("Ending Date", TempGlobalProdOrderLine."Ending Date");
        TempGlobalProdOrderRoutingLine.Validate("Ending Time", TempGlobalProdOrderLine."Ending Time");
        TempGlobalProdOrderRoutingLine."Routing Link Code" := RoutingLine."Routing Link Code";
        TempGlobalProdOrderRoutingLine.Validate("Vendor No. Subc. Price", TempGlobalVendor."No.");
        TempGlobalProdOrderRoutingLine.FillDefaultLocationAndBins();
        TempGlobalProdOrderRoutingLine.Insert();
    end;

    /// <summary>
    /// Loads BOM lines into temporary storage.
    /// </summary>
    /// <param name="BOMNo">The BOM number to load lines for.</param>
    /// <param name="VersionCode">The version code to filter by.</param>
    procedure LoadBOMLines(BOMNo: Code[20]; VersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ClearBOMTables();

        if BOMNo = '' then
            exit;

        SetBOMLineFilters(ProductionBOMLine, BOMNo, VersionCode);
        CopyBOMLinesToTemporary(ProductionBOMLine);
    end;

    local procedure SetBOMLineFilters(var ProductionBOMLine: Record "Production BOM Line"; BOMNo: Code[20]; VersionCode: Code[20])
    begin
        if VersionCode <> '' then begin
            ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
            ProductionBOMLine.SetRange("Version Code", VersionCode);
        end else begin
            ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
            ProductionBOMLine.SetRange("Version Code", '');
        end;
    end;

    local procedure CopyBOMLinesToTemporary(var ProductionBOMLine: Record "Production BOM Line")
    begin
        if ProductionBOMLine.FindSet() then
            repeat
                TempGlobalProductionBOMLine := ProductionBOMLine;
                TempGlobalProductionBOMLine.Insert();
            until ProductionBOMLine.Next() = 0;
    end;

    /// <summary>
    /// Loads routing lines into temporary storage.
    /// </summary>
    /// <param name="RoutingNo">The routing number to load lines for.</param>
    /// <param name="VersionCode">The version code to filter by.</param>
    procedure LoadRoutingLines(RoutingNo: Code[20]; VersionCode: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin

        ClearRoutingTables();

        if RoutingNo = '' then
            exit;

        if VersionCode = '' then
            VersionCode := SubcVersionMgmt.GetDefaultRoutingVersion(RoutingNo);

        SetRoutingLineFilters(RoutingLine, RoutingNo, VersionCode);
        CopyRoutingLinesToTemporary(RoutingLine);
    end;

    local procedure SetRoutingLineFilters(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; VersionCode: Code[20])
    begin
        if VersionCode <> '' then begin
            RoutingLine.SetRange("Routing No.", RoutingNo);
            RoutingLine.SetRange("Version Code", VersionCode);
        end else begin
            RoutingLine.SetRange("Routing No.", RoutingNo);
            RoutingLine.SetRange("Version Code", '');
        end;
    end;

    local procedure CopyRoutingLinesToTemporary(var RoutingLine: Record "Routing Line")
    begin
        if RoutingLine.FindSet() then
            repeat
                TempGlobalRoutingLine := RoutingLine;
                TempGlobalRoutingLine.Insert();
            until RoutingLine.Next() = 0;
    end;

    /// <summary>
    /// Updates the version code for all routing lines.
    /// </summary>
    /// <param name="NewVersionCode">The new version code to apply.</param>
    procedure UpdateRoutingVersionCode(NewVersionCode: Code[20])
    var
        TempRoutingLine: Record "Routing Line" temporary;
        TempRoutingLine2: Record "Routing Line" temporary;
    begin
        TempRoutingLine.Copy(TempGlobalRoutingLine, true);
        TempRoutingLine2.Copy(TempGlobalRoutingLine, true);

        TempRoutingLine.SetFilter("Version Code", '<>%1', NewVersionCode);
        if TempRoutingLine.FindSet() then
            repeat
                TempRoutingLine2 := TempRoutingLine;
                TempRoutingLine2."Version Code" := NewVersionCode;
                TempRoutingLine2.Insert();
            until TempRoutingLine.Next() = 0;

        TempRoutingLine.DeleteAll();
    end;

    /// <summary>
    /// Updates the version code for all BOM lines.
    /// </summary>
    /// <param name="NewVersionCode">The new version code to apply.</param>
    procedure UpdateBOMVersionCode(NewVersionCode: Code[20])
    var
        TempProductionBOMLine: Record "Production BOM Line" temporary;
        TempProductionBOMLine2: Record "Production BOM Line" temporary;
    begin
        TempProductionBOMLine.Copy(TempGlobalProductionBOMLine, true);
        TempProductionBOMLine2.Copy(TempGlobalProductionBOMLine, true);

        TempProductionBOMLine.SetFilter("Version Code", '<>%1', NewVersionCode);
        if TempProductionBOMLine.FindSet(true) then
            repeat
                TempProductionBOMLine2 := TempProductionBOMLine;
                TempProductionBOMLine2."Version Code" := NewVersionCode;
                TempProductionBOMLine2.Insert();
            until TempProductionBOMLine.Next() = 0;

        TempProductionBOMLine.DeleteAll();
    end;

    /// <summary>
    /// Gets the global routing lines as routing records.
    /// </summary>
    /// <param name="TempRoutingLines">The temporary routing lines to copy to.</param>
    procedure GetGlobalRoutingLinesAsRouting(var TempRoutingLines: Record "Routing Line" temporary)
    begin
        TempRoutingLines.Copy(TempGlobalRoutingLine, true);
    end;

    local procedure GetSubmanagementSetup()
    begin
        if HasSubManagementSetup then
            exit;
        if SubcManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    local procedure ClearBOMTables()
    begin
        TempGlobalProductionBOMLine.Reset();
        TempGlobalProductionBOMLine.DeleteAll();
    end;

    local procedure ClearRoutingTables()
    begin
        TempGlobalRoutingLine.Reset();
        TempGlobalRoutingLine.DeleteAll();
    end;

    local procedure FillProdOrderComponentDefaultBin()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        Item: Record Item;
    begin
        Item.SetLoadFields(Type);
        if not Item.Get(TempGlobalProdOrderComponent."Item No.") then
            exit;
        if not Item.IsInventoriableType() then
            exit;

        TempProdOrderRoutingLine.Copy(TempProdOrderRoutingLine, true);
        TempGlobalProdOrderComponent."Bin Code" := TempGlobalProdOrderComponent.GetDefaultConsumptionBin(TempProdOrderRoutingLine);
    end;

    local procedure GetVendor()
    var
        Vendor: Record Vendor;
    begin
        if (TempGlobalVendor."No." <> '') and (Vendor."No." = TempGlobalPurchaseLine."Buy-from Vendor No.") then
            exit;
        Vendor.Get(TempGlobalPurchaseLine."Buy-from Vendor No.");
        TempGlobalVendor := Vendor;
    end;

    local procedure PresetComponentLocationCode()
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
        ComponentsLocationCode: Code[10];
    begin

        ComponentsLocationCode := SubcontractingManagement.GetComponentsLocationCode(TempGlobalPurchaseLine);

        if TempGlobalProdOrderComponent."Routing Link Code" = SubcManagementSetup."Rtng. Link Code Purch. Prov." then
            case TempGlobalProdOrderComponent."Subcontracting Type" of
                "Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase:
                    begin
                        GetVendor();
                        TempGlobalProdOrderComponent.Validate("Location Code", TempGlobalVendor."Subcontr. Location Code");
                        TempGlobalProdOrderComponent."Orig. Location Code" := ComponentsLocationCode;
                    end;
                "Subcontracting Type"::Transfer:
                    TempGlobalProdOrderComponent.Validate("Location Code", ComponentsLocationCode);
            end;

        if TempGlobalProdOrderComponent."Location Code" = '' then
            TempGlobalProdOrderComponent.Validate("Location Code", TempGlobalProductionOrder."Location Code");
    end;

    /// <summary>
    /// Sets new BOM information from temporary records.
    /// </summary>
    /// <param name="TempProductionBOMHeader">The temporary BOM header to copy from.</param>
    /// <param name="TempProductionBOMLine">The temporary BOM lines to copy from.</param>
    procedure SetNewBOMInformation(var TempProductionBOMHeader: Record "Production BOM Header" temporary; var TempProductionBOMLine: Record "Production BOM Line" temporary)
    begin
        ClearBOMTables();
        TempGlobalProductionBOMHeader.Copy(TempProductionBOMHeader, true);
        TempGlobalProductionBOMLine.Copy(TempProductionBOMLine, true);
    end;

    /// <summary>
    /// Sets new routing information from temporary records.
    /// </summary>
    /// <param name="TempRoutingHeader">The temporary routing header to copy from.</param>
    /// <param name="TempRoutingLine">The temporary routing lines to copy from.</param>
    procedure SetNewRoutingInformation(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary)
    begin
        ClearRoutingTables();
        TempGlobalRoutingHeader.Copy(TempRoutingHeader, true);
        TempGlobalRoutingLine.Copy(TempRoutingLine, true);
    end;

    /// <summary>
    /// Sets new production order components from temporary records.
    /// </summary>
    /// <param name="TempProdOrderComponent">The temporary production order components to copy from.</param>
    procedure SetNewProdOrderComponent(var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    begin
        TempGlobalProdOrderComponent.Reset();
        TempGlobalProdOrderComponent.DeleteAll();
        TempGlobalProdOrderComponent.Copy(TempProdOrderComponent, true);
    end;

    /// <summary>
    /// Sets new production order routing lines from temporary records.
    /// </summary>
    /// <param name="TempProdOrderRoutingLine">The temporary production order routing lines to copy from.</param>
    procedure SetNewProdOrderRoutingLine(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
        TempGlobalProdOrderRoutingLine.Reset();
        TempGlobalProdOrderRoutingLine.DeleteAll();
        TempGlobalProdOrderRoutingLine.Copy(TempProdOrderRoutingLine, true);
    end;

    /// <summary>
    /// Sets new production order from temporary records.
    /// </summary>
    /// <param name="TempProductionOrder">The temporary production order to copy from.</param>
    procedure SetNewProdOrder(var TempProductionOrder: Record "Production Order" temporary)
    begin
        TempGlobalProductionOrder.Reset();
        TempGlobalProductionOrder.DeleteAll();
        TempGlobalProductionOrder.Copy(TempProductionOrder, true);
    end;

    /// <summary>
    /// Sets the routing and BOM source type.
    /// </summary>
    /// <param name="SourceType">The source type to set.</param>
    procedure SetRtngBOMSourceType(SourceType: Enum "Subc. RtngBOMSourceType")
    begin
        SubcRtngBOMSourceType := SourceType;
    end;

    /// <summary>
    /// Gets the global BOM lines.
    /// </summary>
    /// <param name="TempProductionBOMLine">The temporary BOM lines to copy to.</param>
    procedure GetGlobalBOMLines(var TempProductionBOMLine: Record "Production BOM Line" temporary)
    begin
        TempProductionBOMLine.Copy(TempGlobalProductionBOMLine, true);
    end;

    /// <summary>
    /// Gets the global routing lines.
    /// </summary>
    /// <param name="TempRoutingLine">The temporary routing lines to copy to.</param>
    procedure GetGlobalRoutingLines(var TempRoutingLine: Record "Routing Line" temporary)
    begin
        TempRoutingLine.Copy(TempGlobalRoutingLine, true);
    end;

    /// <summary>
    /// Gets the global BOM header.
    /// </summary>
    /// <param name="TempProductionBOMHeader">The temporary BOM header to copy to.</param>
    procedure GetGlobalBOMHeader(var TempProductionBOMHeader: Record "Production BOM Header" temporary)
    begin
        TempProductionBOMHeader.Copy(TempGlobalProductionBOMHeader, true);
    end;

    /// <summary>
    /// Gets the global routing header.
    /// </summary>
    /// <param name="TempRoutingHeader">The temporary routing header to copy to.</param>
    procedure GetGlobalRoutingHeader(var TempRoutingHeader: Record "Routing Header" temporary)
    begin
        TempRoutingHeader.Copy(TempGlobalRoutingHeader, true);
    end;

    /// <summary>
    /// Gets the global production order components.
    /// </summary>
    /// <param name="TempProdOrderComponent">The temporary production order components to copy to.</param>
    procedure GetGlobalProdOrderComponent(var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    begin
        TempProdOrderComponent.Copy(TempGlobalProdOrderComponent, true);
    end;

    /// <summary>
    /// Gets the global production order routing lines.
    /// </summary>
    /// <param name="TempProdOrderRoutingLine">The temporary production order routing lines to copy to.</param>
    procedure GetGlobalProdOrderRoutingLine(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
        TempProdOrderRoutingLine.Copy(TempGlobalProdOrderRoutingLine, true);
    end;

    /// <summary>
    /// Gets the global production order.
    /// </summary>
    /// <param name="TempProductionOrder">The temporary production order to copy to.</param>
    procedure GetGlobalProdOrder(var TempProductionOrder: Record "Production Order" temporary)
    begin
        TempProductionOrder.Copy(TempGlobalProductionOrder, true);
    end;

    /// <summary>
    /// Gets the global production order line.
    /// </summary>
    /// <param name="TempProdOrderLine">The temporary production order line to copy to.</param>
    procedure GetGlobalProdOrderLine(var TempProdOrderLine: Record "Prod. Order Line" temporary)
    begin
        TempProdOrderLine.Copy(TempGlobalProdOrderLine, true);
    end;

    /// <summary>
    /// Gets the routing and BOM source type.
    /// </summary>
    /// <returns>The current routing and BOM source type.</returns>
    procedure GetRtngBOMSourceType(): Enum "Subc. RtngBOMSourceType"
    begin
        exit(SubcRtngBOMSourceType);
    end;

    /// <summary>
    /// Gets the global purchase line.
    /// </summary>
    /// <param name="TempPurchaseLine">The temporary purchase line to copy to.</param>
    procedure GetGlobalPurchLine(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
        TempPurchaseLine.Copy(TempGlobalPurchaseLine, true);
    end;


    [InternalEvent(false, false)]
    local procedure OnBeforeBuildTemporaryStructureFromBOMRouting(SubcTempDataInitializer: Codeunit "Subc. Temp Data Initializer")
    begin
    end;
}