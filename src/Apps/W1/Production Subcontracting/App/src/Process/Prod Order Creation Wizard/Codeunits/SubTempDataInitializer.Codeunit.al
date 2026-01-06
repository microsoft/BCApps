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

codeunit 99001552 "Sub. Temp Data Initializer"
{
    var
        TempGlobalProdOrderComponent: Record "Prod. Order Component" temporary;
        TempGlobalProdOrderLine: Record "Prod. Order Line" temporary;
        TempGlobalProdOrderRtngLine: Record "Prod. Order Routing Line" temporary;
        TempGlobalBOMHeader: Record "Production BOM Header" temporary;
        TempGlobalBOMLine: Record "Production BOM Line" temporary;
        TempGlobalProdOrder: Record "Production Order" temporary;
        TempGlobalPurchLine: Record "Purchase Line" temporary;
        TempGlobalRoutingHeader: Record "Routing Header" temporary;
        TempGlobalRoutingLine: Record "Routing Line" temporary;
        TempGlobalVendor: Record Vendor temporary;
        SubManagementSetup: Record "Sub. Management Setup";
        SingleInstance: Codeunit "Single Instance Dictionary";
        SubVersionSelectionMgmt: Codeunit "Sub. Version Mgmt.";
        HasSubManagementSetup: Boolean;
        RtngBOMSourceType: Enum "Sub. RtngBOMSourceType";

    /// <summary>
    /// Initializes the temporary structure for production order processing based on a purchase line.
    /// </summary>
    /// <param name="PurchLine">The purchase line to base the temporary structure on.</param>
    procedure InitializeTemporaryProdOrder(PurchLine: Record "Purchase Line")
    begin
        InitGlobalPurchLine(PurchLine);
        CreateTemporaryProductionOrder();
        CreateTemporaryProdOrderLine();
        ClearTemporaryProductionTables();
    end;

    /// <summary>
    /// Initializes the temporary structure for production order processing based on a purchase line.
    /// </summary>
    /// <param name="PurchLine">The purchase line to base the temporary structure on.</param>
    procedure InitGlobalPurchLine(var PurchLine: Record "Purchase Line")
    begin
        TempGlobalPurchLine.Reset();
        TempGlobalPurchLine.DeleteAll();
        TempGlobalPurchLine := PurchLine;
        TempGlobalPurchLine.Insert();
    end;

    local procedure CreateTemporaryProductionOrder()
    var
        TempProdOrderNoLbl: Label 'TEMP-%1', Locked = true, MaxLength = 20;
    begin
        TempGlobalBOMLine.Reset();
        TempGlobalBOMLine.DeleteAll();
        TempGlobalProdOrder.Init();
        TempGlobalProdOrder.Status := "Production Order Status"::Released;
        TempGlobalProdOrder."No." := StrSubstNo(TempProdOrderNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempGlobalProdOrder."Source Type" := "Prod. Order Source Type"::Item;
        TempGlobalProdOrder."Source No." := TempGlobalPurchLine."No.";
        if TempGlobalPurchLine."Variant Code" <> '' then
            TempGlobalProdOrder."Variant Code" := TempGlobalPurchLine."Variant Code";
        TempGlobalProdOrder."Due Date" := TempGlobalPurchLine."Expected Receipt Date";
        TempGlobalProdOrder.Quantity := TempGlobalPurchLine."Quantity (Base)";
        TempGlobalProdOrder."Location Code" := TempGlobalPurchLine."Location Code";
        TempGlobalProdOrder."Created from Purch. Order" := true;
        TempGlobalProdOrder.Insert();
    end;

    local procedure CreateTemporaryProdOrderLine()
    var
        Item: Record Item;
    begin
        TempGlobalProdOrderLine.Init();
        TempGlobalProdOrderLine.Status := TempGlobalProdOrder.Status;
        TempGlobalProdOrderLine."Prod. Order No." := TempGlobalProdOrder."No.";
        TempGlobalProdOrderLine."Line No." := 10000;
        TempGlobalProdOrderLine."Routing Reference No." := TempGlobalProdOrderLine."Line No.";
        TempGlobalProdOrderLine."Item No." := TempGlobalProdOrder."Source No.";
        TempGlobalProdOrderLine."Location Code" := TempGlobalProdOrder."Location Code";
        TempGlobalProdOrderLine."Variant Code" := TempGlobalProdOrder."Variant Code";
        TempGlobalProdOrderLine.Description := TempGlobalProdOrder.Description;
        TempGlobalProdOrderLine."Description 2" := TempGlobalProdOrder."Description 2";
        TempGlobalProdOrderLine.Quantity := TempGlobalProdOrder.Quantity;
        TempGlobalProdOrderLine."Due Date" := TempGlobalProdOrder."Due Date";
        TempGlobalProdOrderLine."Starting Date-Time" := TempGlobalProdOrder."Starting Date-Time";
        TempGlobalProdOrderLine."Ending Date-Time" := TempGlobalProdOrder."Ending Date-Time";

        Item.SetLoadFields("Scrap %", "Inventory Posting Group");
        Item.Get(TempGlobalProdOrder."Source No.");
        TempGlobalProdOrderLine."Scrap %" := Item."Scrap %";
        TempGlobalProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";

        GetSubmanagementSetup();

        TempGlobalProdOrderLine.Insert();
    end;

    local procedure ClearTemporaryProductionTables()
    begin
        TempGlobalProdOrderComponent.Reset();
        TempGlobalProdOrderComponent.DeleteAll();
        TempGlobalProdOrderRtngLine.Reset();
        TempGlobalProdOrderRtngLine.DeleteAll();
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
        if not Item.Get(TempGlobalPurchLine."No.") then
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
        TempGlobalBOMHeader.Init();
        BOMNo := StrSubstNo(TempBOMNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempGlobalBOMHeader."No." := BOMNo;
        TempGlobalBOMHeader.Description := CopyStr(StrSubstNo(BOMForLbl, Item.Description), 1, MaxStrLen(TempGlobalBOMHeader.Description));
        TempGlobalBOMHeader."Unit of Measure Code" := Item."Base Unit of Measure";
        TempGlobalBOMHeader.Insert();
        exit(BOMNo);
    end;

    local procedure InitializeTemporaryBOMLineFromSetup(BOMNo: Code[20])
    begin
        GetSubmanagementSetup();
        TempGlobalBOMLine.Init();
        TempGlobalBOMLine."Production BOM No." := BOMNo;
        TempGlobalBOMLine."Line No." := 10000;
        TempGlobalBOMLine."Type" := "Production BOM Line Type"::Item;
        TempGlobalBOMLine.Validate("No.", SubManagementSetup."Preset Component Item No.");
        TempGlobalBOMLine."Quantity per" := 1;
        TempGlobalBOMLine."Routing Link Code" := SubManagementSetup."Rtng. Link Code Purch. Prov.";
        TempGlobalBOMLine."Subcontracting Type" := "Subcontracting Type"::InventoryByVendor;
        TempGlobalBOMLine.Insert();
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
        Item.Get(TempGlobalPurchLine."No.");

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
        Vendor.Get(TempGlobalPurchLine."Buy-from Vendor No.");
        WorkCenterNo := Vendor."Work Center No.";
        if WorkCenterNo = '' then begin
            SubManagementSetup.TestField("Common Work Center No.");
            WorkCenterNo := SubManagementSetup."Common Work Center No.";
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
        TempGlobalRoutingLine."Routing Link Code" := SubManagementSetup."Rtng. Link Code Purch. Prov.";
        TempGlobalRoutingLine.Insert();

        Location.SetLoadFields("Prod. Output Whse. Handling");
        Location.Get(TempGlobalPurchLine."Location Code");
        if Location."Prod. Output Whse. Handling" <> "Prod. Output Whse. Handling"::"No Warehouse Handling" then
            if SubManagementSetup."Put-Away Work Center No." <> '' then begin
                TempGlobalRoutingLine.Init();
                TempGlobalRoutingLine."Routing No." := RoutingNo;
                TempGlobalRoutingLine."Operation No." := '20';
                TempGlobalRoutingLine.Type := "Capacity Type Routing"::"Work Center";
                TempGlobalRoutingLine."No." := SubManagementSetup."Put-Away Work Center No.";
                TempGlobalRoutingLine."Work Center No." := SubManagementSetup."Put-Away Work Center No.";
                TempGlobalRoutingLine.Description := CopyStr(PutAwayOperationLbl, 1, MaxStrLen(TempGlobalRoutingLine.Description));
                TempGlobalRoutingLine."Routing Link Code" := SubManagementSetup."Rtng. Link Code Purch. Prov.";
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
        SingleInstance.SetCode('SetSubcontractingLocationCodeFromVendor', TempGlobalVendor."Subcontr. Location Code");
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
        TempGlobalProdOrderRtngLine.Reset();
        TempGlobalProdOrderRtngLine.DeleteAll();
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

                    if not SubVersionSelectionMgmt.CheckBOMExists(ProductionBOMLine."Production BOM No.", '') then
                        TempGlobalProdOrderComponent.Validate("Flushing Method", SubManagementSetup."Def. provision flushing method");

                    FillProdOrderComponentDefaultBin();
                    TempGlobalProdOrderComponent.Insert();
                end;
            "Production BOM Line Type"::"Production BOM":
                begin
                    ProductionBOMLine_NextLevel.SetRange("Production BOM No.", ProductionBOMLine."No.");
                    ProductionBOMLine_NextLevel.SetRange("Version Code", SubVersionSelectionMgmt.GetDefaultBOMVersion(ProductionBOMLine."No."));
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

        TempGlobalProdOrderRtngLine.Init();
        TempGlobalProdOrderRtngLine.Status := TempGlobalProdOrderLine.Status;
        TempGlobalProdOrderRtngLine."Prod. Order No." := TempGlobalProdOrderLine."Prod. Order No.";
        TempGlobalProdOrderRtngLine."Routing No." := RoutingLine."Routing No.";
        TempGlobalProdOrderRtngLine.Validate("Routing Reference No.", TempGlobalProdOrderLine."Line No.");
        TempGlobalProdOrderRtngLine.Validate("Operation No.", RoutingLine."Operation No.");
        TempGlobalProdOrderRtngLine.Validate(Type, RoutingLine.Type);
        TempGlobalProdOrderRtngLine.Validate("No.", RoutingLine."No.");
        TempGlobalProdOrderRtngLine.Validate("Work Center No.", RoutingLine."Work Center No.");
        TempGlobalProdOrderRtngLine.Description := RoutingLine.Description;
        TempGlobalProdOrderRtngLine.Validate("Setup Time", RoutingLine."Setup Time");
        TempGlobalProdOrderRtngLine.Validate("Run Time", RoutingLine."Run Time");
        TempGlobalProdOrderRtngLine.Validate("Wait Time", RoutingLine."Wait Time");
        TempGlobalProdOrderRtngLine.Validate("Move Time", RoutingLine."Move Time");
        TempGlobalProdOrderRtngLine.Validate("Ending Date", TempGlobalProdOrderLine."Ending Date");
        TempGlobalProdOrderRtngLine.Validate("Ending Time", TempGlobalProdOrderLine."Ending Time");
        TempGlobalProdOrderRtngLine."Routing Link Code" := RoutingLine."Routing Link Code";
        TempGlobalProdOrderRtngLine.Validate("Vendor No. Subc. Price", TempGlobalVendor."No.");
        TempGlobalProdOrderRtngLine.FillDefaultLocationAndBins();
        TempGlobalProdOrderRtngLine.Insert();
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
                TempGlobalBOMLine := ProductionBOMLine;
                TempGlobalBOMLine.Insert();
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
            VersionCode := SubVersionSelectionMgmt.GetDefaultRoutingVersion(RoutingNo);

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
        TempBOMLine: Record "Production BOM Line" temporary;
        TempBOMLine2: Record "Production BOM Line" temporary;
    begin
        TempBOMLine.Copy(TempGlobalBOMLine, true);
        TempBOMLine2.Copy(TempGlobalBOMLine, true);

        TempBOMLine.SetFilter("Version Code", '<>%1', NewVersionCode);
        if TempBOMLine.FindSet(true) then
            repeat
                TempBOMLine2 := TempBOMLine;
                TempBOMLine2."Version Code" := NewVersionCode;
                TempBOMLine2.Insert();
            until TempBOMLine.Next() = 0;

        TempBOMLine.DeleteAll();
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
        if SubManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    local procedure ClearBOMTables()
    begin
        TempGlobalBOMLine.Reset();
        TempGlobalBOMLine.DeleteAll();
    end;

    local procedure ClearRoutingTables()
    begin
        TempGlobalRoutingLine.Reset();
        TempGlobalRoutingLine.DeleteAll();
    end;

    local procedure FillProdOrderComponentDefaultBin()
    var
        TempProdOrderRtngLine: Record "Prod. Order Routing Line" temporary;
        Item: Record Item;
    begin
        Item.SetLoadFields(Type);
        if not Item.Get(TempGlobalProdOrderComponent."Item No.") then
            exit;
        if not Item.IsInventoriableType() then
            exit;

        TempProdOrderRtngLine.Copy(TempGlobalProdOrderRtngLine, true);
        TempGlobalProdOrderComponent."Bin Code" := TempGlobalProdOrderComponent.GetDefaultConsumptionBin(TempProdOrderRtngLine);
    end;

    local procedure GetVendor()
    var
        Vendor: Record Vendor;
    begin
        if (TempGlobalVendor."No." <> '') and (Vendor."No." = TempGlobalPurchLine."Buy-from Vendor No.") then
            exit;
        Vendor.Get(TempGlobalPurchLine."Buy-from Vendor No.");
        TempGlobalVendor := Vendor;
    end;

    local procedure PresetComponentLocationCode()
    var
        SubcontractingMgmt: Codeunit "Subcontracting Mgmt.";
        ComponentsLocationCode: Code[10];
    begin

        ComponentsLocationCode := SubcontractingMgmt.GetComponentsLocationCode(TempGlobalPurchLine);

        if TempGlobalProdOrderComponent."Routing Link Code" = SubManagementSetup."Rtng. Link Code Purch. Prov." then
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
            TempGlobalProdOrderComponent.Validate("Location Code", TempGlobalProdOrder."Location Code");
    end;

    /// <summary>
    /// Sets new BOM information from temporary records.
    /// </summary>
    /// <param name="TempBOMHeader">The temporary BOM header to copy from.</param>
    /// <param name="TempBOMLines">The temporary BOM lines to copy from.</param>
    procedure SetNewBOMInformation(var TempBOMHeader: Record "Production BOM Header" temporary; var TempBOMLines: Record "Production BOM Line" temporary)
    begin
        ClearBOMTables();
        TempGlobalBOMHeader.Copy(TempBOMHeader, true);
        TempGlobalBOMLine.Copy(TempBOMLines, true);
    end;

    /// <summary>
    /// Sets new routing information from temporary records.
    /// </summary>
    /// <param name="TempRoutingHeader">The temporary routing header to copy from.</param>
    /// <param name="TempRoutingLines">The temporary routing lines to copy from.</param>
    procedure SetNewRoutingInformation(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLines: Record "Routing Line" temporary)
    begin
        ClearRoutingTables();
        TempGlobalRoutingHeader.Copy(TempRoutingHeader, true);
        TempGlobalRoutingLine.Copy(TempRoutingLines, true);
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
    /// <param name="TempProdOrderRtngLine">The temporary production order routing lines to copy from.</param>
    procedure SetNewProdOrderRoutingLine(var TempProdOrderRtngLine: Record "Prod. Order Routing Line" temporary)
    begin
        TempGlobalProdOrderRtngLine.Reset();
        TempGlobalProdOrderRtngLine.DeleteAll();
        TempGlobalProdOrderRtngLine.Copy(TempProdOrderRtngLine, true);
    end;

    /// <summary>
    /// Sets new production order from temporary records.
    /// </summary>
    /// <param name="TempProdOrder">The temporary production order to copy from.</param>
    procedure SetNewProdOrder(var TempProdOrder: Record "Production Order" temporary)
    begin
        TempGlobalProdOrder.Reset();
        TempGlobalProdOrder.DeleteAll();
        TempGlobalProdOrder.Copy(TempProdOrder, true);
    end;

    /// <summary>
    /// Sets the routing and BOM source type.
    /// </summary>
    /// <param name="SourceType">The source type to set.</param>
    procedure SetRtngBOMSourceType(SourceType: Enum "Sub. RtngBOMSourceType")
    begin
        RtngBOMSourceType := SourceType;
    end;

    /// <summary>
    /// Gets the global BOM lines.
    /// </summary>
    /// <param name="TempBOMLines">The temporary BOM lines to copy to.</param>
    procedure GetGlobalBOMLines(var TempBOMLines: Record "Production BOM Line" temporary)
    begin
        TempBOMLines.Copy(TempGlobalBOMLine, true);
    end;

    /// <summary>
    /// Gets the global routing lines.
    /// </summary>
    /// <param name="TempRoutingLines">The temporary routing lines to copy to.</param>
    procedure GetGlobalRoutingLines(var TempRoutingLines: Record "Routing Line" temporary)
    begin
        TempRoutingLines.Copy(TempGlobalRoutingLine, true);
    end;

    /// <summary>
    /// Gets the global BOM header.
    /// </summary>
    /// <param name="TempBOMHeader">The temporary BOM header to copy to.</param>
    procedure GetGlobalBOMHeader(var TempBOMHeader: Record "Production BOM Header" temporary)
    begin
        TempBOMHeader.Copy(TempGlobalBOMHeader, true);
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
    /// <param name="TempProdOrderRtngLine">The temporary production order routing lines to copy to.</param>
    procedure GetGlobalProdOrderRoutingLine(var TempProdOrderRtngLine: Record "Prod. Order Routing Line" temporary)
    begin
        TempProdOrderRtngLine.Copy(TempGlobalProdOrderRtngLine, true);
    end;

    /// <summary>
    /// Gets the global production order.
    /// </summary>
    /// <param name="TempProductionOrder">The temporary production order to copy to.</param>
    procedure GetGlobalProdOrder(var TempProductionOrder: Record "Production Order" temporary)
    begin
        TempProductionOrder.Copy(TempGlobalProdOrder, true);
    end;

    /// <summary>
    /// Gets the global production order line.
    /// </summary>
    /// <param name="TempProductionOrderLine">The temporary production order line to copy to.</param>
    procedure GetGlobalProdOrderLine(var TempProductionOrderLine: Record "Prod. Order Line" temporary)
    begin
        TempProductionOrderLine.Copy(TempGlobalProdOrderLine, true);
    end;

    /// <summary>
    /// Gets the routing and BOM source type.
    /// </summary>
    /// <returns>The current routing and BOM source type.</returns>
    procedure GetRtngBOMSourceType(): Enum "Sub. RtngBOMSourceType"
    begin
        exit(RtngBOMSourceType);
    end;

    /// <summary>
    /// Gets the global purchase line.
    /// </summary>
    /// <param name="TempPurchaseLine">The temporary purchase line to copy to.</param>
    procedure GetGlobalPurchLine(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
        TempPurchaseLine.Copy(TempGlobalPurchLine, true);
    end;


    [InternalEvent(false, false)]
    local procedure OnBeforeBuildTemporaryStructureFromBOMRouting(TempDataInitializer: Codeunit "Sub. Temp Data Initializer")
    begin
    end;
}