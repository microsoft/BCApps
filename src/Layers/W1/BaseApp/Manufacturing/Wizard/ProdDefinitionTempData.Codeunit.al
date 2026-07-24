// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 99001016 "Prod. Definition Temp Data"
{
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempBOMHeader: Record "Production BOM Header" temporary;
        TempBOMLine: Record "Production BOM Line" temporary;
        TempProdOrder: Record "Production Order" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        TempRoutingHeader: Record "Routing Header" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdDefinitionVersionMgmt: Codeunit "Prod. Definition Version Mgmt.";
        ProdOrdLineBind: Codeunit "Prod. Def. ProdOrdLine Bind";
        GlobalItemNo: Code[20];
        GlobalItemDescription: Text[100];
        GlobalBaseUOM: Code[10];
        ManufacturingSetupRead: Boolean;
        GlobalSourceType: Enum "Prod. Definition Source";
        RoutingBOMSourceType: Enum "Prod. Definition Source";
        ProdOrderStatus: Enum "Production Order Status";
        ItemInventoriableTypeCache: Dictionary of [Code[20], Boolean];
        TempProdOrderNoLbl: Label 'TEMP-%1', Locked = true, MaxLength = 20;
        ProductionOrderQtyZeroOrNegativeErr: Label 'Cannot create a production order from Sales Line %1 line %2: the calculated quantity (%3) is zero or negative because the line is fully or over-reserved.', Comment = '%1 = Document No., %2 = Line No., %3 = Quantity';
        BOMForLbl: Label 'BOM for %1';
        TempBOMNoLbl: Label 'TEMP-BOM-%1', Locked = true, MaxLength = 20;
        RoutingForLbl: Label 'Routing for %1';
        TempRoutingNoLbl: Label 'TEMP-RTNG-%1', Locked = true, MaxLength = 20;

    /// <summary>
    /// Initializes the temporary data from an item record, setting item details and clearing production tables.
    /// </summary>
    /// <param name="Item">The item to initialize the temporary production data from.</param>
    internal procedure InitializeFromItem(Item: Record Item)
    begin
        GlobalItemNo := Item."No.";
        GlobalItemDescription := Item.Description;
        GlobalBaseUOM := Item."Base Unit of Measure";
        ClearSourceContext();
        GlobalSourceType := "Prod. Definition Source"::Item;
        ClearTemporaryProductionTables();
    end;

    /// <summary>
    /// Initializes the temporary data from a sales line, creating a temporary production order and clearing production tables.
    /// </summary>
    /// <param name="SalesLine">The sales line to base the temporary production data on.</param>
    internal procedure InitializeFromSalesLine(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Location: Record Location;
    begin
        ClearSourceContext();
        GlobalSourceType := "Prod. Definition Source"::SalesLine;
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();

        GlobalItemNo := SalesLine."No.";
        GlobalItemDescription := SalesLine.Description;
        Item.SetLoadFields("Base Unit of Measure");
        if Item.Get(SalesLine."No.") then
            GlobalBaseUOM := Item."Base Unit of Measure";

        CreateTemporaryProductionOrderFromSalesLine(SalesLine);
        CreateTemporaryProdOrderLine();

        TempProdOrderLine.Description := SalesLine.Description;
        TempProdOrderLine."Description 2" := SalesLine."Description 2";
        if Location.Get(TempProdOrderLine."Location Code") and not Location."Require Pick" and (SalesLine."Bin Code" <> '') then
            TempProdOrderLine."Bin Code" := SalesLine."Bin Code";
        TempProdOrderLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        TempProdOrderLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        TempProdOrderLine."Dimension Set ID" := SalesLine."Dimension Set ID";
        TempProdOrderLine.Modify();

        ClearTemporaryProductionTables();
    end;

    /// <summary>
    /// Initializes the temporary data from a stockkeeping unit. The parent item's description and base unit of measure
    /// are resolved and stored alongside the SKU's location and variant codes for downstream BOM/routing resolution.
    /// </summary>
    /// <param name="SKU">The stockkeeping unit to initialize the temporary production data from.</param>
    internal procedure InitializeFromSKU(SKU: Record "Stockkeeping Unit")
    var
        Item: Record Item;
    begin
        ClearSourceContext();
        GlobalSourceType := "Prod. Definition Source"::StockkeepingUnit;
        TempSKU := SKU;
        TempSKU.Insert();

        Item.SetLoadFields(Description, "Base Unit of Measure");
        Item.Get(SKU."Item No.");
        GlobalItemNo := SKU."Item No.";
        GlobalItemDescription := Item.Description;
        GlobalBaseUOM := Item."Base Unit of Measure";
        ClearTemporaryProductionTables();
    end;

    local procedure CreateTemporaryProductionOrderFromSalesLine(SalesLine: Record "Sales Line")
    begin
        TempProdOrder.Reset();
        TempProdOrder.DeleteAll();
        TempProdOrder.Init();
        TempProdOrder.Status := ProdOrderStatus;
        TempProdOrder."No." := StrSubstNo(TempProdOrderNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempProdOrder."Starting Date" := WorkDate();
        TempProdOrder."Creation Date" := WorkDate();
        TempProdOrder."Due Date" := SalesLine."Shipment Date";
        TempProdOrder."Source Type" := "Prod. Order Source Type"::Item;
        TempProdOrder."Location Code" := SalesLine."Location Code";
        TempProdOrder.Validate("Source No.", SalesLine."No.");
        TempProdOrder.Validate("Variant Code", SalesLine."Variant Code");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        TempProdOrder.Quantity := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)";
        if TempProdOrder.Quantity <= 0 then
            Error(ProductionOrderQtyZeroOrNegativeErr, SalesLine."Document No.", SalesLine."Line No.", TempProdOrder.Quantity);
        TempProdOrder.InitRecord();
        TempProdOrder.Insert();
    end;

    /// <summary>
    /// Creates and inserts a temporary production order line from the current internal temporary production order.
    /// Call SetNewProdOrder first to ensure the production order context is set correctly.
    /// </summary>
    internal procedure CreateTemporaryProdOrderLine()
    var
        Item: Record Item;
    begin
        TempProdOrderLine.Reset();
        TempProdOrderLine.DeleteAll();
        TempProdOrderLine.Init();
        TempProdOrderLine.Status := TempProdOrder.Status;
        TempProdOrderLine."Prod. Order No." := TempProdOrder."No.";
        TempProdOrderLine."Line No." := 10000;
        TempProdOrderLine."Routing Reference No." := TempProdOrderLine."Line No.";
        TempProdOrderLine.Validate("Item No.", TempProdOrder."Source No.");
        TempProdOrderLine."Location Code" := TempProdOrder."Location Code";
        TempProdOrderLine.Validate("Variant Code", TempProdOrder."Variant Code");
        TempProdOrderLine.Validate(Quantity, TempProdOrder.Quantity);
        TempProdOrderLine."Due Date" := TempProdOrder."Due Date";

        Item.SetLoadFields("Scrap %", "Inventory Posting Group");
        if Item.Get(TempProdOrder."Source No.") then begin
            TempProdOrderLine."Scrap %" := Item."Scrap %";
            TempProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";
        end;

        TempProdOrderLine.Insert();
        BindProdOrderSubscriber();
    end;

    /// <summary>
    /// Clears the temporary production order component and routing line tables.
    /// Call this after SetNewProdOrder and CreateTemporaryProdOrderLine to reset the component/routing state.
    /// </summary>
    internal procedure ClearTemporaryProductionTables()
    begin
        TempProdOrderComponent.Reset();
        TempProdOrderComponent.DeleteAll();
        TempProdOrderRoutingLine.Reset();
        TempProdOrderRoutingLine.DeleteAll();
    end;

    local procedure ClearSourceContext()
    begin
        GlobalSourceType := "Prod. Definition Source"::Empty;
        TempSalesLine.Reset();
        TempSalesLine.DeleteAll();
        TempPurchLine.Reset();
        TempPurchLine.DeleteAll();
        TempSKU.Reset();
        TempSKU.DeleteAll();
    end;

    /// <summary>
    /// Creates a new blank temporary BOM header and an optional default component line for editing in the wizard.
    /// </summary>
    /// <param name="ItemNo">The item number the new BOM is being created for.</param>
    /// <param name="ItemDescription">The item description used to name the BOM.</param>
    /// <param name="BaseUOMCode">The base unit of measure code for the BOM header.</param>
    internal procedure InitializeNewTemporaryBOMInformation(ItemNo: Code[20]; ItemDescription: Text[100]; BaseUOMCode: Code[10])
    var
        BOMNo: Code[20];
    begin
        ClearBOMTables();

        GetManufacturingSetup();
        ManufacturingSetup.TestField("Production BOM Nos.");

        TempBOMHeader.Init();
        BOMNo := StrSubstNo(TempBOMNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempBOMHeader."No." := BOMNo;
        TempBOMHeader.Description := CopyStr(StrSubstNo(BOMForLbl, ItemDescription), 1, MaxStrLen(TempBOMHeader.Description));
        TempBOMHeader."Unit of Measure Code" := BaseUOMCode;
        TempBOMHeader.Insert();

        InitializeDefaultTemporaryBOMLine(BOMNo, ManufacturingSetup."Def. Wiz. Comp Item No.");
        UpdateProdOrderBOMInfo(BOMNo, '');
    end;

    /// <summary>
    /// Creates a new blank temporary routing header for editing in the wizard, and adds a default operation 10 if a common work center is configured.
    /// </summary>
    /// <param name="ItemNo">The item number the new routing is being created for.</param>
    /// <param name="ItemDescription">The item description used to name the routing.</param>
    internal procedure InitializeNewTemporaryRoutingInformation(ItemNo: Code[20]; ItemDescription: Text[100])
    var
        RoutingNo: Code[20];
    begin
        ClearRoutingTables();

        GetManufacturingSetup();
        ManufacturingSetup.TestField("Routing Nos.");

        TempRoutingHeader.Init();
        RoutingNo := StrSubstNo(TempRoutingNoLbl, CopyStr(Format(CreateGuid()), 2, 10));
        TempRoutingHeader."No." := RoutingNo;
        TempRoutingHeader.Description := CopyStr(StrSubstNo(RoutingForLbl, ItemDescription), 1, MaxStrLen(TempRoutingHeader.Description));
        TempRoutingHeader.Insert();

        AddDefaultRoutingOperation(RoutingNo, ManufacturingSetup."Def. Wiz. Work Center No.");
        UpdateProdOrderRoutingInfo(RoutingNo, '');
        OnAfterInitializeNewTemporaryRoutingInformation(TempRoutingHeader, TempRoutingLine, ItemNo);
    end;

    local procedure InitializeDefaultTemporaryBOMLine(BOMNo: Code[20]; DefaultComponentItemNo: Code[20])
    begin
        if DefaultComponentItemNo = '' then
            exit;

        TempBOMLine.Init();
        TempBOMLine."Production BOM No." := BOMNo;
        TempBOMLine."Line No." := 10000;
        TempBOMLine.Type := "Production BOM Line Type"::Item;
        TempBOMLine.Validate("No.", DefaultComponentItemNo);
        TempBOMLine.Validate("Quantity per", 1);
        OnBeforeInsertDefaultTemporaryBOMLine(TempBOMLine, DefaultComponentItemNo);
        TempBOMLine.Insert();
    end;

    local procedure AddDefaultRoutingOperation(RoutingNo: Code[20]; DefaultWorkCenterNo: Code[20])
    begin
        if DefaultWorkCenterNo = '' then
            exit;

        TempRoutingLine.Init();
        TempRoutingLine."Routing No." := RoutingNo;
        TempRoutingLine."Operation No." := '10';
        TempRoutingLine.Type := "Capacity Type Routing"::"Work Center";
        TempRoutingLine.Validate("No.", DefaultWorkCenterNo);
        TempRoutingLine.Validate("Work Center No.", DefaultWorkCenterNo);
        OnBeforeInsertDefaultRoutingOperation(TempRoutingLine);
        TempRoutingLine.Insert();
    end;

    /// <summary>
    /// Builds the temporary production order component and routing line structures from the current temporary BOM and routing data.
    /// </summary>
    internal procedure BuildTemporaryStructureFromBOMRouting()
    begin
        BuildTemporaryRoutingLines();
        BuildTemporaryComponents();
    end;

    local procedure BuildTemporaryComponents()
    var
        TempProductionBOMLine: Record "Production BOM Line" temporary;
        LineNo: Integer;
    begin
        TempProdOrderComponent.Reset();
        TempProdOrderComponent.DeleteAll();

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
        TempRoutingLineCopy: Record "Routing Line" temporary;
    begin
        TempProdOrderRoutingLine.Reset();
        TempProdOrderRoutingLine.DeleteAll();
        GetGlobalRoutingLines(TempRoutingLineCopy);
        if TempRoutingLineCopy.FindSet() then
            repeat
                CreateTemporaryProdOrderRoutingLineFromRouting(TempRoutingLineCopy);
            until TempRoutingLineCopy.Next() = 0;
    end;

    local procedure CreateTemporaryComponentFromBOMLine(ProductionBOMLine: Record "Production BOM Line"; BOMQuantity: Decimal; var LineNo: Integer)
    var
        ProductionBOMLineNextLevel: Record "Production BOM Line";
        TempProdOrderRoutingLineCopy: Record "Prod. Order Routing Line" temporary;
        Item: Record Item;
    begin
        GetManufacturingSetup();

        case ProductionBOMLine.Type of
            "Production BOM Line Type"::Item:
                begin
                    LineNo += 10000;
                    TempProdOrderComponent.Init();
                    TempProdOrderComponent.Status := TempProdOrderLine.Status;
                    TempProdOrderComponent."Prod. Order No." := TempProdOrderLine."Prod. Order No.";
                    TempProdOrderComponent."Prod. Order Line No." := TempProdOrderLine."Line No.";
                    TempProdOrderComponent."Line No." := LineNo;
                    TempProdOrderComponent."Qty. per Unit of Measure" := 1;
                    TempProdOrderComponent.Validate("Item No.", ProductionBOMLine."No.");
                    TempProdOrderComponent.Validate("Variant Code", ProductionBOMLine."Variant Code");
                    TempProdOrderComponent.Description := ProductionBOMLine.Description;
                    TempProdOrderComponent."Description 2" := ProductionBOMLine."Description 2";
                    TempProdOrderComponent.Validate("Quantity per", ProductionBOMLine."Quantity per" * BOMQuantity);
                    if ProductionBOMLine."Unit of Measure Code" <> '' then
                        TempProdOrderComponent.Validate("Unit of Measure Code", ProductionBOMLine."Unit of Measure Code");
                    TempProdOrderComponent.Length := ProductionBOMLine.Length;
                    TempProdOrderComponent.Width := ProductionBOMLine.Width;
                    TempProdOrderComponent.Weight := ProductionBOMLine.Weight;
                    TempProdOrderComponent.Depth := ProductionBOMLine.Depth;
                    TempProdOrderComponent.Position := ProductionBOMLine.Position;
                    TempProdOrderComponent."Position 2" := ProductionBOMLine."Position 2";
                    TempProdOrderComponent."Position 3" := ProductionBOMLine."Position 3";
                    TempProdOrderComponent."Lead-Time Offset" := ProductionBOMLine."Lead-Time Offset";
                    TempProdOrderComponent.Validate("Scrap %", ProductionBOMLine."Scrap %");
                    TempProdOrderComponent.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula");
                    TempProdOrderComponent."Routing Link Code" := ProductionBOMLine."Routing Link Code";
                    if TempProdOrderLine."Location Code" <> '' then
                        TempProdOrderComponent.Validate("Location Code", TempProdOrderLine."Location Code");

                    Item.SetLoadFields(Type);
                    if Item.Get(TempProdOrderComponent."Item No.") and Item.IsInventoriableType() then begin
                        TempProdOrderRoutingLineCopy.Copy(TempProdOrderRoutingLine, true);
                        TempProdOrderComponent."Bin Code" := TempProdOrderComponent.GetDefaultConsumptionBin(TempProdOrderRoutingLineCopy);
                    end;

                    if not ProdDefinitionVersionMgmt.CheckBOMExists(ProductionBOMLine."Production BOM No.", '') then
                        TempProdOrderComponent."Flushing Method" := ManufacturingSetup."Def. Wiz. Flushing Method";
                    TempProdOrderComponent.Insert();
                    OnAfterCreateTemporaryComponentFromBOMLine(TempProdOrderComponent, ProductionBOMLine);
                end;
            "Production BOM Line Type"::"Production BOM":
                begin
                    ProductionBOMLineNextLevel.SetRange("Production BOM No.", ProductionBOMLine."No.");
                    ProductionBOMLineNextLevel.SetRange("Version Code", ProdDefinitionVersionMgmt.GetDefaultBOMVersion(ProductionBOMLine."No."));
                    if ProductionBOMLineNextLevel.FindSet() then
                        repeat
                            CreateTemporaryComponentFromBOMLine(ProductionBOMLineNextLevel, BOMQuantity * ProductionBOMLine."Quantity per", LineNo);
                        until ProductionBOMLineNextLevel.Next() = 0;
                end;
        end;
    end;

    local procedure CreateTemporaryProdOrderRoutingLineFromRouting(RoutingLine: Record "Routing Line")
    var
        WorkCenterNo: Code[20];
    begin
        TempProdOrderRoutingLine.Init();
        TempProdOrderRoutingLine.Status := TempProdOrderLine.Status;
        TempProdOrderRoutingLine."Prod. Order No." := TempProdOrderLine."Prod. Order No.";
        TempProdOrderRoutingLine."Routing No." := RoutingLine."Routing No.";
        TempProdOrderRoutingLine.Validate("Routing Reference No.", TempProdOrderLine."Line No.");
        TempProdOrderRoutingLine.Validate("Operation No.", RoutingLine."Operation No.");
        TempProdOrderRoutingLine.Insert();

        TempProdOrderRoutingLine.Validate(Type, RoutingLine.Type);

        WorkCenterNo := RoutingLine."Work Center No.";
        if WorkCenterNo = '' then begin
            GetManufacturingSetup();
            WorkCenterNo := ManufacturingSetup."Def. Wiz. Work Center No.";
        end;

        if (RoutingLine.Type = RoutingLine.Type::"Work Center") and (RoutingLine."No." = '') and (WorkCenterNo <> '') then
            TempProdOrderRoutingLine.Validate("No.", WorkCenterNo)
        else
            TempProdOrderRoutingLine.Validate("No.", RoutingLine."No.");

        TempProdOrderRoutingLine.Validate("Work Center No.", WorkCenterNo);
        TempProdOrderRoutingLine.Description := RoutingLine.Description;
        TempProdOrderRoutingLine."Description 2" := RoutingLine."Description 2";
        TempProdOrderRoutingLine.Validate("Setup Time", RoutingLine."Setup Time");
        TempProdOrderRoutingLine.Validate("Run Time", RoutingLine."Run Time");
        TempProdOrderRoutingLine.Validate("Wait Time", RoutingLine."Wait Time");
        TempProdOrderRoutingLine.Validate("Move Time", RoutingLine."Move Time");
        if TempProdOrderLine."Ending Date" <> 0D then
            TempProdOrderRoutingLine.Validate("Ending Date", TempProdOrderLine."Ending Date");
        if TempProdOrderLine."Ending Time" <> 0T then
            TempProdOrderRoutingLine.Validate("Ending Time", TempProdOrderLine."Ending Time");
        TempProdOrderRoutingLine."Routing Link Code" := RoutingLine."Routing Link Code";
        TempProdOrderRoutingLine."Previous Operation No." := RoutingLine."Previous Operation No.";
        TempProdOrderRoutingLine."Next Operation No." := RoutingLine."Next Operation No.";
        TempProdOrderRoutingLine."Setup Time Unit of Meas. Code" := RoutingLine."Setup Time Unit of Meas. Code";
        TempProdOrderRoutingLine."Run Time Unit of Meas. Code" := RoutingLine."Run Time Unit of Meas. Code";
        TempProdOrderRoutingLine."Wait Time Unit of Meas. Code" := RoutingLine."Wait Time Unit of Meas. Code";
        TempProdOrderRoutingLine."Move Time Unit of Meas. Code" := RoutingLine."Move Time Unit of Meas. Code";
        TempProdOrderRoutingLine."Fixed Scrap Quantity" := RoutingLine."Fixed Scrap Quantity";
        TempProdOrderRoutingLine."Scrap Factor %" := RoutingLine."Scrap Factor %";
        TempProdOrderRoutingLine."Send-Ahead Quantity" := RoutingLine."Send-Ahead Quantity";
        TempProdOrderRoutingLine."Concurrent Capacities" := RoutingLine."Concurrent Capacities";
        TempProdOrderRoutingLine."Lot Size" := RoutingLine."Lot Size";
        TempProdOrderRoutingLine."Unit Cost per" := RoutingLine."Unit Cost per";
        TempProdOrderRoutingLine.FillDefaultLocationAndBins();
        TempProdOrderRoutingLine.Modify();
        OnAfterCreateTemporaryProdOrderRoutingLineFromRouting(TempProdOrderRoutingLine, RoutingLine);
    end;

    /// <summary>
    /// Loads production BOM lines from the database into the internal temporary BOM line table.
    /// </summary>
    /// <param name="BOMNo">The production BOM number to load lines from.</param>
    /// <param name="VersionCode">The BOM version code to load. Use empty string for the base version.</param>
    internal procedure LoadBOMLines(BOMNo: Code[20]; VersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ClearBOMTables();
        UpdateProdOrderBOMInfo(BOMNo, VersionCode);

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
                TempBOMLine := ProductionBOMLine;
                TempBOMLine.Insert();
            until ProductionBOMLine.Next() = 0;
    end;

    /// <summary>
    /// Loads routing lines from the database into the internal temporary routing line table.
    /// </summary>
    /// <param name="RoutingNo">The routing number to load lines from.</param>
    /// <param name="VersionCode">The routing version code to load. If empty, the default active version is used.</param>
    internal procedure LoadRoutingLines(RoutingNo: Code[20]; VersionCode: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        ClearRoutingTables();
        UpdateProdOrderRoutingInfo(RoutingNo, VersionCode);

        if RoutingNo = '' then
            exit;

        if VersionCode = '' then
            VersionCode := ProdDefinitionVersionMgmt.GetDefaultRoutingVersion(RoutingNo);

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
                TempRoutingLine := RoutingLine;
                TempRoutingLine.Insert();
            until RoutingLine.Next() = 0;
    end;

    /// <summary>
    /// Updates the version code on all temporary routing lines to the specified new version code.
    /// </summary>
    /// <param name="NewVersionCode">The new version code to assign to all temporary routing lines.</param>
    internal procedure UpdateRoutingVersionCode(NewVersionCode: Code[20])
    var
        TempRoutingLineCopy: Record "Routing Line" temporary;
        TempRoutingLineToInsert: Record "Routing Line" temporary;
    begin
        TempRoutingLineCopy.Copy(TempRoutingLine, true);
        TempRoutingLineToInsert.Copy(TempRoutingLineCopy, true);

        TempRoutingLineCopy.SetFilter("Version Code", '<>%1', NewVersionCode);
        if TempRoutingLineCopy.FindSet() then
            repeat
                TempRoutingLineToInsert := TempRoutingLineCopy;
                TempRoutingLineToInsert."Version Code" := NewVersionCode;
                TempRoutingLineToInsert.Insert();
            until TempRoutingLineCopy.Next() = 0;

        TempRoutingLineCopy.DeleteAll();
    end;

    /// <summary>
    /// Updates the version code on all temporary BOM lines to the specified new version code.
    /// </summary>
    /// <param name="NewVersionCode">The new version code to assign to all temporary BOM lines.</param>
    internal procedure UpdateBOMVersionCode(NewVersionCode: Code[20])
    var
        TempBOMLineCopy: Record "Production BOM Line" temporary;
        TempBOMLineToInsert: Record "Production BOM Line" temporary;
    begin
        TempBOMLineCopy.Copy(TempBOMLine, true);
        TempBOMLineToInsert.Copy(TempBOMLineCopy, true);

        TempBOMLineCopy.SetFilter("Version Code", '<>%1', NewVersionCode);
        if TempBOMLineCopy.FindSet(true) then
            repeat
                TempBOMLineToInsert := TempBOMLineCopy;
                TempBOMLineToInsert."Version Code" := NewVersionCode;
                TempBOMLineToInsert.Insert();
            until TempBOMLineCopy.Next() = 0;

        TempBOMLineCopy.DeleteAll();
    end;

    local procedure ClearBOMTables()
    begin
        TempBOMHeader.Reset();
        TempBOMHeader.DeleteAll();
        TempBOMLine.Reset();
        TempBOMLine.DeleteAll();
    end;

    local procedure ClearRoutingTables()
    begin
        TempRoutingHeader.Reset();
        TempRoutingHeader.DeleteAll();
        TempRoutingLine.Reset();
        TempRoutingLine.DeleteAll();
    end;

    /// <summary>
    /// Replaces the internal temporary BOM data with the provided BOM header and lines.
    /// </summary>
    /// <param name="TempBOMHeader">The temporary BOM header to store.</param>
    /// <param name="TempBOMLines">The temporary BOM lines to store.</param>
    internal procedure SetNewBOMInformation(var TempBOMHeader2: Record "Production BOM Header" temporary; var TempBOMLines2: Record "Production BOM Line" temporary)
    begin
        ClearBOMTables();
        TempBOMHeader.Copy(TempBOMHeader2, true);
        TempBOMLine.Copy(TempBOMLines2, true);
    end;

    /// <summary>
    /// Replaces the internal temporary routing data with the provided routing header and lines.
    /// </summary>
    /// <param name="TempRoutingHeader">The temporary routing header to store.</param>
    /// <param name="TempRoutingLines">The temporary routing lines to store.</param>
    internal procedure SetNewRoutingInformation(var TempRoutingHeader2: Record "Routing Header" temporary; var TempRoutingLines2: Record "Routing Line" temporary)
    begin
        ClearRoutingTables();
        TempRoutingHeader.Copy(TempRoutingHeader2, true);
        TempRoutingLine.Copy(TempRoutingLines2, true);
    end;

    /// <summary>
    /// Replaces the internal temporary production order components with the provided records.
    /// </summary>
    /// <param name="TempProdOrderComponent">The temporary production order component records to store.</param>
    internal procedure SetNewProdOrderComponent(var TempProdOrderComponent2: Record "Prod. Order Component" temporary)
    begin
        TempProdOrderComponent.Reset();
        TempProdOrderComponent.DeleteAll();
        TempProdOrderComponent.Copy(TempProdOrderComponent2, true);
    end;

    /// <summary>
    /// Replaces the internal temporary production order routing lines with the provided records.
    /// </summary>
    /// <param name="TempProdOrderRoutingLine">The temporary production order routing line records to store.</param>
    internal procedure SetNewProdOrderRoutingLine(var TempProdOrderRoutingLine2: Record "Prod. Order Routing Line" temporary)
    begin
        TempProdOrderRoutingLine.Reset();
        TempProdOrderRoutingLine.DeleteAll();
        TempProdOrderRoutingLine.Copy(TempProdOrderRoutingLine2, true);
    end;

    /// <summary>
    /// Replaces the internal temporary production order with the provided record.
    /// </summary>
    /// <param name="TempProdOrder">The temporary production order record to store.</param>
    internal procedure SetNewProdOrder(var TempProdOrder2: Record "Production Order" temporary)
    begin
        TempProdOrder.Reset();
        TempProdOrder.DeleteAll();
        TempProdOrder.Copy(TempProdOrder2, true);
    end;

    /// <summary>
    /// Sets the global item context (item number and description) used throughout the wizard.
    /// This is normally set automatically by InitializeFromItem or InitializeFromSalesLine.
    /// Call this before SetNewProdOrder and CreateTemporaryProdOrderLine when initializing from a custom source type.
    /// </summary>
    /// <param name="ItemNo">The item number to set as the global item context.</param>
    /// <param name="ItemDescription">The item description to set as the global item context.</param>
    internal procedure SetGlobalItemInfo(ItemNo: Code[20]; ItemDescription: Text[100])
    begin
        GlobalItemNo := ItemNo;
        GlobalItemDescription := ItemDescription;
    end;

    /// <summary>
    /// Stores a copy of the given purchase line as the internal purchase line context.
    /// This is used by downstream logic (e.g. BOM/routing source resolution) that reads back the stored purchase line.
    /// </summary>
    /// <param name="PurchLine">The purchase line to store.</param>
    internal procedure SetNewPurchLine(PurchLine: Record "Purchase Line")
    begin
        TempPurchLine.Reset();
        TempPurchLine.DeleteAll();
        TempPurchLine := PurchLine;
        TempPurchLine.Insert();
    end;

    /// <summary>
    /// Sets the source type indicating whether the BOM/routing originates from an existing record or is newly defined.
    /// </summary>
    /// <param name="SourceType">The source type to set.</param>
    internal procedure SetRtngBOMSourceType(SourceType: Enum "Prod. Definition Source")
    begin
        RoutingBOMSourceType := SourceType;
    end;

    /// <summary>
    /// Returns the internal temporary BOM lines by copying them into the provided variable.
    /// </summary>
    /// <param name="TempBOMLines">The variable to receive the temporary BOM lines.</param>
    internal procedure GetGlobalBOMLines(var TempBOMLines: Record "Production BOM Line" temporary)
    begin
        TempBOMLines.Copy(TempBOMLine, true);
    end;

    /// <summary>
    /// Returns the internal temporary routing lines by copying them into the provided variable.
    /// </summary>
    /// <param name="TempRoutingLines">The variable to receive the temporary routing lines.</param>
    internal procedure GetGlobalRoutingLines(var TempRoutingLines: Record "Routing Line" temporary)
    begin
        TempRoutingLines.Copy(TempRoutingLine, true);
    end;

    /// <summary>
    /// Returns the internal temporary BOM header by copying it into the provided variable.
    /// </summary>
    /// <param name="TempBOMHeader">The variable to receive the temporary BOM header.</param>
    internal procedure GetGlobalBOMHeader(var TempBOMHeaderOut: Record "Production BOM Header" temporary)
    begin
        TempBOMHeaderOut.Copy(TempBOMHeader, true);
    end;

    /// <summary>
    /// Returns the internal temporary routing header by copying it into the provided variable.
    /// </summary>
    /// <param name="TempRoutingHeader">The variable to receive the temporary routing header.</param>
    internal procedure GetGlobalRoutingHeader(var TempRoutingHeaderOut: Record "Routing Header" temporary)
    begin
        TempRoutingHeaderOut.Copy(TempRoutingHeader, true);
    end;

    /// <summary>
    /// Returns the internal temporary production order components by copying them into the provided variable.
    /// </summary>
    /// <param name="TempProdOrderComponent">The variable to receive the temporary production order components.</param>
    internal procedure GetGlobalProdOrderComponent(var TempProdOrderComponentOut: Record "Prod. Order Component" temporary)
    begin
        TempProdOrderComponentOut.Copy(TempProdOrderComponent, true);
    end;

    /// <summary>
    /// Returns the internal temporary production order routing lines by copying them into the provided variable.
    /// </summary>
    /// <param name="TempProdOrderRoutingLine">The variable to receive the temporary production order routing lines.</param>
    internal procedure GetGlobalProdOrderRoutingLine(var TempProdOrderRoutingLineOut: Record "Prod. Order Routing Line" temporary)
    begin
        TempProdOrderRoutingLineOut.Copy(TempProdOrderRoutingLine, true);
    end;

    /// <summary>
    /// Returns the internal temporary production order by copying it into the provided variable.
    /// </summary>
    /// <param name="TempProductionOrder">The variable to receive the temporary production order.</param>
    internal procedure GetGlobalProdOrder(var TempProductionOrder: Record "Production Order" temporary)
    begin
        TempProductionOrder.Copy(TempProdOrder, true);
    end;

    /// <summary>
    /// Returns the internal temporary production order line by copying it into the provided variable.
    /// </summary>
    /// <param name="TempProductionOrderLine">The variable to receive the temporary production order line.</param>
    internal procedure GetGlobalProdOrderLine(var TempProductionOrderLine: Record "Prod. Order Line" temporary)
    begin
        TempProductionOrderLine.Copy(TempProdOrderLine, true);
    end;

    /// <summary>
    /// Sets the Routing No. on the temporary production order line.
    /// If the Prod. Order Routing Line already has a routing assigned, this will overwrite the existing routing reference with the new one.
    /// </summary>
    /// <param name="RoutingNo">The routing number to assign.</param>
    /// <param name="VersionCode">The routing version code to assign.</param>
    internal procedure UpdateProdOrderRoutingInfo(RoutingNo: Code[20]; VersionCode: Code[20])
    begin
        if TempProdOrderLine."Prod. Order No." = '' then
            exit;
        if not TempProdOrderLine.FindFirst() then
            exit;
        TempProdOrderLine."Routing No." := RoutingNo;
        TempProdOrderLine."Routing Version Code" := VersionCode;
        TempProdOrderLine.Modify();

        UpdateProdOrderRoutingLineRoutingNo(RoutingNo);
    end;

    local procedure UpdateProdOrderRoutingLineRoutingNo(NewRoutingNo: Code[20])
    var
        TempProdOrderRoutingLineCopy: Record "Prod. Order Routing Line" temporary;
        TempProdOrderRoutingLineToInsert: Record "Prod. Order Routing Line" temporary;
    begin
        TempProdOrderRoutingLineCopy.Copy(TempProdOrderRoutingLine, true);
        TempProdOrderRoutingLineToInsert.Copy(TempProdOrderRoutingLine, true);

        TempProdOrderRoutingLineCopy.SetFilter("Routing No.", '<>%1', NewRoutingNo);
        if TempProdOrderRoutingLineCopy.FindSet(true) then
            repeat
                TempProdOrderRoutingLineToInsert := TempProdOrderRoutingLineCopy;
                TempProdOrderRoutingLineToInsert."Routing No." := NewRoutingNo;
                TempProdOrderRoutingLineToInsert.Insert();
            until TempProdOrderRoutingLineCopy.Next() = 0;

        TempProdOrderRoutingLineCopy.DeleteAll();
    end;

    /// <summary>
    /// Sets the Production BOM No. and Version Code on the temporary production order line.
    /// </summary>
    /// <param name="BOMNo">The production BOM number to assign.</param>
    /// <param name="VersionCode">The production BOM version code to assign.</param>
    internal procedure UpdateProdOrderBOMInfo(BOMNo: Code[20]; VersionCode: Code[20])
    begin
        if TempProdOrderLine."Prod. Order No." = '' then
            exit;
        if not TempProdOrderLine.FindFirst() then
            exit;
        TempProdOrderLine."Production BOM No." := BOMNo;
        TempProdOrderLine."Production BOM Version Code" := VersionCode;
        TempProdOrderLine.Modify();
    end;

    /// <summary>
    /// Returns the currently stored BOM/routing source type.
    /// </summary>
    /// <returns>The source type indicating whether BOM/routing data originates from an existing record or is newly defined.</returns>
    internal procedure GetRtngBOMSourceType(): Enum "Prod. Definition Source"
    begin
        exit(RoutingBOMSourceType);
    end;

    /// <summary>
    /// Returns the stored global purchase line by copying it into the provided variable.
    /// </summary>
    /// <param name="TempPurchaseLine">The variable to receive the temporary purchase line.</param>
    internal procedure GetGlobalPurchLine(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
        TempPurchaseLine.Copy(TempPurchLine, true);
    end;

    /// <summary>
    /// Returns the stored global sales line by copying it into the provided variable.
    /// </summary>
    /// <param name="TempSalesLine">The variable to receive the temporary sales line.</param>
    internal procedure GetGlobalSalesLine(var TempSalesLineOut: Record "Sales Line" temporary)
    begin
        TempSalesLineOut.Copy(TempSalesLine, true);
    end;

    /// <summary>
    /// Returns the stored global stockkeeping unit by copying it into the provided variable.
    /// </summary>
    /// <param name="TempSKU">The variable to receive the temporary stockkeeping unit.</param>
    internal procedure GetGlobalSKU(var TempSKUOut: Record "Stockkeeping Unit" temporary)
    begin
        TempSKUOut.Copy(TempSKU, true);
    end;

    /// <summary>
    /// Returns the item number that was used to initialize this temporary data instance.
    /// </summary>
    /// <returns>The global item number.</returns>
    internal procedure GetGlobalItemNo(): Code[20]
    begin
        exit(GlobalItemNo);
    end;

    /// <summary>
    /// Returns the source record type that was used to initialize this temporary data instance,
    /// e.g. Item, StockkeepingUnit, SalesLine, or PurchaseLine.
    /// </summary>
    /// <returns>The source type enum value.</returns>
    internal procedure GetGlobalSourceType(): Enum "Prod. Definition Source"
    begin
        exit(GlobalSourceType);
    end;

    /// <summary>
    /// Sets the source record type. Use this when initializing TempData from an extension-handled source
    /// (e.g. in a subscriber to Prod. Def. Source Initializer.OnInitializeFromSource) so the source type
    /// is available to callers via GetGlobalSourceType.
    /// </summary>
    /// <param name="SourceType">The source type to set.</param>
    internal procedure SetGlobalSourceType(SourceType: Enum "Prod. Definition Source")
    begin
        GlobalSourceType := SourceType;
    end;

    /// <summary>
    /// Sets the production order status on the temporary production order line.
    /// </summary>
    /// <param name="NewStatus">The production order status to set.</param>
    internal procedure SetProdOrderStatus(NewStatus: Enum "Production Order Status")
    begin
        ProdOrderStatus := NewStatus;
    end;

    /// <summary>
    /// Get the production order status.
    /// </summary>
    /// <returns>The production order status.</returns>
    internal procedure GetProdOrderStatus(): Enum "Production Order Status"
    begin
        exit(ProdOrderStatus);
    end;

    local procedure GetManufacturingSetup()
    begin
        if ManufacturingSetupRead then
            exit;

        ManufacturingSetup.Get();
        ManufacturingSetupRead := true;
    end;

    local procedure BindProdOrderSubscriber()
    begin
        UnbindSubscription(ProdOrdLineBind);
        ProdOrdLineBind.SetProdOrder(TempProdOrder);
        ProdOrdLineBind.SetProdOrderLine(TempProdOrderLine);
        BindSubscription(ProdOrdLineBind);
    end;



    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTemporaryComponentFromBOMLine(var TempProdOrderComponent: Record "Prod. Order Component" temporary; ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTemporaryProdOrderRoutingLineFromRouting(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; RoutingLine: Record "Routing Line")
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeNewTemporaryRoutingInformation(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary; ItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDefaultRoutingOperation(var TempRoutingLine: Record "Routing Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDefaultTemporaryBOMLine(var TempBOMLine: Record "Production BOM Line" temporary; DefaultComponentItemNo: Code[20])
    begin
    end;
}